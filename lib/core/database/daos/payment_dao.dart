import 'package:business_manager/core/database/app_database.dart';
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

  Future<PaymentRow?> findByClientRequestId(String clientRequestId) => (select(
    payments,
  )..where((t) => t.clientRequestId.equals(clientRequestId))).getSingleOrNull();

  Future<List<PaymentRow>> getPaymentsForMember(String memberId) {
    return (select(payments)
          ..where((t) => t.memberId.equals(memberId))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionAt)]))
        .get();
  }
}
