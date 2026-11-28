# 42 — Build Commands for All Platforms (dev / prod)

Every build picks a **flavour** in two places:

| What | dev | prod |
| :--- | :--- | :--- |
| Entry point (`-t`) | `lib/main_dev.dart` | `lib/main_prod.dart` |
| Settings (`--dart-define-from-file`) | `config/dev.local.json` | `config/prod.local.json` |
| Database file | `business_manager_dev.sqlite` | `business_manager_prod.sqlite` |
| Photos folder | `media_dev/` | `media_prod/` |
| Android app id | `com.brijesh.stitchflow.dev` | `com.brijesh.stitchflow` |
| App name | StitchFlow Dev | StitchFlow |

dev and prod never share data: they use different database and photo files on
every platform.

Native `--flavor` support:

| Platform | `--flavor dev/prod` | How the flavour is chosen |
| :--- | :--- | :--- |
| Android | ✅ Yes (Gradle `productFlavors`) | `--flavor` + `-t` + config file |
| iOS | ✅ Yes (`dev` / `prod` Xcode schemes) | `--flavor` + `-t` + config file |
| macOS | ✅ Yes (`dev` / `prod` Xcode schemes) | `--flavor` + `-t` + config file |
| Windows / Linux / Web | Not supported by Flutter | `-t` + config file only |

Always run first, once per checkout or after pulling changes:

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
```

---

## 1. Android

**Needs:** Android SDK (any OS). Prod release also needs `android/key.properties`
(copy `android/key.properties.example`) and the upload keystore. Without it, a
prod release build stops with an error on purpose; dev release falls back to
debug signing for local QA.

```bash
# Run on a phone / emulator
flutter run --flavor dev  -t lib/main_dev.dart  --dart-define-from-file=config/dev.local.json
flutter run --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json

# APK (install directly / share on WhatsApp)
flutter build apk --release --flavor dev  -t lib/main_dev.dart  --dart-define-from-file=config/dev.local.json
flutter build apk --release --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json

# Smaller APKs, one per CPU type (arm64 is right for almost all phones)
flutter build apk --release --split-per-abi --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json

# App bundle for Google Play (prod only)
flutter build appbundle --release --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json
```

Output:
- APK: `build/app/outputs/flutter-apk/app-<flavor>-release.apk`
- AAB: `build/app/outputs/bundle/prodRelease/app-prod-release.aab`

Shortcut script (Windows): `.\build_apk.bat prod`, `.\build_apk.bat dev`,
`.\build_apk.bat prod debug`.

---

## 2. Windows (.exe)

**Needs:** a Windows PC with Visual Studio 2022 and the
**"Desktop development with C++"** workload (`flutter doctor` must show ✓ for
Visual Studio).

```powershell
# Run while developing
flutter run -d windows -t lib/main_dev.dart --dart-define-from-file=config/dev.local.json

# Release build
flutter build windows --release -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json
flutter build windows --release -t lib/main_dev.dart  --dart-define-from-file=config/dev.local.json
```

Output: `build\windows\x64\runner\Release\` → `StitchFlow.exe` **plus** its
DLLs and the `data` folder. Ship the **whole folder** (zip it or wrap it in an
installer); the `.exe` alone will not start.

Both flavours build into the same folder, so copy the folder away (for example
`StitchFlow-prod\`) before building the other flavour.

Where data lives: `%APPDATA%\com.brijesh\StitchFlow\` (`db\` and the photo
folder). It is a private per-user folder, not Documents, so OneDrive cannot
lock or corrupt the live database. Only one StitchFlow window can run at a
time; opening it again brings the existing window forward.

---

## 3. iOS

**Needs:** a Mac with Xcode, CocoaPods, and an Apple Developer account for
device / App Store builds. iOS cannot be built on Windows.

### 3.1 Until flavours are wired in Xcode (current state)

```bash
# Run on simulator / iPhone
flutter run -t lib/main_dev.dart  --dart-define-from-file=config/dev.local.json
flutter run -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json

# App Store / TestFlight archive (prod)
flutter build ipa --release -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json

