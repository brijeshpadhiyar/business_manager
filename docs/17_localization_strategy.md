# 17 — Localization Strategy (`gen-l10n`)

## 1. Official Flutter Localization Setup

We use Flutter's official `gen-l10n` pipeline (`flutter_localizations` SDK + `intl: ^0.20.3`).

### `l10n.yaml` Configuration
```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
output-dir: lib/l10n/generated
untranslated-messages-file: l10n_untranslated.txt
```
- `untranslated-messages-file` acts as a CI/review gate: every English key added to `app_en.arb` **must** have a matching Gujarati translation in `app_gu.arb`.
- In `MaterialApp.router`, wire `localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates]` using `package:material_ui/material_ui.dart` (Flutter 3.50+ decoupled delegates).

---

## 2. Supported Locales & Persistence

- **Supported Locales (V1):**
  - `en` — English (`Business Manager`)
  - `gu` — Gujarati (`બિઝનેસ મેનેજર`)
- **User Settings Options:**
  - `System Default` (follows OS locale; falls back to `en` if OS locale is neither `en` nor `gu`)
  - `English` (`Locale('en')`)
  - `ગુજરાતી (Gujarati)` (`Locale('gu')`)
- **Persistence:** Stored in `shared_preferences` (`app_locale`: `'system' | 'en' | 'gu'`) and managed reactively by `LocaleCubit`.

---

## 3. Cross-Platform Gujarati Font Rendering

- **Problem:** Relying on system fallback fonts causes inconsistent Gujarati conjunct (*jodakshar*) rendering on Windows, Linux, and Web browsers.
- **Solution:** Bundle **Noto Sans Gujarati** (`Regular`, `Medium`, `SemiBold`, `Bold` `.ttf` files) in `assets/fonts/` and register them in `pubspec.yaml` and `AppTypography`. Works 100% offline on Android, iOS, Web, Windows, macOS, and Linux.

---

## 4. ARB Authoring Conventions

- **Zero Hardcoded Strings:** Every title, button, label, validation error, status badge, dialog message, empty state, and tooltip must come from `context.l10n.<key>` (convenience extension on `BuildContext`).
- **Key Naming:** `<feature><ScreenOrContext><Element>` in `lowerCamelCase`:
  - `appTitle`: `"Business Manager"` / `"બિઝનેસ મેનેજર"`
  - `stockMovementReturnGood`: `"Good Return"` / `"સારા પીસ પરત"`
  - `stockMovementReturnDamaged`: `"Damaged Return"` / `"નુકસાનગ્રસ્ત પીસ પરત"`
  - `stockMovementLost`: `"Lost Pieces"` / `"ખોવાયેલા પીસ"`
  - `stockMovementShortage`: `"Shortage / Missing"` / `"ઘટ / ખૂટતા પીસ"`
  - `ledgerAdvanceCredit`: `"Advance Credit"` / `"એડવાન્સ જમા"`
- **Plurals & Placeholders:** Use ICU message syntax (`{count, plural, =1{1 piece} other{{count} pieces}}`) and typed placeholders for dates and currency amounts.

---

## 5. Number, Currency & Date Formatting

- **Currency:** Always format paise via `MoneyFormatter` using Indian numbering system (`₹1,25,000.00` via `NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2)` — configurable numeral style for Gujarati if desired).
- **Dates & Times:** Always convert UTC → `Asia/Kolkata` before formatting with `DateFormat` in the active locale (`en` or `gu`).
