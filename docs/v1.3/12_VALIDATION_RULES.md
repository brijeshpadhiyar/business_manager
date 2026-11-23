# StitchFlow V1.3 — Global Validation Rules Specification

This document defines the canonical, centralized validation rules, accepted formats, layer enforcement, and bilingual error messages (English & Gujarati) for StitchFlow V1.3.

---

## 1. Centralized Validation Architecture

Located in `lib/core/validation/`:

| File | Responsibility |
| :--- | :--- |
| `validation_error.dart` | Typed `ValidationErrorCode` enum + `ValidationResult` value object + centralized length & numeric limit constants (`ValidationLimits`). |
| `app_validators.dart` | Pure Dart, UI-independent reusable validators (`requiredValidator`, `whitespaceValidator`, `nameValidator`, `mobileNumberValidator`, `emailValidator`, `numericValidator`, `integerValidator`, `decimalValidator`, `positiveNumberValidator`, `quantityValidator`, `nonNegativeQuantityValidator`, `amountValidator`, `nonNegativeAmountValidator`, `percentageValidator`, `dateValidator`, `dateRangeValidator`, `isoDateRangeValidator`, `duplicateValidator`, `maxLengthValidator`, `pinValidator`, `recoveryKeyValidator`, `hexColorValidator`) and exact string-to-paise/int parsers without floating-point drift. |
| `validation_localizer.dart` | Maps `ValidationErrorCode` and `DomainValidationException.code` to localized `AppLocalizations` strings (English & Gujarati) with zero hardcoded UI strings. |
| `form_validation_helper.dart` | Reusable Form UX helper (`FormValidationCoordinator`) for submit-triggered `AutovalidateMode`, duplicate-submission locking, and scrolling/focusing the first invalid field into view. |

---

## 2. Core Limits & Numeric Precision Constants (`ValidationLimits`)

| Constant | Value | Business Rationale |
| :--- | :--- | :--- |
| `maxShortNameLength` | `100` | Process names, lot numbers, design names, colour names, reference numbers. |
| `maxPersonNameLength` | `120` | Worker names, owner names, business names (EN/GU). |
| `maxAddressLength` | `300` | Multi-line workshop/worker addresses. |
| `maxNotesLength` | `500` | Optional notes, descriptions, and audit/reversal reasons. |
| `maxSearchLength` | `120` | Safe search filter query length. |
| `maxQuantity` | `10000000` (1 Crore pcs) | Prevents integer overflow in stock totals & `quantity * ratePaise`. |
| `maxAmountPaise` | `99999999999` (₹99,99,99,999.99) | Exact integer paise ceiling (~₹100 Crore) preventing 64-bit overflow while accommodating all garment workshop ledgers. |
| `minValidEpochMillis` | `946684800000` (2000-01-01 UTC) | Matches `AppDatePicker` minimum calendar year (`2000`). |
| `maxValidEpochMillis` | `4102444800000` (2100-01-01 UTC) | Matches `AppDatePicker` maximum calendar year (`2100`). |

---

## 3. Indian & International Mobile Number Rules

Applies to: **Worker Phone** (`members.phone`) and **Business Profile Phone** (`business_profile.phone`). Both fields are **optional**; validation runs whenever non-empty.

1. **No Silent Mutation:** Never silently truncate digits or auto-prepend `+91`. Only outer whitespace is trimmed when persisting.
2. **Offline-First Honesty:** Validates syntax/format only; never claims OTP or SIM ownership verification.
3. **Allowed Formatting Characters:** Digits `0-9`, spaces, hyphens `-`, parentheses `( )`, and an optional single leading `+`.
   - Any letters, symbols (`@`, `#`, `*`, `.`), or misplaced `+` -> **Rejected** (`mobileInvalidChars`).
4. **Normalization (for checking only):** Strip whitespace, hyphens, and parentheses.
5. **Indian Local Number (no leading `+`):**
   - Must be **exactly 10 digits** AND start with **`6`, `7`, `8`, or `9`** (`^[6-9]\d{9}$`).
   - Rejects incomplete numbers (e.g. `987654321`), 11+ digits (e.g. `09876543210` or `98765432101`), and invalid prefixes (`1234567890`, `5555555555`).
