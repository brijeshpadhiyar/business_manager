# StitchFlow V1.2 — Final Production Release Report

**Product:** StitchFlow — *From Fabric to Finished.*  
**Version:** `1.2.0+3` (upgraded cleanly from `1.1.0+2`)  
**Release Date (IST):** 2026-11-23  
**Workspace:** `C:\A1\business_manager`  
**Flavors:** Dev (`com.brijesh.stitchflow.dev` / `StitchFlow Dev`) & Production (`com.brijesh.stitchflow` / `StitchFlow`)  
**Architecture Mode:** 100% Offline, Single-Owner Garment Workshop Application (English & Gujarati, Light / Dark / System Themes)

---

## 1. Executive Summary

StitchFlow V1.2 (`1.2.0+3`) delivers all five planned production milestones (`12.1` → `12.5`) on top of the verified V1.1 offline Flutter + Drift/SQLite + BLoC + GoRouter + `material_ui: ^1.11.1` architecture without resetting databases, altering historical accounting calculations, or introducing any cloud, Firebase, Supabase, or multi-user dependencies:

- **Milestone 12.1 (Local Security & App Lock):** Optional 4-digit or 6-digit local PIN hashed via salted PBKDF2-HMAC-SHA256 (`210,000` iterations in an Isolate), Android Keystore-backed `flutter_secure_storage`, optional Android BiometricPrompt unlock (`local_auth` v3 on `FlutterFragmentActivity`), configurable inactivity/background auto-lock, dynamic Android `FLAG_SECURE` + `PrivacyShieldOverlay`, persistent exponential brute-force lockout, offline 8-character Crockford Recovery Key flow, and re-authentication gates on Backup Restore and Raw SQLite Export. **Defaults to OFF for seamless V1.1 → V1.2 upgrade continuity.**
- **Milestone 12.2 (Faster Daily Workshop Operations):** IST-accurate *Today's Workshop* dashboard cards, *Important Pending Work* priority panel, dedicated `/daily-summary` production recap (`Today`, `Yesterday`, custom IST date), `WorkerDetailPage` live open-issues & balance overview with 1-tap return, Quick Issue recent in-stock & `(Process, Worker)` suggestion chips with unusual-action confirmation guard, Quick Return `Oldest First` default sorting with IST age badges, and `Half` / `+10` / `+25` / `Fill Remaining Good` / dynamic Next-Process settlement shortcuts.
- **Milestone 12.3 (Schema v3, Advanced Reports, Business Insights & Gujarati-Safe Exports):** Non-destructive SQLite Schema v2 → v3 upgrade adding 5 composite reporting indexes, single-pass `ReportsAnalyticsCalculator` covering **6 unified report categories** (Daily Workshop, Worker Performance, Process Performance with strictly verified turnaround time, Inventory, Labour & Financial, and Business Insights with lightweight `CustomPainter` trend charts, period-over-period comparisons, process bottlenecks, defect reasons, and labour cost share), plus **100% offline Gujarati-accurate Print/PDF** (native Android `WebView` + `PrintManager` loading bundled `NotoSansGujarati`), **MIT-licensed Excel (`.xlsx`)** via `excel_plus` in an Isolate, and **UTF-8 BOM `.csv`** export.
- **Milestone 12.4 (100% Offline Local Android Notifications):** 5 deterministic IST reminder categories/channels (`1001`–`1005`) powered by `flutter_local_notifications` v23 (`AndroidScheduleMode.inexactAllowWhileIdle`, zero exact-alarm permissions), automatic cancellation when work/payments are settled, 24-hour alert cooldown deduplication, lock-screen privacy redaction when App PIN is enabled, lock-safe deep-link queueing behind `AppLockGate`, contextual Android 13+ permission opt-in, and OEM battery guidance.
- **Milestone 12.5 (Documentation, QA, Version Bump & Release Packaging):** Help & Guidance expanded from 15 → **19 bilingual (EN & GU) topics**, version bumped to `1.2.0+3`, **0 untranslated localization keys**, **0 static analyzer issues**, **102 / 102 automated tests passing**, **193 ms** measured analytics benchmark on 5,000 movements + 3,000 labour + 1,000 payments, and all **4 Android APKs** built and verified.

