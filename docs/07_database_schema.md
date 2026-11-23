# 07 — Database Schema (Drift + SQLite)

## 1. Global Schema Conventions

- **Primary Keys:** `TEXT` storing UUIDv7 strings (time-sortable, offline-safe, future-sync-ready).
- **Monetary Values:** `INTEGER` storing **paise** (`₹20.00` → `2000`; `CHECK >= 0` unless explicitly signed).
- **Timestamps:** `INTEGER` storing UTC milliseconds since Unix epoch (`created_at`, `updated_at`, `deleted_at`, `transaction_at`, `recorded_at`).
- **Business Dates:** `TEXT` in strict ISO-8601 `YYYY-MM-DD` format (`Asia/Kolkata` calendar date) for `effective_from` / `effective_to`.
- **SQLite PRAGMAs (Enforced on every connection open):**
  - `PRAGMA foreign_keys = ON;`
  - `PRAGMA journal_mode = WAL;`
  - `PRAGMA synchronous = FULL;` *(strict ACID durability for financial/inventory records — see `ADR-012`)*
  - `PRAGMA busy_timeout = 5000;`

---

## 2. Table Definitions

### 2.1 `business_profile` (Singleton / Configurable Branding & Global Defaults)
| Column | SQLite Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | Singleton `'default'` |
| `name_en` | `TEXT` | `NOT NULL DEFAULT 'Business Manager'` | English display name |
| `name_gu` | `TEXT` | `NOT NULL DEFAULT 'બિઝનેસ મેનેજર'` | Gujarati display name |
| `owner_name` | `TEXT` | `NULL` | Default operator label for audit |
| `phone` | `TEXT` | `NULL` | Business contact number |
| `address` | `TEXT` | `NULL` | Workshop address |
| `logo_attachment_id` | `TEXT` | `NULL REFERENCES attachments(id)` | Optional custom logo |
| `default_billing_mode` | `TEXT` | `NOT NULL DEFAULT 'RECEIVED_QTY' CHECK(IN ('RECEIVED_QTY','GIVEN_QTY'))` | Global labour billing default |
| `created_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `updated_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |

### 2.2 `lots`
| Column | SQLite Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | UUIDv7 |
| `lot_number` | `TEXT` | `NOT NULL` | Unique among non-deleted lots (partial unique index) |
| `title` | `TEXT` | `NULL` | Optional descriptive title |
| `notes` | `TEXT` | `NULL` | Freeform notes |
| `status` | `TEXT` | `NOT NULL DEFAULT 'ACTIVE' CHECK(IN ('ACTIVE','COMPLETED','ARCHIVED'))` | Lot lifecycle status |
| `transaction_at` | `INTEGER` | `NOT NULL` | Lot business creation date/time (UTC) |
| `recorded_at` | `INTEGER` | `NOT NULL` | App entry timestamp (UTC) |
| `created_by` | `TEXT` | `NULL` | Local operator label |
| `updated_by` | `TEXT` | `NULL` | Local operator label |
| `created_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `updated_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `deleted_at` | `INTEGER` | `NULL` | Soft delete UTC epoch ms |

*Index:* `CREATE UNIQUE INDEX idx_lots_number_active ON lots(lot_number) WHERE deleted_at IS NULL;`

### 2.3 `lot_designs`
| Column | SQLite Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | UUIDv7 |
| `lot_id` | `TEXT` | `NOT NULL REFERENCES lots(id) ON DELETE RESTRICT` | Parent lot |
| `design_name` | `TEXT` | `NOT NULL` | Design code/name (e.g., `Design A`) |
| `notes` | `TEXT` | `NULL` | Optional notes |
| `created_by` | `TEXT` | `NULL` | Local operator label |
| `updated_by` | `TEXT` | `NULL` | Local operator label |
| `created_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `updated_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `deleted_at` | `INTEGER` | `NULL` | Soft delete UTC epoch ms |

*Index:* `CREATE UNIQUE INDEX idx_lot_designs_unique ON lot_designs(lot_id, lower(design_name)) WHERE deleted_at IS NULL;`

### 2.4 `design_colours`
| Column | SQLite Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | UUIDv7 |
| `lot_design_id` | `TEXT` | `NOT NULL REFERENCES lot_designs(id) ON DELETE RESTRICT` | Parent design |
| `colour_name` | `TEXT` | `NOT NULL` | Colour name (e.g., `Red`, `Blue`) |
| `colour_hex` | `TEXT` | `NULL` | Optional UI swatch hex (`#E53935`) |
| `initial_quantity` | `INTEGER` | `NOT NULL CHECK(initial_quantity > 0)` | Starting good pieces |
| `unit_price_paise` | `INTEGER` | `NOT NULL DEFAULT 0 CHECK(unit_price_paise >= 0)` | Garment price per piece (paise) |
| `notes` | `TEXT` | `NULL` | Optional notes |
| `created_by` | `TEXT` | `NULL` | Local operator label |
| `updated_by` | `TEXT` | `NULL` | Local operator label |
| `created_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `updated_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `deleted_at` | `INTEGER` | `NULL` | Soft delete UTC epoch ms |