6. **Indian Number with Explicit `+91` Country Code:**
   - Must have **exactly 10 digits** after `+91` starting with **`6`, `7`, `8`, or `9`**.
7. **International Numbers (`+` followed by non-`91` country code):**
   - Country-code-aware ITU-T E.164 check: `7` to `15` total digits after `+`, first digit `1-9` (no leading `0`).

### Mobile Number Error Messages

| Code | English | Gujarati |
| :--- | :--- | :--- |
| `mobileRequired` | `Enter mobile number.` | `મોબાઇલ નંબર દાખલ કરો.` |
| `mobileInvalidIndian` | `Enter a valid 10-digit mobile number.` | `માન્ય 10 અંકનો મોબાઇલ નંબર દાખલ કરો.` |
| `mobileInvalidChars` | `Mobile number contains invalid characters.` | `મોબાઇલ નંબરમાં અમાન્ય અક્ષરો છે.` |
| `mobileInvalidInternational` | `Enter a valid international mobile number with country code.` | `દેશના કોડ સાથે માન્ય આંતરરાષ્ટ્રીય મોબાઇલ નંબર દાખલ કરો.` |

---

## 4. Numeric & Financial Parsing Rules (Zero Floating-Point Drift)

1. **Exact Decimal-to-Paise Conversion (`parseRupeesToPaiseExact`):**
   - Rejects `NaN`, `Infinity`, scientific notation (`1e5`), commas/letters/symbols.
   - Rejects negative sign when disallowed (`negativeNotAllowed`).
   - Rejects more than 2 decimal places (`tooManyDecimals`) — **never silently rounds** `10.999`.
   - Parses whole rupees and fractional paise using integer arithmetic (`BigInt` overflow-checked against `ValidationLimits.maxAmountPaise`).
2. **Exact Integer Quantity Parsing (`parseQuantityExact`):**
   - Rejects decimals (`10.5`), letters, negative signs, scientific notation, and values exceeding `ValidationLimits.maxQuantity`.
   - Distinguishes positive-only (`> 0`) vs non-negative (`>= 0`) fields cleanly.

---

## 5. Complete Field-by-Field Rules & Bilingual Error Catalog

### 5.1 Worker Management (`WorkerFormPage`, `WorkerAssignmentsPage`, `WorkerRepositoryImpl`)

| Field | Req. | Format & Rule | Layers | English Error | Gujarati Error |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Worker Name | Required | Trimmed, non-blank, `<= 120` chars | UI, Repo | `This field is required.` / `Maximum 120 characters allowed.` | `આ વિગત ભરવી ફરજિયાત છે.` / `વધુમાં વધુ 120 અક્ષરો દાખલ કરી શકાય છે.` |
| Mobile Number | Optional | Valid 10-digit Indian (`[6-9]\d{9}`), `+91` Indian, or E.164 international | UI, Repo | See Section 3 | See Section 3 |
| Address | Optional | Trimmed, `<= 300` chars | UI, Repo | `Maximum 300 characters allowed.` | `વધુમાં વધુ 300 અક્ષરો દાખલ કરી શકાય છે.` |
| Notes | Optional | Trimmed, `<= 500` chars | UI, Repo | `Maximum 500 characters allowed.` | `વધુમાં વધુ 500 અક્ષરો દાખલ કરી શકાય છે.` |
| Process Assignment | Required | Active worker + active process + no active duplicate link | UI, BLoC, Repo, DB | `This process is already assigned to the worker.` / `Activate this worker before adding process assignments.` / `Only active processes can be assigned.` | `આ પ્રક્રિયા આ કારીગરને પહેલેથી સોંપેલી છે.` / `પ્રક્રિયા સોંપતા પહેલા આ કારીગરને સક્રિય કરો.` / `માત્ર સક્રિય પ્રક્રિયાઓ જ સોંપી શકાય છે.` |

