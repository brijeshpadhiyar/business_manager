import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';

/// Matches `workshop_expenses.category` CHECK constraint.
enum ExpenseCategory {
  rent('RENT'),
  electricity('ELECTRICITY'),
  machineRepair('MACHINE_REPAIR'),
  staffSalary('STAFF_SALARY'),
  supplies('SUPPLIES'),
  refreshments('REFRESHMENTS'),
  transport('TRANSPORT'),
  other('OTHER');

  const ExpenseCategory(this.dbValue);

  final String dbValue;

  static ExpenseCategory fromDbValue(String value) {
    return ExpenseCategory.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => throw ArgumentError('Unknown ExpenseCategory: $value'),
    );
  }
}

/// Matches `workshop_expenses.payment_status` CHECK constraint.
enum ExpensePaymentStatus {
  paid('PAID'),
  unpaid('UNPAID');

  const ExpensePaymentStatus(this.dbValue);

  final String dbValue;

  static ExpensePaymentStatus fromDbValue(String value) {
    return ExpensePaymentStatus.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => throw ArgumentError('Unknown ExpensePaymentStatus: $value'),
    );
  }
}

/// Matches `cashbook_entries.account_bucket` CHECK constraint.
enum CashbookAccountBucket {
  cash('CASH'),
  bank('BANK'),
  both('BOTH');

  const CashbookAccountBucket(this.dbValue);

  final String dbValue;

  static CashbookAccountBucket fromDbValue(String value) {
    return CashbookAccountBucket.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () =>
          throw ArgumentError('Unknown CashbookAccountBucket: $value'),
    );
  }
}

/// Matches `cashbook_entries.entry_type` CHECK constraint.
enum CashbookEntryType {
  openingCash('OPENING_CASH'),
  openingBank('OPENING_BANK'),
  cashToBank('CASH_TO_BANK'),
  bankToCash('BANK_TO_CASH'),
  capitalIn('CAPITAL_IN'),
  ownerDrawing('OWNER_DRAWING'),
  expenseSettlement('EXPENSE_SETTLEMENT'),
  reversal('REVERSAL');

  const CashbookEntryType(this.dbValue);

  final String dbValue;

  static CashbookEntryType fromDbValue(String value) {
    return CashbookEntryType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => throw ArgumentError('Unknown CashbookEntryType: $value'),
    );
  }
}

/// Unified Cashbook ledger entry source discriminator.
enum CashbookTimelineSource {
  workerPayment,
  partyPayment,
  workshopExpense,
  cashbookEntry,
}

