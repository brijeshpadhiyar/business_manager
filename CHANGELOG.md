# Changelog

All notable changes to the **Business Manager (`બિઝનેસ મેનેજર`)** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - System Improvements (Phases 1–4)

### Added
- **Interactive System Guidance, Button Spotlights, Voice Narration & Complete User Guide Hub**:
  - Built a custom native Flutter `Overlay`/root-stack spotlight engine (`GuideSpotlightOverlay`, `GuideTarget`, `GuideTargetRegistry`) with button-upper callout bubbles, automatic scroll-into-view, and interactive pass-through.
  - Added offline bilingual Text-to-Speech narration (`flutter_tts: ^4.2.5`, `FlutterTtsGuideVoiceService`) supporting English & Gujarati (`gu-IN`) with 1-tap Mute/Replay/Speed controls and silent graceful fallback when a device voice pack is unavailable.
  - Added **First-Time Welcome Card** on Dashboard (language picker EN/GU, Voice ON/OFF, Start Complete Training, Explain This Screen, Skip), **9-Chapter End-to-End Action Coach** (walking across Dashboard, Settings, Processes, Workers, Lots, Stock Issue, Receive Return, Accounting, and Reports with floating "What To Do Next" Action Coach banner), per-screen `?` Guide Quick Menu, and subtle first-visit screen hints.
  - Upgraded **Help & Guidance** (`HelpGuidancePage` & `HelpTopicDetailPage`) into a full Training & User Guide Hub with 9-chapter progress tracking, **"Show Me Live"** deep-launch links, step-highlighted audio playback across all 19 bilingual topics, and **"What To Do Next"** workflow links.
- **Phase 1 — CI/CD Safety Net & Data Trust (`v1.5.1`)**:
  - Added GitHub Actions CI workflows (`.github/workflows/ci.yml` for PR `gen-l10n`, `analyze`, `test`, and Web release build; `.github/workflows/release_builds.yml` for tag/manual Android `dev`/`prod` APK & Windows release bundles).
  - Built **Data Health & Reconciliation Center** (`Settings → Data Health & Diagnostics`) verifying `PRAGMA integrity_check`, `PRAGMA foreign_key_check`, golden stock equation across every design/colour, worker ledger parity, sync queue counts, and media parity, plus safe audited maintenance actions (WAL checkpoint, orphan media cleanup, failed sync retry) and shareable diagnostic export.
  - Surfaced `Pending QC` (`pendingInspectionStock` / `pendingInspection`) KPIs & columns across Dashboard and Reports (Inventory KPI strip, Lot Stock table, Colour Stock table).
  - Localized all 53 remaining hardcoded English strings in Process Routing (`job_process_routing_page.dart`, `job_routing_cubit.dart`, `RoutingErrorLocalizer`) with a regression guard test (`hardcoded_ui_strings_guard_test.dart`).
  - Updated `ReportHtmlBuilder` print/PDF styling to the Indigo Thread palette (`#4F46E5`, `#059669`, `#F59E0B`) and added Material 3 `Badge` support to `ResponsiveNavigation` with live Sync attention badges.
- **Phase 2 — Bilingual Karigar Slips & Daily Speed (`v1.6.0`)**:
  - Built unified bilingual **Karigar Slips** (`lib/features/slips/`) supporting Stock Issue Challan, Return/QC Slip, Payment Receipt, and Worker Khata Statement with 3 zero-dependency sharing modes: **Branded PNG Receipt Image (`RepaintBoundary`)**, **WhatsApp/SMS Bilingual Text (+ Copy)**, and **Offline Printable HTML/PDF**, plus an in-sheet EN/GU language toggle.
  - Added **Audited Undo Snackbars** (6-second Undo triggering standard audited reversal rows), **Form Draft Autosave & Remembered Defaults** (`FormDraftService`), **First-Run Workshop Setup Checklist** (`SetupChecklistCard` on Dashboard), and **Compact/Comfortable Layout Density Toggle** (`DensityCubit` wired into `AppTheme` & `AppearanceSettingsPage`).