*Index:* `CREATE UNIQUE INDEX idx_design_colours_unique ON design_colours(lot_design_id, lower(colour_name)) WHERE deleted_at IS NULL;`

### 2.5 `processes` (100% Dynamic Production Processes)
| Column | SQLite Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | UUIDv7 |
| `name` | `TEXT` | `NOT NULL` | Process name (e.g., `Cutting`, `Press`, `Stitching`) |
| `description` | `TEXT` | `NULL` | Optional notes |
| `is_active` | `INTEGER` | `NOT NULL DEFAULT 1 CHECK(is_active IN (0,1))` | Active flag |
| `billing_mode_override` | `TEXT` | `NULL CHECK(billing_mode_override IS NULL OR billing_mode_override IN ('RECEIVED_QTY','GIVEN_QTY'))` | `NULL` inherits global default |
| `include_damaged_in_labour` | `INTEGER` | `NOT NULL DEFAULT 0 CHECK(include_damaged_in_labour IN (0,1))` | Optional per-process damaged labour toggle |
| `created_by` | `TEXT` | `NULL` | Local operator label |
| `updated_by` | `TEXT` | `NULL` | Local operator label |
| `created_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `updated_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `deleted_at` | `INTEGER` | `NULL` | Soft delete UTC epoch ms |

*Index:* `CREATE UNIQUE INDEX idx_processes_name_active ON processes(lower(name)) WHERE deleted_at IS NULL;`

### 2.6 `members` (Workers / Karigars)
| Column | SQLite Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | UUIDv7 |
| `name` | `TEXT` | `NOT NULL` | Worker name (e.g., `Hasmukh Bhai`) |
| `phone` | `TEXT` | `NULL` | Contact number |
| `address` | `TEXT` | `NULL` | Optional worker address (`FR-030`) |
| `notes` | `TEXT` | `NULL` | Optional notes |
| `is_active` | `INTEGER` | `NOT NULL DEFAULT 1 CHECK(is_active IN (0,1))` | Active flag |
| `created_by` | `TEXT` | `NULL` | Local operator label |
| `updated_by` | `TEXT` | `NULL` | Local operator label |
| `created_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `updated_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `deleted_at` | `INTEGER` | `NULL` | Soft delete UTC epoch ms |

### 2.7 `member_processes` (Many-to-Many Join Table)
| Column | SQLite Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | UUIDv7 |
| `member_id` | `TEXT` | `NOT NULL REFERENCES members(id) ON DELETE RESTRICT` | Worker |
| `process_id` | `TEXT` | `NOT NULL REFERENCES processes(id) ON DELETE RESTRICT` | Process |
| `is_active` | `INTEGER` | `NOT NULL DEFAULT 1 CHECK(is_active IN (0,1))` | Active assignment |
| `created_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `updated_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |

*Index:* `CREATE UNIQUE INDEX idx_member_processes_pair ON member_processes(member_id, process_id);`

### 2.8 `member_process_rates` (Historical Effective-Dated Rates)
| Column | SQLite Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | UUIDv7 |
| `member_id` | `TEXT` | `NOT NULL REFERENCES members(id) ON DELETE RESTRICT` | Worker |
| `process_id` | `TEXT` | `NOT NULL REFERENCES processes(id) ON DELETE RESTRICT` | Process |
| `rate_paise` | `INTEGER` | `NOT NULL CHECK(rate_paise >= 0)` | Rate per piece in paise |
| `effective_from` | `TEXT` | `NOT NULL` | Inclusive IST date `YYYY-MM-DD` |
| `effective_to` | `TEXT` | `NULL` | Inclusive IST date `YYYY-MM-DD` (`NULL` = ongoing) |
| `notes` | `TEXT` | `NULL` | Reason for rate change |
| `created_by` | `TEXT` | `NULL` | Local operator label |
| `updated_by` | `TEXT` | `NULL` | Local operator label |
| `created_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `updated_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `deleted_at` | `INTEGER` | `NULL` | Soft delete UTC epoch ms |

*Check:* `CHECK(effective_to IS NULL OR effective_to >= effective_from)`
*Index:* `CREATE INDEX idx_rates_lookup ON member_process_rates(member_id, process_id, effective_from, effective_to) WHERE deleted_at IS NULL;`

