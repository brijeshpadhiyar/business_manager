# 08 — Phased Implementation Tasks (Milestones 12.0 – 12.5)

**Execution Rule:** Do **not** begin Milestone 12.1 until Milestone 12.0 design docs and Owner Approval Decisions (`00_V1_2_EXECUTIVE_PLAN.md` Section 6) are confirmed. Each milestone (`12.1` through `12.5`) is independently buildable, testable, and shippable without leaving broken code.

---

## Dependency Graph & Milestone Rationale

```text
12.0 (Approved Plan)
  │
  ▼
12.1 (Local PIN, Biometrics, App Lock, FlutterFragmentActivity, FLAG_SECURE)
  │
  ▼
12.2 (Daily Workshop UX: Today Dashboard, Daily Summary, Quick Issue/Return, Worker Overview)
  │
  ▼
12.3 (Schema v3 Indexes + Advanced Reports + Business Insights + Gujarati PDF/Print/Excel)
  │
  ▼
12.4 (Local Android Notifications — reuses 12.1 Lock Gate, 12.2 Daily Summary, 12.3 v3 Indexes)
  │
  ▼
12.5 (Full QA, Migration/Backup Verification, L10n & Help Polish, V1.2 Release APKs 1.2.0+3)
```

*Why this order:* 12.1 modifies `MainActivity.kt` (`FlutterFragmentActivity`) and installs root `AppLockGate` first so every new screen in 12.2–12.4 is automatically lock-protected. 12.2 establishes `WorkshopDailyCalculator` and `/daily-summary` reused by Reports (12.3) and Notifications (12.4). 12.3 introduces the index-only `v2 -> v3` migration so both Reports and Notifications (12.4) execute on indexed `transaction_at` and `audit_logs` queries.

---

## Milestone 12.0 — Architecture Audit & Approved Design (COMPLETE)
- **Deliverables:** `docs/releases/v1.2/00..08_*.md` (all 9 files created and verified against live codebase).
- **Exit Gate:** Owner sign-off on Section 6 decisions in `00_V1_2_EXECUTIVE_PLAN.md`.

---

## Milestone 12.1 — Local PIN, Biometric & App-Lock Security (Phase A)

### Packages & Native Changes
- **Add to `pubspec.yaml`:**
  - `flutter_secure_storage: ^10.3.4`
  - `local_auth: ^3.0.2`
- **Modify `android/app/src/main/kotlin/com/brijesh/stitchflow/MainActivity.kt`:**
  - Extend `FlutterFragmentActivity` instead of `FlutterActivity`.
  - Add `MethodChannel("com.brijesh.stitchflow/window_security")` to toggle `WindowManager.LayoutParams.FLAG_SECURE` dynamically from Dart.
- **Modify `android/app/src/main/AndroidManifest.xml`:**
  - Add `android:allowBackup="false"` on `<application>`.
  - Add `<uses-permission android:name="android.permission.USE_BIOMETRIC"/>`.
- **Database Changes:** None (credentials live solely in Android Keystore via `flutter_secure_storage`; security events log to existing `audit_logs` with `entity_type = 'app_security'`, `action_type = 'UPDATE'`).

### Dependency-Ordered Tasks
1. **12.1.1 — Crypto & Domain Layer:**
   - Create `lib/features/security/domain/entities/security_entities.dart`
   - Create `lib/features/security/domain/services/pin_hasher.dart` (PBKDF2-HMAC-SHA256 via `crypto`, 210k iterations, 16-byte `Random.secure()` salt, `Isolate.run`, constant-time compare, Crockford 8-char `RecoveryKeyGenerator`)
   - Create `lib/features/security/domain/repositories/security_repository.dart`
2. **12.1.2 — Secure Storage, Biometric & Window Security Data Layer:**
   - Create `lib/features/security/data/repositories/secure_storage_security_repository.dart` (`AndroidOptions(resetOnError: false, migrateOnAlgorithmChange: true)`, flavor-prefixed keys `sf_<flavor>_*`, persistent lockout counters)
   - Create `lib/features/security/data/services/local_auth_biometric_service.dart` (`local_auth` v3 flat `authenticate()` API + typed `LocalAuthException` handling)
   - Create `lib/features/security/data/services/window_security_channel.dart`
   - Update `lib/core/di/register_module.dart` & run `build_runner`
