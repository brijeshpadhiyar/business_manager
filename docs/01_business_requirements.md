# 01 — Business Requirements

All business requirements below are **confirmed Version 1 requirements**. Zero open questions remain from discovery.

---

## 1. Branding & Business Profile

- **Default Display Names:**
  - English: `Business Manager`
  - Gujarati: `બિઝનેસ મેનેજર`
- **Configurability:** Application branding, business name, logo, address/contact metadata, and global billing defaults must be stored in a configurable `business_profile` / settings layer so they can be customized later without code changes.

---

## 2. Lot, Design & Colour Management

- Create, view, edit, archive/soft-delete, and search **Lots**.
- Every Lot must have a **unique Lot Number** (e.g., `1001`, `LOT-2026-01`).
- Record Lot creation date and time (`createdAt`, `transactionAt`).
- Attach **multiple photos** to a Lot (stored locally in private app storage).
- Add **multiple Designs** within a Lot.
- Add **multiple Colours** within each Design.
- Maintain separate **initial quantity** and **unit price (in paise)** for each `Design + Colour` combination.

---

## 3. Quantity-Based Inventory & Multi-Process Stock Flow

- Inventory is strictly **quantity-based** (never individual piece serial tracking).
  - Example: `Lot 1001` → `Design A / Red: 100 pcs`, `Design A / Blue: 80 pcs`, `Design B / Black: 120 pcs`.
- Every stock movement is recorded as an immutable ledger event; historical stock transactions are never overwritten.
- **Independent Multi-Process Tracking (Confirmed):**
  - Track `issued`, `received` (good), `damaged`, `lost`, `shortage`, `pending`, and `available` quantities independently for every process.
  - **Example Flow (Must Be Supported):**
    1. Initial stock: `100` pieces.
    2. Issue `100` pieces to *Cutting* → Physical in-house available = `0`; Cutting pending = `100`.
    3. Receive `80` Good pieces from *Cutting* → Physical in-house available = `80`; Cutting pending = `20`.
    4. Issue `80` pieces to *Stitching* → Physical in-house available = `0`; Cutting pending = `20`; Stitching pending = `80`.
  - **Strict Physical Stock Validation:** Prevent issuing more stock than `PhysicalAvailableInHouse`.
  - **Flexible Sequence:** Never hardcode process order; any active process can be executed in any order.

---

## 4. Dynamic Process Management

- Processes (e.g., *Cutting*, *Press*, *Stitching*, *Finishing*, *Packing*) are 100% user-created and managed.
- Users can create, edit, activate, and deactivate processes.
- Each process supports optional overrides for:
  - **Labour Billing Mode** (`GIVEN_QTY` vs `RECEIVED_QTY`, falling back to global default `RECEIVED_QTY`).
  - **Include Damaged Returns in Labour** (`true` / `false`, default `false`).
- Deactivating a process hides it from new assignments while keeping all historical transactions, rates, and reports 100% intact.

---

## 5. Worker / Member Management

- Create, edit, activate, and deactivate Workers/Members (e.g., *Ravi Bhai*, *Darshan Bhai*, *Hasmukh Bhai*, *Rakesh Bhai*).
- Store optional phone number, notes, and profile metadata.
- **Many-to-Many Process Linking:** A Member can be linked to multiple Processes; a Process can have multiple Members.
- Deactivating a Member or unlinking a Process must preserve all historical transactions, rates, labour records, and ledgers.

---

## 6. Historical Member Pricing

- Each Member can have distinct piece rates for each Process.
- Maintain historical rates with `effective_from` (inclusive `YYYY-MM-DD`) and `effective_to` (nullable inclusive `YYYY-MM-DD`).
  - Example: *Hasmukh Bhai* — Cutting: `₹20` until `2026-11-30`; Cutting: `₹30` starting `2026-12-01`.
- **Rate Effective Date Reference (Confirmed):**
  - Always use `transactionAt` converted to `Asia/Kolkata` (`IST`) calendar date (`YYYY-MM-DD`) to select the applicable rate.
  - Keep `recordedAt` separately to record when the entry was actually saved on the device.
  - Backdated transactions automatically resolve the historical rate effective on `transactionAt`.
- **Rate Immutability & Partial Return Rate Lock (Confirmed):**
  - Lock the applicable rate on the original `ISSUE` movement (e.g., `₹20` on Nov 28).
  - Subsequent partial returns (e.g., `80` pcs returned on Dec 5 after a Dec 1 hike to `₹30`) automatically inherit the locked `₹20` rate.
  - Updating a Member's rate never recalculates existing transactions.
  - Manual rate overrides on a movement require explicit user confirmation, a mandatory reason, and a complete `audit_logs` record.

---

## 7. Stock Movements, Partial Returns & Damaged Stock Disposition