### 5.2 Business Profile (`BusinessProfilePage`, `BusinessProfileCubit`, `BusinessProfileRepositoryImpl`)

| Field | Req. | Format & Rule | Layers | English Error | Gujarati Error |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Business Name (EN) | Required | Trimmed, non-blank, `<= 120` chars | UI, BLoC, Repo | `This field is required.` / `Maximum 120 characters allowed.` | `આ વિગત ભરવી ફરજિયાત છે.` / `વધુમાં વધુ 120 અક્ષરો દાખલ કરી શકાય છે.` |
| Business Name (GU) | Required | Trimmed, non-blank, `<= 120` chars | UI, BLoC, Repo | `This field is required.` / `Maximum 120 characters allowed.` | `આ વિગત ભરવી ફરજિયાત છે.` / `વધુમાં વધુ 120 અક્ષરો દાખલ કરી શકાય છે.` |
| Owner Name | Optional | Trimmed, `<= 120` chars | UI, BLoC, Repo | `Maximum 120 characters allowed.` | `વધુમાં વધુ 120 અક્ષરો દાખલ કરી શકાય છે.` |
| Business Phone | Optional | Indian 10-digit / `+91` / E.164 | UI, BLoC, Repo | See Section 3 | See Section 3 |
| Address | Optional | Trimmed, `<= 300` chars | UI, BLoC, Repo | `Maximum 300 characters allowed.` | `વધુમાં વધુ 300 અક્ષરો દાખલ કરી શકાય છે.` |
| Default Billing Mode | Required | `RECEIVED_QTY` or `GIVEN_QTY` | UI, Repo, DB | Constrained enum & SQLite `CHECK` | Constrained enum & SQLite `CHECK` |

### 5.3 Lots, Designs & Colours (`LotListPage`, `LotDetailPage`, `LotListCubit`, `LotDetailCubit`, `LotRepositoryImpl`)

| Field | Req. | Format & Rule | Layers | English Error | Gujarati Error |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Lot Number | Required | Trimmed, non-blank, `<= 100` chars, unique among active lots | UI, BLoC, Repo, DB | `This field is required.` / `An active lot with this lot number already exists.` | `આ વિગત ભરવી ફરજિયાત છે.` / `આ લોટ નંબર સાથેનો સક્રિય લોટ પહેલેથી અસ્તિત્વમાં છે.` |
| Lot Title | Optional | Trimmed, `<= 120` chars | UI, Repo | `Maximum 120 characters allowed.` | `વધુમાં વધુ 120 અક્ષરો દાખલ કરી શકાય છે.` |
| Lot Date | Required | Valid epoch millis (`2000-2100`) | UI, Repo | `Select a valid date.` | `માન્ય તારીખ પસંદ કરો.` |
| Design Name | Required | Trimmed, non-blank, `<= 100` chars, case-insensitive unique within lot | UI, BLoC, Repo, DB | `This field is required.` / `A design with this name already exists in this lot.` | `આ વિગત ભરવી ફરજિયાત છે.` / `આ નામની ડિઝાઇન આ લોટમાં પહેલેથી છે.` |
| Colour Name | Required | Trimmed, non-blank, `<= 100` chars, case-insensitive unique within design | UI, BLoC, Repo, DB | `This field is required.` / `This colour already exists in this design.` | `આ વિગત ભરવી ફરજિયાત છે.` / `આ કલર આ ડિઝાઇનમાં પહેલેથી છે.` |
| Initial Quantity | Required | Positive integer `1..10,000,000`; on edit must not make `physicalAvailableInHouse < 0` or `totalGoodPhysicalStock < 0` | UI, Repo (atomic tx), DB (`CHECK > 0`) | `Enter a whole number greater than 0.` / `Quantity cannot be less than stock already issued or damaged.` | `0 થી મોટી પૂર્ણ સંખ્યા દાખલ કરો.` / `જથ્થો પહેલેથી આપેલ અથવા ડેમેજ સ્ટોક કરતાં ઓછો હોઈ શકે નહીં.` |
| Unit Price (₹) | Optional (default `0`) | Non-negative decimal (`<= 2` decimals), `0..₹99,99,99,999.99` | UI, Repo, DB (`CHECK >= 0`) | `Value cannot be negative.` / `Enter up to 2 decimal places.` / `Enter a valid amount.` | `મૂલ્ય ઋણ હોઈ શકતું નથી.` / `વધુમાં વધુ 2 દશાંશ સ્થાન સુધી દાખલ કરો.` / `માન્ય રકમ દાખલ કરો.` |
| Notes | Optional | Trimmed, `<= 500` chars | UI, Repo | `Maximum 500 characters allowed.` | `વધુમાં વધુ 500 અક્ષરો દાખલ કરી શકાય છે.` |

