# 22 — Technical Decisions (Architecture Decision Records)

This log captures all major architectural and product-engineering decisions made during Phase 0 discovery so future contributors understand *why* each choice was made.

---

### ADR-001: Drift + `drift_flutter` + `sqlite3 ^3.9.1` (No `sqlite3_flutter_libs`)
- **Context:** Need an offline-first relational SQLite database supporting foreign keys, transactions, migrations, and all 6 Flutter platforms including Web.
- **Decision:** Use `drift ^2.35.3` + `drift_flutter ^0.3.1` + `sqlite3 ^3.9.1`. Do **not** include `sqlite3_flutter_libs` (deprecated in `sqlite3 3.x` in favor of native Dart build hooks).
- **Consequences:** Cleaner build pipeline on Android/iOS/Desktop; Web requires bundling matching `sqlite3.wasm` and `drift_worker.js` in `web/` with OPFS→IndexedDB fallback.

### ADR-002: Integer Paise for All Monetary Values
- **Context:** Garment piece-rates, partial returns, and advances require exact currency math over thousands of transactions.
- **Decision:** Store all prices, rates, labour amounts, and payments as 64-bit `INTEGER` paise (`₹20.50` = `2050`).
- **Consequences:** Zero IEEE-754 floating-point rounding drift; display formatting handled exclusively by `MoneyFormatter`.

### ADR-003: Append-Only Ledger for Stock, Labour & Payments
- **Context:** Silent edits or hard deletes corrupt historical stock counts, worker payables, and auditability.
- **Decision:** `stock_movements`, `labour_entries`, `payments`, and `audit_logs` are strictly append-only. Corrections use explicit `REVERSAL` or `ADJUSTMENT_DAMAGED_TO_GOOD` rows with mandatory reasons.
- **Consequences:** 100% traceability and deterministic recalculation; slightly more complex query aggregation mitigated by composite SQLite indexes.

### ADR-004: Independent Multi-Process Stock Flow + Global Physical Stock Cap
- **Context:** Processes are dynamic and order-agnostic, yet physical inventory cannot be double-issued beyond what is physically in-house.
- **Decision:** Track `issued`, `returned`, `damaged`, `lost`, `shortage`, and `pending` per process independently while enforcing `issue_qty <= PhysicalAvailableInHouse` inside atomic transactions.
- **Consequences:** Supports arbitrary sequences (e.g., 100 → Cutting → 80 return → 80 to Stitching) while strictly preventing phantom stock creation.

### ADR-005: Dedicated Damaged Stock Bucket + Future-Ready Repair Architecture
- **Context:** Damaged returns must reduce worker pending count without polluting good available stock, while keeping V1 simple.
- **Decision:** Separate `RETURN_GOOD`, `RETURN_DAMAGED`, `SETTLEMENT_LOST`, and `SETTLEMENT_SHORTAGE`. Track damaged pieces in a dedicated bucket; allow V1 authorized `ADJUSTMENT_DAMAGED_TO_GOOD` with mandatory reason/audit; defer full repair shop workflow to V2.
- **Consequences:** Clean V1 UX, zero silent stock conversion, zero schema rework if a `repair_orders` module is added later.

### ADR-006: Lock Rate, Billing Mode & Damaged Eligibility on `ISSUE`
- **Context:** Rates and process billing configs can change while batches are still out with workers.
- **Decision:** Resolve rate via `transactionAt` in `Asia/Kolkata` and lock `applied_rate_paise`, `locked_billing_mode` (default `RECEIVED_QTY`), and `locked_include_damaged` (default `false`) on the `ISSUE` row; inherit onto all partial returns. Manual rate overrides require explicit confirmation, reason, and audit log.
- **Consequences:** Guarantees zero retroactive bill corruption and zero double-counting of labour.

