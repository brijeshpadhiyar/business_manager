import 'package:business_manager/core/database/tables/lot_tables.dart';
import 'package:business_manager/core/database/tables/process_member_tables.dart';
import 'package:drift/drift.dart';

/// 2.9 `stock_movements` — Append-only inventory & settlement ledger.
@DataClassName('StockMovementRow')
class StockMovements extends Table {
  @override
  String get tableName => 'stock_movements';

  TextColumn get id => text()();
  TextColumn get lotId =>
      text().references(Lots, #id, onDelete: KeyAction.restrict)();
  TextColumn get lotDesignId =>
      text().references(LotDesigns, #id, onDelete: KeyAction.restrict)();
  TextColumn get designColourId =>
      text().references(DesignColours, #id, onDelete: KeyAction.restrict)();
  TextColumn get processId => text().nullable().references(
    Processes,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get memberId => text().nullable().references(
    Members,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get parentIssueId => text().nullable().references(
    StockMovements,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get jobProcessId => text().nullable()();
  TextColumn get reversesMovementId => text().nullable().references(
    StockMovements,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get clientRequestId => text().nullable()();
  TextColumn get movementType => text()();
  IntColumn get quantity => integer()();
  TextColumn get sourceRateId => text().nullable().references(
    MemberProcessRates,
    #id,
    onDelete: KeyAction.restrict,
  )();
  IntColumn get appliedRatePaise => integer().withDefault(const Constant(0))();
  IntColumn get isRateOverridden => integer().withDefault(const Constant(0))();
  TextColumn get overrideReason => text().nullable()();
  TextColumn get lockedBillingMode => text().nullable()();
  IntColumn get lockedIncludeDamaged =>
      integer().withDefault(const Constant(0))();
  TextColumn get reason => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get transactionAt => integer()();
  IntColumn get recordedAt => integer()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get updatedBy => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK(movement_type IN ('ISSUE', 'RETURN_GOOD', 'RETURN_DAMAGED', 'SETTLEMENT_LOST', 'SETTLEMENT_SHORTAGE', 'ADJUSTMENT_DAMAGED_TO_GOOD', 'REVERSAL'))",
    'CHECK(quantity > 0)',
    'CHECK(applied_rate_paise >= 0)',
    'CHECK(is_rate_overridden IN (0, 1))',
    "CHECK(locked_billing_mode IS NULL OR locked_billing_mode IN ('RECEIVED_QTY', 'GIVEN_QTY'))",
    'CHECK(locked_include_damaged IN (0, 1))',
  ];
}

/// 2.10 `labour_entries` — Append-only labour ledger with strict idempotency.
@DataClassName('LabourEntryRow')
class LabourEntries extends Table {
  @override
  String get tableName => 'labour_entries';

  TextColumn get id => text()();
  TextColumn get stockMovementId =>
      text().references(StockMovements, #id, onDelete: KeyAction.restrict)();
  TextColumn get reversesLabourEntryId => text().nullable().references(
    LabourEntries,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get memberId =>
      text().references(Members, #id, onDelete: KeyAction.restrict)();
  TextColumn get processId =>
      text().references(Processes, #id, onDelete: KeyAction.restrict)();
  TextColumn get lotId =>
      text().references(Lots, #id, onDelete: KeyAction.restrict)();
  TextColumn get basisType => text()();
  IntColumn get quantity => integer()();
  IntColumn get ratePaise => integer()();
  IntColumn get amountPaise => integer()();
  IntColumn get isPayable => integer()();
  IntColumn get transactionAt => integer()();
  IntColumn get recordedAt => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK(basis_type IN ('ISSUED', 'RECEIVED_GOOD', 'RECEIVED_DAMAGED', 'REVERSAL'))",
    'CHECK(rate_paise >= 0)',
    'CHECK(is_payable IN (0, 1))',
  ];
}

/// 2.11 `payments` — Append-only worker regular payments, advances, refunds & reversals.
@DataClassName('PaymentRow')
class Payments extends Table {
  @override
  String get tableName => 'payments';

  TextColumn get id => text()();
  TextColumn get memberId =>
      text().references(Members, #id, onDelete: KeyAction.restrict)();
  TextColumn get paymentType => text()();
  TextColumn get reversesPaymentId => text().nullable().references(
    Payments,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get clientRequestId => text().nullable()();
  IntColumn get amountPaise => integer()();
  TextColumn get paymentMode => text()();
  TextColumn get referenceNo => text().nullable()();
  TextColumn get reason => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get transactionAt => integer()();
  IntColumn get recordedAt => integer()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get updatedBy => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK(payment_type IN ('REGULAR', 'ADVANCE', 'ADVANCE_REFUND', 'REVERSAL'))",
    'CHECK(amount_paise > 0)',
    "CHECK(payment_mode IN ('CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE', 'OTHER'))",
  ];
}

/// 2.14 `worker_ledger_adjustments` — Append-only audited worker ledger
/// adjustments (`CREDIT` increases worker payable, `DEBIT` reduces payable,
/// `REVERSAL` reverses an earlier adjustment). Added in schema v2.
@DataClassName('WorkerLedgerAdjustmentRow')
class WorkerLedgerAdjustments extends Table {
  @override
  String get tableName => 'worker_ledger_adjustments';

  TextColumn get id => text()();
  TextColumn get memberId =>
      text().references(Members, #id, onDelete: KeyAction.restrict)();
  TextColumn get adjustmentType => text()();
  TextColumn get reversesAdjustmentId => text().nullable().references(
    WorkerLedgerAdjustments,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get clientRequestId => text().nullable()();
  IntColumn get amountPaise => integer()();
  TextColumn get reason => text()();
  // Schema v9: traceability for adjustments created from a Routing extra
  // charge / deduction (`process_additional_charges.id`) and its operation.
  TextColumn get sourceChargeId => text().nullable()();
  TextColumn get jobProcessId => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get transactionAt => integer()();
  IntColumn get recordedAt => integer()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get updatedBy => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK(adjustment_type IN ('CREDIT', 'DEBIT', 'REVERSAL'))",
    'CHECK(amount_paise > 0)',
    "CHECK(length(trim(reason)) > 0)",
  ];
}