---

## 2. Verified Environment & Stack Baseline

| Component | Verified Value |
| :--- | :--- |
| **Flutter SDK** | `3.50.1` (`stable`) |
| **Dart SDK** | `3.14.0` |
| **UI Library** | `material_ui: ^1.11.1` (preserved) |
| **State Management** | `flutter_bloc: ^9.1.1` |
| **Database** | `drift: ^2.35.3` + `sqlite3: ^3.9.1`, Schema Version `3` (14 tables, 8 DAOs) |
| **Navigation & DI** | `go_router: ^18.1.4`, `get_it: ^9.3.0`, `injectable: ^3.0.0` |
| **Timezone & Formatting** | `timezone: ^0.11.2` (`Asia/Kolkata` / IST), `intl: ^0.20.3` |
| **Android `compileSdk`** | `37` (updated from `flutter.compileSdkVersion` / `36` to satisfy `flutter_local_notifications 23.0.4` & `androidx.core:core:1.19.0`; `targetSdk` and `minSdk` preserved) |
| **Java / Kotlin Toolchain** | Java 17 + `isCoreLibraryDesugaringEnabled = true` (`com.android.tools:desugar_jdk_libs:2.1.4`) |

---

## 3. Non-Negotiable Architecture & Scope Compliance Audit

| Rule / Exclusion | Status | Evidence |
| :--- | :---: | :--- |
| Zero Firebase / FCM / Supabase / Cloud DB | **PASS** | Verified in `pubspec.yaml`; 0 cloud packages, 0 network calls. |
| Zero User Accounts / Email Login / Staff Login / RBAC | **PASS** | Single-owner local PIN only; no user/role tables added. |
| Fully Offline Operation | **PASS** | All PIN auth, analytics, charts, WebView Print/PDF, Excel/CSV, backups, and local notifications operate 100% offline. |
| Append-Only Ledgers & Existing Calculators Preserved | **PASS** | `StockCalculator`, `LabourCalculator`, `LedgerCalculator`, and append-only DAOs preserved intact; `ReportsAnalyticsCalculator` reuses `StockCalculator` & `LedgerCalculator` directly. |
| Zero Fabricated Sales / Revenue / Profit Metrics | **PASS** | Verified in UI & HTML/Excel exports (`Reference Stock Value`, `Labour Cost`, `Earned Labour`); asserted in `reports_v1_2_ui_test.dart`. |
| Flavor Isolation (`dev` vs `prod`) | **PASS** | Separate `applicationId`s, SQLite DB filenames, media dirs, secure storage namespaces (`sf_dev_security` / `sf_prod_security`), and SharedPreferences notification prefixes. |
| No False Claims of SQLite File Encryption | **PASS** | Clearly disclosed in UI (`SecuritySettingsPage`), Help Topic 17, and Section 17 below. |

---

## 4. Packages Added & Compatibility Deviations Documented

| Package | Version Installed | License | Purpose & Verified API Adaptation |
| :--- | :--- | :--- | :--- |
| `flutter_secure_storage` | `^11.2.0` | BSD-3 | Android Keystore-backed PIN verifier/salt/recovery key storage. Adapted to v11 `AndroidOptions(resetOnError: false, migrateOnAlgorithmChange: true, storageNamespace: ...)` (deprecated `encryptedSharedPreferences` removed in v11). |
| `local_auth` | `^3.0.2` | BSD-3 | Android BiometricPrompt unlock. Adapted to v3 flat `authenticate(localizedReason:, biometricOnly: true, persistAcrossBackgrounding: true)` and typed `LocalAuthException`. `MainActivity` migrated to `FlutterFragmentActivity`. |
| `excel_plus` | `^2.29.3` | MIT | Pure-Dart multi-sheet `.xlsx` generation in `Isolate.run` with full UTF-8 Gujarati support. |
| `flutter_local_notifications` | `^23.0.4` | BSD-3 | Local Android notification channels & `zonedSchedule(..., androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle)`. Adapted to v23 named parameters (`initialize(settings:)`, `show(id:)`, `cancel(id:)`, `zonedSchedule(id:, scheduledDate:, ...)`). Required `compileSdk = 37` (installed locally as `android-37.0`) and Gradle core library desugaring (`desugar_jdk_libs:2.1.4`). |

