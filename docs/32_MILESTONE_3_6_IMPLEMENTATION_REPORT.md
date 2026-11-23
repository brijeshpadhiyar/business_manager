# 32 — Milestone 3.6 Implementation Report (StitchFlow APK Build Automation)

**Completed Date:** 2026-11-23  
**Milestone Scope:** One-command Windows APK build automation (`build_apk.bat` + `scripts/build_apk.ps1`) with Asia/Kolkata timestamping, flavor-isolated output directories under `build/releases/`, stale-APK protection, `.gitignore` rules, full testing across all 4 flavor/mode combinations + error cases, and documentation.

---

## 1. Scripts & Configuration Files Created / Updated

- **Created:**
  - `build_apk.bat` — Root-level Windows CMD & PowerShell entrypoint delegating to `scripts/build_apk.ps1` and propagating exact exit codes.
  - `scripts/build_apk.ps1` — Strict-mode PowerShell build orchestrator (argument validation, Flutter PATH check, stale APK removal, timed `flutter build apk`, Asia/Kolkata IST timestamping, same-second collision suffix `_01`/`_02`, size-verified copy, formatted summary output).
  - `docs/31_STITCHFLOW_BUILD_AUTOMATION.md` — Developer & release build guide.
- **Updated:**
  - `.gitignore` — Added `/build/releases/` and `*.apk` while keeping `build_apk.bat`, `scripts/`, and `docs/` tracked.
  - `android/app/src/main/res/drawable-nodpi/splash_brand_dark.png` — Moved from `drawable-night-nodpi/` to `drawable-nodpi/` to resolve Android Release Lint `MissingDefaultResource` discovered during the first `assembleDevRelease` test (zero visual/branding change).
  - `README.md`, `CHANGELOG.md`.

---

## 2. Commands Tested & Example Generated APK Filenames

| Test Case | Command | Result | Output / Verified Behavior |
| :--- | :--- | :---: | :--- |
| Missing flavor | `.\build_apk.bat` | **PASS** | Prints usage, exit code `1` |
| Invalid flavor | `.\build_apk.bat staging` | **PASS** | Prints error + usage, exit code `1` |
| Invalid mode | `.\build_apk.bat dev profile` | **PASS** | Prints error + usage, exit code `1` |
| Build failure handling | `.\build_apk.bat dev` (before lint fix) | **PASS** | Stopped on exit code `1`, copied **0** stale APKs |
| Dev Release | `.\build_apk.bat dev` | **PASS** | `build\releases\dev\StitchFlow_Dev_20261123_123709.apk` (`60.88 MB`, `84.2s`, `com.brijesh.stitchflow.dev`) |
| Prod Release | `.\build_apk.bat prod` | **PASS** | `build\releases\prod\StitchFlow_Prod_20261123_123832.apk` (`60.88 MB`, `81.6s`, `com.brijesh.stitchflow`) |
| Dev Debug | `.\build_apk.bat dev debug` | **PASS** | `build\releases\dev\StitchFlow_Dev_20261123_123855_debug.apk` (`170.18 MB`, `23.3s`) |
| Prod Debug | `.\build_apk.bat prod debug` | **PASS** | `build\releases\prod\StitchFlow_Prod_20261123_124005_debug.apk` (`169.88 MB`, `69.1s`) |
| Previous APK preservation | Listed `build\releases\` after all 4 builds | **PASS** | All 4 APKs preserved side-by-side with zero overwrites |
| Static analysis | `flutter analyze` | **PASS** | `No issues found!` |
| Automated tests | `flutter test` | **PASS** | `42 / 42` tests passed |

---

## 3. Verified Output Folder Structure

```text
build/releases/
├── dev/
│   ├── StitchFlow_Dev_20261123_123709.apk
│   └── StitchFlow_Dev_20261123_123855_debug.apk
└── prod/
    ├── StitchFlow_Prod_20261123_123832.apk
    └── StitchFlow_Prod_20261123_124005_debug.apk
```

---

## 4. Known Limitations

- **Windows Entrypoint:** `build_apk.bat` + `scripts/build_apk.ps1` target Windows CMD/PowerShell as requested; a macOS/Linux `.sh` equivalent can be added later if needed.
- **Release Signing:** Local release APKs currently sign with Android debug keys until a production keystore is configured prior to Play Store distribution.
