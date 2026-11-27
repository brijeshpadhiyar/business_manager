import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/tables/production_tracking_tables.dart';
import 'package:drift/drift.dart';

part 'production_tracking_dao.g.dart';

/// Append-first DAO for Schema v8 production returns, quality inspections,
/// rejection records, and rejection repair operations.
@DriftAccessor(
  tables: [
    ProductionReturns,
    ProductionInspections,
    RejectionRecords,
    RejectionRepairs,
  ],
)
class ProductionTrackingDao extends DatabaseAccessor<AppDatabase>
    with _$ProductionTrackingDaoMixin {
  ProductionTrackingDao(super.db);

  // --- ProductionReturns ---

  Future<void> insertReturn(ProductionReturnsCompanion entry) =>
      into(productionReturns).insert(entry);

  Future<ProductionReturnRow?> findReturnById(String id) => (select(
    productionReturns,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<ProductionReturnRow?> findReturnByClientRequestId(
    String clientRequestId,
  ) => (select(
    productionReturns,
  )..where((t) => t.clientRequestId.equals(clientRequestId))).getSingleOrNull();

  Future<List<ProductionReturnRow>> getAllReturns() {
    return (select(productionReturns)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.asc(t.transactionAt),
            (t) => OrderingTerm.asc(t.recordedAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Future<List<ProductionReturnRow>> getReturnsForIssue(String parentIssueId) {
    return (select(productionReturns)
          ..where(
            (t) => t.parentIssueId.equals(parentIssueId) & t.deletedAt.isNull(),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.transactionAt),
            (t) => OrderingTerm.asc(t.recordedAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Future<List<ProductionReturnRow>> getReturnsForLot(String lotId) {
    return (select(productionReturns)
          ..where((t) => t.lotId.equals(lotId) & t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.asc(t.transactionAt),
            (t) => OrderingTerm.asc(t.recordedAt),
          ]))
        .get();
  }

  // --- ProductionInspections ---

  Future<void> insertInspection(ProductionInspectionsCompanion entry) =>
      into(productionInspections).insert(entry);

  Future<ProductionInspectionRow?> findInspectionById(String id) => (select(
    productionInspections,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<ProductionInspectionRow?> findInspectionByClientRequestId(
    String clientRequestId,
  ) => (select(
    productionInspections,
  )..where((t) => t.clientRequestId.equals(clientRequestId))).getSingleOrNull();

  Future<List<ProductionInspectionRow>> getAllInspections() {
    return (select(productionInspections)..orderBy([
          (t) => OrderingTerm.asc(t.transactionAt),
          (t) => OrderingTerm.asc(t.recordedAt),
          (t) => OrderingTerm.asc(t.id),
        ]))
        .get();
  }

  Future<List<ProductionInspectionRow>> getInspectionsForReturn(
    String productionReturnId,
  ) {
    return (select(productionInspections)
          ..where((t) => t.productionReturnId.equals(productionReturnId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.transactionAt),
            (t) => OrderingTerm.asc(t.recordedAt),
          ]))
        .get();
  }

  Future<List<ProductionInspectionRow>> getInspectionsForIssue(
    String parentIssueId,
  ) {
    return (select(productionInspections)
          ..where((t) => t.parentIssueId.equals(parentIssueId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.transactionAt),
            (t) => OrderingTerm.asc(t.recordedAt),
          ]))
        .get();
  }

  Future<List<ProductionInspectionRow>> getInspectionsForRepair(
    String rejectionRepairId,
  ) {
    return (select(productionInspections)
          ..where((t) => t.rejectionRepairId.equals(rejectionRepairId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.transactionAt),
            (t) => OrderingTerm.asc(t.recordedAt),
          ]))
        .get();
  }

  Future<List<ProductionInspectionRow>> getInspectionsForLot(String lotId) {
    return (select(productionInspections)
          ..where((t) => t.lotId.equals(lotId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.transactionAt),
            (t) => OrderingTerm.asc(t.recordedAt),
          ]))
        .get();
  }

  // --- RejectionRecords ---

  Future<void> insertRejectionRecord(RejectionRecordsCompanion entry) =>
      into(rejectionRecords).insert(entry);

  Future<RejectionRecordRow?> findRejectionById(String id) => (select(
    rejectionRecords,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<RejectionRecordRow>> getAllRejections() {
    return (select(rejectionRecords)..orderBy([
          (t) => OrderingTerm.desc(t.inspectedAt),
          (t) => OrderingTerm.desc(t.createdAt),
        ]))
        .get();
  }

  Future<int> updateRejectionStatus(
    String id, {
    required String status,
    required int updatedAt,
  }) {
    return (update(rejectionRecords)..where((t) => t.id.equals(id))).write(
      RejectionRecordsCompanion(
        status: Value(status),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  // --- RejectionRepairs ---

  Future<void> insertRejectionRepair(RejectionRepairsCompanion entry) =>
      into(rejectionRepairs).insert(entry);

  Future<RejectionRepairRow?> findRepairById(String id) => (select(
    rejectionRepairs,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<RejectionRepairRow?> findRepairByClientRequestId(
    String clientRequestId,
  ) => (select(
    rejectionRepairs,
  )..where((t) => t.clientRequestId.equals(clientRequestId))).getSingleOrNull();

  Future<List<RejectionRepairRow>> getAllRepairs() {
    return (select(rejectionRepairs)..orderBy([
          (t) => OrderingTerm.desc(t.transactionAt),
          (t) => OrderingTerm.desc(t.recordedAt),
        ]))
        .get();
  }

  Future<List<RejectionRepairRow>> getRepairsForRejection(
    String rejectionRecordId,
  ) {
    return (select(rejectionRepairs)
          ..where((t) => t.rejectionRecordId.equals(rejectionRecordId))
          ..orderBy([(t) => OrderingTerm.asc(t.transactionAt)]))
        .get();
  }

  /// Repaired pieces of [designColourId] that are still waiting for
  /// re-inspection. They are still in the Damaged bucket but reserved for an
  /// open repair, so no other repair flow may move them to good stock.
  Future<int> pendingReinspectionQtyForColour(String designColourId) async {
    final row = await customSelect(
      'SELECT COALESCE(SUM(MAX(r.repaired_quantity - COALESCE(('
      '  SELECT SUM(i.accepted_quantity + i.rejected_quantity)'
      '  FROM production_inspections i WHERE i.rejection_repair_id = r.id'
      '), 0), 0)), 0) AS pending '
      'FROM rejection_repairs r WHERE r.design_colour_id = ?',
      variables: [Variable.withString(designColourId)],
      readsFrom: {rejectionRepairs, productionInspections},
    ).getSingle();
    return row.read<int>('pending');
  }

  Future<int> updateRepairStatus(
    String id, {
    required String status,
    required int updatedAt,
  }) {
    return (update(rejectionRepairs)..where((t) => t.id.equals(id))).write(
      RejectionRepairsCompanion(
        status: Value(status),
        updatedAt: Value(updatedAt),
      ),
    );
  }
}
