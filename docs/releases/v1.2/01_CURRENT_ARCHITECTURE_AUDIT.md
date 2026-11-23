# 01 — Current Architecture Audit (StitchFlow V1.1 Baseline)

**Audit Target:** `C:\A1\business_manager`  
**Audit Date:** `2026-11-23` (`Asia/Kolkata`)  
**Methodology:** Direct source inspection of `pubspec.yaml`, `android/`, `lib/`, `test/`, `config/`, `scripts/`, `docs/`, plus live execution of `flutter --version`, `flutter analyze`, and `flutter test`.

---

## 1. Verified Baseline vs. V1.1 Report

| Baseline Item | V1.1 Report Claim | Live Verification Result | Status |
| :--- | :--- | :--- | :---: |
| Flutter / Dart SDK | `3.50.1` / `3.14.0` | `Flutter 3.50.1` (`stable`, rev `ae9b586f34`) / `Dart 3.14.0` / `DevTools 2.61.0` | **VERIFIED** |
| App Version | `1.1.0+2` | `pubspec.yaml`: `1.1.0+2`, `AppIdentity`: `1.1.0` / build `2` *(Note: `NativeBackupRestoreService.appVersionString` still reads `'1.0.0+1'`)* | **PARTIAL GAP** |
| Material 3 Library | `material_ui: ^1.11.1` | Present in `pubspec.yaml` and imported consistently across `lib/core/widgets/` and pages | **VERIFIED** |
| Database Engine | Drift + SQLite, schema v2 | `drift: ^2.35.3`, `drift_flutter: ^0.3.1`, `sqlite3: ^3.9.1`; `DatabaseMigrationManager.currentSchemaVersion = 2`; 14 tables, 8 DAOs | **VERIFIED** |
| Offline-First | 100% offline | Zero HTTP/cloud/Firebase/Supabase dependencies in `pubspec.yaml` | **VERIFIED** |
| Flavors | `dev` & `prod` | `android/app/build.gradle.kts`, `config/dev.json`, `config/prod.json`, `lib/main_dev.dart`, `lib/main_prod.dart`, `scripts/build_apk.ps1` | **VERIFIED** |
| Localization | EN & GU, 0 untranslated | 507 keys in `app_en.arb`, 507 keys in `app_gu.arb`, `l10n_untranslated.txt = {}` | **VERIFIED** |
| Themes | Light, Dark, System | `ThemeCubit` + `AppTheme.light()` / `AppTheme.dark()` + `AppSemanticColors` + `AppSurfaceTokens` | **VERIFIED** |
| Static Analysis | 0 issues | `flutter analyze` -> `No issues found! (ran in 9.7s)` | **VERIFIED** |
| Automated Tests | 77 passing | `flutter test` -> `77 / 77 All tests passed!` *(Note: 1 duplicate test method in `app_database_persistence_migration_test.dart`)* | **VERIFIED (Minor cleanup)** |

---

## 2. Technology Stack & Dependency Inventory

Current production dependencies in `pubspec.yaml`:
- **UI & Motion:** `material_ui: ^1.11.1`, `cupertino_icons: ^2.0.0`, `animations: 3.0.0`, `flutter_animate: 4.5.2`
- **State & Navigation:** `flutter_bloc: ^9.1.1`, `go_router: ^18.1.4`
- **DI & Models:** `get_it: ^9.3.0`, `injectable: ^3.0.0`, `freezed_annotation: ^3.1.0`, `json_annotation: ^4.12.0`
- **Persistence & Files:** `drift: ^2.35.3`, `drift_flutter: ^0.3.1`, `sqlite3: ^3.9.1`, `shared_preferences: ^2.5.3`, `path_provider: ^2.1.6`, `path: ^1.9.1`, `archive: ^4.6.0`, `file_picker: ^13.4.1`, `image_picker: ^1.2.4`, `share_plus: ^13.3.1`
- **Time, Formatting & Crypto:** `intl: ^0.20.3`, `timezone: ^0.11.2`, `uuid: ^4.6.0`, `crypto: ^3.0.6`

**Key Reuse Takeaways:**
- `crypto: ^3.0.6` is already installed -> enables zero-native-dependency PBKDF2-HMAC-SHA256 for PIN & recovery key hashing.
- `timezone: ^0.11.2` is already installed -> directly powers `flutter_local_notifications` scheduled IST reminders via `IstDateTimeHelper.istLocation`.
- `share_plus: ^13.3.1` is already installed -> directly shares exported Excel (`.xlsx`), CSV (`.csv`), and PDF files.
- `archive: ^4.6.0` is already installed -> `.zip` backups and OpenXML support.
- `shared_preferences: ^2.5.3` is already installed -> stores theme, locale, notification settings, and non-sensitive UX preferences.

