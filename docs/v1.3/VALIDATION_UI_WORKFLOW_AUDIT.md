# StitchFlow V1.3 – Complete Application Audit (Validation, Shared UI & Workflows)

**Date:** 2026-11-24  
**Workspace:** `c:\A1\business_manager`  
**Audited Baseline:** Schema v6 (19 SQLite tables), Flutter SDK / Dart `^3.14.0`, `material_ui: ^1.11.1`, 148/148 tests passing, `flutter analyze` 0 issues.

---

## 1. Architecture Overview

StitchFlow is an offline-first, bilingual (English + Gujarati) Flutter business management application built on:
- **State Management**: `flutter_bloc` (`Bloc` / `Cubit`)
- **Database**: Drift ORM + SQLite (`AppDatabase`, schema v6, WAL + `foreign_keys = ON` + `synchronous = FULL`, atomic `DatabaseTransactionRunner`)
- **Routing**: `go_router` (`RoutePaths` + `AppMotion.buildPage`)
- **DI**: `get_it` + `injectable`
- **Design System**: StitchFlow V1.3 Premium Glassmorphism (`AppColors`, `AppSurfaceTokens`, `AppTheme.light()` / `AppTheme.dark()`, `AppMotion`, `AppGlassBackdrop`, `AppGlassSurface`)

## 2. Module Inventory

| # | Module | Layer Path | Primary Screens |
|---|--------|-----------|-----------------|
| 1 | Dashboard | `lib/features/dashboard/` | `DashboardPage` |
| 2 | Lots & Colours | `lib/features/lots/` | `LotListPage`, `LotDetailPage`, `LotColourDetailPage`, `VisualColourPickerSheet` |
| 3 | Inventory | `lib/features/inventory/` | `InventoryOverviewPage` |
| 4 | Processes | `lib/features/processes/` | `ProcessListPage`, `ProcessDetailPage`, `ProcessFormPage` |
| 5 | Workers | `lib/features/workers/` | `WorkerListPage`, `WorkerDetailPage`, `WorkerFormPage`, `WorkerAssignmentsPage` |
| 6 | Rates | `lib/features/rates/` | `RateHistoryPage`, `RateFormPage` |
| 7 | Stock Movements | `lib/features/stock_movements/` | `StockMovementsPage`, `StockIssuePage`, `ReceiveReturnPickerPage`, `StockSettlementPage`, `DamagedRepairPage` |
| 8 | Process Routing & Pricing | `lib/features/process_routing/` | `JobProcessRoutingPage` (Multi-process, direct transfer, factory return, reassignment, dynamic pricing, extra charges, payments) |
| 9 | Accounting & Payments | `lib/features/accounting/` | `AccountingOverviewPage`, `WorkerLedgerPage`, `PaymentFormPage`, `WorkerAdjustmentFormPage` |
| 10 | Reports & Daily Summary | `lib/features/reports/` | `ReportsPage`, `DailySummaryPage`, `ReportFilterBar`, `ReportExportSheet` |
| 11 | Backup & Restore | `lib/features/backup/` | `BackupRestorePage` |
| 12 | Business Profile | `lib/features/business_profile/` | `BusinessProfilePage` |
| 13 | Notifications | `lib/features/notifications/` | `NotificationSettingsPage` |
| 14 | Settings & Help | `lib/features/settings/` | `SettingsHomePage`, `AppearanceSettingsPage`, `StockLabourSettingsPage`, `HelpGuidancePage`, `AboutStitchFlowPage` |
| 15 | Security | `lib/features/security/` | `SecuritySettingsPage`, `PinSetupPage`, `PinRecoveryPage`, `AppLockScreen`, `SecurityReauthDialog` |

## 3. Form & Input Inventory

