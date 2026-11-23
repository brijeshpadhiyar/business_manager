# 31 — StitchFlow APK Build Automation Guide

## 1. Quick Commands (Windows PowerShell & CMD)

Run from the project root (`c:\A1\business_manager`):

```powershell
# Development Release APK (default mode)
.\build_apk.bat dev

# Production Release APK (default mode)
.\build_apk.bat prod

# Development Debug APK (optional mode)
.\build_apk.bat dev debug

# Production Debug APK (optional mode)
.\build_apk.bat prod debug
```

*Running `.\build_apk.bat` with no arguments or an invalid flavor/mode prints clear usage instructions and exits with status code `1`.*

---

## 2. Flavor & Build Mode Matrix

| Command | Flavor | Mode | Application ID | Entrypoint | Config File |
| :--- | :---: | :---: | :--- | :--- | :--- |
| `.\build_apk.bat dev` | `dev` | `release` | `com.brijesh.stitchflow.dev` | `lib/main_dev.dart` | `config/dev.json` |
| `.\build_apk.bat prod` | `prod` | `release` | `com.brijesh.stitchflow` | `lib/main_prod.dart` | `config/prod.json` |
| `.\build_apk.bat dev debug` | `dev` | `debug` | `com.brijesh.stitchflow.dev` | `lib/main_dev.dart` | `config/dev.json` |
| `.\build_apk.bat prod debug` | `prod` | `debug` | `com.brijesh.stitchflow` | `lib/main_prod.dart` | `config/prod.json` |

---

## 3. Output Directory Structure & Naming Format

All packaged APKs are stored under `build/releases/` (excluded from Git via `.gitignore`):

```text
build/
└── releases/
    ├── dev/
    │   ├── StitchFlow_Dev_YYYYMMDD_HHMMSS.apk
    │   └── StitchFlow_Dev_YYYYMMDD_HHMMSS_debug.apk
    └── prod/
        ├── StitchFlow_Prod_YYYYMMDD_HHMMSS.apk
        └── StitchFlow_Prod_YYYYMMDD_HHMMSS_debug.apk
```

- **Timestamp Timezone:** Always generated in **Asia/Kolkata (`India Standard Time`, UTC+05:30)** regardless of the build machine's local timezone.
- **No Overwrite Guarantee:** Previous APKs are never overwritten. If two builds complete within the same second, a numeric suffix (`_01`, `_02`, ...) is appended automatically.
- **Stale APK Safety:** Any prior `build/app/outputs/flutter-apk/app-<flavor>-<mode>.apk` is cleared before invoking `flutter build apk`, so a failed build can never copy an old APK.

---

## 4. Troubleshooting

- **`'flutter' was not found on PATH`:** Install the Flutter SDK and add `<flutter_sdk>\bin` to your Windows System `PATH`, then reopen your terminal.
- **Gradle / Android Lint Failure:** Inspect the Gradle output directly above `[ERROR] Flutter build failed`. No APK is copied when Gradle returns a non-zero exit code.
- **Release Signing Note:** Currently `android/app/build.gradle.kts` uses debug signing for local release APK testing. Configure a private release keystore (`key.properties`) before Play Store publication (`docs/28_STITCHFLOW_BRAND_AND_APP_IDENTITY.md`).
