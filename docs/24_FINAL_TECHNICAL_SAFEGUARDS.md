# 24 — Final Technical Safeguards & Architecture Validation

**Review Date:** 2026-11-23  
**Reviewers:** Principal Flutter Architect & Database Architect  
**Status:** All 5 high-risk technical safeguards validated and integrated into the project blueprint prior to Milestone 1.

---

## 1. Stock Reversal Dependency Protection

### Problem Identified
Reversing a historical stock movement that supplied stock to subsequent movements (e.g., `100` initial → `100` issued to Cutting → `80` returned from Cutting → `80` issued to Stitching → user attempts to reverse the Cutting return of `80`) would leave physical inventory in an impossible negative state (`-80`), or retroactively invalidate a downstream `ISSUE` even if a later return brought current stock back above zero. The same risk applies to reversing an `ADJUSTMENT_DAMAGED_TO_GOOD` whose repaired pieces were already issued, or reversing a `RETURN_DAMAGED` whose damaged pieces were already repaired into good stock.

### Technical Decision & Validation Rules
Every `REVERSAL` of a `stock_movements` row executes inside an **atomic SQLite transaction** running a two-stage simulation in `StockCalculator.validateReversal(designColourMovements, targetMovementId)`:
1. **Direct Child Guard:** If `target.movement_type == 'ISSUE'`, verify zero active child settlements (`parent_issue_id == target.id`) exist.
2. **Post-Reversal Aggregate & Chronological Prefix Replay:**
   - Remove `target` from the active movement list for `target.design_colour_id`.
   - Replay all remaining active movements in chronological order (`transaction_at ASC, recorded_at ASC, id ASC`).
   - Verify that **at every step in the timeline** AND at the final state:
     - `PhysicalAvailableInHouse >= 0`
     - `DamagedBucket >= 0`
     - `ParentRemainingPending(issue) >= 0` for all active issues
   - If any step dips below `0`, **reject the reversal** with `DownstreamStockDependencyFailure`, identifying the exact blocking downstream movement(s) (type, process, member, date, quantity) so the user knows which downstream transaction(s) must be reversed first.
3. **Never Silently Modify Downstream Rows:** Subsequent transactions are never auto-adjusted or cascade-deleted. Users either reverse downstream transactions in reverse dependency order or record an explicit compensating adjustment.

---

## 2. Labour Entry Idempotency & Duplicate Submission Protection

### Problem Identified
Without strict database-level uniqueness and request idempotency, a double-tap on Save, a retried BLoC event, or a bug in settlement orchestration could generate duplicate `labour_entries` for the same stock movement or duplicate reversal entries—corrupting worker payables.

### Technical Decision & Database Changes
1. **Unique Composite Index on `labour_entries`:**
   ```sql
   CREATE UNIQUE INDEX idx_labour_movement_basis_unique
   ON labour_entries(stock_movement_id, basis_type);
   ```
   Guarantees at most one `ISSUED`, `RECEIVED_GOOD`, `RECEIVED_DAMAGED`, or `REVERSAL` labour entry per `stock_movement_id`.
2. **Unique Single-Reversal Partial Index on `labour_entries`:**
   ```sql
   CREATE UNIQUE INDEX idx_labour_single_reversal
   ON labour_entries(reverses_labour_entry_id)
   WHERE reverses_labour_entry_id IS NOT NULL;
   ```
3. **Client Request Idempotency Token (`client_request_id`):**
   - Added nullable `client_request_id TEXT` to `stock_movements` and `payments` with unique partial indexes:
     - `CREATE UNIQUE INDEX idx_sm_client_request_id ON stock_movements(client_request_id) WHERE client_request_id IS NOT NULL;`
     - `CREATE UNIQUE INDEX idx_payments_client_request_id ON payments(client_request_id) WHERE client_request_id IS NOT NULL;`
   - Each form submission generates a UUIDv4 `client_request_id`. If retried (e.g., rapid double-tap or BLoC retry), the repository checks for an existing row with that `client_request_id` inside the transaction and returns the existing result idempotently.
4. **Transactional Coupling & UI Guard:**
   - `stock_movements` + `labour_entries` + `audit_logs` are always inserted in a single Drift `transaction(() async { ... })`.
   - Primary submit buttons disable immediately (`isLoading: true`) and BLoCs ignore duplicate in-flight submit events.

---

## 3. SQLite WAL Backup Consistency & Safe Restore

### Problem Identified
In `WAL` mode, live writes reside in `business_manager_<flavor>.sqlite-wal` until checkpointed. Naively copying the main `.sqlite` file produces an incomplete or corrupted export.

### Technical Decision & Platform Snapshot Strategy
- **Native Platforms (Android, iOS, Windows, macOS, Linux):**
  1. Run `PRAGMA wal_checkpoint(TRUNCATE);` to flush WAL frames where unblocked.
  2. Execute SQLite **`VACUUM INTO '<temp_export_path>'`** (supported in SQLite 3.27+ / `sqlite3 ^3.9.1`). This produces a 100% consistent, compacted, self-contained single `.sqlite` snapshot with **zero `-wal`/`-shm` sidecars**, safely while the active DB connection remains open.
  3. Validate the snapshot via `PRAGMA integrity_check;` and compute SHA-256.
  4. For Full Backup (`.zip`), bundle `database.sqlite` + all active `media_<flavor>/` files + `manifest.json` (format version, app version, flavor, schema version, UTC/IST timestamps, DB & per-file SHA-256 checksums).
