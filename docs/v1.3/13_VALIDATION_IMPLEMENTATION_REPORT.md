# StitchFlow V1.3 — Global Validation & Data Integrity Implementation Report

**Document:** `docs/v1.3/13_VALIDATION_IMPLEMENTATION_REPORT.md`  
**Phase:** Additional Phase — Global Validation & Data Integrity (V1.3)  
**Audit Reference:** [11_GLOBAL_VALIDATION_AUDIT.md](./11_GLOBAL_VALIDATION_AUDIT.md)  
**Rules Reference:** [12_VALIDATION_RULES.md](./12_VALIDATION_RULES.md)  
**Test Results Reference:** [14_VALIDATION_TEST_RESULTS.md](./14_VALIDATION_TEST_RESULTS.md)  

---

## 1. Executive Summary

This phase audited and hardened data validation across the complete StitchFlow V1.3 application — spanning all **14 data-entry surfaces**, **9 domain repositories**, **12 BLoCs/Cubits**, and the **Premium Glass Light & Dark design system** — with **zero new external dependencies**, **zero destructive database migrations**, and **100% preservation of existing valid records and business calculations**.

Key architectural outcomes:
1. **Centralized Validation Architecture (`lib/core/validation/`):** Pure-Dart, dependency-free reusable validators, exact `BigInt`-backed financial/quantity parsers, bilingual localizer (`ValidationLocalizer`), and first-invalid-field focus/scroll helper (`FormValidationHelper`).
2. **Indian & International Mobile Validation:** Consistent validation across Worker Management and Business Profile for 10-digit Indian mobile numbers (`[6-9]\d{9}`), `+91` formatted numbers, and country-code-aware E.164 international numbers — without silently truncating or auto-prepending `+91`, and without claiming offline OTP/ownership verification.
3. **Exact Numeric & Financial Integrity:** Eliminated floating-point rounding drift (`double.tryParse * 100`) and `int.parse` overflow crashes across payments, adjustments, rates, lots, and stock movements by parsing decimal strings directly to exact integer paise via `BigInt` and rejecting `>2` decimal places, `NaN`, `Infinity`, scientific notation, negatives, and out-of-range values.
4. **Atomic Negative-Stock Prevention:** Closed a critical repository gap in `LotRepositoryImpl.updateDesignColour` by computing live `StockCalculator` balances inside the write transaction and blocking `initialQuantity` reductions below committed/issued/damaged stock (`quantity_below_committed_stock`).
5. **Multi-Layer Enforcement & Bilingual UX:** Every rule is enforced at UI/Form, BLoC/Cubit, and Repository/Transaction layers, with 33 new English and Gujarati localization keys and WCAG-AA error styling in both Light and Dark Glass themes.

---

## 2. Centralized Validation Architecture

Created under `lib/core/validation/` with zero third-party package additions:

| File | Responsibility |
| --- | --- |
| `lib/core/validation/validation_error.dart` | Defines `ValidationLimits` (max lengths, max quantity `10,000,000`, max amount `₹10,00,00,000.00` / `10,000,000,000` paise, epoch date bounds), `ValidationErrorCode` enum, and immutable `ValidationResult`. |
| `lib/core/validation/app_validators.dart` | Pure reusable validators: `requiredValidator`, `whitespaceValidator`, `maxLengthValidator`, `nameValidator`, `mobileNumberValidator`, `normalizeMobileForValidation`, `emailValidator`, `numericValidator`, `integerValidator`, `decimalValidator`, `positiveNumberValidator`, `quantityValidator`, `nonNegativeQuantityValidator`, `parseQuantityExact`, `amountValidator`, `nonNegativeAmountValidator`, `parseRupeesToPaiseExact`, `percentageValidator`, `dateValidator`, `dateRangeValidator`, `isoDateRangeValidator`, `duplicateValidator`, `hexColorValidator`, `pinValidator`, `recoveryKeyValidator`. |
| `lib/core/validation/validation_localizer.dart` | Maps every `ValidationErrorCode` and `DomainValidationException` code cleanly to `AppLocalizations` (English & Gujarati) via `localize`, `wrap`, `localizeDomainException`, and `localizeDomainCode`. |
| `lib/core/validation/form_validation_helper.dart` | Provides `ValidatedFieldAnchor`, `FormValidationHelper.validateAndFocusFirstInvalid`, and `scrollToAnchor` to move focus and scroll the first invalid input into view on failed form submission. |
| `lib/core/validation/validation.dart` | Barrel export for clean imports across features. |

