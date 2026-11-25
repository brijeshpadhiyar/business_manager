# StitchFlow V1.3 – Hardening, Shared UI & Workflow QA Implementation Plan

**Date:** 2026-11-24  
**Based On:** `docs/v1.3/VALIDATION_UI_WORKFLOW_AUDIT.md`

---

## Execution Stages

### Stage 1 – Shared Common UI Components & `AppMessageService` (Phases 1 & 2)
1. Add `toastification` (`^3.2.2`) to `pubspec.yaml` and verify dependency resolution with `material_ui: ^1.11.1` & Flutter SDK.
2. Wrap `BusinessManagerApp` in `lib/app.dart` with `ToastificationWrapper`.
3. Create `lib/core/services/app_message_service.dart` providing:
   - `AppMessageService.success`, `error`, `warning`, `info`, `loading`, `dismiss`, `dismissAll`
   - Glassmorphism toast cards built with `AppSurfaceTokens`, `AppColors`, `AppRadius`, `AppSpacing`, Light/Dark Glass contrast, close button, optional action button, responsive top (mobile) / top-right (desktop) alignment, and rapid-duplicate throttling.
   - Safe fallback when an isolated widget test does not wrap `ToastificationWrapper`.
4. Update `lib/core/widgets/app_feedback.dart` to delegate all calls (`showSuccess`, `showError`, `showWarning`, `showInfo`) to `AppMessageService` so all 43 existing call sites automatically upgrade.
5. Upgrade `AppDialog` (optional icon, tone, scrollable content) and `AppLoader` (add `AppLoader.inline` for inline spinners).
6. Create missing shared widgets in `lib/core/widgets/` and export via `widgets.dart`:
   - `app_confirmation_dialog.dart` (`AppConfirmationDialog`)
   - `app_success_state.dart` (`AppSuccessState`)
   - `app_search_field.dart` (`AppSearchField`)
   - `app_section_header.dart` (`AppSectionHeader`)

### Stage 2 – Migrate Duplicate Dialogs, SnackBars & Raw Exception Leaks (Phase 1.3 & 2.6)
1. Replace direct `ScaffoldMessenger.of(context).showSnackBar` and raw `showDialog`/`Dialog` + `CircularProgressIndicator` in `lot_detail_page.dart`.
2. Replace all 5 raw `AlertDialog` usages with frosted-glass `AppDialog`:
   - `accounting_overview_page.dart`
   - `worker_ledger_page.dart`
   - `stock_movements_page.dart`
   - `security_settings_page.dart`
   - `security_reauth_dialog.dart`
3. Replace raw `e.toString()` user error leaks with `ValidationLocalizer.localizeDomainCode` / localized unexpected error fallback in `accounting_overview_page.dart`, `worker_ledger_page.dart`, `stock_labour_settings_page.dart`, and `stock_movements_page.dart`.

### Stage 3 – Centralized Validation Hardening & Localization (Phases 3, 4 & 7)
1. Add `minLengthValidator` and `exactLengthValidator` to `AppValidators` and create `lib/core/validation/input_formatters.dart` (`AppInputFormatters`).
2. Add EN & GU ARB keys in `lib/l10n/app_en.arb` and `lib/l10n/app_gu.arb` for notification titles (Success/Error/Warning/Info) and V1.3 Process Routing domain errors, then regenerate `flutter gen-l10n`.
3. Extend `ValidationLocalizer.localizeDomainCode` to cover all V1.3 Process Routing and Colour Master domain codes.
4. Upgrade all 6 bottom sheets + Cancel dialog in `job_process_routing_page.dart` to use `Form` + `AppValidators.parseQuantityExact` / `AppValidators.parseRupeesToPaiseExact` / `AppValidators.requiredValidator` / `ValidationLocalizer` (eliminating floating-point `double.tryParse`).

### Stage 4 – Complete 12-Scenario Business Workflow QA & Shared UI Tests (Phases 5 & 6)
1. Create `test/features/complete_workflow_qa_test.dart` covering all 12 required scenarios:
   - Scenario 1: Lot Creation (multiple designs + colours + totals)
   - Scenario 2: Colour-Only Lot (`__NO_DESIGN__` sentinel hidden in UI)
   - Scenario 3: Worker Assignment (500 pcs / D-101 Red 200 -> Dharmesh 60, Ramesh 40)
   - Scenario 4: Multiple Variants assigned to same worker
   - Scenario 5: Direct Worker Transfer (100 -> 60 Packing + 40 remain)
   - Scenario 6: Factory Return (Good + Damaged, Partial & Full)
   - Scenario 7: Partial Split (500 -> 300 Direct Transfer + 150 Factory Return + 50 Pending)
   - Scenario 8: Dynamic Pricing (Default rate, Override + mandatory reason, Default rate update, Historical rate preservation, Pricing units)
   - Scenario 9: Additional Charges & Deductions (₹2,950 + ₹150 - ₹50 = ₹3,050 in exact integer paise)
   - Scenario 10: Worker Payments (Pending -> Partial -> Full -> Multiple payments -> Duplicate protection)
   - Scenario 11: Full End-to-End Production Lifecycle
   - Scenario 12: Negative Workflow Testing (zero/negative/excess/invalid/missing/duplicate)
   - Plus Database v5 -> v6 additive migration & foreign-key integrity verification.
2. Create `test/widget/shared_ui_and_messaging_test.dart` testing `AppMessageService`, `AppConfirmationDialog`, `AppDialog`, `AppSuccessState`, `AppSearchField`, `AppSectionHeader`, and `AppValidators` extensions in Light Glass & Dark Glass + EN & GU.

### Stage 5 – Final Verification, Release APK & Documentation (Phase 8)
1. Run `flutter analyze` (target: 0 issues).
2. Run full `flutter test` suite (target: 100% pass).
3. Run `flutter build apk --release --flavor prod -t lib/main_prod.dart`.
4. Write all 6 final documentation reports in `docs/v1.3/`:
   - `VALIDATION_AUDIT_REPORT.md`
   - `SHARED_UI_COMPONENT_AUDIT.md`
   - `WORKFLOW_QA_REPORT.md`
   - `VALIDATION_UI_IMPLEMENTATION_REPORT.md`
   - `VALIDATION_TEST_RESULTS.md`
   - `VALIDATION_UI_CHANGELOG.md`
