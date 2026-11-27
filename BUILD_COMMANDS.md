# StitchFlow — Build Commands (All Platforms)

Complete run and build commands for **Android**, **Windows**, **iOS**, **macOS**, **Linux**, and **Web** across both **`dev`** and **`prod`** flavours.

---

## 0. One-Time Setup & Pre-Build Checks

1. Create local flavour config files (if not already present — `*.local.json` files are gitignored):
   ```powershell
   Copy-Item config\dev.example.json config\dev.local.json
   Copy-Item config\prod.example.json config\prod.local.json
   ```
   Fill in `SUPABASE_URL` and `SUPABASE_ANON_KEY` (and Google client IDs if using Google Sign-In) in both files.

2. Run dependencies, localization, codegen, and verification checks from the project root:
   ```powershell
   flutter pub get
   flutter gen-l10n
   dart run build_runner build --delete-conflicting-outputs
   flutter analyze --fatal-infos
   flutter test
   ```

---

## Flavour Overview (`dev` vs `prod`)

| Setting | `dev` | `prod` |
| :--- | :--- | :--- |
| Entry point (`-t`) | `lib/main_dev.dart` | `lib/main_prod.dart` |
| Config file (`--dart-define-from-file`) | `config/dev.local.json` | `config/prod.local.json` |
| SQLite database | `business_manager_dev.sqlite` | `business_manager_prod.sqlite` |
| Media folder | `media_dev/` | `media_prod/` |
| `--flavor` flag | Android (and iOS once Xcode schemes are wired) | Android (and iOS once Xcode schemes are wired) |

> **Important:** Do **not** pass `--flavor` for **Windows, macOS (current), Linux, or Web** — Flutter selects the flavour on those targets using `-t` and `--dart-define-from-file`.

---

## 1. Android (`.apk` / `.aab`)

**Prerequisites:** Android SDK. For `prod` release signing, copy `android/key.properties.example` to `android/key.properties` and configure your upload keystore.

### Shortcut Batch Script (Windows)
```powershell
# Dev Release APK -> build/releases/dev/StitchFlow_Dev_YYYYMMDD_HHMMSS.apk
.\build_apk.bat dev

# Prod Release APK -> build/releases/prod/StitchFlow_Prod_YYYYMMDD_HHMMSS.apk
.\build_apk.bat prod

# Optional Debug APKs
.\build_apk.bat dev debug
.\build_apk.bat prod debug
```

### Direct Flutter Commands
```powershell
# Run on connected phone / emulator
flutter run --flavor dev  -t lib/main_dev.dart  --dart-define-from-file=config/dev.local.json
flutter run --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json

# Universal Release APK
flutter build apk --release --flavor dev  -t lib/main_dev.dart  --dart-define-from-file=config/dev.local.json
flutter build apk --release --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json

# Smaller per-ABI APKs (arm64-v8a fits most modern Android phones)
flutter build apk --release --split-per-abi --flavor dev  -t lib/main_dev.dart  --dart-define-from-file=config/dev.local.json
flutter build apk --release --split-per-abi --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json

# Play Store App Bundle (.aab)
flutter build appbundle --release --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json
```

- **APK output:** `build\app\outputs\flutter-apk\app-<flavor>-release.apk`
- **AAB output:** `build\app\outputs\bundle\prodRelease\app-prod-release.aab`

---

## 2. Windows (`.exe`)

**Prerequisites:**
1. **Visual Studio 2022** with the **"Desktop development with C++"** workload (`flutter doctor` must pass for Visual Studio).
2. **`nuget.exe`** on `PATH` (required by the `flutter_tts` plugin to fetch `Microsoft.Windows.CppWinRT`):
   ```powershell
   winget install Microsoft.NuGet
   ```
   Open a **new** terminal (or restart your IDE) so `PATH` reloads, then verify:
   ```powershell
   where.exe nuget
   ```
   > If an earlier build failed before `nuget.exe` was installed, delete the cached CMake folder first so CMake stops using `NUGET_EXE-NOTFOUND`:
   > ```powershell
   > if (Test-Path build\windows) { Remove-Item -Recurse -Force build\windows }
   > ```

