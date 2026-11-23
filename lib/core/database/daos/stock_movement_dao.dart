import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/tables/ledger_tables.dart';
import 'package:drift/drift.dart';

part 'stock_movement_dao.g.dart';

/// Strictly append-only DAO for `stock_movements`.
/// Exposes ONLY `INSERT` and `SELECT` operations — never `UPDATE` or `DELETE`.
@DriftAccessor(tables: [StockMovements])
class StockMovementDao extends DatabaseAccessor<AppDatabase>
    with _$StockMovementDaoMixin {
  StockMovementDao(super.db);

  Future<void> insertMovement(StockMovementsCompanion entry) =>
      into(stockMovements).insert(entry);

  Future<StockMovementRow?> findById(String id) =>
      (select(stockMovements)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<StockMovementRow?> findByClientRequestId(String clientRequestId) =>
      (select(stockMovements)
            ..where((t) => t.clientRequestId.equals(clientRequestId)))
          .getSingleOrNull();

  Future<List<StockMovementRow>> getMovementsForDesignColour(
    String designColourId,
  ) {
    return (select(stockMovements)
          ..where((t) => t.designColourId.equals(designColourId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.transactionAt),
            (t) => OrderingTerm.asc(t.recordedAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Future<bool> hasMovementsUsingRate(String rateId) async {
    final row =
        await (select(stockMovements)
              ..where((t) => t.sourceRateId.equals(rateId))
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }
}