---

## 3. Android Configuration & Build Pipeline Audit

### 3.1 `android/app/build.gradle.kts`
- `namespace = "com.brijesh.stitchflow"`, `applicationId = "com.brijesh.stitchflow"` (`.dev` suffix for `dev` flavor).
- `compileSdk = flutter.compileSdkVersion`, `minSdk = flutter.minSdkVersion`, `targetSdk = flutter.targetSdkVersion`.
- Java 17 / Kotlin JVM 17 target.
- **V1.2 Gaps Identified:**
  1. `compileOptions` does **not** yet enable `isCoreLibraryDesugaringEnabled = true` and `dependencies` does not include `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")` — required by `flutter_local_notifications`.
  2. Release signing currently uses `signingConfigs.getByName("debug")` (acceptable for local sideload APK; documented as known limitation).

### 3.2 `android/app/src/main/AndroidManifest.xml` & `MainActivity.kt`
- `MainActivity.kt` currently extends `io.flutter.embedding.android.FlutterActivity`.
  - **CRITICAL FOR V1.2:** `local_auth: ^3.0.2` requires `FlutterFragmentActivity` on Android (`BiometricPrompt` throws `no_fragment_activity` otherwise).
- `AndroidManifest.xml` currently declares no `<uses-permission>` elements and omits `android:allowBackup`.
  - **CRITICAL FOR V1.2:**
    - Must set `android:allowBackup="false"` to prevent Android Auto Backup from copying KeyStore-wrapped secure storage files across devices and causing `InvalidKeyException`.
    - Must add `USE_BIOMETRIC` (Phase A).
    - Must add `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `ScheduledNotificationReceiver`, and `ScheduledNotificationBootReceiver` (Phase D).
- Custom URL scheme `stitchflow://` is already registered on `MainActivity` (`android:launchMode="singleTop"`).
- Branded Android 12+ (`values-v31/`, `values-night-v31/`) and legacy (`drawable-v21/`, `drawable-night-v21/`) splash screens and adaptive launcher icons are fully configured and verified by automated resource tests.

### 3.3 Build Scripts
- `build_apk.bat` delegates to `scripts/build_apk.ps1`, passing `--flavor <dev|prod> -t lib/main_<flavor>.dart --dart-define-from-file=config/<flavor>.json` and copying timestamped IST APKs into `build/releases/<flavor>/` without overwriting prior releases. **Preserved intact in V1.2.**

---

## 4. App Bootstrap, DI, Routing & State Management Audit

- **Startup (`lib/bootstrap.dart`):**
  1. `WidgetsFlutterBinding.ensureInitialized()`
  2. `IstDateTimeHelper.initialize()` (loads `timezone/data/latest_10y.dart` and caches `Asia/Kolkata`)
  3. `await configureDependencies(config)` (`GetIt` + `injectable`)
  4. `await getIt<DatabaseInitializer>().initialize()` (opens SQLite and verifies PRAGMAs)
  5. `runApp(BusinessManagerApp(config: config))`
- **Session Reload (`lib/core/di/app_session_controller.dart`):**
  - After atomic `.zip` restore, `AppSessionController.instance.reloadSession(config)` calls `getIt.reset()`, re-runs `configureDependencies`, re-initializes the DB, increments `generation`, and `BusinessManagerApp` rebuilds a fresh `KeyedSubtree` + `GoRouter`.
  - **V1.2 Implication:** `AppLockCubit` (Phase A) MUST preserve the active unlocked state across an authorized restore reload so the owner is not abruptly kicked to the PIN screen right after completing a restore!
- **Root App (`lib/app.dart`):**
  - Provides `LocaleCubit` and `ThemeCubit` via `MultiBlocProvider` above `MaterialApp.router`.
  - **V1.2 Integration Point:** Provide `AppLockCubit` alongside `LocaleCubit`/`ThemeCubit` and wrap `MaterialApp.router`'s `builder` in an `AppLockGate` overlay so locked states cover 100% of routes, dialogs, and bottom sheets with zero dashboard flash!
- **Navigation (`lib/core/router/app_router.dart` & `route_paths.dart`):**
  - Clean declarative `GoRouter` with 31 routes and `StitchFlowShellPage` using `ResponsiveNavigation` (5 spacious mobile bottom tabs: `Dashboard`, `Lots`, `Stock`, `Workers`, `Settings`).
  - Uses `AppMotion.buildPage` (`SharedAxisTransition` / reduced-motion safe).