- **Web Platform (`sqlite3.wasm`):**
  - `VACUUM INTO '<filesystem_path>'` is unavailable for host OS paths in browser WASM.
  - Export consistent raw `.sqlite` bytes via Drift Web Worker checkpoint + OPFS file read / `sqlite3_serialize` → browser download; bundle with OPFS/IndexedDB media blobs for `.zip` download.
  - *Limitation:* Large Web media backups are constrained by browser RAM; native Android/Desktop is recommended for large photo archives.
- **Safe Atomic Restore & Production Protection:**
  - Verify `manifest.json`, `schema_version <= currentAppSchemaVersion`, DB & attachment SHA-256 checksums, and `PRAGMA integrity_check;` on staged files before touching live data.
  - **Explicit Production Confirmation:** Restoring into `prod` requires an explicit two-step confirmation dialog displaying backup date (`Asia/Kolkata`), flavor, and summary counts. Restoring a `dev` backup into `prod` is **blocked** in `prod` to prevent test data from polluting production.
  - Automatically capture a pre-restore safety snapshot, close DB, remove stale `-wal`/`-shm`, swap DB + media, reopen DB (running Drift migrations if needed), and roll back automatically on any error.

---

## 4. Atomic Worker-Process Validation Before Stock Issue

### Problem Identified
Validating member/process status, member-process linkage, historical rate, and physical stock outside the write transaction risks stale reads or allowing issues to deactivated/unlinked workers.

### Technical Decision
All 5 pre-issue checks execute inside the **same atomic Drift transaction** as the `ISSUE` insert:
1. **Member Active:** `members.id = :memberId AND deleted_at IS NULL AND is_active = 1`.
2. **Process Active:** `processes.id = :processId AND deleted_at IS NULL AND is_active = 1`.
3. **Member-Process Linked:** `member_processes(member_id, process_id)` exists with `is_active = 1`.
4. **Historical Rate Resolved:** Effective rate exists in `member_process_rates` for `(member_id, process_id, toAsiaKolkataDate(transactionAt))` (unless user confirmed an explicit audited manual override).
5. **Physical Stock Available:** `issue_qty > 0 AND issue_qty <= PhysicalAvailableInHouse` (recomputed inside the transaction).

**Historical Accessibility Guarantee:** Deactivating a member, process, or `member_processes` link later never breaks historical `stock_movements`, pending partial returns on already-open issues, `labour_entries`, `payments`, ledgers, or reports.

---

## 5. SQLite Durability Review (`synchronous = FULL` vs `NORMAL`)

### Evaluation
| Setting (with `journal_mode = WAL`) | Crash Corruption Safety | Committed Transaction Durability on Sudden Power Loss / Battery Pull | Single-User Write Latency (Android Flash) |
| :--- | :--- | :--- | :--- |
| `PRAGMA synchronous = NORMAL;` | Safe (DB won't corrupt) | **Risk:** Uncheckpointed transactions in `-wal` can be lost on OS crash / battery pull | ~1–2 ms |
| **`PRAGMA synchronous = FULL;` (Recommended)** | Safe (DB won't corrupt) | **Strict ACID Durability:** Every commit `fsync`s the `-wal` file; zero lost financial/stock records | ~2–8 ms (imperceptible on background isolate) |

### Decision (`ADR-012`)
Adopt **`PRAGMA synchronous = FULL;`** alongside `PRAGMA journal_mode = WAL;` and `PRAGMA foreign_keys = ON;`. Because this application records human-paced financial, labour, and inventory transactions on a personal Android phone (where sudden battery drain or OS kills are realistic), strict ACID durability outweighs a ~3–5 ms background write difference.

---

## 6. Summary of Updated Documents & New Test Scenarios

- **Database Schema (`docs/07_database_schema.md`):** Switched to `PRAGMA synchronous = FULL;`, added `idx_labour_movement_basis_unique`, and added `client_request_id` + unique partial indexes on `stock_movements` and `payments`.
- **Stock Rules (`docs/09_stock_calculation_rules.md`):** Added Section 4.6 (Chronological Prefix Replay Reversal Dependency Guard) and Section 4.7 (Atomic 5-Point Pre-Issue Worker-Process Validation).
- **Labour Rules (`docs/10_labour_calculation_rules.md`):** Added Section 2.1 (Labour Entry Idempotency & Duplicate Submission Protection).
- **Backup Strategy (`docs/14_backup_restore_strategy.md`):** Added WAL safety rationale, `VACUUM INTO` vs Web WASM byte serialization, and explicit production overwrite / cross-flavor protection.
- **Storage & NFRs (`docs/03_non_functional_requirements.md`, `docs/13_offline_storage_strategy.md`):** Updated to `PRAGMA synchronous = FULL;`.
- **Testing Strategy (`docs/20_testing_strategy.md`):** Added Tests #28–#34 covering downstream stock reversal protection, damaged-to-good reversal protection, labour idempotency, `client_request_id` retry safety, atomic 5-point pre-issue worker-process validation, WAL `VACUUM INTO` snapshot consistency, and `PRAGMA synchronous = FULL` verification.
- **ADRs & Changelog (`docs/22_technical_decisions.md`, `CHANGELOG.md`, `README.md`):** Added `ADR-012` (SQLite `WAL + synchronous = FULL`) and `ADR-013` (Chronological Reversal Guard & Idempotency).