/// Immutable domain entity for a row in `workshop_expenses`.
final class WorkshopExpenseEntity {
  const WorkshopExpenseEntity({
    required this.id,
    required this.category,
    required this.title,
    this.payeeName,
    required this.amountPaise,
    required this.paymentStatus,
    this.paymentMode,
    this.referenceNo,
    this.reversesExpenseId,
    this.clientRequestId,
    this.reason,
    this.notes,
    required this.transactionAt,
    required this.recordedAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final ExpenseCategory category;
  final String title;
  final String? payeeName;
  final int amountPaise;
  final ExpensePaymentStatus paymentStatus;
  final PaymentMode? paymentMode;
  final String? referenceNo;
  final String? reversesExpenseId;
  final String? clientRequestId;
  final String? reason;
  final String? notes;
  final int transactionAt;
  final int recordedAt;
  final String? createdBy;
  final int createdAt;
  final int updatedAt;

  bool get isReversal => reversesExpenseId != null;
}

/// Enriched view of a [WorkshopExpenseEntity] with settlement & reversal status.
final class WorkshopExpenseView {
  const WorkshopExpenseView({
    required this.expense,
    required this.isReversed,
    required this.settledPaise,
    this.hasReceiptAttachment = false,
  });

  final WorkshopExpenseEntity expense;
  final bool isReversed;
  final int settledPaise;
  final bool hasReceiptAttachment;

  int get remainingUnpaidPaise {
    if (isReversed || expense.isReversal) return 0;
    if (expense.paymentStatus == ExpensePaymentStatus.paid) return 0;
    final rem = expense.amountPaise - settledPaise;
    return rem > 0 ? rem : 0;
  }

  bool get isFullySettled => remainingUnpaidPaise == 0;
}

/// Immutable domain entity for a row in `cashbook_entries`.
final class CashbookEntryEntity {
  const CashbookEntryEntity({
    required this.id,
    required this.entryType,
    required this.accountBucket,
    required this.paymentMode,
    required this.amountPaise,
    this.linkedExpenseId,
    this.reversesEntryId,
    this.clientRequestId,
    this.referenceNo,
    this.reason,
    this.notes,
    required this.transactionAt,
    required this.recordedAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final CashbookEntryType entryType;
  final CashbookAccountBucket accountBucket;
  final PaymentMode paymentMode;
  final int amountPaise;
  final String? linkedExpenseId;
  final String? reversesEntryId;
  final String? clientRequestId;
  final String? referenceNo;
  final String? reason;
  final String? notes;
  final int transactionAt;
  final int recordedAt;
  final String? createdBy;
  final int createdAt;
  final int updatedAt;

  bool get isReversal =>
      reversesEntryId != null || entryType == CashbookEntryType.reversal;
}

/// Unified chronological Cash & Bank register item.
final class CashbookTimelineItem {
  const CashbookTimelineItem({
    required this.id,
    required this.source,
    required this.accountBucket,
    required this.paymentMode,
    required this.title,
    this.subtitle,
    required this.cashDeltaPaise,
    required this.bankDeltaPaise,
    required this.grossAmountPaise,
    required this.transactionAt,
    required this.recordedAt,
    required this.isReversed,
    required this.isReversal,
    this.expenseView,
    this.cashbookEntry,
    this.subTypeCode,
  });

  final String id;
  final CashbookTimelineSource source;
  final CashbookAccountBucket accountBucket;
  final PaymentMode paymentMode;
  final String title;
  final String? subtitle;
  final int cashDeltaPaise;
  final int bankDeltaPaise;
  final int grossAmountPaise;
  final int transactionAt;
  final int recordedAt;
  final bool isReversed;
  final bool isReversal;
  final WorkshopExpenseView? expenseView;
  final CashbookEntryEntity? cashbookEntry;
  final String? subTypeCode;
}

/// Category total row for Workshop Expenses.
final class ExpenseCategoryBreakdown {
  const ExpenseCategoryBreakdown({
    required this.category,
    required this.totalPaise,
    required this.paidPaise,
    required this.unpaidPaise,
    required this.entryCount,
  });

  final ExpenseCategory category;
  final int totalPaise;
  final int paidPaise;
  final int unpaidPaise;
  final int entryCount;
}

/// Complete Cashbook & Workshop Expense summary produced by [CashbookCalculator].
final class CashbookSummary {
  const CashbookSummary({
    required this.openingCashPaise,
    required this.openingBankPaise,
    required this.cashInflowPaise,
    required this.cashOutflowPaise,
    required this.currentCashBalancePaise,
    required this.bankInflowPaise,
    required this.bankOutflowPaise,
    required this.currentBankBalancePaise,
    required this.totalExpensesPaidPaise,
    required this.totalExpensesUnpaidPaise,
    required this.todayExpensesPaise,
    required this.expenses,
    required this.pendingBills,
    required this.categoryBreakdowns,
    required this.timeline,
  });

  final int openingCashPaise;
  final int openingBankPaise;
  final int cashInflowPaise;
  final int cashOutflowPaise;
  final int currentCashBalancePaise;
  final int bankInflowPaise;
  final int bankOutflowPaise;
  final int currentBankBalancePaise;
  final int totalExpensesPaidPaise;
  final int totalExpensesUnpaidPaise;
  final int todayExpensesPaise;
  final List<WorkshopExpenseView> expenses;
  final List<WorkshopExpenseView> pendingBills;
  final List<ExpenseCategoryBreakdown> categoryBreakdowns;
  final List<CashbookTimelineItem> timeline;

  int get totalLiquidBalancePaise =>
      currentCashBalancePaise + currentBankBalancePaise;

  int get totalWorkshopExpensesPaise =>
      totalExpensesPaidPaise + totalExpensesUnpaidPaise;
}

/// True business-wide Net Profit combining Sales, Labour, Lot Direct Costs,
/// and Workshop Overhead Expenses.
final class TrueWorkshopNetProfitSummary {
  const TrueWorkshopNetProfitSummary({
    required this.netDispatchedSalesPaise,
    required this.workerLabourPaise,
    required this.lotDirectCostsPaise,
    required this.workshopOverheadExpensesPaise,
    required this.workshopExpensesPaidPaise,
    required this.workshopExpensesUnpaidPaise,
    required this.trueNetProfitPaise,
    required this.netMarginPercent,
  });

  final int netDispatchedSalesPaise;
  final int workerLabourPaise;
  final int lotDirectCostsPaise;
  final int workshopOverheadExpensesPaise;
  final int workshopExpensesPaidPaise;
  final int workshopExpensesUnpaidPaise;
  final int trueNetProfitPaise;
  final double netMarginPercent;
}