- **Preferences Isolation Note:**
  - `LocaleCubit` (`app_locale_preference`) and `ThemeCubit` (`app_theme_preference`) store keys in `SharedPreferences` (which is already isolated per Android `applicationId`: `com.brijesh.stitchflow.dev` vs `com.brijesh.stitchflow`). Still, prefixing new V1.2 secure-storage and notification preference keys with `sf_${config.flavor.name}_` provides belt-and-suspenders isolation in unit/widget tests and desktop builds.

---

## 5. Drift Database, DAOs & Transaction Integrity Audit

### 5.1 Current Schema (Version 2 — 14 Tables, 8 DAOs)

| Table | Role | Mutability | Key Constraints & Notes |
| :--- | :--- | :--- | :--- |
| `business_profile` | Singleton workshop branding & global billing mode | Mutable (`UPDATE`) | `default_billing_mode IN ('RECEIVED_QTY', 'GIVEN_QTY')` |
| `lots` | Production lots | Soft-delete (`deleted_at`) | Unique active `lot_number`; status `ACTIVE/COMPLETED/ARCHIVED` |
| `lot_designs` | Designs inside a lot | Soft-delete | Unique `(lot_id, lower(design_name))` active |
| `design_colours` | Atomic SKU quantity + reference unit price | Soft-delete | `initial_quantity > 0`, `unit_price_paise >= 0` |
| `processes` | 100% dynamic production processes | Soft-delete + `is_active` | Optional `billing_mode_override`, `include_damaged_in_labour` |
| `members` | Workers / Karigars | Soft-delete + `is_active` | Contact details + notes |
| `member_processes` | Worker <-> Process assignments | Toggle `is_active` | Unique `(member_id, process_id)` |
| `member_process_rates` | Historical effective-dated rates (IST `YYYY-MM-DD`) | Soft-delete (blocked if used) | `rate_paise >= 0`, `effective_to >= effective_from` |
| `stock_movements` | Core stock issue/return/settlement/repair/reversal ledger | **Strictly append-only** | `client_request_id` unique; single reversal unique; locks rate, billing mode & include_damaged |
| `labour_entries` | Payable & informational labour ledger | **Strictly append-only** | Unique `(stock_movement_id, basis_type)`; single reversal unique |
| `payments` | Regular, Advance, Advance Refund & Reversal | **Strictly append-only** | `client_request_id` unique; single reversal unique; `amount_paise > 0` |
| `worker_ledger_adjustments` | Audited Credit, Debit & Reversal (added in v2) | **Strictly append-only** | `client_request_id` unique; single reversal unique; `reason` non-empty |
| `attachments` | Private media metadata + SHA-256 | Soft-delete | `entity_type IN ('LOT', 'STOCK_MOVEMENT', 'PAYMENT', 'BUSINESS_PROFILE')` |
| `audit_logs` | Complete immutable audit trail | **Strictly append-only** | `CHECK(action_type IN ('CREATE', 'UPDATE', 'SOFT_DELETE', 'DEACTIVATE', 'REACTIVATE', 'RATE_OVERRIDE', 'REVERSAL', 'DAMAGED_TO_GOOD_ADJUSTMENT', 'BACKUP_EXPORT', 'BACKUP_RESTORE'))` |

### 5.2 Database Safety & Index Gaps Found
1. **PRAGMAs Verified:** `foreign_keys = ON`, `journal_mode = WAL`, `synchronous = FULL`, `busy_timeout = 5000` enforced on every connection in `beforeOpen` and verified by `DatabaseInitializer`.
2. **Atomic Transactions:** `DatabaseTransactionRunner.runInTransaction()` wraps every stock issue, settlement, repair, reversal, payment, and adjustment atomically alongside `audit_logs`.
3. **`audit_logs` CHECK Constraint:** Because `action_type` has an explicit SQLite `CHECK` constraint, V1.2 security audit records (e.g., PIN enabled/changed/disabled/recovered) MUST use existing `action_type = 'UPDATE'` (or `'CREATE'`) with `entity_type = 'app_security'` rather than rebuilding `audit_logs`.
4. **Missing Date-Range Indexes for Phase C & D:** Current `SchemaIndexes` has no standalone index on `stock_movements(transaction_at DESC, movement_type)`, `labour_entries(transaction_at DESC, is_payable)`, `payments(transaction_at DESC)`, `worker_ledger_adjustments(transaction_at DESC)`, or `audit_logs(action_type, recorded_at DESC)`. Adding these via an additive **v2 -> v3** index-only migration will make date-bounded reports and backup-age checks fast even at 50,000+ rows.