### 5.4 Stock Issue (`StockIssuePage`, `StockMovementRepositoryImpl`)

| Field | Req. | Format & Rule | Layers | English Error | Gujarati Error |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Stock (Lot/Design/Colour) | Required | Active SKU with `physicalAvailableInHouse > 0` | UI, Repo (atomic tx) | `This field is required.` / `Cannot issue more than available good stock.` | `આ વિગત ભરવી ફરજિયાત છે.` / `ઉપલબ્ધ સારા સ્ટોક કરતાં વધુ માલ આપી શકાય નહીં.` |
| Active Process | Required | Active, non-deleted process | UI, Repo (atomic tx) | `Selected process is inactive or unavailable.` | `પસંદ કરેલી પ્રક્રિયા નિષ્ક્રિય અથવા અનુપલબ્ધ છે.` |
| Eligible Worker | Required | Active worker with active process assignment | UI, Repo (atomic tx) | `Selected worker is not actively assigned to this process.` | `પસંદ કરેલા કારીગરને આ પ્રક્રિયા સોંપાયેલી નથી.` |
| Issue Quantity | Required | Positive integer `1..physicalAvailableInHouse` (`<= 10,000,000`) | UI, Repo (atomic tx), DB (`CHECK > 0`) | `Enter a valid positive piece quantity.` / `Cannot issue more than available good stock.` | `માન્ય ધન પીસ સંખ્યા દાખલ કરો.` / `ઉપલબ્ધ સારા સ્ટોક કરતાં વધુ માલ આપી શકાય નહીં.` |
| Rate / Override Rate | Required | Effective historical rate exists (no conflict) OR valid non-negative override rate (`<= 2` decimals) + mandatory override reason | UI, Repo (atomic tx), DB (`CHECK >= 0`) | `No effective rate configured for this date.` / `Enter a valid non-negative price (e.g. 250 or 250.50).` / `Override reason is required.` | `આ તારીખ માટે કોઈ સક્રિય ભાવ ગોઠવેલ નથી.` / `માન્ય ભાવ દાખલ કરો (દા.ત. 250 અથવા 250.50).` / `ભાવ ફેરફાર માટે કારણ ફરજિયાત છે.` |
| Transaction Date/Time | Required | Valid epoch millis (`2000-2100`) | UI, Repo | `Select a valid date.` | `માન્ય તારીખ પસંદ કરો.` |
| Duplicate Submit Guard | Mandatory | UI `_saving` lock + deterministic `clientRequestId` idempotency | UI, Repo, DB (`UNIQUE`) | Idempotent return of original record | મૂળ રેકોર્ડ સુરક્ષિત રીતે પરત |

### 5.5 Return Work, Settlement, Repair & Reversal (`StockSettlementPage`, `DamagedRepairPage`, `StockMovementsPage`, `StockMovementRepositoryImpl`)