### 2.9 `stock_movements` (Append-Only Inventory & Settlement Ledger)
| Column | SQLite Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | UUIDv7 |
| `lot_id` | `TEXT` | `NOT NULL REFERENCES lots(id) ON DELETE RESTRICT` | Denormalized for fast lot queries |
| `lot_design_id` | `TEXT` | `NOT NULL REFERENCES lot_designs(id) ON DELETE RESTRICT` | Parent design |
| `design_colour_id` | `TEXT` | `NOT NULL REFERENCES design_colours(id) ON DELETE RESTRICT` | Atomic SKU unit |
| `process_id` | `TEXT` | `NULL REFERENCES processes(id) ON DELETE RESTRICT` | Required for ISSUE/RETURN/SETTLEMENT; `NULL` for damaged-to-good repair adjustment |
| `member_id` | `TEXT` | `NULL REFERENCES members(id) ON DELETE RESTRICT` | Required for ISSUE/RETURN/SETTLEMENT; `NULL` for internal adjustment |
| `parent_issue_id` | `TEXT` | `NULL REFERENCES stock_movements(id) ON DELETE RESTRICT` | Required for `RETURN_GOOD`, `RETURN_DAMAGED`, `SETTLEMENT_LOST`, `SETTLEMENT_SHORTAGE` |
| `reverses_movement_id` | `TEXT` | `NULL REFERENCES stock_movements(id) ON DELETE RESTRICT` | Populated only for `REVERSAL` rows |
| `client_request_id` | `TEXT` | `NULL` | Optional UUIDv4 idempotency token preventing duplicate form submissions |
| `movement_type` | `TEXT` | `NOT NULL CHECK(IN ('ISSUE','RETURN_GOOD','RETURN_DAMAGED','SETTLEMENT_LOST','SETTLEMENT_SHORTAGE','ADJUSTMENT_DAMAGED_TO_GOOD','REVERSAL'))` | Strict movement discriminator |
| `quantity` | `INTEGER` | `NOT NULL CHECK(quantity > 0)` | Positive piece count |
| `source_rate_id` | `TEXT` | `NULL REFERENCES member_process_rates(id) ON DELETE RESTRICT` | Rate row used at lock time |
| `applied_rate_paise` | `INTEGER` | `NOT NULL DEFAULT 0 CHECK(applied_rate_paise >= 0)` | Locked/effective rate in paise |
| `is_rate_overridden` | `INTEGER` | `NOT NULL DEFAULT 0 CHECK(is_rate_overridden IN (0,1))` | `1` if manually overridden |
| `override_reason` | `TEXT` | `NULL` | Mandatory if `is_rate_overridden = 1` |
| `locked_billing_mode` | `TEXT` | `NULL CHECK(locked_billing_mode IS NULL OR locked_billing_mode IN ('RECEIVED_QTY','GIVEN_QTY'))` | Locked on `ISSUE` & inherited on settlements |
| `locked_include_damaged` | `INTEGER` | `NOT NULL DEFAULT 0 CHECK(locked_include_damaged IN (0,1))` | Locked on `ISSUE` & inherited on settlements |
| `reason` | `TEXT` | `NULL` | Mandatory for `RETURN_DAMAGED`, `SETTLEMENT_LOST`, `SETTLEMENT_SHORTAGE`, `ADJUSTMENT_DAMAGED_TO_GOOD`, `REVERSAL` |
| `notes` | `TEXT` | `NULL` | Optional additional notes |
| `transaction_at` | `INTEGER` | `NOT NULL` | Actual business date/time (UTC) |
| `recorded_at` | `INTEGER` | `NOT NULL` | Device entry timestamp (UTC) |
| `created_by` | `TEXT` | `NULL` | Local operator label |
| `updated_by` | `TEXT` | `NULL` | Local operator label |
| `created_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `updated_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `deleted_at` | `INTEGER` | `NULL` | Soft delete (unused for immutable ledger; kept for schema uniformity) |

*Indexes:*
- `idx_sm_design_colour ON stock_movements(design_colour_id, movement_type)`
- `idx_sm_parent_issue ON stock_movements(parent_issue_id)`
- `idx_sm_member_tx ON stock_movements(member_id, transaction_at DESC)`
- `idx_sm_process_tx ON stock_movements(process_id, transaction_at DESC)`
- `CREATE UNIQUE INDEX idx_sm_single_reversal ON stock_movements(reverses_movement_id) WHERE reverses_movement_id IS NOT NULL;`
- `CREATE UNIQUE INDEX idx_sm_client_request_id ON stock_movements(client_request_id) WHERE client_request_id IS NOT NULL;`

