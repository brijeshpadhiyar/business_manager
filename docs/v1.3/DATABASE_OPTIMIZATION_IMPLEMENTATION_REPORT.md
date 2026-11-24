# StitchFlow V1.3 — Database Optimization Implementation Report (Schema v7)

**Date:** 2026-11-24  
**Scope:** Phase 2–4 — Schema v7 Additive Indexes, Query Optimizations (DB-01 through DB-05), Migration Integrity Matrix & Benchmarks  
**Status:** Implemented & Verified

---

## 1. Durability & Safety Guarantees Preserved

All SQLite durability and integrity settings in [`AppDatabase`](file:///c:/A1/business_manager/lib/core/database/app_database.dart) remain strictly unchanged:
- `PRAGMA journal_mode = WAL`
- `PRAGMA synchronous = FULL`
- `PRAGMA foreign_keys = ON`
- `PRAGMA busy_timeout = 5000`
- **19 tables** preserved with zero destructive schema changes.
- **Additive-only migration** from Schema v6 to Schema v7 (`CREATE INDEX IF NOT EXISTS`).

---

## 2. Optimizations Implemented (DB-01..DB-05)

| ID | Issue Identified in Audit | Implementation | Files Modified |
| :--- | :--- | :--- | :--- |
| **DB-01** | N+1 query in `LotRepositoryImpl.getLotDetail()`: looped through every `LotDesign` and executed one `getColoursForDesign(designId)` query per design. | Added chunked batch query `LotDao.getColoursForDesigns(List<String> designIds)` (chunk size `500` to stay safely under SQLite's 999 bind-parameter limit) and grouped colours by `lotDesignId` in memory. | [`lot_dao.dart`](file:///c:/A1/business_manager/lib/core/database/daos/lot_dao.dart), [`lot_repository_impl.dart`](file:///c:/A1/business_manager/lib/features/lots/data/repositories/lot_repository_impl.dart) |
| **DB-02** | `getMovementsForLot(lotId)` sorted `stock_movements` by `(transaction_at ASC, recorded_at ASC)` using `USE TEMP B-TREE FOR ORDER BY`. | Added composite index `idx_sm_lot_tx ON stock_movements(lot_id, transaction_at ASC, recorded_at ASC)`. | [`schema_indexes.dart`](file:///c:/A1/business_manager/lib/core/database/migrations/schema_indexes.dart) |
| **DB-03** | `hasMovementsUsingRate(rateId)` performed a full table scan on `stock_movements` due to missing index on `source_rate_id`. | Added partial index `idx_sm_source_rate ON stock_movements(source_rate_id) WHERE source_rate_id IS NOT NULL`. | [`schema_indexes.dart`](file:///c:/A1/business_manager/lib/core/database/migrations/schema_indexes.dart) |
| **DB-04** | `getActiveLots()` filtered `deleted_at IS NULL` and ordered by `transaction_at DESC` without a covering partial index. | Added partial index `idx_lots_active_tx ON lots(transaction_at DESC) WHERE deleted_at IS NULL`. | [`schema_indexes.dart`](file:///c:/A1/business_manager/lib/core/database/migrations/schema_indexes.dart) |
| **DB-05** | `JobProcessDao.getNextSequenceOrderForLot(lotId)` loaded all `job_processes` rows for the lot into Dart just to compute `max + 1`. | Replaced with single-row SQL aggregate: `SELECT COALESCE(MAX(sequence_order), 0) + 1 AS next_seq FROM job_processes WHERE lot_id = ? AND deleted_at IS NULL`. | [`job_process_dao.dart`](file:///c:/A1/business_manager/lib/core/database/daos/job_process_dao.dart) |
| **Schema v7** | Schema version remained at `6`. | Bumped `DatabaseMigrationManager.currentSchemaVersion` from `6` to `7`; `handleOnUpgrade` applies `SchemaIndexes.allIndexStatements` (now **38 indexes** total, including `v7IndexStatements`). | [`database_migration_manager.dart`](file:///c:/A1/business_manager/lib/core/database/migrations/database_migration_manager.dart), [`schema_indexes.dart`](file:///c:/A1/business_manager/lib/core/database/migrations/schema_indexes.dart) |

---

## 3. Migration & Integrity Verification Matrix

Verified in [`test/database/schema_v7_migration_and_perf_test.dart`](file:///c:/A1/business_manager/test/database/schema_v7_migration_and_perf_test.dart) against real file-backed SQLite databases with populated records:

| Migration Path | Tables Verified | v7 Indexes Present | `PRAGMA integrity_check` | `PRAGMA foreign_key_check` | Seeded Data Preserved | Status |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| Fresh Schema v7 | 19 | All 3 (`idx_sm_lot_tx`, `idx_sm_source_rate`, `idx_lots_active_tx`) | `ok` | 0 violations | N/A | **PASSED** |
| `v1 -> v7` | 19 | All 3 | `ok` | 0 violations | Yes | **PASSED** |
| `v2 -> v7` | 19 | All 3 | `ok` | 0 violations | Yes | **PASSED** |
| `v3 -> v7` | 19 | All 3 | `ok` | 0 violations | Yes | **PASSED** |
| `v4 -> v7` | 19 | All 3 | `ok` | 0 violations | Yes | **PASSED** |
| `v5 -> v7` | 19 | All 3 | `ok` | 0 violations | Yes | **PASSED** |
| `v6 -> v7` | 19 | All 3 | `ok` | 0 violations | Yes | **PASSED** |

---

## 4. `EXPLAIN QUERY PLAN` Index Verification

All four target queries were verified via `EXPLAIN QUERY PLAN` in automated tests:

1. **`getMovementsForLot`**: Uses `idx_sm_lot_tx` — no `USE TEMP B-TREE FOR ORDER BY`.
2. **`hasMovementsUsingRate`**: Uses partial index `idx_sm_source_rate` — no full table scan (`SCAN stock_movements`).
3. **`getActiveLots`**: Uses partial index `idx_lots_active_tx` — no `USE TEMP B-TREE FOR ORDER BY`.
4. **`getNextSequenceOrderForLot`**: Uses `idx_jp_lot_seq` with SQL `MAX(sequence_order)` aggregate.

---

## 5. Measured Performance Benchmarks

Measured directly during `flutter test -r expanded test/database/schema_v7_migration_and_perf_test.dart` on file-backed SQLite:

| Operation & Dataset Size | Measured Latency | Optimization Applied |
| :--- | :---: | :--- |
| `LotRepositoryImpl.getLotDetail()` (25 designs, 100 colours) | **10.96 ms** (`10,958 µs`) | DB-01 chunked batch `IN` query (1 query instead of 25) |
| `StockMovementDao.getMovementsForLot()` (1,000 movements) | **3.87 ms** (`3,872 µs`) | DB-02 `idx_sm_lot_tx` (zero temp B-tree sort) |
| `StockMovementDao.hasMovementsUsingRate()` (1,000 movements) | **1.17 ms** (`1,166 µs`) | DB-03 partial index `idx_sm_source_rate` |
| `LotDao.getActiveLots()` (100 active lots) | **3.22 ms** (`3,219 µs`) | DB-04 partial index `idx_lots_active_tx` |
| `JobProcessDao.getNextSequenceOrderForLot()` (100 processes) | **3.81 ms** (`3,812 µs`) | DB-05 SQL `COALESCE(MAX(sequence_order), 0) + 1` |
