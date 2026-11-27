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

  Future<LabourEntryRow?> findById(String id) =>
      (select(labourEntries)..where((t) => t.id.equals(id))).getSingleOrNull();

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

  /// True when [issueMovementId] carries a payable, non-reversed `ISSUED`
  /// labour entry. Only legacy (pre-v1.2) `GIVEN_QTY` issues have one; their
  /// settlements must not pay labour a second time.
  Future<bool> issueHasPayableLabour(String issueMovementId) async {
    final rows = await getEntriesForMovement(issueMovementId);
    for (final r in rows) {
      if (r.basisType != 'ISSUED' || r.isPayable != 1) continue;
      if (await findReversalForEntry(r.id) == null) return true;
    }
    return false;
  }

  Future<List<LabourEntryRow>> getEntriesForMovement(String stockMovementId) {
    return (select(
      labourEntries,
    )..where((t) => t.stockMovementId.equals(stockMovementId))).get();
  }
}
