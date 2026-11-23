# 09 — Stock Calculation Rules

All inventory calculations live in a pure Dart domain service (`StockCalculator`) and are derived deterministically from active (non-reversed) `stock_movements` rows. Direct mutation of stock totals is strictly forbidden.

---

## 1. Movement Types & Active Filtering

A `stock_movements` row is **active** if its `id` is NOT referenced by any `REVERSAL` row (`reverses_movement_id`).

| Movement Type | Affects In-House Good Stock | Affects Worker Pending | Affects Damaged Bucket | Affects Lost / Shortage |
| :--- | :---: | :---: | :---: | :---: |
| `ISSUE` | `-qty` | `+qty` | `0` | `0` |
| `RETURN_GOOD` | `+qty` | `-qty` | `0` | `0` |
| `RETURN_DAMAGED` | `0` *(never added to good)* | `-qty` | `+qty` | `0` |
| `SETTLEMENT_LOST` | `0` | `-qty` | `0` | `+qty` (Lost) |
| `SETTLEMENT_SHORTAGE` | `0` | `-qty` | `0` | `+qty` (Shortage) |
| `ADJUSTMENT_DAMAGED_TO_GOOD` | `+qty` | `0` | `-qty` | `0` |

---

## 2. Core Formulas (Per `design_colour_id`)

Let $Q_0$ be `design_colours.initial_quantity`, and let sums be taken over **active** movements for that `design_colour_id`:

1. **Damaged Stock Bucket:**
   $$\text{DamagedBucket} = \sum \text{RETURN\_DAMAGED} - \sum \text{ADJUSTMENT\_DAMAGED\_TO\_GOOD}$$
2. **Total Lost & Shortage:**
   $$\text{TotalLost} = \sum \text{SETTLEMENT\_LOST}, \quad \text{TotalShortage} = \sum \text{SETTLEMENT\_SHORTAGE}$$
3. **Total Surviving Good Physical Stock:**
   $$\text{TotalGoodPhysicalStock} = Q_0 - \text{DamagedBucket} - \text{TotalLost} - \text{TotalShortage}$$
4. **Total Pending With Workers (Across All Processes):**
   $$\text{TotalPendingWithWorkers} = \sum \text{ISSUE} - \sum (\text{RETURN\_GOOD} + \text{RETURN\_DAMAGED} + \text{SETTLEMENT\_LOST} + \text{SETTLEMENT\_SHORTAGE})$$
5. **Physical Available In-House (Eligible for Next Issue):**
   $$\text{PhysicalAvailableInHouse} = \text{TotalGoodPhysicalStock} - \text{TotalPendingWithWorkers}$$
   *(Algebraically equivalent to: $Q_0 - \sum \text{ISSUE} + \sum \text{RETURN\_GOOD} + \sum \text{ADJUSTMENT\_DAMAGED\_TO\_GOOD}$.)*

---

## 3. Independent Per-Process Formulas (No Hardcoded Sequence)

For any `(design_colour_id, process_id)` pair:
- $\text{ProcessIssued}(p) = \sum \text{ISSUE}_p$
- $\text{ProcessGoodReturned}(p) = \sum \text{RETURN\_GOOD}_p$
- $\text{ProcessDamaged}(p) = \sum \text{RETURN\_DAMAGED}_p$
- $\text{ProcessLost}(p) = \sum \text{SETTLEMENT\_LOST}_p$
- $\text{ProcessShortage}(p) = \sum \text{SETTLEMENT\_SHORTAGE}_p$
- $\text{ProcessPending}(p) = \text{ProcessIssued}(p) - (\text{ProcessGoodReturned}(p) + \text{ProcessDamaged}(p) + \text{ProcessLost}(p) + \text{ProcessShortage}(p))$
- $\text{ProcessAvailableToIssue}(p) = \text{PhysicalAvailableInHouse}$

---

## 4. Strict Validation Invariants (Enforced Inside Atomic DB Transactions)

1. **Over-Issue Prevention:**
   - Before saving an `ISSUE(qty)`: require `qty > 0` AND `qty <= PhysicalAvailableInHouse`.
2. **Over-Return / Over-Settlement Prevention:**
   - For any settlement linked to `parent_issue_id`:
     $$\text{ParentRemainingPending} = \text{parent.qty} - \sum \text{active settlements for parent\_issue\_id}$$
   - Require `settlement_qty > 0` AND `settlement_qty <= ParentRemainingPending`.
   - When submitting a combined settlement form (e.g., `95 Good + 3 Damaged + 2 Lost`), require `(good + damaged + lost + shortage) <= ParentRemainingPending`.
