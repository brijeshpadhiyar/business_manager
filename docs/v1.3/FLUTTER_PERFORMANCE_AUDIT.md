# StitchFlow V1.3 – Flutter Performance Audit (Phase 2)

**Date:** 2026-11-24  
**Workspace:** `c:\A1\business_manager`  
**Audit Mode:** Read-Only Baseline Inspection

---

## 1. Current Verified Baseline

| Metric | Current Verified Measurement | Notes |
|---|---|---|
| Static Analysis (`flutter analyze`) | **0 issues** (4.2s) | Verified fresh |
| Automated Test Suite (`flutter test`) | **160 / 160 passed** (49s) | Verified fresh |
| Universal Release APK Size (`app-prod-release.apk`) | **76.42 MB** | Bundles `armeabi-v7a` + `arm64-v8a` + `x86_64` |
| `StreamSubscription` leaks | **0** | 0 manual `StreamSubscription` fields in `lib/` |
| `AnimationController` leaks | **0** | All animations use declarative `flutter_animate` / `animations` / `AnimatedSwitcher` |
| `debugPrint` / `print` in `lib/` | **0** | Structured `AppLogger` only |
| Physical-device / Profile-mode FPS & Cold-start Trace | **Pending** | No physical Android device attached during read-only audit; emulator/device trace planned in Phase 6 |

---

## 2. Identified Flutter Performance Bottlenecks

### PF-01 (P1 – High): `FutureBuilder` Creating Uncached Futures Inside `build()`
- **Location**: `lib/features/lots/presentation/pages/lot_detail_page.dart:805` and `:1262`.
- **Root Cause**: `FutureBuilder<JobRoutingOverview?>(future: getIt<ProcessRoutingRepository>().getJobRoutingOverview(lotId))` is instantiated inline inside `_buildLoaded`. Every keystroke in the Design search field triggers `LotDetailCubit.setDesignSearch`, rebuilding `_LotDetailView` and re-running a full multi-table SQLite read (`getJobRoutingOverview`) + re-reading photo bytes from disk in `_LotPhotoTile`.
- **Recommended Fix**: Move `routingOverview` loading into `LotDetailCubit` (loaded once alongside `detail` on `loadLot`) and cache photo bytes in `_LotPhotoTile` (`StatefulWidget` with `initState` future) so search typing is 100% in-memory and instant.

### PF-02 (P1 – High): Unthrottled Keystroke Search Triggering SQLite Reads
- **Location**: `lot_list_page.dart:239`, `worker_list_page.dart:81`, `process_list_page.dart:84`.
- **Root Cause**: Typing a 10-character search query fires 10 consecutive full-table SQLite reads (`getActiveLots`, `getAllMembers`, `getAllProcesses`) + 10 BLoC loading/loaded rebuild cycles.
- **Recommended Fix**: Add optional `debounceDuration` (default `220ms` when enabled) to `AppSearchField` (properly cancelling `Timer` in `dispose()`) and migrate all 3 list pages to `AppSearchField`.

### PF-03 (P2 – Medium): Dense Scrolling `BackdropFilter` Cost on Low-End GPUs
- **Location**: `lib/core/widgets/app_card.dart` & `lib/core/widgets/app_glass_surface.dart` (14 `BackdropFilter` sites total; `AppCard` defaults to `isGlass: true`, `blurSigma: 14`).
- **Analysis**: `AppGlassSurface` already uses `RepaintBoundary` (good!), and `AppMotionEntrance` / `AppSkeletonBox` respect `MediaQuery.maybeDisableAnimationsOf(context)`. However, inside long scrolling `ListView.separated` lists (Lots, Workers, Processes, Stock Movements), rendering 8–12 simultaneous `BackdropFilter(sigma: 14)` saveLayers per frame can cause shader/fill-rate pressure on budget Android GPUs.
- **Recommended Fix**: Preserve full `BackdropFilter` on Hero cards, KPI `AppMetricTile`s, `AppBar`, Navigation chrome, `AppDialog`, `AppBottomSheet`, and `AppMessageService` toasts; add a lightweight `blurSigma: 0` (translucent frosted gradient + luminous glass border without extra GPU readback) option or `isLightweightGlass` mode for dense scrolling list rows if profile-mode raster timing exceeds 16ms.

### PF-04 (P2 – Medium): ListView Lazy Rendering & Stable Keys
- **Verified Good**: `lot_list_page.dart`, `worker_list_page.dart`, and `process_list_page.dart` all use `ListView.separated` (lazy item builder).
- **Improvement**: Add stable `ValueKey<String>(item.id)` keys to list item cards so Flutter reuses Element/RenderObject subtrees across filter/search updates.

### PF-05 (P2 – Medium): APK Size Optimization (`76.42 MB` Universal APK)
- **Root Cause**: Universal APK contains 3 native ABIs (`arm64-v8a`, `armeabi-v7a`, `x86_64`).
- **Recommended Fix**: Verify `--split-per-abi` APK sizes (`arm64-v8a` typically ~26–28 MB) and evaluate R8 shrinking in `build.gradle.kts` without breaking Drift/SQLite/local_auth reflection.
