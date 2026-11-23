# 29 — Milestone 3.5 Implementation Report (StitchFlow Branding & Application Identity)

**Completed Date:** 2026-11-23  
**Milestone Scope:** Official StitchFlow ("Concept A — Thread S") logo/icon/splash asset generation, brand color integration into Material 3 design system, centralized `AppIdentity`, cross-platform application identifier migration, `stitchflow://` URL scheme registration, data safety verification, and full build/test validation. Zero Milestone 4 business features or database schema changes implemented.

---

## 1. Data Safety Audit (Pre-Migration Check)

- **Previous Identifiers Recorded:**
  - Android: `com.brijesh.business_manager` (prod) / `com.brijesh.business_manager.dev` (dev)
  - iOS / macOS: `com.brijesh.businessManager`
  - Linux: `com.brijesh.business_manager`
  - Windows / Web: `business_manager`
- **Local Data Inspection:** Checked `%USERPROFILE%\Documents\db` and `%APPDATA%\com.brijesh` prior to editing; confirmed **0 existing local test databases or media files** on this host.
- **Database Schema Guarantee:** Zero changes made to `docs/07_database_schema.md`, Drift tables, or schema version (`schemaVersion = 1` preserved intact).

---

## 2. Branding Assets Generated & Visually Inspected

Generated clean geometric vector SVGs and 4x supersampled anti-aliased rasters (visually inspected via `stitchflow_brand_preview.png` and `stitchflow_logo_horizontal.png`):
- **Master Logos (`assets/branding/logo/`):** `stitchflow_logo.svg`, `stitchflow_logo.png`, `stitchflow_logo_horizontal.svg`, `stitchflow_logo_horizontal.png`, `stitchflow_logo_dark.svg`, `stitchflow_logo_monochrome.svg`, `stitchflow_symbol.svg`, `stitchflow_symbol.png`.
- **Platform Icons (`assets/branding/icons/` + native folders):** Android adaptive foreground/background/monochrome + mipmaps (`mdpi`–`xxxhdpi`), iOS `AppIcon.appiconset` (opaque Navy), macOS `AppIcon.appiconset` + `stitchflow_macos.icns`, Windows multi-size `app_icon.ico`, Linux `512px` PNG + SVG, Web `favicon.png` + PWA standard & maskable icons.
- **Splash Screens (`assets/branding/splash/` + Android `drawable` / `drawable-night`):** Light (`#F5F7FA`) and Dark (`#172B4D`) StitchFlow branded launch screens.

---

## 3. Platform Configuration Changes & Final Identifiers

| Platform | Files Updated | Final Identifiers / Names | Validation Status |
| :--- | :--- | :--- | :--- |
| **Android** | `build.gradle.kts`, `MainActivity.kt` (moved to `com/brijesh/stitchflow/`), `AndroidManifest.xml`, `colors.xml`, `ic_launcher.xml`, `launch_background.xml` (light & night) | Dev: `com.brijesh.stitchflow.dev` (`StitchFlow Dev`); Prod: `com.brijesh.stitchflow` (`StitchFlow`); Scheme: `stitchflow://` | **Built & Verified** (both `dev` & `prod` APKs built) |
| **Web** | `web/manifest.json`, `web/index.html`, `web/favicon.png`, `web/icons/*.png` | `StitchFlow` (`#172B4D` theme/bg) | Config & assets verified |
| **Windows** | `Runner.rc`, `main.cpp`, `resources/app_icon.ico` | Product/Window: `StitchFlow` | Metadata & `.ico` verified |
| **Linux** | `linux/CMakeLists.txt`, `my_application.cc`, `assets/branding/icons/stitchflow_linux*` | `com.brijesh.stitchflow` / `StitchFlow` | Config verified (Linux build requires Linux host) |
| **iOS** | `Info.plist` (`stitchflow://` URL scheme), `project.pbxproj`, `Flavor-dev.xcconfig`, `Flavor-prod.xcconfig`, `AppIcon.appiconset` | Dev: `com.brijesh.stitchflow.dev`; Prod: `com.brijesh.stitchflow` | Config & icons verified (Xcode scheme wiring & build require macOS) |
| **macOS** | `AppInfo.xcconfig`, `project.pbxproj`, `Flavor-dev.xcconfig`, `Flavor-prod.xcconfig`, `AppIcon.appiconset`, `stitchflow_macos.icns` | Dev: `com.brijesh.stitchflow.dev`; Prod: `com.brijesh.stitchflow` | Config & icons verified (Xcode scheme wiring & build require macOS) |

---

## 4. Design System, Identity & Localization Integration

- Created `lib/core/config/app_identity.dart` exposing `StitchFlow`, `From Fabric to Finished.`, `stitchflow` URL scheme, flavor display names, and platform IDs.
- Integrated `#172B4D` (Deep Navy), `#0D9488` (Teal), `#F4A340` (Amber), and `#F5F7FA` (Soft White) into `AppColors` and `AppTheme.light()` / `AppTheme.dark()` while keeping all semantic status colors (`goodStock`, `pending`, `damaged`, `advanceCredit`) and `ThemeCubit` untouched.
- Updated `app_en.arb` / `app_gu.arb` with `StitchFlow` / `સ્ટિચફ્લો`, `StitchFlow Dev` / `સ્ટિચફ્લો (Dev)`, and `From Fabric to Finished.` / `કાપડથી તૈયાર વસ્ત્ર સુધી.`.
- Added `test/unit/app_identity_branding_test.dart` (5 new tests covering identity, flavor separation, brand hex tokens, theme integration, and on-disk asset verification).

---

## 5. Commands Executed & Results

| Command | Result |
| :--- | :--- |
| `flutter pub get` | **PASS** |
| `flutter gen-l10n` | **PASS** (`0` untranslated keys) |
| `dart run build_runner build` | **PASS** (`0` warnings) |
| `dart format .` | **PASS** (101 files formatted) |
| `flutter analyze` | **PASS** (`No issues found!`) |
| `flutter test` | **PASS** (`35 / 35` tests passed) |
| `flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json` | **PASS** (`app-dev-debug.apk`) |
| `flutter build apk --debug --flavor prod -t lib/main_prod.dart --dart-define-from-file=config/prod.json` | **PASS** (`app-prod-debug.apk`) |

---

## 6. Known Limitations & Remaining Manual Steps

- **iOS / macOS Xcode Schemes:** `Flavor-dev.xcconfig` and `Flavor-prod.xcconfig` are prepared in `ios/Flutter/` and `macos/Runner/Configs/`; linking them to dedicated `dev` and `prod` Xcode Schemes requires opening the project in Xcode on macOS.
- **Linux / iOS / macOS Native Builds:** Not compiled on this Windows host; verified configuration files and icon assets only.
- **Deep-Link Route Handling:** `stitchflow://` native scheme registration is complete; feature deep-link routes will be connected in Milestones 4+.
