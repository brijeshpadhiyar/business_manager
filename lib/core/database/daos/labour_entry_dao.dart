import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/tables/ledger_tables.dart';
import 'package:drift/drift.dart';

part 'labour_entry_dao.g.dart';

/// Strictly append-only DAO for `labour_entries`.
/// Exposes ONLY `INSERT` and `SELECT` operations — never `UPDATE` or `DELETE`.
@DriftAccessor(tables: [LabourEntries])
class LabourEntryDao extends DatabaseAccessor<AppDatabase>
    with _$LabourEntryDaoMixin {
  LabourEntryDao(super.db);

  Future<void> insertEntry(LabourEntriesCompanion entry) =>
      into(labourEntries).insert(entry);

  Future<LabourEntryRow?> findReversalForEntry(String entryId) => (select(
    labourEntries,
  )..where((t) => t.reversesLabourEntryId.equals(entryId))).getSingleOrNull();

  Future<List<LabourEntryRow>> getAllEntries() {
    return (select(labourEntries)..orderBy([
          (t) => OrderingTerm.desc(t.transactionAt),
          (t) => OrderingTerm.desc(t.recordedAt),
        ]))
        .get();
  }

  Future<List<LabourEntryRow>> getEntriesForMember(String memberId) {
    return (select(labourEntries)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactionAt),
            (t) => OrderingTerm.desc(t.recordedAt),
          ]))
        .get();
  }

  Future<List<LabourEntryRow>> getEntriesForMovement(String stockMovementId) {
    return (select(
      labourEntries,
    )..where((t) => t.stockMovementId.equals(stockMovementId))).get();
  }

  /// Bounded read-only date-range query accelerated by `idx_labour_tx_payable`.
  Future<List<LabourEntryRow>> getEntriesInRange({
    int? fromUtcMillis,
    int? toUtcMillis,
  }) {
    final query = select(labourEntries);
    if (fromUtcMillis != null && toUtcMillis != null) {
      query.where(
        (t) =>
            t.transactionAt.isBiggerOrEqualValue(fromUtcMillis) &
            t.transactionAt.isSmallerOrEqualValue(toUtcMillis),
      );
    } else if (fromUtcMillis != null) {
      query.where((t) => t.transactionAt.isBiggerOrEqualValue(fromUtcMillis));
    } else if (toUtcMillis != null) {
      query.where((t) => t.transactionAt.isSmallerOrEqualValue(toUtcMillis));
    }
    query.orderBy([
      (t) => OrderingTerm.desc(t.transactionAt),
      (t) => OrderingTerm.desc(t.recordedAt),
    ]);
    return query.get();
  }
}
