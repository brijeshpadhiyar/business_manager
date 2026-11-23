# 06 — Database & Migration Plan (Schema v2 -> v3)

**Current Verified Schema:** Version `2` (`14` tables, `8` DAOs, `24` indexes: 21 v1 + 3 v2).  
**Proposed V1.2 Schema:** Version `3` — **Strictly Additive, Index-Only Migration** (zero tables added/removed, zero columns altered, zero existing user data modified or reset).

---

## 1. Storage Placement Decision Matrix (Why Zero New SQLite Tables Are Needed)

Before introducing any schema change, every V1.2 requirement was evaluated against StitchFlow's offline-first, backup-safe, and security boundaries:

| V1.2 Capability | Data Stored | Chosen Storage | Why NOT a SQLite Table? |
| :--- | :--- | :--- | :--- |
| **Phase A: Local Security** | PIN verifier (`pbkdf2_hmac_sha256$v1$...`), Recovery Key verifier, biometric flag, timeout, lockout attempts/timestamps | **`flutter_secure_storage` (Android Keystore RSA-OAEP + AES-GCM)** | SQLite is exported in unencrypted `.zip` backups & raw `.sqlite` inspection exports. Putting PIN hashes in SQLite would expose verifiers in backups and cause restoring an old backup to overwrite the active PIN. |
| **Phase A: Security Audit** | PIN enabled/changed/disabled/recovered events | **Existing `audit_logs` table** (`entity_type = 'app_security'`, `action_type = 'UPDATE'`) | Satisfies existing `CHECK(action_type IN (...))` constraint with zero DDL changes; never logs plaintext PINs or hashes. |
| **Phase B: Recent Suggestions** | Recent `(Process, Worker)` pairs & recent Stock colours | **Derived live from existing `stock_movements`** (last 20 active `ISSUE` rows) | 100% accurate, automatically reflects restored backups, zero redundant persistence! |
| **Phase B: UI Preferences** | Pending Returns default sort order | **Flavor-scoped `SharedPreferences`** | Ephemeral UI preference, same pattern as `ThemeCubit` and `LocaleCubit`. |
| **Phase C: Advanced Reports & Insights** | Daily Workshop, Worker/Process Performance, Turnaround Time, Inventory, Financial, Trends, Period Comparisons | **Derived live from existing 14 tables** via pure Dart `ReportsAnalyticsCalculator` | Zero denormalized/stale cache tables; 100% single source of truth matching `StockCalculator` & `LedgerCalculator`. |
| **Phase D: Local Notifications** | Category toggles, reminder times, thresholds, dedupe plan hash | **Flavor-scoped `SharedPreferences`** | Bound to device-local Android `AlarmManager` & OS notification permissions; should not leak across devices via `.zip` backups. Last backup timestamp is read directly from existing `audit_logs`. |

---

## 2. Why Schema v2 -> v3 (Index-Only) IS Justified

Inspecting `lib/core/database/migrations/schema_indexes.dart` revealed that all existing ledger indexes are keyed by entity (`member_id`, `process_id`, `design_colour_id`), with **no standalone date-range indexes on `transaction_at`** and **no index on `audit_logs(action_type, recorded_at)`**.