- **Phase 3 — Multi-User Team RBAC & Cloud Sync v2 (`v1.7.0`, Drift Schema v11)**:
  - Added Supabase Migration 4 (`supabase/migrations/20261127000004_v1_7_team_rbac.sql`) introducing `business_members`, `business_invites`, `stitchflow_user_role()`, `stitchflow_redeem_invite()`, and role-aware RLS across all 23 domain tables and private storage.
  - Added pure-Dart 4-role `RbacPolicy` (`OWNER`, `MANAGER`, `QC_INSPECTOR`, `ACCOUNTANT`) + `PermissionGate` widget, `SupabaseTeamRepository`, and `TeamManagementPage` (`Settings → Team & Role Access`) with WhatsApp-shareable 8-char invite codes (`XXXX-XXXX`).
  - Executed additive Drift SQLite **Schema v10 → v11** migration (`active_role`, `active_business_name`, `cached_team_members`, `idx_audit_logs_reason_rec`).
  - Built **Sync Conflict Inspector** (`SyncConflictInspectorPage` + `SyncConflictService`) with side-by-side field diffs (`Your Superseded Edit` vs `Applied Cloud Version`) and non-blocking Acknowledge / One-Tap Audited Restore.
- **Phase 4 — SQLite DB Pagination, Modular Cleanup & Portable QA Gates (`v1.8.0`)**:
  - Added true SQLite `LIMIT`/`OFFSET` and O(log N) keyset/cursor pagination (`PageRequest`, `CursorPageRequest`, `PagedResult<T>`) across `LotDao`, `ProcessMemberDao`, `StockMovementDao`, `PaymentDao`, and `AttachmentAuditDao`, plus `buildWhen` scoping on heavy pages.
  - Extracted modular UI widgets (`stock_issue_step_widgets.dart`, `routing_handover_row.dart`) and added Indigo Thread semantic surface aliases (`AppElevatedSurface`, `surfaceFill`, `navBarFill`).
  - Added **5,000-movement SQLite scale & index benchmark** (`scale_5000_movements_benchmark_test.dart`) and **Android tap-target/contrast accessibility + 300px keyboard-open sheet** tests (`accessibility_and_keyboard_sheets_test.dart`).

## [Unreleased] - System Improvements (Phases 1–4)

### Added
- **Phase 1 — CI/CD Safety Net & Data Trust (`v1.5.1`)**:
  - Added GitHub Actions CI workflows (`.github/workflows/ci.yml` for PR `gen-l10n`, `analyze`, `test`, and Web release build; `.github/workflows/release_builds.yml` for tag/manual Android `dev`/`prod` APK & Windows release bundles).
  - Built **Data Health & Reconciliation Center** (`Settings → Data Health & Diagnostics`) verifying `PRAGMA integrity_check`, `PRAGMA foreign_key_check`, golden stock equation across every design/colour, worker ledger parity, sync queue counts, and media parity, plus safe audited maintenance actions (WAL checkpoint, orphan media cleanup, failed sync retry) and shareable diagnostic export.
  - Surfaced `Pending QC` (`pendingInspectionStock` / `pendingInspection`) KPIs & columns across Dashboard and Reports (Inventory KPI strip, Lot Stock table, Colour Stock table).
  - Localized all 53 remaining hardcoded English strings in Process Routing (`job_process_routing_page.dart`, `job_routing_cubit.dart`, `RoutingErrorLocalizer`) with a regression guard test (`hardcoded_ui_strings_guard_test.dart`).
  - Updated `ReportHtmlBuilder` print/PDF styling to the Indigo Thread palette (`#4F46E5`, `#059669`, `#F59E0B`) and added Material 3 `Badge` support to `ResponsiveNavigation` with live Sync attention badges.
