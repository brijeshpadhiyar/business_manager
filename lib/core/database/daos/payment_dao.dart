import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/pagination/page_query.dart';
import 'package:business_manager/core/database/tables/ledger_tables.dart';
import 'package:drift/drift.dart';

part 'payment_dao.g.dart';

/// Strictly append-only DAO for `payments`.
/// Exposes ONLY `INSERT` and `SELECT` operations — never `UPDATE` or `DELETE`.
@DriftAccessor(tables: [Payments])
class PaymentDao extends DatabaseAccessor<AppDatabase> with _$PaymentDaoMixin {
  PaymentDao(super.db);

  Future<void> insertPayment(PaymentsCompanion entry) =>
      into(payments).insert(entry);

  Future<PaymentRow?> findById(String id) =>
      (select(payments)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<PaymentRow?> findByClientRequestId(String clientRequestId) => (select(
    payments,
  )..where((t) => t.clientRequestId.equals(clientRequestId))).getSingleOrNull();

  Future<PaymentRow?> findReversalForPayment(String paymentId) => (select(
    payments,
  )..where((t) => t.reversesPaymentId.equals(paymentId))).getSingleOrNull();

  Future<List<PaymentRow>> getAllPayments() {
    return (select(payments)..orderBy([
          (t) => OrderingTerm.desc(t.transactionAt),
          (t) => OrderingTerm.desc(t.recordedAt),
        ]))
        .get();
  }

  Future<List<PaymentRow>> getPaymentsForMember(String memberId) {
    return (select(payments)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactionAt),
            (t) => OrderingTerm.desc(t.recordedAt),
          ]))
        .get();
  }

  /// Bounded read-only date-range query accelerated by `idx_payments_tx`.
  Future<List<PaymentRow>> getPaymentsInRange({
    int? fromUtcMillis,
    int? toUtcMillis,
  }) {
    final query = select(payments);
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

  /// Indexed SQLite `LIMIT`/`OFFSET` pagination for payments & worker ledgers.
  Future<PagedResult<PaymentRow>> getPaymentsPaged({
    int limit = 50,
    int offset = 0,
    String? memberId,
  }) async {
    Expression<bool> predicate($PaymentsTable t) => memberId != null
        ? t.memberId.equals(memberId)
        : const Constant(true);

    final countExp = payments.id.count();
    final countRow = await (selectOnly(payments)
          ..addColumns([countExp])
          ..where(predicate(payments)))
        .getSingle();
    final total = countRow.read(countExp) ?? 0;

    final rows = await (select(payments)
          ..where(predicate)
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactionAt),
            (t) => OrderingTerm.desc(t.recordedAt),
            (t) => OrderingTerm.desc(t.id),
          ])
          ..limit(limit, offset: offset))
        .get();

    return PagedResult<PaymentRow>(
      items: rows,
      totalCount: total,
      hasMore: offset + rows.length < total,
    );
  }
}
