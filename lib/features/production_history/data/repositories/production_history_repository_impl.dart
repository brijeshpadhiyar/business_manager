import 'dart:convert';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/features/accounting/domain/calculators/labour_calculator.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/notifications/data/services/notification_refresh_coordinator.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
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
  ProductionHistoryRepositoryImpl(this._db, this._txRunner, this._idGenerator);

  final AppDatabase _db;
  final DatabaseTransactionRunner _txRunner;
  final IdGenerator _idGenerator;

  static const ProductionHistoryCalculator _calc =
      ProductionHistoryCalculator();
  static const StockCalculator _stockCalc = StockCalculator();
  static const LabourCalculator _labourCalc = LabourCalculator();

  Future<String> _resolveActor([String? explicit]) async {
    final trimmed = explicit?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    final profile = await _db.businessProfileDao.getProfile();
    final owner = profile?.ownerName?.trim();
    return (owner != null && owner.isNotEmpty) ? owner : 'local_owner';
  }

  StockMovementEntity _mapMovement(StockMovementRow r) => StockMovementEntity(
    id: r.id,
    lotId: r.lotId,
    lotDesignId: r.lotDesignId,
    designColourId: r.designColourId,
    processId: r.processId,
    memberId: r.memberId,
    parentIssueId: r.parentIssueId,
    jobProcessId: r.jobProcessId,
    reversesMovementId: r.reversesMovementId,
    clientRequestId: r.clientRequestId,
    movementType: StockMovementType.fromDbValue(r.movementType),
    quantity: r.quantity,
    sourceRateId: r.sourceRateId,
    appliedRatePaise: r.appliedRatePaise,
    isRateOverridden: r.isRateOverridden == 1,
    overrideReason: r.overrideReason,
    lockedBillingMode: r.lockedBillingMode != null
        ? BillingMode.fromDbValue(r.lockedBillingMode!)
        : null,
    lockedIncludeDamaged: r.lockedIncludeDamaged == 1,
    reason: r.reason,
    notes: r.notes,
    transactionAt: r.transactionAt,
    recordedAt: r.recordedAt,
    createdBy: r.createdBy,
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  );

  ProductionReturnEntity _mapReturn(ProductionReturnRow r) =>
      ProductionReturnEntity(
        id: r.id,
        clientRequestId: r.clientRequestId,
        parentIssueId: r.parentIssueId,
        jobProcessId: r.jobProcessId,
        lotId: r.lotId,
        lotDesignId: r.lotDesignId,
        designColourId: r.designColourId,
        processId: r.processId,
        memberId: r.memberId,
        returnedQuantity: r.returnedQuantity,
        returnMode: ProductionReturnMode.fromDbValue(r.returnMode),
        notes: r.notes,
        transactionAt: r.transactionAt,
        recordedAt: r.recordedAt,
        createdBy: r.createdBy,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  ProductionInspectionEntity _mapInspection(ProductionInspectionRow r) =>
      ProductionInspectionEntity(
        id: r.id,
        clientRequestId: r.clientRequestId,
        inspectionType: ProductionInspectionType.fromDbValue(r.inspectionType),
        productionReturnId: r.productionReturnId,
        rejectionRecordId: r.rejectionRecordId,
        rejectionRepairId: r.rejectionRepairId,
        parentIssueId: r.parentIssueId,
        jobProcessId: r.jobProcessId,
        lotId: r.lotId,
        lotDesignId: r.lotDesignId,
        designColourId: r.designColourId,
        processId: r.processId,
        memberId: r.memberId,
        acceptedQuantity: r.acceptedQuantity,
        rejectedQuantity: r.rejectedQuantity,
        lockedRatePaise: r.lockedRatePaise,
        earnedAmountPaise: r.earnedAmountPaise,
        creditWorkerEarnings: r.creditWorkerEarnings == 1,
        linkedGoodMovementId: r.linkedGoodMovementId,
        linkedDamagedMovementId: r.linkedDamagedMovementId,
        linkedLabourEntryId: r.linkedLabourEntryId,
        rejectionReason: r.rejectionReason,
        notes: r.notes,
        inspectedBy: r.inspectedBy,
        approvedBy: r.approvedBy,
        authorizedViaPin: r.authorizedViaPin == 1,
        transactionAt: r.transactionAt,
        recordedAt: r.recordedAt,
        createdAt: r.createdAt,
      );

  RejectionRecordEntity _mapRejection(RejectionRecordRow r) =>
      RejectionRecordEntity(
        id: r.id,
        lotId: r.lotId,
        lotDesignId: r.lotDesignId,
        designColourId: r.designColourId,
        processId: r.processId,
        memberId: r.memberId,
        parentIssueId: r.parentIssueId,
        jobProcessId: r.jobProcessId,
        productionReturnId: r.productionReturnId,
        inspectionId: r.inspectionId,
        stockMovementId: r.stockMovementId,
        rejectedQuantity: r.rejectedQuantity,
        rejectionReason: r.rejectionReason,
        status: RejectionStatus.fromDbValue(r.status),
        inspectedAt: r.inspectedAt,
        recordedBy: r.recordedBy,
        notes: r.notes,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

  RejectionRepairEntity _mapRepair(RejectionRepairRow r) =>
      RejectionRepairEntity(
        id: r.id,
        clientRequestId: r.clientRequestId,
        rejectionRecordId: r.rejectionRecordId,
        lotId: r.lotId,
        designColourId: r.designColourId,
        processId: r.processId,
        memberId: r.memberId,
        repairedQuantity: r.repairedQuantity,
        repairSource: RepairSource.fromDbValue(r.repairSource),
        status: RepairStatus.fromDbValue(r.status),
        repairedBy: r.repairedBy,
        notes: r.notes,
        transactionAt: r.transactionAt,
        recordedAt: r.recordedAt,
        createdAt: r.createdAt,
        updatedAt: r.updatedAt,
      );

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

  Future<ProductionHistoryDataset> _loadDataset() async {
    final allLots = await _db.select(_db.lots).get();
    final allDesigns = await _db.select(_db.lotDesigns).get();
    final allColours = await _db.select(_db.designColours).get();
    final allProcs = await _db.select(_db.processes).get();
    final allWorkers = await _db.select(_db.members).get();
    final allMovements = (await _db.stockMovementDao.getAllMovements())
        .map(_mapMovement)
        .toList();
    final allReturns = (await _db.productionTrackingDao.getAllReturns())
        .map(_mapReturn)
        .toList();
    final allInspections = (await _db.productionTrackingDao.getAllInspections())
        .map(_mapInspection)
        .toList();
    final allRejections = (await _db.productionTrackingDao.getAllRejections())
        .map(_mapRejection)
        .toList();
    final allRepairs = (await _db.productionTrackingDao.getAllRepairs())
        .map(_mapRepair)
        .toList();
    final allLabour = (await _db.labourEntryDao.getAllEntries())
        .map(_mapLabour)
        .toList();
    final allPayments = (await _db.paymentDao.getAllPayments())
        .map(_mapPayment)
        .toList();
    final allAdjustments = (await _db.workerAdjustmentDao.getAllAdjustments())
        .map(_mapAdjustment)
        .toList();
    final handoverRows = await _db.jobProcessDao.getAllHandovers();

    final designMap = {
      for (final d in allDesigns)
        d.id: LotDesignEntity(
          id: d.id,
          lotId: d.lotId,
          designName: d.designName,
          notes: d.notes,
          createdAt: d.createdAt,
          updatedAt: d.updatedAt,
        ),
    };
    final colourMap = {
      for (final c in allColours)
        c.id: DesignColourEntity(
          id: c.id,
          lotDesignId: c.lotDesignId,
          colourName: c.colourName,
          colourHex: c.colourHex,
          initialQuantity: c.initialQuantity,
          unitPricePaise: c.unitPricePaise,
          notes: c.notes,
          createdAt: c.createdAt,
          updatedAt: c.updatedAt,
        ),
    };
    final procMap = {
      for (final p in allProcs)
        p.id: (name: p.name, isActive: p.isActive == 1 && p.deletedAt == null),
    };
    final workerMap = {
      for (final w in allWorkers)
        w.id: (
          name: w.name,
          phone: w.phone,
          address: w.address,
          notes: w.notes,
          isActive: w.isActive == 1 && w.deletedAt == null,
          createdAt: w.createdAt,
        ),
    };
    final handovers = handoverRows
        .map(
          (h) => ProcessHandoverEntity(
            id: h.id,
            transferReference: h.transferReference,
            clientRequestId: h.clientRequestId,
            lotId: h.lotId,
            lotDesignId: h.lotDesignId,
            designColourId: h.designColourId,
            designName: designMap[h.lotDesignId]?.designName ?? '-',
            colourName: colourMap[h.designColourId]?.colourName ?? '-',
            handoverType: ProcessHandoverType.fromDbValue(h.handoverType),
            fromJobProcessId: h.fromJobProcessId,
            toJobProcessId: h.toJobProcessId,
            fromMemberId: h.fromMemberId,
            fromMemberName: h.fromMemberId != null
                ? workerMap[h.fromMemberId!]?.name
                : null,
            toMemberId: h.toMemberId,
            toMemberName: h.toMemberId != null
                ? workerMap[h.toMemberId!]?.name
                : null,
            processId: h.processId,
            processName: procMap[h.processId]?.name ?? '-',
            quantityDispatched: h.quantityDispatched,
            quantityReceived: h.quantityReceived,
            status: ProcessHandoverStatus.fromDbValue(h.status),
            linkedStockMovementId: h.linkedStockMovementId,
            notes: h.notes,
            transactionAt: h.transactionAt,
            recordedAt: h.recordedAt,
          ),
        )
        .toList();

    return ProductionHistoryDataset(
      lots: {
        for (final l in allLots)
          l.id: (
            entity: LotEntity(
              id: l.id,
              lotNumber: l.lotNumber,
              title: l.title,
              notes: l.notes,
              status: LotStatus.fromDbValue(l.status),
              transactionAt: l.transactionAt,
              recordedAt: l.recordedAt,
              createdAt: l.createdAt,
              updatedAt: l.updatedAt,
            ),
            createdBy: l.createdBy,
            updatedBy: l.updatedBy,
          ),
      },
      designs: designMap,
      colours: colourMap,
      processes: procMap,
      workers: workerMap,
      movements: allMovements,
      returns: allReturns,
      inspections: allInspections,
      rejections: allRejections,
      repairs: allRepairs,
      labourEntries: allLabour,
      payments: allPayments,
      adjustments: allAdjustments,
      handovers: handovers,
    );
  }

  Future<String?> _validateDamagedStockForRepair({
    required String designColourId,
    required int quantity,
    required bool reserveOpenRepairs,
  }) async {
    final colour = await _db.lotDao.findDesignColourById(designColourId);
    if (colour == null) return 'colour_not_found';
    final movs = (await _db.stockMovementDao.getMovementsForDesignColour(
      designColourId,
    )).map(_mapMovement).toList();
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
    )).map(_mapMovement).toList();
    final issueReturns = (await _db.productionTrackingDao.getReturnsForIssue(
      parentIssue.id,
    )).map(_mapReturn).toList();
    final issueInspections =
        (await _db.productionTrackingDao.getInspectionsForIssue(parentIssue.id))
            .map(_mapInspection)
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

  /// Internal atomic helper executed inside an active DB transaction to record
  /// an initial QC inspection, stock movements, payable labour (strictly for
  /// accepted qty), rejection record, and audit trail.
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
      final mapped = _mapInspection(existingInsp);
      return InspectionApprovalResult(
        inspection: mapped,
        earnedAmountPaise: mapped.earnedAmountPaise,
        wasIdempotentReplay: true,
      );
    }

    final colourMovs = (await _db.stockMovementDao.getMovementsForDesignColour(
      parentIssue.designColourId,
    )).map(_mapMovement).toList();
    if (_stockCalc.reversedMovementIds(colourMovs).contains(parentIssue.id)) {
      throw const DomainValidationException(
        'parent_issue_inactive',
        'The original issue was reversed; this return can no longer be approved.',
      );
    }

    final existingInsps =
        (await _db.productionTrackingDao.getInspectionsForReturn(retRow.id))
            .map(_mapInspection)
            .toList();
    final remainingPending = _calc.remainingPendingInspectionForReturn(
      productionReturn: _mapReturn(retRow),
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
      // Rule 3: Rejected pieces NEVER generate labour_entries.
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
      createdRejection = _mapRejection(rejRow!);
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
      inspection: _mapInspection(inserted!),
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
          final parentIssue = _mapMovement(parentRow);

          if (existing != null) {
            final mappedRet = _mapReturn(existing);
            final insps =
                (await _db.productionTrackingDao.getInspectionsForReturn(
                  existing.id,
                )).map(_mapInspection).toList();
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
              )).map(_mapMovement).toList();
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
          final actor = await _resolveActor(approvedBy ?? inspectedBy);
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
              inspectedBy: await _resolveActor(inspectedBy),
              approvedBy: await _resolveActor(approvedBy),
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
            productionReturn: _mapReturn(retRow),
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
            parentIssue: _mapMovement(parentRow),
            acceptedQuantity: acceptedQuantity,
            rejectedQuantity: rejectedQuantity,
            transactionAtUtcMillis: transactionAtUtcMillis,
            rejectionReason: rejectionReason,
            notes: notes,
            inspectedBy: await _resolveActor(inspectedBy),
            approvedBy: await _resolveActor(approvedBy),
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
      if (existing != null) return _mapRepair(existing);

      final rejRow = await _db.productionTrackingDao.findRejectionById(
        rejectionRecordId,
      );
      if (rejRow == null) {
        throw const DomainValidationException(
          'rejection_not_found',
          'Rejection record was not found.',
        );
      }

      // Compute exact remaining open unrepaired quantity for this rejection
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

      // One damaged bucket, two repair flows: the pieces must still be in the
      // Damaged bucket and not already reserved by another open repair.
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
      final actor = await _resolveActor(repairedBy);
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
      return _mapRepair(created!);
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
            final mapped = _mapInspection(existingInsp);
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
          final parentIssue = _mapMovement(parentRow);

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

          // Strict anti-duplicate guard: total reapproved across ALL repairs
          // for this rejection record can NEVER exceed rejected_quantity.
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
          final inspectorActor = await _resolveActor(inspectedBy);
          final approverActor = await _resolveActor(approvedBy);
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

          // Update repair & rejection statuses cleanly
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
            inspection: _mapInspection(inserted!),
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
  }) async {
    final data = await _loadDataset();
    return _calc.buildDashboard(data, filter: filter);
  }

  @override
  Future<LotCompleteHistory?> getLotCompleteHistory(String lotId) async {
    final data = await _loadDataset();
    return _calc.buildLotCompleteHistory(lotId, data);
  }

  @override
  Future<List<LotTimelineEvent>> getLotTimeline(String lotId) async {
    final data = await _loadDataset();
    return _calc.buildLotTimeline(lotId, data);
  }

  @override
  Future<WorkerCompleteProfile?> getWorkerCompleteProfile(
    String workerId, {
    ProductionHistoryFilter? filter,
  }) async {
    final data = await _loadDataset();
    return _calc.buildWorkerCompleteProfile(workerId, data, filter: filter);
  }

  @override
  Future<List<WorkerCompleteProfile>> getAllWorkerProfiles({
    ProductionHistoryFilter? filter,
  }) async {
    final data = await _loadDataset();
    final profiles = <WorkerCompleteProfile>[];
    for (final wId in data.workers.keys) {
      if (filter?.workerId != null && wId != filter!.workerId) continue;
      final profile = _calc.buildWorkerCompleteProfile(
        wId,
        data,
        filter: filter,
      );
      if (profile != null) {
        if (filter?.searchQuery != null &&
            filter!.searchQuery!.trim().isNotEmpty) {
          final q = filter.searchQuery!.trim().toLowerCase();
          final hay = '${profile.workerName} ${profile.phone ?? ''}'
              .toLowerCase();
          if (!hay.contains(q) && profile.lotHistory.isEmpty) continue;
        }
        profiles.add(profile);
      }
    }
    profiles.sort(
      (a, b) => b.financialSummary.outstandingPayablePaise.compareTo(
        a.financialSummary.outstandingPayablePaise,
      ),
    );
    return profiles;
  }

  @override
  Future<List<ProcessCompleteHistory>> getAllProcessHistories({
    ProductionHistoryFilter? filter,
  }) async {
    final data = await _loadDataset();
    return _calc.buildAllProcessHistories(data, filter: filter);
  }

  @override
  Future<ProcessCompleteHistory?> getProcessCompleteHistory(
    String processId, {
    ProductionHistoryFilter? filter,
  }) async {
    final data = await _loadDataset();
    final list = _calc.buildAllProcessHistories(
      data,
      filter: (filter ?? const ProductionHistoryFilter()).copyWith(
        processId: processId,
      ),
    );
    return list.isNotEmpty ? list.first : null;
  }

  @override
  Future<List<PendingReturnView>> getPendingReturns({
    String? lotId,
    String? workerId,
    String? processId,
  }) async {
    final data = await _loadDataset();
    return _calc.buildPendingReturns(
      data,
      lotId: lotId,
      workerId: workerId,
      processId: processId,
    );
  }

  @override
  Future<List<RejectionRecordView>> getRejectionRecords({
    String? lotId,
    String? workerId,
    String? processId,
    bool onlyOpen = false,
  }) async {
    final data = await _loadDataset();
    return _calc.buildRejectionViews(
      data,
      lotId: lotId,
      workerId: workerId,
      processId: processId,
      onlyOpen: onlyOpen,
    );
  }

  @override
  Future<ProductionTransactionDetail?> getTransactionDetail({
    required ProductionTransactionKind kind,
    required String id,
  }) async {
    final data = await _loadDataset();

    Future<List<ProductionAuditEntryView>> loadAudits(
      String entityType,
      String entityId,
    ) async {
      final rows = await _db.attachmentAuditDao.getAuditLogsForEntity(
        entityType,
        entityId,
      );
      return rows
          .map(
            (a) => ProductionAuditEntryView(
              id: a.id,
              actionType: a.actionType,
              actor: a.actor,
              reason: a.reason,
              recordedAt: a.recordedAt,
              newValueJson: a.newValueJson,
            ),
          )
          .toList();
    }

    switch (kind) {
      case ProductionTransactionKind.stockMovement:
        final movRow = await _db.stockMovementDao.findById(id);
        if (movRow == null) return null;
        final m = _mapMovement(movRow);
        final links =
            <({String label, ProductionTransactionKind kind, String id})>[];
        if (m.parentIssueId != null) {
          links.add((
            label: 'Parent Issue Assignment',
            kind: ProductionTransactionKind.stockMovement,
            id: m.parentIssueId!,
          ));
        }
        final labRows = await _db.labourEntryDao.getEntriesForMovement(m.id);
        for (final l in labRows) {
          links.add((
            label: 'Labour Entry (${l.basisType})',
            kind: ProductionTransactionKind.labourEntry,
            id: l.id,
          ));
        }
        return ProductionTransactionDetail(
          kind: kind,
          id: m.id,
          title: 'Stock Movement — ${m.movementType.dbValue}',
          statusLabel: m.movementType.dbValue,
          transactionAt: m.transactionAt,
          recordedAt: m.recordedAt,
          actor: m.createdBy,
          lotId: m.lotId,
          lotNumber: data.lots[m.lotId]?.entity.lotNumber ?? m.lotId,
          designName: data.designs[m.lotDesignId]?.designName,
          colourName: data.colours[m.designColourId]?.colourName,
          processId: m.processId,
          processName: m.processId != null
              ? data.processes[m.processId!]?.name
              : null,
          workerId: m.memberId,
          workerName: m.memberId != null
              ? data.workers[m.memberId!]?.name
              : null,
          quantity: m.quantity,
          lockedRatePaise: m.appliedRatePaise,
          amountPaise: m.quantity * m.appliedRatePaise,
          reason: m.reason ?? m.overrideReason,
          notes: m.notes,
          parentIssueId: m.parentIssueId,
          relatedLinks: links,
          auditTrail: await loadAudits('stock_movements', m.id),
        );

      case ProductionTransactionKind.productionReturn:
        final retRow = await _db.productionTrackingDao.findReturnById(id);
        if (retRow == null) return null;
        final r = _mapReturn(retRow);
        final insps = await _db.productionTrackingDao.getInspectionsForReturn(
          r.id,
        );
        final links = <({String label, ProductionTransactionKind kind, String id})>[
          (
            label: 'Parent Assignment Issue',
            kind: ProductionTransactionKind.stockMovement,
            id: r.parentIssueId,
          ),
          for (final i in insps)
            (
              label:
                  'Inspection (Acc ${i.acceptedQuantity}, Rej ${i.rejectedQuantity})',
              kind: ProductionTransactionKind.inspection,
              id: i.id,
            ),
        ];
        return ProductionTransactionDetail(
          kind: kind,
          id: r.id,
          title: 'Production Return Receipt',
          statusLabel: r.returnMode.dbValue,
          transactionAt: r.transactionAt,
          recordedAt: r.recordedAt,
          actor: r.createdBy,
          lotId: r.lotId,
          lotNumber: data.lots[r.lotId]?.entity.lotNumber ?? r.lotId,
          designName: data.designs[r.lotDesignId]?.designName,
          colourName: data.colours[r.designColourId]?.colourName,
          processId: r.processId,
          processName: data.processes[r.processId]?.name,
          workerId: r.memberId,
          workerName: data.workers[r.memberId]?.name,
          quantity: r.returnedQuantity,
          notes: r.notes,
          parentIssueId: r.parentIssueId,
          relatedLinks: links,
          auditTrail: await loadAudits('production_returns', r.id),
        );

      case ProductionTransactionKind.inspection:
        final inspRow = await _db.productionTrackingDao.findInspectionById(id);
        if (inspRow == null) return null;
        final i = _mapInspection(inspRow);
        final links =
            <({String label, ProductionTransactionKind kind, String id})>[
              (
                label: 'Parent Assignment Issue',
                kind: ProductionTransactionKind.stockMovement,
                id: i.parentIssueId,
              ),
              if (i.productionReturnId != null)
                (
                  label: 'Production Return Receipt',
                  kind: ProductionTransactionKind.productionReturn,
                  id: i.productionReturnId!,
                ),
              if (i.linkedLabourEntryId != null)
                (
                  label: 'Generated Worker Earning',
                  kind: ProductionTransactionKind.labourEntry,
                  id: i.linkedLabourEntryId!,
                ),
              if (i.rejectionRecordId != null)
                (
                  label: 'Original Rejection Record',
                  kind: ProductionTransactionKind.rejection,
                  id: i.rejectionRecordId!,
                ),
            ];
        return ProductionTransactionDetail(
          kind: kind,
          id: i.id,
          title: i.inspectionType == ProductionInspectionType.reinspection
              ? 'Repair Re-Inspection & Approval'
              : 'Quality Inspection & Approval',
          statusLabel: i.inspectionType.dbValue,
          transactionAt: i.transactionAt,
          recordedAt: i.recordedAt,
          actor: i.inspectedBy,
          approvedBy: i.approvedBy,
          authorizedViaPin: i.authorizedViaPin,
          lotId: i.lotId,
          lotNumber: data.lots[i.lotId]?.entity.lotNumber ?? i.lotId,
          designName: data.designs[i.lotDesignId]?.designName,
          colourName: data.colours[i.designColourId]?.colourName,
          processId: i.processId,
          processName: data.processes[i.processId]?.name,
          workerId: i.memberId,
          workerName: data.workers[i.memberId]?.name,
          quantity: i.totalInspectedQuantity,
          acceptedQuantity: i.acceptedQuantity,
          rejectedQuantity: i.rejectedQuantity,
          lockedRatePaise: i.lockedRatePaise,
          amountPaise: i.earnedAmountPaise,
          reason: i.rejectionReason,
          notes: i.notes,
          parentIssueId: i.parentIssueId,
          relatedLinks: links,
          auditTrail: await loadAudits('production_inspections', i.id),
        );

      case ProductionTransactionKind.rejection:
        final rejRow = await _db.productionTrackingDao.findRejectionById(id);
        if (rejRow == null) return null;
        final r = _mapRejection(rejRow);
        final repairs = await _db.productionTrackingDao.getRepairsForRejection(
          r.id,
        );
        return ProductionTransactionDetail(
          kind: kind,
          id: r.id,
          title: 'Rejection / Defect Record',
          statusLabel: r.status.dbValue,
          transactionAt: r.inspectedAt,
          recordedAt: r.createdAt,
          actor: r.recordedBy,
          lotId: r.lotId,
          lotNumber: data.lots[r.lotId]?.entity.lotNumber ?? r.lotId,
          designName: data.designs[r.lotDesignId]?.designName,
          colourName: data.colours[r.designColourId]?.colourName,
          processId: r.processId,
          processName: data.processes[r.processId]?.name,
          workerId: r.memberId,
          workerName: data.workers[r.memberId]?.name,
          rejectedQuantity: r.rejectedQuantity,
          quantity: r.rejectedQuantity,
          amountPaise: 0,
          reason: r.rejectionReason,
          notes: r.notes,
          parentIssueId: r.parentIssueId,
          relatedLinks: [
            (
              label: 'Inspection Event',
              kind: ProductionTransactionKind.inspection,
              id: r.inspectionId,
            ),
            for (final rep in repairs)
              (
                label: 'Repair (${rep.repairedQuantity} pcs)',
                kind: ProductionTransactionKind.repair,
                id: rep.id,
              ),
          ],
          auditTrail: await loadAudits(
            'production_inspections',
            r.inspectionId,
          ),
        );

      case ProductionTransactionKind.repair:
        final repRow = await _db.productionTrackingDao.findRepairById(id);
        if (repRow == null) return null;
        final rep = _mapRepair(repRow);
        final insps = await _db.productionTrackingDao.getInspectionsForRepair(
          rep.id,
        );
        return ProductionTransactionDetail(
          kind: kind,
          id: rep.id,
          title: 'Rejection Repair Operation',
          statusLabel: '${rep.repairSource.dbValue} • ${rep.status.dbValue}',
          transactionAt: rep.transactionAt,
          recordedAt: rep.recordedAt,
          actor: rep.repairedBy,
          lotId: rep.lotId,
          lotNumber: data.lots[rep.lotId]?.entity.lotNumber ?? rep.lotId,
          colourName: data.colours[rep.designColourId]?.colourName,
          processId: rep.processId,
          processName: data.processes[rep.processId]?.name,
          workerId: rep.memberId,
          workerName: data.workers[rep.memberId]?.name,
          quantity: rep.repairedQuantity,
          notes: rep.notes,
          relatedLinks: [
            (
              label: 'Original Rejection Record',
              kind: ProductionTransactionKind.rejection,
              id: rep.rejectionRecordId,
            ),
            for (final ins in insps)
              (
                label: 'Re-Inspection (Acc ${ins.acceptedQuantity})',
                kind: ProductionTransactionKind.inspection,
                id: ins.id,
              ),
          ],
          auditTrail: await loadAudits('rejection_repairs', rep.id),
        );

      case ProductionTransactionKind.handover:
        final hoRow = await _db.jobProcessDao.findHandoverById(id);
        if (hoRow == null) return null;
        return ProductionTransactionDetail(
          kind: kind,
          id: hoRow.id,
          title: 'Process Handover — ${hoRow.handoverType}',
          statusLabel: hoRow.status,
          transactionAt: hoRow.transactionAt,
          recordedAt: hoRow.recordedAt,
          actor: hoRow.createdBy,
          lotId: hoRow.lotId,
          lotNumber: data.lots[hoRow.lotId]?.entity.lotNumber ?? hoRow.lotId,
          designName: data.designs[hoRow.lotDesignId]?.designName,
          colourName: data.colours[hoRow.designColourId]?.colourName,
          processId: hoRow.processId,
          processName: data.processes[hoRow.processId]?.name,
          workerId: hoRow.toMemberId ?? hoRow.fromMemberId,
          workerName: (hoRow.toMemberId ?? hoRow.fromMemberId) != null
              ? data.workers[(hoRow.toMemberId ?? hoRow.fromMemberId)!]?.name
              : null,
          quantity: hoRow.quantityDispatched,
          referenceNo: hoRow.transferReference,
          notes: hoRow.notes,
          auditTrail: await loadAudits('PROCESS_HANDOVER', hoRow.id),
        );

      case ProductionTransactionKind.labourEntry:
        final labRow = await _db.labourEntryDao.findById(id);
        if (labRow == null) return null;
        return ProductionTransactionDetail(
          kind: kind,
          id: labRow.id,
          title: 'Worker Labour Earning (${labRow.basisType})',
          statusLabel: labRow.isPayable == 1 ? 'PAYABLE' : 'INFORMATIONAL',
          transactionAt: labRow.transactionAt,
          recordedAt: labRow.recordedAt,
          lotId: labRow.lotId,
          lotNumber: data.lots[labRow.lotId]?.entity.lotNumber ?? labRow.lotId,
          processId: labRow.processId,
          processName: data.processes[labRow.processId]?.name,
          workerId: labRow.memberId,
          workerName: data.workers[labRow.memberId]?.name,
          quantity: labRow.quantity,
          lockedRatePaise: labRow.ratePaise,
          amountPaise: labRow.amountPaise,
          relatedLinks: [
            (
              label: 'Linked Stock Movement',
              kind: ProductionTransactionKind.stockMovement,
              id: labRow.stockMovementId,
            ),
          ],
          auditTrail: await loadAudits(
            'stock_movements',
            labRow.stockMovementId,
          ),
        );

      case ProductionTransactionKind.payment:
        final payRow = await _db.paymentDao.findById(id);
        if (payRow == null) return null;
        return ProductionTransactionDetail(
          kind: kind,
          id: payRow.id,
          title: 'Worker Payment — ${payRow.paymentType}',
          statusLabel: payRow.paymentMode,
          transactionAt: payRow.transactionAt,
          recordedAt: payRow.recordedAt,
          actor: payRow.createdBy,
          workerId: payRow.memberId,
          workerName: data.workers[payRow.memberId]?.name,
          amountPaise: payRow.amountPaise,
          referenceNo: payRow.referenceNo,
          reason: payRow.reason,
          notes: payRow.notes,
          auditTrail: await loadAudits('payments', payRow.id),
        );

      case ProductionTransactionKind.adjustment:
        final adjRow = await _db.workerAdjustmentDao.findById(id);
        if (adjRow == null) return null;
        return ProductionTransactionDetail(
          kind: kind,
          id: adjRow.id,
          title: 'Worker Ledger Adjustment — ${adjRow.adjustmentType}',
          statusLabel: adjRow.adjustmentType,
          transactionAt: adjRow.transactionAt,
          recordedAt: adjRow.recordedAt,
          actor: adjRow.createdBy,
          workerId: adjRow.memberId,
          workerName: data.workers[adjRow.memberId]?.name,
          amountPaise: adjRow.amountPaise,
          reason: adjRow.reason,
          notes: adjRow.notes,
          auditTrail: await loadAudits('worker_ledger_adjustments', adjRow.id),
        );
    }
  }

  @override
  Future<ProductionHistoryFilterOptions> getFilterOptions() async {
    final allLots = await _db.select(_db.lots).get();
    final allWorkers = await _db.select(_db.members).get();
    final allProcs = await _db.select(_db.processes).get();
    final allDesigns = await _db.select(_db.lotDesigns).get();
    final allColours = await _db.select(_db.designColours).get();

    final designNames = <String>{};
    for (final d in allDesigns) {
      if (d.designName.trim().isNotEmpty &&
          d.designName != kColourOnlyDesignSentinel) {
        designNames.add(d.designName.trim());
      }
    }
    final colourNames = <String>{};
    for (final c in allColours) {
      if (c.colourName.trim().isNotEmpty) {
        colourNames.add(c.colourName.trim());
      }
    }

    return ProductionHistoryFilterOptions(
      lots:
          allLots
              .map(
                (l) => HistoryFilterOption(
                  id: l.id,
                  label: l.lotNumber,
                  isActive: l.deletedAt == null && l.status != 'ARCHIVED',
                ),
              )
              .toList()
            ..sort((a, b) => a.label.compareTo(b.label)),
      workers:
          allWorkers
              .map(
                (w) => HistoryFilterOption(
                  id: w.id,
                  label: w.name,
                  isActive: w.isActive == 1 && w.deletedAt == null,
                ),
              )
              .toList()
            ..sort((a, b) => a.label.compareTo(b.label)),
      processes:
          allProcs
              .map(
                (p) => HistoryFilterOption(
                  id: p.id,
                  label: p.name,
                  isActive: p.isActive == 1 && p.deletedAt == null,
                ),
              )
              .toList()
            ..sort((a, b) => a.label.compareTo(b.label)),
      designNames: designNames.toList()..sort(),
      colourNames: colourNames.toList()..sort(),
    );
  }
}
