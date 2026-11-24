# StitchFlow V1.3 – Hardening, Shared UI & Workflow QA Changelog

## 2026-11-24

### Phase 0 – Application Audit & Plan
- Audited all 15 feature modules, 27 shared widgets, `AppValidators`, database schema v6 (19 tables), and 43+ notification call sites.
- Authored `docs/v1.3/VALIDATION_UI_WORKFLOW_AUDIT.md` and `docs/v1.3/VALIDATION_UI_WORKFLOW_IMPLEMENTATION_PLAN.md`.

### Phase 1 & 2 – Shared Common UI & Glassmorphism Messaging (`toastification ^3.2.2`)
- Added `toastification: ^3.2.2` and mounted `ToastificationWrapper` inside `MaterialApp.router` builder in `lib/app.dart`.
- Created `lib/core/services/app_message_service.dart` (`success`, `error`, `warning`, `info`, `loading`, `dismiss`, `dismissAll`, `cancelPendingTimers`) with frosted Glassmorphism cards, Light/Dark Glass contrast, responsive top/top-right positioning, and duplicate throttling.
- Upgraded `AppFeedback` to delegate to `AppMessageService`.
- Enhanced `AppDialog` (icon, tone, scrollable content) and `AppLoader` (`AppLoader.inline`).
- Added `AppConfirmationDialog`, `AppSuccessState`, `AppSearchField`, and `AppSectionHeader` to `lib/core/widgets/widgets.dart`.
- Migrated all 5 raw `AlertDialog` instances, 1 raw `showDialog`, 1 direct `ScaffoldMessenger.showSnackBar`, and 4 raw `e.toString()` user error leaks across Lots, Accounting, Stock Movements, Security, and Settings.

### Phase 3, 4 & 7 – Centralized Validation & Bilingual Localization (EN/GU)
- Added `minLengthValidator` & `exactLengthValidator` to `AppValidators` and created `lib/core/validation/input_formatters.dart`.
- Added EN & GU ARB keys for notification titles and V1.3 Process Routing validation messages in `app_en.arb` and `app_gu.arb`; regenerated localizations via `flutter gen-l10n`.
- Extended `ValidationLocalizer.localizeDomainCode` for V1.3 routing & colour master error codes.
- Upgraded `JobProcessRoutingPage` sheets to use `AppValidators.parseRupeesToPaiseExact` and `AppValidators.parseQuantityExact` (eliminating floating-point `double.tryParse`).

### Phase 5, 6 & 8 – Complete Workflow QA, Verification & Release
- Added `test/features/complete_workflow_qa_test.dart` (12 end-to-end business workflow scenarios) and `test/widget/shared_ui_and_messaging_test.dart`.
- Verified `flutter analyze` (0 issues), `flutter test` (160/160 passed), and production APK build (`app-prod-release.apk`, 76.4 MB).
- Authored all 6 V1.3 audit, QA, test, and implementation reports in `docs/v1.3/`.