| Module / Screen | Form Type | Current Validation Status | Severity |
|---|---|---|---|
| `LotListPage` (New Lot) | `AppBottomSheet` + `Form` | Uses `AppValidators` + `ValidationLocalizer` | ALREADY IMPLEMENTED |
| `LotDetailPage` (Edit Lot / Design / Colour) | `AppBottomSheet` + `Form` | Uses `AppValidators` + `ValidationLocalizer` | ALREADY IMPLEMENTED |
| `VisualColourPickerSheet` (Qty & Custom Colour) | `AppBottomSheet` + `AppDialog` | Manual `int.tryParse` + `AppColourUtils.normalizeHex` | MEDIUM |
| `WorkerFormPage` | Page `Form` | Uses `AppValidators` (name, Indian/E.164 mobile, address, notes) | ALREADY IMPLEMENTED |
| `ProcessFormPage` | Page `Form` | Uses `AppValidators` (name, notes) | ALREADY IMPLEMENTED |
| `RateFormPage` | Page `Form` | Uses `AppValidators` (rate, ISO date range) | ALREADY IMPLEMENTED |
| `StockIssuePage` / `StockSettlementPage` / `DamagedRepairPage` | Page `Form` | Uses `AppValidators` + `FormValidationHelper` | ALREADY IMPLEMENTED |
| `PaymentFormPage` / `WorkerAdjustmentFormPage` | Page `Form` | Uses `AppValidators` + `FormValidationHelper` | ALREADY IMPLEMENTED |
| `BusinessProfilePage` | Page `Form` | Uses `AppValidators` (EN/GU name, mobile, email) | ALREADY IMPLEMENTED |
| `JobProcessRoutingPage` (6 sheets + cancel dialog) | `AppBottomSheet` / `AppDialog` | **Manual `double.tryParse` * 100 (`_parseRupeesToPaise`) & `int.tryParse`, no `Form` / `AppValidators` inline validation** | **HIGH** |
| `AccountingOverviewPage` (Reverse Payment dialog) | `AlertDialog` + `Form` | Inline lambda instead of `AppValidators.nameValidator` | MEDIUM |
| `WorkerLedgerPage` / `StockMovementsPage` (Reverse dialogs) | `AlertDialog` + `Form` | Uses `AppValidators`, but wraps raw `AlertDialog` instead of frosted `AppDialog` | MEDIUM |

## 4. Existing Validators (`lib/core/validation/`)

- **ALREADY IMPLEMENTED**:
  - `AppValidators` (`app_validators.dart`, 730 lines): `requiredValidator`, `whitespaceValidator`, `maxLengthValidator`, `nameValidator`, `mobileNumberValidator` (Indian 10-digit & `+91` + E.164), `emailValidator`, `numericValidator`, `integerValidator`, `decimalValidator`, `positiveNumberValidator`, `parseQuantityExact` (BigInt exact), `quantityValidator`, `nonNegativeQuantityValidator`, `parseRupeesToPaiseExact` (BigInt zero-float exact), `amountValidator`, `nonNegativeAmountValidator`, `percentageValidator`, `dateValidator`, `dateRangeValidator`, `isoDateRangeValidator`, `duplicateValidator`, `hexColorValidator`, `pinValidator`, `recoveryKeyValidator`.
  - `ValidationLimits`, `ValidationErrorCode`, `ValidationResult` (`validation_error.dart`).
  - `ValidationLocalizer` (`validation_localizer.dart`): EN/GU mapping for `ValidationResult` & `DomainValidationException`.
  - `FormValidationHelper` (`form_validation_helper.dart`): scroll-to-first-invalid-field + focus management.
  - Domain calculators: `ProcessRoutingValidator`, `ProcessPricingCalculator`, `StockCalculator`, `LabourCalculator`.

## 5. Missing Validators & Validation Gaps

- **HIGH**: `JobProcessRoutingPage` uses floating-point `double.tryParse` (`_parseRupeesToPaise`) instead of `AppValidators.parseRupeesToPaiseExact` and lacks `Form` + `AppValidators` inline validation on Add Process, Reassign, Direct Transfer, Factory Return, Additional Charge, Record Payment, Confirm Receipt, and Cancel Process.
- **MEDIUM**: `AppValidators` lacks `minLengthValidator` and `exactLengthValidator` helpers, and there is no shared `AppInputFormatters` (`input_formatters.dart`) for digits-only, decimal-2-places, mobile, and HEX inputs.
- **MEDIUM**: `ValidationLocalizer.localizeDomainCode` is missing mappings for V1.3 Process Routing & Colour Master domain codes (`rate_override_reason_required`, `exceeds_dispatched_quantity`, `exceeds_held_quantity`, `unaccounted_quantity_remaining`, `duplicate_colour_name` / `duplicate_colour_master`, `invalid_charge_amount`, `overpayment_not_allowed`).

## 6. Shared Widget Inventory (`lib/core/widgets/`)

Already implemented (27 files): `AppScaffold`, `ResponsiveNavigation`, `AppDialog`, `AppBottomSheet`, `AppButton`, `AppIconButton`, `AppCard`, `AppMetricTile`, `AppTextField`, `AppDropdown`, `AppDatePicker`, `AppLoader`, `AppSkeletonBox`/`AppSkeletonList`, `AppEmptyState`, `AppErrorView`, `AppFeedback`, `AppGlassBackdrop`, `AppGlassSurface`, `AppHeading`, `AppStatusBadge`, `AppCheckbox`, `AppRadio`, `AppSwitch`, `AppText`, `AppDataTable`, `AppAnimatedNumber`, `AppColourSwatch`.