### ADR-007: Support Advance Payments & Negative Pending Balances
- **Context:** Workers routinely take cash advances ahead of completing garment batches.
- **Decision:** Model `REGULAR`, `ADVANCE`, `ADVANCE_REFUND`, and `REVERSAL` payments. Expose `OutstandingPayable = max(0, NetBalance)` and `AdvanceCreditBalance = max(0, -NetBalance)`.
- **Consequences:** Real-world karigar accounting works accurately out of the box.

### ADR-008: Official Material 3 Foundation via `material_ui: ^1.11.1`
- **Context:** Starting in Flutter `3.47+`, the Flutter team decoupled Material Design from `package:flutter/material.dart` into the official `material_ui` package (`flutter.dev`), already resolved to `1.11.1` in `pubspec.lock`.
- **Decision:** Keep and pin `material_ui: ^1.11.1` (`package:material_ui/material_ui.dart`) as the official Material 3 foundation across all 6 platforms, and build our centralized design system and reusable widgets (`AppButton`, `AppCard`, `AppText`, `AppScaffold`, `AppTextField`, `AppDropdown`, etc.) cleanly on top of it without adding third-party UI kits or duplicate widget implementations.
- **Consequences:** Stays aligned with official Flutter 3.50+ architecture, benefits from independent Material 3 updates from `flutter.dev`, maintains full Light/Dark & accessibility control, and avoids third-party UI bloat.

### ADR-009: Bundled Noto Sans Gujarati for Offline Cross-Platform L10n
- **Context:** Gujarati script rendering varies across Windows, Linux, and Web when relying on system fonts.
- **Decision:** Bundle Noto Sans Gujarati `.ttf` weights locally and use Flutter's official `gen-l10n` (`app_en.arb` + `app_gu.arb`) with default names `Business Manager` / `બિઝનેસ મેનેજર` stored configurably in `business_profile`.
- **Consequences:** Consistent offline Gujarati rendering across all 6 platforms.

### ADR-010: Private Internal DB + Explicit Unencrypted V1 Exports (`.sqlite` & `.zip`)
- **Context:** Owner needs to inspect raw `.sqlite` files in external viewers and back up data easily on Android without losing access to encrypted keys, while keeping active DB files safe from other apps.
- **Decision:** Keep live DB strictly in private app storage; export raw `.sqlite` (`VACUUM INTO`) and unencrypted full `.zip` backups **only** on explicit user action; defer optional backup encryption and app PIN/biometric lock to post-V1.
- **Consequences:** Safe day-to-day storage, maximum data portability in V1, clear security upgrade path for V2.

### ADR-011: UUIDv7 Primary Keys & UTC Timestamps
- **Context:** App is 100% offline in V1, but future cloud sync should remain possible without schema overhaul.
- **Decision:** Use UUIDv7 `TEXT` primary keys and UTC epoch ms timestamps across all tables, rendering in `Asia/Kolkata` via `timezone`.
- **Consequences:** Time-sortable collision-free IDs and unambiguous timezone math across devices.

### ADR-012: SQLite `WAL` Mode with `PRAGMA synchronous = FULL`
- **Context:** In `WAL` mode, `synchronous = NORMAL` protects against DB corruption but can lose the most recent uncheckpointed commits on sudden Android battery pull or power loss.
- **Decision:** Configure `PRAGMA journal_mode = WAL;` + `PRAGMA synchronous = FULL;` + `PRAGMA foreign_keys = ON;`.
- **Consequences:** Strict ACID durability for every financial/inventory commit at an imperceptible ~2–8 ms background isolate write cost for human-paced single-user workshop traffic.

### ADR-013: Chronological Reversal Dependency Guard & Request Idempotency
- **Context:** Reversing a stock return or damaged-to-good adjustment that already fed downstream movements would corrupt historical inventory continuity; double-taps/retries could duplicate labour entries.
- **Decision:** Enforce chronological prefix replay validation inside atomic reversal transactions, add `UNIQUE(stock_movement_id, basis_type)` on `labour_entries`, and add `client_request_id` unique partial indexes on `stock_movements` and `payments`.
- **Consequences:** Eliminates phantom negative stock, duplicate labour generation, and duplicate submissions at both domain and SQLite constraint layers.