# Unsigned build check (no Apple account needed)
flutter build ios --release --no-codesign -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json
```

Output: `build/ios/ipa/*.ipa` (upload with Transporter or Xcode Organizer).

Note: today dev and prod iOS builds share the bundle id `com.brijesh.stitchflow`,
so installing one replaces the other on the same iPhone. Their data stays
separate (different database files).

### 3.2 After flavours are wired (§3.3)

```bash
flutter run --flavor dev  -t lib/main_dev.dart  --dart-define-from-file=config/dev.local.json
flutter build ipa --release --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json
flutter build ipa --release --flavor dev  -t lib/main_dev.dart  --dart-define-from-file=config/dev.local.json
```

### 3.3 One-time Xcode setup for iOS flavours (on the Mac)

`ios/Flutter/Flavor-dev.xcconfig` and `Flavor-prod.xcconfig` already hold the
bundle ids and display names; Xcode just needs to use them.

1. Open `ios/Runner.xcworkspace` in Xcode → select the **Runner project** →
   **Info** → **Configurations**.
2. Duplicate each of Debug, Release and Profile twice and name them:
   `Debug-dev`, `Release-dev`, `Profile-dev`, `Debug-prod`, `Release-prod`,
   `Profile-prod` (names must be exactly this).
3. For each new configuration, set the **Runner** target's configuration file
   to a new xcconfig that includes both files, e.g. `ios/Flutter/Debug-dev.xcconfig`:
   ```
   #include "Debug.xcconfig"
   #include "Flavor-dev.xcconfig"
   ```
   (Release/Profile ones include `Release.xcconfig`; prod ones include
   `Flavor-prod.xcconfig`.) Keep the CocoaPods `#include?` line that
   `pod install` adds.
4. Runner target → **Build Settings**: set `PRODUCT_BUNDLE_IDENTIFIER` to
   `$(PRODUCT_BUNDLE_IDENTIFIER)` from the xcconfig (delete the hard-coded value),
   and in `Info.plist` set `CFBundleDisplayName` to `$(APP_DISPLAY_NAME)`.
5. **Product → Scheme → Manage Schemes**: duplicate `Runner` into schemes named
   `dev` and `prod`; in each scheme use the matching `-dev` / `-prod`
   configurations for Run, Test, Profile, Analyze and Archive. Tick **Shared**.
6. Run `cd ios && pod install`, then the §3.2 commands.

---

## 4. macOS

**Needs:** a Mac with Xcode.

```bash
flutter run -d macos -t lib/main_dev.dart --dart-define-from-file=config/dev.local.json
flutter build macos --release -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json
```

Output: `build/macos/Build/Products/Release/StitchFlow.app`. Sign and
notarize it before giving it to other Macs.

---

## 5. Linux

**Needs:** a Linux machine with `clang cmake ninja-build pkg-config libgtk-3-dev`
(plus `libsecret-1-dev` for secure storage).

```bash
flutter run -d linux -t lib/main_dev.dart --dart-define-from-file=config/dev.local.json
flutter build linux --release -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json
```

Output: `build/linux/x64/release/bundle/` (ship the whole folder).

---

## 6. Web

**Needs:** Chrome (any OS).

```bash
flutter run -d chrome -t lib/main_dev.dart --dart-define-from-file=config/dev.local.json
flutter build web --release -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json
```

Output: `build/web/` — upload the folder to any static host. Data is stored in
the browser; use **Backup → Web backup (.json)** to keep a copy.

---

## 7. Versioning

Version and build number come from `pubspec.yaml` (`version: 1.3.0+4`) on every
platform (Android versionName/versionCode, iOS/macOS short version/build,
Windows file version). Override for one build:

```bash
flutter build apk --release --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json --build-name=1.4.0 --build-number=5
```

## 8. Quick reference

| Platform | prod release command |
| :--- | :--- |
| Android APK | `flutter build apk --release --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json` |
| Android Play | `flutter build appbundle --release --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json` |
| Windows | `flutter build windows --release -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json` |
| iOS | `flutter build ipa --release -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json` |
| macOS | `flutter build macos --release -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json` |
| Linux | `flutter build linux --release -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json` |
| Web | `flutter build web --release -t lib/main_prod.dart --dart-define-from-file=config/prod.local.json` |

For dev, swap `prod` → `dev` in the flavour, entry point and config file.