---

## 5. Milestone 12.1 — Local Security, PIN, Biometrics & App Lock

### Key Implemented Components
- **Android Native:**
  - `android/app/src/main/kotlin/com/brijesh/stitchflow/MainActivity.kt`: `FlutterFragmentActivity` + `MethodChannel("com.brijesh.stitchflow/window_security")` for dynamic `FLAG_SECURE`.
  - `android/app/src/main/AndroidManifest.xml`: `android:allowBackup="false"`, `USE_BIOMETRIC`.
- **Cryptography & Storage (`lib/features/security/`):**
  - `PinHasher`: PBKDF2-HMAC-SHA256 (`210,000` iterations in `Isolate.run`), 16-byte CSPRNG salt, constant-time verification, unambiguous Crockford 8-char Recovery Key (`XXXX-XXXX`, alphabet `23456789ABCDEFGHJKMNPQRSTUVWXYZ`), progressive brute-force lockout schedule (`5→30s`, `8→2m`, `10+→5m`).
  - `SecureStorageSecurityRepository`: Flavor-prefixed secure keys, `resetOnError: false`, `audit_logs` trail (`entity_type = 'app_security'`, `action_type = 'UPDATE'`) with **zero** plaintext PIN/salt/hash logging, never written to SQLite or backup `.zip`.
- **Lifecycle & UI Protection:**
  - `AppLockCubit` + `AppLockGate` wrapping `MaterialApp.router` `builder` with isolated `Navigator` for `AppLockScreen` and opaque `PrivacyShieldOverlay` on `inactive`/`hidden`/`paused` (zero flash of Dashboard before unlock).
  - Clock-rollback fail-closed protection, `runWithSystemPicker` suspension around FilePicker/ImagePicker/SharePlus/PrintManager, `markPreserveUnlockAcrossSessionReload()` across atomic backup restores.
  - `SecuritySettingsPage`, `PinSetupPage`, `PinRecoveryPage`, `SecurityReauthDialog` (gating Restore Backup & Export Raw `.sqlite`), and Dashboard AppBar **Lock Now** button.

---

## 6. Milestone 12.2 — Faster Daily Workshop Operations

### Key Implemented Components
- **Pure-Dart Daily Calculator:** `lib/features/reports/domain/calculators/workshop_daily_calculator.dart` (strict `Asia/Kolkata` day bounds, `pendingAgeDays`, `prioritizeImportantPending`, `calculateDailySummary`, `deriveRecentIssueSuggestions`).
- **Today's Workshop Dashboard (`lib/features/dashboard/presentation/pages/dashboard_page.dart`):**
  - Today's Issued, Returned Good, Labour Earned, Payments Paid, and Damaged/Lost alert badge.
  - *Important Pending Work* card (prioritized by oldest age & highest quantity) + tappable Process-wise Pending rows + 1-tap *Daily Summary* quick action.
