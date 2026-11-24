# StitchFlow V1.3 – 120Hz Performance Optimization & Smoothness Report

**Date:** 2026-11-24  
**Workspace:** `c:\A1\business_manager`  
**Flutter / Dart Toolchain:** Flutter `3.50.1` (stable) • Dart `3.14.0` • DevTools `2.61.0`  
**Target Device:** OPPO Reno 16 (High-Refresh-Rate Android Display)  
**Verification Status:** Automated Analysis & Full Test Suite **PASSED (0 issues, 178/178 tests)** | Fresh Dev Profile, Dev Release & Prod Profile APKs **BUILT** | Physical-Device ADB Telemetry **Pending Device Connection / Manual On-Device Verification**

---

## 1. Initial Performance Baseline (Phase 1 Code & Architecture Audit)

Before any code modifications were made, the entire Flutter rendering tree, Android platform setup, BLoC/Cubit layer, scrolling screens, animation primitives, and image loaders were audited, and an unmodified baseline `dev` Profile APK was built and archived (`app-dev-profile-baseline.apk`, 104.0 MB) for future apples-to-apples hardware comparison.

### Baseline Automated Health (Unmodified)
- `flutter analyze`: **0 issues**
- `flutter test`: **164 / 164 passed**
- Drift / SQLite Schema v7 durability settings: `WAL`, `synchronous=FULL`, `foreign_keys=ON`, `busy_timeout=5000` (all preserved strictly untouched)

### Root Causes Identified Behind 40–60 FPS Feel on 120Hz Android Hardware

| ID | Category | Severity | Concrete Root Cause Found |
|---|---|---|---|
| **R-01** | **Android Display Mode** | **Critical** | `MainActivity.kt` did not request the highest supported `Display.Mode` (`preferredDisplayModeId`). On many high-refresh-rate Android OEMs (including ColorOS / OPPO, HyperOS, OxygenOS), Flutter apps default to 60Hz unless a high-refresh display mode is explicitly requested at the window level. |
| **R-02** | **Per-Card & Nested `BackdropFilter` GPU Fill-Rate** | **Critical** | `AppCard` and `AppMetricTile` defaulted to `isGlass: true, blurSigma: 14`, creating a `RepaintBoundary` + dual `BoxShadow` (`blurRadius: 20` & `12`) + `ClipRRect` + `BackdropFilter(sigma: 14)` on **100+ cards across 35 screens**. Scrolling screens executed 8–14 simultaneous GPU backdrop readbacks + Gaussian blurs per 8.33ms frame, and `LotDetailPage` **nested** `_PremiumLotColourCard` (`σ=14`) inside `_buildDesignSectionCard` (`σ=14`). |
| **R-03** | **Stacked Header Chrome Blurs & `Opacity` `saveLayer`s** | **High** | Collapsible screens stacked `ResponsiveNavigation` `AppBar` (`σ=18`) + `AppCollapsibleHeader` (`σ=16`) + `AppPinnedSliverHeader` (`σ=14`) + `NavigationBar` (`σ=20`), while `AppCollapsibleHeader` used `Opacity` inside a per-frame `LayoutBuilder` (allocating `canvas.saveLayer` on every scroll pixel). Dialogs (`σ=22`) and Bottom Sheets (`σ=24`) animated very large Gaussian kernels across entire viewports. |
| **R-04** | **PF-01: Inline `FutureBuilder`s & Repeated Reads in `LotDetailPage`** | **High** | `lot_detail_page.dart:805` created `getJobRoutingOverview(lotId)` inline inside `build()`, and `:1262` created `readPhotoBytes(...)` inline inside `_LotPhotoTile.build()`. Every keystroke in Design Search re-ran multi-table SQLite queries, re-read all lot photos from disk, and executed $O(N \times M)$ linear `.where(...)` scans on `skuBalances` and `jobProcesses`. |
| **R-05** | **Tab Destruction, Double-Page Transitions & Scroll-Time Animations** | **High** | `StitchFlowShellPage` destroyed and recreated tabs on every bottom-nav switch (re-running SQLite queries + `FadeThroughTransition`). Pushed routes ran `SharedAxisTransition` (`280ms`, compositing two full transparent glass pages simultaneously). `LotListPage`, `WorkerListPage`, `AccountingOverviewPage`, `StockMovementsPage`, and `JobProcessRoutingPage` wrapped scrolling items in `AppMotionEntrance` (`flutter_animate` delays up to `280ms` + `360ms` fade/slide). `AppPressable` called `setState` + `AnimatedScale` on every card touch-down before scroll drags. |
| **R-06** | **Eager List Rendering & Search/Filter Spinner Flashes** | **High** | `AccountingOverviewPage`, `InventoryOverviewPage` (via `AppDataTable` mobile `Column`), `StockMovementsPage`, `LotDetailPage`, `ReceiveReturnPickerPage`, `WorkerLedgerPage`, `DailySummaryPage`, and `RateHistoryPage` rendered full lists eagerly inside `Column` / `ListView(children: [...])`. `AppSearchField` defaulted `debounceDuration` to `null` (firing SQLite queries per keystroke), and list Cubits emitted `status: loading` on every search/filter/refresh, flashing a full-screen spinner. |
| **R-07** | **Full-Resolution Image Decoding & Uncached Themes/Backdrops** | **Medium** | `_LotPhotoTile` decoded up-to-1600×1600 JPEGs (~10 MB RGBA) without `cacheWidth` for `112×112` thumbnails; brand PNG icons decoded full-res assets; `AppTheme.light()`/`dark()` rebuilt `ThemeData` on every root rebuild; `AppGlassBackdrop` `CustomPaint` lacked `isComplex: true, willChange: false`. |

