import 'package:business_manager/core/database/tables/ledger_tables.dart';
import 'package:business_manager/core/database/tables/lot_tables.dart';
import 'package:business_manager/core/database/tables/process_member_tables.dart';
import 'package:drift/drift.dart';

/// 2.15 `job_processes` — Unlimited flexible operations per Job (Lot + SKU)
/// with immutable dynamic pricing snapshots (`defaultRatePaise`,
/// `agreedRatePaise`, `pricingUnit`, `rateOverrideReason`) and payment tracking.
@DataClassName('JobProcessRow')
class JobProcesses extends Table {
  @override
  String get tableName => 'job_processes';

  TextColumn get id => text()();
  TextColumn get lotId =>
      text().references(Lots, #id, onDelete: KeyAction.restrict)();
  TextColumn get lotDesignId =>
      text().references(LotDesigns, #id, onDelete: KeyAction.restrict)();
  TextColumn get designColourId =>
      text().references(DesignColours, #id, onDelete: KeyAction.restrict)();
  TextColumn get processId =>
      text().references(Processes, #id, onDelete: KeyAction.restrict)();
  TextColumn get memberId => text().nullable().references(
    Members,
    #id,
    onDelete: KeyAction.restrict,
  )();
  IntColumn get sequenceOrder => integer().withDefault(const Constant(1))();
  IntColumn get plannedQuantity => integer()();
  IntColumn get dispatchedQuantity =>
      integer().withDefault(const Constant(0))();
  IntColumn get receivedQuantity => integer().withDefault(const Constant(0))();
  IntColumn get returnedToFactoryQuantity =>
      integer().withDefault(const Constant(0))();
  IntColumn get transferredOutQuantity =>
      integer().withDefault(const Constant(0))();
  IntColumn get damagedQuantity => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('DRAFT'))();
  TextColumn get sourceJobProcessId => text().nullable().references(
    JobProcesses,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get linkedIssueMovementId => text().nullable().references(
    StockMovements,
    #id,
    onDelete: KeyAction.restrict,
  )();
  // Schema v5 dynamic pricing snapshot & payment tracking columns
  IntColumn get defaultRatePaise => integer().withDefault(const Constant(0))();
  IntColumn get agreedRatePaise => integer().withDefault(const Constant(0))();
  TextColumn get pricingUnit =>
      text().withDefault(const Constant('PER_PIECE'))();
  TextColumn get rateOverrideReason => text().nullable()();
  IntColumn get payableAmountPaise =>
      integer().withDefault(const Constant(0))();
  IntColumn get paidAmountPaise => integer().withDefault(const Constant(0))();
  TextColumn get paymentStatus =>
      text().withDefault(const Constant('PENDING'))();
  TextColumn get notes => text().nullable()();
  IntColumn get transactionAt => integer()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get updatedBy => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK(planned_quantity > 0)',
    'CHECK(dispatched_quantity >= 0)',
    'CHECK(received_quantity >= 0)',
    'CHECK(returned_to_factory_quantity >= 0)',
    'CHECK(transferred_out_quantity >= 0)',
    'CHECK(damaged_quantity >= 0)',
    'CHECK(default_rate_paise >= 0)',
    'CHECK(agreed_rate_paise >= 0)',
    'CHECK(payable_amount_paise >= 0)',
    'CHECK(paid_amount_paise >= 0)',
    "CHECK(status IN ('DRAFT', 'PENDING', 'DISPATCHED', 'IN_PROGRESS', 'PARTIALLY_COMPLETED', 'COMPLETED', 'PARTIALLY_RETURNED', 'RETURNED', 'TRANSFERRED', 'CANCELLED'))",
    "CHECK(payment_status IN ('PENDING', 'PARTIALLY_PAID', 'PAID'))",
  ];
}

/// 2.16 `process_handovers` — Immutable chronological movement & transfer
/// ledger for factory dispatches, direct worker-to-worker transfers, factory
/// returns, reassignments, and cancellations. Added in schema v4.
@DataClassName('ProcessHandoverRow')
class ProcessHandovers extends Table {
  @override
  String get tableName => 'process_handovers';

  TextColumn get id => text()();
  TextColumn get transferReference => text()();
  TextColumn get clientRequestId => text().nullable()();
  TextColumn get lotId =>
      text().references(Lots, #id, onDelete: KeyAction.restrict)();
  TextColumn get lotDesignId =>
      text().references(LotDesigns, #id, onDelete: KeyAction.restrict)();
  TextColumn get designColourId =>
      text().references(DesignColours, #id, onDelete: KeyAction.restrict)();
  TextColumn get handoverType => text()();
  TextColumn get fromJobProcessId => text().nullable().references(
    JobProcesses,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get toJobProcessId => text().nullable().references(
    JobProcesses,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get fromMemberId => text().nullable().references(
    Members,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get toMemberId => text().nullable().references(
    Members,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get processId =>
      text().references(Processes, #id, onDelete: KeyAction.restrict)();
  IntColumn get quantityDispatched => integer()();
  IntColumn get quantityReceived => integer().withDefault(const Constant(0))();
  TextColumn get status =>
      text().withDefault(const Constant('PENDING_RECEIPT'))();
  TextColumn get linkedStockMovementId => text().nullable().references(
    StockMovements,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get notes => text().nullable()();
  IntColumn get transactionAt => integer()();
  IntColumn get recordedAt => integer()();
  TextColumn get createdBy => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK(handover_type IN ('FACTORY_DISPATCH', 'DIRECT_TRANSFER', 'FACTORY_RETURN', 'REASSIGNMENT', 'CANCELLATION'))",
    'CHECK(quantity_dispatched >= 0)',
    'CHECK(quantity_received >= 0)',
    'CHECK(quantity_received <= quantity_dispatched)',
    "CHECK(status IN ('PENDING_RECEIPT', 'PARTIALLY_RECEIVED', 'RECEIVED', 'CANCELLED'))",
  ];
}

/// 2.17 `process_additional_charges` — Process-specific extra charges (urgent
/// work, special cutting) and deductions linked to a Job operation. Added in v5.
@DataClassName('ProcessAdditionalChargeRow')
class ProcessAdditionalCharges extends Table {
  @override
  String get tableName => 'process_additional_charges';

  TextColumn get id => text()();
  TextColumn get jobProcessId =>
      text().references(JobProcesses, #id, onDelete: KeyAction.restrict)();
  TextColumn get lotId =>
      text().references(Lots, #id, onDelete: KeyAction.restrict)();
  TextColumn get designColourId =>
      text().references(DesignColours, #id, onDelete: KeyAction.restrict)();
  TextColumn get memberId =>
      text().references(Members, #id, onDelete: KeyAction.restrict)();
  TextColumn get chargeType => text()();
  TextColumn get description => text()();
  IntColumn get amountPaise => integer()();
  TextColumn get clientRequestId => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  IntColumn get transactionAt => integer()();
  IntColumn get createdAt => integer()();
  // Schema v9: the worker_ledger_adjustments row that carries this charge into
  // the worker ledger (set for new charges and by the v8 -> v9 migration).
  TextColumn get ledgerAdjustmentId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK(charge_type IN ('EXTRA_CHARGE', 'DEDUCTION'))",
    'CHECK(amount_paise > 0)',
    'CHECK(length(trim(description)) > 0)',
  ];
}

/// 2.18 `process_rate_history` — Immutable audit log of default process rate
/// changes and per-assignment rate overrides. Added in schema v5.
@DataClassName('ProcessRateHistoryRow')
class ProcessRateHistories extends Table {
  @override
  String get tableName => 'process_rate_history';

  TextColumn get id => text()();
  TextColumn get scope => text()();
  TextColumn get processId =>
      text().references(Processes, #id, onDelete: KeyAction.restrict)();
  TextColumn get jobProcessId => text().nullable().references(
    JobProcesses,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get memberId => text().nullable().references(
    Members,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get designColourId => text().nullable().references(
    DesignColours,
    #id,
    onDelete: KeyAction.restrict,
  )();
  IntColumn get previousRatePaise => integer()();
  IntColumn get newRatePaise => integer()();
  TextColumn get pricingUnit => text()();
  TextColumn get reason => text()();
  TextColumn get changedBy => text().nullable()();
  IntColumn get changedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK(scope IN ('PROCESS_DEFAULT', 'JOB_ASSIGNMENT'))",
    'CHECK(previous_rate_paise >= 0)',
    'CHECK(new_rate_paise >= 0)',
    'CHECK(length(trim(reason)) > 0)',
  ];
}