### 2.10 `labour_entries` (Append-Only Labour Ledger)
| Column | SQLite Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | UUIDv7 |
| `stock_movement_id` | `TEXT` | `NOT NULL REFERENCES stock_movements(id) ON DELETE RESTRICT` | Source movement |
| `reverses_labour_entry_id` | `TEXT` | `NULL REFERENCES labour_entries(id) ON DELETE RESTRICT` | Populated only on `REVERSAL` rows |
| `member_id` | `TEXT` | `NOT NULL REFERENCES members(id) ON DELETE RESTRICT` | Earning worker |
| `process_id` | `TEXT` | `NOT NULL REFERENCES processes(id) ON DELETE RESTRICT` | Process performed |
| `lot_id` | `TEXT` | `NOT NULL REFERENCES lots(id) ON DELETE RESTRICT` | For lot cost reporting |
| `basis_type` | `TEXT` | `NOT NULL CHECK(IN ('ISSUED','RECEIVED_GOOD','RECEIVED_DAMAGED','REVERSAL'))` | Clear distinction between issued vs received labour |
| `quantity` | `INTEGER` | `NOT NULL` | Signed on `REVERSAL`, positive otherwise |
| `rate_paise` | `INTEGER` | `NOT NULL CHECK(rate_paise >= 0)` | Rate applied |
| `amount_paise` | `INTEGER` | `NOT NULL` | `quantity * rate_paise` (negative on `REVERSAL`) |
| `is_payable` | `INTEGER` | `NOT NULL CHECK(is_payable IN (0,1))` | `1` = contributes to Earned/Payable Labour; `0` = informational only |
| `transaction_at` | `INTEGER` | `NOT NULL` | Business date/time (UTC) |
| `recorded_at` | `INTEGER` | `NOT NULL` | Entry timestamp (UTC) |
| `created_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `updated_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `deleted_at` | `INTEGER` | `NULL` | Soft delete (unused for immutable ledger) |

*Indexes:*
- `idx_labour_member_payable ON labour_entries(member_id, is_payable, transaction_at DESC)`
- `CREATE UNIQUE INDEX idx_labour_movement_basis_unique ON labour_entries(stock_movement_id, basis_type);` *(prevents duplicate labour entries per movement & basis)*
- `CREATE UNIQUE INDEX idx_labour_single_reversal ON labour_entries(reverses_labour_entry_id) WHERE reverses_labour_entry_id IS NOT NULL;`

### 2.11 `payments` (Append-Only Worker Payments & Advances)
| Column | SQLite Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | UUIDv7 |
| `member_id` | `TEXT` | `NOT NULL REFERENCES members(id) ON DELETE RESTRICT` | Worker |
| `payment_type` | `TEXT` | `NOT NULL CHECK(IN ('REGULAR','ADVANCE','ADVANCE_REFUND','REVERSAL'))` | Payment category |
| `reverses_payment_id` | `TEXT` | `NULL REFERENCES payments(id) ON DELETE RESTRICT` | Populated only on `REVERSAL` |
| `client_request_id` | `TEXT` | `NULL` | Optional UUIDv4 idempotency token preventing duplicate payment submissions |
| `amount_paise` | `INTEGER` | `NOT NULL CHECK(amount_paise > 0)` | Positive amount in paise |
| `payment_mode` | `TEXT` | `NOT NULL CHECK(IN ('CASH','UPI','BANK_TRANSFER','CHEQUE','OTHER'))` | Payment channel |
| `reference_no` | `TEXT` | `NULL` | UPI ref / receipt / cheque no |
| `reason` | `TEXT` | `NULL` | Mandatory on `REVERSAL` |
| `notes` | `TEXT` | `NULL` | Payment notes |
| `transaction_at` | `INTEGER` | `NOT NULL` | Actual payment date/time (UTC) |
| `recorded_at` | `INTEGER` | `NOT NULL` | App entry timestamp (UTC) |
| `created_by` | `TEXT` | `NULL` | Local operator label |
| `updated_by` | `TEXT` | `NULL` | Local operator label |
| `created_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `updated_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `deleted_at` | `INTEGER` | `NULL` | Soft delete (unused for immutable ledger) |

*Indexes:*
- `idx_payments_member_tx ON payments(member_id, transaction_at DESC)`
- `CREATE UNIQUE INDEX idx_payments_single_reversal ON payments(reverses_payment_id) WHERE reverses_payment_id IS NOT NULL;`
- `CREATE UNIQUE INDEX idx_payments_client_request_id ON payments(client_request_id) WHERE client_request_id IS NOT NULL;`

