import 'dart:typed_data';

import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/cashbook/domain/entities/cashbook_entities.dart';

/// Input payload for recording a new Workshop Expense with optional receipt bytes.
final class RecordExpenseInput {
  const RecordExpenseInput({
    required this.category,
    required this.title,
    this.payeeName,
    required this.amountPaise,
    required this.paymentStatus,
    this.paymentMode,
    this.referenceNo,
    this.notes,
    required this.transactionAtUtcMillis,
    this.clientRequestId,
    this.receiptBytes,
    this.receiptExtension,
    this.receiptMimeType,
  });

  final ExpenseCategory category;
  final String title;
  final String? payeeName;
  final int amountPaise;
  final ExpensePaymentStatus paymentStatus;
  final PaymentMode? paymentMode;
  final String? referenceNo;
  final String? notes;
  final int transactionAtUtcMillis;
  final String? clientRequestId;
  final Uint8List? receiptBytes;
  final String? receiptExtension;
  final String? receiptMimeType;
}

/// Abstract repository contract for Workshop Expenses & Unified Cash/Bank Book.
abstract interface class CashbookRepository {
  Future<CashbookSummary> getCashbookSummary({
    int? fromUtcMillis,
    int? toUtcMillis,
  });

  Future<WorkshopExpenseView?> getExpenseDetail(String expenseId);

  Future<List<CashbookEntryEntity>> getExpenseSettlements(String expenseId);

  Future<Uint8List?> readExpenseReceiptBytes(String expenseId);

  Future<void> attachExpenseReceipt({
    required String expenseId,
    required Uint8List receiptBytes,
    String fileExtension = 'jpg',
    String mimeType = 'image/jpeg',
  });

  Future<WorkshopExpenseEntity> recordExpense(RecordExpenseInput input);

  Future<CashbookEntryEntity> markExpensePaid({
    required String expenseId,
    required PaymentMode paymentMode,
    required int amountPaise,
    String? referenceNo,
    String? notes,
    required int transactionAtUtcMillis,
    String? clientRequestId,
  });

  Future<WorkshopExpenseEntity> reverseExpense({
    required String expenseId,
    required String reason,
    required int transactionAtUtcMillis,
  });

  Future<CashbookEntryEntity> recordCashbookEntry({
    required CashbookEntryType entryType,
    required CashbookAccountBucket accountBucket,
    required PaymentMode paymentMode,
    required int amountPaise,
    String? referenceNo,
    String? notes,
    required int transactionAtUtcMillis,
    String? clientRequestId,
  });

  Future<void> setOpeningBalances({
    required int openingCashPaise,
    required int openingBankPaise,
    required int transactionAtUtcMillis,
  });

  Future<CashbookEntryEntity> reverseCashbookEntry({
    required String entryId,
    required String reason,
    required int transactionAtUtcMillis,
  });
}
