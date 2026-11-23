# Changelog

All notable changes to the **Business Manager (`બિઝનેસ મેનેજર`)** project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
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
