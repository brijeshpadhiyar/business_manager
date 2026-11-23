# 27 — Milestone 3 Implementation Report (Offline Database Core — Drift + SQLite)

**Completed Date:** 2026-11-23  
**SDK & Stack Verified:** Flutter `3.50.1` (`stable`) / Dart `3.14.0` / `drift: ^2.35.3` (`2.35.4`) / `drift_flutter: ^0.3.1` / `sqlite3: ^3.9.1` (`3.9.2`)  
**Milestone Scope:** Complete offline-first Drift + SQLite database core (all 13 documented tables, 20 indexes/unique constraints, 7 thin persistence-only DAOs, WAL + `synchronous = FULL` PRAGMA verification, atomic transaction runner, migration framework, cross-platform connection layer, private media storage foundation, and 12 comprehensive database/media tests). Zero business screens or business workflows implemented.

---

## 1. Final Schema & Table Count (13 Tables)

All 13 tables from `docs/07_database_schema.md` and `docs/24_FINAL_TECHNICAL_SAFEGUARDS.md` were implemented with exact columns, `ON DELETE RESTRICT` foreign keys, SQL `CHECK` constraints (`customConstraints`), UUIDv7 `TEXT` primary keys, UTC epoch ms timestamps, and integer paise monetary columns:

1. `business_profile` (singleton `'default'`, seeded automatically in `onCreate` with `Business Manager` / `બિઝનેસ મેનેજર` and `default_billing_mode = 'RECEIVED_QTY'`)
2. `lots`
3. `lot_designs`
4. `design_colours`
5. `processes`
6. `members` (including `address`, `created_by`, `updated_by`)
7. `member_processes`
8. `member_process_rates` (`CHECK(effective_to IS NULL OR effective_to >= effective_from)`)
9. `stock_movements` (all 26 columns including `client_request_id`, `locked_billing_mode`, `locked_include_damaged`, `is_rate_overridden`, `override_reason`, `reason`, `parent_issue_id`, `reverses_movement_id`)
10. `labour_entries` (including `reverses_labour_entry_id`)
11. `payments` (including `reverses_payment_id`, `client_request_id`, `reason`)
12. `attachments` (portable POSIX relative paths + SHA-256 checksum)
13. `audit_logs`

---

## 2. Files Created & Modified

### Created Files
- **Tables (`lib/core/database/tables/`):** `business_profile_table.dart`, `lot_tables.dart`, `process_member_tables.dart`, `ledger_tables.dart`, `attachment_audit_tables.dart`.
- **Migrations & Indexes (`lib/core/database/migrations/`):** `schema_indexes.dart` (20 SQLite index/unique constraint statements), `database_migration_manager.dart`.
- **Cross-Platform Connections (`lib/core/database/connection/`):** `database_connection.dart`, `database_connection_native.dart`, `database_connection_web.dart`, `database_connection_unsupported.dart`.
- **DAOs (`lib/core/database/daos/`):** `business_profile_dao.dart`, `lot_dao.dart`, `process_member_dao.dart`, `stock_movement_dao.dart` (append-only), `labour_entry_dao.dart` (append-only), `payment_dao.dart` (append-only), `attachment_audit_dao.dart` (audit append-only) + generated `*.g.dart`.
- **Database Core (`lib/core/database/`):** `app_database.dart` (+ generated `app_database.g.dart`), `database_pragma_status.dart`, `database_initializer.dart`, `database_transaction_runner.dart`.
- **Private Media Storage (`lib/core/platform/`):** `media_storage_service.dart`, `media_storage_service_native.dart`, `media_storage_service_web.dart`, `media_storage_factory.dart`.
- **Tests:** `test/database/app_database_integrity_test.dart`, `test/database/app_database_persistence_migration_test.dart`, `test/unit/media_storage_service_test.dart`.

### Modified Files
- `lib/core/di/register_module.dart` & regenerated `lib/core/di/injection.config.dart` — Registered `AppDatabase` (`dispose: disposeAppDatabase`), `DatabaseInitializer`, `DatabaseTransactionRunner`, and `MediaStorageService`.
- `lib/bootstrap.dart` — Invokes `getIt<DatabaseInitializer>().initialize()` cleanly on app startup.
- `CHANGELOG.md`, `README.md`.

---

## 3. Effective SQLite PRAGMA Verification

