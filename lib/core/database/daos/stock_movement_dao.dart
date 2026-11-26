import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/pagination/page_query.dart';
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

  Future<StockMovementRow?> findReversalForMovement(String movementId) =>
      (select(stockMovements)
            ..where((t) => t.reversesMovementId.equals(movementId)))
          .getSingleOrNull();

  Future<List<StockMovementRow>> getAllMovements() {
    return (select(stockMovements)..orderBy([
          (t) => OrderingTerm.asc(t.transactionAt),
          (t) => OrderingTerm.asc(t.recordedAt),
          (t) => OrderingTerm.asc(t.id),
        ]))
        .get();
  }

  /// O(log N) keyset/cursor pagination over `stock_movements` ordered newest-first
  /// (`transaction_at DESC, id DESC`), accelerated by `idx_sm_tx_type`.
  Future<PagedResult<StockMovementRow>> getMovementsPaged({
    int limit = 50,
    int? cursorTransactionAt,
    String? cursorId,
    String? movementType,
    String? memberId,
    String? lotId,
  }) async {
    Expression<bool> baseFilter($StockMovementsTable t) {
      Expression<bool> expr = const Constant(true);
      if (movementType != null && movementType.isNotEmpty) {
        expr = expr & t.movementType.equals(movementType);
      }
      if (memberId != null && memberId.isNotEmpty) {
        expr = expr & t.memberId.equals(memberId);
      }
      if (lotId != null && lotId.isNotEmpty) {
        expr = expr & t.lotId.equals(lotId);
      }
      return expr;
    }

    final countExp = stockMovements.id.count();
    final countRow = await (selectOnly(stockMovements)
          ..addColumns([countExp])
          ..where(baseFilter(stockMovements)))
        .getSingle();
    final total = countRow.read(countExp) ?? 0;

    final query = select(stockMovements)
      ..where((t) {
        var expr = baseFilter(t);
        if (cursorTransactionAt != null && cursorId != null) {
          expr =
              expr &
              (t.transactionAt.isSmallerThanValue(cursorTransactionAt) |
                  (t.transactionAt.equals(cursorTransactionAt) &
                      t.id.isSmallerThanValue(cursorId)));
        }
        return expr;
      })
      ..orderBy([
        (t) => OrderingTerm.desc(t.transactionAt),
        (t) => OrderingTerm.desc(t.id),
      ])
      ..limit(limit + 1);

    final fetched = await query.get();
    final hasMore = fetched.length > limit;
    final items = hasMore ? fetched.sublist(0, limit) : fetched;
    final last = items.isNotEmpty ? items.last : null;

    return PagedResult<StockMovementRow>(
      items: items,
      totalCount: total,
      hasMore: hasMore,
      nextCursorTransactionAt: last?.transactionAt,
      nextCursorId: last?.id,
    );
  }

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

  Future<List<StockMovementRow>> getMovementsForLot(String lotId) {
    return (select(stockMovements)
          ..where((t) => t.lotId.equals(lotId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.transactionAt),
            (t) => OrderingTerm.asc(t.recordedAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Future<List<StockMovementRow>> getMovementsForMember(String memberId) {
    return (select(stockMovements)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactionAt),
            (t) => OrderingTerm.desc(t.recordedAt),
          ]))
        .get();
  }

  Future<List<StockMovementRow>> getMovementsForProcess(String processId) {
    return (select(stockMovements)
          ..where((t) => t.processId.equals(processId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactionAt),
            (t) => OrderingTerm.desc(t.recordedAt),
          ]))
        .get();
  }

  Future<List<StockMovementRow>> getMovementsByParentIssue(
    String parentIssueId,
  ) {
    return (select(stockMovements)
          ..where((t) => t.parentIssueId.equals(parentIssueId))
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

  /// Bounded read-only date-range query accelerated by `idx_sm_tx_type`.
  Future<List<StockMovementRow>> getMovementsInRange({
    int? fromUtcMillis,
    int? toUtcMillis,
  }) {
    final query = select(stockMovements);
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
      (t) => OrderingTerm.asc(t.transactionAt),
      (t) => OrderingTerm.asc(t.recordedAt),
      (t) => OrderingTerm.asc(t.id),
    ]);
    return query.get();
  }
}