- **Phase 2 — Bilingual Karigar Slips & Daily Speed (`v1.6.0`)**:
  - Built unified bilingual **Karigar Slips** (`lib/features/slips/`) supporting Stock Issue Challan, Return/QC Slip, Payment Receipt, and Worker Khata Statement with 3 zero-dependency sharing modes: **Branded PNG Receipt Image (`RepaintBoundary`)**, **WhatsApp/SMS Bilingual Text (+ Copy)**, and **Offline Printable HTML/PDF**, plus an in-sheet EN/GU language toggle.
  - Added **Audited Undo Snackbars** (6-second Undo triggering standard audited reversal rows), **Form Draft Autosave & Remembered Defaults** (`FormDraftService`), **First-Run Workshop Setup Checklist** (`SetupChecklistCard` on Dashboard), and **Compact/Comfortable Layout Density Toggle** (`DensityCubit` wired into `AppTheme` & `AppearanceSettingsPage`).
- **Phase 3 — Multi-User Team RBAC & Cloud Sync v2 (`v1.7.0`, Drift Schema v11)**:
  - Added Supabase Migration 4 (`supabase/migrations/20261127000004_v1_7_team_rbac.sql`) introducing `business_members`, `business_invites`, `stitchflow_user_role()`, `stitchflow_redeem_invite()`, and role-aware RLS across all 23 domain tables and private storage.
  - Added pure-Dart 4-role `RbacPolicy` (`OWNER`, `MANAGER`, `QC_INSPECTOR`, `ACCOUNTANT`) + `PermissionGate` widget, `SupabaseTeamRepository`, and `TeamManagementPage` (`Settings → Team & Role Access`) with WhatsApp-shareable 8-char invite codes (`XXXX-XXXX`).
  - Executed additive Drift SQLite **Schema v10 → v11** migration (`active_role`, `active_business_name`, `cached_team_members`, `idx_audit_logs_reason_rec`).
  - Built **Sync Conflict Inspector** (`SyncConflictInspectorPage` + `SyncConflictService`) with side-by-side field diffs (`Your Superseded Edit` vs `Applied Cloud Version`) and non-blocking Acknowledge / One-Tap Audited Restore.
- **Phase 4 — SQLite DB Pagination, Modular Cleanup & Portable QA Gates (`v1.8.0`)**:
  - Added true SQLite `LIMIT`/`OFFSET` and O(log N) keyset/cursor pagination (`PageRequest`, `CursorPageRequest`, `PagedResult<T>`) across `LotDao`, `ProcessMemberDao`, `StockMovementDao`, `PaymentDao`, and `AttachmentAuditDao`, plus `buildWhen` scoping on heavy pages.
  - Extracted modular UI widgets (`stock_issue_step_widgets.dart`, `routing_handover_row.dart`) and added Indigo Thread semantic surface aliases (`AppElevatedSurface`, `surfaceFill`, `navBarFill`).
  - Added **5,000-movement SQLite scale & index benchmark** (`scale_5000_movements_benchmark_test.dart`) and **Android tap-target/contrast accessibility + 300px keyboard-open sheet** tests (`accessibility_and_keyboard_sheets_test.dart`).

## [1.5.0] - 2026-11-26

### Added
- **Dual Cloud Authentication (Google Sign-In + Phone Number OTP) (`lib/features/auth/`)**:
  - Offline-first optional sign-in: existing v1.4 users continue working offline immediately, new users can choose **Continue with Google**, **Continue with Phone Number (SMS OTP)**, or **Continue Offline (Local Only)**.
  - Cached secure auth sessions (`flutter_secure_storage`) allow indefinite offline usage once signed in.
  - Added **Account & Identity Linking** screen (`AccountSettingsPage`) to link both Google and Phone Number to the same StitchFlow account, view synced devices, and sign out safely with unsynced-changes warnings.
- **Complete Supabase Backend & Storage (`supabase/migrations/`)**:
  - Added full PostgreSQL migrations mirroring all 23 Drift SQLite tables with composite `(business_id, id)` primary keys, server-side `server_updated_at` triggers, strict owner-scoped Row-Level Security (RLS), Realtime `sync_notifications` wake-ups, and a private `stitchflow-media` Storage bucket for lot photos and business logo.
  - Added `supabase/README.md` with isolated `dev`/`prod` project setup, Google OAuth, and Phone OTP (test OTPs in `dev`, MSG91/Twilio in `prod`) instructions.
