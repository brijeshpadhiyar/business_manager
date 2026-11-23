# 02 — Functional Requirements

Each functional requirement is uniquely numbered (`FR-xxx`) for traceability across database schema, implementation roadmap, and test scenarios.

---

## 1. Branding, Settings & Localization (`FR-001` – `FR-006`)

- **FR-001:** Display configurable business branding defaulting to `Business Manager` (English) and `બિઝનેસ મેનેજર` (Gujarati), with editable business name, logo, contact info, and notes in `business_profile`.
- **FR-002:** Support theme selection (`System` default, `Light`, `Dark`) persisted locally.
- **FR-003:** Support language selection (`System Default`, `English`, `Gujarati`) persisted locally, updating all UI strings immediately without app restart.
- **FR-004:** Configure global default labour billing mode (`RECEIVED_QTY` default, or `GIVEN_QTY`).
- **FR-005:** Provide local device/operator label (optional local profile name such as `"Owner"`) stamped into `created_by` / `updated_by` audit fields.
- **FR-006:** Ensure strict environment separation between `dev` and `prod` flavors (separate DB, separate media directory, separate app ID & name).

---

## 2. Lot, Design & Colour Management (`FR-010` – `FR-018`)

- **FR-010:** Create a Lot with a unique `lot_number`, optional title/notes, and `transactionAt` (lot creation date/time).
- **FR-011:** Enforce uniqueness of `lot_number` across active (non-deleted) lots with clear localized validation errors.
- **FR-012:** Attach one or more photos to a Lot via camera or gallery/file picker, copied into private app storage and tracked in `attachments`.
- **FR-013:** Add, edit, and soft-delete multiple Designs within a Lot (`lot_designs`).
- **FR-014:** Add and edit multiple Colours within each Design (`design_colours`), each storing `initial_quantity` (integer > 0) and `unit_price_paise` (integer >= 0).
- **FR-015:** Prevent hard-deleting a Lot, Design, or Design+Colour that has existing stock movements; allow archiving/soft-deleting only when permitted by integrity rules.
- **FR-016:** Display real-time Lot summary: initial pieces, physical in-house good stock, total pending with workers, damaged stock bucket, lost/shortage totals, and process-wise breakdown.
- **FR-017:** Search and filter Lots by lot number, design name, colour name, date range, and pending status.
- **FR-018:** View full-screen Lot photos with zoom/pan and delete/add capability (audited).

---

## 3. Dynamic Process Management (`FR-020` – `FR-025`)

- **FR-020:** Create custom production processes (name, optional Gujarati/secondary label or localized display, description) with zero hardcoded process list or sequence.
- **FR-021:** Edit process name, description, optional `billing_mode_override` (`NULL` = inherit global, `RECEIVED_QTY`, `GIVEN_QTY`), and `include_damaged_in_labour` (`false` default).
- **FR-022:** Activate or deactivate any process.
- **FR-023:** Hide deactivated processes from new stock issue dropdowns while keeping them fully visible in historical transactions, member ledgers, and reports.
- **FR-024:** Assign/unassign multiple Members to a Process (many-to-many).
- **FR-025:** Display process-wise live workload (total issued, good returned, damaged/lost/shortage, currently pending).

---

## 4. Worker / Member & Historical Pricing (`FR-030` – `FR-039`)

- **FR-030:** Create and edit Members (name, phone, address/notes, active status).
- **FR-031:** Link a Member to multiple Processes (`member_processes`) and unlink when no longer performing that process without breaking history.
- **FR-032:** Deactivate/reactivate a Member; deactivated members cannot receive new stock issues, but pending returns, payments, and historical ledgers remain fully accessible.
- **FR-033:** Add historical piece rates per `(member_id, process_id)` with `rate_paise` (>= 0), `effective_from` (`YYYY-MM-DD`), and optional `effective_to` (`YYYY-MM-DD`).
- **FR-034:** Prevent overlapping effective date ranges for the same `(member_id, process_id)` pair.
- **FR-035:** Automatically close the previous open-ended rate (`effective_to = new_effective_from - 1 day`) when a user adds a newer rate (with explicit UI preview/confirmation).
- **FR-036:** Resolve the applicable rate on a new `ISSUE` using `transactionAt` converted to `Asia/Kolkata` business date (`YYYY-MM-DD`).
- **FR-037:** Block saving an `ISSUE` if no effective rate exists for `(member_id, process_id, businessDateIST)` unless the user explicitly enters an audited one-time rate or creates a rate record first.
- **FR-038:** Updating or adding a new rate must **never** recalculate existing stock movements or labour entries.
- **FR-039:** Display full chronological rate history per Member and Process.

---

## 5. Stock Movements, Partial Returns & Damaged Adjustments (`FR-040` – `FR-052`)

- **FR-040:** Record a Stock Issue (`ISSUE`) capturing: Lot, Design, Colour, Process, Member, Quantity (> 0), Locked Rate, Locked Billing Mode, Locked `include_damaged_in_labour`, `transactionAt`, `recordedAt`, Notes, and optional Attachments.
- **FR-041:** Strictly validate `issue_qty <= PhysicalAvailableInHouse` inside an atomic DB transaction before committing an `ISSUE`.
- **FR-042:** Record multiple partial settlements against an open `ISSUE` (`parent_issue_id`) using four distinct types:
  - `RETURN_GOOD`
  - `RETURN_DAMAGED`
  - `SETTLEMENT_LOST`
  - `SETTLEMENT_SHORTAGE`
