# 35 — Milestone 6 Implementation Report (Stock Movements)

**Completed Date:** 2026-11-23  
**SDK & Stack Verified:** Flutter `3.50.1` (`stable`) / Dart `3.14.0` / `material_ui: ^1.11.1` / `flutter_bloc: ^9.1.1` / `drift: ^2.35.3`  
**Status:** Complete

---

## 1. Features Implemented

- **Stock Issuing (`ISSUE`):**
  - Select Lot / Design / Colour with live **Available Good Stock** badge.
  - Dynamically select any active Process (zero hardcoded sequences) and only actively assigned, active Workers.
  - Complete IST transaction date & time picker (`AppDatePicker(includeTime: true)`).
  - Historical rate resolution & lock via `MemberProcessRateResolver` (by `transactionAt` in `Asia/Kolkata`), storing `source_rate_id` and `applied_rate_paise` on the movement, with optional audited manual rate override (`RATE_OVERRIDE` audit log + mandatory reason).
  - Locks effective billing mode (`locked_billing_mode`) and damaged labour eligibility (`locked_include_damaged`) on issue creation.
  - Prevents issuing more than `PhysicalAvailableInHouse` inside an atomic SQLite transaction.
- **Partial & Complete Returns / Settlements:**
  - Linked strictly to `parent_issue_id`, supporting multiple partial returns over time.
  - Combined settlement entry supporting `RETURN_GOOD`, `RETURN_DAMAGED`, `SETTLEMENT_LOST`, and `SETTLEMENT_SHORTAGE` in one atomic transaction.
  - Automatically inherits the parent issue's locked rate and billing configuration—never re-evaluating today's rate.
  - Prevents total settled quantity from exceeding remaining pending quantity; mandates non-empty `reason` for damaged, lost, and shortage settlements.
  - Separate stock buckets: only `RETURN_GOOD` increases good physical in-house stock; `RETURN_DAMAGED` enters the Damaged Stock bucket; `SETTLEMENT_LOST` and `SETTLEMENT_SHORTAGE` reduce surviving good stock.
- **Damaged-to-Good Repair Adjustment (`ADJUSTMENT_DAMAGED_TO_GOOD`):**
  - Explicit audited adjustment moving repaired pieces (`<= damagedBucket`) back to good physical stock with mandatory reason, IST timestamp, and `DAMAGED_TO_GOOD_ADJUSTMENT` audit log.
- **Stock History, Views & Reversal Safety:**
  - 5-tab hub (`Pending Issues`, `Live Stock`, `Timeline`, `By Worker`, `By Process`) with search and movement-type filtering.
  - Strictly append-only `StockMovementDao` (zero `UPDATE` or `DELETE` methods).
  - Idempotent submissions via per-form UUIDv4 `client_request_id`.
  - Chronological prefix replay reversal guard (`StockCalculator.validateReversal`) preventing downstream stock corruption or orphaned child settlements.

---

## 2. Architecture & Important Files

- **Domain:**
  - `lib/features/stock_movements/domain/entities/stock_movement_entities.dart`
  - `lib/features/stock_movements/domain/calculators/stock_calculator.dart` (100% pure Dart)
  - `lib/features/stock_movements/domain/repositories/stock_movement_repository.dart`
- **Data:**
  - `lib/core/database/daos/stock_movement_dao.dart` (extended read-only queries; strictly append-only)
  - `lib/features/stock_movements/data/repositories/stock_movement_repository_impl.dart`
- **Presentation:**
  - `lib/features/stock_movements/presentation/bloc/stock_movements_cubit.dart`
  - `lib/features/stock_movements/presentation/pages/stock_movements_page.dart`
  - `lib/features/stock_movements/presentation/pages/stock_issue_page.dart`
  - `lib/features/stock_movements/presentation/pages/stock_settlement_page.dart`
  - `lib/features/stock_movements/presentation/pages/damaged_repair_page.dart`

---

## 3. Database Changes

- Reused v1 `stock_movements` table and all 6 indexes (`idx_sm_design_colour`, `idx_sm_parent_issue`, `idx_sm_member_tx`, `idx_sm_process_tx`, `idx_sm_single_reversal`, `idx_sm_client_request_id`). No destructive alterations.

---

## 4. Business Rules Implemented

- `PhysicalAvailableInHouse = InitialQty - sum(ISSUE) + sum(RETURN_GOOD) + sum(ADJUSTMENT_DAMAGED_TO_GOOD)` over active (non-reversed) movements.
- `DamagedBucket = sum(RETURN_DAMAGED) - sum(ADJUSTMENT_DAMAGED_TO_GOOD)`.
- Atomic 5-point pre-issue check (active worker, active process, active assignment, resolved rate or audited override, sufficient in-house stock).
- Chronological prefix replay blocks any reversal that would drive `PhysicalAvailableInHouse < 0`, `DamagedBucket < 0`, or `ParentRemainingPending < 0` at any historical timestamp.

---

## 5. Packages Added / Removed

- Added `animations: ^3.0.0` and `flutter_animate: ^4.5.2` as part of the centralized StitchFlow UI/UX Design System upgrade (`docs/34_UI_UX_DESIGN_SYSTEM.md`). Zero stock-specific third-party packages added.

---

## 6. Verification & Tests

- Pure Dart calculator unit tests: `test/features/stock_calculator_test.dart`
- Full transactional SQLite workflow & reversal-guard tests: `test/features/end_to_end_business_workflow_test.dart`
- Responsive EN/GU Light/Dark widget tests: `test/widget/milestones_6_to_9_ui_test.dart`
- Verified with `flutter analyze` (0 issues) and full `flutter test` suite (see `docs/39_MILESTONE_10_FINAL_QA_RELEASE_REPORT.md` for final aggregate counts and APK build artifacts).

---

## 7. Known Issues & Limitations

- Bulk multi-colour batch issuing in a single form is intentionally deferred post-V1 to keep single-issue rate locking and validation crystal clear on compact Android phones.

---

## 8. Manual Android Testing Instructions

1. Open **Dashboard → Issue Stock** (or **Stock Movements → Issue Stock**).
2. Select a Lot/Design/Colour, verify **Available Good** badge matches initial quantity, select Process & assigned Worker, verify locked rate preview appears, issue `100` pcs.
3. Verify attempting to issue `1` more piece is blocked.
4. Open **Pending Issues**, tap the issue, enter `80` Good Returned, save, and verify remaining pending is `20` and `80` good pieces are immediately issuable to another process.
5. Settle remaining `20` as `15` Good + `3` Damaged + `2` Lost with a reason; verify damaged bucket shows `3` and **Repair Damaged** can move `2` pieces back to good stock.
6. In **Timeline**, attempt to reverse the `80` Good Return after issuing `80` to the next process—confirm the app blocks it cleanly.
