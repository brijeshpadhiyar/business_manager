# 10 — Labour Calculation & Member Ledger Rules

All labour and ledger calculations live in pure Dart domain services (`LabourCalculator`, `LedgerCalculator`). No calculation logic is permitted in BLoCs or UI widgets.

---

## 1. Billing Mode Configuration & Locking

- **Global Default (`business_profile.default_billing_mode`):** `RECEIVED_QTY` (**Pay on Received Quantity**).
- **Per-Process Override (`processes.billing_mode_override`):** `NULL` (inherit global), `RECEIVED_QTY`, or `GIVEN_QTY`.
- **Damaged Pieces Eligibility (`processes.include_damaged_in_labour`):**
  - Default: `false` (**Pay on Good Returned Quantity only**).
  - Optional per-process setting: `true` (includes `RETURN_DAMAGED` in labour calculation when required).
  - `SETTLEMENT_LOST` and `SETTLEMENT_SHORTAGE` are **never** included in labour calculations by default.
- **Anti-Double-Counting Lock Rule:**
  - When an `ISSUE` movement is created, the effective `billing_mode` and `include_damaged_in_labour` are **locked onto the `ISSUE` row** (`locked_billing_mode`, `locked_include_damaged`) and inherited by all child settlements of that issue.
  - Changing global or process billing settings later applies **only to new `ISSUE` transactions**, guaranteeing zero double-counting and zero skipped labour on in-flight work.

---

## 2. Labour Entry Generation Matrix

| Movement Type | `locked_billing_mode = RECEIVED_QTY` (Default) | `locked_billing_mode = GIVEN_QTY` |
| :--- | :--- | :--- |
| `ISSUE` | Insert `basis_type = 'ISSUED'`, `is_payable = 0` *(informational)* | Insert `basis_type = 'ISSUED'`, `is_payable = 1` *(payable)* |
| `RETURN_GOOD` | Insert `basis_type = 'RECEIVED_GOOD'`, `is_payable = 1` *(payable)* | Insert `basis_type = 'RECEIVED_GOOD'`, `is_payable = 0` *(informational)* |
| `RETURN_DAMAGED` | If `locked_include_damaged == 1`: insert `RECEIVED_DAMAGED`, `is_payable = 1`; else no payable entry | No payable entry (already billed on `ISSUE`) |
| `SETTLEMENT_LOST` | No labour entry | No labour entry |
| `SETTLEMENT_SHORTAGE` | No labour entry | No labour entry |
| `REVERSAL` | Insert `basis_type = 'REVERSAL'` with negated `quantity` & `amount_paise` matching the reversed row's `is_payable` | Same |

- **Monetary Formula (Integer Paise):**
  $$\text{amount\_paise} = \text{quantity} \times \text{applied\_rate\_paise}$$

### 2.1 Labour Entry Idempotency & Duplicate Protection
1. **Database Uniqueness:** Enforced by `CREATE UNIQUE INDEX idx_labour_movement_basis_unique ON labour_entries(stock_movement_id, basis_type);` and `CREATE UNIQUE INDEX idx_labour_single_reversal ON labour_entries(reverses_labour_entry_id) WHERE reverses_labour_entry_id IS NOT NULL;`.
2. **Atomic Transactional Insertion:** `stock_movements`, `labour_entries`, and `audit_logs` are always written inside a single Drift `transaction(() async { ... })`.
3. **Retry-Safe Use Cases (`client_request_id`):** Submissions carry a per-form UUIDv4 `client_request_id` (unique partial index on `stock_movements` and `payments`). Duplicate taps or retried BLoC submissions return the already-committed result idempotently without generating duplicate labour entries.

---

## 3. Worked Labour Examples

### Example 1 — Default (`RECEIVED_QTY`, `include_damaged_in_labour = false`)
- Issue `100` pcs at `₹20` (`2000` paise):
  - `IssuedLabour = 100 × 2000 = ₹2,000` (`is_payable = 0`).
- Settle: `95 Good`, `3 Damaged`, `2 Lost`:
  - `ReceivedLabour (Good) = 95 × 2000 = ₹1,900` (`is_payable = 1`).
  - Damaged (`3`) & Lost (`2`) generate `₹0` payable labour.
  - **Earned / Payable Labour = `₹1,900`** (NOT `₹2,000 + ₹1,900` — zero double-counting).

