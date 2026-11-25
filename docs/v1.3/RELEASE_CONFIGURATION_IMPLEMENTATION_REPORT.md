# StitchFlow V1.3 — Release Configuration Implementation Report

**Date:** 2026-11-24  
**Scope:** Phase 1 — Production Release Signing (PR-01) & Version Synchronization (PR-02)  
**Status:** Implemented & Verified (Local Upload Keystore Required for Signed Production APK)

---

## 1. Audit Findings Addressed

| Finding | Description | Resolution |
| :--- | :--- | :--- |
| **PR-01** | `android/app/build.gradle.kts` signed `release` builds with `signingConfigs.getByName("debug")`. | Implemented `key.properties`-backed `release` signing config with a flavor-aware fail-safe `GradleException` guard: `prod` / generic release builds strictly fail when `android/key.properties` is missing or incomplete, while `dev` release builds (`com.brijesh.stitchflow.dev`) fall back to debug signing with an explicit warning for local QA. Debug builds continue to use the Android debug keystore. |
| **PR-02** | Version mismatch between `pubspec.yaml` (`1.0.0+1`) and `lib/core/config/app_identity.dart` (`1.2.0` / `2`). | Synchronized both `pubspec.yaml` and `AppIdentity` to **`1.3.0+4`** (`appVersion = '1.3.0'`, `appBuildNumber = '4'`). |

---

## 2. Files Changed

- [`android/app/build.gradle.kts`](file:///c:/A1/business_manager/android/app/build.gradle.kts) — Loads `android/key.properties` safely; configures `signingConfigs.create("release")` when complete; enforces `GradleException` when a release task (`*Release*`) runs without valid release signing credentials; keeps `buildTypes.debug` on `debug` signing.
- [`android/key.properties.example`](file:///c:/A1/business_manager/android/key.properties.example) — Safe placeholder template documenting `storePassword`, `keyPassword`, `keyAlias`, and `storeFile` without real credentials.
- [`.gitignore`](file:///c:/A1/business_manager/.gitignore) — Added `android/key.properties`, `key.properties`, `*.jks`, `*.keystore`, and `*.p12` to prevent accidental secret commits.
- [`pubspec.yaml`](file:///c:/A1/business_manager/pubspec.yaml) — Updated `version: 1.3.0+4`.
- [`lib/core/config/app_identity.dart`](file:///c:/A1/business_manager/lib/core/config/app_identity.dart) — Updated `appVersion = '1.3.0'` and `appBuildNumber = '4'`.
- [`test/unit/app_identity_branding_test.dart`](file:///c:/A1/business_manager/test/unit/app_identity_branding_test.dart) — Added assertions for `AppIdentity.appVersion == '1.3.0'` and `AppIdentity.appBuildNumber == '4'`.
- [`test/widget/v1_1_ux_settings_stock_workflows_test.dart`](file:///c:/A1/business_manager/test/widget/v1_1_ux_settings_stock_workflows_test.dart) — Updated About screen assertion from hardcoded `'1.2.0'` to `AppIdentity.appVersion`.

---

## 3. Local Upload Keystore & Signing Setup Guide

No real keystore, passwords, or `android/key.properties` file are committed to the repository. To build a production-signed APK or App Bundle locally:

### Step 1 — Generate an Upload Keystore (Outside Source Control)

```powershell
keytool -genkey -v -keystore "$HOME\stitchflow-upload-keystore.jks" `
  -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 `
  -alias stitchflow-upload
```

Back up the keystore file and passwords in your organization's password manager / secret vault.

### Step 2 — Create `android/key.properties` (Git-Ignored)

Copy `android/key.properties.example` to `android/key.properties` and populate your real values:

```properties
storePassword=<YOUR_KEYSTORE_PASSWORD>
keyPassword=<YOUR_KEY_PASSWORD>
keyAlias=stitchflow-upload
storeFile=C:/Users/<YOUR_USER>/stitchflow-upload-keystore.jks
```

### Step 3 — Build Production Artifacts

```powershell
# Production APK
flutter build apk --release --flavor prod -t lib/main_prod.dart

# Production Play Store App Bundle (AAB)
flutter build appbundle --release --flavor prod -t lib/main_prod.dart
```

---

## 4. Verification Results

| Check | Command | Outcome |
| :--- | :--- | :--- |
| Branding & version unit test | `flutter test test/unit/app_identity_branding_test.dart` | **PASSED** (5/5) |
| Dev release APK local QA fallback (no `android/key.properties`) | `.\build_apk.bat dev` | **PASSED** — Displayed `Signing : debug (dev fallback - local QA only)` and produced `build/releases/dev/StitchFlow_Dev_20261124_142651.apk` (76.45 MB) |
| Fail-safe prod release script guard (no `android/key.properties`) | `.\build_apk.bat prod` | **FAILED SAFELY AS DESIGNED** (exit code `1` with actionable `key.properties` instructions) |
| Fail-safe prod release Gradle guard (no `android/key.properties`) | `flutter build apk --release --flavor prod -t lib/main_prod.dart` | **FAILED SAFELY AS DESIGNED** at `android/app/build.gradle.kts:93` with `GradleException: Missing or incomplete Android release signing config for production release...` |
| Static analysis | `flutter analyze` | **PASSED** (0 issues) |

> **Release APK Status:** A production-signed APK was **not** built because no local `android/key.properties` or upload keystore exists in this workspace. The Gradle guard verified that release builds cannot silently fall back to debug signing.
