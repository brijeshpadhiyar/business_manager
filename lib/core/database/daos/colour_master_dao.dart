import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/tables/colour_master_table.dart';
import 'package:drift/drift.dart';

part 'colour_master_dao.g.dart';

/// DAO for the offline-first `colour_master` catalog.
@DriftAccessor(tables: [ColourMasters])
class ColourMasterDao extends DatabaseAccessor<AppDatabase>
    with _$ColourMasterDaoMixin {
  ColourMasterDao(super.db);

  Future<List<ColourMasterRow>> getAllActiveColours() {
    return (select(colourMasters)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<List<ColourMasterRow>> getRecentColours({int limit = 8}) {
    return (select(colourMasters)
          ..where((t) => t.deletedAt.isNull() & t.lastUsedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.lastUsedAt)])
          ..limit(limit))
        .get();
  }

  Future<ColourMasterRow?> findById(String id) =>
      (select(colourMasters)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<ColourMasterRow?> findActiveByLowerName(String lowerName) {
    return (select(colourMasters)..where(
          (t) => t.deletedAt.isNull() & t.name.lower().equals(lowerName),
        ))
        .getSingleOrNull();
  }

  Future<void> insertColour(ColourMastersCompanion entry) =>
      into(colourMasters).insert(entry);

  Future<int> updateColourById(String id, ColourMastersCompanion patch) {
    return (update(colourMasters)..where((t) => t.id.equals(id))).write(patch);
  }
}
