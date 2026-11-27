import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/mappers/ledger_row_mappers.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/process_routing/data/repositories/process_routing_support.dart';
import 'package:business_manager/features/process_routing/domain/calculators/job_process_progress_calculator.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';

/// Read, hydration, and batched progress queries for [ProcessRoutingRepositoryImpl].
final class ProcessRoutingReadDelegate {
  const ProcessRoutingReadDelegate(this._db, this._stockRepo);

  final AppDatabase _db;
  final StockMovementRepository _stockRepo;

  /// Batched progress loader (constant 4 DB queries regardless of row count).
  Future<Map<String, JobProcessProgress>> loadProgress(
    List<JobProcessRow> rows,
  ) async {
    if (rows.isEmpty) return const {};
    final colourIds = {for (final r in rows) r.designColourId}.toList();
    final lotIds = {for (final r in rows) r.lotId}.toList();

    final pendingByIssue = await _stockRepo.getPendingInspectionByIssue();
    final allMovements = await _db.stockMovementDao
        .getMovementsForDesignColours(colourIds);
    final allLabour = await _db.labourEntryDao.getEntriesForLots(lotIds);
    final allHandovers = await _db.jobProcessDao.getHandoversForLots(lotIds);

    final movsByColour = <String, List<StockMovementEntity>>{};
    for (final m in allMovements) {
      movsByColour
          .putIfAbsent(m.designColourId, () => [])
          .add(LedgerRowMappers.stockMovement(m));
    }

    final labourByLot = <String, List<LabourEntryEntity>>{};
    for (final l in allLabour) {
      labourByLot
          .putIfAbsent(l.lotId, () => [])
          .add(LedgerRowMappers.labourEntry(l));
    }

    final transferOut = <String, int>{};
    for (final h in allHandovers) {
      if (h.handoverType == ProcessHandoverType.directTransfer.dbValue &&
          h.fromJobProcessId != null) {
        transferOut[h.fromJobProcessId!] =
            (transferOut[h.fromJobProcessId!] ?? 0) + h.quantityDispatched;
      }
    }

    return {
      for (final r in rows)
        r.id: ProcessRoutingSupport.progressCalc.calculate(
          jobProcessId: r.id,
          movementsForColour: movsByColour[r.designColourId] ?? const [],
          pendingInspectionByIssue: pendingByIssue,
          labourEntries: labourByLot[r.lotId] ?? const [],
          legacyLinkedIssueId: r.linkedIssueMovementId,
          directTransferOutQty: transferOut[r.id] ?? 0,
        ),
    };
  }

