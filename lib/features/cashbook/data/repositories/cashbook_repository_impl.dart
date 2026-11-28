import 'dart:convert';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/database/mappers/actor_resolver.dart';
import 'package:business_manager/core/database/mappers/ledger_row_mappers.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/auth/domain/services/rbac_policy.dart';
import 'package:business_manager/features/cashbook/domain/calculators/cashbook_calculator.dart';
import 'package:business_manager/features/cashbook/domain/entities/cashbook_entities.dart';
import 'package:business_manager/features/cashbook/domain/repositories/cashbook_repository.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CashbookRepository)
final class CashbookRepositoryImpl implements CashbookRepository {
  CashbookRepositoryImpl(
    this._db,
    this._txRunner,
    this._idGenerator,
    this._mediaStorage,
  );

  final AppDatabase _db;
  final DatabaseTransactionRunner _txRunner;
  final IdGenerator _idGenerator;
  final MediaStorageService _mediaStorage;

  static const CashbookCalculator _calc = CashbookCalculator();

  Future<BusinessRole> _currentEffectiveRole() async {
    final session = await _db.syncDao.getSessionState();
    if (session.boundUserId == null || session.boundUserId!.isEmpty) {
      return BusinessRole.owner;
    }
    return BusinessRole.fromDbValue(session.activeRole);
  }

  Future<void> _requirePermission(AppPermission permission) async {
    final role = await _currentEffectiveRole();
    if (!RbacPolicy.can(role, permission)) {
      throw const DomainValidationException(
        'permission_denied',
        'Permission denied',
      );
    }
  }

  @override
  Future<CashbookSummary> getCashbookSummary({
    int? fromUtcMillis,
    int? toUtcMillis,
  }) async {
    await _requirePermission(AppPermission.viewCashbookAndExpenses);

    final expenses = (await _db.cashbookDao.getAllExpenses())
        .map(LedgerRowMappers.workshopExpense)
        .toList();
    final entries = (await _db.cashbookDao.getAllCashbookEntries())
        .map(LedgerRowMappers.cashbookEntry)
        .toList();
    final workerPayments = (await _db.paymentDao.getAllPayments())
        .map(LedgerRowMappers.payment)
        .toList();
    final partyPayments = (await _db.partyDispatchDao.getAllPartyPayments())
        .map(LedgerRowMappers.partyPayment)
        .toList();

    final workers = await _db.processMemberDao.getNonDeletedMembers();
    final parties = await _db.partyDispatchDao.getNonDeletedParties();
    final allAttachments = await _db.attachmentAuditDao
        .getAllActiveAttachments();

    final receiptExpenseIds = <String>{
      for (final a in allAttachments)
        if (a.entityType == 'WORKSHOP_EXPENSE') a.entityId,
    };

    return _calc.calculateSummary(
      expenses: expenses,
      cashbookEntries: entries,
      workerPayments: workerPayments,
      partyPayments: partyPayments,
      workerNames: {for (final w in workers) w.id: w.name},
      partyNames: {for (final p in parties) p.id: p.name},
      expenseIdsWithReceipt: receiptExpenseIds,
      fromUtcMillis: fromUtcMillis,
      toUtcMillis: toUtcMillis,
    );
  }

  @override
  Future<WorkshopExpenseView?> getExpenseDetail(String expenseId) async {
    await _requirePermission(AppPermission.viewCashbookAndExpenses);
    final row = await _db.cashbookDao.getExpenseById(expenseId);
    if (row == null) return null;

    final entity = LedgerRowMappers.workshopExpense(row);
    final isRev = await _db.cashbookDao.hasReversalForExpense(expenseId);
    final settlements = await _db.cashbookDao.getSettlementsForExpense(
      expenseId,
    );
    final allEntries = (await _db.cashbookDao.getAllCashbookEntries())
        .map(LedgerRowMappers.cashbookEntry)
        .toList();
    final revEntries = _calc.reversedCashbookEntryIds(allEntries);

    var settled = 0;
    for (final s in settlements) {
      if (s.reversesEntryId == null && !revEntries.contains(s.id)) {
        settled += s.amountPaise;
      }
    }
    final atts = await _db.attachmentAuditDao.getActiveAttachments(
      'WORKSHOP_EXPENSE',
      expenseId,
    );
    return WorkshopExpenseView(
      expense: entity,
      isReversed: isRev,
      settledPaise: settled,
      hasReceiptAttachment: atts.isNotEmpty,
    );
  }