### Commands (PowerShell)
```powershell
# Run locally in dev mode
flutter run -d windows -t lib/main_dev.dart --dart-define-from-file=config/dev.local.json

# Build DEV Release .exe
flutter build windows --release -t lib/main_dev.dart --dart-define-from-file=config/dev.local.json

# Build PROD Release .exe
flutter build windows --release -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json

# Optional Debug .exe builds
flutter build windows --debug -t lib/main_dev.dart  --dart-define-from-file=config/dev.local.json
flutter build windows --debug -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json
```

- **Release output:** `build\windows\x64\runner\Release\` (`StitchFlow.exe`, required `.dll` files, and `data\` folder).
- **Debug output:** `build\windows\x64\runner\Debug\`
- **Distribution note:** Always copy or zip the **entire `Release\` folder**; `StitchFlow.exe` cannot run alone without its DLLs and `data\` directory. Since `dev` and `prod` build to the same `Release\` path, copy/rename the folder (e.g. `StitchFlow-dev\`) before building the other flavour.
- **App data location:** `%APPDATA%\com.brijesh\StitchFlow\`

---

## 3. Web

**Prerequisites:** Chrome (for local run).

```bash
# Run locally in Chrome
flutter run -d chrome -t lib/main_dev.dart  --dart-define-from-file=config/dev.local.json
flutter run -d chrome -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json

# Build DEV Web bundle
flutter build web --release -t lib/main_dev.dart  --dart-define-from-file=config/dev.local.json

# Build PROD Web bundle
flutter build web --release -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json
```

- **Output:** `build/web/` (deployable to any static host).

---

## 4. iOS (macOS host required)

**Prerequisites:** Mac with Xcode, CocoaPods, and Apple Developer signing for device / App Store builds. See [docs/42_BUILD_COMMANDS_ALL_PLATFORMS.md](docs/42_BUILD_COMMANDS_ALL_PLATFORMS.md#3-ios) for optional Xcode scheme setup.

```bash
# Run on Simulator / iPhone
flutter run -t lib/main_dev.dart  --dart-define-from-file=config/dev.local.json
flutter run -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json

# Unsigned .app build verification (no Apple signing account needed)
flutter build ios --release --no-codesign -t lib/main_dev.dart  --dart-define-from-file=config/dev.local.json
flutter build ios --release --no-codesign -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json

# Signed IPA (TestFlight / App Store)
flutter build ipa --release -t lib/main_dev.dart  --dart-define-from-file=config/dev.local.json
flutter build ipa --release -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json
```

- **Output:** `build/ios/ipa/*.ipa` (or `build/ios/iphoneos/Runner.app` for `--no-codesign`).

---

## 5. macOS (macOS host required)

**Prerequisites:** Mac with Xcode.

```bash
# Run on macOS
flutter run -d macos -t lib/main_dev.dart  --dart-define-from-file=config/dev.local.json
flutter run -d macos -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json

# Build .app bundle
flutter build macos --release -t lib/main_dev.dart  --dart-define-from-file=config/dev.local.json
flutter build macos --release -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json
```

- **Output:** `build/macos/Build/Products/Release/StitchFlow.app`

---

## 6. Linux (Linux host required)

**Prerequisites:** `clang cmake ninja-build pkg-config libgtk-3-dev libsecret-1-dev`

```bash
# Run on Linux
flutter run -d linux -t lib/main_dev.dart  --dart-define-from-file=config/dev.local.json
flutter run -d linux -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json

# Build Linux bundle
flutter build linux --release -t lib/main_dev.dart  --dart-define-from-file=config/dev.local.json
flutter build linux --release -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json
```

- **Output:** `build/linux/x64/release/bundle/` (ship the entire bundle directory).

---

## 7. Overriding Version & Build Number

Default version comes from `pubspec.yaml` (`version: ...`). Override for any single build command with:

```powershell
--build-name=1.9.0 --build-number=10
```

Example:
```powershell
flutter build windows --release -t lib/main_dev.dart --dart-define-from-file=config/dev.local.json --build-name=1.9.0 --build-number=10
```
