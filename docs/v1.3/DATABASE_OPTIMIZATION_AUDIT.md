# StitchFlow V1.3 – Database & Drift/SQLite Optimization Audit (Phase 3)

**Date:** 2026-11-24  
**Workspace:** `c:\A1\business_manager`  
**Verified Current Schema:** **v6** (19 tables, 35 indexes, WAL mode, `foreign_keys = ON`, `synchronous = FULL`, `busy_timeout = 5000ms`)

---

## 1. Schema & Configuration Verification

| Check | Status | Evidence |
|---|---|---|
| Schema Version | **v6** | `DatabaseMigrationManager.currentSchemaVersion = 6` |
| Table Count | **19 tables** | Verified in `app_database_integrity_test.dart` (`lots`, `lot_designs`, `design_colours`, `colour_master`, `processes`, `members`, `member_processes`, `member_process_rates`, `stock_movements`, `job_processes`, `process_handovers`, `process_additional_charges`, `process_rate_history`, `labour_entries`, `payments`, `worker_ledger_adjustments`, `business_profile`, `attachments`, `audit_logs`) |
| Foreign Keys | **ENFORCED (`ON`)** | `DatabaseInitializer.initialize()` fails fast if `PRAGMA foreign_keys` is not `1` |
| Durability | **WAL + `synchronous = FULL`** | Preserved; must NOT be weakened |
| Atomic Transactions | **Verified** | `DatabaseTransactionRunner.runInTransaction` + rollback tests passing |
| Monetary Precision | **100% Integer Paise** | All amounts, rates, charges, deductions, payments stored as `INTEGER` paise |
| Idempotency & Reversals | **Enforced at SQLite level** | Partial unique indexes on `client_request_id`, `reverses_*_id`, and `(stock_movement_id, basis_type)` |

---

## 2. Query & N+1 Audit Findings

| ID | Severity | Location | Issue | Evidence & Optimization |
|---|---|---|---|---|
| **DB-01** | **P1 – High** | `lib/features/lots/data/repositories/lot_repository_impl.dart:62-72` | **N+1 Query Pattern** in `getLotDetail(lotId)` | Loops `for (final d in designRows) { await _db.lotDao.getColoursForDesign(d.id); }`. For 20 designs = 21 queries. **Fix**: Add `getColoursForDesigns(List<String> designIds)` (`lot_design_id IN (...)`) -> constant **2 queries**. |
| **DB-02** | **P1 – High** | `lib/core/database/daos/stock_movement_dao.dart:52-61` | **Missing Index on `stock_movements(lot_id, transaction_at)`** | `getMovementsForLot(lotId)` (called by `getJobRoutingOverview`) filters `WHERE lot_id = ? ORDER BY transaction_at ASC`. Currently performs a **FULL TABLE SCAN** of `stock_movements`. **Fix**: Add `idx_sm_lot_tx ON stock_movements(lot_id, transaction_at ASC, recorded_at ASC)`. |
| **DB-03** | **P2 – Medium** | `lib/core/database/daos/stock_movement_dao.dart:96-103` | **Missing Partial Index on `stock_movements(source_rate_id)`** | `hasMovementsUsingRate(rateId)` scans all `stock_movements` rows to check if a rate is locked by history. **Fix**: Add `idx_sm_source_rate ON stock_movements(source_rate_id) WHERE source_rate_id IS NOT NULL`. |
| **DB-04** | **P2 – Medium** | `lib/core/database/daos/lot_dao.dart:17-21` | **Missing Index on `lots(transaction_at DESC)`** | `getActiveLots()` filters `WHERE deleted_at IS NULL ORDER BY transaction_at DESC`. Only `lot_number` is indexed. **Fix**: Add `idx_lots_active_tx ON lots(transaction_at DESC) WHERE deleted_at IS NULL`. |
| **DB-05** | **P2 – Medium** | `lib/core/database/daos/job_process_dao.dart:57-65` | **Over-fetching rows for `MAX(sequence_order)`** | `getNextSequenceOrderForLot` fetches every `job_processes` row into Dart memory just to compute `max + 1`. **Fix**: Single SQL aggregate `SELECT COALESCE(MAX(sequence_order), 0) + 1`. |

---

## 3. Migration & Integrity Verification Gaps

- Existing migration tests verify `v1 -> current`, `v2 -> current`, and `v4 -> current` (`app_database_persistence_migration_test.dart`, `multi_process_routing_workflow_test.dart`, `lot_variants_dynamic_pricing_test.dart`).
- **Gap (DB-06, P1 – High)**: We should add a dedicated **complete migration matrix test** verifying:
  - Fresh creation (v6/v7)
  - `v1 -> current`, `v2 -> current`, `v3 -> current`, `v4 -> current`, `v5 -> current`, and `v6 -> current` on populated file-backed databases
  - `PRAGMA integrity_check` == `'ok'` and `PRAGMA foreign_key_check` == empty after every migration
  - `EXPLAIN QUERY PLAN` assertions verifying index usage on `getMovementsForLot`, `hasMovementsUsingRate`, `getActiveLots`, and `getJobProcessesForLot`!

---

## 4. Backup & Restore Audit Summary

- `NativeBackupRestoreService` (`lib/features/backup/data/services/native_backup_restore_service.dart`) creates WAL-consistent snapshots via `PRAGMA wal_checkpoint(TRUNCATE)` + `VACUUM INTO`, runs read-only `PRAGMA integrity_check`, hashes with SHA-256, and validates archive manifest before replacing the live DB.
- No destructive or partial-replacement defects found in the backup/restore pipeline.