  @override
  Future<List<CashbookEntryEntity>> getExpenseSettlements(
    String expenseId,
  ) async {
    await _requirePermission(AppPermission.viewCashbookAndExpenses);
    final rows = await _db.cashbookDao.getSettlementsForExpense(expenseId);
    return rows.map(LedgerRowMappers.cashbookEntry).toList();
  }

  @override
  Future<Uint8List?> readExpenseReceiptBytes(String expenseId) async {
    await _requirePermission(AppPermission.viewCashbookAndExpenses);
    final atts = await _db.attachmentAuditDao.getActiveAttachments(
      'WORKSHOP_EXPENSE',
      expenseId,
    );
    if (atts.isEmpty) return null;
    return _mediaStorage.readBytes(atts.first.relativePath);
  }

  @override
  Future<void> attachExpenseReceipt({
    required String expenseId,
    required Uint8List receiptBytes,
    String fileExtension = 'jpg',
    String mimeType = 'image/jpeg',
  }) async {
    if (receiptBytes.isEmpty) {
      throw const DomainValidationException(
        'receipt_required',
        'Receipt is required',
      );
    }

    final expRow = await _db.cashbookDao.getExpenseById(expenseId);
    if (expRow == null) {
      throw const DomainValidationException(
        'expense_not_found',
        'Expense not found',
      );
    }
    if (expRow.paymentStatus == ExpensePaymentStatus.paid.dbValue &&
        expRow.paymentMode == PaymentMode.cash.dbValue) {
      await _requirePermission(AppPermission.recordCashExpense);
    } else {
      await _requirePermission(AppPermission.recordNonCashExpenseAndTransfers);
    }

    final savedMedia = await _mediaStorage.saveBytes(
      bytes: receiptBytes,
      category: MediaCategory.expenses,
      entityId: expenseId,
      fileExtension: fileExtension,
      mimeType: mimeType,
    );

    try {
      await _txRunner.runInTransaction(() async {
        final now = IstDateTimeHelper.nowUtcMillis();
        final actor = await ActorResolver.resolveRequired(_db);
        final attId = _idGenerator.nextEntityId();

        await _db.attachmentAuditDao.insertAttachment(
          AttachmentsCompanion(
            id: Value(attId),
            entityType: const Value('WORKSHOP_EXPENSE'),
            entityId: Value(expenseId),
            relativePath: Value(savedMedia.relativePath),
            mimeType: Value(savedMedia.mimeType),
            fileSizeBytes: Value(savedMedia.fileSizeBytes),
            sha256: Value(savedMedia.sha256Hex),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        await _db.attachmentAuditDao.insertAuditLog(
          AuditLogsCompanion(
            id: Value(_idGenerator.nextEntityId()),
            entityType: const Value('WORKSHOP_EXPENSE'),
            entityId: Value(expenseId),
            actionType: const Value('UPDATE'),
            actor: Value(actor),
            newValueJson: Value(
              jsonEncode({
                'event': 'ATTACH_RECEIPT',
                'attachmentId': attId,
                'mimeType': savedMedia.mimeType,
              }),
            ),
            transactionAt: Value(now),
            recordedAt: Value(now),
          ),
        );
      });
    } catch (_) {
      await _mediaStorage.deleteIfExists(savedMedia.relativePath);
      rethrow;
    }
  }

  @override
  Future<WorkshopExpenseEntity> recordExpense(RecordExpenseInput input) async {
    final trimmedTitle = input.title.trim();
    if (trimmedTitle.isEmpty) {
      throw const DomainValidationException(
        'title_required',
        'Title is required',
      );
    }
    if (input.amountPaise <= 0) {
      throw const DomainValidationException(
        'positive_amount_required',
        'Amount must be positive',
      );
    }
    if (input.paymentStatus == ExpensePaymentStatus.paid &&
        input.paymentMode == null) {
      throw const DomainValidationException(
        'payment_mode_required',
        'Payment mode is required',
      );
    }
    if (input.paymentMode == PaymentMode.other) {
      throw const DomainValidationException(
        'unsupported_payment_mode',
        'Unsupported payment mode',
      );
    }

    // RBAC: Managers may record Paid Cash expenses only.
    if (input.paymentStatus == ExpensePaymentStatus.paid &&
        input.paymentMode == PaymentMode.cash) {
      await _requirePermission(AppPermission.recordCashExpense);
    } else {
      await _requirePermission(AppPermission.recordNonCashExpenseAndTransfers);
    }

    final reqId = input.clientRequestId?.trim();
    if (reqId != null && reqId.isNotEmpty) {
      final existing = await _db.cashbookDao.findExpenseByClientRequestId(
        reqId,
      );
      if (existing != null) return LedgerRowMappers.workshopExpense(existing);
    }

    final expenseId = _idGenerator.nextEntityId();
    SavedMediaFile? savedMedia;
    if (input.receiptBytes != null && input.receiptBytes!.isNotEmpty) {
      savedMedia = await _mediaStorage.saveBytes(
        bytes: input.receiptBytes!,
        category: MediaCategory.expenses,
        entityId: expenseId,
        fileExtension: input.receiptExtension ?? 'jpg',
        mimeType: input.receiptMimeType ?? 'image/jpeg',
      );
    }

    try {
      return await _txRunner.runInTransaction(() async {
        final now = IstDateTimeHelper.nowUtcMillis();
        final actor = await ActorResolver.resolveRequired(_db);
        final modeDb = input.paymentStatus == ExpensePaymentStatus.paid
            ? input.paymentMode!.dbValue
            : null;
        final payee = _cleanNullable(input.payeeName);
        final refNo = _cleanNullable(input.referenceNo);
        final notes = _cleanNullable(input.notes);

        await _db.cashbookDao.insertExpense(
          WorkshopExpensesCompanion(
            id: Value(expenseId),
            category: Value(input.category.dbValue),
            title: Value(trimmedTitle),
            payeeName: Value(payee),
            amountPaise: Value(input.amountPaise),
            paymentStatus: Value(input.paymentStatus.dbValue),
            paymentMode: Value(modeDb),
            referenceNo: Value(refNo),
            clientRequestId: Value(reqId),
            notes: Value(notes),
            transactionAt: Value(input.transactionAtUtcMillis),
            recordedAt: Value(now),
            createdBy: Value(actor),
            updatedBy: Value(actor),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        if (savedMedia != null) {
          await _db.attachmentAuditDao.insertAttachment(
            AttachmentsCompanion(
              id: Value(_idGenerator.nextEntityId()),
              entityType: const Value('WORKSHOP_EXPENSE'),
              entityId: Value(expenseId),
              relativePath: Value(savedMedia.relativePath),
              mimeType: Value(savedMedia.mimeType),
              fileSizeBytes: Value(savedMedia.fileSizeBytes),
              sha256: Value(savedMedia.sha256Hex),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
        }

        await _db.attachmentAuditDao.insertAuditLog(
          AuditLogsCompanion(
            id: Value(_idGenerator.nextEntityId()),
            entityType: const Value('WORKSHOP_EXPENSE'),
            entityId: Value(expenseId),
            actionType: const Value('CREATE'),
            actor: Value(actor),
            newValueJson: Value(
              jsonEncode({
                'category': input.category.dbValue,
                'title': trimmedTitle,
                'amountPaise': input.amountPaise,
                'paymentStatus': input.paymentStatus.dbValue,
                'paymentMode': modeDb,
              }),
            ),
            transactionAt: Value(input.transactionAtUtcMillis),
            recordedAt: Value(now),
          ),
        );

        final saved = await _db.cashbookDao.getExpenseById(expenseId);
        return LedgerRowMappers.workshopExpense(saved!);
      });
    } catch (_) {
      if (savedMedia != null) {
        await _mediaStorage.deleteIfExists(savedMedia.relativePath);
      }
      rethrow;
    }
  }

  @override
  Future<CashbookEntryEntity> markExpensePaid({
    required String expenseId,
    required PaymentMode paymentMode,
    required int amountPaise,
    String? referenceNo,
    String? notes,
    required int transactionAtUtcMillis,
    String? clientRequestId,
  }) async {
    await _requirePermission(AppPermission.recordNonCashExpenseAndTransfers);
    if (paymentMode == PaymentMode.other) {
      throw const DomainValidationException(
        'unsupported_payment_mode',
        'Unsupported payment mode',
      );
    }
    if (amountPaise <= 0) {
      throw const DomainValidationException(
        'positive_amount_required',
        'Amount must be positive',
      );
    }

    final reqId = clientRequestId?.trim();
    if (reqId != null && reqId.isNotEmpty) {
      final existing = await _db.cashbookDao.findCashbookEntryByClientRequestId(
        reqId,
      );
      if (existing != null) return LedgerRowMappers.cashbookEntry(existing);
    }

    return _txRunner.runInTransaction(() async {
      final expRow = await _db.cashbookDao.getExpenseById(expenseId);
      if (expRow == null) {
        throw const DomainValidationException(
          'expense_not_found',
          'Expense not found',
        );
      }
      if (expRow.reversesExpenseId != null ||
          await _db.cashbookDao.hasReversalForExpense(expenseId)) {
        throw const DomainValidationException(
          'expense_already_reversed',
          'Expense already reversed',
        );
      }
      if (expRow.paymentStatus == ExpensePaymentStatus.paid.dbValue) {
        throw const DomainValidationException(
          'expense_already_paid',
          'Expense already paid',
        );
      }

      final settlements = await _db.cashbookDao.getSettlementsForExpense(
        expenseId,
      );
      var alreadySettled = 0;
      for (final s in settlements) {
        final isRev = await _db.cashbookDao.hasReversalForEntry(s.id);
        if (s.reversesEntryId == null && !isRev) {
          alreadySettled += s.amountPaise;
        }
      }
      final remaining = expRow.amountPaise - alreadySettled;
      if (amountPaise > remaining) {
        throw const DomainValidationException(
          'settlement_exceeds_unpaid_balance',
          'Settlement exceeds unpaid balance',
        );
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await ActorResolver.resolveRequired(_db);
      final id = _idGenerator.nextEntityId();
      final bucket = CashbookCalculator.bucketForPaymentMode(paymentMode);

      await _db.cashbookDao.insertCashbookEntry(
        CashbookEntriesCompanion(
          id: Value(id),
          entryType: Value(CashbookEntryType.expenseSettlement.dbValue),
          accountBucket: Value(bucket.dbValue),
          paymentMode: Value(paymentMode.dbValue),
          amountPaise: Value(amountPaise),
          linkedExpenseId: Value(expenseId),
          clientRequestId: Value(reqId),
          referenceNo: Value(_cleanNullable(referenceNo)),
          notes: Value(_cleanNullable(notes)),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('CASHBOOK_ENTRY'),
          entityId: Value(id),
          actionType: const Value('CREATE'),
          actor: Value(actor),
          newValueJson: Value(
            jsonEncode({
              'entryType': CashbookEntryType.expenseSettlement.dbValue,
              'linkedExpenseId': expenseId,
              'amountPaise': amountPaise,
              'paymentMode': paymentMode.dbValue,
            }),
          ),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
        ),
      );

      final saved = await _db.cashbookDao.getCashbookEntryById(id);
      return LedgerRowMappers.cashbookEntry(saved!);
    });
  }

  @override
  Future<WorkshopExpenseEntity> reverseExpense({
    required String expenseId,
    required String reason,
    required int transactionAtUtcMillis,
  }) async {
    await _requirePermission(AppPermission.recordNonCashExpenseAndTransfers);
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw const DomainValidationException(
        'reason_required',
        'Reason is required',
      );
    }

    return _txRunner.runInTransaction(() async {
      final original = await _db.cashbookDao.getExpenseById(expenseId);
      if (original == null) {
        throw const DomainValidationException(
          'expense_not_found',
          'Expense not found',
        );
      }
      if (original.reversesExpenseId != null ||
          await _db.cashbookDao.hasReversalForExpense(expenseId)) {
        throw const DomainValidationException(
          'expense_already_reversed',
          'Expense already reversed',
        );
      }

      // Block reversing an unpaid expense if active settlements exist.
      final settlements = await _db.cashbookDao.getSettlementsForExpense(
        expenseId,
      );
      for (final s in settlements) {
        if (s.reversesEntryId == null &&
            !await _db.cashbookDao.hasReversalForEntry(s.id)) {
          throw const DomainValidationException(
            'expense_has_active_settlement',
            'Reverse active settlement first',
          );
        }
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await ActorResolver.resolveRequired(_db);
      final revId = _idGenerator.nextEntityId();

      await _db.cashbookDao.insertExpense(
        WorkshopExpensesCompanion(
          id: Value(revId),
          category: Value(original.category),
          title: Value(original.title),
          payeeName: Value(original.payeeName),
          amountPaise: Value(original.amountPaise),
          paymentStatus: Value(original.paymentStatus),
          paymentMode: Value(original.paymentMode),
          reversesExpenseId: Value(original.id),
          reason: Value(trimmedReason),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('WORKSHOP_EXPENSE'),
          entityId: Value(revId),
          actionType: const Value('REVERSAL'),
          actor: Value(actor),
          previousValueJson: Value(
            jsonEncode({
              'reversedExpenseId': original.id,
              'amountPaise': original.amountPaise,
            }),
          ),
          reason: Value(trimmedReason),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
        ),
      );

      final saved = await _db.cashbookDao.getExpenseById(revId);
      return LedgerRowMappers.workshopExpense(saved!);
    });
  }

  @override
  Future<CashbookEntryEntity> recordCashbookEntry({
    required CashbookEntryType entryType,
    required CashbookAccountBucket accountBucket,
    required PaymentMode paymentMode,
    required int amountPaise,
    String? referenceNo,
    String? notes,
    required int transactionAtUtcMillis,
    String? clientRequestId,
  }) async {
    await _requirePermission(AppPermission.recordNonCashExpenseAndTransfers);
    if (amountPaise <= 0) {
      throw const DomainValidationException(
        'positive_amount_required',
        'Amount must be positive',
      );
    }
    if (paymentMode == PaymentMode.other) {
      throw const DomainValidationException(
        'unsupported_payment_mode',
        'Unsupported payment mode',
      );
    }
    if (entryType == CashbookEntryType.openingCash ||
        entryType == CashbookEntryType.openingBank ||
        entryType == CashbookEntryType.expenseSettlement ||
        entryType == CashbookEntryType.reversal) {
      throw const DomainValidationException(
        'invalid_cashbook_entry_type',
        'Invalid cashbook entry type',
      );
    }

    final reqId = clientRequestId?.trim();
    if (reqId != null && reqId.isNotEmpty) {
      final existing = await _db.cashbookDao.findCashbookEntryByClientRequestId(
        reqId,
      );
      if (existing != null) return LedgerRowMappers.cashbookEntry(existing);
    }

    return _txRunner.runInTransaction(() async {
      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await ActorResolver.resolveRequired(_db);
      final id = _idGenerator.nextEntityId();

      await _db.cashbookDao.insertCashbookEntry(
        CashbookEntriesCompanion(
          id: Value(id),
          entryType: Value(entryType.dbValue),
          accountBucket: Value(accountBucket.dbValue),
          paymentMode: Value(paymentMode.dbValue),
          amountPaise: Value(amountPaise),
          clientRequestId: Value(reqId),
          referenceNo: Value(_cleanNullable(referenceNo)),
          notes: Value(_cleanNullable(notes)),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('CASHBOOK_ENTRY'),
          entityId: Value(id),
          actionType: const Value('CREATE'),
          actor: Value(actor),
          newValueJson: Value(
            jsonEncode({
              'entryType': entryType.dbValue,
              'accountBucket': accountBucket.dbValue,
              'paymentMode': paymentMode.dbValue,
              'amountPaise': amountPaise,
            }),
          ),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
        ),
      );

      final saved = await _db.cashbookDao.getCashbookEntryById(id);
      return LedgerRowMappers.cashbookEntry(saved!);
    });
  }

  @override
  Future<void> setOpeningBalances({
    required int openingCashPaise,
    required int openingBankPaise,
    required int transactionAtUtcMillis,
  }) async {
    await _requirePermission(AppPermission.manageOpeningBalances);
    if (openingCashPaise < 0 || openingBankPaise < 0) {
      throw const DomainValidationException(
        'negative_amount_not_allowed',
        'Negative amount not allowed',
      );
    }

    await _txRunner.runInTransaction(() async {
      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await ActorResolver.resolveRequired(_db);
      final allEntries = await _db.cashbookDao.getAllCashbookEntries();

      await _replaceOpeningEntry(
        allEntries: allEntries,
        type: CashbookEntryType.openingCash,
        bucket: CashbookAccountBucket.cash,
        mode: PaymentMode.cash,
        newAmountPaise: openingCashPaise,
        actor: actor,
        transactionAtUtcMillis: transactionAtUtcMillis,
        nowUtcMillis: now,
      );

      await _replaceOpeningEntry(
        allEntries: allEntries,
        type: CashbookEntryType.openingBank,
        bucket: CashbookAccountBucket.bank,
        mode: PaymentMode.bankTransfer,
        newAmountPaise: openingBankPaise,
        actor: actor,
        transactionAtUtcMillis: transactionAtUtcMillis,
        nowUtcMillis: now,
      );
    });
  }

  Future<void> _replaceOpeningEntry({
    required List<CashbookEntryRow> allEntries,
    required CashbookEntryType type,
    required CashbookAccountBucket bucket,
    required PaymentMode mode,
    required int newAmountPaise,
    required String actor,
    required int transactionAtUtcMillis,
    required int nowUtcMillis,
  }) async {
    final reversedIds = <String>{
      for (final r in allEntries)
        if (r.reversesEntryId != null) r.reversesEntryId!,
    };
    final activeExisting = allEntries
        .where(
          (r) =>
              r.entryType == type.dbValue &&
              r.reversesEntryId == null &&
              !reversedIds.contains(r.id),
        )
        .toList();

    final currentTotal = activeExisting.fold<int>(
      0,
      (sum, r) => sum + r.amountPaise,
    );
    if (currentTotal == newAmountPaise && activeExisting.isNotEmpty) return;
    if (activeExisting.isEmpty && newAmountPaise == 0) return;

    for (final old in activeExisting) {
      final revId = _idGenerator.nextEntityId();
      await _db.cashbookDao.insertCashbookEntry(
        CashbookEntriesCompanion(
          id: Value(revId),
          entryType: Value(CashbookEntryType.reversal.dbValue),
          accountBucket: Value(old.accountBucket),
          paymentMode: Value(old.paymentMode),
          amountPaise: Value(old.amountPaise),
          reversesEntryId: Value(old.id),
          reason: const Value('Opening balance updated'),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(nowUtcMillis),
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: Value(nowUtcMillis),
          updatedAt: Value(nowUtcMillis),
        ),
      );
    }

    final newId = _idGenerator.nextEntityId();
    await _db.cashbookDao.insertCashbookEntry(
      CashbookEntriesCompanion(
        id: Value(newId),
        entryType: Value(type.dbValue),
        accountBucket: Value(bucket.dbValue),
        paymentMode: Value(mode.dbValue),
        amountPaise: Value(newAmountPaise),
        transactionAt: Value(transactionAtUtcMillis),
        recordedAt: Value(nowUtcMillis),
        createdBy: Value(actor),
        updatedBy: Value(actor),
        createdAt: Value(nowUtcMillis),
        updatedAt: Value(nowUtcMillis),
      ),
    );

    await _db.attachmentAuditDao.insertAuditLog(
      AuditLogsCompanion(
        id: Value(_idGenerator.nextEntityId()),
        entityType: const Value('CASHBOOK_ENTRY'),
        entityId: Value(newId),
        actionType: const Value('CREATE'),
        actor: Value(actor),
        previousValueJson: Value(jsonEncode({'amountPaise': currentTotal})),
        newValueJson: Value(
          jsonEncode({'entryType': type.dbValue, 'amountPaise': newAmountPaise}),
        ),
        transactionAt: Value(transactionAtUtcMillis),
        recordedAt: Value(nowUtcMillis),
      ),
    );
  }

  @override
  Future<CashbookEntryEntity> reverseCashbookEntry({
    required String entryId,
    required String reason,
    required int transactionAtUtcMillis,
  }) async {
    await _requirePermission(AppPermission.recordNonCashExpenseAndTransfers);
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw const DomainValidationException(
        'reason_required',
        'Reason is required',
      );
    }

    return _txRunner.runInTransaction(() async {
      final original = await _db.cashbookDao.getCashbookEntryById(entryId);
      if (original == null) {
        throw const DomainValidationException(
          'cashbook_entry_not_found',
          'Cashbook entry not found',
        );
      }
      if (original.reversesEntryId != null ||
          original.entryType == CashbookEntryType.reversal.dbValue ||
          await _db.cashbookDao.hasReversalForEntry(entryId)) {
        throw const DomainValidationException(
          'entry_already_reversed',
          'Entry already reversed',
        );
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await ActorResolver.resolveRequired(_db);
      final revId = _idGenerator.nextEntityId();

      await _db.cashbookDao.insertCashbookEntry(
        CashbookEntriesCompanion(
          id: Value(revId),
          entryType: Value(CashbookEntryType.reversal.dbValue),
          accountBucket: Value(original.accountBucket),
          paymentMode: Value(original.paymentMode),
          amountPaise: Value(original.amountPaise),
          linkedExpenseId: Value(original.linkedExpenseId),
          reversesEntryId: Value(original.id),
          reason: Value(trimmedReason),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('CASHBOOK_ENTRY'),
          entityId: Value(revId),
          actionType: const Value('REVERSAL'),
          actor: Value(actor),
          previousValueJson: Value(
            jsonEncode({
              'reversedEntryId': original.id,
              'entryType': original.entryType,
              'amountPaise': original.amountPaise,
            }),
          ),
          reason: Value(trimmedReason),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
        ),
      );

      final saved = await _db.cashbookDao.getCashbookEntryById(revId);
      return LedgerRowMappers.cashbookEntry(saved!);
    });
  }

  static String? _cleanNullable(String? raw) {
    final trimmed = raw?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}