  JobProcessEntity toEntity(
    JobProcessRow row,
    JobProcessProgress p, {
    required String designName,
    required String colourName,
    required String processName,
    required String? workerName,
  }) {
    final fromStock = p.issueIds.isNotEmpty;
    final dispatched = fromStock
        ? p.dispatchedQuantity
        : row.dispatchedQuantity;
    final returned = fromStock
        ? p.returnedToFactoryQuantity
        : row.returnedToFactoryQuantity;
    final transferred = fromStock
        ? p.transferredOutQuantity
        : row.transferredOutQuantity;
    final damaged = fromStock
        ? p.damagedQuantity + p.lostShortageQuantity
        : row.damagedQuantity;
    final inQc = fromStock ? p.pendingInspectionQuantity : 0;
    final withWorker = fromStock ? p.withWorkerQuantity : 0;
    final stored = JobProcessStatus.fromDbValue(row.status);
    final JobProcessStatus status;
    if (stored == JobProcessStatus.cancelled) {
      status = stored;
    } else if (stored == JobProcessStatus.completed &&
        withWorker == 0 &&
        inQc == 0) {
      status = stored;
    } else if (fromStock) {
      final derived = ProcessRoutingSupport.validator.resolveStatus(
        dispatchedQty: dispatched,
        receivedQty: row.receivedQuantity,
        returnedQty: returned,
        transferredOutQty: transferred,
        damagedQty: damaged + inQc,
        isCancelled: false,
      );
      status = inQc > 0 && derived.isTerminal
          ? JobProcessStatus.partiallyReturned
          : derived;
    } else {
      status = stored;
    }

    return JobProcessEntity(
      id: row.id,
      lotId: row.lotId,
      lotDesignId: row.lotDesignId,
      designColourId: row.designColourId,
      designName: designName,
      colourName: colourName,
      processId: row.processId,
      processName: processName,
      memberId: row.memberId,
      workerName: workerName,
      sequenceOrder: row.sequenceOrder,
      plannedQuantity: dispatched > row.plannedQuantity
          ? dispatched
          : row.plannedQuantity,
      dispatchedQuantity: dispatched,
      receivedQuantity: row.receivedQuantity > dispatched
          ? dispatched
          : row.receivedQuantity,
      returnedToFactoryQuantity: returned,
      transferredOutQuantity: transferred,
      damagedQuantity: damaged,
      pendingInspectionQuantity: inQc,
      openIssueIds: p.openIssueIds,
      status: status,
      sourceJobProcessId: row.sourceJobProcessId,
      linkedIssueMovementId: row.linkedIssueMovementId,
      defaultRatePaise: row.defaultRatePaise,
      agreedRatePaise: row.agreedRatePaise,
      pricingUnit: row.pricingUnit,
      rateOverrideReason: row.rateOverrideReason,
      payableAmountPaise: fromStock
          ? p.payableAmountPaise
          : row.payableAmountPaise,
      paidAmountPaise: row.paidAmountPaise,
      paymentStatus: ProcessPaymentStatus.fromDbValue(row.paymentStatus),
      notes: row.notes,
      transactionAt: row.transactionAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<JobProcessEntity> hydrateJobProcess(JobProcessRow row) async =>
      (await hydrateWithProgress(row)).entity;

  Future<({JobProcessEntity entity, JobProcessProgress progress})>
  hydrateWithProgress(JobProcessRow row) async {
    final design = await _db.lotDao.findDesignById(row.lotDesignId);
    final colour = await _db.lotDao.findDesignColourById(row.designColourId);
    final proc = await _db.processMemberDao.findProcessById(row.processId);
    final member = row.memberId != null
        ? await _db.processMemberDao.findMemberById(row.memberId!)
        : null;
    final progress =
        (await loadProgress([row]))[row.id] ?? JobProcessProgress.empty;
    return (
      entity: toEntity(
        row,
        progress,
        designName: design?.designName ?? '-',
        colourName: colour?.colourName ?? '-',
        processName: proc?.name ?? '-',
        workerName: member?.name,
      ),
      progress: progress,
    );
  }

  Future<ProcessHandoverEntity> hydrateHandover(ProcessHandoverRow row) async {
    final design = await _db.lotDao.findDesignById(row.lotDesignId);
    final colour = await _db.lotDao.findDesignColourById(row.designColourId);
    final proc = await _db.processMemberDao.findProcessById(row.processId);
    final fromMember = row.fromMemberId != null
        ? await _db.processMemberDao.findMemberById(row.fromMemberId!)
        : null;
    final toMember = row.toMemberId != null
        ? await _db.processMemberDao.findMemberById(row.toMemberId!)
        : null;

    return ProcessHandoverEntity(
      id: row.id,
      transferReference: row.transferReference,
      clientRequestId: row.clientRequestId,
      lotId: row.lotId,
      lotDesignId: row.lotDesignId,
      designColourId: row.designColourId,
      designName: design?.designName ?? '-',
      colourName: colour?.colourName ?? '-',
      handoverType: ProcessHandoverType.fromDbValue(row.handoverType),
      fromJobProcessId: row.fromJobProcessId,
      toJobProcessId: row.toJobProcessId,
      fromMemberId: row.fromMemberId,
      fromMemberName: fromMember?.name,
      toMemberId: row.toMemberId,
      toMemberName: toMember?.name,
      processId: row.processId,
      processName: proc?.name ?? '-',
      quantityDispatched: row.quantityDispatched,
      quantityReceived: row.quantityReceived,
      status: ProcessHandoverStatus.fromDbValue(row.status),
      linkedStockMovementId: row.linkedStockMovementId,
      notes: row.notes,
      transactionAt: row.transactionAt,
      recordedAt: row.recordedAt,
    );
  }

  ProcessAdditionalChargeEntity mapCharge(ProcessAdditionalChargeRow r) {
    return ProcessAdditionalChargeEntity(
      id: r.id,
      jobProcessId: r.jobProcessId,
      lotId: r.lotId,
      designColourId: r.designColourId,
      memberId: r.memberId,
      chargeType: ProcessChargeType.fromDbValue(r.chargeType),
      description: r.description,
      amountPaise: r.amountPaise,
      transactionAt: r.transactionAt,
      createdAt: r.createdAt,
    );
  }

  Future<JobRoutingOverview?> getJobRoutingOverview(String lotId) async {
    final lotRow = await _db.lotDao.findLotById(lotId);
    if (lotRow == null || lotRow.deletedAt != null) return null;

    final lot = LotEntity(
      id: lotRow.id,
      lotNumber: lotRow.lotNumber,
      title: lotRow.title,
      notes: lotRow.notes,
      status: LotStatus.fromDbValue(lotRow.status),
      transactionAt: lotRow.transactionAt,
      recordedAt: lotRow.recordedAt,
      createdAt: lotRow.createdAt,
      updatedAt: lotRow.updatedAt,
    );

    final skuBalances = await _stockRepo.getAllDesignColourBalances(
      lotId: lotId,
    );
    final processRows = await _db.jobProcessDao.getJobProcessesForLot(lotId);
    final handoverRows = await _db.jobProcessDao.getHandoversForLot(lotId);
    final chargeRows = await _db.jobProcessDao.getChargesForLot(lotId);

    final nonDeletedProcs = await _db.processMemberDao.getNonDeletedProcesses();
    final nonDeletedMembers = await _db.processMemberDao.getNonDeletedMembers();
    final activeProcesses = nonDeletedProcs
        .where((p) => p.isActive == 1)
        .toList();
    final activeMembers = nonDeletedMembers
        .where((m) => m.isActive == 1)
        .toList();

    final designs = await _db.lotDao.getDesignsForLot(lotId);
    final designById = {for (final d in designs) d.id: d.designName};
    final colourById = {for (final b in skuBalances) b.designColourId: b};
    final procById = {for (final p in nonDeletedProcs) p.id: p.name};
    final memberById = {for (final m in nonDeletedMembers) m.id: m.name};
    final defaultPricingByProcessId = {
      for (final p in nonDeletedProcs)
        p.id: ProcessDefaultPricing(
          processId: p.id,
          defaultRatePaise: p.defaultRatePaise,
          defaultPricingUnit: p.defaultPricingUnit,
        ),
    };

    final progressById = await loadProgress(processRows);
    final jobProcesses = processRows.map((row) {
      final sku = colourById[row.designColourId];
      return toEntity(
        row,
        progressById[row.id] ?? JobProcessProgress.empty,
        designName: sku?.designName ?? designById[row.lotDesignId] ?? '-',
        colourName: sku?.colourName ?? '-',
        processName: procById[row.processId] ?? '-',
        workerName: row.memberId != null ? memberById[row.memberId!] : null,
      );
    }).toList();

    final handovers = handoverRows.map((row) {
      final sku = colourById[row.designColourId];
      return ProcessHandoverEntity(
        id: row.id,
        transferReference: row.transferReference,
        clientRequestId: row.clientRequestId,
        lotId: row.lotId,
        lotDesignId: row.lotDesignId,
        designColourId: row.designColourId,
        designName: sku?.designName ?? designById[row.lotDesignId] ?? '-',
        colourName: sku?.colourName ?? '-',
        handoverType: ProcessHandoverType.fromDbValue(row.handoverType),
        fromJobProcessId: row.fromJobProcessId,
        toJobProcessId: row.toJobProcessId,
        fromMemberId: row.fromMemberId,
        fromMemberName: row.fromMemberId != null
            ? memberById[row.fromMemberId!]
            : null,
        toMemberId: row.toMemberId,
        toMemberName: row.toMemberId != null
            ? memberById[row.toMemberId!]
            : null,
        processId: row.processId,
        processName: procById[row.processId] ?? '-',
        quantityDispatched: row.quantityDispatched,
        quantityReceived: row.quantityReceived,
        status: ProcessHandoverStatus.fromDbValue(row.status),
        linkedStockMovementId: row.linkedStockMovementId,
        notes: row.notes,
        transactionAt: row.transactionAt,
        recordedAt: row.recordedAt,
      );
    }).toList();

    final additionalCharges = chargeRows.map(mapCharge).toList();
    final costSummary = ProcessRoutingSupport.pricingCalc
        .calculateJobCostSummary(
          jobProcesses: jobProcesses,
          charges: additionalCharges,
        );

    final locations = <GoodsLocationBucket>[];
    final factoryTotal = skuBalances.fold(
      0,
      (sum, b) => sum + b.physicalAvailableInHouse,
    );
    if (factoryTotal > 0) {
      locations.add(
        GoodsLocationBucket(
          locationLabel: 'Factory',
          operationLabel: 'In-House Ready',
          quantity: factoryTotal,
          isFactory: true,
        ),
      );
    }
    for (final jp in jobProcesses) {
      if (!jp.status.isTerminal && jp.pendingQuantity > 0) {
        locations.add(
          GoodsLocationBucket(
            locationLabel: jp.workerName ?? 'Unassigned',
            operationLabel: '${jp.processName} • ${jp.variantLabel}',
            quantity: jp.pendingQuantity,
            isFactory: false,
          ),
        );
      }
    }

    return JobRoutingOverview(
      lot: lot,
      skuBalances: skuBalances,
      jobProcesses: jobProcesses,
      handovers: handovers,
      currentLocations: locations,
      availableProcesses: activeProcesses
          .map(
            (p) => ProcessEntity(
              id: p.id,
              name: p.name,
              description: p.description,
              isActive: p.isActive == 1,
              includeDamagedInLabour: p.includeDamagedInLabour == 1,
              createdAt: p.createdAt,
              updatedAt: p.updatedAt,
            ),
          )
          .toList(),
      availableWorkers: activeMembers
          .map(
            (m) => WorkerEntity(
              id: m.id,
              name: m.name,
              phone: m.phone,
              address: m.address,
              notes: m.notes,
              isActive: m.isActive == 1,
              createdAt: m.createdAt,
              updatedAt: m.updatedAt,
            ),
          )
          .toList(),
      defaultPricingByProcessId: defaultPricingByProcessId,
      additionalCharges: additionalCharges,
      costSummary: costSummary,
    );
  }

  Future<List<ProcessRateHistoryEntity>> getProcessRateHistory(
    String processId,
  ) async {
    final rows = await _db.jobProcessDao.getRateHistoryForProcess(processId);
    return rows
        .map(
          (r) => ProcessRateHistoryEntity(
            id: r.id,
            scope: r.scope,
            processId: r.processId,
            jobProcessId: r.jobProcessId,
            memberId: r.memberId,
            designColourId: r.designColourId,
            previousRatePaise: r.previousRatePaise,
            newRatePaise: r.newRatePaise,
            pricingUnit: r.pricingUnit,
            reason: r.reason,
            changedBy: r.changedBy,
            changedAt: r.changedAt,
          ),
        )
        .toList();
  }
}