### Example 2 — Process Override (`RECEIVED_QTY`, `include_damaged_in_labour = true`)
- Same settlement (`95 Good`, `3 Damaged`, `2 Lost` at `₹20`):
  - `ReceivedLabour (Good) = ₹1,900` (`is_payable = 1`).
  - `ReceivedLabour (Damaged) = 3 × 2000 = ₹60` (`is_payable = 1`).
  - Lost (`2`) = `₹0`.
  - **Earned / Payable Labour = `₹1,960`**.

### Example 3 — Process Override (`GIVEN_QTY`)
- Issue `100` pcs at `₹20`:
  - `IssuedLabour = ₹2,000` (`is_payable = 1`).
- Return `80` Good pcs later:
  - `ReceivedLabour = ₹1,600` (`is_payable = 0`, informational tracking only).
  - **Earned / Payable Labour = `₹2,000`** (no double-counting).

---

## 4. Advance Payments, Negative Balances & Member Ledger Formulas

All sums below are computed over **active** (non-reversed) rows for `member_id` in integer paise. A `labour_entries` row is active iff its `id` is NOT referenced by any `reverses_labour_entry_id` (and `basis_type != 'REVERSAL'`). A `payments` row is active iff its `id` is NOT referenced by any `reverses_payment_id` (and `payment_type != 'REVERSAL'`). *(Note: Summing all `labour_entries` including negative `REVERSAL` rows yields the exact same `EarnedLabour` total as summing active rows, providing an additional built-in reconciliation check.)*

1. **Issued Labour Total (Informational):**
   $$\text{TotalIssuedLabour} = \sum \text{amount\_paise where basis\_type = 'ISSUED'}$$
2. **Received Labour Total (Informational):**
   $$\text{TotalReceivedLabour} = \sum \text{amount\_paise where basis\_type IN ('RECEIVED\_GOOD', 'RECEIVED\_DAMAGED')}$$
3. **Earned / Payable Labour:**
   $$\text{EarnedLabour} = \sum \text{amount\_paise where is\_payable = 1}$$
4. **Payment Breakdown:**
   - $\text{RegularPayments} = \sum \text{payments.amount\_paise where payment\_type = 'REGULAR'}$
   - $\text{AdvancePayments} = \sum \text{payments.amount\_paise where payment\_type = 'ADVANCE'}$
   - $\text{AdvanceRefunds} = \sum \text{payments.amount\_paise where payment\_type = 'ADVANCE\_REFUND'}$
   - $\text{NetPaidToWorker} = \text{RegularPayments} + \text{AdvancePayments} - \text{AdvanceRefunds}$
5. **Net Financial Position (Supports Negative Pending Balance):**
   $$\text{NetBalance} = \text{EarnedLabour} - \text{NetPaidToWorker}$$
   - **Outstanding Payable (Owner owes Worker):** $\text{OutstandingPayable} = \max(0, \text{NetBalance})$
   - **Advance Credit Balance (Worker holds Advance):** $\text{AdvanceCreditBalance} = \max(0, -\text{NetBalance})$

### Worked Advance Payment Lifecycle
1. Worker takes `₹1,000` Advance (`ADVANCE`):
   - `EarnedLabour = ₹0`, `AdvancePayments = ₹1,000`, `NetBalance = -₹1,000` → **`OutstandingPayable = ₹0`**, **`AdvanceCreditBalance = ₹1,000`**.
2. Worker earns `₹600` labour:
   - `NetBalance = ₹600 - ₹1,000 = -₹400` → **`OutstandingPayable = ₹0`**, **`AdvanceCreditBalance = ₹400`**.
3. Worker earns another `₹1,000` labour:
   - `NetBalance = ₹1,600 - ₹1,000 = +₹600` → **`OutstandingPayable = ₹600`**, **`AdvanceCreditBalance = ₹0`**.
4. Owner pays `₹600` (`REGULAR`):
   - `NetBalance = ₹0` → **`OutstandingPayable = ₹0`**, **`AdvanceCreditBalance = ₹0`**.
5. *(Alternative Exit Case)* If Worker leaves at Step 2 with `₹400` Advance Credit and returns `₹400` cash (`ADVANCE_REFUND`):
   - `NetPaidToWorker = ₹1,000 - ₹400 = ₹600`, `NetBalance = ₹600 - ₹600 = ₹0` → Settled cleanly without deleting history.
