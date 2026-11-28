// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cashbook_dao.dart';

// ignore_for_file: type=lint
mixin _$CashbookDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkshopExpensesTable get workshopExpenses =>
      attachedDatabase.workshopExpenses;
  $CashbookEntriesTable get cashbookEntries => attachedDatabase.cashbookEntries;
  CashbookDaoManager get managers => CashbookDaoManager(this);
}

class CashbookDaoManager {
  final _$CashbookDaoMixin _db;
  CashbookDaoManager(this._db);
  $$WorkshopExpensesTableTableManager get workshopExpenses =>
      $$WorkshopExpensesTableTableManager(
        _db.attachedDatabase,
        _db.workshopExpenses,
      );
  $$CashbookEntriesTableTableManager get cashbookEntries =>
      $$CashbookEntriesTableTableManager(
        _db.attachedDatabase,
        _db.cashbookEntries,
      );
}
