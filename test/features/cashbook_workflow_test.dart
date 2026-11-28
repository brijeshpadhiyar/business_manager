import 'dart:io';
import 'dart:typed_data';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/cashbook/data/repositories/cashbook_repository_impl.dart';
import 'package:business_manager/features/cashbook/domain/entities/cashbook_entities.dart';
import 'package:business_manager/features/cashbook/domain/repositories/cashbook_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(IstDateTimeHelper.initialize);

  late Directory tempDir;
  late AppDatabase db;
  late CashbookRepositoryImpl repo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sf_cashbook_wf_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final idGen = IdGenerator();
    repo = CashbookRepositoryImpl(
      db,
      DatabaseTransactionRunner(db),
      idGen,
      NativeMediaStorageService(
        config: AppConfig.dev(),
        idGenerator: idGen,
        baseDirectoryOverride: tempDir,
      ),
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  test(
    'records paid/unpaid expenses with receipts, settles bills, transfers, and blocks invalid reversals',
    () async {
      final now = IstDateTimeHelper.nowUtcMillis();

      await repo.setOpeningBalances(
        openingCashPaise: 500000,
        openingBankPaise: 1000000,
        transactionAtUtcMillis: now,
      );

      // Paid Cash expense with receipt bytes
      final tea = await repo.recordExpense(
        RecordExpenseInput(
          category: ExpenseCategory.refreshments,
          title: 'Evening Tea',
          payeeName: 'Raju Stall',
          amountPaise: 15000,
          paymentStatus: ExpensePaymentStatus.paid,
          paymentMode: PaymentMode.cash,
          transactionAtUtcMillis: now,
          receiptBytes: Uint8List.fromList([1, 2, 3, 4]),
          receiptExtension: 'jpg',
          receiptMimeType: 'image/jpeg',
        ),
      );
      final receipt = await repo.readExpenseReceiptBytes(tea.id);
      expect(receipt, Uint8List.fromList([1, 2, 3, 4]));

      // Unpaid Electricity Bill
      final bill = await repo.recordExpense(
        RecordExpenseInput(
          category: ExpenseCategory.electricity,
          title: 'DGVCL Bill',
          amountPaise: 320000,
          paymentStatus: ExpensePaymentStatus.unpaid,
          transactionAtUtcMillis: now,
        ),
      );

      // Over-settlement is blocked
      await expectLater(
        () => repo.markExpensePaid(
          expenseId: bill.id,
          paymentMode: PaymentMode.upi,
          amountPaise: 400000,
          transactionAtUtcMillis: now,
        ),
        throwsA(isA<DomainValidationException>()),
      );

      // Settle bill via UPI
      final settlement = await repo.markExpensePaid(
        expenseId: bill.id,
        paymentMode: PaymentMode.upi,
        amountPaise: 320000,
        transactionAtUtcMillis: now,
      );

      // Cannot reverse settled expense while active settlement exists
      await expectLater(
        () => repo.reverseExpense(
          expenseId: bill.id,
          reason: 'Mistake',
          transactionAtUtcMillis: now,
        ),
        throwsA(isA<DomainValidationException>()),
      );

      // Cash -> Bank transfer ₹2,000
      await repo.recordCashbookEntry(
        entryType: CashbookEntryType.cashToBank,
        accountBucket: CashbookAccountBucket.both,
        paymentMode: PaymentMode.bankTransfer,
        amountPaise: 200000,
        transactionAtUtcMillis: now,
      );

      var summary = await repo.getCashbookSummary();
      // Cash: 5000 - 150 - 2000 = 2850 (285000 paise)
      expect(summary.currentCashBalancePaise, 285000);
      // Bank: 10000 - 3200 + 2000 = 8800 (880000 paise)
      expect(summary.currentBankBalancePaise, 880000);
      expect(summary.pendingBills, isEmpty);

      // Reverse settlement -> bill returns to pending & bank balance restores
      await repo.reverseCashbookEntry(
        entryId: settlement.id,
        reason: 'Wrong UPI account',
        transactionAtUtcMillis: now,
      );
      summary = await repo.getCashbookSummary();
      expect(summary.currentBankBalancePaise, 1200000);
      expect(summary.pendingBills, hasLength(1));

      // Now the unpaid expense itself can be reversed
      await repo.reverseExpense(
        expenseId: bill.id,
        reason: 'Duplicate bill',
        transactionAtUtcMillis: now,
      );
      summary = await repo.getCashbookSummary();
      expect(summary.pendingBills, isEmpty);
    },
  );

  test(
    'enforces RBAC role restrictions inside repository for Manager and QC Inspector',
    () async {
      final now = IstDateTimeHelper.nowUtcMillis();
      await db.syncDao.updateSessionBinding(
        userId: 'user-mgr',
        businessId: 'biz-1',
      );
      await db.customStatement(
        "UPDATE sync_session_state SET active_role = 'MANAGER' WHERE id = 1;",
      );

      // Manager CAN record Paid Cash expense
      await repo.recordExpense(
        RecordExpenseInput(
          category: ExpenseCategory.supplies,
          title: 'Bobbins',
          amountPaise: 5000,
          paymentStatus: ExpensePaymentStatus.paid,
          paymentMode: PaymentMode.cash,
          transactionAtUtcMillis: now,
        ),
      );

      // Manager CANNOT record UPI / Unpaid expense or Transfers or Opening Balances
      await expectLater(
        () => repo.recordExpense(
          RecordExpenseInput(
            category: ExpenseCategory.rent,
            title: 'Rent',
            amountPaise: 50000,
            paymentStatus: ExpensePaymentStatus.paid,
            paymentMode: PaymentMode.upi,
            transactionAtUtcMillis: now,
          ),
        ),
        throwsA(isA<DomainValidationException>()),
      );
      await expectLater(
        () => repo.setOpeningBalances(
          openingCashPaise: 10000,
          openingBankPaise: 10000,
          transactionAtUtcMillis: now,
        ),
        throwsA(isA<DomainValidationException>()),
      );

      // QC Inspector CANNOT view or record Cashbook
      await db.customStatement(
        "UPDATE sync_session_state SET active_role = 'QC_INSPECTOR' WHERE id = 1;",
      );
      await expectLater(
        () => repo.getCashbookSummary(),
        throwsA(isA<DomainValidationException>()),
      );
    },
  );

  test(
    'supports partial bill settlements with settlement history and post-create receipt attachment',
    () async {
      final now = IstDateTimeHelper.nowUtcMillis();

      final bill = await repo.recordExpense(
        RecordExpenseInput(
          category: ExpenseCategory.machineRepair,
          title: 'Overlock Service',
          payeeName: 'Juki Care',
          amountPaise: 300000,
          paymentStatus: ExpensePaymentStatus.unpaid,
          transactionAtUtcMillis: now,
        ),
      );

      // Installment 1: ₹1,000 Cash
      await repo.markExpensePaid(
        expenseId: bill.id,
        paymentMode: PaymentMode.cash,
        amountPaise: 100000,
        referenceNo: 'CASH-01',
        transactionAtUtcMillis: now + 1000,
      );

      var detail = await repo.getExpenseDetail(bill.id);
      expect(detail, isNotNull);
      expect(detail!.settledPaise, 100000);
      expect(detail.remainingUnpaidPaise, 200000);
      expect(detail.isFullySettled, isFalse);
      expect(detail.hasReceiptAttachment, isFalse);

      // Installment 2: ₹2,000 UPI
      await repo.markExpensePaid(
        expenseId: bill.id,
        paymentMode: PaymentMode.upi,
        amountPaise: 200000,
        referenceNo: 'UPI-99',
        transactionAtUtcMillis: now + 2000,
      );

      detail = await repo.getExpenseDetail(bill.id);
      expect(detail!.settledPaise, 300000);
      expect(detail.remainingUnpaidPaise, 0);
      expect(detail.isFullySettled, isTrue);

      final settlements = await repo.getExpenseSettlements(bill.id);
      expect(settlements, hasLength(2));
      expect(settlements[0].amountPaise, 100000);
      expect(settlements[1].amountPaise, 200000);

      // Attach receipt after creation
      await repo.attachExpenseReceipt(
        expenseId: bill.id,
        receiptBytes: Uint8List.fromList([10, 20, 30]),
      );

      detail = await repo.getExpenseDetail(bill.id);
      expect(detail!.hasReceiptAttachment, isTrue);
      final bytes = await repo.readExpenseReceiptBytes(bill.id);
      expect(bytes, Uint8List.fromList([10, 20, 30]));
    },
  );
}
