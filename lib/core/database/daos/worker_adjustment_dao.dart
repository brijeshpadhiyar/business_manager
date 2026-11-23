import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/tables/ledger_tables.dart';
import 'package:drift/drift.dart';

part 'worker_adjustment_dao.g.dart';

/// Strictly append-only DAO for `worker_ledger_adjustments`.
/// Exposes ONLY `INSERT` and `SELECT` operations — never `UPDATE` or `DELETE`.
@DriftAccessor(tables: [WorkerLedgerAdjustments])
class WorkerAdjustmentDao extends DatabaseAccessor<AppDatabase>
    with _$WorkerAdjustmentDaoMixin {
  WorkerAdjustmentDao(super.db);

  Future<void> insertAdjustment(WorkerLedgerAdjustmentsCompanion entry) =>
      into(workerLedgerAdjustments).insert(entry);

  Future<WorkerLedgerAdjustmentRow?> findById(String id) => (select(
    workerLedgerAdjustments,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<WorkerLedgerAdjustmentRow?> findByClientRequestId(
    String clientRequestId,
  ) => (select(
    workerLedgerAdjustments,
  )..where((t) => t.clientRequestId.equals(clientRequestId))).getSingleOrNull();

  Future<WorkerLedgerAdjustmentRow?> findReversalForAdjustment(
    String adjustmentId,
  ) =>
      (select(workerLedgerAdjustments)
            ..where((t) => t.reversesAdjustmentId.equals(adjustmentId)))
          .getSingleOrNull();

  Future<List<WorkerLedgerAdjustmentRow>> getAdjustmentsForMember(
    String memberId,
  ) {
    return (select(workerLedgerAdjustments)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactionAt),
            (t) => OrderingTerm.desc(t.recordedAt),
          ]))
        .get();
  }

  Future<List<WorkerLedgerAdjustmentRow>> getAllAdjustments() {
    return (select(workerLedgerAdjustments)..orderBy([
          (t) => OrderingTerm.desc(t.transactionAt),
          (t) => OrderingTerm.desc(t.recordedAt),
        ]))
        .get();
  }
}
