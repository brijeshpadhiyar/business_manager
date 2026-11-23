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

  Future<List<LabourEntryRow>> getEntriesForMember(String memberId) {
    return (select(labourEntries)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionAt)]))
        .get();
  }

  Future<List<LabourEntryRow>> getEntriesForMovement(String stockMovementId) {
    return (select(labourEntries)
          ..where((t) => t.stockMovementId.equals(stockMovementId)))
        .get();
  }
}
