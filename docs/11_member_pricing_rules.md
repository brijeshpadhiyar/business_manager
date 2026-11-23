# 11 — Member Pricing Rules

Historical pricing logic lives in a pure Dart domain service (`RateResolver`). Rates are never hardcoded and historical transactions are never retroactively recalculated.

---

## 1. Effective Date Structure

Each row in `member_process_rates` defines a rate for `(member_id, process_id)`:
- `rate_paise`: Integer >= 0 (e.g., `2000` for `₹20.00`).
- `effective_from`: Inclusive IST calendar date (`YYYY-MM-DD`).
- `effective_to`: Inclusive IST calendar date (`YYYY-MM-DD`), or `NULL` meaning **currently ongoing / open-ended**.

### Example: Hasmukh Bhai — Cutting
| `effective_from` | `effective_to` | `rate_paise` | Display |
| :--- | :--- | :---: | :--- |
| `2026-01-01` | `2026-11-30` | `2000` | ₹20.00 / pc |
| `2026-12-01` | `NULL` | `3000` | ₹30.00 / pc |

---

## 2. Non-Overlapping Date Range Invariant

For any active `(member_id, process_id)`, two rate intervals $[s_1, e_1]$ and $[s_2, e_2]$ (treating `NULL` as $+\infty$) must **never overlap**:
$$\text{Overlap iff } s_1 \le e_2 \land s_2 \le e_1$$

- **Auto-Close UX Convenience:** When adding a new rate starting on `new_from` (e.g., `2026-12-01`) while an open-ended rate (`effective_to = NULL`, `effective_from < new_from`) exists, the app shows a confirmation preview and—inside an atomic DB transaction—updates the previous rate's `effective_to` to `new_from - 1 day` (`2026-11-30`), inserts the new rate, and records an `audit_logs` entry.
- Gaps between rate periods are permitted (e.g., if a worker paused for a month), in which case rate lookup returns `NoEffectiveRateFound`.

---

## 3. Rate Resolution Algorithm (`transactionAt` in `Asia/Kolkata`)

1. Take the stock issue's `transactionAt` (UTC epoch ms).
2. Convert `transactionAt` to `Asia/Kolkata` (`IST`, UTC+05:30) and extract calendar date `businessDateIST` (`YYYY-MM-DD`).
   - *Critical Boundary Case:* `2026-11-30T19:00:00Z` = `2026-12-01 00:30:00 IST` → `businessDateIST = '2026-12-01'` → resolves **`₹30`** (NOT `₹20`).
3. Query active `member_process_rates` where:
   - `member_id = :memberId`
   - `process_id = :processId`
   - `effective_from <= :businessDateIST`
   - `(effective_to IS NULL OR effective_to >= :businessDateIST)`
4. Because ranges are strictly non-overlapping, this returns **0 or 1 row**.
   - **1 row:** Return `ResolvedRate(rateId, ratePaise)`.
   - **0 rows:** Block automatic save and prompt the user to either configure a rate for that date or explicitly enter an audited one-time rate override.
5. **Backdated Entries:** If today is `2026-12-05` (`recordedAt`) and the user enters a backdated issue with `transactionAt = 2026-11-29 IST`, `RateResolver` automatically selects `₹20` (`effective_to = 2026-11-30`).

---

## 4. Partial Return Rate Lock & Audited Manual Override

1. **Lock on `ISSUE`:**
   - When `ISSUE` is committed, `applied_rate_paise` and `source_rate_id` are persisted permanently on the `ISSUE` row.
2. **Automatic Inheritance on Partial Returns:**
   - Every `RETURN_GOOD` and `RETURN_DAMAGED` linked to `parent_issue_id` automatically copies `applied_rate_paise` and `source_rate_id` from the parent `ISSUE`.
   - **Example:**
     - `2026-11-28`: Issue `100` pcs to Hasmukh Bhai → locked at **`₹20`**.
     - `2026-12-01`: Hasmukh Bhai's Cutting rate increases to **`₹30`**.
     - `2026-12-05`: Hasmukh Bhai returns `80` pcs → automatically billed at **`₹20`** (`80 × ₹20 = ₹1,600`), **never** `₹30`.
3. **Manual Rate Override Protocol:**
   - If the business owner intentionally wants to override the locked rate on a specific movement (e.g., special bonus or negotiated rate on a difficult batch):
     1. User taps "Override Rate".
     2. App shows an explicit confirmation dialog displaying `Locked Rate (₹20)` vs `New Rate (₹25)`.
     3. User must enter a mandatory non-empty `override_reason`.
     4. Movement stores `applied_rate_paise = 2500`, `is_rate_overridden = 1`, `override_reason = "..."`.
     5. Scope: Applies **only to that specific movement row**; the parent `ISSUE`'s locked rate remains `₹20` for any other future partial returns unless explicitly overridden again.
     6. System writes an `audit_logs` row with `action_type = 'RATE_OVERRIDE'`, `previous_value_json`, `new_value_json`, and `reason`.
