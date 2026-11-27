import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/mappers/ledger_row_mappers.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';

/// Shared row mappers and full dataset loader for production history & QC.
abstract final class ProductionHistoryDatasetLoader {
  static ProductionReturnEntity mapReturn(ProductionReturnRow r) =>
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

  static ProductionInspectionEntity mapInspection(ProductionInspectionRow r) =>
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

  static RejectionRecordEntity mapRejection(RejectionRecordRow r) =>
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

  static RejectionRepairEntity mapRepair(RejectionRepairRow r) =>
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

  static Future<ProductionHistoryDataset> loadDataset(AppDatabase db) async {
    final allLots = await db.select(db.lots).get();
    final allDesigns = await db.select(db.lotDesigns).get();
    final allColours = await db.select(db.designColours).get();
    final allProcs = await db.select(db.processes).get();
    final allWorkers = await db.select(db.members).get();
    final allMovements = (await db.stockMovementDao.getAllMovements())
        .map(LedgerRowMappers.stockMovement)
        .toList();
    final allReturns = (await db.productionTrackingDao.getAllReturns())
        .map(mapReturn)
        .toList();
    final allInspections = (await db.productionTrackingDao.getAllInspections())
        .map(mapInspection)
        .toList();
    final allRejections = (await db.productionTrackingDao.getAllRejections())
        .map(mapRejection)
        .toList();
    final allRepairs = (await db.productionTrackingDao.getAllRepairs())
        .map(mapRepair)
        .toList();
    final allLabour = (await db.labourEntryDao.getAllEntries())
        .map(LedgerRowMappers.labourEntry)
        .toList();
    final allPayments = (await db.paymentDao.getAllPayments())
        .map(LedgerRowMappers.payment)
        .toList();
    final allAdjustments = (await db.workerAdjustmentDao.getAllAdjustments())
        .map(LedgerRowMappers.workerAdjustment)
        .toList();
    final handoverRows = await db.jobProcessDao.getAllHandovers();

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
}