---

## 6. Feature-by-Feature Codebase Audit

### 6.1 Dashboard (`lib/features/dashboard/`)
- **Current State:** Displays branded hero banner, 7 quick-action buttons, 4 all-time Stock Health KPIs, 4 all-time Financial Health KPIs, static (non-tappable) Process-wise Pending rows, and last 6 audit log entries.
- **V1.2 Gaps:**
  - Shows **all-time** totals only — lacks **Today's** IST workshop activity (Issued, Good Returned, Labour Earned, Payments, Damaged/Lost).
  - Lacks an **Important / Oldest Pending Work** card with direct 1-tap `Receive Return`.
  - Quick Actions dock lacks `Pending Work`, `Worker Ledger`, `Daily Summary`, and `Lock Now`.
  - Process-wise Pending rows are not tappable.

### 6.2 Stock Movements, Issue & Return (`lib/features/stock_movements/`)
- **Current State (Strong V1.1 Base):**
  - `StockCalculator` (604 lines, pure Dart) enforces all inventory invariants, settlement validation, and chronological prefix replay reversal guards.
  - `StockIssuePage` already provides 4-step single-flow + Step 5 Success, searchable stock picker with `In Stock Only`, Process & Worker chips, locked rate/billing preview, `+10/+25/+50/All` chips, over-stock validation, and `clientRequestId` idempotency.
  - `ReceiveReturnPickerPage` & `StockSettlementPage` already provide worker/process chip filtering, live remaining pending bar, `All Good` chip, Lost vs. Shortage helpers, mandatory reason enforcement, consequences/labour preview, and Step 5 "Issue Returned Stock to Next Process".
- **V1.2 Gaps:**
  - `StockIssuePage` has **no recent process/worker/colour suggestions** (always picks `procs.first` and `activeAssigned.first`) and **no unusual-action confirmation dialog** (e.g., issuing 100% of available stock or rate override confirmation).
  - `ReceiveReturnPickerPage` sorts newest-first only (no **Oldest First** / **Highest Pending** sort, no pending-age badges, no route query params `?workerId=...&processId=...`).
  - `StockSettlementPage` has only `All Good` shortcut (no `Half`, `+10`, `+25`, or "Fill Remaining as Good" helper when damaged/lost/shortage is entered).

### 6.3 Workers, Processes, Lots, Accounting (`lib/features/workers/`, `accounting/`, `lots/`, `processes/`)
- **Strong Foundation:** `LabourCalculator` (114 lines) and `LedgerCalculator` (394 lines) are pure Dart, thoroughly unit-tested, handle reversals, advances, negative advance credits, and opening/running balances cleanly.
- **V1.2 Gaps:**
  - `WorkerDetailPage` (explicit comment on line 18: *"Intentionally omits labour earnings and payment balances"*) does **not** show that worker's live pending issues, pending quantity, earned labour, or outstanding balance!
  - `LedgerCalculator.buildLedgerLines` uses hardcoded English `'Lot'` and `'pcs'` inside `title`/`subtitle` strings (minor localization polish opportunity).

### 6.4 Reports (`lib/features/reports/`)
- **Current State:** `ReportsPage` renders 10 horizontal `ChoiceChip` tabs powered by `ReportsRepositoryImpl.getBusinessReports()`.
- **Critical V1.2 Gaps Found in Code:**
  1. **Redundant Queries:** `getBusinessReports()` calls `getAllDesignColourBalances()`, `getWorkerStockSummaries()`, `getProcessStockSummaries()`, `getOpenIssues()`, and `getMovementHistory()` separately — reading the entire `stock_movements` table **5 times per load**!
  2. **Incomplete Date Filtering:** `fromUtcMillis` and `toUtcMillis` are only applied to `damagedLostShortageMovements`, `labourEntries`, and `payments`. `workerStockRows`, `processStockRows`, `workerFinancialSummaries`, and `openIssues` ignore the date range!
  3. **Missing Filter Controls in UI:** `ReportsCubit` already accepts `lotId`, `workerId`, `processId`, but `ReportsPage` only exposes Search + From/To Date pickers — no preset chips (`Today`, `Yesterday`, `This Week`, `This Month`, `Previous Month`) and no Worker/Process/Lot/Design/Colour filter selectors!
  4. **Missing Capabilities:** No Daily Workshop Report, no Process Average Completion Time, no Worker Process-wise Productivity breakdown, no Business Insights (trends, bottlenecks, period-over-period comparisons), and no PDF/Print/Excel export.