## 7. Duplicate Component & Bypass Inventory

| Severity | Finding | Location(s) |
|---|---|---|
| **HIGH** | Direct `ScaffoldMessenger.of(context).showSnackBar(...)` bypassing centralized messaging | `lib/features/lots/presentation/pages/lot_detail_page.dart:65` |
| **HIGH** | 5 raw `AlertDialog` widgets bypassing frosted-glass `AppDialog` | `accounting_overview_page.dart:71`, `worker_ledger_page.dart:54`, `security_settings_page.dart:111`, `security_reauth_dialog.dart:127`, `stock_movements_page.dart:114` |
| **HIGH** | Raw `e.toString()` shown directly in error messages (leaks exception text) | `accounting_overview_page.dart:130`, `worker_ledger_page.dart:139`, `stock_labour_settings_page.dart:94`, `stock_movements_page.dart:185` |
| **MEDIUM** | Raw `showDialog` + `Dialog` bypass for photo preview | `lib/features/lots/presentation/pages/lot_detail_page.dart:1284` |
| **MEDIUM** | Raw `CircularProgressIndicator` in feature widgets instead of `AppLoader` / inline loader | `lot_detail_page.dart:1261`, `app_lock_screen.dart:193`, `app_lock_gate.dart:176` |
| **LOW** | Repeated search field and section header boilerplate across feature pages | `lot_list_page.dart`, `worker_list_page.dart`, `process_list_page.dart`, `lot_detail_page.dart` |

## 8. Missing Common Components

1. `AppMessageService` (`lib/core/services/app_message_service.dart`) — centralized notification service with `success`, `error`, `warning`, `info`, `loading`, `dismiss`, `dismissAll`, Glassmorphism toast cards, duplicate throttling, responsive positioning, and clean abstraction over `toastification` (or safe fallback when Overlay/ToastificationWrapper is absent in isolated widget tests).
2. `AppConfirmationDialog` (`lib/core/widgets/app_confirmation_dialog.dart`) — dedicated semantic confirmation dialog helper with icon, tone (`destructive`, `warning`, `info`), and clear consequence messaging built on `AppDialog`.
3. `AppSuccessState` (`lib/core/widgets/app_success_state.dart`) — reusable full/inline success state widget.
4. `AppSearchField` (`lib/core/widgets/app_search_field.dart`) — consistent clearable search input with max-length guard.
5. `AppSectionHeader` (`lib/core/widgets/app_section_header.dart`) — consistent section heading with optional trailing action.
6. `AppInputFormatters` (`lib/core/validation/input_formatters.dart`) — centralized reusable `TextInputFormatter` presets.

## 9. Existing Notification Implementations

- `AppFeedback` (`lib/core/widgets/app_feedback.dart`): 43 call sites across 15 feature files. Uses plain `ScaffoldMessenger.maybeOf(context)?.showSnackBar(...)` with only `showSuccess`, `showError`, `showInfo` (no `showWarning`, no `loading`, no `dismiss`/`dismissAll`, no Glassmorphism toast cards, no desktop top-right positioning, no duplicate suppression).
- 1 direct `ScaffoldMessenger.of(context).showSnackBar` in `lot_detail_page.dart:65`.
- `AppFeedback` will be retained as a thin backwards-compatible facade delegating to `AppMessageService` so all 43 call sites immediately gain the new Glassmorphism notification system without breaking any existing callers or tests.

## 10. Workflow Risks

- **MEDIUM**: Floating-point `_parseRupeesToPaise` in `JobProcessRoutingPage` (`(double.tryParse * 100).round()`) could diverge from `AppValidators.parseRupeesToPaiseExact` on edge-case inputs (> 2 decimals, large numbers).
- **LOW**: All 12 end-to-end business scenarios need a dedicated consolidated QA test suite verifying every stage from Lot Creation -> Colour-Only -> Worker Assignment -> Multi-Variant -> Direct Transfer -> Factory Return -> Partial Split -> Dynamic Pricing -> Additional Charges & Deductions -> Worker Payments -> Negative Workflows in a single deterministic suite.

## 11. Database Integrity Risks

- **ALREADY IMPLEMENTED & VERIFIED**: Schema v6 (19 tables), `PRAGMA foreign_keys = ON`, `PRAGMA synchronous = FULL`, `PRAGMA journal_mode = WAL`, atomic `DatabaseTransactionRunner`, partial unique indexes (`client_request_id`, active names, single reversal).
- **LOW**: Need explicit regression tests verifying v5 -> v6 migration preserves all existing records (including null-HEX `design_colours`, `job_processes`, `process_handovers`, `payments`, `labour_entries`, `audit_logs`) and seeds `colour_master` idempotently.