3. **12.1.3 — Root `AppLockCubit`, `AppLockGate` & Lifecycle Integration:**
   - Create `lib/features/security/presentation/bloc/app_lock_cubit.dart` (`@lazySingleton`, cold-start init, background timestamp check, foreground inactivity timer, system-picker suspension guard, pending deep-link queue, preserve-unlock flag for restore reload)
   - Create `lib/features/security/presentation/widgets/app_lock_gate.dart` (opaque StitchFlow `PrivacyShieldOverlay`, `WidgetsBindingObserver`, pointer inactivity `Listener`, root lock overlay above `MaterialApp.router`)
   - Modify `lib/bootstrap.dart` (initialize `AppLockCubit` before `runApp`), `lib/app.dart` (provide `AppLockCubit` + wrap `MaterialApp.router` `builder` in `AppLockGate`), and `lib/core/di/app_session_controller.dart` (preserve unlocked state across authorized backup restore)
4. **12.1.4 — Security Screens & Sensitive Action Re-Auth:**
   - Create `lib/features/security/presentation/widgets/pin_keypad.dart` & `security_reauth_dialog.dart`
   - Create `lib/features/security/presentation/pages/app_lock_screen.dart`
   - Create `lib/features/security/presentation/pages/security_settings_page.dart` (`/settings/security`)
   - Create `lib/features/security/presentation/pages/pin_setup_page.dart` (`/settings/security/pin-setup`)
   - Create `lib/features/security/presentation/pages/pin_recovery_page.dart`
   - Modify `lib/core/router/route_paths.dart`, `lib/core/router/app_router.dart`, `lib/features/settings/presentation/pages/settings_home_page.dart` (add App Lock & Security section), `lib/features/backup/presentation/pages/backup_restore_page.dart` (require `SecurityReauthDialog` before Restore & Raw SQLite Export), `lib/core/localization/domain_label_localizer.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_gu.arb`
5. **12.1.5 — Tests & Verification:**
   - Create `test/features/security/pin_hasher_test.dart`, `test/features/security/app_lock_cubit_test.dart`, `test/widget/security_ui_test.dart`
   - Run `flutter gen-l10n`, `flutter analyze`, `flutter test`, `.\build_apk.bat dev debug`.

### Acceptance Criteria
- Cold launch with PIN enabled shows Lock Screen immediately (zero Dashboard frames rendered).
- PIN setup, confirm, change, disable, auto-lock timeout, Lock Now, Privacy Shield, `FLAG_SECURE`, persistent lockout, biometric success/cancel/unavailable fallback, and Recovery Key reset all pass automated tests in EN & GU at 360dp.
- No PIN or hash ever appears in logs, SQLite, or `.zip` backups.

### Risks & Rollback
- *Risk:* `FlutterFragmentActivity` theme mismatch on older Android themes -> verify `values/styles.xml` and `values-v31/styles.xml` on Android build.
- *Risk:* `image_picker` / `file_picker` briefly pausing activity triggers unwanted immediate lock -> mitigated by `suspendAutoLockDuringSystemPicker()`.
- *Rollback:* Revert `MainActivity.kt`, remove `AppLockGate` wrapper, and remove `lib/features/security/` (zero DB impact).

---

## Milestone 12.2 — Daily Workshop Productivity (Phase B)

### Packages & Database Changes
- **Packages:** None.
- **Database Changes:** None.

### Dependency-Ordered Tasks
1. **12.2.1 — Pure Dart Daily & Productivity Calculators:**
   - Create `lib/features/reports/domain/calculators/workshop_daily_calculator.dart` (Today/Date IST summary, important/oldest pending ranking, pending-age calculation, active recent `(processId, workerId)` & in-stock colour suggestions)
   - Extend `lib/features/reports/domain/entities/dashboard_report_entities.dart` (additive Today fields & `importantPendingIssues` on `DashboardSnapshot` + `DailyWorkshopSummary`)
   - Extend `lib/features/reports/domain/repositories/reports_repository.dart` & `reports_repository_impl.dart` (`getDailyWorkshopSummary(int istDayUtcMillis)`)
   - Add `getRecentIssueSuggestions()` to `StockMovementRepository` / `StockMovementRepositoryImpl`
