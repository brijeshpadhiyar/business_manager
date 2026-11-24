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

  /// Batch-fetches all active colours for [designIds] using chunked `IN (...)`
  /// queries (eliminating N+1 reads while staying well below SQLite's 999
  /// parameter limit).
  Future<List<DesignColourRow>> getColoursForDesigns(
    List<String> designIds,
  ) async {
    if (designIds.isEmpty) return const [];
    const chunkSize = 500;
    if (designIds.length <= chunkSize) {
      return (select(designColours)
            ..where((t) => t.lotDesignId.isIn(designIds) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.colourName)]))
          .get();
    }
    final all = <DesignColourRow>[];
    for (var i = 0; i < designIds.length; i += chunkSize) {
      final end = (i + chunkSize > designIds.length)
          ? designIds.length
          : i + chunkSize;
      final chunk = designIds.sublist(i, end);
      final rows =
          await (select(designColours)
                ..where((t) => t.lotDesignId.isIn(chunk) & t.deletedAt.isNull())
                ..orderBy([(t) => OrderingTerm.asc(t.colourName)]))
              .get();
      all.addAll(rows);
    }
    all.sort((a, b) => a.colourName.compareTo(b.colourName));
    return all;
  }

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
