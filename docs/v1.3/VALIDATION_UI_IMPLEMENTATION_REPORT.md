# StitchFlow V1.3 – Hardening, Shared UI & Workflow QA Implementation Report

**Date:** 2026-11-24  
**Workspace:** `c:\A1\business_manager`  
**Schema Version:** v6 (19 tables, fully backwards-compatible with v1–v5)

## 1. Original Issues & Root Causes
1. **Scattered Dialogs & SnackBar Bypass**: 5 screens rendered raw `AlertDialog` widgets bypassing the V1.3 frosted-glass `AppDialog`, 1 screen called `ScaffoldMessenger.of(context).showSnackBar` directly, and 1 screen used raw `showDialog`/`Dialog`.
2. **Legacy Notification Design**: `AppFeedback` (43 call sites) used plain `SnackBar`s without Glassmorphism styling, warning/loading variants, responsive top/top-right positioning, or duplicate throttling.
3. **Raw Exception Leaks**: 4 catch blocks displayed `e.toString()` directly to users.
4. **Floating-Point Parsing in Process Routing**: `JobProcessRoutingPage` parsed monetary inputs with `(double.tryParse * 100).round()` instead of `AppValidators.parseRupeesToPaiseExact`.

## 2. Architecture Decisions
- **Notification Package Selected**: `toastification: ^3.2.2` (Dart 3, multi-platform Android/Windows/Web, MIT licensed, zero conflicts with `material_ui: ^1.11.1`).
- **Strict Abstraction**: `toastification` is encapsulated exclusively inside `lib/core/services/app_message_service.dart` and `ToastificationWrapper` in `lib/app.dart`. No feature module imports `toastification`.
- **Zero Timer Leaks**: `AppMessageService` manages auto-close timers explicitly and cancels them synchronously via `AppMessageService.cancelPendingTimers()` in `BusinessManagerApp.dispose()`, ensuring deterministic teardown in both production restarts and widget tests.
- **Zero Breaking Changes**: `AppFeedback` remains as a thin facade delegating to `AppMessageService`; no database schema changes were required beyond the existing v6 schema.

## 3. Components Created
- `lib/core/services/app_message_service.dart` — Glassmorphism notification service (`success`, `error`, `warning`, `info`, `loading`, `dismiss`, `dismissAll`, `cancelPendingTimers`).
- `lib/core/widgets/app_confirmation_dialog.dart` — Semantic confirmation dialog (`info`, `warning`, `destructive`) with consequence banner.
- `lib/core/widgets/app_success_state.dart` — Reusable frosted-glass success state.
- `lib/core/widgets/app_search_field.dart` — Clearable search field with `ValidationLimits.maxSearchLength`.
- `lib/core/widgets/app_section_header.dart` — Consistent section heading + subtitle + trailing action.
- `lib/core/validation/input_formatters.dart` — Shared `AppInputFormatters` presets.

## 4. Components Modified & Feature Screens Migrated
- Core: `pubspec.yaml`, `lib/app.dart`, `app_dialog.dart`, `app_feedback.dart`, `app_loader.dart`, `widgets.dart`, `app_validators.dart`, `validation_localizer.dart`, `validation.dart`, `l10n_extensions.dart`, `app_en.arb`, `app_gu.arb`.
- Feature screens migrated: `lot_detail_page.dart`, `accounting_overview_page.dart`, `worker_ledger_page.dart`, `stock_movements_page.dart`, `security_settings_page.dart`, `security_reauth_dialog.dart`, `stock_labour_settings_page.dart`, `job_process_routing_page.dart`.

## 5. Verification Summary
- **Database Integrity**: All 19 tables, PRAGMAs (`foreign_keys=ON`, `synchronous=FULL`, `WAL`), atomic transactions, rollback, unique partial indexes, and v1–v6 migration tests verified.
- **`flutter analyze`**: **0 issues found**.
- **`flutter test`**: **160 / 160 tests passed**.
- **Production Release APK**: `build/app/outputs/flutter-apk/app-prod-release.apk` (76.4 MB) built cleanly.
- **Runtime Verification**: Automated widget tests verified Light Glass, Dark Glass, EN & GU localization, 360dp responsive layout, dialogs, notifications, and navigation; physical/emulator manual install was not re-run in this pass (previously verified on `Pixel_5` for V1.3 Glassmorphism).

## 6. Remaining Issues & Future Recommendations
- Consider migrating remaining feature search bars (`lot_list_page.dart`, `worker_list_page.dart`, `process_list_page.dart`) to `AppSearchField` incrementally as those screens evolve.
- If a `dev` flavor APK is also required alongside `prod`, run `flutter build apk --release --flavor dev -t lib/main_dev.dart`.