### 6.5 Backup & Restore (`lib/features/backup/`)
- **Strong Foundation:** `NativeBackupRestoreService` uses `PRAGMA wal_checkpoint(TRUNCATE)` + `VACUUM INTO`, SHA-256 checksums for DB and all media files, Zip-Slip path traversal protection, cross-flavor guard (`dev -> prod` blocked), schema-too-new guard, automatic pre-restore safety snapshot + rollback on failure, and `AppSessionController.reloadSession`.
- **V1.2 Gaps:**
  - `NativeBackupRestoreService.appVersionString` is hardcoded to `'1.0.0+1'` (should use `'${AppIdentity.appVersion}+${AppIdentity.appBuildNumber}'`).
  - Destructive Restore and Raw SQLite Export are not yet gated by PIN/Biometric re-authentication when App Lock is enabled.
  - No reminder mechanism tracking days since last `BACKUP_EXPORT`.

### 6.6 Settings & Localization (`lib/features/settings/`, `lib/core/localization/`)
- **Strong Foundation:** Clean 6-section `SettingsHomePage`, 15 bilingual Help topics, calibrated `NotoSansGujarati` line heights (`1.38–1.50`), `fontFamilyFallback`, `FittedBox` numeric scaling, 507 EN & GU keys with 0 untranslated.
- **V1.2 Gaps:**
  - Needs two new Settings sections: **App Lock & Security** (`/settings/security`) and **Notifications & Reminders** (`/settings/notifications`), plus new Help topics covering PIN/Biometrics, Recovery Key, Advanced Reports/Export, and Notifications.
  - `DomainLabelLocalizer.auditAction` / `auditEntity` missing mappings for `BACKUP_EXPORT`, `BACKUP_RESTORE`, `DEACTIVATE`, `REACTIVATE`, `DAMAGED_TO_GOOD_ADJUSTMENT`, `backup`, and future `app_security`.

---

## 7. Test Suite & Reusable Test Utilities Audit

- **20 test files** across `test/database/`, `test/features/`, `test/unit/`, and `test/widget/` — **77 passing tests**.
- **Reusable Patterns Already Established:**
  - In-memory Drift testing (`AppDatabase.forTesting(NativeDatabase.memory())`) and file-backed migration testing (`NativeDatabase(dbFile)` + `PRAGMA user_version = 1`).
  - Full-app DI widget harness in `test/widget/v1_1_ux_settings_stock_workflows_test.dart` (`getIt.reset()`, `SharedPreferences.setMockInitialValues({})`, `configureDependencies(config)`, unregister/register in-memory `AppDatabase` + temp `NativeMediaStorageService`).
  - Viewport testing at `360x800` (mobile), `800x1024` (tablet), `1280x800` (desktop) across EN/GU and Light/Dark with `expect(tester.takeException(), isNull)`.
- **Cleanup Item:** `test/database/app_database_persistence_migration_test.dart` contains an identical duplicated `v1 to v2` test block (lines 108–173 and 175–240) that should be deduplicated when adding `v2 -> v3` migration tests.

---

## 8. Existing Functionality Directly Reusable in V1.2

| Existing Module | Reused In V1.2 For |
| :--- | :--- |
| `StockCalculator`, `LabourCalculator`, `LedgerCalculator`, `MemberProcessRateResolver` | All Phase B & C metrics, Daily Summary, Insights, and Notification eligibility checks (zero formula duplication). |
| `IstDateTimeHelper` (`Asia/Kolkata` + `timezone: ^0.11.2`) | Report date presets, Today's Dashboard cutoffs, Turnaround calculations, and Scheduled Notification triggers. |
| `DatabaseTransactionRunner` & `IdGenerator` | Preserved unchanged for all atomic workshop operations & security audit log entries. |
| `AppTheme`, `AppColors`, `AppTypography`, `lib/core/widgets/` (`AppCard`, `AppButton`, `AppMetricTile`, `AppStatusBadge`, `AppDataTable`, `AppDialog`, `AppSwitch`, `AppFeedback`) | Lock screen, PIN pad, Security/Notification settings, Daily Summary, and Report filters/cards. |
| `DomainLabelLocalizer` | Extended for backup/security audit labels and report export headers. |
| `share_plus` + `NativeBackupRestoreService` | Sharing `.xlsx`/`.csv`/PDF exports; checking last backup timestamp in `audit_logs`. |
| `AppSessionController` | Safely reloading DI after backup restore without dropping active unlock session. |