- **Dedicated Daily Summary (`/daily-summary`):** `DailySummaryPage` + `DailySummaryCubit` with `Today`, `Yesterday`, custom IST date picker, Process-wise & Worker-wise breakdowns, and live workshop pending summary.
- **Worker Live Overview (`lib/features/workers/presentation/pages/worker_detail_page.dart`):** Live pending pieces, open issues with 1-tap `Return`, earned labour, outstanding payable / advance credit, and recent payments.
- **Faster Stock Issue & Return (`stock_issue_page.dart`, `receive_return_picker_page.dart`, `stock_settlement_page.dart`):**
  - Pre-filterable query params (`?workerId=&processId=&lotId=&designColourId=`).
  - Recent In-Stock Colour chips & Recent `(Process, Worker)` chips (excluding inactive/unassigned/out-of-stock).
  - Unusual-action confirmation dialog when issuing 100% of `>= 50` pieces, overriding rate, or backdating `> 7` days.
  - `Oldest First` default sorting + `Highest Pending` / `Newest First` chips + color-coded IST pending-age badges.
  - `Half`, `+10`, `+25`, `Fill Remaining Good`, and Step 5 dynamic Next-Process shortcut chips.

---

## 7. Milestone 12.3 — Schema v3, Advanced Reports, Insights & Gujarati-Safe Exports

### Database Schema v3 (`lib/core/database/migrations/`)
- Upgraded `currentSchemaVersion` from `2` to `3` non-destructively (zero table resets, zero column drops).
- Added 5 composite reporting indexes (`schema_indexes.dart`):
  1. `idx_sm_tx_type` on `stock_movements(transaction_at, movement_type)`
  2. `idx_labour_tx_payable` on `labour_entries(transaction_at, is_payable)`
  3. `idx_payments_tx` on `payments(transaction_at)`
  4. `idx_wla_tx` on `worker_ledger_adjustments(transaction_at)`
  5. `idx_audit_action_rec` on `audit_logs(action_type, recorded_at)`
- Added bounded read-only DAO range/audit queries (`getMovementsInRange`, `getEntriesInRange`, `getPaymentsInRange`, `getAdjustmentsInRange`, `getLatestAuditByAction`).
- Fixed `NativeBackupRestoreService` manifest version to dynamically read `'${AppIdentity.appVersion}+${AppIdentity.appBuildNumber}'` (`1.2.0+3`).

### 6 Unified Report Categories & Insights (`lib/features/reports/`)
- Single-pass `ReportsRepositoryImpl.getAdvancedReports(ReportFilter)` eliminates redundant table scans and feeds `ReportsAnalyticsCalculator`:
  1. **Daily Workshop Report** (day-by-day IST table + tap-to-drill into `/daily-summary`)
  2. **Worker Performance** (Period Flow vs. clearly labeled Current Standing + expandable Process-Wise Productivity)
  3. **Process Performance** (throughput, pending workload, worker contribution %, and strictly verified `Avg. Completion Time` computed solely from 100%-settled issues with `t_complete >= t_issue`, displaying `N/A` when `n == 0`)
  4. **Inventory** (4 sub-tabs: Stock Summary with *Reference Stock Value*, Lot-Wise, Design & Colour, and Movement History with optional *Include Reversed* toggle)
  5. **Labour & Financial** (3 sub-tabs: Labour Earned, Worker Financial Summary, and Mode-filterable Payments)
  6. **Business Insights** (`CustomPainter` dual-bar Production Trends, zero-division-safe Period-over-Period Comparisons, ranked Process Bottlenecks with 1-tap jump to Return Picker, Top Worker Productivity Trends, Process Labour Cost Shares, and Top Damaged/Lost Reasons)
- **Filter Bar:** 1-tap IST Date Presets (`Today`, `Yesterday`, `This Week` Mon–Sun, `This Month`, `Prev. Month`, `All Time`, `Custom`), debounced search (250ms), and cascading `Worker`, `Process`, `Lot → Design → Colour` dropdowns.