| Field | Req. | Format & Rule | Layers | English Error | Gujarati Error |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Parent Issue | Required | Active non-reversed ISSUE with `remainingPending > 0` | UI, Repo (atomic tx) | `Original stock issue is no longer active.` | `મૂળ સ્ટોક ઇશ્યુ હવે સક્રિય નથી.` |
| Good / Damaged / Lost / Shortage Qty | Conditional | Each `>= 0` integer (`<= 10,000,000`); sum `> 0` and `<= remainingPending` | UI, Repo (atomic tx), DB (`CHECK > 0`) | `Enter a whole number 0 or greater.` / `Enter at least one quantity greater than zero.` / `Total settled quantity exceeds remaining pending quantity.` | `0 અથવા તેથી મોટી પૂર્ણ સંખ્યા દાખલ કરો.` / `ઓછામાં ઓછી એક સંખ્યા શૂન્યથી વધુ દાખલ કરો.` / `કુલ સેટલ સંખ્યા બાકી સંખ્યા કરતાં વધુ છે.` |
| Settlement Reason | Conditional | Required (non-blank, `<= 500` chars) whenever `damaged + lost + shortage > 0` | UI, Repo | `Reason is required for damaged, lost, or shortage settlements.` | `ડેમેજ, ખોવાયેલ અથવા ઘટ માટે કારણ ફરજિયાત છે.` |
| Repair Quantity | Required | Positive integer `1..damagedBucket` | UI, Repo (atomic tx) | `Enter a valid positive piece quantity.` / `Quantity exceeds current damaged stock bucket.` | `માન્ય ધન પીસ સંખ્યા દાખલ કરો.` / `સંખ્યા હાલના ડેમેજ સ્ટોક કરતાં વધુ છે.` |
| Repair / Reversal Reason | Required | Trimmed, non-blank, `<= 500` chars | UI, Repo | `This field is required.` | `આ વિગત ભરવી ફરજિયાત છે.` |

### 5.6 Payments & Worker Adjustments (`PaymentFormPage`, `WorkerAdjustmentFormPage`, `WorkerLedgerPage`, `AccountingRepositoryImpl`)

| Field | Req. | Format & Rule | Layers | English Error | Gujarati Error |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Worker | Required | Non-deleted worker ID | UI, Repo | `This field is required.` / `Selected worker was not found.` | `આ વિગત ભરવી ફરજિયાત છે.` / `પસંદ કરેલ કારીગર મળ્યો નથી.` |
| Payment / Adjustment Amount | Required | Strictly positive decimal (`> 0`), `<= 2` decimal places, `<= ₹99,99,99,999.99` | UI, Repo, DB (`CHECK > 0`) | `Enter a valid amount greater than 0.` / `Value cannot be negative.` / `Enter up to 2 decimal places.` / `Amount exceeds maximum allowed limit.` | `0 થી વધુ માન્ય રકમ દાખલ કરો.` / `મૂલ્ય ઋણ હોઈ શકતું નથી.` / `વધુમાં વધુ 2 દશાંશ સ્થાન સુધી દાખલ કરો.` / `રકમ મહત્તમ મર્યાદા કરતાં વધુ છે.` |
| Payment Type / Mode | Required | Supported enum (`REGULAR`/`ADVANCE`/`ADVANCE_REFUND`; `CASH`/`UPI`/`BANK_TRANSFER`/`CHEQUE`/`OTHER`) | UI, Repo, DB (`CHECK`) | Enforced via typed enums & SQLite `CHECK` | Enforced via typed enums & SQLite `CHECK` |
| Reference No. | Optional | Trimmed, `<= 100` chars | UI, Repo | `Maximum 100 characters allowed.` | `વધુમાં વધુ 100 અક્ષરો દાખલ કરી શકાય છે.` |
| Adjustment / Reversal Reason | Required | Trimmed, non-blank, `<= 500` chars | UI, Repo, DB (`CHECK`) | `This field is required.` | `આ વિગત ભરવી ફરજિયાત છે.` |
| Ledger Date Range | Optional | When both set, `toUtcMillis >= fromUtcMillis` | UI, BLoC | `End date cannot be earlier than start date.` | `અંતિમ તારીખ શરૂઆતની તારીખથી પહેલાની હોઈ શકે નહીં.` |

### 5.7 Processes & Historical Rates (`ProcessFormPage`, `RateFormPage`, `ProcessRepositoryImpl`, `RateRepositoryImpl`)

