import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/database/mappers/actor_resolver.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/process_routing/data/repositories/process_routing_handover_delegate.dart';
import 'package:business_manager/features/process_routing/data/repositories/process_routing_read_delegate.dart';
import 'package:business_manager/features/process_routing/data/repositories/process_routing_support.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/process_routing/domain/repositories/process_routing_repository.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

/// Production implementation of [ProcessRoutingRepository] delegating read
/// hydration and handover workflows to focused data collaborators.
@LazySingleton(as: ProcessRoutingRepository)
final class ProcessRoutingRepositoryImpl implements ProcessRoutingRepository {
  ProcessRoutingRepositoryImpl(
    this._db,
    this._txRunner,
    this._stockRepo,
    this._idGenerator,
  ) : _support = ProcessRoutingSupport(_db, _stockRepo, _idGenerator),
      _readDelegate = ProcessRoutingReadDelegate(_db, _stockRepo) {
    _handoverDelegate = ProcessRoutingHandoverDelegate(
      _db,
      _txRunner,
      _stockRepo,
      _idGenerator,
      _support,
      _readDelegate,
    );
  }

  final AppDatabase _db;
  final DatabaseTransactionRunner _txRunner;
  final StockMovementRepository _stockRepo;
  final IdGenerator _idGenerator;
  final ProcessRoutingSupport _support;
  final ProcessRoutingReadDelegate _readDelegate;
  late final ProcessRoutingHandoverDelegate _handoverDelegate;

  @override
  Future<JobRoutingOverview?> getJobRoutingOverview(String lotId) =>
      _readDelegate.getJobRoutingOverview(lotId);

  @override
  Future<List<ProcessRateHistoryEntity>> getProcessRateHistory(
    String processId,
  ) => _readDelegate.getProcessRateHistory(processId);

  @override
  Future<ProcessDefaultPricing> updateProcessDefaultRate({
    required String processId,
    required int defaultRatePaise,
    required String defaultPricingUnit,
    required String reason,
  }) async {
    if (defaultRatePaise < 0) _support.throwValidation('invalid_rate');
    final cleanUnit = defaultPricingUnit.trim().toUpperCase();
    if (cleanUnit.isEmpty) _support.throwValidation('pricing_unit_required');
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) _support.throwValidation('reason_required');

    final proc = await _db.processMemberDao.findProcessById(processId);
    if (proc == null || proc.deletedAt != null) {
      _support.throwValidation('process_not_found');
    }

    final actor = await ActorResolver.resolveRequired(_db);
    final now = IstDateTimeHelper.nowUtcMillis();

    await _txRunner.runInTransaction(() async {
      await _db.processMemberDao.updateProcessById(
        processId,
        ProcessesCompanion(
          defaultRatePaise: Value(defaultRatePaise),
          defaultPricingUnit: Value(cleanUnit),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );

      await _db.jobProcessDao.insertRateHistory(
        ProcessRateHistoriesCompanion.insert(
          id: _idGenerator.nextEntityId(),
          scope: 'PROCESS_DEFAULT',
          processId: processId,
          previousRatePaise: proc.defaultRatePaise,
          newRatePaise: defaultRatePaise,
          pricingUnit: cleanUnit,
          reason: cleanReason,
          changedBy: Value(actor),
          changedAt: now,
        ),
      );

      await _support.writeAudit(
        entityType: 'PROCESS',
        entityId: processId,
        actionType: 'UPDATE',
        actor: actor,
        payload: {
          'previousDefaultRatePaise': proc.defaultRatePaise,
          'newDefaultRatePaise': defaultRatePaise,
          'defaultPricingUnit': cleanUnit,
        },
        transactionAt: now,
        now: now,
        reason: cleanReason,
      );
    });

    return ProcessDefaultPricing(
      processId: processId,
      defaultRatePaise: defaultRatePaise,
      defaultPricingUnit: cleanUnit,
    );
  }