- **Offline-First Bidirectional Sync Engine (`lib/features/sync/`, Drift Schema v10)**:
  - Additive SQLite schema migration `v9 -> v10` adding `sync_session_state`, `sync_outbox`, `sync_cursors`, and `sync_media_queue` plus guarded SQLite change-capture triggers across all 23 domain tables (zero echo loops during remote apply).
  - Implemented `SyncEngine` with FK topological push order, self-referencing parent-first ordering, incremental delta pulls (`server_updated_at > cursor`), SHA-256 cloud media upload/lazy download, exponential backoff retries, Smart First-Login Merge Prompt, and Last-Write-Wins (LWW) conflict resolution with `audit_logs` diff recording.
  - Added live **SyncStatusBadge** in the app shell and dedicated **Cloud Sync Center** (`SyncCenterPage`) in Settings.
- **Account-Scoped App Lock & Cloud PIN Recovery (`lib/features/security/`)**:
  - Namespaced local App Lock PIN storage by active user ID with seamless v1.4 legacy PIN migration and optional Google re-authentication recovery on `PinRecoveryPage`.
- **Localization & Tests**:
  - Added complete English and Gujarati (`app_en.arb` + `app_gu.arb`) translations for all v1.5 auth, sync, merge, and recovery flows.
  - Added automated tests for Schema v10 migration & triggers, `SyncConflictResolver`, `SyncEngine`, and `AuthCubit`.

## [1.1.0] - 2026-11-23

### Added
- **Centralized Settings & Bilingual Help Hub (`lib/features/settings/`)**:
  - Dedicated **Settings** destination organizing **Appearance** (System/Light/Dark + System/English/Gujarati with live readability preview), **Business Profile** (single source of truth), **Stock & Labour Preferences** (global billing mode + per-process override overview), **Backup & Data Safety**, **Help & Guidance**, and **About StitchFlow** (`1.1.0+2`, flavor info, offline privacy guarantee, licenses).
  - Added searchable 15-topic practical garment workshop **Help & Guidance** guide in both English and Gujarati with *When to Use*, numbered step cards, and practical examples.
- **Redesigned Stock Issue & Receive Return Workflows**:
  - Streamlined 4-step guided **Stock Issue** flow (+ Step 5 Success screen with updated available stock, *Issue More Stock*, and *View Issue / Receive Return* shortcuts), searchable in-stock selector, tap-friendly Process/Worker chips, live locked rate & billing mode preview, quick-fill quantity chips, and live over-stock validation.
  - Added searchable/filterable **Receive Return** Pending Issue picker (`ReceiveReturnPickerPage`) and redesigned settlement flow with live dynamic remaining pending bar, `All Good` quick fill, clear Lost vs. Shortage helpers, live stock & labour consequences preview powered by `LabourCalculator`, mandatory reason guard, and post-save *Issue Returned Stock to Next Process* shortcut.
  - Added `DomainLabelLocalizer` to localize all stock movement types, labour basis types, billing modes, and audit log actions/entities (zero raw database enum strings in UI).
  - Added 112 new EN/GU localization keys (`0` untranslated) and `test/widget/v1_1_ux_settings_stock_workflows_test.dart` (`77/77` total tests passing).
- **Documentation**: Created `docs/40_STITCHFLOW_V1_1_UX_IMPROVEMENT_REPORT.md`.

### Fixed
- **Android 12+ & Legacy Branded Splash Screen**:
  - Fixed blank `drawable-v21/launch_background.xml`, added `drawable-night-v21/launch_background.xml`, added Android 12+ `values-v31/styles.xml` and `values-night-v31/styles.xml` with safe-zone `splash_icon_android12.png` and `splash_branding_light/dark.png`, replaced unscaled `nodpi` splash bitmaps with density-bucketed (`mdpi`–`xxxhdpi`) drawables, and aligned `NormalTheme` window backgrounds (`#F5F7FA` / `#0D1422`) to eliminate launch flashes.
