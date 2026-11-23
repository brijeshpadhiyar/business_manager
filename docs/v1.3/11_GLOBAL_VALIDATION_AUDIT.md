# StitchFlow V1.3 — Global Validation & Data Integrity Audit

**Audit Date:** 2026-11-23  
**Scope:** Every form, bottom sheet, dialog, filter bar, BLoC/Cubit, repository, domain calculator, and SQLite table in StitchFlow (`lib/features/**`, `lib/core/**`).  
**Baseline:** 102/102 existing unit, repository, database, and widget tests passing (`flutter test`).

---

## 1. Executive Summary

StitchFlow's database schema (`app_database.dart` + `schema_indexes.dart`) and core stock/labour calculators (`StockCalculator`, `LabourCalculator`, `LedgerCalculator`, `MemberProcessRateResolver`) already provide strong relational and financial foundations (idempotency via `client_request_id`, partial unique indexes, chronological reversal replay, rate locking).

However, a complete end-to-end audit across **14 data-entry surfaces**, **9 repositories**, and **12 BLoCs/Cubits** identified **31 concrete validation, UX, and data-integrity gaps** that must be closed for V1.3:

| Severity | Count | Key Themes |
| :--- | :---: | :--- |
| **Critical** | 5 | Floating-point silent rounding in financial inputs (`double.tryParse * 100`), integer overflow crash (`FormatException`) on huge rate inputs, `updateDesignColour` allowing `initialQuantity` reduction below committed stock (creating negative stock!), missing mobile validation on Worker & Business Profile, missing submit guards on Lot/Design/Colour bottom sheets. |
| **High** | 11 | Wrong error messages (`validationRequired` shown for negative/zero/non-numeric amounts), unvalidated date range ordering on Worker Ledger & silent mutation on Reports, missing repository-layer validation for phone/lengths/bounds, missing individual field validators on Settlement quantities, missing Recovery Key empty-vs-invalid validation. |
| **Medium** | 10 | Missing `AutovalidateMode` (errors don't clear smoothly on edit), no focus/scroll to first invalid field, missing length limits on names/notes/addresses/reasons, raw `e.toString()` / unlocalized `DomainValidationException` codes leaked to UI, missing submit guard on `WorkerAssignmentsPage` & reversal dialogs. |
| **Low** | 5 | Missing `FilteringTextInputFormatter` on integer inputs (`DamagedRepairPage`, Colour sheet), unvalidated `colourHex` format when supplied, unbounded search/filter strings, missing BLoC-layer format guards on `AppLockCubit` & `NotificationSettingsCubit`. |

---

## 2. Screen-by-Screen & Layer-by-Layer Audit Matrix

### A. Worker Management
Files audited:
- `lib/features/workers/presentation/pages/worker_form_page.dart`
- `lib/features/workers/presentation/pages/worker_assignments_page.dart`
- `lib/features/workers/presentation/bloc/worker_assignments_cubit.dart`
- `lib/features/workers/data/repositories/worker_repository_impl.dart`

| Finding ID | Location | Issue Category | Description & Risk |
| :--- | :--- | :--- | :--- |
| **W-01** | `WorkerFormPage` (`_phoneCtrl`) | Missing mobile validation | Accepts letters (`"abc"`), symbols, incomplete digits (`"123"`), or invalid prefixes with zero feedback. |
| **W-02** | `WorkerRepositoryImpl` (`createWorker`, `updateWorker`) | UI bypass | Direct repository calls do not validate phone format or field lengths (`name`, `address`, `notes`). |
| **W-03** | `WorkerFormPage` | Missing length limits & Form UX | No max-length validation on Name (120), Address (300), Notes (500); no `AutovalidateMode` after submit attempt; no focus/scroll to first invalid field. |
| **W-04** | `WorkerAssignmentsPage` | Repeated submission | `_assign` lacks an `_isAssigning` guard; rapid taps can send concurrent `assignProcess` requests before state refreshes. |
| **W-05** | Business Rule Check | Duplicate workers | Verified: Workers **may** legitimately share names or family mobile numbers. No uniqueness constraint is imposed on `members.name` or `members.phone`; preserve this rule. |

---

### B. Business Profile
Files audited:
- `lib/features/business_profile/presentation/pages/business_profile_page.dart`
- `lib/features/business_profile/presentation/bloc/business_profile_cubit.dart`
- `lib/features/business_profile/data/repositories/business_profile_repository_impl.dart`

| Finding ID | Location | Issue Category | Description & Risk |
| :--- | :--- | :--- | :--- |
| **BP-01** | `BusinessProfilePage` (`_phoneController`) | Missing mobile validation | Business phone accepts arbitrary text, letters, and invalid numbers. |
| **BP-02** | `BusinessProfileRepositoryImpl` (`updateProfile`) | UI bypass | Does not validate phone format or length bounds on `nameEn`, `nameGu`, `ownerName`, `address`. (Must retain `ArgumentError` for empty `nameEn`/`nameGu` per existing contract.) |
| **BP-03** | `BusinessProfileCubit` & `BusinessProfilePage` | Error localization & UX | Cubit exposes raw `e.toString()` instead of mapping `DomainValidationException` codes to localized messages; page lacks `AutovalidateMode` after submit and focus/scroll to first invalid field. |

---

### C. Inventory, Lots, Designs & Colours
Files audited:
- `lib/features/lots/presentation/pages/lot_list_page.dart`
- `lib/features/lots/presentation/pages/lot_detail_page.dart`
- `lib/features/lots/presentation/bloc/lot_list_cubit.dart`
- `lib/features/lots/presentation/bloc/lot_detail_cubit.dart`
- `lib/features/lots/data/repositories/lot_repository_impl.dart`

| Finding ID | Location | Issue Category | Description & Risk |
| :--- | :--- | :--- | :--- |
| **L-01** | `LotListPage` (`_showCreateLotSheet`) | Repeated submission | Save button has no `isSaving` state guard; double-taps trigger duplicate DB inserts. |
| **L-02** | `LotDetailPage` (`_showEditLotSheet`, `_showDesignSheet`, `_showColourSheet`) | Repeated submission | None of the 3 bottom sheets disable Save while a write is in progress. |
| **L-03** | `LotDetailPage` (`_showColourSheet` `parsePaise`) | Invalid decimal / silent rounding | Uses `double.tryParse(clean)` + `(parsed * 100).round()`. Silently rounds `250.999` to `251.00`, accepts scientific notation (`1e4`) and `Infinity`/`NaN`, and lacks upper-bound overflow protection. |
| **L-04** | `LotDetailPage` (`_showColourSheet` qty) | Invalid integer input | No `FilteringTextInputFormatter.digitsOnly`, no max-quantity bound, and empty vs non-positive share the same message. |
| **L-05** | `LotRepositoryImpl.updateDesignColour` | **Critical business-rule / negative stock** | Editing `initialQuantity` downwards does NOT check existing stock movements! If 100 pcs were created and 60 pcs were issued/damaged, editing `initialQuantity` to 40 leaves `physicalAvailableInHouse = -20` (negative stock!). Must be atomically validated inside the DB transaction. |
| **L-06** | `LotRepositoryImpl` & Cubits | UI bypass & length limits | No length limits on `lotNumber`, `title`, `designName`, `colourName`, `notes`, or `colourHex` validation. Cubits return raw `e.toString()`, relying on substring matching `.contains('UNIQUE')`. |

---

### D. Issue Work (Stock Issue)
Files audited:
- `lib/features/stock_movements/presentation/pages/stock_issue_page.dart`
- `lib/features/stock_movements/data/repositories/stock_movement_repository_impl.dart`
- `lib/features/stock_movements/domain/calculators/stock_calculator.dart`

| Finding ID | Location | Issue Category | Description & Risk |
| :--- | :--- | :--- | :--- |
| **SI-01** | `StockIssuePage` (`_parseRupeesToPaise`) | Invalid decimal / silent rounding | Uses `double.tryParse` + `(parsed * 100).round()`. Silently rounds >2 decimals, accepts scientific notation/`Infinity`/`NaN`, and lacks upper bound. |
| **SI-02** | `StockIssuePage` (`_overrideRateCtrl` validator) | Incorrect error message | Shows `validationRequired` ("This field is required.") even when user entered `-10`, `abc`, or `12.345`. |
| **SI-03** | `StockIssuePage` (`_qtyCtrl`) | Overflow / huge numeric input | No max quantity limit; pasting 20 digits causes `int.tryParse` to return `null` and silently resolve `_parsedQty` to `0`. |
| **SI-04** | `StockMovementRepositoryImpl.issueStock` | UI bypass | If `allowRateOverride == true` with `overrideRatePaise == null`, silently ignores the override flag instead of rejecting; no upper-bound check on `quantity` or `overrideRatePaise` (risk of `quantity * ratePaise` overflow) and no `transactionAtUtcMillis > 0` check. |
| **SI-05** | `StockIssuePage` | Form UX & length limits | Missing length limits on `overrideReason` and `notes`; no scroll/focus to invalid override fields when collapsed. |

---

### E. Return Work, Settlements, Repair & Reversals
Files audited:
- `lib/features/stock_movements/presentation/pages/stock_settlement_page.dart`
- `lib/features/stock_movements/presentation/pages/damaged_repair_page.dart`
- `lib/features/stock_movements/presentation/pages/stock_movements_page.dart`
- `lib/features/stock_movements/data/repositories/stock_movement_repository_impl.dart`

| Finding ID | Location | Issue Category | Description & Risk |
| :--- | :--- | :--- | :--- |
| **SR-01** | `StockSettlementPage` (good/damaged/lost/shortage) | Missing field validators & overflow | Individual quantity inputs have no `validator` and silently fall back to `0` on `int.tryParse` overflow (20+ digits). |
| **SR-02** | `StockSettlementPage` | Missing focus/scroll & length limits | No focus/scroll to `_reasonCtrl` when reason is required; no max length on `reason` / `notes`. |
| **SR-03** | `DamagedRepairPage` | Missing input guards & error mapping | Quantity field has no `digitsOnly` formatter or max bound; missing length limits on `reason`/`notes`; only maps `exceeds_damaged_stock` and shows raw English message for other codes; no `AutovalidateMode` after submit. |
| **SR-04** | `StockMovementsPage` (`_confirmReverse`) | Missing length limit & UX | Reversal reason dialog has no max length, no `AutovalidateMode`, and no submit lock during reversal execution. |
| **SR-05** | `StockMovementRepositoryImpl` (`recordSettlement`, `recordDamagedToGoodAdjustment`, `reverseMovement`) | UI bypass | Does not validate `transactionAtUtcMillis > 0` or max text lengths / numeric bounds on direct repository invocations. |

---

### F. Payments & Worker Ledger Adjustments
Files audited:
- `lib/features/accounting/presentation/pages/payment_form_page.dart`
- `lib/features/accounting/presentation/pages/worker_adjustment_form_page.dart`
- `lib/features/accounting/presentation/pages/worker_ledger_page.dart`
- `lib/features/accounting/presentation/bloc/worker_ledger_cubit.dart`
- `lib/features/accounting/data/repositories/accounting_repository_impl.dart`

| Finding ID | Location | Issue Category | Description & Risk |
| :--- | :--- | :--- | :--- |
| **P-01** | `PaymentFormPage` (`_parsePaise`) | Invalid decimal / silent rounding & wrong error | Uses `double.tryParse * 100 .round()`. Shows `validationRequired` even when user typed `0`, `-100`, `10.999`, or `abc`! |
| **P-02** | `WorkerAdjustmentFormPage` (`_parsePaise`) | Invalid decimal / silent rounding & wrong error | Identical floating-point bug and wrong `validationRequired` message for invalid/non-positive amounts. |
| **P-03** | `PaymentFormPage` & `WorkerAdjustmentFormPage` | Missing worker validator, length limits & error mapping | Worker dropdown lacks `validator`; `referenceNo`, `reason`, `notes` lack max length; `DomainValidationException` displays raw English `e.message` instead of localized text; no focus/scroll to first invalid field. |
| **P-04** | `WorkerLedgerPage` & `WorkerLedgerCubit` | **Missing date-range validation** | Users can select `From Date > To Date` with zero validation or warning; `WorkerLedgerCubit.loadLedger` silently queries an inverted range and displays an empty ledger! |
| **P-05** | `AccountingRepositoryImpl` | UI bypass | Does not enforce max amount bound (`maxAmountPaise`), `transactionAtUtcMillis > 0`, or length limits on `referenceNo`, `reason`, `notes`. |

---

### G. Process & Historical Rate Management
Files audited:
- `lib/features/processes/presentation/pages/process_form_page.dart`
- `lib/features/processes/data/repositories/process_repository_impl.dart`
- `lib/features/rates/presentation/pages/rate_form_page.dart`
- `lib/features/rates/data/repositories/rate_repository_impl.dart`
- `lib/features/rates/domain/services/member_process_rate_resolver.dart`

| Finding ID | Location | Issue Category | Description & Risk |
| :--- | :--- | :--- | :--- |
| **PR-01** | `RateFormPage` (`_parseRupeesToPaise`) | **Crash on huge numeric input** | `int.parse(match.group(1)!)` throws an unhandled `FormatException` when user types 20+ digits (overflowing 64-bit int). |
| **PR-02** | `RateFormPage` (`effectiveTo` < `effectiveFrom`) | Missing inline cross-field date validation | Date ordering error is only caught after tapping Save and hitting the repository, instead of showing an inline error on the `Effective To` picker immediately. |
| **PR-03** | `RateFormPage` | Incomplete error mapping & UX | Missing localization mapping for `rate_invalid_from_date`, `rate_invalid_to_date`, `rate_too_large`; no length limit on `notes`; no focus/scroll to invalid field. |
| **PR-04** | `ProcessFormPage` & `ProcessRepositoryImpl` | Missing length limits & UX | No length limits on `name` (100) and `description` (500); no `AutovalidateMode` after submit or focus/scroll. |

---

### H. Reports & Filters
Files audited:
- `lib/features/reports/presentation/widgets/report_filter_bar.dart`
- `lib/features/reports/presentation/bloc/reports_cubit.dart`
- `lib/features/reports/presentation/pages/reports_page.dart`
- `lib/features/reports/presentation/pages/daily_summary_page.dart`

| Finding ID | Location | Issue Category | Description & Risk |
| :--- | :--- | :--- | :--- |
| **R-01** | `ReportsCubit.setCustomDateRange` & `ReportFilterBar` | Silent date-range mutation | When user selects `To Date < From Date`, `ReportsCubit` silently rewrites `to = endOfIstDay(from)` without informing the user. Should reject inverted custom ranges with a clear inline localized date-range error on `ReportFilterBar` (and preserve valid previous filter / allow fixing). |
| **R-02** | `ReportFilterBar` | Unbounded search input | Search text input has no max length guard or whitespace normalization awareness. |

---

### I. Authentication, Security & Settings
Files audited:
- `lib/features/security/presentation/pages/pin_setup_page.dart`
- `lib/features/security/presentation/pages/pin_recovery_page.dart`
- `lib/features/security/presentation/pages/app_lock_screen.dart`
- `lib/features/security/presentation/widgets/security_reauth_dialog.dart`
- `lib/features/security/presentation/bloc/app_lock_cubit.dart`
- `lib/features/security/data/repositories/secure_storage_security_repository.dart`
- `lib/features/notifications/presentation/bloc/notification_settings_cubit.dart`
- `lib/features/notifications/data/repositories/notification_settings_repository.dart`

| Finding ID | Location | Issue Category | Description & Risk |
| :--- | :--- | :--- | :--- |
| **S-01** | `PinRecoveryPage` | Missing empty vs format distinction & Form UX | Recovery key field is not inside a `Form`, shows the same generic invalid message when empty vs malformed, and lacks inline `errorText` on the `AppTextField`. |
| **S-02** | `AppLockCubit` | BLoC-layer format guard | `enablePin` and `changePin` rely solely on repository `ArgumentError`; should also validate PIN & recovery key formats cleanly at BLoC boundary. |
| **S-03** | `NotificationSettingsCubit` / `NotificationSettingsRepository` | Settings bounds validation | No explicit clamping/validation of persisted or updated `pendingWorkDaysThreshold` (1..365), `workerSettlementMinPaise` (>=0), `backupReminderIntervalDays` (1..365), `hour` (0..23), `minute` (0..59). |

---

## 3. Summary of Preserved Business Rules & Invariants

1. **No Existing Data Mutated or Reset:** Zero destructive migrations, zero automatic merging or deletion of existing records.
2. **All Existing Calculations Preserved:** `StockCalculator`, `LabourCalculator`, `LedgerCalculator`, and `ReportsAnalyticsCalculator` formulas remain untouched.
3. **Optional Fields Remain Optional:** Worker phone/address/notes, Business owner/phone/address, Lot title/notes, Payment reference/notes, Rate effectiveTo/notes remain optional.
4. **Legitimate Shared Worker Data Allowed:** Workers sharing a name or family mobile number are never falsely blocked.
5. **Historical Rate Locking Preserved:** Rates referenced by `stock_movements` remain strictly immutable.
6. **Zero New Dependencies:** Built cleanly in pure Dart + Flutter Material 3 (`material_ui`) + existing `intl` / ARB localization.