Phase B (Today's Dashboard & Daily Summary), Phase C (Today / Yesterday / Week / Month / Custom / Period-over-Period Reports & Insights), and Phase D (Backup Reminder checking latest `BACKUP_EXPORT` in `audit_logs`) all execute date-range scans. Without date indexes, SQLite performs full table scans as workshop history grows to 10,000–50,000+ rows.

### 2.1 Exact Additive DDL for Schema v3 (`SchemaIndexes.v3IndexStatements`)

```sql
-- 1. Date-range & movement-type queries for Daily Report, Today Dashboard, Trends & Insights
CREATE INDEX IF NOT EXISTS idx_sm_tx_type
  ON stock_movements(transaction_at DESC, movement_type);

-- 2. Date-range payable labour queries for Daily Summary, Labour Report & Cost Trends
CREATE INDEX IF NOT EXISTS idx_labour_tx_payable
  ON labour_entries(transaction_at DESC, is_payable);

-- 3. Date-range payment history & Today's Payments queries
CREATE INDEX IF NOT EXISTS idx_payments_tx
  ON payments(transaction_at DESC, payment_type);

-- 4. Date-range worker adjustment queries
CREATE INDEX IF NOT EXISTS idx_wla_tx
  ON worker_ledger_adjustments(transaction_at DESC);

-- 5. Fast lookup of latest BACKUP_EXPORT / BACKUP_RESTORE for Backup Reminder notification
CREATE INDEX IF NOT EXISTS idx_audit_action_rec
  ON audit_logs(action_type, recorded_at DESC);
```

### 2.2 Tables & Columns Added / Modified
- **Tables added:** None (`0`).
- **Columns added/modified/dropped:** None (`0`).
- **Existing constraints modified:** None (`0`).
- **Indexes added:** `5` idempotent `CREATE INDEX IF NOT EXISTS` statements (`24 -> 29` total indexes).

### 2.3 Alternative Considered: "Stay on Schema v2"
- *Pros:* V1.2 `.zip` backups could still be restored into older V1.1 APKs.
- *Cons:* No clean Drift `onUpgrade` hook to create the 5 performance indexes on upgraded devices; date-range report queries remain full table scans on large datasets.
- *Decision:* **Upgrade to `schemaVersion = 3` (index-only)** because forward compatibility from V1.0 (`v1`) and V1.1 (`v2`) -> V1.2 (`v3`) is 100% seamless, zero user data is touched, and query performance scales cleanly for multi-year workshop ledgers. *(Note: Owner can veto and keep v2 if downgrading a backup back to V1.1 is required — documented in Executive Plan Section 6.)*

---

## 3. Migration Sequence (`DatabaseMigrationManager`)

In `lib/core/database/migrations/database_migration_manager.dart`:
1. Update `static const int currentSchemaVersion = 3;`.
2. Update `SchemaIndexes.allIndexStatements` to include `...v3IndexStatements`.
3. `handleOnCreate(m, db)`: Creates all 14 tables + runs all 29 idempotent indexes + seeds default `business_profile`.
4. `handleOnUpgrade(m, db, from, to)`:
   - `if (from < 2)` -> runs existing `CREATE TABLE IF NOT EXISTS worker_ledger_adjustments (...)`.
   - `if (from < 3)` -> no table DDL needed; falls through to the existing loop executing all `SchemaIndexes.allIndexStatements` (which idempotently creates all 5 v3 indexes via `CREATE INDEX IF NOT EXISTS`!).
5. `beforeOpen` continues to enforce and verify:
   - `PRAGMA foreign_keys = ON;`
   - `PRAGMA journal_mode = WAL;`
   - `PRAGMA synchronous = FULL;`
   - `PRAGMA busy_timeout = 5000;`

### Optional Read-Only DAO Query Additions (Zero Table Changes)
Add bounded read-only helper queries in existing DAOs for Phase B/C/D:
- `StockMovementDao.getMovementsInRange(int fromUtcMillis, int toUtcMillis)`
- `StockMovementDao.getRecentIssues({int limit = 20})`
- `LabourEntryDao.getEntriesInRange(int fromUtcMillis, int toUtcMillis)`
- `PaymentDao.getPaymentsInRange(int fromUtcMillis, int toUtcMillis)`
- `WorkerAdjustmentDao.getAdjustmentsInRange(int fromUtcMillis, int toUtcMillis)`
- `AttachmentAuditDao.getLatestAuditByAction(String actionType)` (for Backup Reminder!)

All 4 ledger DAOs remain **strictly append-only** (`INSERT` and `SELECT` only — never `UPDATE` or `DELETE`).

---

## 4. Existing-Data Preservation & Rollback / Recovery Strategy

### 4.1 Data Preservation Guarantees
- `CREATE INDEX IF NOT EXISTS` never mutates table rows, primary keys, foreign keys, timestamps, or audit history.
- Drift runs `onUpgrade` inside a SQLite transaction: if an unexpected I/O error occurs (e.g., disk full during index build), SQLite rolls back the transaction cleanly and `PRAGMA user_version` remains `2` with all v2 data untouched.
- Flavor isolation remains strictly enforced (`business_manager_dev.sqlite` vs `business_manager_prod.sqlite`).

### 4.2 Rollback & Recovery Strategy
- **Upgrade Failure:** Because `v2 -> v3` only creates indexes inside Drift's migration transaction, rolling back leaves a 100% intact `v2` database.
- **Restore Failure:** `NativeBackupRestoreService.restoreFromZip()` already creates an automatic pre-restore safety snapshot (`VACUUM INTO`) + media copy in a temp rollback directory, validates `PRAGMA integrity_check` and `foreign_keys = ON` after swap, and automatically rolls back both DB and media if any verification step fails.
- **Recommended User Safety Step Before Installing V1.2 Over V1.1:** Create one V1.1 `.zip` backup via `Settings -> Backup & Data Safety` prior to sideloading V1.2 (also verifiable on `dev` flavor side-by-side first).

---

## 5. Backup & Restore Compatibility Matrix

| Source Backup Schema | Target App Schema | Result | Mechanism |
| :---: | :---: | :--- | :--- |
| **V1.0 (`v1`)** | **V1.2 (`v3`)** | **Supported & Verified** | `NativeBackupRestoreService` accepts `manifest.schemaVersion (1) <= 3`; opening `verifyDb` triggers Drift `onUpgrade(1 -> 3)` creating `worker_ledger_adjustments` + all 29 indexes, verifies `integrity_check = ok`, writes `BACKUP_RESTORE` audit log. |
| **V1.1 (`v2`)** | **V1.2 (`v3`)** | **Supported & Verified** | Accepts `2 <= 3`; opening `verifyDb` triggers `onUpgrade(2 -> 3)` adding the 5 v3 indexes; 100% of v2 data preserved. |
| **V1.2 (`v3`)** | **V1.2 (`v3`)** | **Supported & Verified** | Direct restore + integrity check. |
| **V1.2 (`v3`)** | **V1.1 (`v2`)** | **Cleanly Blocked** | Existing guard `manifest.schemaVersion > currentSchemaVersion` returns `schema_too_new` with clear prompt to update StitchFlow. |
| **`dev` backup** | **`prod` app** | **Cleanly Blocked** | Existing `cross_flavor_blocked` guard preserved intact. |

### Required Maintenance Fix in `NativeBackupRestoreService`
- Fix line 34 (`static const String appVersionString = '1.0.0+1';`) to reference `'${AppIdentity.appVersion}+${AppIdentity.appBuildNumber}'` (`'1.2.0+3'`) so `manifest.json` accurately records the creating app version!
- Keep `BackupManifest.currentFormatVersion = 1` unchanged so archive format stays 100% backward compatible.
- Confirm PIN/biometric credentials in `flutter_secure_storage` are **never** included in `.zip` exports and **never** erased or overwritten by a backup restore.
