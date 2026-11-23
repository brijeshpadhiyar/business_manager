# StitchFlow V1.3 — Global Validation Test Results

**Document:** `docs/v1.3/14_VALIDATION_TEST_RESULTS.md`  
**Phase:** Additional Phase — Global Validation & Data Integrity (V1.3)  
**Implementation Reference:** [13_VALIDATION_IMPLEMENTATION_REPORT.md](./13_VALIDATION_IMPLEMENTATION_REPORT.md)  

---

## 1. Execution Summary

| Verification Gate | Command | Result | Duration |
| --- | --- | --- | --- |
| **Static Analysis** | `flutter analyze` | **PASS — No issues found!** (0 errors, 0 warnings, 0 infos) | 6.5s |
| **Full Automated Test Suite** | `flutter test` | **PASS — 129 / 129 tests passed** (0 failures, 0 skipped) | 01:24 |

### Test Suite Breakdown

| Category | Test Files | Tests | Status |
| --- | --- | --- | --- |
| Existing V1.0–V1.3 Regression Suite | Existing unit, repository, BLoC, integration & widget suites | **102** | **102 / 102 PASSED** |
| New Centralized Validator Unit Tests | `test/unit/app_validators_test.dart` | **16** | **16 / 16 PASSED** |
| New Multi-Layer BLoC / Repo / DB Tests | `test/features/validation_multi_layer_test.dart` | **6** | **6 / 6 PASSED** |
| New Form UX / Localization / Glass Theme Widget Tests | `test/widget/validation_forms_ui_test.dart` | **5** | **5 / 5 PASSED** |
| **Total** | **All suites** | **129** | **129 / 129 PASSED** |

---

## 2. Detailed New Validation Test Inventory

### A. `test/unit/app_validators_test.dart` (16 Tests)

1. `Required, Whitespace & Name Validators` — `rejects null, empty, and whitespace-only values` (EN & GU inputs).
2. `Required, Whitespace & Name Validators` — `whitespaceValidator allows empty optional values but rejects spaces-only`.
3. `Required, Whitespace & Name Validators` — `nameValidator enforces required and maxLength cleanly` (120-char limit, bilingual names).
4. `Indian & International Mobile Number Validation` — `accepts valid 10-digit Indian mobile numbers and formatting` (`6–9` prefixes, spaces, hyphens, parentheses, `+91`).
5. `Indian & International Mobile Number Validation` — `accepts valid country-code-aware international E.164 numbers` (`+1`, `+44`, `+971`).
6. `Indian & International Mobile Number Validation` — `rejects incomplete, invalid-prefix, letters, and unsupported chars` (9/11 digits, leading `0`, prefixes `1`/`5`, `+91 5...`, letters, `@`, `*`, `++`, malformed E.164).
7. `Email & Percentage Validators` — `validates email addresses accurately` (empty optional/required, valid, missing TLD, double dots).
8. `Email & Percentage Validators` — `validates percentages between 0 and 100` (`0`, `100`, `12.5`, `-1`, `100.01`, `12.345`).
9. `Exact Numeric, Quantity & Financial Validation` — `quantityValidator rejects zero, negative, decimals, letters, and huge overflow` (`0`, `-5`, `10.5`, `1e5`, 24-digit overflow, max cap).
10. `Exact Numeric, Quantity & Financial Validation` — `parseRupeesToPaiseExact avoids float drift, rejects >2 decimals & overflow` (`19.99 -> 1999`, `250.5 -> 25050`, `.50 -> 50`, `0` vs non-negative `0`, `-10`, `10.999`, `NaN`, `Infinity`, `1e5`, `₹100`, 24-digit overflow).
11. `Date, Date Range, Duplicate & Security Validators` — `validates epoch dates and ordered date ranges` (valid order, inverted epoch range, inverted ISO range, invalid calendar date `2026-02-30`).
12. `Date, Date Range, Duplicate & Security Validators` — `duplicateValidator checks case-insensitively with exclude support`.
13. `Date, Date Range, Duplicate & Security Validators` — `pinValidator and recoveryKeyValidator enforce strict formats` (`1234`, `123456`, `123`, `12ab`, whitespace, `INVALID!`, `WXYZ-2345`).
14. `Bilingual Localization Coverage (EN & GU)` — `every ValidationErrorCode produces non-empty distinct EN & GU messages`.
15. `Bilingual Localization Coverage (EN & GU)` — `mobile error messages match required English & Gujarati phrasing`.
16. `Bilingual Localization Coverage (EN & GU)` — `DomainValidationException codes localize cleanly in EN & GU`.

### B. `test/features/validation_multi_layer_test.dart` (6 Tests)

1. `WorkerRepository rejects invalid phones & lengths, allows shared name/family phone` — Verifies repository-level rejection of `12345`, `98765abcde`, and 121-char names; verifies shared names & family phone numbers succeed and preserve trimmed formatting without auto-prepending `+91`.
2. `BusinessProfileRepository & Cubit validate phone and map validation codes` — Verifies `BusinessProfileCubit` catches `mobile_invalid_indian` on invalid Indian prefix `5555555555`.
3. `LotRepository atomically blocks reducing initialQuantity below committed stock` — Issues 60/100 pcs, verifies reducing `initialQuantity` to 50 throws `quantity_below_committed_stock`, and verifies reducing to 60 (exact committed stock -> 0 available) succeeds cleanly.
4. `StockMovementRepository & AccountingRepository enforce upper bounds and strict override` — Verifies `allowRateOverride: true` with `overrideRatePaise: null` throws `invalid_rate`, payment above `ValidationLimits.maxAmountPaise` throws `amount_too_large`, and duplicate `clientRequestId` replay is idempotent (only 1 payment stored).
5. `ReportsCubit rejects end date earlier than start date with dateRangeErrorCode` — Verifies inverted custom date range sets `invalid_date_range` and valid range clears it.
6. `WorkerLedgerCubit rejects end date earlier than start date` — Verifies inverted ledger date filter sets `invalid_date_range` and valid range clears it.