---

## 2. Optimizations Implemented

### A. Native Android High-Refresh-Rate Opt-In
- **[`android/app/src/main/kotlin/com/brijesh/stitchflow/MainActivity.kt`](file:///c:/A1/business_manager/android/app/src/main/kotlin/com/brijesh/stitchflow/MainActivity.kt)**:
  - Added safe API 23+ `requestHighestSupportedRefreshRate()` invoked in `onCreate()` and `onAttachedToWindow()`.
  - Queries `display.supportedModes` (API 30+) with `windowManager.defaultDisplay` fallback (API 23–29), filters to modes matching the active physical resolution (`physicalWidth` × `physicalHeight`), selects `maxByOrNull { it.refreshRate }`, and assigns `window.attributes.preferredDisplayModeId`.
  - Never hardcodes 120Hz, never alters resolution, respects OEM/system ceilings, and safely catches any platform exception.

### B. Glassmorphism GPU Optimization (All 35 Screens)
- **[`lib/core/design_system/app_colors.dart`](file:///c:/A1/business_manager/lib/core/design_system/app_colors.dart)**: Added `AppSurfaceTokens.lightweightGlassGradient` tuned for both **Light Glass** and **Dark Glass** so cards with `blurSigma == 0` preserve frosted specular luminosity, depth, and crisp contrast over `AppGlassBackdrop`.
- **[`lib/core/widgets/app_glass_backdrop.dart`](file:///c:/A1/business_manager/lib/core/widgets/app_glass_backdrop.dart)**: Added `isComplex: true, willChange: false` to `CustomPaint` so Flutter/Impeller caches the ambient aurora gradient + 3 radial orb glows into a static GPU layer once.
- **[`lib/core/widgets/app_glass_surface.dart`](file:///c:/A1/business_manager/lib/core/widgets/app_glass_surface.dart)** & **[`lib/core/widgets/app_card.dart`](file:///c:/A1/business_manager/lib/core/widgets/app_card.dart)** & **[`lib/core/widgets/app_metric_tile.dart`](file:///c:/A1/business_manager/lib/core/widgets/app_metric_tile.dart)**:
  - Added `enum AppGlassStyle { full, lightweight }` and `AppCard.listItem(...)`.
  - Switched default `AppCard` and `AppMetricTile` rendering globally to `AppGlassStyle.lightweight` (`blurSigma: 0`, single soft shadow, zero `BackdropFilter`, zero unnecessary per-card `RepaintBoundary`, `enablePressScale: false` with native `InkWell` ripple).
  - Preserved real `BackdropFilter` blur (tuned `sigma 10–14`) strictly on fixed/modal chrome and focal hero surfaces:
    - Dashboard Hero Banner (`glassStyle: AppGlassStyle.full, blurSigma: 12`)
    - `ResponsiveNavigation` `AppBar` / `NavigationBar` / `NavigationRail` / `NavigationDrawer` (`sigma: 12`)
    - `AppScaffold` fixed `AppBar` (`sigma: 12`) & `AppCollapsibleHeader` toolbar (`sigma: 10`)
    - `AppDialog` (`sigma: 14`), `AppBottomSheet` (`sigma: 14`), `AppMessageService` toasts (`sigma: 12`)
- **[`lib/core/widgets/app_collapsible_header.dart`](file:///c:/A1/business_manager/lib/core/widgets/app_collapsible_header.dart)**:
  - Switched `AppPinnedSliverHeader` to lightweight frosted glass (eliminating stacked double full-width `BackdropFilter` passes during scrolling).
  - Replaced collapsed title `Opacity` widget with direct `TextStyle.color` alpha interpolation (zero `saveLayer`) and short-circuited expanded `Opacity` when `expandedOpacity >= 0.995`.
- **[`lib/core/widgets/app_skeleton.dart`](file:///c:/A1/business_manager/lib/core/widgets/app_skeleton.dart)**: Switched `AppSkeletonList` cards to lightweight glass.

### C. Lot Detail Optimization (PF-01)
- **[`lib/features/lots/presentation/bloc/lot_detail_cubit.dart`](file:///c:/A1/business_manager/lib/features/lots/presentation/bloc/lot_detail_cubit.dart)** (regenerated `lot_detail_cubit.freezed.dart` & `injection.config.dart`):
  - Injected `ProcessRoutingRepository` and loaded `getLotDetail` + `getJobRoutingOverview` in parallel once inside `loadLot(lotId)`.
  - Pre-indexed `balancesByColourId` and `operationsByColourId` maps for $O(1)$ per-card lookups.
  - Added bounded per-lot photo future cache (`_maxCachedPhotos = 48`), evicted on `removePhoto` and cleared on `close()`.
- **[`lib/features/lots/presentation/pages/lot_detail_page.dart`](file:///c:/A1/business_manager/lib/features/lots/presentation/pages/lot_detail_page.dart)**:
  - Removed both inline `FutureBuilder`s (`line 805` & `line 1262`).
  - Isolated Design Search via `BlocSelector` so typing triggers **0 extra DB queries and 0 extra disk reads** (verified by automated mock test).
  - Converted designs section to `CustomScrollView` + lazy `SliverList.separated` with stable `ValueKey`s and zero nested `BackdropFilter`s.
  - Converted `_LotPhotoTile` into a `StatefulWidget` with cached `Future` and DPR-bounded `cacheWidth` thumbnail decoding (`gaplessPlayback: true`).

### D. Widget Rebuilds, Silent In-Place Updates & Instant Tabs
- **[`lib/core/router/app_router.dart`](file:///c:/A1/business_manager/lib/core/router/app_router.dart)**: Upgraded `StitchFlowShellPage` to a **lazy-initialized `IndexedStack`** with per-tab `ValueNotifier<int>` silent refresh signals — instant tab switches, preserved scroll positions, and live data without stale caches.
- **[`lib/core/design_system/app_theme.dart`](file:///c:/A1/business_manager/lib/core/design_system/app_theme.dart)**: Cached static `ThemeData` instances (`_lightTheme`, `_darkTheme`).
- **Silent in-place search/filter/refresh (zero spinner flashes) + out-of-order search request guards**:
  - `lot_list_cubit.dart`, `worker_list_cubit.dart`, `process_list_cubit.dart`, `stock_movements_cubit.dart`, `accounting_overview_cubit.dart` (also precomputes summary totals once on load), `dashboard_cubit.dart`, `inventory_overview_cubit.dart`.
- **Debounced search (`AppSearchField`)**: Enabled `220ms` debounce on SQLite-backed search inputs (`LotListPage`, `WorkerListPage`, `ProcessListPage`, `StockMovementsPage` history) and `120–160ms` on in-memory filters (`LotDetailPage`, `AccountingOverviewPage`, `ReceiveReturnPickerPage`).

### E. Scrolling & Animation Optimizations
- **[`lib/core/widgets/app_data_table.dart`](file:///c:/A1/business_manager/lib/core/widgets/app_data_table.dart)**: Added `AppDataTable.buildSliver<T>` rendering lazy `SliverList.separated` on compact mobile (`< 600dp`) with `AppCard.listItem` and stable `ValueKey`s.
- **Converted eager lists to lazy `CustomScrollView` + `SliverList.separated`**:
  - `inventory_overview_page.dart`, `accounting_overview_page.dart` (all 3 tabs), `stock_movements_page.dart`, `lot_detail_page.dart`, `receive_return_picker_page.dart`, `worker_ledger_page.dart`, `daily_summary_page.dart`, `rate_history_page.dart`.
- **[`lib/core/design_system/app_motion.dart`](file:///c:/A1/business_manager/lib/core/design_system/app_motion.dart)**:
  - Replaced double-page `SharedAxisTransition` in `AppMotion.buildPage` with a fast **200ms forward / 160ms reverse** incoming `FadeTransition` + subtle `4%` `SlideTransition` (avoiding double-screen compositing over glass backdrops).
  - Shortened `AppMotionEntrance` to `180ms` with capped `20ms` stagger (max `60ms` delay) and removed `AppMotionEntrance` from scrolling list item builders (`LotListPage`, `WorkerListPage`, `AccountingOverviewPage`, `StockMovementsPage`, `JobProcessRoutingPage`).
  - Added scroll-drag cancellation (`> 10px` pointer movement) in `AppPressable`.
  - Made `AppDialog` (`200ms`/`150ms`) and `AppBottomSheet` (`220ms`/`160ms`) transitions snappy and reduced-motion-safe.
- **[`lib/core/widgets/app_animated_number.dart`](file:///c:/A1/business_manager/lib/core/widgets/app_animated_number.dart)**: Converted to `StatefulWidget` so refreshes animate smoothly from `oldValue -> newValue` (or remain steady when unchanged) instead of restarting from `0`.

### F. Image & Memory Optimizations
- **[`lib/bootstrap.dart`](file:///c:/A1/business_manager/lib/bootstrap.dart)**: Configured conservative mobile-friendly `PaintingBinding.instance.imageCache` caps (`maximumSize = 200`, `maximumSizeBytes = 64 MiB`).
- Added bounded `cacheWidth`/`cacheHeight` decoding to `_LotPhotoTile` (`lot_detail_page.dart`) and all brand `Image.asset` call sites (`responsive_navigation.dart`, `dashboard_page.dart`, `app_lock_screen.dart`, `app_lock_gate.dart`, `about_stitchflow_page.dart`).

### G. Dev-Only Opt-In Stress Dataset Seeder
- **[`lib/core/dev/dev_perf_seeder.dart`](file:///c:/A1/business_manager/lib/core/dev/dev_perf_seeder.dart)**: Strictly gated by `config.isDev && const bool.fromEnvironment('SEED_PERF_DATA')`. Seeds **60 lots (including 1 stress lot with 8 designs × 4 colours + 4 real PNG photos), 540 design-colours, 40 workers, 20 processes, 175 stock movements, 70 labour entries, and 80 payments** in a single transaction while leaving `prod` data 100% untouched.

---

## 3. Automated Verification Results

| Check | Result |
|---|---|
| `dart run build_runner build` | **0 warnings, 0 errors** |
| `flutter analyze` | **0 issues found** |
| `flutter test` (Full Suite) | **178 / 178 passed (100%)** |
| `test/features/lot_detail_perf_test.dart` | **PASSED** — verified 0 extra `getJobRoutingOverview` DB queries & 0 extra `readPhotoBytes` disk reads during Design Search typing |
| `test/widget/glass_performance_mode_test.dart` | **PASSED (5/5)** — verified lightweight glass defaults, preserved Hero/AppBar full blur, zero stacked pinned-header blur, lazy `AppDataTable.buildSliver`, and silent in-place `LotListCubit` search updates |

---

## 4. Fresh APK Artifacts Built for OPPO Reno 16

| Artifact | Package | Mode | Size | Purpose |
|---|---|---|---|---|
| `build/app/outputs/flutter-apk/stitchflow-v1.3-dev-release-seeded.apk` | `com.brijesh.stitchflow.dev` | **Release (AOT)** | **76.7 MB** | Primary 120Hz real-world smoothness verification with seeded 60-lot / 540-SKU dataset |
| `build/app/outputs/flutter-apk/stitchflow-v1.3-dev-profile-seeded.apk` | `com.brijesh.stitchflow.dev` | **Profile (AOT + DevTools)** | **104.3 MB** | Flutter DevTools & `adb shell dumpsys gfxinfo` profiling against seeded dataset |
| `build/app/outputs/flutter-apk/stitchflow-v1.3-prod-profile.apk` | `com.brijesh.stitchflow` | **Profile (AOT + DevTools)** | **104.1 MB** | Final verification against real production workshop data (touches zero prod records) |

*(Note: A signed `prod` Release APK requires configuring `android/key.properties` per the PR-01 release signing safeguard in `android/app/build.gradle.kts`.)*

---

## 5. Physical-Device Profiling Status (OPPO Reno 16)

> **Honest Reporting Notice:** During this session, no Android device was connected via ADB (`adb devices` returned empty), and you chose to install and test the freshly built APKs directly on your OPPO Reno 16. **No FPS, frame-time, CPU, or memory numbers have been fabricated.**

### How to Capture Exact Before/After Numbers When OPPO Reno 16 Is Connected via ADB
1. Verify active display mode & refresh rate on OPPO Reno 16:
   ```powershell
   adb shell dumpsys display | Select-String -Pattern "mActiveMode|mSupportedModes|refreshRate"
   adb shell settings get system peak_refresh_rate
   ```
2. Run deterministic scroll profiling (`adb shell dumpsys gfxinfo <pkg> reset` + swipes + `framestats` + `dumpsys meminfo`) using the prepared helper script in the session scratch directory (`profile_device.ps1`) against:
   - Archived unmodified baseline APK (`scratch/app-dev-profile-baseline.apk`)
   - Fresh optimized Profile APK (`build/app/outputs/flutter-apk/stitchflow-v1.3-dev-profile-seeded.apk`)
   - Fresh Prod Profile APK (`build/app/outputs/flutter-apk/stitchflow-v1.3-prod-profile.apk`)

### Physical-Device Measurement Template (To Populate on OPPO Reno 16)

| Scenario (OPPO Reno 16, Profile Mode) | Active Hz | Baseline Avg / P90 / P99 (ms) | Optimized Avg / P90 / P99 (ms) | Jank > 8.33ms (%) | Notes |
|---|---|---|---|---|---|
| Cold Launch | Pending | Pending | Pending | Pending | Measure via `adb shell am start -W` |
| Dashboard Scrolling | Pending | Pending | Pending | Pending | Hero full blur + lightweight KPIs |
| Lot List (60 Lots) | Pending | Pending | Pending | Pending | Collapsible header + debounced search |
| Lot Detail (`LOT-1060`, 8 designs, 32 colours, 4 photos) | Pending | Pending | Pending | Pending | PF-01 zero DB/disk reads on search |
| Worker List (40 Workers) | Pending | Pending | Pending | Pending | Lazy `SliverList` + silent search |
| Process List (20 Processes) | Pending | Pending | Pending | Pending | Lazy `SliverList` + silent search |
| Inventory (540 SKUs) | Pending | Pending | Pending | Pending | Lazy `AppDataTable.buildSliver` |
| Accounting (40 Workers / 80 Payments / 70 Labour) | Pending | Pending | Pending | Pending | Lazy `SliverList` + precomputed totals |
| Dialog & Bottom Sheet Transitions | Pending | Pending | Pending | Pending | Tuned `sigma: 14` + `200–220ms` |
| Light Glass & Dark Glass + Repeated Tab Switching | Pending | Pending | Pending | Pending | Lazy `IndexedStack` + memory stability |

---

## 6. Remaining Known Considerations

- **First-Frame Shader Warm-Up**: On cold launch, the very first dialog or bottom sheet open with `BackdropFilter(sigma: 14)` may take slightly longer than 8.33ms on first-ever pipeline compilation depending on the device's GPU driver; subsequent opens reuse cached pipelines.
- **Reports Complex Layouts (`ReportsPage`)**: Individual report sub-tables (`AppDataTable`) now render lightweight glass cards on mobile, and category switches are instant (`KeyedSubtree`), though the top-level `ReportsPage` still wraps heterogeneous chart + KPI + table sections in a `ListView` — if profiling on huge multi-year datasets shows any scroll hitch inside Reports, migrating each category into dedicated sliver builders is a clean next step.
- **Prod Release Signing**: Add `android/key.properties` pointing to your upload keystore before building `flutter build apk --release --flavor prod -t lib/main_prod.dart`.
