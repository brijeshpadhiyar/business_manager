# 28 — StitchFlow Brand & Application Identity Specification

**Effective Date:** 2026-11-23  
**Status:** FINAL (Approved Official Identity)

---

## 1. Official Brand Identity

- **Application Name:** `StitchFlow` (`સ્ટિચફ્લો` in Gujarati)
- **Short Name:** `StitchFlow`
- **Development Flavor Display Name:** `StitchFlow Dev` (`સ્ટિચફ્લો (Dev)` in Gujarati)
- **Tagline:** `From Fabric to Finished.` (`કાપડથી તૈયાર વસ્ત્ર સુધી.` in Gujarati)
- **Category:** Garment & Production Management
- **Architecture:** 100% Offline-First Multi-Platform Flutter Application

---

## 2. Logo System (Concept A — Thread S)

- **Symbol:** Clean, minimal S-shaped continuous Teal thread (`#0D9488`) crossed by an Amber needle/thread accent (`#F4A340`), engineered to remain crisp and recognizable at `16px–48px` launcher sizes with proper safe-area margins.
- **Master Assets (`assets/branding/logo/`):**
  - `stitchflow_symbol.svg` / `stitchflow_symbol.png` (`1024×1024`)
  - `stitchflow_logo.svg` / `stitchflow_logo.png` (`1024×1024`, primary vertical on Soft White `#F5F7FA`)
  - `stitchflow_logo_horizontal.svg` / `stitchflow_logo_horizontal.png` (`1600×512`)
  - `stitchflow_logo_dark.svg` (Dark Navy `#172B4D` background)
  - `stitchflow_logo_monochrome.svg` (Single-color Deep Navy `#172B4D`)

---

## 3. Official Brand Color Tokens (`lib/core/design_system/app_colors.dart`)

| Token | Hex | Role |
| :--- | :---: | :--- |
| `AppColors.brandNavy` | `#172B4D` | Primary brand color, dark splash background, adaptive icon background |
| `AppColors.brandTeal` | `#0D9488` | Secondary actions, highlights, Thread S stroke |
| `AppColors.brandAmber` | `#F4A340` | Selected accents, needle accent, dark tagline |
| `AppColors.brandSoftWhite` | `#F5F7FA` | Light surface & light splash background |

*All existing semantic status tokens (`goodStock`, `pending`, `damaged`, `advanceCredit`) and `ThemeCubit` (`System`, `Light`, `Dark`) are strictly preserved.*

---

## 4. Typography

- Preserves offline-bundled **Noto Sans Gujarati** (`Regular 400`, `Medium 500`, `SemiBold 600`, `Bold 700`) and existing compact Material 3 type scale (`AppTypography`) with zero additional font dependencies.

---

## 5. Official Platform Identifiers & Flavor Separation

| Platform | Production Identifier / Name | Development Identifier / Name |
| :--- | :--- | :--- |
| **Android** | `com.brijesh.stitchflow` / `StitchFlow` | `com.brijesh.stitchflow.dev` / `StitchFlow Dev` |
| **iOS** | `com.brijesh.stitchflow` / `StitchFlow` (`Flavor-prod.xcconfig`) | `com.brijesh.stitchflow.dev` / `StitchFlow Dev` (`Flavor-dev.xcconfig`) |
| **macOS** | `com.brijesh.stitchflow` / `StitchFlow` (`Flavor-prod.xcconfig`) | `com.brijesh.stitchflow.dev` / `StitchFlow Dev` (`Flavor-dev.xcconfig`) |
| **Windows** | `StitchFlow` (`Runner.rc`, `main.cpp`) | `StitchFlow Dev` (via `AppIdentity.displayNameFor(config)` / `--dart-define-from-file`) |
| **Linux** | `com.brijesh.stitchflow` / `StitchFlow` | `StitchFlow Dev` (via `AppIdentity.displayNameFor(config)` / `--dart-define-from-file`) |
| **Web (PWA)** | `StitchFlow` (Short: `StitchFlow`) | `StitchFlow Dev` (runtime title via `onGenerateTitle`) |

---

## 6. Versioning Strategy

- Version and build number are managed centrally in `pubspec.yaml` (`version: 1.0.0+1`).
- Both `dev` and `prod` share the same semantic version (`1.0.0+1`); Android `dev` appends `versionNameSuffix = "-dev"` (`1.0.0-dev`) for unambiguous QA identification.

---

## 7. Asset Naming, Icon Specifications & Splash Screens

- **Android:** Adaptive icon (`mipmap-anydpi-v26/ic_launcher.xml` + `drawable-nodpi/ic_launcher_foreground.png` [66% safe zone] + `@color/ic_launcher_background` `#172B4D` + `ic_launcher_monochrome.png`), legacy `mipmap-{mdpi..xxxhdpi}/ic_launcher.png`, and Light/Dark native splash (`drawable/launch_background.xml` + `drawable-night/launch_background.xml`).
- **iOS:** Opaque Navy `1024×1024` master + full `ios/Runner/Assets.xcassets/AppIcon.appiconset/` PNG set (no alpha channel per Apple HIG).
- **macOS:** Full `macos/Runner/Assets.xcassets/AppIcon.appiconset/` PNG set + `assets/branding/icons/stitchflow_macos.icns`.
- **Windows:** Multi-resolution `windows/runner/resources/app_icon.ico` (`16, 24, 32, 48, 64, 128, 256 px`).
- **Linux:** `assets/branding/icons/stitchflow_linux_512.png` & `stitchflow_linux.svg`.
- **Web:** `web/favicon.png` (`64×64`), `web/icons/Icon-{192,512}.png`, and safe-area `web/icons/Icon-maskable-{192,512}.png`.

---

## 8. Deep-Link Scheme (`stitchflow://`)

- **Android:** Registered `<intent-filter>` (`ACTION_VIEW`, `DEFAULT`, `BROWSABLE`, `android:scheme="stitchflow"`) in `AndroidManifest.xml`.
- **iOS:** Registered `CFBundleURLTypes` (`stitchflow`) in `ios/Runner/Info.plist`.
- **Scope Note:** Native URL scheme registration is configured; full feature deep-link route parsing (e.g., `stitchflow://lot/<id>`) will be wired and tested once feature routes are implemented in Milestones 4+.

---

## 9. Release & Signing Notes

- Before Play Store / App Store release, replace the temporary debug signing config in `android/app/build.gradle.kts` with an encrypted release keystore (`key.properties`, never committed to Git) and configure Xcode `dev` & `prod` schemes on macOS using `Flavor-dev.xcconfig` / `Flavor-prod.xcconfig`.