- **FR-043:** Strictly validate `settlement_qty <= parent_issue_remaining_pending_qty` inside an atomic DB transaction.
- **FR-044:** Require a non-empty `reason` (and support notes/attachments) for all `RETURN_DAMAGED`, `SETTLEMENT_LOST`, and `SETTLEMENT_SHORTAGE` movements.
- **FR-045:** Ensure `RETURN_DAMAGED` increments the Damaged Stock Bucket and **never** increments `PhysicalAvailableInHouse`.
- **FR-046:** Automatically lock and inherit `applied_rate_paise` from the parent `ISSUE` onto every child return/settlement movement.
- **FR-047:** Allow explicit manual rate override on a return movement **only** after a confirmation dialog + mandatory `override_reason`, recording `is_rate_overridden = true` and writing an `audit_logs` entry.
- **FR-048:** Allow an authorized **Damaged-to-Good Repair Adjustment** (`ADJUSTMENT_DAMAGED_TO_GOOD`) for a `design_colour_id`, validating `qty <= current_damaged_bucket_qty`, requiring reason, date/time, notes, and writing an `audit_logs` entry.
- **FR-049:** Support explicit **Reversal / Compensating Movement** (`REVERSAL`) to correct a mistakenly entered transaction without mutating or hard-deleting the original row.
- **FR-050:** Block reversing a parent `ISSUE` if any non-reversed child settlements exist.
- **FR-051:** Allow attaching photos/documents to any stock movement.
- **FR-052:** Display complete filterable Transaction History (by Lot, Design, Colour, Process, Member, Movement Type, Date Range).

---

## 6. Labour Calculation, Payments & Member Ledger (`FR-060` – `FR-071`)

- **FR-060:** Automatically create immutable `labour_entries` inside the same DB transaction as stock movements according to the locked `billing_mode` and `include_damaged_in_labour` flags.
- **FR-061:** Track `Issued Labour`, `Received Labour`, `Earned/Payable Labour`, `Regular Payments`, `Advance Payments`, `Advance Refunds`, `Outstanding Payable`, and `Advance Credit Balance` distinctly without double-counting.
- **FR-062:** Exclude `SETTLEMENT_LOST` and `SETTLEMENT_SHORTAGE` from payable labour by default.
- **FR-063:** Record Member Payments with types: `REGULAR`, `ADVANCE`, and `ADVANCE_REFUND`.
- **FR-064:** Capture `amount_paise` (> 0), `payment_mode` (Cash, UPI, Bank Transfer, Cheque, Other), `reference_no`, `transactionAt`, `recordedAt`, `notes`, and optional receipt photo attachment.
- **FR-065:** Support paying an Advance before any labour is earned, automatically displaying the resulting negative net balance as **Advance Credit Balance**.
- **FR-066:** Automatically offset Advance Credit against newly earned labour in ledger calculations.
- **FR-067:** Allow reversing a mistakenly entered payment via an explicit `REVERSAL` payment record (never silent edit/delete).
- **FR-068:** Display comprehensive **Member Ledger** screen: summary cards (Pending Pieces, Earned Labour, Total Paid, Outstanding Payable / Advance Credit), process-wise breakdown, rate history tab, and unified date-wise transaction timeline.
- **FR-069:** Filter Member Ledger by date range (`Asia/Kolkata`), process, and entry type (Stock / Labour / Payment).
- **FR-070:** Show Audit Trail viewer for any transaction (displaying `transactionAt`, `recordedAt`, `createdAt`, `action_type`, `previous_value`, `new_value`).
- **FR-071:** Support exporting/sharing a readable Member Ledger summary (future-extensible to PDF/CSV in reporting phase).

---

## 7. Reports & Backup / Restore (`FR-080` – `FR-089`)

- **FR-080:** **Lot Summary Report:** Per-lot initial, in-house good, in-process pending, damaged, lost/shortage, and total labour cost.
- **FR-081:** **Process Workload Report:** Per-process issued, good returned, damaged/lost/shortage, pending pieces, and labour totals.
- **FR-082:** **Worker Pending Stock & Payable Report:** Every worker's current pending pieces, earned labour, advances, regular payments, outstanding payable, and advance credit.
- **FR-083:** **Damaged / Lost / Shortage Report:** Filterable audit breakdown by lot, process, member, and date range, including authorized damaged-to-good repair adjustments.
- **FR-084:** **Payment & Cashflow Report:** Date-wise regular payments, advances, and advance refunds grouped by payment mode.
- **FR-085:** **Export Raw SQLite Database:** Explicit user action to checkpoint WAL (`PRAGMA wal_checkpoint(TRUNCATE)`) and export a clean copy of the `.sqlite` file via system share/save dialog for inspection in external SQLite viewers.
- **FR-086:** **Create Full Backup (`.zip`):** Explicit user action to package the checkpointed `.sqlite` database, all lot photos, all attachments, and `manifest.json` (schema version, flavor, app version, UTC timestamp, SHA-256 checksums) into an unencrypted `.zip` archive.
- **FR-087:** **Restore Full Backup (`.zip`):** Validate `manifest.json`, checksums, and schema version compatibility; create an automatic pre-restore safety snapshot; close DB; atomically swap DB + media; reopen DB; roll back automatically on any error.
- **FR-088:** Display last backup date/time (`Asia/Kolkata`) and backup health reminder in Settings.
- **FR-089:** Never expose the internal live SQLite database directly in public Android storage; all exports occur strictly via explicit user action.