  @override
  Future<JobProcessEntity> addJobProcess({
    required String lotId,
    required String designColourId,
    required String processId,
    required String workerId,
    required int quantity,
    required int transactionAtUtcMillis,
    bool dispatchImmediately = true,
    int? agreedRatePaise,
    String? pricingUnit,
    String? rateOverrideReason,
    String? notes,
    String? clientRequestId,
  }) async {
    final trimmedReqId = clientRequestId?.trim();
    if (trimmedReqId != null && trimmedReqId.isNotEmpty) {
      final existingHandover = await _db.jobProcessDao
          .findHandoverByClientRequestId(trimmedReqId);
      if (existingHandover != null && existingHandover.toJobProcessId != null) {
        final existingJp = await _db.jobProcessDao.findJobProcessById(
          existingHandover.toJobProcessId!,
        );
        if (existingJp != null) {
          return _readDelegate.hydrateJobProcess(existingJp);
        }
      }
    }

    final balance = await _stockRepo.getDesignColourBalance(designColourId);
    if (balance == null || balance.lotId != lotId) {
      _support.throwValidation('sku_not_found');
    }

    if (dispatchImmediately) {
      final err = ProcessRoutingSupport.validator.validateFactoryDispatch(
        designColourId: designColourId,
        processId: processId,
        workerId: workerId,
        quantity: quantity,
        availableInHouse: balance.physicalAvailableInHouse,
      );
      if (err != null) _support.throwValidation(err);
    } else {
      if (quantity <= 0) _support.throwValidation('invalid_quantity');
      if (processId.trim().isEmpty) {
        _support.throwValidation('process_required');
      }
      if (workerId.trim().isEmpty) _support.throwValidation('worker_required');
    }

    final pricing = await _support.resolveAssignmentPricing(
      processId: processId,
      workerId: workerId,
      quantity: quantity,
      transactionAtUtcMillis: transactionAtUtcMillis,
      requestedAgreedRatePaise: agreedRatePaise,
      requestedPricingUnit: pricingUnit,
      requestedOverrideReason: rateOverrideReason,
    );

    final actor = await ActorResolver.resolveRequired(_db);
    final now = IstDateTimeHelper.nowUtcMillis();
    final jpId = _idGenerator.nextEntityId();

    await _txRunner.runInTransaction(() async {
      final nextSeq = await _db.jobProcessDao.getNextSequenceOrderForLot(lotId);
      String? linkedIssueId;

      if (dispatchImmediately) {
        final issue = await _support.issueStockWithResolvedRate(
          designColourId: designColourId,
          processId: processId,
          workerId: workerId,
          quantity: quantity,
          transactionAtUtcMillis: transactionAtUtcMillis,
          effectivePerPieceRatePaise: pricing.perPieceRatePaise,
          overrideReason: pricing.overrideReason,
          notes: notes,
          jobProcessId: jpId,
          clientRequestId: trimmedReqId != null && trimmedReqId.isNotEmpty
              ? 'jp_iss_$trimmedReqId'
              : null,
        );
        linkedIssueId = issue.id;
      }

      final initialStatus = dispatchImmediately
          ? JobProcessStatus.dispatched
          : JobProcessStatus.pending;

      await _db.jobProcessDao.insertJobProcess(
        JobProcessesCompanion.insert(
          id: jpId,
          lotId: lotId,
          lotDesignId: balance.lotDesignId,
          designColourId: designColourId,
          processId: processId,
          memberId: Value(workerId),
          sequenceOrder: Value(nextSeq),
          plannedQuantity: quantity,
          dispatchedQuantity: Value(dispatchImmediately ? quantity : 0),
          receivedQuantity: const Value(0),
          status: Value(initialStatus.dbValue),
          linkedIssueMovementId: Value(linkedIssueId),
          defaultRatePaise: Value(pricing.defaultRatePaise),
          agreedRatePaise: Value(pricing.agreedRatePaise),
          pricingUnit: Value(pricing.pricingUnit),
          rateOverrideReason: Value(pricing.overrideReason),
          payableAmountPaise: Value(pricing.payableAmountPaise),
          paidAmountPaise: const Value(0),
          paymentStatus: Value(
            ProcessRoutingSupport.pricingCalc
                .resolvePaymentStatus(
                  netPayablePaise: pricing.payableAmountPaise,
                  paidPaise: 0,
                )
                .dbValue,
          ),
          notes: Value(notes?.trim()),
          transactionAt: transactionAtUtcMillis,
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: now,
          updatedAt: now,
        ),
      );

      if (pricing.isOverridden) {
        await _db.jobProcessDao.insertRateHistory(
          ProcessRateHistoriesCompanion.insert(
            id: _idGenerator.nextEntityId(),
            scope: 'JOB_ASSIGNMENT',
            processId: processId,
            jobProcessId: Value(jpId),
            memberId: Value(workerId),
            designColourId: Value(designColourId),
            previousRatePaise: pricing.defaultRatePaise,
            newRatePaise: pricing.agreedRatePaise,
            pricingUnit: pricing.pricingUnit,
            reason: pricing.overrideReason!,
            changedBy: Value(actor),
            changedAt: now,
          ),
        );
      }

      if (dispatchImmediately) {
        final handoverId = _idGenerator.nextEntityId();
        final ref = ProcessRoutingSupport.validator.generateReference(
          type: ProcessHandoverType.factoryDispatch,
          transactionAtUtcMillis: transactionAtUtcMillis,
          uniqueId: handoverId,
        );
        await _db.jobProcessDao.insertHandover(
          ProcessHandoversCompanion.insert(
            id: handoverId,
            transferReference: ref,
            clientRequestId: Value(
              trimmedReqId != null && trimmedReqId.isNotEmpty
                  ? trimmedReqId
                  : null,
            ),
            lotId: lotId,
            lotDesignId: balance.lotDesignId,
            designColourId: designColourId,
            handoverType: ProcessHandoverType.factoryDispatch.dbValue,
            toJobProcessId: Value(jpId),
            toMemberId: Value(workerId),
            processId: processId,
            quantityDispatched: quantity,
            quantityReceived: const Value(0),
            status: Value(ProcessHandoverStatus.pendingReceipt.dbValue),
            linkedStockMovementId: Value(linkedIssueId),
            notes: Value(notes?.trim()),
            transactionAt: transactionAtUtcMillis,
            recordedAt: now,
            createdBy: Value(actor),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      await _support.writeAudit(
        entityType: 'JOB_PROCESS',
        entityId: jpId,
        actionType: 'CREATE',
        actor: actor,
        payload: {
          'lotId': lotId,
          'designColourId': designColourId,
          'processId': processId,
          'workerId': workerId,
          'quantity': quantity,
          'defaultRatePaise': pricing.defaultRatePaise,
          'agreedRatePaise': pricing.agreedRatePaise,
          'pricingUnit': pricing.pricingUnit,
          'payableAmountPaise': pricing.payableAmountPaise,
          'dispatched': dispatchImmediately,
        },
        transactionAt: transactionAtUtcMillis,
        now: now,
        reason: pricing.overrideReason,
      );
    });

    final created = await _db.jobProcessDao.findJobProcessById(jpId);
    return _readDelegate.hydrateJobProcess(created!);
  }

  @override
  Future<JobProcessEntity> editJobProcess({
    required String jobProcessId,
    String? workerId,
    int? plannedQuantity,
    String? notes,
  }) async {
    final row = await _db.jobProcessDao.findJobProcessById(jobProcessId);
    if (row == null || row.deletedAt != null) {
      _support.throwValidation('process_not_found');
    }
    final currentStatus = JobProcessStatus.fromDbValue(row.status);
    if (currentStatus.isTerminal) {
      _support.throwValidation('process_already_closed');
    }
    if (plannedQuantity != null && plannedQuantity < row.dispatchedQuantity) {
      _support.throwValidation('invalid_quantity');
    }
    if (plannedQuantity != null && plannedQuantity <= 0) {
      _support.throwValidation('invalid_quantity');
    }

    final actor = await ActorResolver.resolveRequired(_db);
    final now = IstDateTimeHelper.nowUtcMillis();
    final newPlanned = plannedQuantity ?? row.plannedQuantity;
    final recomputedPayable = ProcessRoutingSupport.pricingCalc
        .calculateBaseAmountPaise(
          quantity: newPlanned,
          ratePaise: row.agreedRatePaise,
          pricingUnit: row.pricingUnit,
        );

    await _txRunner.runInTransaction(() async {
      await _db.jobProcessDao.updateJobProcess(
        jobProcessId,
        JobProcessesCompanion(
          memberId: workerId != null && row.dispatchedQuantity == 0
              ? Value(workerId)
              : const Value.absent(),
          plannedQuantity: plannedQuantity != null
              ? Value(plannedQuantity)
              : const Value.absent(),
          payableAmountPaise: Value(recomputedPayable),
          notes: notes != null ? Value(notes.trim()) : const Value.absent(),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );
      await _support.writeAudit(
        entityType: 'JOB_PROCESS',
        entityId: jobProcessId,
        actionType: 'UPDATE',
        actor: actor,
        payload: {
          'workerId': workerId,
          'plannedQuantity': plannedQuantity,
          'notes': notes,
        },
        transactionAt: row.transactionAt,
        now: now,
      );
    });

    final updated = await _db.jobProcessDao.findJobProcessById(jobProcessId);
    return _readDelegate.hydrateJobProcess(updated!);
  }

  @override
  Future<ProcessHandoverEntity> dispatchJobProcess({
    required String jobProcessId,
    required int quantity,
    required int transactionAtUtcMillis,
    String? notes,
    String? clientRequestId,
  }) => _handoverDelegate.dispatchJobProcess(
    jobProcessId: jobProcessId,
    quantity: quantity,
    transactionAtUtcMillis: transactionAtUtcMillis,
    notes: notes,
    clientRequestId: clientRequestId,
  );

  @override
  Future<ProcessHandoverEntity> confirmHandoverReceipt({
    required String handoverId,
    required int receivedQuantity,
    required int transactionAtUtcMillis,
  }) => _handoverDelegate.confirmHandoverReceipt(
    handoverId: handoverId,
    receivedQuantity: receivedQuantity,
    transactionAtUtcMillis: transactionAtUtcMillis,
  );

  @override
  Future<ProcessHandoverEntity> directTransfer({
    required String sourceJobProcessId,
    required String destinationProcessId,
    required String destinationWorkerId,
    required int quantity,
    required int transactionAtUtcMillis,
    bool autoConfirmReceipt = false,
    int? agreedRatePaise,
    String? pricingUnit,
    String? rateOverrideReason,
    String? notes,
    String? clientRequestId,
  }) => _handoverDelegate.directTransfer(
    sourceJobProcessId: sourceJobProcessId,
    destinationProcessId: destinationProcessId,
    destinationWorkerId: destinationWorkerId,
    quantity: quantity,
    transactionAtUtcMillis: transactionAtUtcMillis,
    autoConfirmReceipt: autoConfirmReceipt,
    agreedRatePaise: agreedRatePaise,
    pricingUnit: pricingUnit,
    rateOverrideReason: rateOverrideReason,
    notes: notes,
    clientRequestId: clientRequestId,
  );

  @override
  Future<ProcessHandoverEntity> returnToFactory({
    required String sourceJobProcessId,
    required int goodQuantity,
    int damagedQuantity = 0,
    required int transactionAtUtcMillis,
    String? reason,
    String? notes,
    String? clientRequestId,
  }) => _handoverDelegate.returnToFactory(
    sourceJobProcessId: sourceJobProcessId,
    goodQuantity: goodQuantity,
    damagedQuantity: damagedQuantity,
    transactionAtUtcMillis: transactionAtUtcMillis,
    reason: reason,
    notes: notes,
    clientRequestId: clientRequestId,
  );

  @override
  Future<ProcessHandoverEntity> reassignFromFactory({
    required String lotId,
    required String designColourId,
    required String targetProcessId,
    required String targetWorkerId,
    required int quantity,
    required int transactionAtUtcMillis,
    int? agreedRatePaise,
    String? pricingUnit,
    String? rateOverrideReason,
    String? notes,
    String? clientRequestId,
  }) => _handoverDelegate.reassignFromFactory(
    lotId: lotId,
    designColourId: designColourId,
    targetProcessId: targetProcessId,
    targetWorkerId: targetWorkerId,
    quantity: quantity,
    transactionAtUtcMillis: transactionAtUtcMillis,
    agreedRatePaise: agreedRatePaise,
    pricingUnit: pricingUnit,
    rateOverrideReason: rateOverrideReason,
    notes: notes,
    clientRequestId: clientRequestId,
  );

  @override
  Future<ProcessAdditionalChargeEntity> addAdditionalCharge({
    required String jobProcessId,
    required ProcessChargeType chargeType,
    required String description,
    required int amountPaise,
    required int transactionAtUtcMillis,
    String? clientRequestId,
  }) async {
    final trimmedReqId = clientRequestId?.trim();
    if (trimmedReqId != null && trimmedReqId.isNotEmpty) {
      final existing = await _db.jobProcessDao.findChargeByClientRequestId(
        trimmedReqId,
      );
      if (existing != null) return _readDelegate.mapCharge(existing);
    }

    if (amountPaise <= 0) _support.throwValidation('invalid_amount');
    final cleanDesc = description.trim();
    if (cleanDesc.isEmpty) _support.throwValidation('description_required');

    final jp = await _db.jobProcessDao.findJobProcessById(jobProcessId);
    if (jp == null || jp.deletedAt != null || jp.memberId == null) {
      _support.throwValidation('process_not_found');
    }

    final actor = await ActorResolver.resolveRequired(_db);
    final now = IstDateTimeHelper.nowUtcMillis();
    final chargeId = _idGenerator.nextEntityId();
    final adjustmentId = _idGenerator.nextEntityId();
    final isExtra = chargeType == ProcessChargeType.extraCharge;

    await _txRunner.runInTransaction(() async {
      await _db.workerAdjustmentDao.insertAdjustment(
        WorkerLedgerAdjustmentsCompanion.insert(
          id: adjustmentId,
          memberId: jp.memberId!,
          adjustmentType: isExtra ? 'CREDIT' : 'DEBIT',
          clientRequestId: Value('pac_$chargeId'),
          amountPaise: amountPaise,
          reason: cleanDesc,
          notes: const Value('Routing charge'),
          sourceChargeId: Value(chargeId),
          jobProcessId: Value(jp.id),
          transactionAt: transactionAtUtcMillis,
          recordedAt: now,
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await _db.jobProcessDao.insertAdditionalCharge(
        ProcessAdditionalChargesCompanion.insert(
          id: chargeId,
          jobProcessId: jp.id,
          lotId: jp.lotId,
          designColourId: jp.designColourId,
          memberId: jp.memberId!,
          chargeType: chargeType.dbValue,
          description: cleanDesc,
          amountPaise: amountPaise,
          clientRequestId: Value(
            trimmedReqId != null && trimmedReqId.isNotEmpty
                ? trimmedReqId
                : null,
          ),
          createdBy: Value(actor),
          transactionAt: transactionAtUtcMillis,
          createdAt: now,
          ledgerAdjustmentId: Value(adjustmentId),
        ),
      );

      final allOpCharges = await _db.jobProcessDao.getChargesForJobProcess(
        jp.id,
      );
      var extra = 0;
      var deduct = 0;
      for (final c in allOpCharges) {
        if (c.chargeType == ProcessChargeType.extraCharge.dbValue) {
          extra += c.amountPaise;
        } else {
          deduct += c.amountPaise;
        }
      }
      final netPayable = (jp.payableAmountPaise + extra - deduct).clamp(
        0,
        1 << 62,
      );
      final payStatus = ProcessRoutingSupport.pricingCalc.resolvePaymentStatus(
        netPayablePaise: netPayable,
        paidPaise: jp.paidAmountPaise,
      );

      await _db.jobProcessDao.updateJobProcess(
        jp.id,
        JobProcessesCompanion(
          paymentStatus: Value(payStatus.dbValue),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );

      await _support.writeAudit(
        entityType: 'PROCESS_CHARGE',
        entityId: chargeId,
        actionType: 'CREATE',
        actor: actor,
        payload: {
          'jobProcessId': jp.id,
          'chargeType': chargeType.dbValue,
          'description': cleanDesc,
          'amountPaise': amountPaise,
          'ledgerAdjustmentId': adjustmentId,
        },
        transactionAt: transactionAtUtcMillis,
        now: now,
      );
    });

    final rows = await _db.jobProcessDao.getChargesForJobProcess(jp.id);
    return _readDelegate.mapCharge(rows.firstWhere((r) => r.id == chargeId));
  }

  @override
  Future<JobProcessEntity> markProcessCompleted({
    required String jobProcessId,
    required int transactionAtUtcMillis,
  }) async {
    final row = await _db.jobProcessDao.findJobProcessById(jobProcessId);
    if (row == null || row.deletedAt != null) {
      _support.throwValidation('process_not_found');
    }
    final entity = await _readDelegate.hydrateJobProcess(row);
    final err = ProcessRoutingSupport.validator.validateCompletion(entity);
    if (err != null) _support.throwValidation(err);

    final actor = await ActorResolver.resolveRequired(_db);
    final now = IstDateTimeHelper.nowUtcMillis();

    await _txRunner.runInTransaction(() async {
      await _db.jobProcessDao.updateJobProcess(
        jobProcessId,
        JobProcessesCompanion(
          status: Value(JobProcessStatus.completed.dbValue),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );
      await _support.writeAudit(
        entityType: 'JOB_PROCESS',
        entityId: jobProcessId,
        actionType: 'UPDATE',
        actor: actor,
        payload: {'status': JobProcessStatus.completed.dbValue},
        transactionAt: transactionAtUtcMillis,
        now: now,
      );
    });

    final updated = await _db.jobProcessDao.findJobProcessById(jobProcessId);
    return _readDelegate.hydrateJobProcess(updated!);
  }

  @override
  Future<JobProcessEntity> cancelJobProcess({
    required String jobProcessId,
    required String reason,
    required int transactionAtUtcMillis,
  }) async {
    if (reason.trim().isEmpty) _support.throwValidation('reason_required');
    final row = await _db.jobProcessDao.findJobProcessById(jobProcessId);
    if (row == null || row.deletedAt != null) {
      _support.throwValidation('process_not_found');
    }
    final entity = await _readDelegate.hydrateJobProcess(row);
    final err = ProcessRoutingSupport.validator.validateCancellation(entity);
    if (err != null) _support.throwValidation(err);

    final actor = await ActorResolver.resolveRequired(_db);
    final now = IstDateTimeHelper.nowUtcMillis();
    final handoverId = _idGenerator.nextEntityId();
    final ref = ProcessRoutingSupport.validator.generateReference(
      type: ProcessHandoverType.cancellation,
      transactionAtUtcMillis: transactionAtUtcMillis,
      uniqueId: handoverId,
    );

    await _txRunner.runInTransaction(() async {
      await _db.jobProcessDao.updateJobProcess(
        jobProcessId,
        JobProcessesCompanion(
          status: Value(JobProcessStatus.cancelled.dbValue),
          notes: Value(reason.trim()),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );

      await _db.jobProcessDao.insertHandover(
        ProcessHandoversCompanion.insert(
          id: handoverId,
          transferReference: ref,
          lotId: row.lotId,
          lotDesignId: row.lotDesignId,
          designColourId: row.designColourId,
          handoverType: ProcessHandoverType.cancellation.dbValue,
          fromJobProcessId: Value(row.id),
          fromMemberId: Value(row.memberId),
          processId: row.processId,
          quantityDispatched: 0,
          quantityReceived: const Value(0),
          status: Value(ProcessHandoverStatus.cancelled.dbValue),
          notes: Value(reason.trim()),
          transactionAt: transactionAtUtcMillis,
          recordedAt: now,
          createdBy: Value(actor),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await _support.writeAudit(
        entityType: 'JOB_PROCESS',
        entityId: jobProcessId,
        actionType: 'UPDATE',
        actor: actor,
        payload: {
          'event': 'CANCELLED',
          'reason': reason.trim(),
          'reference': ref,
        },
        transactionAt: transactionAtUtcMillis,
        now: now,
        reason: reason.trim(),
      );
    });

    final updated = await _db.jobProcessDao.findJobProcessById(jobProcessId);
    return _readDelegate.hydrateJobProcess(updated!);
  }
}