---

## 3. Audited Screens, Fields & Implemented Validation Rules

### A. Worker Management & Assignments
- **`lib/features/workers/presentation/pages/worker_form_page.dart`**
  - **Worker Name (Required):** `nameValidator` (trimmed, rejects empty & whitespace-only, max 120 chars).
  - **Mobile Number (Optional):** `mobileNumberValidator(isRequired: false)` (Indian 10-digit `[6-9]\d{9}`, `+91`, or country-code-aware E.164 international; rejects letters/unsupported symbols; trims without silently modifying/truncating or auto-prepending `+91`).
  - **Address (Optional):** `maxLengthValidator(300)` + rejects whitespace-only non-empty input.
  - **Notes (Optional):** `maxLengthValidator(500)`.
  - **UX:** `AutovalidateMode.onUserInteraction` enabled after first submit; focus/scroll to first invalid field; submit lock via `isSubmitting`.
- **`lib/features/workers/presentation/pages/worker_assignments_page.dart`**
  - Added `_isAssigning` re-entry lock to prevent duplicate process-assignment submissions from rapid taps.
- **`lib/features/workers/data/repositories/worker_repository_impl.dart`**
  - Enforces `_validateWorkerInputs` on both `createWorker` and `updateWorker` (name, phone, address, notes).
  - **Preserved Business Rule:** Legitimate workers sharing a name or family mobile number continue to be permitted; no overly restrictive uniqueness constraint was added.

### B. Business Profile
- **`lib/features/business_profile/presentation/pages/business_profile_page.dart`**
  - **Business Name (English) & (Gujarati) (Required):** `nameValidator(maxLength: 120)`.
  - **Tagline (Optional):** `maxLengthValidator(160)`.
  - **Phone (Optional):** `mobileNumberValidator(isRequired: false)`.
  - **Address (Optional):** `maxLengthValidator(300)`.
  - **UX:** `AutovalidateMode` after first submit, focus/scroll helper, localized domain error banner via `ValidationLocalizer`.
- **`lib/features/business_profile/presentation/bloc/business_profile_cubit.dart` & `business_profile_repository_impl.dart`**
  - Preserves existing `ArgumentError` contract for empty EN/GU names while adding `DomainValidationException` guards for phone format and max lengths; Cubit surfaces structured error codes cleanly.

### C. Inventory & Lots (Lots, Designs, Colours)
- **`lib/features/lots/presentation/pages/lot_list_page.dart`**
  - Lot number/name (`nameValidator`, max 80), notes (`maxLengthValidator(500)`), `isSaving` submit lock preventing repeated creation taps, localized duplicate/domain errors.
- **`lib/features/lots/presentation/pages/lot_detail_page.dart`**
  - Hardened all 3 modal sheets (Add/Edit Design, Add/Edit Design Colour, Edit Lot) with `isSaving` duplicate-tap locks, `AutovalidateMode`, exact `parseQuantityExact` (positive integer `1..10,000,000`), exact `parseRupeesToPaiseExact` (non-negative up to 2 decimals, max `₹10,00,00,000.00`), hex colour validation (`hexColorValidator`), and localized `quantity_below_committed_stock` feedback.
- **`lib/features/lots/presentation/bloc/lot_list_cubit.dart` & `lot_detail_cubit.dart`**
  - Cleanly propagate `DomainValidationException.code` to the UI.
