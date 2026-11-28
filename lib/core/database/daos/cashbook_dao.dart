import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/tables/cashbook_tables.dart';
import 'package:drift/drift.dart';

part 'cashbook_dao.g.dart';

/// Persistence-only DAO for `workshop_expenses` and `cashbook_entries`.
/// Strictly append-only — corrections require explicit reversal rows.
@DriftAccessor(tables: [WorkshopExpenses, CashbookEntries])
class CashbookDao extends DatabaseAccessor<AppDatabase>
    with _$CashbookDaoMixin {
  CashbookDao(super.db);

  // ── Workshop Expenses ───────────────────────────────────────────────────

  Future<void> insertExpense(WorkshopExpensesCompanion entry) =>
      into(workshopExpenses).insert(entry);

  Future<WorkshopExpenseRow?> getExpenseById(String id) {
    return (select(
      workshopExpenses,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
  }

  Future<WorkshopExpenseRow?> findExpenseByClientRequestId(
    String clientRequestId,
  ) {
    return (select(workshopExpenses)
          ..where((t) => t.clientRequestId.equals(clientRequestId)))
        .getSingleOrNull();
  }

  Future<bool> hasReversalForExpense(String expenseId) async {
    final row =
        await (select(workshopExpenses)
              ..where(
                (t) =>
                    t.reversesExpenseId.equals(expenseId) &
                    t.deletedAt.isNull(),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  Future<List<WorkshopExpenseRow>> getAllExpenses() {
    return (select(workshopExpenses)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactionAt),
            (t) => OrderingTerm.desc(t.recordedAt),
          ]))
        .get();
  }

  // ── Cashbook Entries ────────────────────────────────────────────────────

  Future<void> insertCashbookEntry(CashbookEntriesCompanion entry) =>
      into(cashbookEntries).insert(entry);

  Future<CashbookEntryRow?> getCashbookEntryById(String id) {
    return (select(
      cashbookEntries,
    )..where((t) => t.id.equals(id) & t.deletedAt.isNull())).getSingleOrNull();
  }

  Future<CashbookEntryRow?> findCashbookEntryByClientRequestId(
    String clientRequestId,
  ) {
    return (select(cashbookEntries)
          ..where((t) => t.clientRequestId.equals(clientRequestId)))
        .getSingleOrNull();
  }

  Future<bool> hasReversalForEntry(String entryId) async {
    final row =
        await (select(cashbookEntries)
              ..where(
                (t) => t.reversesEntryId.equals(entryId) & t.deletedAt.isNull(),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  Future<List<CashbookEntryRow>> getAllCashbookEntries() {
    return (select(cashbookEntries)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactionAt),
            (t) => OrderingTerm.desc(t.recordedAt),
          ]))
        .get();
  }

  Future<List<CashbookEntryRow>> getSettlementsForExpense(String expenseId) {
    return (select(cashbookEntries)
          ..where(
            (t) => t.linkedExpenseId.equals(expenseId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.transactionAt)]))
        .get();
  }
}