Configured in `AppDatabase.migration.beforeOpen` and verified directly via `AppDatabase.verifyPragmas()`:
- `PRAGMA foreign_keys = ON;` → Verified `1` (`true`) on both in-memory and file-backed SQLite.
- `PRAGMA journal_mode = WAL;` → Verified `'wal'` on file-backed SQLite (`'memory'` on in-memory test DBs).
- `PRAGMA synchronous = FULL;` → Verified `2` (`FULL`, `ADR-012` strict ACID durability).
- `PRAGMA busy_timeout = 5000;` → Verified `5000` ms.

---

## 4. Indexes, Constraints & Append-Only Safeguards (20 Indexes)

- **Active Uniqueness (Partial Unique Indexes):** `idx_lots_number_active`, `idx_lot_designs_unique`, `idx_design_colours_unique`, `idx_processes_name_active`, `idx_member_processes_pair`.
- **Reversal Uniqueness (Single-Reversal Guards):** `idx_sm_single_reversal`, `idx_labour_single_reversal`, `idx_payments_single_reversal`.
- **Labour Idempotency:** `idx_labour_movement_basis_unique` on `labour_entries(stock_movement_id, basis_type)`.
- **Duplicate Submission Idempotency:** `idx_sm_client_request_id`, `idx_payments_client_request_id`.
- **Append-Only DAOs:** `StockMovementDao`, `LabourEntryDao`, `PaymentDao`, and `AuditLogs` expose **only `INSERT` and `SELECT`** methods—zero `UPDATE` or `DELETE` methods exist.

---

## 5. Atomic Transaction & Migration Strategy

- **Atomic Transactions (`DatabaseTransactionRunner`):** Injectable wrapper around `AppDatabase.transaction<T>(...)` so read → domain validation → multi-table write → audit log either all commit or all roll back together (verified via commit + mid-transaction failure rollback tests).
- **Migration Strategy (`DatabaseMigrationManager`):**
  - `schemaVersion = 1` (`DatabaseMigrationManager.currentSchemaVersion`).
  - Future schema changes must: (1) increment `currentSchemaVersion`, (2) add explicit `if (from < N)` DDL/data migration steps inside `handleOnUpgrade`, (3) re-apply idempotent indexes, and (4) add an automated upgrade test verifying zero data loss from `v(N-1)` to `vN`.

---

## 6. Platform Compatibility & Web Deployment Notes

| Platform | Connection Strategy | Media Storage | Validation Status |
| :--- | :--- | :--- | :--- |
| **Android (Primary)** | `NativeDatabase.createInBackground` in `<appDocsDir>/db/<flavor>.sqlite` (`sqlite3 ^3.9.2` build hooks) | Private `<appDocsDir>/<media_flavor>/` | **Verified** (`dev` APK built + native SQLite tests passing) |
| **Windows / macOS / Linux / iOS** | Same `database_connection_native.dart` private app storage | Same `NativeMediaStorageService` | Windows native SQLite verified in tests; iOS/macOS/Linux require respective host OS toolchains |
| **Web** | `drift_flutter` (`driftDatabase` → `sqlite3.wasm` + `drift_worker.js`, OPFS → IndexedDB fallback) | Stub (`WebMediaStorageService`); OPFS/IndexedDB blob store scheduled for Milestone 7/8 | Static `web/sqlite3.wasm` & `web/drift_worker.js` + optional COOP/COEP headers required for Web deployment in Milestone 8 |

---

## 7. Commands Executed & Validation Results

| Command | Result |
| :--- | :--- |
| `dart run build_runner build` | **PASS** (`0` warnings; generated all Drift table/DAO/DB & DI files) |
| `flutter analyze` | **PASS** (`No issues found!`) |
| `flutter test` | **PASS** (`30 / 30` tests passed — 12 new DB/rollback/persistence/migration/media tests + 18 Milestone 1 & 2 tests) |
| `flutter build apk --debug --flavor dev -t lib/main_dev.dart --dart-define-from-file=config/dev.json` | **PASS** (`build\app\outputs\flutter-apk\app-dev-debug.apk`) |

---

## 8. Known Limitations & Pending Approval

- **Web Assets Deferred to Milestone 8:** `web/sqlite3.wasm` and `web/drift_worker.js` + Web OPFS/IndexedDB media blob storage are scheduled for Milestone 7/8 multi-platform polish.
- **Pending Approval:** Confirm Milestone 3 database core & private media foundation before proceeding to **Milestone 4 (Master Data Modules — Dynamic Processes, Members, Historical Rates, Lots/Designs/Colours/Photos)**.