### C. `test/widget/validation_forms_ui_test.dart` (5 Tests)

1. `WorkerFormPage validates whitespace, Indian mobile numbers, clears errors on fix, and renders Gujarati + Dark Glass cleanly` — Tested at `360×800` dp in both **English Light Glass** and **Gujarati Dark Glass**; asserts whitespace rejection, invalid character error, incomplete 10-digit error, instant error clearing on correction, and zero RenderFlex overflow.
2. `BusinessProfilePage validates phone number in Light and Dark themes` — Verifies invalid Indian prefix `5432109876` displays localized inline error in Dark Glass with zero exceptions.
3. `PaymentFormPage & WorkerAdjustmentFormPage enforce exact positive decimal validation` — Verifies `0` shows positive-amount error (not required), `100.999` shows `<=2` decimals error, `-50` shows negative error, huge 23-digit overflow is rejected gracefully, valid `250.50` clears error, and whitespace-only adjustment reason is rejected.
4. `RateFormPage rejects huge overflow & >2 decimal rates without FormatException` — Verifies 26-digit input does not crash `int.parse` and `20.123` shows `<=2` decimals error.
5. `PinRecoveryPage distinguishes empty vs invalid recovery key inline` — Verifies empty submission shows required prompt and `BAD!` shows inline invalid recovery key error.

---

## 3. Requirement-to-Test Coverage Matrix

| Requirement (Phase Section 10) | Verified By | Status |
| --- | --- | --- |
| Empty required fields | `app_validators_test.dart`, `validation_forms_ui_test.dart` | Covered & Passed |
| Whitespace-only input | `app_validators_test.dart`, `validation_forms_ui_test.dart` (`WorkerFormPage`, `WorkerAdjustmentFormPage`) | Covered & Passed |
| Valid & invalid Indian mobile numbers | `app_validators_test.dart`, `validation_multi_layer_test.dart`, `validation_forms_ui_test.dart` | Covered & Passed |
| Supported international formats (E.164) | `app_validators_test.dart` (`+1`, `+44`, `+971`, malformed codes) | Covered & Passed |
| Valid & invalid email addresses | `app_validators_test.dart` | Covered & Passed |
| Negative quantities & amounts | `app_validators_test.dart`, `validation_forms_ui_test.dart` | Covered & Passed |
| Zero quantities & zero payments | `app_validators_test.dart`, `validation_forms_ui_test.dart` (`PaymentFormPage`) | Covered & Passed |
| Invalid decimals (`>2` places, float drift) | `app_validators_test.dart`, `validation_forms_ui_test.dart` (`PaymentFormPage`, `RateFormPage`) | Covered & Passed |
| Very large numeric inputs (overflow) | `app_validators_test.dart`, `validation_multi_layer_test.dart`, `validation_forms_ui_test.dart` | Covered & Passed |
| Date-range ordering errors | `app_validators_test.dart`, `validation_multi_layer_test.dart` (`ReportsCubit`, `WorkerLedgerCubit`) | Covered & Passed |
| Duplicate records & safe shared-name rules | `app_validators_test.dart`, `validation_multi_layer_test.dart`, existing Lot/Process/Rate repo tests | Covered & Passed |
| Insufficient stock & negative-stock prevention | `validation_multi_layer_test.dart` (`updateDesignColour`), existing stock movement tests | Covered & Passed |
| Excessive return quantities & partial returns | Existing stock movement settlement tests + `StockMovementRepositoryImpl` bounds | Covered & Passed |
| Invalid payments & strict rate override | `validation_multi_layer_test.dart`, `validation_forms_ui_test.dart` | Covered & Passed |
| Repeated submission / idempotency | `validation_multi_layer_test.dart` (`clientRequestId` replay) + UI submit locks | Covered & Passed |
| Database transaction integrity | `validation_multi_layer_test.dart` (in-memory Drift SQLite transactions) + 102 existing tests | Covered & Passed |
| English & Gujarati error messages | `app_validators_test.dart` (all enum codes & exact mobile strings), `validation_forms_ui_test.dart` | Covered & Passed |
| Error clearing after correction | `validation_forms_ui_test.dart` (`WorkerFormPage`, `PaymentFormPage`) | Covered & Passed |
| Light & Dark Glass validation appearance (360dp) | `validation_forms_ui_test.dart` (Light & Dark Glass, EN & GU, zero overflow) | Covered & Passed |

---

## 4. Issues Discovered & Resolved During Verification

1. **Widget test Material localization delegate for Gujarati (`gu`):** Updated test harness in `validation_forms_ui_test.dart` to mirror `lib/app.dart` (`const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates]`) because StitchFlow uses decoupled `package:material_ui/material_ui.dart`.
2. **Off-screen Save button at `360×800` dp:** Used `tester.ensureVisible` before tapping Save in long scrollable forms (`WorkerFormPage`, `BusinessProfilePage`, `PaymentFormPage`, `WorkerAdjustmentFormPage`).
3. **Existing contract compatibility:** Confirmed all 102 pre-existing tests pass unchanged without weakening a single assertion (including `ArgumentError` and SQLite `UNIQUE` contracts in `BusinessProfileRepositoryImpl` and `LotRepositoryImpl`).
