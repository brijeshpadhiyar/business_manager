# 25 — Milestone 1 Implementation Report (Flutter Project Foundation)

**Completed Date:** 2026-11-23  
**SDK Verified:** Flutter `3.50.1` (`stable`) / Dart `3.14.0`  
**Milestone Scope:** Foundation only (dependencies, `material_ui: ^1.11.1`, `dev`/`prod` flavors, `gen-l10n` EN/GU localization + Noto Sans Gujarati offline font + persisted `LocaleCubit`, DI, minimal `go_router` foundation shell, core utils, and unit/widget tests). Zero business screens, database tables, or business logic implemented.

---

## 1. Files Created & Modified

### Modified Files
- `pubspec.yaml` — Pinned `material_ui: ^1.11.1`, added verified V1 dependencies & dev/test packages, enabled `generate: true`, registered `NotoSansGujarati` font weights (`400`, `500`, `600`, `700`).
- `analysis_options.yaml` — Excluded generated files (`lib/l10n/generated/**`, `*.g.dart`, `*.freezed.dart`, `*.config.dart`) from static analysis.
- `android/app/build.gradle.kts` — Enabled `buildFeatures { resValues = true }` (required by modern AGP) and configured `environment` flavor dimension with `dev` (`com.brijesh.business_manager.dev`, `Business Manager Dev`) and `prod` (`com.brijesh.business_manager`, `Business Manager`).
- `android/app/src/main/AndroidManifest.xml` — Switched `android:label` to `@string/app_name`.
- `lib/main.dart` — Delegated to shared `bootstrap(AppConfig.fromEnvironment())`.
- `test/widget_test.dart` — Replaced default counter test with live EN → Gujarati (`બિઝનેસ મેનેજર`) & flavor verification widget test.
- `CHANGELOG.md`, `README.md`, `docs/04_technology_stack.md`, `docs/17_localization_strategy.md`, `docs/18_flavor_configuration.md`.

### Created Files
- **Fonts (`assets/fonts/`):** `NotoSansGujarati-Regular.ttf`, `NotoSansGujarati-Medium.ttf`, `NotoSansGujarati-SemiBold.ttf`, `NotoSansGujarati-Bold.ttf` (OFL-1.1 from Google Fonts).
- **Localization:** `l10n.yaml`, `lib/l10n/app_en.arb`, `lib/l10n/app_gu.arb` (+ generated `lib/l10n/generated/app_localizations*.dart`).
- **Flavor Configs & Entrypoints:** `config/dev.json`, `config/prod.json`, `lib/main_dev.dart`, `lib/main_prod.dart`, `lib/bootstrap.dart`, `lib/app.dart`, `lib/core/config/{app_flavor,app_config,app_logger}.dart`.
- **Core Foundation:**
  - `lib/core/di/{injection,register_module}.dart` (+ generated `injection.config.dart`)
  - `lib/core/localization/{locale_state,locale_cubit,l10n_extensions}.dart` (+ generated `locale_state.freezed.dart`)
  - `lib/core/router/{route_paths,app_router}.dart`
  - `lib/core/utils/{ist_datetime_helper,money_formatter,id_generator}.dart`
  - `lib/core/error/{failures,exceptions}.dart`
- **Unit Tests:** `test/unit/foundation_utils_test.dart`.

---

## 2. Dependencies Added & Resolved Versions (`pubspec.lock`)

### Production Dependencies
| Package | Constraint | Resolved Version | Role |
| :--- | :--- | :--- | :--- |
| `material_ui` | `^1.11.1` | `1.11.1` | Official decoupled Flutter Material 3 library (`flutter.dev`) |
| `flutter_localizations` | `sdk: flutter` | SDK | Flutter localization framework |
| `flutter_bloc` | `^9.1.1` | `9.1.1` | BLoC/Cubit state management |
| `drift` | `^2.35.3` | `2.35.4` | Reactive type-safe SQLite ORM |
| `drift_flutter` | `^0.3.1` | `0.3.1` | Cross-platform Drift connection helper |
| `sqlite3` | `^3.9.1` | `3.9.2` | SQLite native build hooks + WASM |
| `go_router` | `^18.1.4` | `18.1.4` | Declarative Navigation 2.0 routing |
| `freezed_annotation` | `^3.1.0` | `3.1.0` | Immutable state/model annotations |
| `json_annotation` | `^4.12.0` | `4.12.0` | JSON serialization annotations |
| `get_it` | `^8.0.2` | `8.3.0` | Service locator DI |
| `injectable` | `^3.0.0` | `3.0.0` | Annotation-based DI |
| `intl` | `^0.20.3` | `0.20.3` | Formatting & ARB support |
| `timezone` | `^0.11.2` | `0.11.2` | IANA `Asia/Kolkata` conversions |
| `shared_preferences` | `^2.5.3` | `2.5.6` | Local preferences persistence |
| `path_provider` | `^2.1.6` | `2.1.6` | OS private app directories |
| `path` | `^1.9.1` | `1.9.1` | Cross-platform path joining |
| `image_picker` | `^1.2.4` | `1.2.4` | Camera/gallery capture + resize/compression |
| `file_picker` | `^13.4.1` | `13.4.1` | Backup & attachment picker |
| `archive` | `^4.6.0` | `4.7.1` | Pure Dart `.zip` backup/restore |
| `share_plus` | `^13.3.1` | `13.3.1` | Explicit user-initiated export/share |
| `uuid` | `^4.6.0` | `4.6.0` | UUIDv7 entity IDs & UUIDv4 request IDs |
| `crypto` | `^3.0.6` | `3.0.8` | SHA-256 checksums for backup manifests |

