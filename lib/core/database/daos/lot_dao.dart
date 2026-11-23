import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/tables/lot_tables.dart';
import 'package:drift/drift.dart';

part 'lot_dao.g.dart';

@DriftAccessor(tables: [Lots, LotDesigns, DesignColours])
class LotDao extends DatabaseAccessor<AppDatabase> with _$LotDaoMixin {
  LotDao(super.db);

  Future<void> insertLot(LotsCompanion entry) => into(lots).insert(entry);

  Future<LotRow?> findLotById(String id) =>
      (select(lots)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<LotRow>> getActiveLots() =>
      (select(lots)..where((t) => t.deletedAt.isNull())).get();

  Future<void> insertDesign(LotDesignsCompanion entry) =>
      into(lotDesigns).insert(entry);

  Future<List<LotDesignRow>> getDesignsForLot(String lotId) => (select(
    lotDesigns,
  )..where((t) => t.lotId.equals(lotId) & t.deletedAt.isNull())).get();

  Future<void> insertDesignColour(DesignColoursCompanion entry) =>
      into(designColours).insert(entry);

  Future<List<DesignColourRow>> getColoursForDesign(String lotDesignId) =>
      (select(designColours)..where(
            (t) => t.lotDesignId.equals(lotDesignId) & t.deletedAt.isNull(),
          ))
          .get();
}