### Gujarati-Safe Offline Export & Print
- **Print / Save as PDF:** Pure-Dart `ReportHtmlBuilder` + Kotlin `MethodChannel("com.brijesh.stitchflow/report_print")` driving native Android `WebView` + `PrintManager` (`ISO_A4`) loading bundled `NotoSansGujarati-Regular.ttf` and `NotoSansGujarati-Bold.ttf` via `file:///android_asset/flutter_assets/...` for 100% HarfBuzz Indic conjunct & matra shaping.
- **Excel (`.xlsx`):** `ExcelCsvExportService` using MIT-licensed `excel_plus` inside `Isolate.run` (single-category or 7-sheet Full Workbook) shared via `share_plus` wrapped in `runWithSystemPicker`.
- **CSV Fallback:** Pure-Dart UTF-8 with BOM (`\uFEFF`) `.csv` generator in `Isolate.run` for instant Gujarati-compatible Excel import on large datasets.

---

## 8. Milestone 12.4 — Local Android Notifications

### Native Configuration
- `android/app/build.gradle.kts`: `isCoreLibraryDesugaringEnabled = true` + `desugar_jdk_libs:2.1.4`.
- `android/app/src/main/AndroidManifest.xml`: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, and `android:exported="false"` `ScheduledNotificationReceiver` & `ScheduledNotificationBootReceiver`. **Zero** `USE_EXACT_ALARM` / `SCHEDULE_EXACT_ALARM` permissions requested.

### 5 Deterministic IST Categories & Anti-Noise Architecture
| ID | Channel ID | Category | Default Schedule (IST) | Auto-Cancel / Anti-Noise Rule | Deep-Link |
| :---: | :--- | :--- | :--- | :--- | :--- |
| `1001` | `sf_pending_work` | Pending Work Reminder | Daily `10:00 AM` (`>= 3d` pending) | Cancelled automatically when pending issues drop to `0` | `/stock/return` |
| `1002` | `sf_worker_settlement` | Worker Settlement Reminder | Saturday `06:00 PM` (`>= ₹500` payable) | Cancelled automatically when balances clear | `/accounting` |
| `1003` | `sf_daily_summary` | Daily Workshop Summary | Daily `08:00 PM` | Skipped/cancelled on quiet days when toggle ON | `/daily-summary` |
| `1004` | `sf_backup_reminder` | Offline Backup Reminder | Every `7` days `08:30 PM` | Anchored to latest `BACKUP_EXPORT` audit row; pushed forward immediately upon backup | `/settings/backup` |
| `1005` | `sf_business_alerts` | Important Local Alerts | Evaluated on change (`>= 20` damaged or `>= 14d` overdue) | Strict 24-hour cooldown per alert key; auto-cancelled when resolved | `/stock/repair` or `/stock/return` |

- **Lock-Screen Privacy:** When App PIN is enabled, notification bodies omit exact `₹` rupee figures and worker names and mark `NotificationVisibility.private`.
- **Lock-Safe Deep Linking:** Notification tap payloads are checked against a strict 5-route allowlist and queued in `AppLockCubit.queueDeepLinkRoute` so locked apps always require PIN/biometric unlock first before navigating.
- **Reconcile-on-Change Hooks:** Non-blocking background sync hooks wired into startup (`bootstrap.dart`), app resume (`AppLockGate`), Stock Issue / Settlement / Repair (`StockMovementRepositoryImpl`), Payment / Adjustment (`AccountingRepositoryImpl`), Full Backup Export (`NativeBackupRestoreService`), Restore (`AppSessionController`), and Language Change (`LocaleCubit`).

---

## 9. Milestone 12.5 — Help Catalog, Localization & Version Bump

- **Help & Guidance Catalog (`lib/features/settings/domain/help_topics.dart`):** Expanded from 15 → **19 complete bilingual (English & Gujarati) topics**, adding:
  - Topic 16: *App PIN & Fingerprint Unlock* (`એપ પિન અને ફિંગરપ્રિન્ટ લોક`)
  - Topic 17: *Recovery Key & App Lock Safety* (`રિકવરી કી અને લોક સુરક્ષા`)
  - Topic 18: *Advanced Reports, PDF & Excel Export* (`એડવાન્સ રિપોર્ટ્સ, PDF અને એક્સેલ એક્સપોર્ટ`)
  - Topic 19: *Local Reminders & Android Battery Settings* (`ઓફલાઇન યાદ અપાવણી અને બેટરી સેટિંગ્સ`)