### Dev & Testing Dependencies
| Package | Constraint | Resolved Version | Notes |
| :--- | :--- | :--- | :--- |
| `build_runner` | `^2.16.1` | `2.16.1` | Pinned to `^2.16.1` because `build_runner 2.16.2+` requires `analyzer ^14.3.0` which conflicts with `injectable_generator 3.1.3` (`lean_builder 1.2.2` / `_fe_analyzer_shared <106.0.0`) |
| `drift_dev` | `^2.35.3` | `2.35.3` | Drift code generator |
| `freezed` | `^4.0.2` | `4.0.3` | Freezed code generator |
| `json_serializable` | `^6.15.2` | `6.15.2` | JSON code generator |
| `injectable_generator` | `^3.1.3` | `3.1.3` | DI code generator |
| `bloc_test` | `^10.0.0` | `10.0.0` | BLoC/Cubit testing |
| `mocktail` | `^1.0.5` | `1.0.5` | Null-safe mocking |

---

## 3. Flavor Configuration Details

| Setting | `dev` | `prod` |
| :--- | :--- | :--- |
| Android `applicationId` | `com.brijesh.business_manager.dev` | `com.brijesh.business_manager` |
| Android `app_name` | `Business Manager Dev` | `Business Manager` |
| Entrypoint | `lib/main_dev.dart` | `lib/main_prod.dart` |
| Config file | `config/dev.json` | `config/prod.json` |
| Planned DB filename | `business_manager_dev.sqlite` | `business_manager_prod.sqlite` |
| Planned Media dir | `media_dev` | `media_prod` |
| Debug Logging (`AppLogger`) | Enabled (`true`) | Strictly Disabled (`false`) |

---

## 4. Localization Configuration

- **Tool:** Flutter official `gen-l10n` (`l10n.yaml` → `lib/l10n/generated/app_localizations.dart`).
- **Locales:** English (`en`) and Gujarati (`gu`), with **0 untranslated messages** verified via `l10n_untranslated.txt`.
- **Material 3 Delegates:** Uses `GlobalMaterialLocalizations.delegates` from `package:material_ui/material_ui.dart` (Flutter 3.50 decoupled API), automatically wiring Material, Widgets, and Cupertino localizations with zero deprecation warnings.
- **Persistence:** `LocaleCubit` persists `AppLocalePreference` (`system`, `en`, `gu`) in `SharedPreferences` (`app_locale_preference`).
- **Gujarati Font:** Bundled 4 static weights of **Noto Sans Gujarati** (`400`, `500`, `600`, `700`) in `assets/fonts/` for guaranteed offline rendering across all platforms.

---

## 5. Commands Executed & Results

| Command | Result |
| :--- | :--- |
| `flutter pub get` | **PASS** (147 dependencies resolved cleanly) |
| `flutter gen-l10n` | **PASS** (0 untranslated messages) |
| `dart run build_runner build` | **PASS** (0 warnings; generated `locale_state.freezed.dart`, `injection.config.dart`) |
| `flutter analyze` | **PASS** (`No issues found!`) |
| `flutter test` | **PASS** (`7 / 7` tests passed: flavor isolation, IST midnight boundary, INR formatting, UUIDv7/v4, `LocaleCubit` persistence, live EN → Gujarati widget render) |
| `flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json` | **PASS** (`build\app\outputs\flutter-apk\app-dev-debug.apk`) |
| `flutter build apk --debug --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.json` | **PASS** (`build\app\outputs\flutter-apk\app-prod-debug.apk`) |

---

## 6. Known Issues & Platform Environment Notes

- **iOS / macOS / Linux Builds:** Not executed on this **Windows** development host (Xcode is required for iOS/macOS; Linux desktop toolchain is required for Linux). Existing `ios/`, `macos/`, `linux/`, `windows/`, and `web/` folders remain intact and unmodified.
- **`build_runner` Version Pin (`^2.16.1`):** Temporary constraint until `injectable_generator` updates `lean_builder` to support `analyzer ^14.3.0`.
- **Generated `app_localizations.dart` Exclusion:** Flutter 3.50's `gen-l10n` still references legacy `flutter_localizations` symbols inside its generated file, so `lib/l10n/generated/**` is excluded in `analysis_options.yaml` while `lib/app.dart` uses `package:material_ui/material_ui.dart`'s `GlobalMaterialLocalizations.delegates`.

---

## 7. Decisions Requiring Approval Before Milestone 2

- Confirm approval of Milestone 1 deliverables and `build_runner: ^2.16.1` compatibility pin so we can proceed to **Milestone 2 (Material 3 Design System & 20 Centralized Common Widgets)**.