- **`lib/features/lots/data/repositories/lot_repository_impl.dart`**
  - Preserves existing `ArgumentError` and SQLite `UNIQUE` contracts.
  - Adds length, date, max-quantity, max-price, and `hexColor` guards.
  - **Critical Atomic Negative-Stock Guard:** Inside the `updateDesignColour` database transaction, recomputes balances with `StockCalculator` against the candidate `initialQuantity`; if `physicalAvailableInHouse < 0 || totalGoodPhysicalStock < 0`, aborts atomically with `DomainValidationException('quantity_below_committed_stock', ...)`.

### D. Issue Work, Return/Settlement & Damaged Repair
- **`lib/features/stock_movements/presentation/pages/stock_issue_page.dart`**
  - Validates Lot, Design, Colour, Process, Worker selections, positive integer quantity bounded by live `availableGoodStock`, date, optional override rate (`parseRupeesToPaiseExact`, non-negative, <=2 decimals) + required override reason when override is enabled, and notes max length. Prevents duplicate submissions via `_isSubmitting` + idempotency key (`clientRequestId`).
- **`lib/features/stock_movements/presentation/pages/stock_settlement_page.dart`**
  - Validates original issue reference, non-negative good/damaged/missing integer quantities with combined total > 0 and `<= remainingPending`, valid settlement date, and notes length; preserves partial return logic and historical rate locking.
- **`lib/features/stock_movements/presentation/pages/damaged_repair_page.dart`**
  - Validates positive integer repair quantity `<= damagedStock`, date, and reason/notes length with submit lock.
- **`lib/features/stock_movements/presentation/pages/stock_movements_page.dart`**
  - Uses `ValidationLocalizer` for consistent localized domain error display across movement operations.
- **`lib/features/stock_movements/data/repositories/stock_movement_repository_impl.dart`**
  - Enforces upper bounds on quantity (`10,000,000`), rate (`maxAmountPaise`), valid epoch dates, and text lengths across `issueStock`, `recordSettlement`, and `recordDamagedToGoodAdjustment`.
  - Fixed `allowRateOverride` edge case: enabling override with `overrideRatePaise == null` now throws `DomainValidationException('invalid_rate', ...)` instead of silently falling back.
  - Preserves atomic transaction stock checks (`insufficient_good_stock`, `exceeds_pending_quantity`, `exceeds_damaged_stock`) and `clientRequestId` idempotency.

### E. Payments, Adjustments & Worker Ledger
- **`lib/features/accounting/presentation/pages/payment_form_page.dart`**
  - Replaced float-based parsing (`double.tryParse * 100`) and incorrect `validationRequired` error on `0` with exact `amountValidator` / `parseRupeesToPaiseExact` (strictly `> 0`, max 2 decimals, no silent rounding, safe overflow rejection).
  - Validates Worker selection, payment mode, date, reference max length (100), and notes max length (500).
- **`lib/features/accounting/presentation/pages/worker_adjustment_form_page.dart`**
  - Validates positive exact decimal amount (`amountValidator`), required non-whitespace reason (`requiredValidator` + max 300), and date.
- **`lib/features/accounting/presentation/pages/worker_ledger_page.dart` & `worker_ledger_cubit.dart`**
  - Added `dateRangeErrorCode` to `WorkerLedgerState` to reject inverted date filters (`fromUtcMillis > toUtcMillis`) with inline localized feedback and localized reversal dialog validation.
- **`lib/features/accounting/data/repositories/accounting_repository_impl.dart`**
  - Enforces `amount_too_large`, `invalid_date`, and field length bounds inside `recordPayment` and `recordAdjustment`, preserving existing idempotency and historical settlement calculations.

### F. Process & Rate Management
- **`lib/features/processes/presentation/pages/process_form_page.dart` & `process_repository_impl.dart`**
  - Validates Process Name (`nameValidator`, max 100) and Description (`maxLengthValidator(500)`), preserving case-insensitive duplicate checks.
- **`lib/features/rates/presentation/pages/rate_form_page.dart` & `rate_repository_impl.dart`**
  - Fixed `int.parse` crash on huge inputs by switching to exact `nonNegativeAmountValidator` / `parseRupeesToPaiseExact`.
  - Added inline Effective To >= Effective From date-range validation (`isoDateRangeValidator`), notes max length (500), and repository-level `rate_too_large` & length guards.
  - Preserves historical rate locking (`rate_locked_by_history`) and overlapping effective-range protection.