- **Localization Completeness:** `flutter gen-l10n` verified `l10n_untranslated.txt` = **`{}`** (0 untranslated keys across English and Gujarati).
- **Version Alignment:** Updated to **`1.2.0+3`** in both `pubspec.yaml` and `lib/core/config/app_identity.dart`.

---

## 10. Pre-Release Validation Results (Actual Executed Outputs)

| # | Command | Exit Code | Measured Result |
| :---: | :--- | :---: | :--- |
| 1 | `dart format .` | `0` | Formatted 262 files cleanly |
| 2 | `flutter gen-l10n` | `0` | `l10n_untranslated.txt` = `{}` (0 untranslated keys) |
| 3 | `dart run build_runner build --delete-conflicting-outputs` | `0` | Built cleanly (Drift DAOs, Freezed models, Injectable DI) |
| 4 | `flutter analyze` | `0` | **`No issues found!`** (`9.1s`) |
| 5 | `flutter test` | `0` | **`102 / 102` tests passed** (`01:20`, 0 failures, 0 skipped) |
| 6 | `.\build_apk.bat dev debug` | `0` | `178.1 MB` (`186,756,205 bytes`, `67.9s`) |
| 7 | `.\build_apk.bat prod debug` | `0` | `178.1 MB` (`186,756,161 bytes`, `55.4s`) |
| 8 | `.\build_apk.bat dev` | `0` | `74.1 MB` (`77,702,790 bytes`, `167.2s`) |
| 9 | `.\build_apk.bat prod` | `0` | `74.1 MB` (`77,702,782 bytes`, `131.7s`) |

---

## 11. Performance Benchmark Results (Actual Measured)

- **Test:** `test/features/reports_analytics_test.dart` → `Performance Benchmark (5,000 movements + 3,000 labour + 1,000 payments)` across 120 IST days, 20 workers, 6 processes, 10 lots, 20 designs, and 40 colours.
- **Target:** `< 500 ms`
- **Actual Measured Result (Final Run):** **`193 ms`** (2.6× faster than target) via single-pass O(N) settlement indexing and pre-grouped worker ledgers.

---

## 12. Automated Test Coverage Breakdown (`102 / 102` Passing)

| Test Suite | Coverage Highlights |
| :--- | :--- |
| `test/database/app_database_integrity_test.dart` | 14 tables, FK enforcement, unique partial indexes, PRAGMAs |
| `test/database/app_database_persistence_migration_test.dart` | Deduplicated suite + file-backed **`v1 → v3`** and **`v2 → v3`** migrations verifying all 5 Schema v3 indexes in `sqlite_master` + data preservation |
| `test/features/security/pin_hasher_test.dart` | 210k-iteration Isolate PBKDF2, unique salts, constant-time verify, Crockford recovery key, lockout schedule (`5/8/10+`) |
| `test/features/security/app_lock_cubit_test.dart` | Safe V1.1 default OFF, cold-start lock, lockout persistence across restart, background timeout, privacy shield, clock rollback, system-picker suspension, biometric fallback/cancel, recovery key rotation, deep-link queue |
| `test/widget/security_ui_test.dart` | Full PIN setup, Recovery Key confirmation, Lock Now, wrong PIN, unlock at 360dp |
| `test/features/workshop_daily_test.dart` | IST day boundaries, reversal exclusion, recent suggestions, pending age days |
| `test/widget/workshop_ux_v1_2_test.dart` | Today Dashboard, Daily Summary, Worker Live Overview at 360dp (zero overflow) |
| `test/features/reports_analytics_test.dart` | IST presets, 6 categories, reversal exclusion, verified turnaround time, period comparisons, Gujarati HTML + `.xlsx` round-trip + UTF-8 BOM `.csv`, **5,000-movement benchmark (193 ms)** |
| `test/widget/reports_v1_2_ui_test.dart` | All 6 Report categories, Export sheet, truthful labels (zero Profit/Revenue), zero overflow at 360dp |
| `test/features/notifications_plan_test.dart` | All 5 IST notification categories, auto-cancel on settlement, quiet-day skip, 24h alert cooldown, lock-screen privacy redaction, strict route allowlist |
| `test/widget/notifications_ui_test.dart` | `/settings/notifications` contextual Android 13+ permission opt-in & test notification at 360dp + lock-safe deep link behind active PIN |
| `test/features/end_to_end_business_workflow_test.dart` | Full 18-step workshop workflow + V1.2 Reports/Insights parity + Notification sync + atomic Backup/Restore preserving active PIN in secure storage |
| Legacy V1.0 / V1.1 Suites (`test/unit/`, `test/features/`, `test/widget/`) | 100% regression pass across Lots, Processes, Workers, Rates, Stock, Labour, Ledger, Backup, Branding, Theme/Locale, 19-topic Help Catalog, and responsive breakpoints (`360dp` / `800dp` / `1280dp`) |

