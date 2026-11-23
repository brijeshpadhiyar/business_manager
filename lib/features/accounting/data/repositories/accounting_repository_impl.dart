import 'dart:convert';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/domain/calculators/ledger_calculator.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/accounting/domain/repositories/accounting_repository.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/stock_movements/domain/calculators/stock_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: AccountingRepository)
final class AccountingRepositoryImpl implements AccountingRepository {
  AccountingRepositoryImpl(this._db, this._txRunner, this._idGenerator);

  final AppDatabase _db;
  final DatabaseTransactionRunner _txRunner;
  final IdGenerator _idGenerator;

  static const LedgerCalculator _ledgerCalc = LedgerCalculator();
  static const StockCalculator _stockCalc = StockCalculator();

  LabourEntryEntity _mapLabour(LabourEntryRow r) => LabourEntryEntity(
    id: r.id,
    stockMovementId: r.stockMovementId,
    reversesLabourEntryId: r.reversesLabourEntryId,
    memberId: r.memberId,
    processId: r.processId,
    lotId: r.lotId,
    basisType: LabourBasisType.fromDbValue(r.basisType),
    quantity: r.quantity,
    ratePaise: r.ratePaise,
    amountPaise: r.amountPaise,
    isPayable: r.isPayable == 1,
    transactionAt: r.transactionAt,
    recordedAt: r.recordedAt,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  PaymentEntity _mapPayment(PaymentRow r) => PaymentEntity(
    id: r.id,
    memberId: r.memberId,
    paymentType: PaymentType.fromDbValue(r.paymentType),
    reversesPaymentId: r.reversesPaymentId,
    clientRequestId: r.clientRequestId,
    amountPaise: r.amountPaise,
    paymentMode: PaymentMode.fromDbValue(r.paymentMode),
    referenceNo: r.referenceNo,
    reason: r.reason,
    notes: r.notes,
    transactionAt: r.transactionAt,
    recordedAt: r.recordedAt,
    createdBy: r.createdBy,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  WorkerAdjustmentEntity _mapAdjustment(WorkerLedgerAdjustmentRow r) =>
      WorkerAdjustmentEntity(
        id: r.id,
        memberId: r.memberId,
        adjustmentType: WorkerAdjustmentType.fromDbValue(r.adjustmentType),
        reversesAdjustmentId: r.reversesAdjustmentId,
        clientRequestId: r.clientRequestId,
        amountPaise: r.amountPaise,
        reason: r.reason,
        notes: r.notes,
        transactionAt: r.transactionAt,
        recordedAt: r.recordedAt,
        createdBy: r.createdBy,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  StockMovementEntity _mapMovement(StockMovementRow row) => StockMovementEntity(
    id: row.id,
    lotId: row.lotId,
    lotDesignId: row.lotDesignId,
    designColourId: row.designColourId,
    processId: row.processId,
    memberId: row.memberId,
    parentIssueId: row.parentIssueId,
    reversesMovementId: row.reversesMovementId,
    clientRequestId: row.clientRequestId,
    movementType: StockMovementType.fromDbValue(row.movementType),
    quantity: row.quantity,
    sourceRateId: row.sourceRateId,
    appliedRatePaise: row.appliedRatePaise,
    isRateOverridden: row.isRateOverridden == 1,
    overrideReason: row.overrideReason,
    lockedBillingMode: row.lockedBillingMode != null
        ? BillingMode.fromDbValue(row.lockedBillingMode!)
        : null,
    lockedIncludeDamaged: row.lockedIncludeDamaged == 1,
    reason: row.reason,
    notes: row.notes,
    transactionAt: row.transactionAt,
    recordedAt: row.recordedAt,
    createdBy: row.createdBy,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  Future<String?> _resolveActor() async {
    final profile = await _db.businessProfileDao.getProfile();
    final owner = profile?.ownerName?.trim();
    return (owner != null && owner.isNotEmpty) ? owner : 'local_owner';
  }

  @override
  Future<List<WorkerFinancialSummary>> getAllWorkerSummaries() async {
    final workers = await _db.processMemberDao.getNonDeletedMembers();
    final allLabour = (await _db.labourEntryDao.getAllEntries())
        .map(_mapLabour)
        .toList();
    final allPayments = (await _db.paymentDao.getAllPayments())
        .map(_mapPayment)
        .toList();
    final allAdjustments = (await _db.workerAdjustmentDao.getAllAdjustments())
        .map(_mapAdjustment)
        .toList();

    final labourByWorker = <String, List<LabourEntryEntity>>{};
    for (final l in allLabour) {
      labourByWorker.putIfAbsent(l.memberId, () => []).add(l);
    }
    final paymentsByWorker = <String, List<PaymentEntity>>{};
    for (final p in allPayments) {
      paymentsByWorker.putIfAbsent(p.memberId, () => []).add(p);
    }
    final adjByWorker = <String, List<WorkerAdjustmentEntity>>{};
    for (final a in allAdjustments) {
      adjByWorker.putIfAbsent(a.memberId, () => []).add(a);
    }

    final summaries = workers
        .map(
          (w) => _ledgerCalc.calculateWorkerSummary(
            workerId: w.id,
            workerName: w.name,
            workerPhone: w.phone,
            workerIsActive: w.isActive == 1,
            labourEntries: labourByWorker[w.id] ?? const [],
            payments: paymentsByWorker[w.id] ?? const [],
            adjustments: adjByWorker[w.id] ?? const [],
          ),
        )
        .toList();

    summaries.sort((a, b) {
      final outCmp = b.outstandingPayablePaise.compareTo(
        a.outstandingPayablePaise,
      );
      if (outCmp != 0) return outCmp;
      return a.workerName.compareTo(b.workerName);
    });
    return summaries;
  }

  @override
  Future<WorkerLedgerDetail?> getWorkerLedgerDetail(
    String workerId, {
    int? fromUtcMillis,
    int? toUtcMillis,
  }) async {
    final worker = await _db.processMemberDao.findMemberById(workerId);
    if (worker == null || worker.deletedAt != null) return null;

    final labourEntries = (await _db.labourEntryDao.getEntriesForMember(
      workerId,
    )).map(_mapLabour).toList();
    final paymentList = (await _db.paymentDao.getPaymentsForMember(workerId))
        .map(_mapPayment)
        .toList();
    final adjustmentList =
        (await _db.workerAdjustmentDao.getAdjustmentsForMember(workerId))
            .map(_mapAdjustment)
            .toList();
    final movementList = (await _db.stockMovementDao.getMovementsForMember(
      workerId,
    )).map(_mapMovement).toList();

    final procs = await _db.select(_db.processes).get();
    final lots = await _db.select(_db.lots).get();
    final procNames = {for (final p in procs) p.id: p.name};
    final lotNumbers = {for (final l in lots) l.id: l.lotNumber};

    final summary = _ledgerCalc.calculateWorkerSummary(
      workerId: worker.id,
      workerName: worker.name,
      workerPhone: worker.phone,
      workerIsActive: worker.isActive == 1,
      labourEntries: labourEntries,
      payments: paymentList,
      adjustments: adjustmentList,
    );

    final ledgerResult = _ledgerCalc.buildLedgerLines(
      workerId: worker.id,
      labourEntries: labourEntries,
      payments: paymentList,
      adjustments: adjustmentList,
      processNamesById: procNames,
      lotNumbersById: lotNumbers,
      fromUtcMillis: fromUtcMillis,
      toUtcMillis: toUtcMillis,
    );

    final workerStockList = _stockCalc.calculateWorkerSummaries(
      allMovements: movementList,
      workerNamesById: {worker.id: worker.name},
    );
    final stockSummary = workerStockList.isNotEmpty
        ? workerStockList.first
        : WorkerStockSummary(
            workerId: worker.id,
            workerName: worker.name,
            issued: 0,
            goodReturned: 0,
            damaged: 0,
            lost: 0,
            shortage: 0,
            pending: 0,
            openIssuesCount: 0,
          );

    final processBreakdown = _stockCalc.calculateProcessSummaries(
      allMovements: movementList,
      processNamesById: procNames,
    );

    final revPaymentIds = _ledgerCalc.reversedPaymentIds(paymentList);
    final paymentViews = paymentList
        .map(
          (p) => PaymentView(
            payment: p,
            workerName: worker.name,
            isReversed: revPaymentIds.contains(p.id),
          ),
        )
        .toList();

    return WorkerLedgerDetail(
      summary: summary,
      lines: ledgerResult.lines,
      openingBalancePaise: ledgerResult.openingBalancePaise,
      stockSummary: stockSummary,
      processBreakdown: processBreakdown,
      payments: paymentViews,
      adjustments: adjustmentList,
    );
  }

  @override
  Future<List<LabourEntryView>> getLabourEntries({
    String? workerId,
    String? processId,
    String? lotId,
    int? fromUtcMillis,
    int? toUtcMillis,
    bool payableOnly = false,
  }) async {
    final all = (await _db.labourEntryDao.getAllEntries())
        .map(_mapLabour)
        .toList();
    final revIds = _ledgerCalc.reversedLabourIds(all);

    final workers = await _db.select(_db.members).get();
    final procs = await _db.select(_db.processes).get();
    final lots = await _db.select(_db.lots).get();
    final workerNames = {for (final w in workers) w.id: w.name};
    final procNames = {for (final p in procs) p.id: p.name};
    final lotNums = {for (final l in lots) l.id: l.lotNumber};

    final views = <LabourEntryView>[];
    for (final e in all) {
      if (workerId != null && e.memberId != workerId) continue;
      if (processId != null && e.processId != processId) continue;
      if (lotId != null && e.lotId != lotId) continue;
      if (fromUtcMillis != null && e.transactionAt < fromUtcMillis) continue;
      if (toUtcMillis != null && e.transactionAt > toUtcMillis) continue;
      if (payableOnly &&
          (!e.isPayable ||
              e.basisType == LabourBasisType.reversal ||
              revIds.contains(e.id))) {
        continue;
      }

      views.add(
        LabourEntryView(
          entry: e,
          workerName: workerNames[e.memberId] ?? e.memberId,
          processName: procNames[e.processId] ?? e.processId,
          lotNumber: lotNums[e.lotId] ?? e.lotId,
          isReversed: revIds.contains(e.id),
        ),
      );
    }
    return views;
  }

  @override
  Future<List<PaymentView>> getPayments({
    String? workerId,
    PaymentType? paymentType,
    int? fromUtcMillis,
    int? toUtcMillis,
  }) async {
    final all = (await _db.paymentDao.getAllPayments())
        .map(_mapPayment)
        .toList();
    final revIds = _ledgerCalc.reversedPaymentIds(all);
    final workers = await _db.select(_db.members).get();
    final workerNames = {for (final w in workers) w.id: w.name};

    final views = <PaymentView>[];
    for (final p in all) {
      if (workerId != null && p.memberId != workerId) continue;
      if (paymentType != null && p.paymentType != paymentType) continue;
      if (fromUtcMillis != null && p.transactionAt < fromUtcMillis) continue;
      if (toUtcMillis != null && p.transactionAt > toUtcMillis) continue;
      views.add(
        PaymentView(
          payment: p,
          workerName: workerNames[p.memberId] ?? p.memberId,
          isReversed: revIds.contains(p.id),
        ),
      );
    }
    return views;
  }

  @override
  Future<PaymentEntity> recordPayment({
    required String workerId,
    required PaymentType paymentType,
    required int amountPaise,
    required PaymentMode paymentMode,
    required int transactionAtUtcMillis,
    String? referenceNo,
    String? notes,
    String? clientRequestId,
  }) async {
    if (paymentType == PaymentType.reversal) {
      throw const DomainValidationException(
        'invalid_payment_type',
        'Use reversePayment() to reverse a payment.',
      );
    }
    if (amountPaise <= 0) {
      throw const DomainValidationException(
        'invalid_amount',
        'Payment amount must be greater than zero.',
      );
    }

    final reqId = clientRequestId?.trim().isEmpty ?? true
        ? _idGenerator.nextRequestId()
        : clientRequestId!.trim();

    return _txRunner.runInTransaction(() async {
      final existingByReq = await _db.paymentDao.findByClientRequestId(reqId);
      if (existingByReq != null) {
        return _mapPayment(existingByReq);
      }

      final worker = await _db.processMemberDao.findMemberById(workerId);
      if (worker == null || worker.deletedAt != null) {
        throw const DomainValidationException(
          'worker_not_found',
          'Worker was not found.',
        );
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await _resolveActor();
      final paymentId = _idGenerator.nextEntityId();
      final cleanedRef = referenceNo?.trim().isEmpty ?? true
          ? null
          : referenceNo!.trim();
      final cleanedNotes = notes?.trim().isEmpty ?? true ? null : notes!.trim();

      await _db.paymentDao.insertPayment(
        PaymentsCompanion(
          id: Value(paymentId),
          memberId: Value(worker.id),
          paymentType: Value(paymentType.dbValue),
          clientRequestId: Value(reqId),
          amountPaise: Value(amountPaise),
          paymentMode: Value(paymentMode.dbValue),
          referenceNo: Value(cleanedRef),
          notes: Value(cleanedNotes),
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
          entityType: const Value('payments'),
          entityId: Value(paymentId),
          actionType: const Value('CREATE'),
          actor: Value(actor),
          newValueJson: Value(
            jsonEncode({
              'worker': worker.name,
              'payment_type': paymentType.dbValue,
              'amount_paise': amountPaise,
              'payment_mode': paymentMode.dbValue,
              'reference_no': cleanedRef,
            }),
          ),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
        ),
      );

      final inserted = await _db.paymentDao.findById(paymentId);
      return _mapPayment(inserted!);
    });
  }

  @override
  Future<PaymentEntity> reversePayment({
    required String paymentId,
    required String reason,
    required int transactionAtUtcMillis,
    String? notes,
  }) async {
    if (reason.trim().isEmpty) {
      throw const DomainValidationException(
        'reason_required',
        'A reason is required to reverse a payment.',
      );
    }

    return _txRunner.runInTransaction(() async {
      final original = await _db.paymentDao.findById(paymentId);
      if (original == null) {
        throw const DomainValidationException(
          'payment_not_found',
          'Payment record was not found.',
        );
      }
      if (original.paymentType == PaymentType.reversal.dbValue) {
        throw const DomainValidationException(
          'cannot_reverse_reversal',
          'A reversal payment cannot itself be reversed.',
        );
      }
      final existingRev = await _db.paymentDao.findReversalForPayment(
        paymentId,
      );
      if (existingRev != null) {
        throw const DomainValidationException(
          'already_reversed',
          'This payment has already been reversed.',
        );
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await _resolveActor();
      final revId = _idGenerator.nextEntityId();
      final cleanedReason = reason.trim();
      final cleanedNotes = notes?.trim().isEmpty ?? true ? null : notes!.trim();

      await _db.paymentDao.insertPayment(
        PaymentsCompanion(
          id: Value(revId),
          memberId: Value(original.memberId),
          paymentType: Value(PaymentType.reversal.dbValue),
          reversesPaymentId: Value(original.id),
          amountPaise: Value(original.amountPaise),
          paymentMode: Value(original.paymentMode),
          referenceNo: Value(original.referenceNo),
          reason: Value(cleanedReason),
          notes: Value(cleanedNotes),
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
          entityType: const Value('payments'),
          entityId: Value(revId),
          actionType: const Value('REVERSAL'),
          actor: Value(actor),
          previousValueJson: Value(
            jsonEncode({
              'reversed_payment_id': original.id,
              'payment_type': original.paymentType,
              'amount_paise': original.amountPaise,
            }),
          ),
          newValueJson: Value(
            jsonEncode({'reversal_id': revId, 'reason': cleanedReason}),
          ),
          reason: Value(cleanedReason),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
        ),
      );

      final inserted = await _db.paymentDao.findById(revId);
      return _mapPayment(inserted!);
    });
  }

  @override
  Future<WorkerAdjustmentEntity> recordAdjustment({
    required String workerId,
    required WorkerAdjustmentType adjustmentType,
    required int amountPaise,
    required String reason,
    required int transactionAtUtcMillis,
    String? notes,
    String? clientRequestId,
  }) async {
    if (adjustmentType == WorkerAdjustmentType.reversal) {
      throw const DomainValidationException(
        'invalid_adjustment_type',
        'Use reverseAdjustment() to reverse an adjustment.',
      );
    }
    if (amountPaise <= 0) {
      throw const DomainValidationException(
        'invalid_amount',
        'Adjustment amount must be greater than zero.',
      );
    }
    if (reason.trim().isEmpty) {
      throw const DomainValidationException(
        'reason_required',
        'A reason is required for a worker ledger adjustment.',
      );
    }

    final reqId = clientRequestId?.trim().isEmpty ?? true
        ? _idGenerator.nextRequestId()
        : clientRequestId!.trim();

    return _txRunner.runInTransaction(() async {
      final existingByReq = await _db.workerAdjustmentDao.findByClientRequestId(
        reqId,
      );
      if (existingByReq != null) {
        return _mapAdjustment(existingByReq);
      }

      final worker = await _db.processMemberDao.findMemberById(workerId);
      if (worker == null || worker.deletedAt != null) {
        throw const DomainValidationException(
          'worker_not_found',
          'Worker was not found.',
        );
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await _resolveActor();
      final adjId = _idGenerator.nextEntityId();
      final cleanedReason = reason.trim();
      final cleanedNotes = notes?.trim().isEmpty ?? true ? null : notes!.trim();

      await _db.workerAdjustmentDao.insertAdjustment(
        WorkerLedgerAdjustmentsCompanion(
          id: Value(adjId),
          memberId: Value(worker.id),
          adjustmentType: Value(adjustmentType.dbValue),
          clientRequestId: Value(reqId),
          amountPaise: Value(amountPaise),
          reason: Value(cleanedReason),
          notes: Value(cleanedNotes),
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
          entityType: const Value('worker_ledger_adjustments'),
          entityId: Value(adjId),
          actionType: const Value('CREATE'),
          actor: Value(actor),
          newValueJson: Value(
            jsonEncode({
              'worker': worker.name,
              'adjustment_type': adjustmentType.dbValue,
              'amount_paise': amountPaise,
              'reason': cleanedReason,
            }),
          ),
          reason: Value(cleanedReason),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
        ),
      );

      final inserted = await _db.workerAdjustmentDao.findById(adjId);
      return _mapAdjustment(inserted!);
    });
  }

  @override
  Future<WorkerAdjustmentEntity> reverseAdjustment({
    required String adjustmentId,
    required String reason,
    required int transactionAtUtcMillis,
    String? notes,
  }) async {
    if (reason.trim().isEmpty) {
      throw const DomainValidationException(
        'reason_required',
        'A reason is required to reverse an adjustment.',
      );
    }

    return _txRunner.runInTransaction(() async {
      final original = await _db.workerAdjustmentDao.findById(adjustmentId);
      if (original == null) {
        throw const DomainValidationException(
          'adjustment_not_found',
          'Adjustment record was not found.',
        );
      }
      if (original.adjustmentType == WorkerAdjustmentType.reversal.dbValue) {
        throw const DomainValidationException(
          'cannot_reverse_reversal',
          'A reversal adjustment cannot itself be reversed.',
        );
      }
      final existingRev = await _db.workerAdjustmentDao
          .findReversalForAdjustment(adjustmentId);
      if (existingRev != null) {
        throw const DomainValidationException(
          'already_reversed',
          'This adjustment has already been reversed.',
        );
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await _resolveActor();
      final revId = _idGenerator.nextEntityId();
      final cleanedReason = reason.trim();
      final cleanedNotes = notes?.trim().isEmpty ?? true ? null : notes!.trim();

      await _db.workerAdjustmentDao.insertAdjustment(
        WorkerLedgerAdjustmentsCompanion(
          id: Value(revId),
          memberId: Value(original.memberId),
          adjustmentType: Value(WorkerAdjustmentType.reversal.dbValue),
          reversesAdjustmentId: Value(original.id),
          amountPaise: Value(original.amountPaise),
          reason: Value(cleanedReason),
          notes: Value(cleanedNotes),
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
          entityType: const Value('worker_ledger_adjustments'),
          entityId: Value(revId),
          actionType: const Value('REVERSAL'),
          actor: Value(actor),
          previousValueJson: Value(
            jsonEncode({
              'reversed_adjustment_id': original.id,
              'adjustment_type': original.adjustmentType,
              'amount_paise': original.amountPaise,
            }),
          ),
          newValueJson: Value(
            jsonEncode({'reversal_id': revId, 'reason': cleanedReason}),
          ),
          reason: Value(cleanedReason),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
        ),
      );

      final inserted = await _db.workerAdjustmentDao.findById(revId);
      return _mapAdjustment(inserted!);
    });
  }
}