### G. Reports & Filters
- **`lib/features/reports/presentation/bloc/reports_cubit.dart` & `report_filter_bar.dart`**
  - Added `dateRangeErrorCode` to `ReportsState`. Custom date ranges with `end < start` are now explicitly rejected with inline localized error feedback instead of silently mutating the end date.
  - Bounded `searchQuery` length safely without breaking existing search UX.

### H. Authentication, Security & Notification Settings
- **`lib/features/security/presentation/pages/pin_recovery_page.dart` & `app_lock_cubit.dart`**
  - Distinguishes empty (`recoveryKeyRequired`) vs malformed (`invalidRecoveryKey`) inline recovery key errors.
  - Hardened `AppLockCubit.enablePin` and `changePin` with `pinValidator` (4–6 digits) and `recoveryKeyValidator` while preserving all existing PBKDF2/lockout protections.
- **`lib/features/notifications/presentation/bloc/notification_settings_cubit.dart`**
  - Sanitizes/clamps reminder day thresholds (`1..365`), minimum pending paise (`>= 0`), reminder hour (`0..23`), and minute (`0..59`) before persisting.

---

## 4. Mobile Number Validation Rules (Indian & International)

Implemented in `AppValidators.mobileNumberValidator` & `normalizeMobileForValidation`:
- **Normalization (validation-only):** Strips whitespace, hyphens `-`, parentheses `()`, and dots `.` before checking; user input is **trimmed only** on save — never silently truncated and never auto-prefixed with `+91`.
- **Character Check:** Rejects letters, symbols, misplaced `+`, or `++` with `mobileInvalidChars`:
  - EN: `Mobile number contains invalid characters.`
  - GU: `મોબાઇલ નંબરમાં અમાન્ય અક્ષરો છે.`
- **Indian Mobile Rules (default & `+91`):**
  - Accepts 10 digits starting with `6–9` (`^[6-9]\d{9}$`), or `+91` followed by `^[6-9]\d{9}$`.
  - Rejects `<10` digits, `>10` digits (including leading `0`), or prefixes `0–5` with `mobileInvalidIndian`:
    - EN: `Enter a valid 10-digit mobile number.`
    - GU: `માન્ય 10 અંકનો મોબાઇલ નંબર દાખલ કરો.`
- **International E.164 Rules (non-`+91` starting with `+`):**
  - Country-code-aware E.164 check (`^\+[1-9]\d{6,14}$`, 7–15 digits total); rejects malformed codes with `mobileInvalidInternational`.
- **Offline-First Honesty:** Validation verifies structural syntax only and makes no claim of OTP, SIM, or ownership verification.

---

## 5. Form UX & Premium Glass Design System Integration

- **`lib/core/design_system/app_theme.dart`**
  - Light Glass error color: `AppColors.lightDamaged` (`#B91C1C`) for WCAG-AA contrast on translucent light surfaces.
  - Dark Glass error color: `#FCA5A5` on `#7F1D1D` `errorContainer` for high-contrast legibility on dark frosted glass.
  - `InputDecorationTheme`: `errorMaxLines: 3` (ensuring Gujarati error text wraps cleanly at 360dp with zero overflow), crisp `errorBorder` (`1.3px`) and `focusedErrorBorder` (`1.8px`).
- **`lib/core/widgets/app_text_field.dart` & `app_dropdown.dart`**
  - Added `fieldKey`, `maxLength`, `showCounter`, and `maxLengthEnforcement: MaxLengthEnforcement.none` so overlong user input triggers a clear inline error instead of silently truncating text.
  - Added `errorText` and `autovalidateMode` support on `AppDropdown`.
- **Validation Timing & Focus:**
  - Untouched forms stay clean until submission; after the first failed submit attempt, `AutovalidateMode.onUserInteraction` clears each field's error immediately as the user fixes it.
  - `FormValidationHelper.validateAndFocusFirstInvalid` focuses and scrolls the first invalid field into view while preserving all valid user-entered values.

