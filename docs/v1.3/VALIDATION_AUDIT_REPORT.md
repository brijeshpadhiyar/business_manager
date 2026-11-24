# StitchFlow V1.3 – Centralized Validation Audit Report

**Date:** 2026-11-24  
**Workspace:** `c:\A1\business_manager`

## 1. Existing Validation Foundation (`lib/core/validation/`)

- `AppValidators` (`app_validators.dart`): Pure Dart, UI-independent validation suite using `BigInt` exact parsing for quantities (`parseQuantityExact`) and monetary rupees-to-paise (`parseRupeesToPaiseExact`, zero floating-point drift), Indian 10-digit / `+91` + E.164 international mobile validation, email, dates, date ranges, duplicates, HEX colour codes, PINs, and recovery keys.
- `ValidationLimits`, `ValidationErrorCode`, `ValidationResult` (`validation_error.dart`).
- `ValidationLocalizer` (`validation_localizer.dart`): EN + GU localized error mapping for UI and domain exception codes.
- `FormValidationHelper` (`form_validation_helper.dart`): Scroll-to-first-invalid-field and focus management.
- Domain boundaries: `ProcessRoutingValidator`, `ProcessPricingCalculator`, `StockCalculator`, `LabourCalculator`.

## 2. Gaps Identified & Resolved

| Severity | Finding | Resolution |
|---|---|---|
| **HIGH** | `JobProcessRoutingPage` used floating-point `(double.tryParse * 100).round()` (`_parseRupeesToPaise`) and raw `int.tryParse` across 6 bottom sheets | Replaced with `AppValidators.parseRupeesToPaiseExact` and `AppValidators.parseQuantityExact` (zero floating-point drift, strict <= 2 decimals, rejects NaN/Infinity/negatives) |
| **MEDIUM** | Missing `minLengthValidator`, `exactLengthValidator`, and shared `AppInputFormatters` | Added both validators to `AppValidators` and created `lib/core/validation/input_formatters.dart` |
| **MEDIUM** | Missing EN/GU `ValidationLocalizer` mappings for V1.3 Process Routing & Colour Master error codes | Added ARB keys in `app_en.arb` / `app_gu.arb` and mapped `rate_override_reason_required`, `exceeds_dispatched_quantity`, `exceeds_held_quantity`, `unaccounted_quantity_remaining`, `overpayment_not_allowed`, `duplicate_colour_master`, `invalid_charge_amount` |
| **HIGH** | 4 feature screens passed raw `e.toString()` to error notifications | Replaced with localized `l10n.errorUnexpected` / `ValidationLocalizer.localizeDomainCode` |
