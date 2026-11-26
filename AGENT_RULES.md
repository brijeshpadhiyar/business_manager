# AGENT_RULES.md — Non-Negotiable Architecture & Implementation Guardrails

Any AI coding agent or human engineer operating on this repository **MUST** obey the following rules without exception.

---

## 1. The 12 Non-Negotiable Architectural Constraints

1. **Offline-First Architecture (v1.5+):** All reads and writes MUST hit local Drift SQLite first. Cloud sync with Supabase runs asynchronously via the local `sync_outbox` + delta pull engine and must NEVER block local workflows.
2. **NO Firebase:** Do not add any `firebase_*` or `cloud_firestore` packages.
3. **Supabase Cloud Layer Isolation:** All `supabase_flutter` calls MUST live inside `lib/features/auth/data/` and `lib/features/sync/data/` (never inside UI widgets, BLoCs, or domain calculators).
4. **NO Mandatory Online Sign-In Wall:** The app MUST open and operate 100% offline with zero mandatory sign-in walls. Users may continue offline or sign in with Google / Phone OTP anytime; once signed in, cached sessions work offline indefinitely.
5. **Local SQLite as Primary Source of Truth:** All domain persistence is local SQLite via Drift + local private app files, with Supabase PostgreSQL & Storage acting as the optional cloud replica.
6. **NO Hardcoded Production Processes:** Never hardcode enums, switch cases, or fixed sequences like `Cutting -> Stitching -> Press`. Processes are 100% dynamic rows in `processes`.
7. **NO Hardcoded Member Rates:** All rates live in `member_process_rates` with effective date ranges.
8. **NO Hardcoded User-Facing Strings:** Every UI string must be retrieved via `AppLocalizations` (`app_en.arb` + `app_gu.arb`).
9. **NO Direct Database Access from UI Widgets:** UI widgets and BLoCs must never import Drift DAOs, tables, or `AppDatabase`.
10. **NO Business Calculation Logic Inside BLoCs:** All stock, labour, pricing, and ledger math must be implemented in pure Dart domain calculators/services and unit-tested independently.
11. **NO Direct Stock Quantity Mutation Without Transaction History:** Never update a cached `available_qty` column directly; stock balances are derived from immutable `stock_movements` (and verified inside DB transactions).
12. **NO Silent Historical Transaction Modification:** Never `UPDATE` or hard `DELETE` historical stock movements, labour entries, or payments. Corrections require explicit reversal/adjustment rows and `audit_logs` records.

---

## 2. Confirmed V1 Business Rules (Never Violate)

- **Multi-Process Stock Flow:** Track `issued`, `received`, `pending`, and `available` per process independently without any fixed process order, while enforcing `issue_qty <= PhysicalAvailableInHouse`.
- **Settlement Types:** Always separate `RETURN_GOOD`, `RETURN_DAMAGED`, `SETTLEMENT_LOST`, and `SETTLEMENT_SHORTAGE`. Only `RETURN_GOOD` adds back to good physical stock. Every settlement requires a reason, timestamp, notes, and audit entry.
- **Damaged Stock Bucket:** Track damaged pieces in a dedicated Damaged Stock bucket; never silently convert damaged stock into good stock. Repair/salvage back to good stock is only permitted via an explicit authorized stock adjustment with quantity, reason, date/time, notes, and audit log.
- **Labour Billing:** Default to **Pay on Received Good Quantity** (`RECEIVED_QTY`, `include_damaged_in_labour = false`), configurable globally and per-process. Lock `billing_mode` and `include_damaged_in_labour` on the `ISSUE` transaction at creation time so mid-flight config changes never double-count or skip labour. Lost/shortage pieces never earn labour by default.
- **Historical Rate Lookup & Lock:** Always resolve rates using `transactionAt` converted to `Asia/Kolkata` date (`YYYY-MM-DD`). Lock the resolved rate on the `ISSUE` movement and inherit it automatically on all partial returns. Manual rate override requires explicit confirmation, a reason, and an `audit_logs` diff.
- **Advance Payments:** Allow advance payments and negative pending balances (Advance Credit). Separately expose Earned Labour, Advance Payments, Regular Payments, Outstanding Payable, and Advance Credit Balance.
- **Branding & UI:** Default display names are `Business Manager` (EN) and `બિઝનેસ મેનેજર` (GU), stored configurably. Keep and use Flutter's official decoupled Material 3 package `material_ui: ^1.11.1` (`package:material_ui/material_ui.dart`) as the foundation for our centralized `lib/core/widgets/` library.
- **Backup & Security:** Keep the SQLite DB in private app storage (never public storage). Export raw `.sqlite` or unencrypted full `.zip` backup **only** via explicit user action.

---

## 3. Package & Code Quality Rules

- **Never invent package versions or features.** Consult `docs/04_technology_stack.md` before adding any dependency.
- **Do not add `sqlite3_flutter_libs`** (deprecated; `sqlite3 ^3.9.1` bundles native SQLite via build hooks).
- **Do not add third-party UI kits** (e.g., `getwidget`, `fluent_ui`, etc.); use official `material_ui: ^1.11.1` + centralized `lib/core/widgets/`.
- **Do not skip tests for domain calculators.** Every stock, labour, pricing, advance, and backup rule must have deterministic unit tests as specified in `docs/20_testing_strategy.md`.
- **Flavor Isolation:** Never allow `dev` builds to read or write `prod` database or media directories.
