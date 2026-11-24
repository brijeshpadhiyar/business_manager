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

  Future<ProductionReturnRow?> findReturnById(String id) =>
      (select(productionReturns)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<ProductionReturnRow?> findReturnByClientRequestId(
    String clientRequestId,
  ) =>
      (select(productionReturns)
            ..where((t) => t.clientRequestId.equals(clientRequestId)))
          .getSingleOrNull();

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
            (t) =>
                t.parentIssueId.equals(parentIssueId) & t.deletedAt.isNull(),
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

  Future<List<ProductionReturnRow>> getReturnsForMember(String memberId) {
    return (select(productionReturns)
          ..where((t) => t.memberId.equals(memberId) & t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactionAt),
            (t) => OrderingTerm.desc(t.recordedAt),
          ]))
        .get();
  }

  Future<List<ProductionReturnRow>> getReturnsForProcess(String processId) {
    return (select(productionReturns)
          ..where((t) => t.processId.equals(processId) & t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactionAt),
            (t) => OrderingTerm.desc(t.recordedAt),
          ]))
        .get();
  }

  // --- ProductionInspections ---

  Future<void> insertInspection(ProductionInspectionsCompanion entry) =>
      into(productionInspections).insert(entry);

  Future<ProductionInspectionRow?> findInspectionById(String id) =>
      (select(productionInspections)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<ProductionInspectionRow?> findInspectionByClientRequestId(
    String clientRequestId,
  ) =>
      (select(productionInspections)
            ..where((t) => t.clientRequestId.equals(clientRequestId)))
          .getSingleOrNull();

  Future<List<ProductionInspectionRow>> getAllInspections() {
    return (select(productionInspections)
          ..orderBy([
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

  Future<List<ProductionInspectionRow>> getInspectionsForMember(
    String memberId,
  ) {
    return (select(productionInspections)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactionAt),
            (t) => OrderingTerm.desc(t.recordedAt),
          ]))
        .get();
  }

  Future<List<ProductionInspectionRow>> getInspectionsForProcess(
    String processId,
  ) {
    return (select(productionInspections)
          ..where((t) => t.processId.equals(processId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactionAt),
            (t) => OrderingTerm.desc(t.recordedAt),
          ]))
        .get();
  }

  // --- RejectionRecords ---

  Future<void> insertRejectionRecord(RejectionRecordsCompanion entry) =>
      into(rejectionRecords).insert(entry);

  Future<RejectionRecordRow?> findRejectionById(String id) =>
      (select(rejectionRecords)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<List<RejectionRecordRow>> getAllRejections() {
    return (select(rejectionRecords)
          ..orderBy([
            (t) => OrderingTerm.desc(t.inspectedAt),
            (t) => OrderingTerm.desc(t.createdAt),
          ]))
        .get();
  }

  Future<List<RejectionRecordRow>> getRejectionsForLot(String lotId) {
    return (select(rejectionRecords)
          ..where((t) => t.lotId.equals(lotId))
          ..orderBy([(t) => OrderingTerm.asc(t.inspectedAt)]))
        .get();
  }

  Future<List<RejectionRecordRow>> getRejectionsForMember(String memberId) {
    return (select(rejectionRecords)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([(t) => OrderingTerm.desc(t.inspectedAt)]))
        .get();
  }

  Future<List<RejectionRecordRow>> getRejectionsForProcess(String processId) {
    return (select(rejectionRecords)
          ..where((t) => t.processId.equals(processId))
          ..orderBy([(t) => OrderingTerm.desc(t.inspectedAt)]))
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

  Future<RejectionRepairRow?> findRepairById(String id) =>
      (select(rejectionRepairs)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<RejectionRepairRow?> findRepairByClientRequestId(
    String clientRequestId,
  ) =>
      (select(rejectionRepairs)
            ..where((t) => t.clientRequestId.equals(clientRequestId)))
          .getSingleOrNull();

  Future<List<RejectionRepairRow>> getAllRepairs() {
    return (select(rejectionRepairs)
          ..orderBy([
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

  Future<List<RejectionRepairRow>> getRepairsForLot(String lotId) {
    return (select(rejectionRepairs)
          ..where((t) => t.lotId.equals(lotId))
          ..orderBy([(t) => OrderingTerm.asc(t.transactionAt)]))
        .get();
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