- **Gujarati & Responsive Text/Layout Fixes**:
  - Calibrated `AppTypography` line heights (`1.38–1.50`) with `TextLeadingDistribution.even` and `fontFamilyFallback` to prevent Gujarati matra/descender clipping; replaced missing `→` (`U+2192`) glyph across rate displays.
  - Upgraded `AppAnimatedNumber` with `FittedBox(fit: BoxFit.scaleDown)` (zero silent currency/quantity truncation), `AppButton` & `AppStatusBadge` to wrap gracefully in Gujarati, `AppDropdown` to synchronize controlled selections cleanly, and mobile `NavigationBar` to 5 spacious tabs (`Dashboard`, `Lots`, `Stock`, `Workers`, `Settings`).
  - Fixed 360dp wrapping, responsive KPI grids, and modal controller disposal across Dashboard, Lots, Inventory, Processes, Workers, Rates, Stock, Accounting, Worker Ledger, Reports, and Help screens.

## [1.0.0] - V1 Release

### Added
- **Premium UI/UX Transformation & Design System (`docs/34_UI_UX_DESIGN_SYSTEM.md`)**:
  - Upgraded StitchFlow Material 3 design tokens (`AppColors`, `AppSurfaceTokens`, `AppRadius`, `AppTheme`, `AppMotion`) while preserving official brand colors (`#172B4D`, `#0D9488`, `#F4A340`, `#F5F7FA`).
  - Added selective glassmorphism (`AppGlassSurface`), animated KPI counters (`AppAnimatedNumber`, `AppMetricTile`), skeleton placeholders (`AppSkeletonBox`, `AppSkeletonList`), styled feedback (`AppFeedback`), and reduced-motion-safe Material 3 motion transitions (`animations: ^3.0.0`, `flutter_animate: ^4.5.2`).
  - Upgraded `AppCard`, `AppButton`, `AppStatusBadge`, `AppDialog`, `AppBottomSheet`, `AppDataTable`, `AppEmptyState`, `AppErrorView`, `AppDatePicker` (with IST date+time mode), and `ResponsiveNavigation` (fade-through tab switching + branded sidebar).
- **Milestone 6 — Stock Movements (`docs/35_MILESTONE_6_STOCK_MOVEMENTS_REPORT.md`)**:
  - Implemented pure Dart `StockCalculator` with multi-process independent flow, physical stock cap, combined Good/Damaged/Lost/Shortage settlements, damaged-to-good repair adjustments, and chronological prefix replay reversal protection.
  - Implemented atomic `StockMovementRepositoryImpl` (5-point pre-issue validation, historical rate & billing lock via `MemberProcessRateResolver`, idempotent `client_request_id`, append-only history) and full UI (`StockMovementsPage`, `StockIssuePage`, `StockSettlementPage`, `DamagedRepairPage`).
- **Milestone 7 — Labour, Worker Ledger & Payments (`docs/36_MILESTONE_7_LABOUR_AND_WORKER_ACCOUNTS_REPORT.md`)**:
  - Implemented pure Dart `LabourCalculator` (default `RECEIVED_QTY`, per-process overrides, optional damaged inclusion, anti-double-counting lock) and `LedgerCalculator` (earned labour, advances, negative advance credit balances, adjustments, running balance, IST date filters).
  - Executed additive, zero-data-loss SQLite schema migration `v1 → v2` adding `worker_ledger_adjustments` + `WorkerAdjustmentDao` with automated file-backed migration tests.
  - Implemented `AccountingRepositoryImpl` and full UI (`AccountingOverviewPage`, `WorkerLedgerPage`, `PaymentFormPage`, `WorkerAdjustmentFormPage`).
- **Milestone 8 — Offline Backup, Restore & Data Safety (`docs/37_MILESTONE_8_BACKUP_RESTORE_REPORT.md`)**:
  - Implemented `NativeBackupRestoreService` with WAL-safe `PRAGMA wal_checkpoint(TRUNCATE)` + `VACUUM INTO` snapshots, `PRAGMA integrity_check`, full `.zip` backup (DB + private media + SHA-256 `manifest.json`), clearly separated raw `.sqlite` inspection export, cross-flavor (`dev → prod`) protection, and atomic fail-safe restore with automatic rollback + `AppSessionController` DI reload.
  - Added `BackupRestorePage` with progress tracking, manifest verification preview, and explicit overwrite confirmation.