3. **Mandatory Reason & Audit on Non-Good Settlements:**
   - `RETURN_DAMAGED`, `SETTLEMENT_LOST`, `SETTLEMENT_SHORTAGE`, `ADJUSTMENT_DAMAGED_TO_GOOD`, and `REVERSAL` **must** include a non-empty `reason`, `transactionAt`, `recordedAt`, and an `audit_logs` record.
4. **Damaged-to-Good Repair Adjustment Guard:**
   - Before saving `ADJUSTMENT_DAMAGED_TO_GOOD(qty)`: require `qty > 0` AND `qty <= DamagedBucket`.
   - Never silently convert damaged stock into good stock.
5. **Parent Issue Reversal Guard:**
   - Block reversing an `ISSUE` if any active child settlements exist for that `parent_issue_id`.
6. **Downstream Stock Reversal Dependency Protection (Chronological Prefix Replay):**
   - Before inserting any `REVERSAL` for target movement `M` (`RETURN_GOOD`, `RETURN_DAMAGED`, `ADJUSTMENT_DAMAGED_TO_GOOD`, etc.), `StockCalculator.validateReversal` simulates removing `M` from active movements for `M.design_colour_id` and replays all remaining active movements chronologically (`transaction_at ASC, recorded_at ASC, id ASC`).
   - At **every** point in the timeline and at the final state, `PhysicalAvailableInHouse >= 0`, `DamagedBucket >= 0`, and `ParentRemainingPending >= 0` must hold.
   - Example: `100` initial → `100` issued to Cutting → `80` returned from Cutting → `80` issued to Stitching → attempting to reverse the Cutting return of `80` yields `-80` at the Stitching issue and is **REJECTED** (`DownstreamStockDependencyFailure`) with a clear message identifying the blocking Stitching issue.
   - Equivalent protection applies when reversing `ADJUSTMENT_DAMAGED_TO_GOOD` whose repaired pieces were subsequently issued, or reversing `RETURN_DAMAGED` whose damaged pieces were subsequently repaired into good stock. Downstream transactions are **never** silently mutated.
7. **Atomic 5-Point Worker-Process Pre-Issue Validation:**
   - Inside the **same atomic SQLite transaction** as inserting an `ISSUE`:
     1. Member exists, `deleted_at IS NULL`, and `is_active = 1`.
     2. Process exists, `deleted_at IS NULL`, and `is_active = 1`.
     3. Active `member_processes` link exists for `(member_id, process_id)` (`is_active = 1`).
     4. Effective historical rate exists for `(member_id, process_id, businessDateIST)` (unless explicit audited manual override confirmed).
     5. `issue_qty > 0` AND `issue_qty <= PhysicalAvailableInHouse`.
   - Deactivating a member, process, or link later never affects historical transactions or pending partial returns on already-open issues.

---

## 5. Worked Examples

### Example A — Multi-Process Stock Flow (Flexible Order)
- Initial `Lot 1001 / Design A / Red`: `100` pcs → `PhysicalAvailableInHouse = 100`.
1. Issue `100` pcs to *Cutting* (Hasmukh Bhai):
   - `PhysicalAvailableInHouse = 0`, `Cutting.pending = 100`.
   - Attempting to issue `1` pc to *Stitching* → **REJECTED** (`0` available in-house).
2. Receive `80` `RETURN_GOOD` from *Cutting*:
   - `PhysicalAvailableInHouse = 80`, `Cutting.pending = 20`, `Cutting.goodReturned = 80`.
3. Issue `80` pcs to *Stitching* (Ravi Bhai):
   - `PhysicalAvailableInHouse = 0`, `Cutting.pending = 20`, `Stitching.pending = 80`.
   - Total physical pieces accounted for: `20 (Cutting) + 80 (Stitching) + 0 (In-house) = 100`.

### Example B — Partial Return with Damaged & Lost + Later Authorized Repair
- Issue `100` pcs to *Stitching*.
- Worker settles: `95 RETURN_GOOD` + `3 RETURN_DAMAGED` (reason: "Needle tear") + `2 SETTLEMENT_LOST` (reason: "Misplaced in transit").
  - `ParentRemainingPending = 100 - (95 + 3 + 2) = 0`.
  - `PhysicalAvailableInHouse = 95` (damaged 3 are NOT added to good stock).
  - `DamagedBucket = 3`, `TotalLost = 2`, `TotalGoodPhysicalStock = 95`.
- Later, workshop repairs 2 of the 3 damaged pieces and records `ADJUSTMENT_DAMAGED_TO_GOOD(qty: 2, reason: "Re-stitched collar in-house")`:
  - `DamagedBucket = 1`, `PhysicalAvailableInHouse = 97`, `TotalGoodPhysicalStock = 97`, with full audit log.
