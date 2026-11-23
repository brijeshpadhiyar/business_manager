# 12 — DateTime & Audit Trail Strategy

## 1. Timezone Architecture (UTC Storage → `Asia/Kolkata` Display)

- **Database Storage:** Every timestamp column (`created_at`, `updated_at`, `deleted_at`, `transaction_at`, `recorded_at`) is stored in SQLite as **UTC milliseconds since Unix epoch (`INTEGER`)**.
- **Display Layer:** All user-facing dates and times are converted via `IstDateTimeHelper` (backed by the `timezone` package using IANA `Asia/Kolkata`, UTC+05:30) before formatting with `intl`.
- **Business Date Extraction:** Whenever a calendar date (`YYYY-MM-DD`) is needed for rate lookup (`member_process_rates`), daily report grouping, or ledger date filtering, UTC timestamps are first converted to `Asia/Kolkata` so midnight boundaries always align with Indian Standard Time.

---

## 2. Semantic Distinction of All 5 Timestamp Fields

| Field | Meaning | Mutable? |
| :--- | :--- | :---: |
| `transaction_at` | Actual business date/time when the lot was created, stock moved, or payment happened (supports backdating). | Immutable on ledger tables |
| `recorded_at` | Exact device UTC time when the user tapped Save in the app. | Immutable |
| `created_at` | Record creation UTC timestamp. | Immutable |
| `updated_at` | Last metadata modification UTC timestamp (updated on master data edits like Member phone or Process name). | Updated on master edits |
| `deleted_at` | Nullable soft-delete UTC timestamp (`NULL` = active). | Set only on soft delete |

- **Backdated Entry Transparency:** Whenever `|recorded_at - transaction_at| > 24 hours`, the transaction detail & audit view displays both **Business Date (`transactionAt`)** and **Entered On (`recordedAt`)** clearly.

---

## 3. Immutable Audit Log (`audit_logs`)

Every significant state transition writes an immutable `audit_logs` record inside the **same database transaction** as the entity change:

- **Audited Actions (`action_type`):**
  - `CREATE` — Lot, Design, Colour, Process, Member, Rate, Stock Movement, Payment, Business Profile.
  - `UPDATE` — Master data edits (Lot notes, Process billing config, Member details, Rate `effective_to` auto-close, Business Profile).
  - `SOFT_DELETE` — Archiving/soft-deleting master records or attachments.
  - `DEACTIVATE` / `REACTIVATE` — Process or Member status toggles.
  - `RATE_OVERRIDE` — Manual override of a locked or resolved rate (stores old vs. new paise + mandatory reason).
  - `REVERSAL` — Reversing a stock movement or payment (links original + reversal ID + mandatory reason).
  - `DAMAGED_TO_GOOD_ADJUSTMENT` — Authorized repair adjustment moving pieces from Damaged Stock Bucket back to Good Stock (stores quantity, old/new damaged bucket count, reason, notes).
  - `BACKUP_EXPORT` / `BACKUP_RESTORE` — Records when raw `.sqlite` or `.zip` backups were exported or restored.

### Example `audit_logs` JSON Payload (`RATE_OVERRIDE`)
```json
{
  "entity_type": "stock_movements",
  "entity_id": "019a1b2c-...",
  "action_type": "RATE_OVERRIDE",
  "actor": "Owner",
  "previous_value_json": "{\"applied_rate_paise\": 2000, \"source\": \"parent_issue_lock\"}",
  "new_value_json": "{\"applied_rate_paise\": 2500, \"is_rate_overridden\": true}",
  "reason": "Heavy embroidery rework bonus approved by owner",
  "transaction_at": 1796452200000,
  "recorded_at": 1796452260000
}
```

---

## 4. Non-Overwrite Guarantee

- Historical `stock_movements`, `labour_entries`, `payments`, and `audit_logs` are **append-only**.
- No UI screen or DAO exposes raw editing or hard deletion of historical financial/stock rows.
- Corrections always create an explicit `REVERSAL` entry + replacement entry (if needed), preserving 100% traceability for the business owner.