- **Milestone 9 — Live Dashboard & 10 Business Reports (`docs/38_MILESTONE_9_DASHBOARD_REPORTS_REPORT.md`)**:
  - Upgraded `DashboardPage` to live database-backed KPIs (inventory health, separate worker accounting metrics, process-wise pending work, recent audit activity) and implemented `ReportsPage` covering all 10 filterable bilingual business reports.
- **Milestone 10 — Final QA & Release Readiness (`docs/39_MILESTONE_10_FINAL_QA_RELEASE_REPORT.md`)**:
  - Added 177 bilingual EN/GU localization keys (`0` untranslated), full 18-step E2E workflow tests, pure Dart calculator tests, `v1 → v2` migration tests, responsive EN/GU Light/Dark widget tests, and verified `dev`/`prod` Android APK builds.
- **Phase 0 — Complete Technical Blueprint & Project Documentation (`docs/00` – `docs/22`)**:
  - Project overview, confirmed V1 business requirements, functional requirements, and non-functional requirements.
  - Verified 2026 Flutter `3.50.1` / Dart `3.14.0` technology stack and 6-platform compatibility matrix (`drift ^2.35.3`, `drift_flutter ^0.3.1`, `sqlite3 ^3.9.1`, `flutter_bloc ^9.1.1`, `go_router ^18.1.4`, `freezed ^4.0.2`, `injectable ^3.0.0`, `get_it ^8.0.2`).
  - Feature-first Clean Architecture, folder structure, complete Drift/SQLite database schema, and entity relationship documentation.
  - Confirmed stock calculation rules (multi-process independent flow, physical stock cap, Good/Damaged/Lost/Shortage settlements, damaged stock bucket with authorized repair adjustment).
  - Confirmed labour calculation rules (default *Pay on Received Good Quantity*, global & per-process billing mode, optional per-process damaged inclusion, anti-double-counting invariants, advance payments & negative balances).
  - Confirmed historical member pricing rules (`transactionAt` IST date lookup, partial return rate lock, audited manual override).
  - UTC storage & `Asia/Kolkata` display audit strategy, offline private storage, Web WASM OPFS/IndexedDB strategy, unencrypted v1 `.sqlite` export & `.zip` backup/restore strategy.
  - Official Material 3 centralized design system powered by `material_ui: ^1.11.1` (`flutter.dev`), 20 reusable common widgets, English/Gujarati `gen-l10n` strategy with bundled Noto Sans Gujarati, `dev`/`prod` flavor isolation, Android-first responsive UI strategy, comprehensive test strategy, implementation roadmap, and Architecture Decision Records (ADRs).
- Root governance files: `README.md`, `CHANGELOG.md`, `DEVELOPMENT_GUIDELINES.md`, and `AGENT_RULES.md`.
- **Phase 0 Documentation Audit (`docs/23_DOCUMENTATION_AUDIT_REPORT.md`)**:
  - Completed full line-by-line audit of all 27 documentation & governance files.
  - Added single-reversal `UNIQUE` partial indexes on `stock_movements`, `labour_entries`, and `payments`, plus `labour_entries.reverses_labour_entry_id`, `members.address`, `payments.reason`, and uniform `created_by`/`updated_by` audit columns in `docs/07_database_schema.md`.
  - Updated `docs/05_system_architecture.md` settlement flow to read + validate + insert inside a single atomic Drift transaction (eliminating TOCTOU race risk).
  - Clarified reversed-labour active-row filtering (`docs/10_labour_calculation_rules.md`), native `image_picker` compression (`docs/04_technology_stack.md`, `docs/13_offline_storage_strategy.md`), Web WASM byte export vs native `VACUUM INTO` (`docs/14_backup_restore_strategy.md`), and added Test #27 (`docs/20_testing_strategy.md`).