---

## 6. Localization Coverage (English & Gujarati)

- Added **33 new ARB keys** to both `lib/l10n/app_en.arb` and `lib/l10n/app_gu.arb` and regenerated `lib/l10n/generated/app_localizations*.dart` via `flutter gen-l10n`.
- Zero hardcoded validation strings in widgets, Cubits, or repositories — domain exceptions carry machine-readable codes mapped through `ValidationLocalizer`.
- Verified via unit tests (`app_validators_test.dart`) that **100% of `ValidationErrorCode.values`** and all mapped `DomainValidationException` codes resolve to non-empty English and Gujarati messages, and verified via widget tests at `360×800` dp that Gujarati error text wraps with zero RenderFlex overflow.

---

## 7. Multi-Layer Enforcement Matrix

| Domain / Operation | Layer 1: UI / Form | Layer 2: BLoC / Cubit | Layer 3: Repository / Transaction | Layer 4: SQLite / Drift |
| --- | --- | --- | --- | --- |
| Worker Create / Edit | `WorkerFormPage` (`name`, `mobile`, lengths, focus/scroll, lock) | `WorkerListCubit` / `WorkerDetailCubit` | `WorkerRepositoryImpl._validateWorkerInputs` | Non-null constraints preserved |
| Business Profile | `BusinessProfilePage` (`nameEn/Gu`, `mobile`, lengths) | `BusinessProfileCubit` (maps domain codes) | `BusinessProfileRepositoryImpl` (`ArgumentError` + phone/length guards) | Singleton table constraints |
| Lots / Designs / Colours | `LotListPage` & `LotDetailPage` (exact qty/paise, hex, locks) | `LotListCubit` / `LotDetailCubit` | `LotRepositoryImpl` (bounds + **atomic negative-stock guard** on `updateDesignColour`) | `UNIQUE` constraints preserved |
| Stock Issue / Return / Repair | `StockIssuePage`, `StockSettlementPage`, `DamagedRepairPage` | Movement Cubits + `clientRequestId` | `StockMovementRepositoryImpl` (atomic balances, strict override, bounds, idempotency) | FK & check constraints preserved |
| Payments & Adjustments | `PaymentFormPage`, `WorkerAdjustmentFormPage` (exact `>0` paise) | `WorkerLedgerCubit` (range check + codes) | `AccountingRepositoryImpl` (bounds, dates, lengths, idempotency) | Ledger integrity constraints preserved |
| Processes & Rates | `ProcessFormPage`, `RateFormPage` (exact `>=0` paise, date order) | Process & Rate Cubits | `ProcessRepositoryImpl`, `RateRepositoryImpl` (bounds, overlap, rate lock) | Existing constraints preserved |
| Reports & Ledger Filters | `ReportFilterBar`, `WorkerLedgerPage` (inline date-range error) | `ReportsCubit`, `WorkerLedgerCubit` (rejects `end < start`) | Read-only bounded queries | N/A |
| Security & Notifications | `PinRecoveryPage`, PIN/Notification settings UI | `AppLockCubit` (PIN/recovery format), `NotificationSettingsCubit` (clamped bounds) | Secure storage / prefs | Existing PBKDF2 & lockout preserved |

---

## 8. Known Exceptions & Conscious Scope Decisions

1. **Email Field:** `AppValidators.emailValidator` is implemented, localized (EN/GU), and unit-tested in the centralized validation system for future extensibility, though no V1.3 database entity currently contains an email column.
2. **Offline-First Mobile Validation:** Validates Indian 10-digit, `+91`, and E.164 international formats syntactically only; does not perform OTP, carrier, or ownership checks.
3. **Zero Destructive DB Migrations:** All existing valid database records remain untouched; no schema migration or automatic merging/deletion of legacy duplicate records was introduced.
4. **Shared Worker Names & Family Phones:** Deliberately allowed per existing textile workshop business rules; duplicate prevention applies only where unique business identifiers exist (e.g., Lot/Design/Colour, Process names, overlapping Rate windows, `clientRequestId` idempotency).
