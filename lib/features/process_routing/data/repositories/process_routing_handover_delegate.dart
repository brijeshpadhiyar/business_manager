import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/database/mappers/actor_resolver.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/process_routing/data/repositories/process_routing_read_delegate.dart';
import 'package:business_manager/features/process_routing/data/repositories/process_routing_support.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:drift/drift.dart';

/// Transactional handover, direct transfer, factory return, and reassignment
/// workflows for [ProcessRoutingRepositoryImpl].
final class ProcessRoutingHandoverDelegate {
  const ProcessRoutingHandoverDelegate(
    this._db,
    this._txRunner,
    this._stockRepo,
    this._idGenerator,
    this._support,
    this._readDelegate,
  );

  final AppDatabase _db;
  final DatabaseTransactionRunner _txRunner;
  final StockMovementRepository _stockRepo;
  final IdGenerator _idGenerator;
  final ProcessRoutingSupport _support;
  final ProcessRoutingReadDelegate _readDelegate;

  Future<ProcessHandoverEntity> dispatchJobProcess({
    required String jobProcessId,
    required int quantity,
    required int transactionAtUtcMillis,
    String? notes,
    String? clientRequestId,
  }) async {
    final trimmedReqId = clientRequestId?.trim();
    if (trimmedReqId != null && trimmedReqId.isNotEmpty) {
      final existing = await _db.jobProcessDao.findHandoverByClientRequestId(
        trimmedReqId,
      );
      if (existing != null) return _readDelegate.hydrateHandover(existing);
    }

    final row = await _db.jobProcessDao.findJobProcessById(jobProcessId);
    if (row == null || row.deletedAt != null) {
      _support.throwValidation('process_not_found');
    }
    final status = JobProcessStatus.fromDbValue(row.status);
    if (status.isTerminal) {
      _support.throwValidation('process_already_closed');
    }
    final balance = await _stockRepo.getDesignColourBalance(row.designColourId);
    if (balance == null) _support.throwValidation('sku_not_found');

    final err = ProcessRoutingSupport.validator.validateFactoryDispatch(
      designColourId: row.designColourId,
      processId: row.processId,
      workerId: row.memberId,
      quantity: quantity,
      availableInHouse: balance.physicalAvailableInHouse,
    );
    if (err != null) _support.throwValidation(err);

    final actor = await ActorResolver.resolveRequired(_db);
    final now = IstDateTimeHelper.nowUtcMillis();
    final handoverId = _idGenerator.nextEntityId();
    final perPiece = ProcessRoutingSupport.pricingCalc
        .effectivePerPieceRatePaise(
          quantity: quantity,
          ratePaise: row.agreedRatePaise,
          pricingUnit: row.pricingUnit,
        );

    await _txRunner.runInTransaction(() async {
      final issue = await _support.issueStockWithResolvedRate(
        designColourId: row.designColourId,
        processId: row.processId,
        workerId: row.memberId!,
        quantity: quantity,
        transactionAtUtcMillis: transactionAtUtcMillis,
        effectivePerPieceRatePaise: perPiece,
        overrideReason: row.rateOverrideReason,
        notes: notes ?? row.notes,
        jobProcessId: row.id,
        clientRequestId: trimmedReqId != null && trimmedReqId.isNotEmpty
            ? 'jp_dsp_$trimmedReqId'
            : null,
      );

      final newDispatched = row.dispatchedQuantity + quantity;
      final newPlanned = newDispatched > row.plannedQuantity
          ? newDispatched
          : row.plannedQuantity;
      final newPayable = ProcessRoutingSupport.pricingCalc
          .calculateBaseAmountPaise(
            quantity: newPlanned,
            ratePaise: row.agreedRatePaise,
            pricingUnit: row.pricingUnit,
          );
      final nextStatus = ProcessRoutingSupport.validator.resolveStatus(
        dispatchedQty: newDispatched,
        receivedQty: row.receivedQuantity,
        returnedQty: row.returnedToFactoryQuantity,
        transferredOutQty: row.transferredOutQuantity,
        damagedQty: row.damagedQuantity,
        isCancelled: false,
      );

      await _db.jobProcessDao.updateJobProcess(
        row.id,
        JobProcessesCompanion(
          plannedQuantity: Value(newPlanned),
          dispatchedQuantity: Value(newDispatched),
          payableAmountPaise: Value(newPayable),
          status: Value(nextStatus.dbValue),
          linkedIssueMovementId: Value(row.linkedIssueMovementId ?? issue.id),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );

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
          lotId: row.lotId,
          lotDesignId: row.lotDesignId,
          designColourId: row.designColourId,
          handoverType: ProcessHandoverType.factoryDispatch.dbValue,
          toJobProcessId: Value(row.id),
          toMemberId: Value(row.memberId),
          processId: row.processId,
          quantityDispatched: quantity,
          quantityReceived: const Value(0),
          status: Value(ProcessHandoverStatus.pendingReceipt.dbValue),
          linkedStockMovementId: Value(issue.id),
          notes: Value(notes?.trim()),
          transactionAt: transactionAtUtcMillis,
          recordedAt: now,
          createdBy: Value(actor),
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    final created = await _db.jobProcessDao.findHandoverById(handoverId);
    return _readDelegate.hydrateHandover(created!);
  }

  Future<ProcessHandoverEntity> confirmHandoverReceipt({
    required String handoverId,
    required int receivedQuantity,
    required int transactionAtUtcMillis,
  }) async {
    final row = await _db.jobProcessDao.findHandoverById(handoverId);
    if (row == null) _support.throwValidation('handover_not_found');

    final currentStatus = ProcessHandoverStatus.fromDbValue(row.status);
    final err = ProcessRoutingSupport.validator.validateReceiptConfirmation(
      quantityDispatched: row.quantityDispatched,
      alreadyReceived: row.quantityReceived,
      receiveNow: receivedQuantity,
      currentStatus: currentStatus,
    );
    if (err != null) _support.throwValidation(err);

    final actor = await ActorResolver.resolveRequired(_db);
    final now = IstDateTimeHelper.nowUtcMillis();
    final newReceived = row.quantityReceived + receivedQuantity;
    final nextHandoverStatus = newReceived >= row.quantityDispatched
        ? ProcessHandoverStatus.received
        : ProcessHandoverStatus.partiallyReceived;

    await _txRunner.runInTransaction(() async {
      await _db.jobProcessDao.updateHandoverReceipt(
        handoverId,
        quantityReceived: newReceived,
        status: nextHandoverStatus.dbValue,
        updatedAt: now,
      );

      if (row.toJobProcessId != null) {
        final targetJp = await _db.jobProcessDao.findJobProcessById(
          row.toJobProcessId!,
        );
        if (targetJp != null) {
          final updatedReceived = targetJp.receivedQuantity + receivedQuantity;
          final nextJpStatus = ProcessRoutingSupport.validator.resolveStatus(
            dispatchedQty: targetJp.dispatchedQuantity,
            receivedQty: updatedReceived,
            returnedQty: targetJp.returnedToFactoryQuantity,
            transferredOutQty: targetJp.transferredOutQuantity,
            damagedQty: targetJp.damagedQuantity,
            isCancelled:
                JobProcessStatus.fromDbValue(targetJp.status) ==
                JobProcessStatus.cancelled,
          );
          await _db.jobProcessDao.updateJobProcess(
            targetJp.id,
            JobProcessesCompanion(
              receivedQuantity: Value(updatedReceived),
              status: Value(nextJpStatus.dbValue),
              updatedBy: Value(actor),
              updatedAt: Value(now),
            ),
          );
        }
      }

      await _support.writeAudit(
        entityType: 'PROCESS_HANDOVER',
        entityId: handoverId,
        actionType: 'UPDATE',
        actor: actor,
        payload: {
          'event': 'RECEIPT_CONFIRMED',
          'transferReference': row.transferReference,
          'receivedNow': receivedQuantity,
          'totalReceived': newReceived,
          'status': nextHandoverStatus.dbValue,
        },
        transactionAt: transactionAtUtcMillis,
        now: now,
      );
    });

    final updated = await _db.jobProcessDao.findHandoverById(handoverId);
    return _readDelegate.hydrateHandover(updated!);
  }

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
  }) async {
    final trimmedReqId = clientRequestId?.trim();
    if (trimmedReqId != null && trimmedReqId.isNotEmpty) {
      final existing = await _db.jobProcessDao.findHandoverByClientRequestId(
        trimmedReqId,
      );
      if (existing != null) return _readDelegate.hydrateHandover(existing);
    }

    final srcRow = await _db.jobProcessDao.findJobProcessById(
      sourceJobProcessId,
    );
    if (srcRow == null || srcRow.deletedAt != null) {
      _support.throwValidation('process_not_found');
    }
    final hydrated = await _readDelegate.hydrateWithProgress(srcRow);
    final srcEntity = hydrated.entity;

    final err = ProcessRoutingSupport.validator.validateDirectTransfer(
      sourceProcess: srcEntity,
      destinationWorkerId: destinationWorkerId,
      destinationProcessId: destinationProcessId,
      transferQuantity: quantity,
    );
    if (err != null) _support.throwValidation(err);

    final destPricing = await _support.resolveAssignmentPricing(
      processId: destinationProcessId,
      workerId: destinationWorkerId,
      quantity: quantity,
      transactionAtUtcMillis: transactionAtUtcMillis,
      requestedAgreedRatePaise: agreedRatePaise,
      requestedPricingUnit: pricingUnit,
      requestedOverrideReason: rateOverrideReason,
    );

    final actor = await ActorResolver.resolveRequired(_db);
    final now = IstDateTimeHelper.nowUtcMillis();
    final handoverId = _idGenerator.nextEntityId();
    final destJpId = _idGenerator.nextEntityId();
    final ref = ProcessRoutingSupport.validator.generateReference(
      type: ProcessHandoverType.directTransfer,
      transactionAtUtcMillis: transactionAtUtcMillis,
      uniqueId: handoverId,
    );

    await _txRunner.runInTransaction(() async {
      await _support.settleFifo(
        progress: hydrated.progress,
        goodQuantity: quantity,
        damagedQuantity: 0,
        transactionAtUtcMillis: transactionAtUtcMillis,
        reason: null,
        notes:
            'Direct transfer $ref${notes != null && notes.trim().isNotEmpty ? ' • ${notes.trim()}' : ''}',
        requestIdPrefix: trimmedReqId != null && trimmedReqId.isNotEmpty
            ? 'dt_ret_$trimmedReqId'
            : null,
      );

      final destIssue = await _support.issueStockWithResolvedRate(
        designColourId: srcRow.designColourId,
        processId: destinationProcessId,
        workerId: destinationWorkerId,
        quantity: quantity,
        transactionAtUtcMillis: transactionAtUtcMillis,
        effectivePerPieceRatePaise: destPricing.perPieceRatePaise,
        overrideReason: destPricing.overrideReason,
        notes:
            'Received via direct transfer $ref${notes != null && notes.trim().isNotEmpty ? ' • ${notes.trim()}' : ''}',
        jobProcessId: destJpId,
        clientRequestId: trimmedReqId != null && trimmedReqId.isNotEmpty
            ? 'dt_iss_$trimmedReqId'
            : null,
      );

      final newTransferredOut = srcRow.transferredOutQuantity + quantity;
      final srcNextStatus = ProcessRoutingSupport.validator.resolveStatus(
        dispatchedQty: srcRow.dispatchedQuantity,
        receivedQty: srcRow.receivedQuantity,
        returnedQty: srcRow.returnedToFactoryQuantity,
        transferredOutQty: newTransferredOut,
        damagedQty: srcRow.damagedQuantity,
        isCancelled: false,
      );
      await _db.jobProcessDao.updateJobProcess(
        srcRow.id,
        JobProcessesCompanion(
          transferredOutQuantity: Value(newTransferredOut),
          status: Value(srcNextStatus.dbValue),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );

      final nextSeq = await _db.jobProcessDao.getNextSequenceOrderForLot(
        srcRow.lotId,
      );
      final destStatus = autoConfirmReceipt
          ? JobProcessStatus.inProgress
          : JobProcessStatus.dispatched;

      await _db.jobProcessDao.insertJobProcess(
        JobProcessesCompanion.insert(
          id: destJpId,
          lotId: srcRow.lotId,
          lotDesignId: srcRow.lotDesignId,
          designColourId: srcRow.designColourId,
          processId: destinationProcessId,
          memberId: Value(destinationWorkerId),
          sequenceOrder: Value(nextSeq),
          plannedQuantity: quantity,
          dispatchedQuantity: Value(quantity),
          receivedQuantity: Value(autoConfirmReceipt ? quantity : 0),
          status: Value(destStatus.dbValue),
          sourceJobProcessId: Value(srcRow.id),
          linkedIssueMovementId: Value(destIssue.id),
          defaultRatePaise: Value(destPricing.defaultRatePaise),
          agreedRatePaise: Value(destPricing.agreedRatePaise),
          pricingUnit: Value(destPricing.pricingUnit),
          rateOverrideReason: Value(destPricing.overrideReason),
          payableAmountPaise: Value(destPricing.payableAmountPaise),
          paidAmountPaise: const Value(0),
          paymentStatus: Value(
            ProcessRoutingSupport.pricingCalc
                .resolvePaymentStatus(
                  netPayablePaise: destPricing.payableAmountPaise,
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

      if (destPricing.isOverridden) {
        await _db.jobProcessDao.insertRateHistory(
          ProcessRateHistoriesCompanion.insert(
            id: _idGenerator.nextEntityId(),
            scope: 'JOB_ASSIGNMENT',
            processId: destinationProcessId,
            jobProcessId: Value(destJpId),
            memberId: Value(destinationWorkerId),
            designColourId: Value(srcRow.designColourId),
            previousRatePaise: destPricing.defaultRatePaise,
            newRatePaise: destPricing.agreedRatePaise,
            pricingUnit: destPricing.pricingUnit,
            reason: destPricing.overrideReason!,
            changedBy: Value(actor),
            changedAt: now,
          ),
        );
      }

      await _db.jobProcessDao.insertHandover(
        ProcessHandoversCompanion.insert(
          id: handoverId,
          transferReference: ref,
          clientRequestId: Value(
            trimmedReqId != null && trimmedReqId.isNotEmpty
                ? trimmedReqId
                : null,
          ),
          lotId: srcRow.lotId,
          lotDesignId: srcRow.lotDesignId,
          designColourId: srcRow.designColourId,
          handoverType: ProcessHandoverType.directTransfer.dbValue,
          fromJobProcessId: Value(srcRow.id),
          toJobProcessId: Value(destJpId),
          fromMemberId: Value(srcRow.memberId),
          toMemberId: Value(destinationWorkerId),
          processId: destinationProcessId,
          quantityDispatched: quantity,
          quantityReceived: Value(autoConfirmReceipt ? quantity : 0),
          status: Value(
            autoConfirmReceipt
                ? ProcessHandoverStatus.received.dbValue
                : ProcessHandoverStatus.pendingReceipt.dbValue,
          ),
          linkedStockMovementId: Value(destIssue.id),
          notes: Value(notes?.trim()),
          transactionAt: transactionAtUtcMillis,
          recordedAt: now,
          createdBy: Value(actor),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await _support.writeAudit(
        entityType: 'PROCESS_HANDOVER',
        entityId: handoverId,
        actionType: 'CREATE',
        actor: actor,
        payload: {
          'event': 'DIRECT_TRANSFER',
          'transferReference': ref,
          'fromJobProcessId': srcRow.id,
          'toJobProcessId': destJpId,
          'fromMemberId': srcRow.memberId,
          'toMemberId': destinationWorkerId,
          'destinationProcessId': destinationProcessId,
          'designColourId': srcRow.designColourId,
          'quantity': quantity,
          'agreedRatePaise': destPricing.agreedRatePaise,
        },
        transactionAt: transactionAtUtcMillis,
        now: now,
        reason: destPricing.overrideReason,
      );
    });

    final created = await _db.jobProcessDao.findHandoverById(handoverId);
    return _readDelegate.hydrateHandover(created!);
  }

  Future<ProcessHandoverEntity> returnToFactory({
    required String sourceJobProcessId,
    required int goodQuantity,
    int damagedQuantity = 0,
    required int transactionAtUtcMillis,
    String? reason,
    String? notes,
    String? clientRequestId,
  }) async {
    final trimmedReqId = clientRequestId?.trim();
    if (trimmedReqId != null && trimmedReqId.isNotEmpty) {
      final existing = await _db.jobProcessDao.findHandoverByClientRequestId(
        trimmedReqId,
      );
      if (existing != null) return _readDelegate.hydrateHandover(existing);
    }

    final srcRow = await _db.jobProcessDao.findJobProcessById(
      sourceJobProcessId,
    );
    if (srcRow == null || srcRow.deletedAt != null) {
      _support.throwValidation('process_not_found');
    }
    final hydrated = await _readDelegate.hydrateWithProgress(srcRow);
    final srcEntity = hydrated.entity;

    final err = ProcessRoutingSupport.validator.validateFactoryReturn(
      sourceProcess: srcEntity,
      goodQuantity: goodQuantity,
      damagedQuantity: damagedQuantity,
      reason: reason,
    );
    if (err != null) _support.throwValidation(err);

    final totalReturned = goodQuantity + damagedQuantity;
    final actor = await ActorResolver.resolveRequired(_db);
    final now = IstDateTimeHelper.nowUtcMillis();
    final handoverId = _idGenerator.nextEntityId();
    final ref = ProcessRoutingSupport.validator.generateReference(
      type: ProcessHandoverType.factoryReturn,
      transactionAtUtcMillis: transactionAtUtcMillis,
      uniqueId: handoverId,
    );

    await _txRunner.runInTransaction(() async {
      String? linkedMovementId;
      final batches = await _support.settleFifo(
        progress: hydrated.progress,
        goodQuantity: goodQuantity,
        damagedQuantity: damagedQuantity,
        transactionAtUtcMillis: transactionAtUtcMillis,
        reason: reason,
        notes:
            'Factory return $ref${notes != null && notes.trim().isNotEmpty ? ' • ${notes.trim()}' : ''}',
        requestIdPrefix: trimmedReqId != null && trimmedReqId.isNotEmpty
            ? 'fr_ret_$trimmedReqId'
            : null,
      );
      for (final b in batches) {
        if (b.createdMovements.isNotEmpty) {
          linkedMovementId = b.createdMovements.first.id;
          break;
        }
      }

      final newReturned = srcRow.returnedToFactoryQuantity + goodQuantity;
      final newDamaged = srcRow.damagedQuantity + damagedQuantity;
      final nextStatus = ProcessRoutingSupport.validator.resolveStatus(
        dispatchedQty: srcRow.dispatchedQuantity,
        receivedQty: srcRow.receivedQuantity,
        returnedQty: newReturned,
        transferredOutQty: srcRow.transferredOutQuantity,
        damagedQty: newDamaged,
        isCancelled: false,
      );

      await _db.jobProcessDao.updateJobProcess(
        srcRow.id,
        JobProcessesCompanion(
          returnedToFactoryQuantity: Value(newReturned),
          damagedQuantity: Value(newDamaged),
          status: Value(nextStatus.dbValue),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
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
          lotId: srcRow.lotId,
          lotDesignId: srcRow.lotDesignId,
          designColourId: srcRow.designColourId,
          handoverType: ProcessHandoverType.factoryReturn.dbValue,
          fromJobProcessId: Value(srcRow.id),
          fromMemberId: Value(srcRow.memberId),
          processId: srcRow.processId,
          quantityDispatched: totalReturned,
          quantityReceived: Value(totalReturned),
          status: Value(ProcessHandoverStatus.received.dbValue),
          linkedStockMovementId: Value(linkedMovementId),
          notes: Value(notes?.trim()),
          transactionAt: transactionAtUtcMillis,
          recordedAt: now,
          createdBy: Value(actor),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await _support.writeAudit(
        entityType: 'PROCESS_HANDOVER',
        entityId: handoverId,
        actionType: 'CREATE',
        actor: actor,
        payload: {
          'event': 'FACTORY_RETURN',
          'transferReference': ref,
          'fromJobProcessId': srcRow.id,
          'designColourId': srcRow.designColourId,
          'goodQuantity': goodQuantity,
          'damagedQuantity': damagedQuantity,
        },
        transactionAt: transactionAtUtcMillis,
        now: now,
        reason: reason,
      );
    });

    final created = await _db.jobProcessDao.findHandoverById(handoverId);
    return _readDelegate.hydrateHandover(created!);
  }

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
  }) async {
    final trimmedReqId = clientRequestId?.trim();
    if (trimmedReqId != null && trimmedReqId.isNotEmpty) {
      final existing = await _db.jobProcessDao.findHandoverByClientRequestId(
        trimmedReqId,
      );
      if (existing != null) return _readDelegate.hydrateHandover(existing);
    }

    final balance = await _stockRepo.getDesignColourBalance(designColourId);
    if (balance == null || balance.lotId != lotId) {
      _support.throwValidation('sku_not_found');
    }

    final err = ProcessRoutingSupport.validator.validateReassignment(
      designColourId: designColourId,
      targetProcessId: targetProcessId,
      targetWorkerId: targetWorkerId,
      quantity: quantity,
      availableInHouse: balance.physicalAvailableInHouse,
    );
    if (err != null) _support.throwValidation(err);

    final pricing = await _support.resolveAssignmentPricing(
      processId: targetProcessId,
      workerId: targetWorkerId,
      quantity: quantity,
      transactionAtUtcMillis: transactionAtUtcMillis,
      requestedAgreedRatePaise: agreedRatePaise,
      requestedPricingUnit: pricingUnit,
      requestedOverrideReason: rateOverrideReason,
    );

    final actor = await ActorResolver.resolveRequired(_db);
    final now = IstDateTimeHelper.nowUtcMillis();
    final handoverId = _idGenerator.nextEntityId();
    final newJpId = _idGenerator.nextEntityId();
    final ref = ProcessRoutingSupport.validator.generateReference(
      type: ProcessHandoverType.reassignment,
      transactionAtUtcMillis: transactionAtUtcMillis,
      uniqueId: handoverId,
    );

    await _txRunner.runInTransaction(() async {
      final issue = await _support.issueStockWithResolvedRate(
        designColourId: designColourId,
        processId: targetProcessId,
        workerId: targetWorkerId,
        quantity: quantity,
        transactionAtUtcMillis: transactionAtUtcMillis,
        effectivePerPieceRatePaise: pricing.perPieceRatePaise,
        overrideReason: pricing.overrideReason,
        notes:
            'Factory reassignment $ref${notes != null && notes.trim().isNotEmpty ? ' • ${notes.trim()}' : ''}',
        jobProcessId: newJpId,
        clientRequestId: trimmedReqId != null && trimmedReqId.isNotEmpty
            ? 'ras_iss_$trimmedReqId'
            : null,
      );

      final nextSeq = await _db.jobProcessDao.getNextSequenceOrderForLot(lotId);
      await _db.jobProcessDao.insertJobProcess(
        JobProcessesCompanion.insert(
          id: newJpId,
          lotId: lotId,
          lotDesignId: balance.lotDesignId,
          designColourId: designColourId,
          processId: targetProcessId,
          memberId: Value(targetWorkerId),
          sequenceOrder: Value(nextSeq),
          plannedQuantity: quantity,
          dispatchedQuantity: Value(quantity),
          receivedQuantity: const Value(0),
          status: Value(JobProcessStatus.dispatched.dbValue),
          linkedIssueMovementId: Value(issue.id),
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
            processId: targetProcessId,
            jobProcessId: Value(newJpId),
            memberId: Value(targetWorkerId),
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
          handoverType: ProcessHandoverType.reassignment.dbValue,
          toJobProcessId: Value(newJpId),
          toMemberId: Value(targetWorkerId),
          processId: targetProcessId,
          quantityDispatched: quantity,
          quantityReceived: const Value(0),
          status: Value(ProcessHandoverStatus.pendingReceipt.dbValue),
          linkedStockMovementId: Value(issue.id),
          notes: Value(notes?.trim()),
          transactionAt: transactionAtUtcMillis,
          recordedAt: now,
          createdBy: Value(actor),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await _support.writeAudit(
        entityType: 'PROCESS_HANDOVER',
        entityId: handoverId,
        actionType: 'CREATE',
        actor: actor,
        payload: {
          'event': 'REASSIGNMENT',
          'transferReference': ref,
          'toJobProcessId': newJpId,
          'targetProcessId': targetProcessId,
          'targetWorkerId': targetWorkerId,
          'quantity': quantity,
          'agreedRatePaise': pricing.agreedRatePaise,
        },
        transactionAt: transactionAtUtcMillis,
        now: now,
        reason: pricing.overrideReason,
      );
    });

    final created = await _db.jobProcessDao.findHandoverById(handoverId);
    return _readDelegate.hydrateHandover(created!);
  }
}
