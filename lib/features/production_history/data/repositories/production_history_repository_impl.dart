import 'dart:convert';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/database/mappers/actor_resolver.dart';
import 'package:business_manager/core/database/mappers/ledger_row_mappers.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/features/accounting/domain/calculators/labour_calculator.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/notifications/data/services/notification_refresh_coordinator.dart';
import 'package:business_manager/features/production_history/data/repositories/production_history_dataset_loader.dart';
import 'package:business_manager/features/production_history/data/repositories/production_history_query_delegate.dart';
import 'package:business_manager/features/production_history/domain/calculators/production_history_calculator.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/production_history/domain/repositories/production_history_repository.dart';
import 'package:business_manager/features/stock_movements/domain/calculators/stock_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ProductionHistoryRepository)
final class ProductionHistoryRepositoryImpl
    implements ProductionHistoryRepository {
  ProductionHistoryRepositoryImpl(this._db, this._txRunner, this._idGenerator)
    : _queryDelegate = ProductionHistoryQueryDelegate(_db, _calc);

  final AppDatabase _db;
  final DatabaseTransactionRunner _txRunner;
  final IdGenerator _idGenerator;
  final ProductionHistoryQueryDelegate _queryDelegate;

  static const ProductionHistoryCalculator _calc =
      ProductionHistoryCalculator();
  static const StockCalculator _stockCalc = StockCalculator();
  static const LabourCalculator _labourCalc = LabourCalculator();

  Future<String?> _validateDamagedStockForRepair({
    required String designColourId,
    required int quantity,
    required bool reserveOpenRepairs,
  }) async {
    final colour = await _db.lotDao.findDesignColourById(designColourId);
    if (colour == null) return 'colour_not_found';
    final movs = (await _db.stockMovementDao.getMovementsForDesignColour(
      designColourId,
    )).map(LedgerRowMappers.stockMovement).toList();
    return _stockCalc.validateDamagedToGoodAdjustment(
      initialQuantity: colour.initialQuantity,
      existingMovementsForColour: movs,
      quantity: quantity,
      reason: 'repair',
      reservedForOpenRepairsQty: reserveOpenRepairs
          ? await _db.productionTrackingDao.pendingReinspectionQtyForColour(
              designColourId,
            )
          : 0,
    );
  }

  Future<int> _computeIssueOutstandingTx(
    StockMovementEntity parentIssue,
  ) async {
    final colourMovs = (await _db.stockMovementDao.getMovementsForDesignColour(
      parentIssue.designColourId,
    )).map(LedgerRowMappers.stockMovement).toList();
    final issueReturns = (await _db.productionTrackingDao.getReturnsForIssue(
      parentIssue.id,
    )).map(ProductionHistoryDatasetLoader.mapReturn).toList();
    final issueInspections =
        (await _db.productionTrackingDao.getInspectionsForIssue(parentIssue.id))
            .map(ProductionHistoryDatasetLoader.mapInspection)
            .toList();

    final reversedIds = _stockCalc.reversedMovementIds(colourMovs);
    final pendingByIssue = _calc.pendingInspectionByIssue(
      returns: issueReturns,
      inspections: issueInspections,
      reversedMovementIds: reversedIds,
    );
    final settledRemaining = _stockCalc.calculateIssueRemainingPending(
      issue: parentIssue,
      allMovementsForColour: colourMovs,
    );
    final pendingInsp = pendingByIssue[parentIssue.id] ?? 0;
    return (settledRemaining - pendingInsp).clamp(0, parentIssue.quantity);
  }

  Future<InspectionApprovalResult> _executeInitialInspectionTx({
    required ProductionReturnRow retRow,
    required StockMovementEntity parentIssue,
    required int acceptedQuantity,
    required int rejectedQuantity,
    required int transactionAtUtcMillis,
    required String? rejectionReason,
    required String? notes,
    required String inspectedBy,
    required String approvedBy,
    required bool authorizedViaPin,
    required String reqId,
  }) async {
    final existingInsp = await _db.productionTrackingDao
        .findInspectionByClientRequestId(reqId);
    if (existingInsp != null) {
      final mapped = ProductionHistoryDatasetLoader.mapInspection(existingInsp);
      return InspectionApprovalResult(
        inspection: mapped,
        earnedAmountPaise: mapped.earnedAmountPaise,
        wasIdempotentReplay: true,
      );
    }

    final colourMovs = (await _db.stockMovementDao.getMovementsForDesignColour(
      parentIssue.designColourId,
    )).map(LedgerRowMappers.stockMovement).toList();
    if (_stockCalc.reversedMovementIds(colourMovs).contains(parentIssue.id)) {
      throw const DomainValidationException(
        'parent_issue_inactive',
        'The original issue was reversed; this return can no longer be approved.',
      );
    }

    final existingInsps =
        (await _db.productionTrackingDao.getInspectionsForReturn(retRow.id))
            .map(ProductionHistoryDatasetLoader.mapInspection)
            .toList();
    final remainingPending = _calc.remainingPendingInspectionForReturn(
      productionReturn: ProductionHistoryDatasetLoader.mapReturn(retRow),
      inspections: existingInsps,
    );
    final err = _calc.validateInspectionApproval(
      remainingPendingInspectionQty: remainingPending,
      acceptedQuantity: acceptedQuantity,
      rejectedQuantity: rejectedQuantity,
      rejectionReason: rejectionReason,
    );
    if (err != null) {
      throw DomainValidationException(err, 'Invalid inspection ($err).');
    }

    final now = IstDateTimeHelper.nowUtcMillis();
    final cleanedReason = rejectionReason?.trim().isEmpty ?? true
        ? null
        : rejectionReason!.trim();
    final cleanedNotes = notes?.trim().isEmpty ?? true ? null : notes!.trim();
    final lockedRatePaise = parentIssue.appliedRatePaise;

    String? goodMovId;
    String? dmgMovId;
    String? labourId;
    var earnedPaise = 0;

    if (acceptedQuantity > 0) {
      goodMovId = _idGenerator.nextEntityId();
      await _db.stockMovementDao.insertMovement(
        StockMovementsCompanion(
          id: Value(goodMovId),
          lotId: Value(parentIssue.lotId),
          lotDesignId: Value(parentIssue.lotDesignId),
          designColourId: Value(parentIssue.designColourId),
          processId: Value(parentIssue.processId),
          memberId: Value(parentIssue.memberId),
          parentIssueId: Value(parentIssue.id),
          jobProcessId: Value(parentIssue.jobProcessId),
          clientRequestId: Value('$reqId:GOOD'),
          movementType: Value(StockMovementType.returnGood.dbValue),
          quantity: Value(acceptedQuantity),
          sourceRateId: Value(parentIssue.sourceRateId),
          appliedRatePaise: Value(lockedRatePaise),
          isRateOverridden: Value(parentIssue.isRateOverridden ? 1 : 0),
          overrideReason: Value(parentIssue.overrideReason),
          lockedBillingMode: Value(BillingMode.receivedQty.dbValue),
          lockedIncludeDamaged: const Value(0),
          notes: Value(cleanedNotes),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
          createdBy: Value(approvedBy),
          updatedBy: Value(approvedBy),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final planned = _labourCalc.planForSettlement(
        movementType: StockMovementType.returnGood,
        quantity: acceptedQuantity,
        lockedRatePaise: lockedRatePaise,
        lockedBillingMode: BillingMode.receivedQty,
        lockedIncludeDamaged: false,
        issueLabourAlreadyPaid: await _db.labourEntryDao.issueHasPayableLabour(
          parentIssue.id,
        ),
      );
      if (planned != null &&
          parentIssue.memberId != null &&
          parentIssue.processId != null) {
        labourId = _idGenerator.nextEntityId();
        earnedPaise = planned.amountPaise;
        await _db.labourEntryDao.insertEntry(
          LabourEntriesCompanion(
            id: Value(labourId),
            stockMovementId: Value(goodMovId),
            memberId: Value(parentIssue.memberId!),
            processId: Value(parentIssue.processId!),
            lotId: Value(parentIssue.lotId),
            basisType: Value(planned.basisType.dbValue),
            quantity: Value(planned.quantity),
            ratePaise: Value(planned.ratePaise),
            amountPaise: Value(planned.amountPaise),
            isPayable: const Value(1),
            transactionAt: Value(transactionAtUtcMillis),
            recordedAt: Value(now),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }
    }

    if (rejectedQuantity > 0) {
      dmgMovId = _idGenerator.nextEntityId();
      await _db.stockMovementDao.insertMovement(
        StockMovementsCompanion(
          id: Value(dmgMovId),
          lotId: Value(parentIssue.lotId),
          lotDesignId: Value(parentIssue.lotDesignId),
          designColourId: Value(parentIssue.designColourId),
          processId: Value(parentIssue.processId),
          memberId: Value(parentIssue.memberId),
          parentIssueId: Value(parentIssue.id),
          jobProcessId: Value(parentIssue.jobProcessId),
          clientRequestId: Value('$reqId:DAMAGED'),
          movementType: Value(StockMovementType.returnDamaged.dbValue),
          quantity: Value(rejectedQuantity),
          sourceRateId: Value(parentIssue.sourceRateId),
          appliedRatePaise: Value(lockedRatePaise),
          isRateOverridden: Value(parentIssue.isRateOverridden ? 1 : 0),
          overrideReason: Value(parentIssue.overrideReason),
          lockedBillingMode: Value(BillingMode.receivedQty.dbValue),
          lockedIncludeDamaged: const Value(0),
          reason: Value(cleanedReason),
          notes: Value(cleanedNotes),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
          createdBy: Value(inspectedBy),
          updatedBy: Value(inspectedBy),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
    }

    final inspId = _idGenerator.nextEntityId();
    await _db.productionTrackingDao.insertInspection(
      ProductionInspectionsCompanion(
        id: Value(inspId),
        clientRequestId: Value(reqId),
        inspectionType: Value(ProductionInspectionType.initial.dbValue),
        productionReturnId: Value(retRow.id),
        parentIssueId: Value(parentIssue.id),
        jobProcessId: Value(parentIssue.jobProcessId),
        lotId: Value(parentIssue.lotId),
        lotDesignId: Value(parentIssue.lotDesignId),
        designColourId: Value(parentIssue.designColourId),
        processId: Value(retRow.processId),
        memberId: Value(retRow.memberId),
        acceptedQuantity: Value(acceptedQuantity),
        rejectedQuantity: Value(rejectedQuantity),
        lockedRatePaise: Value(lockedRatePaise),
        earnedAmountPaise: Value(earnedPaise),
        creditWorkerEarnings: const Value(1),
        linkedGoodMovementId: Value(goodMovId),
        linkedDamagedMovementId: Value(dmgMovId),
        linkedLabourEntryId: Value(labourId),
        rejectionReason: Value(cleanedReason),
        notes: Value(cleanedNotes),
        inspectedBy: Value(inspectedBy),
        approvedBy: Value(approvedBy),
        authorizedViaPin: Value(authorizedViaPin ? 1 : 0),
        transactionAt: Value(transactionAtUtcMillis),
        recordedAt: Value(now),
        createdAt: Value(now),
      ),
    );

    RejectionRecordEntity? createdRejection;
    if (rejectedQuantity > 0 && dmgMovId != null) {
      final rejId = _idGenerator.nextEntityId();
      await _db.productionTrackingDao.insertRejectionRecord(
        RejectionRecordsCompanion(
          id: Value(rejId),
          lotId: Value(parentIssue.lotId),
          lotDesignId: Value(parentIssue.lotDesignId),
          designColourId: Value(parentIssue.designColourId),
          processId: Value(retRow.processId),
          memberId: Value(retRow.memberId),
          parentIssueId: Value(parentIssue.id),
          jobProcessId: Value(parentIssue.jobProcessId),
          productionReturnId: Value(retRow.id),
          inspectionId: Value(inspId),
          stockMovementId: Value(dmgMovId),
          rejectedQuantity: Value(rejectedQuantity),
          rejectionReason: Value(cleanedReason!),
          status: Value(RejectionStatus.open.dbValue),
          inspectedAt: Value(transactionAtUtcMillis),
          recordedBy: Value(inspectedBy),
          notes: Value(cleanedNotes),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      final rejRow = await _db.productionTrackingDao.findRejectionById(rejId);
      createdRejection = ProductionHistoryDatasetLoader.mapRejection(rejRow!);
    }

    await _db.attachmentAuditDao.insertAuditLog(
      AuditLogsCompanion(
        id: Value(_idGenerator.nextEntityId()),
        entityType: const Value('production_inspections'),
        entityId: Value(inspId),
        actionType: const Value('CREATE'),
        actor: Value(approvedBy),
        newValueJson: Value(
          jsonEncode({
            'event': 'QUANTITY_APPROVAL',
            'production_return_id': retRow.id,
            'parent_issue_id': parentIssue.id,
            'accepted_quantity': acceptedQuantity,
            'rejected_quantity': rejectedQuantity,
            'locked_rate_paise': lockedRatePaise,
            'earned_amount_paise': earnedPaise,
            'authorized_via_pin': authorizedViaPin,
            'rejection_record_id': createdRejection?.id,
          }),
        ),
        reason: Value(cleanedReason),
        transactionAt: Value(transactionAtUtcMillis),
        recordedAt: Value(now),
      ),
    );

    final inserted = await _db.productionTrackingDao.findInspectionById(inspId);
    return InspectionApprovalResult(
      inspection: ProductionHistoryDatasetLoader.mapInspection(inserted!),
      createdRejection: createdRejection,
      earnedAmountPaise: earnedPaise,
      wasIdempotentReplay: false,
    );
  }

  @override
  Future<ProductionReturnResult> recordProductionReturn({
    required String parentIssueId,
    required int returnedQuantity,
    required int transactionAtUtcMillis,
    bool inspectImmediately = false,
    int acceptedQuantity = 0,
    int rejectedQuantity = 0,
    String? rejectionReason,
    String? notes,
    String? inspectedBy,
    String? approvedBy,
    bool authorizedViaPin = false,
    String? clientRequestId,
  }) async {
    final reqId = clientRequestId?.trim().isEmpty ?? true
        ? _idGenerator.nextRequestId()
        : clientRequestId!.trim();

    if (!AppValidators.dateValidator(transactionAtUtcMillis).isValid) {
      throw const DomainValidationException(
        'invalid_date',
        'Transaction date is invalid.',
      );
    }

    return _txRunner
        .runInTransaction(() async {
          final existing = await _db.productionTrackingDao
              .findReturnByClientRequestId(reqId);
          final parentRow = await _db.stockMovementDao.findById(parentIssueId);
          if (parentRow == null) {
            throw const DomainValidationException(
              'parent_issue_inactive',
              'Original stock issue was not found.',
            );
          }
          final parentIssue = LedgerRowMappers.stockMovement(parentRow);

          if (existing != null) {
            final mappedRet = ProductionHistoryDatasetLoader.mapReturn(
              existing,
            );
            final insps =
                (await _db.productionTrackingDao.getInspectionsForReturn(
                  existing.id,
                )).map(ProductionHistoryDatasetLoader.mapInspection).toList();
            final remOut = await _computeIssueOutstandingTx(parentIssue);
            final remInsp = _calc.remainingPendingInspectionForReturn(
              productionReturn: mappedRet,
              inspections: insps,
            );
            return ProductionReturnResult(
              productionReturn: mappedRet,
              immediateInspection: insps.isNotEmpty ? insps.first : null,
              remainingOutstandingQty: remOut,
              remainingPendingInspectionQty: remInsp,
              wasIdempotentReplay: true,
            );
          }

          if (parentIssue.memberId == null || parentIssue.processId == null) {
            throw const DomainValidationException(
              'parent_issue_inactive',
              'Parent issue is missing worker or process reference.',
            );
          }

          final colourMovs =
              (await _db.stockMovementDao.getMovementsForDesignColour(
                parentIssue.designColourId,
              )).map(LedgerRowMappers.stockMovement).toList();
          final reversedIds = _stockCalc.reversedMovementIds(colourMovs);
          final outstanding = await _computeIssueOutstandingTx(parentIssue);

          final err = _calc.validateReturnSubmission(
            parentIssue: parentIssue,
            returnedQuantity: returnedQuantity,
            currentOutstandingQty: outstanding,
            isReversed: reversedIds.contains(parentIssue.id),
            inspectImmediately: inspectImmediately,
            acceptedQuantity: acceptedQuantity,
            rejectedQuantity: rejectedQuantity,
            rejectionReason: rejectionReason,
          );
          if (err != null) {
            throw DomainValidationException(err, 'Invalid return ($err).');
          }

          final now = IstDateTimeHelper.nowUtcMillis();
          final actor = await ActorResolver.resolveRequired(
            _db,
            explicit: approvedBy ?? inspectedBy,
          );
          final retId = _idGenerator.nextEntityId();
          final cleanedNotes = notes?.trim().isEmpty ?? true
              ? null
              : notes!.trim();

          await _db.productionTrackingDao.insertReturn(
            ProductionReturnsCompanion(
              id: Value(retId),
              clientRequestId: Value(reqId),
              parentIssueId: Value(parentIssue.id),
              jobProcessId: Value(parentIssue.jobProcessId),
              lotId: Value(parentIssue.lotId),
              lotDesignId: Value(parentIssue.lotDesignId),
              designColourId: Value(parentIssue.designColourId),
              processId: Value(parentIssue.processId!),
              memberId: Value(parentIssue.memberId!),
              returnedQuantity: Value(returnedQuantity),
              returnMode: Value(
                inspectImmediately
                    ? ProductionReturnMode.immediateInspection.dbValue
                    : ProductionReturnMode.pendingInspection.dbValue,
              ),
              notes: Value(cleanedNotes),
              transactionAt: Value(transactionAtUtcMillis),
              recordedAt: Value(now),
              createdBy: Value(actor),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

          await _db.attachmentAuditDao.insertAuditLog(
            AuditLogsCompanion(
              id: Value(_idGenerator.nextEntityId()),
              entityType: const Value('production_returns'),
              entityId: Value(retId),
              actionType: const Value('CREATE'),
              actor: Value(actor),
              newValueJson: Value(
                jsonEncode({
                  'event': 'RETURN_RECORDED',
                  'parent_issue_id': parentIssue.id,
                  'returned_quantity': returnedQuantity,
                  'inspect_immediately': inspectImmediately,
                }),
              ),
              transactionAt: Value(transactionAtUtcMillis),
              recordedAt: Value(now),
            ),
          );

          final retRow = (await _db.productionTrackingDao.findReturnById(
            retId,
          ))!;
          ProductionInspectionEntity? immediateInsp;

          if (inspectImmediately) {
            final res = await _executeInitialInspectionTx(
              retRow: retRow,
              parentIssue: parentIssue,
              acceptedQuantity: acceptedQuantity,
              rejectedQuantity: rejectedQuantity,
              transactionAtUtcMillis: transactionAtUtcMillis,
              rejectionReason: rejectionReason,
              notes: cleanedNotes,
              inspectedBy: await ActorResolver.resolveRequired(
                _db,
                explicit: inspectedBy,
              ),
              approvedBy: await ActorResolver.resolveRequired(
                _db,
                explicit: approvedBy,
              ),
              authorizedViaPin: authorizedViaPin,
              reqId: '$reqId:IMM_INSP',
            );
            immediateInsp = res.inspection;
          }

          final remOut = await _computeIssueOutstandingTx(parentIssue);
          final remInsp = inspectImmediately
              ? (returnedQuantity - acceptedQuantity - rejectedQuantity).clamp(
                  0,
                  returnedQuantity,
                )
              : returnedQuantity;

          return ProductionReturnResult(
            productionReturn: ProductionHistoryDatasetLoader.mapReturn(retRow),
            immediateInspection: immediateInsp,
            remainingOutstandingQty: remOut,
            remainingPendingInspectionQty: remInsp,
            wasIdempotentReplay: false,
          );
        })
        .then((result) {
          NotificationRefreshCoordinator.requestBackgroundRefreshIfRegistered();
          return result;
        });
  }

  @override
  Future<InspectionApprovalResult> approveReturnInspection({
    required String productionReturnId,
    required int acceptedQuantity,
    required int rejectedQuantity,
    required int transactionAtUtcMillis,
    String? rejectionReason,
    String? notes,
    String? inspectedBy,
    String? approvedBy,
    bool authorizedViaPin = false,
    String? clientRequestId,
  }) async {
    final reqId = clientRequestId?.trim().isEmpty ?? true
        ? _idGenerator.nextRequestId()
        : clientRequestId!.trim();

    if (!AppValidators.dateValidator(transactionAtUtcMillis).isValid) {
      throw const DomainValidationException(
        'invalid_date',
        'Transaction date is invalid.',
      );
    }

    return _txRunner
        .runInTransaction(() async {
          final retRow = await _db.productionTrackingDao.findReturnById(
            productionReturnId,
          );
          if (retRow == null || retRow.deletedAt != null) {
            throw const DomainValidationException(
              'return_not_found',
              'Production return record was not found.',
            );
          }
          final parentRow = await _db.stockMovementDao.findById(
            retRow.parentIssueId,
          );
          if (parentRow == null) {
            throw const DomainValidationException(
              'parent_issue_inactive',
              'Original stock issue was not found.',
            );
          }
          return _executeInitialInspectionTx(
            retRow: retRow,
            parentIssue: LedgerRowMappers.stockMovement(parentRow),
            acceptedQuantity: acceptedQuantity,
            rejectedQuantity: rejectedQuantity,
            transactionAtUtcMillis: transactionAtUtcMillis,
            rejectionReason: rejectionReason,
            notes: notes,
            inspectedBy: await ActorResolver.resolveRequired(
              _db,
              explicit: inspectedBy,
            ),
            approvedBy: await ActorResolver.resolveRequired(
              _db,
              explicit: approvedBy,
            ),
            authorizedViaPin: authorizedViaPin,
            reqId: reqId,
          );
        })
        .then((result) {
          NotificationRefreshCoordinator.requestBackgroundRefreshIfRegistered();
          return result;
        });
  }

  @override
  Future<RejectionRepairEntity> recordRejectionRepair({
    required String rejectionRecordId,
    required int repairedQuantity,
    required RepairSource repairSource,
    required int transactionAtUtcMillis,
    String? repairedBy,
    String? notes,
    String? clientRequestId,
  }) async {
    final reqId = clientRequestId?.trim().isEmpty ?? true
        ? _idGenerator.nextRequestId()
        : clientRequestId!.trim();

    if (!AppValidators.dateValidator(transactionAtUtcMillis).isValid) {
      throw const DomainValidationException(
        'invalid_date',
        'Transaction date is invalid.',
      );
    }

    return _txRunner.runInTransaction(() async {
      final existing = await _db.productionTrackingDao
          .findRepairByClientRequestId(reqId);
      if (existing != null) {
        return ProductionHistoryDatasetLoader.mapRepair(existing);
      }

      final rejRow = await _db.productionTrackingDao.findRejectionById(
        rejectionRecordId,
      );
      if (rejRow == null) {
        throw const DomainValidationException(
          'rejection_not_found',
          'Rejection record was not found.',
        );
      }

      final existingRepairs = await _db.productionTrackingDao
          .getRepairsForRejection(rejRow.id);
      var reapprovedTotal = 0;
      var pendingReinspTotal = 0;
      for (final rep in existingRepairs) {
        final insps = await _db.productionTrackingDao.getInspectionsForRepair(
          rep.id,
        );
        var acc = 0;
        var rejAgain = 0;
        for (final i in insps) {
          acc += i.acceptedQuantity;
          rejAgain += i.rejectedQuantity;
        }
        reapprovedTotal += acc;
        pendingReinspTotal += (rep.repairedQuantity - acc - rejAgain).clamp(
          0,
          rep.repairedQuantity,
        );
      }
      final openUnrepaired =
          (rejRow.rejectedQuantity - reapprovedTotal - pendingReinspTotal)
              .clamp(0, rejRow.rejectedQuantity);

      final err = _calc.validateRepairSubmission(
        openUnrepairedQty: openUnrepaired,
        repairedQuantity: repairedQuantity,
      );
      if (err != null) {
        throw DomainValidationException(err, 'Invalid repair ($err).');
      }

      final stockErr = await _validateDamagedStockForRepair(
        designColourId: rejRow.designColourId,
        quantity: repairedQuantity,
        reserveOpenRepairs: true,
      );
      if (stockErr != null) {
        throw DomainValidationException(
          stockErr,
          'Invalid repair ($stockErr).',
        );
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await ActorResolver.resolveRequired(
        _db,
        explicit: repairedBy,
      );
      final repairId = _idGenerator.nextEntityId();
      final cleanedNotes = notes?.trim().isEmpty ?? true ? null : notes!.trim();

      await _db.productionTrackingDao.insertRejectionRepair(
        RejectionRepairsCompanion(
          id: Value(repairId),
          clientRequestId: Value(reqId),
          rejectionRecordId: Value(rejRow.id),
          lotId: Value(rejRow.lotId),
          designColourId: Value(rejRow.designColourId),
          processId: Value(rejRow.processId),
          memberId: Value(rejRow.memberId),
          repairedQuantity: Value(repairedQuantity),
          repairSource: Value(repairSource.dbValue),
          status: Value(RepairStatus.pendingReinspection.dbValue),
          repairedBy: Value(actor),
          notes: Value(cleanedNotes),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final nextOpenAfter = openUnrepaired - repairedQuantity;
      final nextRejStatus = nextOpenAfter == 0
          ? RejectionStatus.repairedPendingInspection
          : RejectionStatus.partiallyRepaired;
      await _db.productionTrackingDao.updateRejectionStatus(
        rejRow.id,
        status: nextRejStatus.dbValue,
        updatedAt: now,
      );

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('rejection_repairs'),
          entityId: Value(repairId),
          actionType: const Value('CREATE'),
          actor: Value(actor),
          newValueJson: Value(
            jsonEncode({
              'event': 'REJECTION_REPAIRED',
              'rejection_record_id': rejRow.id,
              'repaired_quantity': repairedQuantity,
              'repair_source': repairSource.dbValue,
            }),
          ),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
        ),
      );

      final created = await _db.productionTrackingDao.findRepairById(repairId);
      return ProductionHistoryDatasetLoader.mapRepair(created!);
    });
  }

  @override
  Future<InspectionApprovalResult> approveRepairReinspection({
    required String rejectionRepairId,
    required int acceptedQuantity,
    required int rejectedAgainQuantity,
    required int transactionAtUtcMillis,
    String? rejectionReason,
    String? notes,
    String? inspectedBy,
    String? approvedBy,
    bool authorizedViaPin = false,
    String? clientRequestId,
  }) async {
    final reqId = clientRequestId?.trim().isEmpty ?? true
        ? _idGenerator.nextRequestId()
        : clientRequestId!.trim();

    if (!AppValidators.dateValidator(transactionAtUtcMillis).isValid) {
      throw const DomainValidationException(
        'invalid_date',
        'Transaction date is invalid.',
      );
    }

    return _txRunner
        .runInTransaction(() async {
          final existingInsp = await _db.productionTrackingDao
              .findInspectionByClientRequestId(reqId);
          if (existingInsp != null) {
            final mapped = ProductionHistoryDatasetLoader.mapInspection(
              existingInsp,
            );
            return InspectionApprovalResult(
              inspection: mapped,
              earnedAmountPaise: mapped.earnedAmountPaise,
              wasIdempotentReplay: true,
            );
          }

          final repRow = await _db.productionTrackingDao.findRepairById(
            rejectionRepairId,
          );
          if (repRow == null) {
            throw const DomainValidationException(
              'repair_not_found',
              'Repair record was not found.',
            );
          }
          final rejRow = await _db.productionTrackingDao.findRejectionById(
            repRow.rejectionRecordId,
          );
          if (rejRow == null) {
            throw const DomainValidationException(
              'rejection_not_found',
              'Rejection record was not found.',
            );
          }
          final parentRow = await _db.stockMovementDao.findById(
            rejRow.parentIssueId,
          );
          if (parentRow == null) {
            throw const DomainValidationException(
              'parent_issue_inactive',
              'Original assignment issue was not found.',
            );
          }
          final parentIssue = LedgerRowMappers.stockMovement(parentRow);

          final prevInspsForRepair = await _db.productionTrackingDao
              .getInspectionsForRepair(repRow.id);
          var prevProcessed = 0;
          for (final i in prevInspsForRepair) {
            prevProcessed += i.acceptedQuantity + i.rejectedQuantity;
          }
          final pendingReinsp = (repRow.repairedQuantity - prevProcessed).clamp(
            0,
            repRow.repairedQuantity,
          );

          final err = _calc.validateRepairReinspection(
            pendingReinspectionQty: pendingReinsp,
            acceptedQuantity: acceptedQuantity,
            rejectedAgainQuantity: rejectedAgainQuantity,
            rejectionReason: rejectionReason,
          );
          if (err != null) {
            throw DomainValidationException(
              err,
              'Invalid reinspection ($err).',
            );
          }

          final allRepairs = await _db.productionTrackingDao
              .getRepairsForRejection(rejRow.id);
          var totalReapprovedSoFar = 0;
          for (final r in allRepairs) {
            final insps = await _db.productionTrackingDao
                .getInspectionsForRepair(r.id);
            for (final i in insps) {
              totalReapprovedSoFar += i.acceptedQuantity;
            }
          }
          if (totalReapprovedSoFar + acceptedQuantity >
              rejRow.rejectedQuantity) {
            throw const DomainValidationException(
              'exceeds_rejected_quantity',
              'Approved repaired quantity cannot exceed original rejected quantity.',
            );
          }

          final now = IstDateTimeHelper.nowUtcMillis();
          final inspectorActor = await ActorResolver.resolveRequired(
            _db,
            explicit: inspectedBy,
          );
          final approverActor = await ActorResolver.resolveRequired(
            _db,
            explicit: approvedBy,
          );
          final cleanedReason = rejectionReason?.trim().isEmpty ?? true
              ? null
              : rejectionReason!.trim();
          final cleanedNotes = notes?.trim().isEmpty ?? true
              ? null
              : notes!.trim();
          final repairSource = RepairSource.fromDbValue(repRow.repairSource);
          final creditWorker = repairSource == RepairSource.originalWorker;
          final lockedRatePaise = parentIssue.appliedRatePaise;

          String? adjMovId;
          String? labourId;
          var earnedPaise = 0;

          if (acceptedQuantity > 0) {
            final stockErr = await _validateDamagedStockForRepair(
              designColourId: parentIssue.designColourId,
              quantity: acceptedQuantity,
              reserveOpenRepairs: false,
            );
            if (stockErr != null) {
              throw DomainValidationException(
                stockErr,
                'Invalid reinspection ($stockErr).',
              );
            }
            adjMovId = _idGenerator.nextEntityId();
            await _db.stockMovementDao.insertMovement(
              StockMovementsCompanion(
                id: Value(adjMovId),
                lotId: Value(parentIssue.lotId),
                lotDesignId: Value(parentIssue.lotDesignId),
                designColourId: Value(parentIssue.designColourId),
                processId: Value(parentIssue.processId),
                memberId: Value(parentIssue.memberId),
                parentIssueId: Value(parentIssue.id),
                jobProcessId: Value(parentIssue.jobProcessId),
                clientRequestId: Value('$reqId:REPAIR_GOOD'),
                movementType: Value(
                  StockMovementType.adjustmentDamagedToGood.dbValue,
                ),
                quantity: Value(acceptedQuantity),
                sourceRateId: Value(parentIssue.sourceRateId),
                appliedRatePaise: Value(lockedRatePaise),
                isRateOverridden: Value(parentIssue.isRateOverridden ? 1 : 0),
                overrideReason: Value(parentIssue.overrideReason),
                lockedBillingMode: Value(BillingMode.receivedQty.dbValue),
                lockedIncludeDamaged: const Value(0),
                reason: Value(
                  creditWorker
                      ? 'Repaired & Re-approved (Original Worker)'
                      : 'Repaired & Re-approved (In-House)',
                ),
                notes: Value(cleanedNotes),
                transactionAt: Value(transactionAtUtcMillis),
                recordedAt: Value(now),
                createdBy: Value(approverActor),
                updatedBy: Value(approverActor),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );

            final planned = _labourCalc.planForRepairReapproval(
              acceptedQuantity: acceptedQuantity,
              lockedRatePaise: lockedRatePaise,
              creditOriginalWorker: creditWorker,
              issueLabourAlreadyPaid: await _db.labourEntryDao
                  .issueHasPayableLabour(parentIssue.id),
            );
            if (planned != null) {
              labourId = _idGenerator.nextEntityId();
              earnedPaise = planned.amountPaise;
              await _db.labourEntryDao.insertEntry(
                LabourEntriesCompanion(
                  id: Value(labourId),
                  stockMovementId: Value(adjMovId),
                  memberId: Value(rejRow.memberId),
                  processId: Value(rejRow.processId),
                  lotId: Value(rejRow.lotId),
                  basisType: Value(planned.basisType.dbValue),
                  quantity: Value(planned.quantity),
                  ratePaise: Value(planned.ratePaise),
                  amountPaise: Value(planned.amountPaise),
                  isPayable: const Value(1),
                  transactionAt: Value(transactionAtUtcMillis),
                  recordedAt: Value(now),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
              );
            }
          }

          final inspId = _idGenerator.nextEntityId();
          await _db.productionTrackingDao.insertInspection(
            ProductionInspectionsCompanion(
              id: Value(inspId),
              clientRequestId: Value(reqId),
              inspectionType: Value(
                ProductionInspectionType.reinspection.dbValue,
              ),
              productionReturnId: Value(rejRow.productionReturnId),
              rejectionRecordId: Value(rejRow.id),
              rejectionRepairId: Value(repRow.id),
              parentIssueId: Value(parentIssue.id),
              jobProcessId: Value(parentIssue.jobProcessId),
              lotId: Value(parentIssue.lotId),
              lotDesignId: Value(parentIssue.lotDesignId),
              designColourId: Value(parentIssue.designColourId),
              processId: Value(rejRow.processId),
              memberId: Value(rejRow.memberId),
              acceptedQuantity: Value(acceptedQuantity),
              rejectedQuantity: Value(rejectedAgainQuantity),
              lockedRatePaise: Value(lockedRatePaise),
              earnedAmountPaise: Value(earnedPaise),
              creditWorkerEarnings: Value(creditWorker ? 1 : 0),
              linkedGoodMovementId: Value(adjMovId),
              linkedLabourEntryId: Value(labourId),
              rejectionReason: Value(cleanedReason),
              notes: Value(cleanedNotes),
              inspectedBy: Value(inspectorActor),
              approvedBy: Value(approverActor),
              authorizedViaPin: Value(authorizedViaPin ? 1 : 0),
              transactionAt: Value(transactionAtUtcMillis),
              recordedAt: Value(now),
              createdAt: Value(now),
            ),
          );

          final remainingOnRepair =
              pendingReinsp - (acceptedQuantity + rejectedAgainQuantity);
          await _db.productionTrackingDao.updateRepairStatus(
            repRow.id,
            status: remainingOnRepair == 0
                ? RepairStatus.completed.dbValue
                : RepairStatus.partiallyReinspected.dbValue,
            updatedAt: now,
          );

          final newTotalReapproved = totalReapprovedSoFar + acceptedQuantity;
          final RejectionStatus nextRejStatus;
          if (newTotalReapproved >= rejRow.rejectedQuantity) {
            nextRejStatus = RejectionStatus.reapproved;
          } else if (newTotalReapproved > 0) {
            nextRejStatus = RejectionStatus.partiallyReapproved;
          } else if (remainingOnRepair > 0) {
            nextRejStatus = RejectionStatus.repairedPendingInspection;
          } else {
            nextRejStatus = RejectionStatus.open;
          }
          await _db.productionTrackingDao.updateRejectionStatus(
            rejRow.id,
            status: nextRejStatus.dbValue,
            updatedAt: now,
          );

          await _db.attachmentAuditDao.insertAuditLog(
            AuditLogsCompanion(
              id: Value(_idGenerator.nextEntityId()),
              entityType: const Value('production_inspections'),
              entityId: Value(inspId),
              actionType: const Value('DAMAGED_TO_GOOD_ADJUSTMENT'),
              actor: Value(approverActor),
              newValueJson: Value(
                jsonEncode({
                  'event': 'REPAIR_REINSPECTION',
                  'rejection_record_id': rejRow.id,
                  'rejection_repair_id': repRow.id,
                  'accepted_quantity': acceptedQuantity,
                  'rejected_again_quantity': rejectedAgainQuantity,
                  'credit_worker_earnings': creditWorker,
                  'locked_rate_paise': lockedRatePaise,
                  'earned_amount_paise': earnedPaise,
                  'authorized_via_pin': authorizedViaPin,
                }),
              ),
              reason: Value(cleanedReason ?? 'Repaired pieces re-inspected'),
              transactionAt: Value(transactionAtUtcMillis),
              recordedAt: Value(now),
            ),
          );

          final inserted = await _db.productionTrackingDao.findInspectionById(
            inspId,
          );
          return InspectionApprovalResult(
            inspection: ProductionHistoryDatasetLoader.mapInspection(inserted!),
            earnedAmountPaise: earnedPaise,
            wasIdempotentReplay: false,
          );
        })
        .then((result) {
          NotificationRefreshCoordinator.requestBackgroundRefreshIfRegistered();
          return result;
        });
  }

  @override
  Future<ProductionHistoryDashboardData> getDashboard({
    ProductionHistoryFilter filter = const ProductionHistoryFilter(),
  }) => _queryDelegate.getDashboard(filter: filter);

  @override
  Future<LotCompleteHistory?> getLotCompleteHistory(String lotId) =>
      _queryDelegate.getLotCompleteHistory(lotId);

  @override
  Future<List<LotTimelineEvent>> getLotTimeline(String lotId) =>
      _queryDelegate.getLotTimeline(lotId);

  @override
  Future<WorkerCompleteProfile?> getWorkerCompleteProfile(
    String workerId, {
    ProductionHistoryFilter? filter,
  }) => _queryDelegate.getWorkerCompleteProfile(workerId, filter: filter);

  @override
  Future<List<WorkerCompleteProfile>> getAllWorkerProfiles({
    ProductionHistoryFilter? filter,
  }) => _queryDelegate.getAllWorkerProfiles(filter: filter);

  @override
  Future<List<ProcessCompleteHistory>> getAllProcessHistories({
    ProductionHistoryFilter? filter,
  }) => _queryDelegate.getAllProcessHistories(filter: filter);

  @override
  Future<ProcessCompleteHistory?> getProcessCompleteHistory(
    String processId, {
    ProductionHistoryFilter? filter,
  }) => _queryDelegate.getProcessCompleteHistory(processId, filter: filter);

  @override
  Future<List<PendingReturnView>> getPendingReturns({
    String? lotId,
    String? workerId,
    String? processId,
  }) => _queryDelegate.getPendingReturns(
    lotId: lotId,
    workerId: workerId,
    processId: processId,
  );

  @override
  Future<List<RejectionRecordView>> getRejectionRecords({
    String? lotId,
    String? workerId,
    String? processId,
    bool onlyOpen = false,
  }) => _queryDelegate.getRejectionRecords(
    lotId: lotId,
    workerId: workerId,
    processId: processId,
    onlyOpen: onlyOpen,
  );

  @override
  Future<ProductionTransactionDetail?> getTransactionDetail({
    required ProductionTransactionKind kind,
    required String id,
  }) => _queryDelegate.getTransactionDetail(kind: kind, id: id);

  @override
  Future<ProductionHistoryFilterOptions> getFilterOptions() =>
      _queryDelegate.getFilterOptions();
}
