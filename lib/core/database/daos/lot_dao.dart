import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/tables/lot_tables.dart';
import 'package:drift/drift.dart';

part 'lot_dao.g.dart';

@DriftAccessor(tables: [Lots, LotDesigns, DesignColours])
class LotDao extends DatabaseAccessor<AppDatabase> with _$LotDaoMixin {
  LotDao(super.db);

  // --- Lots ---
  Future<void> insertLot(LotsCompanion entry) => into(lots).insert(entry);

  Future<LotRow?> findLotById(String id) =>
      (select(lots)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<LotRow>> getActiveLots() =>
      (select(lots)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.transactionAt)]))
          .get();

  Future<int> updateLotById(String id, LotsCompanion entry) =>
      (update(lots)..where((t) => t.id.equals(id))).write(entry);

  Future<int> softDeleteLot(String id, int deletedAtUtcMillis, String? actor) =>
      (update(lots)..where((t) => t.id.equals(id))).write(
        LotsCompanion(
          status: const Value('ARCHIVED'),
          deletedAt: Value(deletedAtUtcMillis),
          updatedAt: Value(deletedAtUtcMillis),
          updatedBy: Value(actor),
        ),
      );

  // --- Lot Designs ---
  Future<void> insertDesign(LotDesignsCompanion entry) =>
      into(lotDesigns).insert(entry);

  Future<LotDesignRow?> findDesignById(String id) =>
      (select(lotDesigns)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<LotDesignRow>> getDesignsForLot(String lotId) =>
      (select(lotDesigns)
            ..where((t) => t.lotId.equals(lotId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.designName)]))
          .get();

  Future<List<LotDesignRow>> getAllActiveDesigns() =>
      (select(lotDesigns)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.designName)]))
          .get();

  Future<int> updateDesignById(String id, LotDesignsCompanion entry) =>
      (update(lotDesigns)..where((t) => t.id.equals(id))).write(entry);

  Future<int> softDeleteDesign(
    String id,
    int deletedAtUtcMillis,
    String? actor,
  ) => (update(lotDesigns)..where((t) => t.id.equals(id))).write(
    LotDesignsCompanion(
      deletedAt: Value(deletedAtUtcMillis),
      updatedAt: Value(deletedAtUtcMillis),
      updatedBy: Value(actor),
    ),
  );

  // --- Design Colours ---
  Future<void> insertDesignColour(DesignColoursCompanion entry) =>
      into(designColours).insert(entry);

  Future<DesignColourRow?> findDesignColourById(String id) =>
      (select(designColours)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<DesignColourRow>> getColoursForDesign(String lotDesignId) =>
      (select(designColours)
            ..where(
              (t) => t.lotDesignId.equals(lotDesignId) & t.deletedAt.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.colourName)]))
          .get();

  Future<List<DesignColourRow>> getAllActiveDesignColours() =>
      (select(designColours)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.colourName)]))
          .get();

  Future<int> updateDesignColourById(String id, DesignColoursCompanion entry) =>
      (update(designColours)..where((t) => t.id.equals(id))).write(entry);

  Future<int> softDeleteDesignColour(
    String id,
    int deletedAtUtcMillis,
    String? actor,
  ) => (update(designColours)..where((t) => t.id.equals(id))).write(
    DesignColoursCompanion(
      deletedAt: Value(deletedAtUtcMillis),
      updatedAt: Value(deletedAtUtcMillis),
      updatedBy: Value(actor),
    ),
  );
}