- **Milestone 3.6 — StitchFlow APK Build Automation (`docs/31_STITCHFLOW_BUILD_AUTOMATION.md`, `docs/32_MILESTONE_3_6_IMPLEMENTATION_REPORT.md`)**:
  - Added root `build_apk.bat` and `scripts/build_apk.ps1` for one-command `dev`/`prod` (`release` default, optional `debug`) Android APK builds with Asia/Kolkata timestamps into `build/releases/<flavor>/`, stale-APK protection, and non-zero exit codes on failure.
  - Updated `.gitignore` for `/build/releases/` & `*.apk`, resolved Android Release Lint `MissingDefaultResource` on `splash_brand_dark.png`, and verified all 4 APK builds (`dev`/`prod` release & debug) + `flutter analyze` (0 issues) + `flutter test` (`42/42`).
- **Milestone 5 — StitchFlow Processes, Workers & Historical Rates (`docs/33_MILESTONE_5_IMPLEMENTATION_REPORT.md`)**:
  - Implemented Module A (Dynamic Production Process Management: create, edit, list, search, active/inactive filter & toggle, process details with assigned workers and audit history; zero hardcoded processes or sequence).
  - Implemented Module B (Worker Management on `members` table: create, edit, list, search, active/inactive filter & toggle, Worker Profile Summary showing contact info, assigned processes, and current per-piece rates without labour/payment balances).
  - Implemented Module C (Many-to-Many Worker-Process Assignments on `member_processes`: multi-process per worker, multi-worker per process, active status guards, duplicate rejection, and non-destructive deactivation/reactivation).
  - Implemented Module D (Historical Per-Piece Rates on `member_process_rates` in integer paise with IST `YYYY-MM-DD` effective dates, non-overlap validation, confirmed atomic auto-close of open-ended rates, historical lock protection against stock-movement-referenced edits) and pure Dart `MemberProcessRateResolver` domain service.
  - Added 88 bilingual EN/GU localization keys (`0` untranslated), fixed Desktop `NavigationDrawer` label overflow, added 15 new unit/repository/widget tests (`57/57` passing, `flutter analyze` 0 issues, Android `dev` debug APK built).
- **Milestone 4 — StitchFlow Business Foundation (`docs/30_MILESTONE_4_IMPLEMENTATION_REPORT.md`)**:
  - Implemented Modules A–F: Business Profile, Lot Management (CRUD, search, filter, archive), Lot Photos (camera/gallery capture, private storage, SHA-256, orphan-file cleanup), Design Management, independent Colour Management (quantities & integer paise prices), and pure Dart read-only Initial Inventory Overview.
  - Added StitchFlow `ResponsiveNavigation` shell (`Dashboard`, `Lots`, `Inventory`, `Business Profile`, `/lots/:id`, and `dev`-accessible `/showcase`) with 80 new EN/GU localized strings (`0` untranslated).
  - Added comprehensive feature & widget tests (`42/42` passing, `flutter analyze` 0 issues, Android `dev` APK built).
- **Milestone 3.5 — StitchFlow Branding & Application Identity (`docs/28_STITCHFLOW_BRAND_AND_APP_IDENTITY.md`, `docs/29_MILESTONE_3_5_IMPLEMENTATION_REPORT.md`)**:
  - Adopted official **StitchFlow** (`સ્ટિચફ્લો`) identity, tagline (*From Fabric to Finished.*), and **Concept A — Thread S** vector/raster logo, adaptive icon, desktop `.ico`/`.icns`, Web PWA icon, and Light/Dark splash asset suite (`assets/branding/`).
  - Updated platform application IDs (`com.brijesh.stitchflow` / `com.brijesh.stitchflow.dev`), registered `stitchflow://` custom URL scheme on Android & iOS, and integrated official brand colors (`#172B4D`, `#0D9488`, `#F4A340`, `#F5F7FA`) into `AppColors`/`AppTheme` while preserving semantic status tokens.
  - Added centralized `AppIdentity`, 5 new branding/identity unit tests (`35/35` passing, `flutter analyze` 0 issues, both `dev` and `prod` Android APKs built).
