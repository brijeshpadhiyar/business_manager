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
