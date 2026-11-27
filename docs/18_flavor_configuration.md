# 18 — Flavor & Environment Configuration

## 1. Flavor Matrix (`dev` vs `prod`)

Development testing must **never** read, modify, or overwrite production data.

| Property | Development (`dev`) | Production (`prod`) |
| :--- | :--- | :--- |
| **Android `applicationId`** | `com.brijesh.business_manager.dev` | `com.brijesh.business_manager` |
| **iOS / macOS Bundle ID** | `com.brijesh.businessManager.dev` | `com.brijesh.businessManager` |
| **App Display Name (EN)** | `Business Manager Dev` | `Business Manager` |
| **App Display Name (GU)** | `બિઝનેસ મેનેજર (Dev)` | `બિઝનેસ મેનેજર` |
| **SQLite Database File** | `business_manager_dev.sqlite` | `business_manager_prod.sqlite` |
| **Media Subdirectory** | `media_dev/` | `media_prod/` |
| **Debug Logging** | Enabled (`true`) | Disabled (`false`) |
| **Visual Dev Indicator** | Subtle `DEV` badge in Settings/AppBar | None |
| **Entrypoint** | `lib/main_dev.dart` | `lib/main_prod.dart` |
| **Config File** | `config/dev.local.json` | `config/prod.local.json` |

---

## 2. Platform-Specific Implementation Strategy

### Android (`android/app/build.gradle.kts`) — Primary Priority
Use native Gradle `productFlavors` (existing namespace `com.brijesh.business_manager`):
```kotlin
buildFeatures {
    resValues = true
}

flavorDimensions += "environment"
productFlavors {
    create("dev") {
        dimension = "environment"
        applicationIdSuffix = ".dev"
        versionNameSuffix = "-dev"
        resValue("string", "app_name", "Business Manager Dev")
    }
    create("prod") {
        dimension = "environment"
        resValue("string", "app_name", "Business Manager")
    }
}
```
Both `dev` and `prod` APKs can be installed **side-by-side on the same Android phone** with completely isolated Android sandboxes.

### iOS & macOS (Xcode Schemes & Build Configurations)
- Create two Xcode Schemes (`dev`, `prod`) mapped to `Debug-dev` / `Release-dev` and `Debug-prod` / `Release-prod` `.xcconfig` files defining `PRODUCT_BUNDLE_IDENTIFIER` and `APP_DISPLAY_NAME`.

### Web, Windows & Linux (`--dart-define-from-file`)
- Native Gradle/Xcode flavors do not apply to Web/Windows/Linux.
- Pass `config/dev.local.json` or `config/prod.local.json` via `--dart-define-from-file=config/dev.local.json` + `-t lib/main_dev.dart`.
- `AppConfig` reads compile-time constants (`String.fromEnvironment('APP_FLAVOR')`, `bool.fromEnvironment('ENABLE_DEBUG_LOGS')`) and routes DB/media paths to `<flavor>`-scoped directories (or flavor-prefixed OPFS/IndexedDB database names on Web).

---

## 3. Build & Run Commands

```bash
# Android
flutter run --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.local.json
flutter build apk --release --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json

# Windows / Linux / macOS / Web
flutter run -d windows -t lib/main_dev.dart --dart-define-from-file=config/dev.local.json
flutter build web --release -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json
```