- **Stock Issue (`ISSUE`):** Required fields: Lot, Design, Colour, Process, Member, Quantity, Locked Applicable Rate, `transactionAt`, `recordedAt`, Notes (optional), Attachments (optional).
- **Partial Returns & Settlements (Confirmed):**
  - Support multiple partial settlements against a single `ISSUE` (`parent_issue_id`).
  - Support four distinct settlement types:
    1. `RETURN_GOOD` — Good pieces returned to workshop (adds back to `PhysicalAvailableInHouse`).
    2. `RETURN_DAMAGED` — Damaged pieces returned (added to **Damaged Stock Bucket**; **never** added to good available stock).
    3. `SETTLEMENT_LOST` — Pieces confirmed lost (reduces surviving physical stock).
    4. `SETTLEMENT_SHORTAGE` — Missing/shortage pieces (reduces surviving physical stock).
  - **Example:** Issued `100` → Good Return `95`, Damaged `3`, Lost/Missing `2` → Outstanding pending = `0`; Good available = `95`; Damaged bucket = `3`; Lost/Shortage = `2`.
  - Prevent total settled quantity across all 4 types from exceeding the parent `ISSUE` quantity.
  - Every non-good settlement (`RETURN_DAMAGED`, `SETTLEMENT_LOST`, `SETTLEMENT_SHORTAGE`) requires a **reason**, timestamp, notes, and full audit history.
- **Damaged Stock Disposition (Confirmed):**
  - V1 tracks Damaged Stock in a dedicated bucket with full reporting and audit history.
  - Database schema is future-ready for full repair/salvage workflows, without building a complex repair UI in V1.
  - V1 allows an explicit **Authorized Damaged-to-Good Repair Adjustment** (`ADJUSTMENT_DAMAGED_TO_GOOD`) requiring quantity (`<= current damaged bucket`), reason, date/time, notes, and audit trail. Damaged stock is never silently converted to good stock.

---

## 8. Labour Calculation

- Support both **Given Quantity** (`GIVEN_QTY`) and **Received Quantity** (`RECEIVED_QTY`) billing modes.
- **Default Billing Mode (Confirmed):** **Pay on Received Quantity** (`RECEIVED_QTY`), configurable globally and overridden individually per process.
- **Damaged Pieces Labour Eligibility (Confirmed):**
  - Default: Labour is payable **only on Good Returned Quantity** (`95 × ₹20 = ₹1,900` in the `95 Good / 3 Damaged / 2 Lost` example).
  - Optional per-process toggle (`include_damaged_in_labour`, default `false`) allows including `RETURN_DAMAGED` pieces in labour when required.
  - `SETTLEMENT_LOST` and `SETTLEMENT_SHORTAGE` are **never** included in labour calculations by default.
- Maintain separate, clearly labeled calculation records for:
  - Issued Labour Amount
  - Received Labour Amount
  - Earned / Payable Amount
  - Paid Amount (Regular + Advance)
  - Pending Payable Amount / Advance Credit Balance
- Strictly prevent duplicate or double-counted labour by locking `billing_mode` and `include_damaged_in_labour` on the `ISSUE` transaction.

---

## 9. Member Ledger & Advance Payments

- **Advance Payments & Negative Balances (Confirmed):**
  - Workers may receive **Advance Payments** before earning labour.
  - Negative pending payable balances represent **Advance Credit** carried forward and automatically offset against future earned labour.
  - Support `ADVANCE`, `REGULAR`, and `ADVANCE_REFUND` payment types, each with `transactionAt`, `recordedAt`, payment mode (Cash/UPI/Bank/Other), reference number, notes, optional receipt attachment, and audit history.
- **Member Ledger View:**
  - Total quantities issued, good returned, damaged/lost/shortage settled, and currently pending.
  - Process-wise transaction breakdown.
  - Historical rate timeline.
  - Earned Labour, Advance Payments, Regular Payments, Outstanding Payable, and Advance Credit Balance.
  - Complete chronological date-wise history.

---

## 10. Audit Trail, Reports & Offline Backup

- **Audit Trail:** Every core entity and transaction tracks `createdAt`, `updatedAt`, `deletedAt` (nullable), `transactionAt`, `recordedAt` (UTC), plus `audit_logs` capturing `action_type`, `actor`, `previous_value`, and `new_value`.
- **Reports:** Lot-wise stock & progress, process-wise pending work, worker-wise pending stock & payables, damaged/lost/shortage report, labour summary, and payment summary.
- **Backup & Restore (Confirmed V1 Security Model):**
  - Internal SQLite database remains inside **private application storage** (never exposed in public folders).
  - Explicit user-triggered **Raw `.sqlite` Export** for inspection in external SQLite viewer tools.
  - Explicit user-triggered **Unencrypted Full `.zip` Backup** (database + lot photos + attachments + `manifest.json`) and atomic restore.
  - Backup encryption and app-level PIN/biometric lock are documented as future enhancements.

---

## 11. Open Questions

*None — all 11 business and technical questions identified during discovery have been formally confirmed and integrated into the Version 1 requirements above.*