---

## 13. Generated Android APK Artifacts

All four APKs were compiled and packaged via `.\build_apk.bat` on **2026-11-23 (IST)**:

| Flavor | Mode | Application ID | APK Size | Timestamped Release Path |
| :--- | :--- | :--- | :---: | :--- |
| **Dev** | Debug | `com.brijesh.stitchflow.dev` | `178.1 MB` (`186,756,205 B`) | `C:\A1\business_manager\build\releases\dev\StitchFlow_Dev_20261123_172328_debug.apk` |
| **Prod** | Debug | `com.brijesh.stitchflow` | `178.1 MB` (`186,756,161 B`) | `C:\A1\business_manager\build\releases\prod\StitchFlow_Prod_20261123_172427_debug.apk` |
| **Dev** | Release | `com.brijesh.stitchflow.dev` | `74.1 MB` (`77,702,790 B`) | `C:\A1\business_manager\build\releases\dev\StitchFlow_Dev_20261123_172716.apk` |
| **Prod** | Release | `com.brijesh.stitchflow` | `74.1 MB` (`77,702,782 B`) | `C:\A1\business_manager\build\releases\prod\StitchFlow_Prod_20261123_172930.apk` |

---

## 14. Signing & Distribution Disclosure (CRITICAL)

- **Current Signing Configuration:** In `android/app/build.gradle.kts`, `buildTypes.release` currently uses **`signingConfigs.getByName("debug")`**.
- **What This Means:**
  - The generated release APKs (`StitchFlow_Dev_20261123_172716.apk` and `StitchFlow_Prod_20261123_172930.apk`) are **debug-signed for direct Android sideloading and upgrade over existing debug-signed V1.1 sideloads**.
  - They are **NOT Google Play Store upload ready**. Before any future Play Store distribution, configure a dedicated release upload keystore (`key.properties` + `signingConfigs.create("release")`) and build an `.aab` (`flutter build appbundle`).

---

## 15. Security Threat Model & Transparent Limitations

- **Protected Against:**
  - Unauthorized casual access on the workshop owner's phone (App PIN + optional BiometricPrompt + configurable inactivity & background auto-lock + progressive brute-force lockout).
  - Shoulder-surfing / Android Recent Apps leakage (`PrivacyShieldOverlay` + dynamic `FLAG_SECURE`).
  - Accidental overwrite or raw DB extraction without confirmation (PIN/biometric re-authentication gate on Backup Restore & Export Raw `.sqlite`).
  - Lock-screen financial exposure (notification bodies redact exact Rupee amounts and worker names when PIN is enabled).