## 12. Recommended Architecture

1. Add `toastification` (evaluated at latest stable `^3.2.2` on pub.dev, Dart 3 & multi-platform compatible) wrapped strictly behind `AppMessageService` (`lib/core/services/app_message_service.dart`). No feature module ever imports `toastification`.
2. Wrap `BusinessManagerApp` root with `ToastificationWrapper` and route all `AppFeedback.*` calls through `AppMessageService` with graceful `ScaffoldMessenger` fallback if an isolated unit/widget test pumps a bare `MaterialApp` without `ToastificationWrapper`.
3. Enhance `AppDialog` with optional icon, semantic tone, and scrollable content; add `AppConfirmationDialog`, `AppSuccessState`, `AppSearchField`, `AppSectionHeader`, and `AppLoader.inline`.
4. Migrate all 5 raw `AlertDialog` usages + 1 raw `showDialog` + 1 direct `ScaffoldMessenger` + raw `e.toString()` error leaks to the shared components and `AppMessageService`.
5. Harden `AppValidators` (`minLengthValidator`, `exactLengthValidator`, `AppInputFormatters`), extend `ValidationLocalizer` for V1.3 Process Routing codes, and migrate all 7 forms/dialogs in `JobProcessRoutingPage` from manual parsing to `Form` + `AppValidators` + `ValidationLocalizer`.

## 13. Files to Create

- `docs/v1.3/VALIDATION_UI_WORKFLOW_AUDIT.md`
- `docs/v1.3/VALIDATION_UI_WORKFLOW_IMPLEMENTATION_PLAN.md`
- `lib/core/services/app_message_service.dart`
- `lib/core/widgets/app_confirmation_dialog.dart`
- `lib/core/widgets/app_success_state.dart`
- `lib/core/widgets/app_search_field.dart`
- `lib/core/widgets/app_section_header.dart`
- `lib/core/validation/input_formatters.dart`
- `test/features/complete_workflow_qa_test.dart`
- `test/widget/shared_ui_and_messaging_test.dart`
- Final V1.3 reports (`VALIDATION_AUDIT_REPORT.md`, `SHARED_UI_COMPONENT_AUDIT.md`, `WORKFLOW_QA_REPORT.md`, `VALIDATION_UI_IMPLEMENTATION_REPORT.md`, `VALIDATION_TEST_RESULTS.md`, `VALIDATION_UI_CHANGELOG.md`)

## 14. Files to Modify

- `pubspec.yaml` (add `toastification`)
- `lib/app.dart` (wrap with `ToastificationWrapper`)
- `lib/core/widgets/app_dialog.dart`, `app_feedback.dart`, `app_loader.dart`, `widgets.dart`
- `lib/core/validation/app_validators.dart`, `validation_localizer.dart`, `validation.dart`
- `lib/l10n/app_en.arb`, `lib/l10n/app_gu.arb` (localized notification titles & V1.3 routing validation messages)
- `lib/features/lots/presentation/pages/lot_detail_page.dart`
- `lib/features/accounting/presentation/pages/accounting_overview_page.dart`, `worker_ledger_page.dart`
- `lib/features/stock_movements/presentation/pages/stock_movements_page.dart`
- `lib/features/security/presentation/pages/security_settings_page.dart`, `security_reauth_dialog.dart`
- `lib/features/settings/presentation/pages/stock_labour_settings_page.dart`
- `lib/features/process_routing/presentation/pages/job_process_routing_page.dart`

## 15. Testing Strategy

- Unit tests for extended `AppValidators`, `AppInputFormatters`, and `ValidationLocalizer`.
- Widget tests for `AppMessageService`, `AppDialog`, `AppConfirmationDialog`, `AppSuccessState`, `AppSearchField`, `AppSectionHeader` in Light Glass & Dark Glass + EN & GU.
- Complete 12-scenario Business Workflow QA integration test (`test/features/complete_workflow_qa_test.dart`) + DB v5 -> v6 migration & integrity verification.
- Full `flutter analyze`, full `flutter test`, and production release APK build (`flutter build apk --release --flavor prod -t lib/main_prod.dart`).

## 16. Migration and Compatibility Risks

- **Zero breaking schema changes**: Current schema is v6; all existing tables, foreign keys, indexes, and records remain untouched.
- **Zero breaking API changes**: `AppFeedback.showSuccess/showError/showInfo` stays intact and delegates to `AppMessageService`; `AppDialog.showConfirmation` stays intact and delegates cleanly.