| Field | Req. | Format & Rule | Layers | English Error | Gujarati Error |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Process Name | Required | Trimmed, non-blank, `<= 100` chars, case-insensitive unique | UI, Repo, DB (`UNIQUE`) | `This field is required.` / `A process with this name already exists.` | `આ વિગત ભરવી ફરજિયાત છે.` / `આ નામની પ્રક્રિયા પહેલેથી અસ્તિત્વમાં છે.` |
| Process Description | Optional | Trimmed, `<= 500` chars | UI, Repo | `Maximum 500 characters allowed.` | `વધુમાં વધુ 500 અક્ષરો દાખલ કરી શકાય છે.` |
| Rate Amount (₹) | Required | Non-negative decimal (`>= 0`), `<= 2` decimals, `<= ₹99,99,99,999.99` | UI, Repo, DB (`CHECK >= 0`) | `This field is required.` / `Value cannot be negative.` / `Enter up to 2 decimal places.` / `Amount exceeds maximum allowed limit.` | `આ વિગત ભરવી ફરજિયાત છે.` / `મૂલ્ય ઋણ હોઈ શકતું નથી.` / `વધુમાં વધુ 2 દશાંશ સ્થાન સુધી દાખલ કરો.` / `રકમ મહત્તમ મર્યાદા કરતાં વધુ છે.` |
| Effective From / To | From Required, To Optional | Valid `YYYY-MM-DD`; if To set, `To >= From`; no overlapping periods; max 1 open-ended rate; immutable once referenced | UI, Repo, DB (`CHECK`) | `Effective To date cannot be earlier than Effective From date.` / `This date range overlaps with an existing rate.` / `This rate is already used in historical transactions and cannot be edited.` | `અંતિમ તારીખ શરૂઆતની તારીખથી પહેલાની હોઈ શકે નહીં.` / `આ તારીખનો સમયગાળો હાલના ભાવ સાથે ઓવરલેપ થાય છે.` / `આ ભાવ ઐતિહાસિક વ્યવહારોમાં વપરાયેલ હોવાથી સુધારી શકાતો નથી.` |

### 5.8 Reports, Security & Settings (`ReportFilterBar`, `ReportsCubit`, `PinSetupPage`, `PinRecoveryPage`, `AppLockCubit`, `NotificationSettingsCubit`)

| Field | Req. | Format & Rule | Layers | English Error | Gujarati Error |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Report Custom Date Range | Optional | When both set, `toDate >= fromDate` (IST calendar dates) | UI, BLoC | `End date cannot be earlier than start date.` | `અંતિમ તારીખ શરૂઆતની તારીખથી પહેલાની હોઈ શકે નહીં.` |
| Report Search Query | Optional | `<= 120` chars | UI, BLoC | Silently bounded via `maxLength` | Silently bounded via `maxLength` |
| App PIN | Required (when enabling) | Strictly 4 or 6 ASCII digits (`0-9`); confirm must match | UI, BLoC, Repo | `Enter a valid 4- or 6-digit PIN.` / `PINs do not match. Please try again.` | `માન્ય 4 અથવા 6 અંકનો PIN દાખલ કરો.` / `PIN મેળ ખાતા નથી. કૃપા કરીને ફરી પ્રયાસ કરો.` |
| Offline Recovery Key | Required (for recovery) | Non-empty; 8 Crockford alphanumeric chars (`XXXX-XXXX` ignoring spaces/hyphens) | UI, BLoC, Repo | `Enter your 8-character Recovery Key.` / `Invalid Recovery Key. Check your code and try again.` | `તમારી 8-અક્ષરની રિકવરી કી દાખલ કરો.` / `રિકવરી કી ખોટી છે. કોડ ચકાસીને ફરી પ્રયાસ કરો.` |
| Notification Thresholds | Required | Days `1..365`, min paise `>= 0`, hour `0..23`, minute `0..59` | BLoC, Repo | Clamped/validated to safe business bounds | સુરક્ષિત મર્યાદામાં ચકાસાયેલ |