- **Explicit Limitations (Do Not Overstate):**
  - **SQLite Database Not Encrypted on Disk:** Local App PIN protects application UI access; it does **not** encrypt the SQLite database file (`business_manager_prod.sqlite`) or exported `.zip` backup archives. Always keep Android device lock-screen encryption enabled and store backup `.zip` files safely.
  - **Rooted / Compromised Devices:** An attacker with full physical root/ADB extraction access on an unlocked Android device can bypass app-level locks.
  - **Lost PIN + Lost Recovery Key:** StitchFlow never silently resets or bypasses App Lock; recovery requires clearing app data/reinstalling and restoring a saved `.zip` backup.

---

## 16. Known OEM & Platform Notes (OPPO ColorOS / Xiaomi / Vivo / Samsung)

- **Background Notification Delivery:** StitchFlow intentionally uses battery-friendly `AndroidScheduleMode.inexactAllowWhileIdle` (no `USE_EXACT_ALARM`). On OEM Android skins (OPPO ColorOS, Xiaomi MIUI/HyperOS, Vivo FuntouchOS, Samsung Deep Sleep), aggressive battery management may delay scheduled alarms or suppress boot receivers until the app is opened once.
- **Mitigation Shipped:** Automatic notification reconciliation on every app open/resume + clear bilingual guidance inside `Settings -> Notifications & Reminders` and Help Topic 19 instructing how to allow background activity for StitchFlow in Android Battery settings.
- **Android WebView Print / PDF:** Requires the built-in Android System WebView (present on all modern Android phones) and operates 100% offline using bundled `NotoSansGujarati` font assets.

---

## 17. Physical Android Device Manual QA Checklist (Pending On-Device Verification)

> **Important Honesty Disclosure:** All automated tests, static analysis, benchmarks, and APK builds above were executed and verified on the Windows build host. The following physical Android hardware checks have **NOT** yet been executed on a physical phone and MUST be verified before handing the Production APK to the workshop owner's father:

- [ ] **Upgrade-Over-V1.1 Continuity:** Install `StitchFlow_Prod_20261123_172930.apk` directly over existing V1.1 (`1.1.0+2`); confirm zero data loss, all lots/workers/balances intact, and App Lock defaults cleanly to OFF.
- [ ] **PIN, Fingerprint & `FLAG_SECURE` Hardware Test:** Enable 4-digit PIN, write down 8-char Recovery Key, enable Fingerprint; verify Android Recent Apps hides workshop data (`FLAG_SECURE`), screenshots are blocked, fingerprint cancel falls back safely to PIN without unlocking, 5 wrong PINs trigger 30s lockout that survives force-stop, and Forgot PIN Recovery Key resets PIN with zero data loss.
- [ ] **Daily Workshop Phone Ergonomics:** Verify 1-handed daily flow on phone — Today's Workshop Dashboard, `/daily-summary`, Recent `(Process, Worker)` chip on Issue Stock, 100% stock confirmation dialog, `Oldest First` Quick Return with `Fill Remaining Good` & Next-Process shortcut, and Worker Detail live overview.
- [ ] **Gujarati Print/PDF & Excel Inspection:** Switch app language to **ગુજરાતી**, open all 6 Report Categories, tap **Print / Save as PDF**, visually inspect Gujarati conjuncts/matras (`કારીગર`, `પ્રક્રિયા`, `મજૂરી`, `સ્ટોક`, `હિસાબ`) in Android Print Preview, save PDF, and open an exported `.xlsx` workbook in Excel / Google Sheets.
- [ ] **Android 13/14/15 Notifications & Lock-Safe Deep Link:** Grant notification permission in `Settings -> Notifications & Reminders`, send Test Notification, lock app with PIN, tap notification, verify PIN screen appears FIRST and routes directly to `/daily-summary` immediately after unlock; reboot phone and confirm scheduled reminders survive (check ColorOS/OEM battery setting if delayed).
- [ ] **Backup & Restore Re-Auth Flow:** Create a V1.2 `.zip` backup, verify PIN re-auth triggers on Raw SQLite Export & Restore Backup, verify Backup Reminder pushes forward by 7 days, and verify PIN remains active after restore.
