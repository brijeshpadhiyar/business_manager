import 'package:drift/drift.dart';

/// 2.22 `workshop_expenses` — Append-only workshop overhead bills & expenses
/// (Rent, Electricity, Machine Repair, Staff Salary, Supplies, etc.) plus
/// explicit audited reversals.
@DataClassName('WorkshopExpenseRow')
class WorkshopExpenses extends Table {
  @override
  String get tableName => 'workshop_expenses';

  TextColumn get id => text()();
  TextColumn get category => text()();
  TextColumn get title => text()();
  TextColumn get payeeName => text().nullable()();
  IntColumn get amountPaise => integer()();
  TextColumn get paymentStatus => text()();
  TextColumn get paymentMode => text().nullable()();
  TextColumn get referenceNo => text().nullable()();
  TextColumn get reversesExpenseId => text().nullable().references(
    WorkshopExpenses,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get clientRequestId => text().nullable()();
  TextColumn get reason => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get transactionAt => integer()();
  IntColumn get recordedAt => integer()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get updatedBy => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK(category IN ('RENT', 'ELECTRICITY', 'MACHINE_REPAIR', 'STAFF_SALARY', 'SUPPLIES', 'REFRESHMENTS', 'TRANSPORT', 'OTHER'))",
    'CHECK(length(trim(title)) > 0)',
    'CHECK(amount_paise > 0)',
    "CHECK(payment_status IN ('PAID', 'UNPAID'))",
    "CHECK(payment_mode IS NULL OR payment_mode IN ('CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE'))",
  ];
}

/// 2.23 `cashbook_entries` — Append-only Cash & Bank register movements:
/// opening balances, Cash↔Bank contra transfers, owner capital/drawings,
/// unpaid expense settlements, and explicit reversals.
@DataClassName('CashbookEntryRow')
class CashbookEntries extends Table {
  @override
  String get tableName => 'cashbook_entries';

  TextColumn get id => text()();
  TextColumn get entryType => text()();
  TextColumn get accountBucket => text()();
  TextColumn get paymentMode => text()();
  IntColumn get amountPaise => integer()();
  TextColumn get linkedExpenseId => text().nullable().references(
    WorkshopExpenses,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get reversesEntryId => text().nullable().references(
    CashbookEntries,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get clientRequestId => text().nullable()();
  TextColumn get referenceNo => text().nullable()();
  TextColumn get reason => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get transactionAt => integer()();
  IntColumn get recordedAt => integer()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get updatedBy => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK(entry_type IN ('OPENING_CASH', 'OPENING_BANK', 'CASH_TO_BANK', 'BANK_TO_CASH', 'CAPITAL_IN', 'OWNER_DRAWING', 'EXPENSE_SETTLEMENT', 'REVERSAL'))",
    "CHECK(account_bucket IN ('CASH', 'BANK', 'BOTH'))",
    "CHECK(payment_mode IN ('CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE'))",
    'CHECK(amount_paise >= 0)',
  ];
}
