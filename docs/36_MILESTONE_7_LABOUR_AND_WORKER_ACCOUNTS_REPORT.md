# 36 — Milestone 7 Implementation Report (Labour, Worker Ledger & Payments)

**Completed Date:** 2026-11-23  
**SDK & Stack Verified:** Flutter `3.50.1` (`stable`) / Dart `3.14.0` / `material_ui: ^1.11.1` / `flutter_bloc: ^9.1.1` / `drift: ^2.35.3`  
**Status:** Complete

---

## 1. Features Implemented

- **Deterministic Labour Calculation (`LabourCalculator`):**
  - Supports **Pay on Received Quantity** (`RECEIVED_QTY`, global default) and **Pay on Given Quantity** (`GIVEN_QTY`).
  - Supports per-process billing override (`processes.billing_mode_override`) and per-process damaged inclusion (`processes.include_damaged_in_labour`, default `false`).
  - Excludes `SETTLEMENT_LOST` and `SETTLEMENT_SHORTAGE` from labour by default.
  - Always uses the original locked `ISSUE` rate (`applied_rate_paise`) and locked billing config (`locked_billing_mode`, `locked_include_damaged`) across all partial returns—preventing double-counting or silent recalculation.
  - Automatically generates offsetting negative `REVERSAL` labour rows inside the same atomic transaction whenever a stock movement is reversed.
- **Worker Ledger (`LedgerCalculator` + `WorkerLedgerPage`):**
  - Displays Earned Labour, Advances Paid, Regular Payments, Advance Refunds, Audited Adjustments (`CREDIT`/`DEBIT`), Outstanding Payable, and Advance Credit Balance separately.
  - Explicitly supports **negative net balances** (Advance Credit carried forward) and **never** counts advances as earned labour.
  - Chronological ledger with exact running balance (`runningBalancePaise`) on every line, IST date-range filters, and exact opening balance calculation when filtered.
- **Payments, Advances & Audited Adjustments:**
  - Full and partial `REGULAR`, `ADVANCE`, and `ADVANCE_REFUND` payments with payment date/time (IST), payment mode (`CASH`, `UPI`, `BANK_TRANSFER`, `CHEQUE`, `OTHER`), reference/receipt number, notes, and `client_request_id` idempotency.
  - Audited worker ledger adjustments (`CREDIT` / `DEBIT`) requiring a mandatory reason.
  - Strictly append-only posted records with audited reversals (single-reversal partial unique indexes).

---

## 2. Architecture & Important Files

- **Domain:**
  - `lib/features/accounting/domain/entities/accounting_entities.dart`
  - `lib/features/accounting/domain/calculators/labour_calculator.dart` (100% pure Dart)
  - `lib/features/accounting/domain/calculators/ledger_calculator.dart` (100% pure Dart)
  - `lib/features/accounting/domain/repositories/accounting_repository.dart`
- **Data:**
  - `lib/core/database/tables/ledger_tables.dart` (added `WorkerLedgerAdjustments` in v2)
  - `lib/core/database/daos/worker_adjustment_dao.dart` (append-only)
  - `lib/core/database/daos/labour_entry_dao.dart` & `payment_dao.dart` (append-only)
  - `lib/features/accounting/data/repositories/accounting_repository_impl.dart`
- **Presentation:**
  - `lib/features/accounting/presentation/bloc/{accounting_overview_cubit.dart, worker_ledger_cubit.dart}`
  - `lib/features/accounting/presentation/pages/{accounting_overview_page.dart, worker_ledger_page.dart, payment_form_page.dart, worker_adjustment_form_page.dart}`

---

## 3. Database Changes (Schema `v1 → v2` Additive Migration)

- Incremented `DatabaseMigrationManager.currentSchemaVersion` from `1` to `2`.
- Added strictly additive, append-only table `worker_ledger_adjustments` (`id`, `member_id`, `adjustment_type`, `reverses_adjustment_id`, `client_request_id`, `amount_paise`, `reason`, `notes`, `transaction_at`, `recorded_at`, `created_by`, `updated_by`, `created_at`, `updated_at`, `deleted_at`) plus 3 indexes (`idx_wla_member_tx`, `idx_wla_single_reversal`, `idx_wla_client_request_id`).
- Zero alterations to existing v1 tables. Verified via automated file-backed `v1 → v2` migration test in `test/database/app_database_persistence_migration_test.dart`.

---

## 4. Business Rules Implemented

- All monetary math uses integer paise (`₹20.00 = 2000`).
- `NetPaidToWorker = RegularPayments + AdvancePayments - AdvanceRefunds`.
- `NetBalance = EarnedLabour + AdjustmentCredits - AdjustmentDebits - NetPaidToWorker`.
- `OutstandingPayable = max(0, NetBalance)`; `AdvanceCreditBalance = max(0, -NetBalance)`.

---

## 5. Packages Added / Removed

- None added for Milestone 7.

---

## 6. Verification & Tests

- Pure Dart labour & ledger unit tests: `test/features/labour_and_ledger_calculator_test.dart`
- Transactional E2E verification (rate lock across Dec 1 hike, advances, regular payments, credit adjustments): `test/features/end_to_end_business_workflow_test.dart`
- Real file-backed `v1 → v2` migration test: `test/database/app_database_persistence_migration_test.dart`
- UI tests in EN/GU & Light/Dark: `test/widget/milestones_6_to_9_ui_test.dart`

---

## 7. Known Issues & Limitations

- Receipt image attachment picker on payments is schema-ready (`attachments.entity_type = 'PAYMENT'`) and deferred to post-V1 to keep payment recording ultra-fast.

---

## 8. Manual Android Testing Instructions

1. Record an **Advance Payment** of `₹1,000` for a worker with zero labour; open **Worker Ledger** and verify **Earned Labour = ₹0.00**, **Advance Credit = ₹1,000.00**, **Outstanding Payable = ₹0.00**.
2. Issue `100` pcs at `₹20` and return `80` good pcs; verify **Earned Labour = ₹1,600.00** and **Outstanding Payable = ₹600.00** (advance automatically offset).
3. Record a `₹600` **Regular Payment** via UPI with a reference number; verify balance settles to `₹0.00`.
4. Test reversing a payment with a mandatory reason and verify the balance restores cleanly with a `Reversed` badge.