- **Milestone 3 — Offline Database Core (Drift + SQLite) (`docs/27_MILESTONE_3_IMPLEMENTATION_REPORT.md`)**:
  - Implemented all 13 documented Drift tables, 20 SQLite indexes/partial unique constraints (active uniqueness, single-reversal guards, labour idempotency, `client_request_id` idempotency), and `CHECK` constraints.
  - Implemented 7 persistence-only DAOs (with strictly append-only `StockMovementDao`, `LabourEntryDao`, `PaymentDao`, and `AuditLogs`), `AppDatabase`, `DatabaseInitializer`, `DatabaseTransactionRunner`, and `DatabaseMigrationManager` (seeding default `business_profile`).
  - Verified effective SQLite PRAGMAs (`foreign_keys = ON`, `journal_mode = WAL`, `synchronous = FULL`, `busy_timeout = 5000`) and implemented private flavor-isolated `NativeMediaStorageService` with SHA-256 checksums and path-traversal protection.
  - Added 12 database/rollback/persistence/migration/media tests (`30/30` passing, `flutter analyze` 0 issues, Android `dev` APK built).
- **Milestone 2 — Material 3 Design System & Common Widget Library (`docs/26_MILESTONE_2_IMPLEMENTATION_REPORT.md`)**:
  - Implemented centralized Material 3 tokens (`AppColors`, `AppSemanticColors`, `AppSpacing`, `AppSizing`, `AppRadius`, `AppElevation`, `AppBreakpoints`, `AppTypography`, `AppTheme.light()` / `AppTheme.dark()`) built on `material_ui: ^1.11.1`.
  - Implemented persistent `ThemeCubit` (`System`, `Light`, `Dark`) saved in `SharedPreferences` and wired reactively in `lib/app.dart`.
  - Implemented all 20 centralized common widgets (`AppScaffold` through `AppDataTable` & `ResponsiveNavigation`) in `lib/core/widgets/`.
  - Added bilingual EN/GU `DesignSystemShowcasePage` (`0` untranslated ARB keys) and 11 new unit/widget tests (`18/18` passing, `flutter analyze` 0 issues, Android `dev` APK built).
- **Milestone 1 — Flutter Project Foundation (`docs/25_MILESTONE_1_IMPLEMENTATION_REPORT.md`)**:
  - Configured verified V1 dependencies in `pubspec.yaml` (keeping official `material_ui: ^1.11.1`, `flutter_bloc`, `drift`/`sqlite3`, `go_router`, `freezed`, `get_it`/`injectable`, `intl`, `timezone`, `shared_preferences`, media/backup packages, and `build_runner: ^2.16.1`).
  - Bundled Noto Sans Gujarati (`Regular`, `Medium`, `SemiBold`, `Bold`) offline font assets in `assets/fonts/`.
  - Implemented `gen-l10n` English (`en`) and Gujarati (`gu`) localization with persisted `LocaleCubit` (`System Default`, `English`, `Gujarati`).
  - Configured isolated `dev` (`com.brijesh.business_manager.dev`) and `prod` (`com.brijesh.business_manager`) flavors in Android Gradle, `config/*.json`, `AppConfig`, and production-silent `AppLogger`.
  - Implemented core DI, minimal `go_router` foundation shell, `IstDateTimeHelper`, `MoneyFormatter`, `IdGenerator`, and unit/widget tests (7/7 passing; `flutter analyze` 0 issues; both `dev` and `prod` Android APKs built).
- **Final Technical Safeguards (`docs/24_FINAL_TECHNICAL_SAFEGUARDS.md`)**:
  - Added chronological prefix replay stock reversal dependency protection for `RETURN_GOOD`, `RETURN_DAMAGED`, and `ADJUSTMENT_DAMAGED_TO_GOOD` (`docs/09_stock_calculation_rules.md`).
  - Added labour entry idempotency (`idx_labour_movement_basis_unique`) and `client_request_id` unique partial indexes on `stock_movements` and `payments` (`docs/07_database_schema.md`, `docs/10_labour_calculation_rules.md`).
  - Upgraded SQLite durability to `PRAGMA synchronous = FULL` in `WAL` mode (`ADR-012`), added atomic 5-point worker-process pre-issue validation, hardened WAL `VACUUM INTO` backup & production restore confirmation (`docs/14_backup_restore_strategy.md`), and added Tests #28–#34 (`docs/20_testing_strategy.md`).