2. **12.2.2 — Dashboard Redesign & Daily Summary Screen:**
   - Update `lib/features/dashboard/presentation/pages/dashboard_page.dart` (Today's Workshop card, 5-action Quick Dock + Lock Now icon when PIN enabled, compact 2×2 Live Status, Important Pending Work with 1-tap Return, tappable Process-wise Pending)
   - Create `lib/features/reports/presentation/bloc/daily_summary_cubit.dart` & `lib/features/reports/presentation/pages/daily_summary_page.dart` (`/daily-summary`)
   - Update `lib/core/router/route_paths.dart` & `app_router.dart`
3. **12.2.3 — Quick Issue & Quick Return Productivity Upgrades:**
   - Update `lib/features/stock_movements/presentation/pages/stock_issue_page.dart` (accept optional `processId`/`workerId` query params, Recent Work Pairs & Recent In-Stock chips, prominent Expected Labour preview, confirmation dialog for 100%-stock >=50 / rate override / >7d backdated issue)
   - Update `lib/features/stock_movements/presentation/pages/receive_return_picker_page.dart` (accept `?workerId=&processId=&lotId=`, `Oldest First` default / `Highest Pending` / `Newest First` sort chips, pending-age badges)
   - Update `lib/features/stock_movements/presentation/pages/stock_settlement_page.dart` (`All Good`, `Half`, `+10`, `+25`, dynamic `Fill Remaining Good`, Step 5 dynamic next-process shortcut chips)
4. **12.2.4 — Worker Work & Balance Overview & Actionable Empty States:**
   - Update `lib/features/workers/presentation/bloc/worker_detail_cubit.dart` & `worker_detail_page.dart` (add live pending qty, open issues with 1-tap Return, earned labour, outstanding/advance balance, quick Issue/Return/Ledger/Payment buttons)
   - Polish empty states & EN/GU strings in `app_en.arb` & `app_gu.arb`
5. **12.2.5 — Tests & Verification:**
   - Create `test/features/workshop_daily_test.dart` & `test/widget/workshop_ux_v1_2_test.dart`
   - Run `flutter gen-l10n`, `flutter analyze`, `flutter test`.

### Acceptance Criteria
- Dashboard displays accurate IST Today totals, Important Pending Work, and tappable Process Pending with zero overflow on 360dp EN/GU Light/Dark.
- Recent suggestions exclude inactive/unassigned/out-of-stock records; existing stock invariants and idempotency pass 100%.
- `WorkerDetailPage` accurately reflects live stock pending & ledger balances.

### Risks & Rollback
- *Risk:* Dashboard vertical bloat on 360dp phones -> mitigated by replacing 8 all-time tiles with compact Today (2×2) + Live Status (2×2) + top-3 Important Pending.
- *Rollback:* Pure presentation/domain additions; zero schema risk.

---

## Milestone 12.3 — Schema v3 Indexes, Advanced Reports, Insights & Gujarati-Safe Export (Phase C)

### Packages, Database & Native Changes
- **Add to `pubspec.yaml`:** `excel_plus: ^2.29.3` *(MIT-licensed; fallback `excel_community: ^2.6.2` if constraint conflict occurs)*.
- **Database Migration (`v2 -> v3`, Index-Only):**
  - Modify `lib/core/database/migrations/schema_indexes.dart` (add 5 `v3IndexStatements`)
  - Modify `lib/core/database/migrations/database_migration_manager.dart` (`currentSchemaVersion = 3`)
  - Add bounded read-only range/audit queries to `StockMovementDao`, `LabourEntryDao`, `PaymentDao`, `WorkerAdjustmentDao`, `AttachmentAuditDao`.
- **Native Android Print/PDF Channel:**
  - Extend `android/app/src/main/kotlin/com/brijesh/stitchflow/MainActivity.kt` with `MethodChannel("com.brijesh.stitchflow/report_print")` invoking Android `WebView` (`loadDataWithBaseURL("file:///android_asset/", ...)`) -> `PrintManager.print()` on `onPageFinished`.

### Dependency-Ordered Tasks
1. **12.3.1 — Schema v3 Indexes & Read-Only DAO Range Queries:**
   - Update `schema_indexes.dart`, `database_migration_manager.dart`, and the 5 DAOs; regenerate Drift code via `build_runner`.
   - Fix `NativeBackupRestoreService.appVersionString` to read `AppIdentity`.
2. **12.3.2 — Report Filter Entities & Single-Pass `ReportsAnalyticsCalculator`:**
   - Create `lib/features/reports/domain/entities/report_filter.dart` (`ReportFilter`, `ReportDatePreset`, `IstDateRangePresets`)
   - Create `lib/features/reports/domain/entities/advanced_report_entities.dart` (all 6 categories + `PeriodComparison` + `ProcessBottleneck` + `TrendPoint`)
   - Create `lib/features/reports/domain/calculators/reports_analytics_calculator.dart` (single-pass aggregation, turnaround time guard, zero-division safety, reversal exclusion, zero fabricated profit/revenue)
   - Refactor `lib/features/reports/data/repositories/reports_repository_impl.dart` to load tables once and delegate to `ReportsAnalyticsCalculator`.
3. **12.3.3 — Gujarati-Safe Print/PDF, Excel (`.xlsx`) & CSV Export Pipeline:**
   - Create `lib/features/reports/domain/services/report_export_service.dart`
   - Create `lib/features/reports/data/services/report_html_builder.dart` (bundles `@font-face` pointing to `NotoSansGujarati`, branded Navy/Teal table styling, truthful ledger footer)
   - Create `lib/features/reports/data/services/android_report_print_channel.dart`
   - Create `lib/features/reports/data/services/excel_csv_export_service.dart` (`Isolate.run` multi-sheet `.xlsx` + UTF-8 BOM `.csv` + `share_plus`)
4. **12.3.4 — Reports & Insights UI Overhaul:**
   - Update `lib/features/reports/presentation/bloc/reports_cubit.dart` (debounced search, 6 categories, presets, cascading Lot->Design->Colour filters, export actions)
   - Create `lib/features/reports/presentation/widgets/report_filter_bar.dart`, `report_trend_chart.dart` (`CustomPainter`), `report_export_sheet.dart`
   - Upgrade `lib/features/reports/presentation/pages/reports_page.dart` (6 clean categories, sub-views for Inventory & Financial, Insights dashboard, Print/Excel/CSV export button)
   - Add bilingual EN/GU strings to `app_en.arb` & `app_gu.arb`
5. **12.3.5 — Tests & Performance Benchmark:**
   - Create `test/features/reports_analytics_test.dart` (all 6 categories, presets, turnaround time, cross-check invariants vs `StockCalculator`/`LedgerCalculator`, 5,000-row benchmark, HTML/Excel/CSV Gujarati round-trip)
   - Create `test/widget/reports_v1_2_ui_test.dart`
   - Update `test/database/app_database_persistence_migration_test.dart` (deduplicate v1->v2 test + add v1->v3 & v2->v3 file-backed migration tests)

### Acceptance Criteria
- Single-pass `getAdvancedReports()` runs in `< 500ms` on 5,000 movements.
- Every report total reconciles 100% with `StockCalculator` and `LedgerCalculator`.
- Gujarati text renders properly in Print/Save-as-PDF preview and opens cleanly in `.xlsx` & `.csv`.

### Risks & Rollback
- *Risk:* Android `WebView` memory leak if not destroyed after print adapter completes -> hold `WebView` reference cleanly and release when print job finishes or new job starts.
- *Rollback:* Schema v3 indexes are purely additive and harmless; export & UI can be reverted independently without touching business data.

---

## Milestone 12.4 — Local Android Notifications (Phase D)

### Packages & Native Changes
- **Add to `pubspec.yaml`:** `flutter_local_notifications: ^22.0.0` (verified against existing `timezone: ^0.11.2`).
- **Modify `android/app/build.gradle.kts`:** Enable `isCoreLibraryDesugaringEnabled = true` and add `coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")`.
- **Modify `android/app/src/main/AndroidManifest.xml`:** Add `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `ScheduledNotificationReceiver`, and `ScheduledNotificationBootReceiver` (`exported="false"`).
- **Database Changes:** None (reads existing repos + `AttachmentAuditDao.getLatestAuditByAction('BACKUP_EXPORT')`; stores notification settings in flavor-prefixed `SharedPreferences`).

### Dependency-Ordered Tasks
1. **12.4.1 — Pure Dart Notification Entities & Deterministic Planner:**
   - Create `lib/features/notifications/domain/entities/notification_entities.dart`
   - Create `lib/features/notifications/domain/calculators/notification_plan_calculator.dart` (all 5 categories, deterministic IDs `1001–1005`, IST scheduling, quiet-day skip, lock-screen privacy redaction when PIN enabled, 24h alert cooldown)
   - Create `lib/features/notifications/domain/services/local_notification_service.dart`
2. **12.4.2 — Android Plugin Adapter, Settings Repo & Refresh Coordinator:**
   - Create `lib/features/notifications/data/repositories/notification_settings_repository.dart`
   - Create `lib/features/notifications/data/services/flutter_local_notifications_adapter.dart` (`AndroidScheduleMode.inexactAllowWhileIdle`, 5 channels, Android 13+ permission checks, tap payload callback)
   - Create `lib/features/notifications/data/services/notification_refresh_coordinator.dart`
   - Hook lightweight non-blocking `NotificationRefreshCoordinator.refresh()` into `bootstrap.dart`, `AppLockGate` resume, `StockMovementRepositoryImpl` (issue/settlement/repair), `AccountingRepositoryImpl` (payment/adjustment), `NativeBackupRestoreService` (backup export), `AppSessionController` (restore), and `LocaleCubit` (language change).
   - Wire notification tap payload into `AppLockCubit` (lock-safe deep linking!).
3. **12.4.3 — Notification Settings UI:**
   - Create `lib/features/notifications/presentation/bloc/notification_settings_cubit.dart`
   - Create `lib/features/notifications/presentation/pages/notification_settings_page.dart` (`/settings/notifications`)
   - Update `route_paths.dart`, `app_router.dart`, `settings_home_page.dart` (add Notifications & Reminders tile), `app_en.arb`, `app_gu.arb`
4. **12.4.4 — Tests & Verification:**
   - Create `test/features/notifications_plan_test.dart` & `test/widget/notifications_ui_test.dart`
   - Run `flutter gen-l10n`, `flutter analyze`, `flutter test`, `.\build_apk.bat dev debug`.

### Acceptance Criteria
- Notifications schedule offline in `Asia/Kolkata`, never duplicate, immediately cancel when pending work or balances are settled, respect denied permissions gracefully, hide rupee amounts when PIN lock is ON, and defer deep-link navigation until unlock.

### Risks & Rollback
- *Risk:* `flutter_local_notifications` Gradle desugaring mismatch -> verified via `.\build_apk.bat dev debug` and `prod` release immediately in 12.4.4.
- *Rollback:* Disable `NotificationRefreshCoordinator` hooks and remove Settings entry; zero DB impact.

---

## Milestone 12.5 — Full QA, Migration, Backup/Restore & Release (`1.2.0+3`)

### Dependency-Ordered Tasks
1. **12.5.1 — Help Catalog, Localization Audit & Version Bump:**
   - Expand `lib/features/settings/domain/help_topics.dart` from 15 -> **19 bilingual topics** (adding: App PIN & Biometrics, Recovery Key & Lock Safety, Advanced Reports & PDF/Excel Export, Local Reminders & Notifications).
   - Complete `DomainLabelLocalizer` mappings (`BACKUP_EXPORT`, `BACKUP_RESTORE`, `DEACTIVATE`, `REACTIVATE`, `DAMAGED_TO_GOOD_ADJUSTMENT`, `backup`, `app_security`).
   - Polish `LedgerCalculator` strings if needed so Gujarati ledger views have zero raw English fragments.
   - Bump `pubspec.yaml` to `1.2.0+3` and `AppIdentity` (`appVersion = '1.2.0'`, `appBuildNumber = '3'`).
2. **12.5.2 — Full End-to-End, Cross-Version Backup & Responsive QA:**
   - Extend `test/features/end_to_end_business_workflow_test.dart` to verify V1.2 Reports, Insights, Notification plan sync, and V1.1 (`v2`) -> V1.2 (`v3`) `.zip` restore with active PIN preserved.
   - Verify 360dp / 800dp / 1280dp + EN/GU + Light/Dark zero-overflow across every V1.2 screen.
3. **12.5.3 — Full Build Verification & Release Report:**
   - Execute `dart format .`, `flutter gen-l10n` (verify `l10n_untranslated.txt == {}`), `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze` (0 issues), `flutter test` (100% pass).
   - Build and verify all 4 Android APKs: `.\build_apk.bat dev debug`, `.\build_apk.bat prod debug`, `.\build_apk.bat dev`, `.\build_apk.bat prod`.
   - Write final release report `docs/41_STITCHFLOW_V1_2_RELEASE_REPORT.md` with exact executed results and manual Android testing instructions.

### Acceptance Criteria
- 0 analyzer warnings/errors, 0 untranslated EN/GU keys, 100% automated test pass rate, all 4 Dev/Prod Android APKs built and verified cleanly.
