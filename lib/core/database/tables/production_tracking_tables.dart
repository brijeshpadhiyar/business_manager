import 'package:business_manager/core/database/tables/job_process_tables.dart';
import 'package:business_manager/core/database/tables/ledger_tables.dart';
import 'package:business_manager/core/database/tables/lot_tables.dart';
import 'package:business_manager/core/database/tables/process_member_tables.dart';
import 'package:drift/drift.dart';

/// 2.19 `production_returns` — Immutable worker return receipts (Schema v8).
///
/// Tracks pieces physically returned by a worker against an `ISSUE` assignment,
/// supporting both `PENDING_INSPECTION` (two-stage QC queue) and
/// `IMMEDIATE_INSPECTION` (fast-path return + immediate inspection).
@DataClassName('ProductionReturnRow')
class ProductionReturns extends Table {
  @override
  String get tableName => 'production_returns';

  TextColumn get id => text()();
  TextColumn get clientRequestId => text().nullable()();
  TextColumn get parentIssueId =>
      text().references(StockMovements, #id, onDelete: KeyAction.restrict)();
  TextColumn get jobProcessId => text().nullable().references(
    JobProcesses,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get lotId =>
      text().references(Lots, #id, onDelete: KeyAction.restrict)();
  TextColumn get lotDesignId =>
      text().references(LotDesigns, #id, onDelete: KeyAction.restrict)();
  TextColumn get designColourId =>
      text().references(DesignColours, #id, onDelete: KeyAction.restrict)();
  TextColumn get processId =>
      text().references(Processes, #id, onDelete: KeyAction.restrict)();
  TextColumn get memberId =>
      text().references(Members, #id, onDelete: KeyAction.restrict)();
  IntColumn get returnedQuantity => integer()();
  TextColumn get returnMode =>
      text().withDefault(const Constant('PENDING_INSPECTION'))();
  TextColumn get notes => text().nullable()();
  IntColumn get transactionAt => integer()();
  IntColumn get recordedAt => integer()();
  TextColumn get createdBy => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK(returned_quantity > 0)',
    "CHECK(return_mode IN ('PENDING_INSPECTION', 'IMMEDIATE_INSPECTION'))",
  ];
}

/// 2.20 `production_inspections` — Immutable QC approval / rejection events
/// (Schema v8).
///
/// Every accepted quantity generates earnings strictly as
/// `accepted_quantity * locked_rate_paise` (unless marked as in-house repair
/// with `credit_worker_earnings = 0`). Rejected quantities NEVER generate
/// earnings.
@DataClassName('ProductionInspectionRow')
class ProductionInspections extends Table {
  @override
  String get tableName => 'production_inspections';

  TextColumn get id => text()();
  TextColumn get clientRequestId => text().nullable()();
  TextColumn get inspectionType =>
      text().withDefault(const Constant('INITIAL'))();
  TextColumn get productionReturnId => text().nullable().references(
    ProductionReturns,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get rejectionRecordId => text().nullable()();
  TextColumn get rejectionRepairId => text().nullable()();
  TextColumn get parentIssueId =>
      text().references(StockMovements, #id, onDelete: KeyAction.restrict)();
  TextColumn get jobProcessId => text().nullable().references(
    JobProcesses,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get lotId =>
      text().references(Lots, #id, onDelete: KeyAction.restrict)();
  TextColumn get lotDesignId =>
      text().references(LotDesigns, #id, onDelete: KeyAction.restrict)();
  TextColumn get designColourId =>
      text().references(DesignColours, #id, onDelete: KeyAction.restrict)();
  TextColumn get processId =>
      text().references(Processes, #id, onDelete: KeyAction.restrict)();
  TextColumn get memberId =>
      text().references(Members, #id, onDelete: KeyAction.restrict)();
  IntColumn get acceptedQuantity => integer().withDefault(const Constant(0))();
  IntColumn get rejectedQuantity => integer().withDefault(const Constant(0))();
  IntColumn get lockedRatePaise => integer().withDefault(const Constant(0))();
  IntColumn get earnedAmountPaise => integer().withDefault(const Constant(0))();
  IntColumn get creditWorkerEarnings =>
      integer().withDefault(const Constant(1))();
  TextColumn get linkedGoodMovementId => text().nullable().references(
    StockMovements,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get linkedDamagedMovementId => text().nullable().references(
    StockMovements,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get linkedLabourEntryId => text().nullable().references(
    LabourEntries,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get rejectionReason => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get inspectedBy => text().nullable()();
  TextColumn get approvedBy => text().nullable()();
  IntColumn get authorizedViaPin => integer().withDefault(const Constant(0))();
  IntColumn get transactionAt => integer()();
  IntColumn get recordedAt => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK(inspection_type IN ('INITIAL', 'REINSPECTION'))",
    'CHECK(accepted_quantity >= 0)',
    'CHECK(rejected_quantity >= 0)',
    'CHECK(accepted_quantity + rejected_quantity > 0)',
    'CHECK(locked_rate_paise >= 0)',
    'CHECK(earned_amount_paise >= 0)',
    'CHECK(credit_worker_earnings IN (0, 1))',
    'CHECK(authorized_via_pin IN (0, 1))',
  ];
}

/// 2.21 `rejection_records` — Permanent defect / rejection registry linked to
/// Lot, Worker, Process, Assignment, and Inspection (Schema v8, Rule 3).
@DataClassName('RejectionRecordRow')
class RejectionRecords extends Table {
  @override
  String get tableName => 'rejection_records';

  TextColumn get id => text()();
  TextColumn get lotId =>
      text().references(Lots, #id, onDelete: KeyAction.restrict)();
  TextColumn get lotDesignId =>
      text().references(LotDesigns, #id, onDelete: KeyAction.restrict)();
  TextColumn get designColourId =>
      text().references(DesignColours, #id, onDelete: KeyAction.restrict)();
  TextColumn get processId =>
      text().references(Processes, #id, onDelete: KeyAction.restrict)();
  TextColumn get memberId =>
      text().references(Members, #id, onDelete: KeyAction.restrict)();
  TextColumn get parentIssueId =>
      text().references(StockMovements, #id, onDelete: KeyAction.restrict)();
  TextColumn get jobProcessId => text().nullable().references(
    JobProcesses,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get productionReturnId => text().nullable().references(
    ProductionReturns,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get inspectionId => text().references(
    ProductionInspections,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get stockMovementId =>
      text().references(StockMovements, #id, onDelete: KeyAction.restrict)();
  IntColumn get rejectedQuantity => integer()();
  TextColumn get rejectionReason => text()();
  TextColumn get status => text().withDefault(const Constant('OPEN'))();
  IntColumn get inspectedAt => integer()();
  TextColumn get recordedBy => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK(rejected_quantity > 0)',
    'CHECK(length(trim(rejection_reason)) > 0)',
    "CHECK(status IN ('OPEN', 'PARTIALLY_REPAIRED', 'REPAIRED_PENDING_INSPECTION', 'PARTIALLY_REAPPROVED', 'REAPPROVED', 'SCRAPPED'))",
  ];
}

/// 2.22 `rejection_repairs` — Immutable repair operations on rejected pieces
/// awaiting subsequent reinspection & re-approval (Schema v8, Rule 3).
@DataClassName('RejectionRepairRow')
class RejectionRepairs extends Table {
  @override
  String get tableName => 'rejection_repairs';

  TextColumn get id => text()();
  TextColumn get clientRequestId => text().nullable()();
  TextColumn get rejectionRecordId =>
      text().references(RejectionRecords, #id, onDelete: KeyAction.restrict)();
  TextColumn get lotId =>
      text().references(Lots, #id, onDelete: KeyAction.restrict)();
  TextColumn get designColourId =>
      text().references(DesignColours, #id, onDelete: KeyAction.restrict)();
  TextColumn get processId =>
      text().references(Processes, #id, onDelete: KeyAction.restrict)();
  TextColumn get memberId =>
      text().references(Members, #id, onDelete: KeyAction.restrict)();
  IntColumn get repairedQuantity => integer()();
  TextColumn get repairSource =>
      text().withDefault(const Constant('ORIGINAL_WORKER'))();
  TextColumn get status =>
      text().withDefault(const Constant('PENDING_REINSPECTION'))();
  TextColumn get repairedBy => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get transactionAt => integer()();
  IntColumn get recordedAt => integer()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK(repaired_quantity > 0)',
    "CHECK(repair_source IN ('ORIGINAL_WORKER', 'IN_HOUSE'))",
    "CHECK(status IN ('PENDING_REINSPECTION', 'PARTIALLY_REINSPECTED', 'COMPLETED'))",
  ];
}