### 2.12 `attachments` (Local Private Media & Photos)
| Column | SQLite Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | UUIDv7 |
| `entity_type` | `TEXT` | `NOT NULL CHECK(IN ('LOT','STOCK_MOVEMENT','PAYMENT','BUSINESS_PROFILE'))` | Owner entity type |
| `entity_id` | `TEXT` | `NOT NULL` | Owner entity UUID |
| `relative_path` | `TEXT` | `NOT NULL` | Path relative to flavor media root (portable across backups) |
| `mime_type` | `TEXT` | `NOT NULL` | e.g., `image/jpeg`, `application/pdf` |
| `file_size_bytes` | `INTEGER` | `NOT NULL` | File size |
| `sha256` | `TEXT` | `NOT NULL` | Integrity checksum for backup/restore |
| `caption` | `TEXT` | `NULL` | Optional photo caption |
| `created_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `updated_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `deleted_at` | `INTEGER` | `NULL` | Soft delete UTC epoch ms |

*Index:* `idx_attachments_entity ON attachments(entity_type, entity_id) WHERE deleted_at IS NULL;`

### 2.13 `audit_logs` (Complete Immutable Audit Trail)
| Column | SQLite Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | UUIDv7 |
| `entity_type` | `TEXT` | `NOT NULL` | Table/domain entity name |
| `entity_id` | `TEXT` | `NOT NULL` | Target record UUID |
| `action_type` | `TEXT` | `NOT NULL CHECK(IN ('CREATE','UPDATE','SOFT_DELETE','DEACTIVATE','REACTIVATE','RATE_OVERRIDE','REVERSAL','DAMAGED_TO_GOOD_ADJUSTMENT','BACKUP_EXPORT','BACKUP_RESTORE'))` | Action performed |
| `actor` | `TEXT` | `NULL` | Local operator label |
| `previous_value_json` | `TEXT` | `NULL` | JSON snapshot before change |
| `new_value_json` | `TEXT` | `NULL` | JSON snapshot after change |
| `reason` | `TEXT` | `NULL` | Mandatory for overrides, settlements, adjustments, reversals |
| `transaction_at` | `INTEGER` | `NOT NULL` | Business timestamp (UTC) |
| `recorded_at` | `INTEGER` | `NOT NULL` | System log timestamp (UTC) |

*Index:* `idx_audit_entity ON audit_logs(entity_type, entity_id, recorded_at DESC);`

---

### 2.14 `worker_ledger_adjustments` (Append-Only Worker Ledger Adjustments — Schema v2)
| Column | SQLite Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `TEXT` | `PRIMARY KEY` | UUIDv7 |
| `member_id` | `TEXT` | `NOT NULL REFERENCES members(id) ON DELETE RESTRICT` | Worker |
| `adjustment_type` | `TEXT` | `NOT NULL CHECK(IN ('CREDIT','DEBIT','REVERSAL'))` | `CREDIT` increases payable, `DEBIT` deducts payable |
| `reverses_adjustment_id` | `TEXT` | `NULL REFERENCES worker_ledger_adjustments(id) ON DELETE RESTRICT` | Populated only on `REVERSAL` |
| `client_request_id` | `TEXT` | `NULL` | Optional UUIDv4 idempotency token |
| `amount_paise` | `INTEGER` | `NOT NULL CHECK(amount_paise > 0)` | Positive amount in paise |
| `reason` | `TEXT` | `NOT NULL CHECK(length(trim(reason)) > 0)` | Mandatory adjustment or reversal reason |
| `notes` | `TEXT` | `NULL` | Optional notes |
| `transaction_at` | `INTEGER` | `NOT NULL` | Business date/time (UTC) |
| `recorded_at` | `INTEGER` | `NOT NULL` | Entry timestamp (UTC) |
| `created_by` | `TEXT` | `NULL` | Local operator label |
| `updated_by` | `TEXT` | `NULL` | Local operator label |
| `created_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `updated_at` | `INTEGER` | `NOT NULL` | UTC epoch ms |
| `deleted_at` | `INTEGER` | `NULL` | Soft delete (unused for immutable ledger) |

*Indexes (v2):*
- `idx_wla_member_tx ON worker_ledger_adjustments(member_id, transaction_at DESC)`
- `CREATE UNIQUE INDEX idx_wla_single_reversal ON worker_ledger_adjustments(reverses_adjustment_id) WHERE reverses_adjustment_id IS NOT NULL;`
- `CREATE UNIQUE INDEX idx_wla_client_request_id ON worker_ledger_adjustments(client_request_id) WHERE client_request_id IS NOT NULL;`
