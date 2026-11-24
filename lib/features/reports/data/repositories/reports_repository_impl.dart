import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/accounting/domain/repositories/accounting_repository.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/production_history/domain/calculators/production_history_calculator.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/reports/domain/calculators/reports_analytics_calculator.dart';
import 'package:business_manager/features/reports/domain/calculators/workshop_daily_calculator.dart';
import 'package:business_manager/features/reports/domain/entities/advanced_report_entities.dart';
import 'package:business_manager/features/reports/domain/entities/dashboard_report_entities.dart';
import 'package:business_manager/features/reports/domain/entities/report_filter.dart';
import 'package:business_manager/features/reports/domain/repositories/reports_repository.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ReportsRepository)
final class ReportsRepositoryImpl implements ReportsRepository {
  ReportsRepositoryImpl(this._db, this._stockRepo, this._accountingRepo);

  final AppDatabase _db;
  final StockMovementRepository _stockRepo;
  final AccountingRepository _accountingRepo;

  static const WorkshopDailyCalculator _dailyCalc = WorkshopDailyCalculator();
  static const ReportsAnalyticsCalculator _analyticsCalc =
      ReportsAnalyticsCalculator();

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

  @override
  Future<AdvancedReportsBundle> getAdvancedReports(ReportFilter filter) async {
    // Single-pass load: fetch each table ONCE (no redundant 5x full scans).
    final profile = await _db.businessProfileDao.getProfile();
    final activeLots = await _db.lotDao.getActiveLots();
    final activeDesigns = await _db.lotDao.getAllActiveDesigns();
    final activeColours = await _db.lotDao.getAllActiveDesignColours();
    final processes = await _db.processMemberDao.getNonDeletedProcesses();
    final workers = await _db.processMemberDao.getNonDeletedMembers();

    final allMovements = (await _db.stockMovementDao.getAllMovements())
        .map(_mapMovement)
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

    final activeLotIds = {for (final l in activeLots) l.id};
    final lotInputs = activeLots
        .map(
          (l) => ReportLotInput(
            id: l.id,
            lotNumber: l.lotNumber,
            title: l.title,
            status: LotStatus.fromDbValue(l.status),
          ),
        )
        .toList();
    final designInputs = activeDesigns
        .where((d) => activeLotIds.contains(d.lotId))
        .map(
          (d) => ReportDesignInput(
            id: d.id,
            lotId: d.lotId,
            designName: d.designName,
          ),
        )
        .toList();
    final activeDesignById = {for (final d in designInputs) d.id: d};
    final colourInputs = activeColours
        .where((c) => activeDesignById.containsKey(c.lotDesignId))
        .map((c) {
          final design = activeDesignById[c.lotDesignId]!;
          return ReportColourInput(
            id: c.id,
            lotId: design.lotId,
            lotDesignId: c.lotDesignId,
            colourName: c.colourName,
            colourHex: c.colourHex,
            initialQuantity: c.initialQuantity,
            unitPricePaise: c.unitPricePaise,
          );
        })
        .toList();
    final processInputs = processes
        .map(
          (p) => ReportProcessInput(
            id: p.id,
            name: p.name,
            isActive: p.isActive == 1,
          ),
        )
        .toList();
    final workerInputs = workers
        .map(
          (w) => ReportWorkerInput(
            id: w.id,
            name: w.name,
            phone: w.phone,
            isActive: w.isActive == 1,
          ),
        )
        .toList();

    final base = _analyticsCalc.compute(
      filter: filter,
      businessNameEn: profile?.nameEn ?? 'StitchFlow',
      businessNameGu: profile?.nameGu ?? 'સ્ટિચફ્લો',
      lots: lotInputs,
      designs: designInputs,
      colours: colourInputs,
      processes: processInputs,
      workers: workerInputs,
      allMovements: allMovements,
      allLabourEntries: allLabour,
      allPayments: allPayments,
      allAdjustments: allAdjustments,
    );

    // Enrich bundle with Schema v8 Pending Inspection, Rejection Records, and
    // Complete Production History rows (Rule 7 & Phase 10).
    final allReturns = (await _db.productionTrackingDao.getAllReturns())
        .map(
          (r) => ProductionReturnEntity(
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
          ),
        )
        .toList();
    final allInspections = (await _db.productionTrackingDao.getAllInspections())
        .map(
          (r) => ProductionInspectionEntity(
            id: r.id,
            clientRequestId: r.clientRequestId,
            inspectionType: ProductionInspectionType.fromDbValue(
              r.inspectionType,
            ),
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
          ),
        )
        .toList();
    final allRejections = (await _db.productionTrackingDao.getAllRejections())
        .map(
          (r) => RejectionRecordEntity(
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
          ),
        )
        .toList();
    final allRepairs = (await _db.productionTrackingDao.getAllRepairs())
        .map(
          (r) => RejectionRepairEntity(
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
          ),
        )
        .toList();

    final dataset = ProductionHistoryDataset(
      lots: {
        for (final l in activeLots)
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
      designs: {
        for (final d in activeDesigns)
          d.id: LotDesignEntity(
            id: d.id,
            lotId: d.lotId,
            designName: d.designName,
            notes: d.notes,
            createdAt: d.createdAt,
            updatedAt: d.updatedAt,
          ),
      },
      colours: {
        for (final c in activeColours)
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
      },
      processes: {
        for (final p in processes)
          p.id: (name: p.name, isActive: p.isActive == 1),
      },
      workers: {
        for (final w in workers)
          w.id: (
            name: w.name,
            phone: w.phone,
            address: w.address,
            notes: w.notes,
            isActive: w.isActive == 1,
            createdAt: w.createdAt,
          ),
      },
      movements: allMovements,
      returns: allReturns,
      inspections: allInspections,
      rejections: allRejections,
      repairs: allRepairs,
      labourEntries: allLabour,
      payments: allPayments,
      adjustments: allAdjustments,
      handovers: const [],
    );

    const prodCalc = ProductionHistoryCalculator();
    final prodRows = prodCalc.buildAssignments(
      dataset,
      filter: ProductionHistoryFilter(
        fromUtcMillis: filter.fromUtcMillis,
        toUtcMillis: filter.toUtcMillis,
        lotId: filter.lotId,
        workerId: filter.workerId,
        processId: filter.processId,
        searchQuery: filter.searchQuery,
      ),
    );
    final pendingRets = prodCalc.buildPendingReturns(
      dataset,
      lotId: filter.lotId,
      workerId: filter.workerId,
      processId: filter.processId,
    );
    final rejRows = prodCalc.buildRejectionViews(
      dataset,
      lotId: filter.lotId,
      workerId: filter.workerId,
      processId: filter.processId,
    );
    final totalPendingInsp = pendingRets.fold<int>(
      0,
      (s, r) => s + r.remainingPendingInspectionQty,
    );

    final pendingInspByWorker = <String, int>{};
    final pendingInspByProcess = <String, int>{};
    for (final r in pendingRets) {
      pendingInspByWorker[r.productionReturn.memberId] =
          (pendingInspByWorker[r.productionReturn.memberId] ?? 0) +
          r.remainingPendingInspectionQty;
      pendingInspByProcess[r.productionReturn.processId] =
          (pendingInspByProcess[r.productionReturn.processId] ?? 0) +
          r.remainingPendingInspectionQty;
    }

    final enrichedWorkers = base.workerPerformance
        .map(
          (w) => WorkerPerformanceRow(
            workerId: w.workerId,
            workerName: w.workerName,
            workerIsActive: w.workerIsActive,
            periodIssuedQty: w.periodIssuedQty,
            periodGoodReturnedQty: w.periodGoodReturnedQty,
            periodDamagedQty: w.periodDamagedQty,
            periodLostShortageQty: w.periodLostShortageQty,
            periodLabourEarnedPaise: w.periodLabourEarnedPaise,
            periodRegularPaymentsPaise: w.periodRegularPaymentsPaise,
            periodAdvancePaymentsPaise: w.periodAdvancePaymentsPaise,
            periodAdvanceRefundsPaise: w.periodAdvanceRefundsPaise,
            periodNetPaymentsPaise: w.periodNetPaymentsPaise,
            currentPendingQty: w.currentPendingQty,
            currentPendingInspectionQty: pendingInspByWorker[w.workerId] ?? 0,
            currentOpenIssuesCount: w.currentOpenIssuesCount,
            currentOutstandingPayablePaise: w.currentOutstandingPayablePaise,
            currentAdvanceCreditPaise: w.currentAdvanceCreditPaise,
            defectRatePercent: w.defectRatePercent,
            processBreakdown: w.processBreakdown,
          ),
        )
        .toList();

    final enrichedProcs = base.processPerformance
        .map(
          (p) => ProcessPerformanceRow(
            processId: p.processId,
            processName: p.processName,
            periodIssuedQty: p.periodIssuedQty,
            periodGoodReturnedQty: p.periodGoodReturnedQty,
            periodDamagedQty: p.periodDamagedQty,
            periodLostShortageQty: p.periodLostShortageQty,
            periodLabourCostPaise: p.periodLabourCostPaise,
            currentPendingQty: p.currentPendingQty,
            currentPendingInspectionQty: pendingInspByProcess[p.processId] ?? 0,
            currentOpenIssuesCount: p.currentOpenIssuesCount,
            oldestOpenIssueAgeDays: p.oldestOpenIssueAgeDays,
            averageTurnaroundHours: p.averageTurnaroundHours,
            settledIssuesCount: p.settledIssuesCount,
            defectRatePercent: p.defectRatePercent,
            workerContributions: p.workerContributions,
          ),
        )
        .toList();

    return AdvancedReportsBundle(
      filter: base.filter,
      filterOptions: base.filterOptions,
      businessNameEn: base.businessNameEn,
      businessNameGu: base.businessNameGu,
      generatedAtUtcMillis: base.generatedAtUtcMillis,
      dailyRows: base.dailyRows,
      dailyTotalIssued: base.dailyTotalIssued,
      dailyTotalGoodReturned: base.dailyTotalGoodReturned,
      dailyTotalDamaged: base.dailyTotalDamaged,
      dailyTotalLostShortage: base.dailyTotalLostShortage,
      dailyTotalLabourPaise: base.dailyTotalLabourPaise,
      dailyTotalNetPaymentsPaise: base.dailyTotalNetPaymentsPaise,
      currentTotalPendingQty: base.currentTotalPendingQty,
      currentTotalPendingInspectionQty: totalPendingInsp,
      workerPerformance: enrichedWorkers,
      processPerformance: enrichedProcs,
      inventory: base.inventory,
      financial: base.financial,
      insights: base.insights,
      productionHistoryRows: prodRows,
      pendingInspectionReturns: pendingRets,
      rejectionRecords: rejRows,
    );
  }

  @override
  Future<DashboardSnapshot> getDashboardSnapshot() async {
    final profile = await _db.businessProfileDao.getProfile();
    final activeLots = await _db.lotDao.getActiveLots();
    final activeDesigns = await _db.lotDao.getAllActiveDesigns();
    final processes = await _db.processMemberDao.getNonDeletedProcesses();
    final workers = await _db.processMemberDao.getNonDeletedMembers();

    final colourBalances = await _stockRepo.getAllDesignColourBalances();
    final processSummaries = await _stockRepo.getProcessStockSummaries();
    final openIssues = await _stockRepo.getOpenIssues();
    final workerFinancials = await _accountingRepo.getAllWorkerSummaries();
    final auditRows = await _db.attachmentAuditDao.getRecentAuditLogs(
      limit: 12,
    );

    final allMovements = (await _db.stockMovementDao.getAllMovements())
        .map(_mapMovement)
        .toList();
    final allLabour = (await _db.labourEntryDao.getAllEntries())
        .map(_mapLabour)
        .toList();
    final allPayments = (await _db.paymentDao.getAllPayments())
        .map(_mapPayment)
        .toList();

    final activeLotIds = {for (final l in activeLots) l.id};
    final validDesigns = activeDesigns
        .where((d) => activeLotIds.contains(d.lotId))
        .length;

    var initialStock = 0;
    var availableGood = 0;
    var damaged = 0;
    var pending = 0;
    var lost = 0;
    var shortage = 0;
    for (final b in colourBalances) {
      initialStock += b.initialQuantity;
      availableGood += b.physicalAvailableInHouse;
      damaged += b.damagedBucket;
      pending += b.totalPendingWithWorkers;
      lost += b.totalLost;
      shortage += b.totalShortage;
    }

    var earnedLabour = 0;
    var adjNet = 0;
    var regPay = 0;
    var advPay = 0;
    var advRef = 0;
    var outstanding = 0;
    var advCredit = 0;
    for (final w in workerFinancials) {
      earnedLabour += w.earnedLabourPaise;
      adjNet += w.netAdjustmentsPaise;
      regPay += w.regularPaymentsPaise;
      advPay += w.advancePaymentsPaise;
      advRef += w.advanceRefundsPaise;
      outstanding += w.outstandingPayablePaise;
      advCredit += w.advanceCreditBalancePaise;
    }

    final procNames = {for (final p in processes) p.id: p.name};
    final workerNames = {for (final w in workers) w.id: w.name};
    final todaySummary = _dailyCalc.calculateDailySummary(
      targetDayUtcMillis: IstDateTimeHelper.nowUtcMillis(),
      allMovements: allMovements,
      allLabourEntries: allLabour,
      allPayments: allPayments,
      processNamesById: procNames,
      workerNamesById: workerNames,
      currentTotalPendingQty: pending,
      currentTotalDamagedQty: damaged,
      currentTotalOutstandingPayablePaise: outstanding,
    );
    final importantPending = _dailyCalc.prioritizeImportantPending(
      openIssues,
      limit: 5,
    );

    final recentActivity = auditRows
        .map(
          (a) => RecentActivityItem(
            id: a.id,
            entityType: a.entityType,
            entityId: a.entityId,
            actionType: a.actionType,
            actor: a.actor,
            reason: a.reason,
            transactionAt: a.transactionAt,
            recordedAt: a.recordedAt,
          ),
        )
        .toList();

    return DashboardSnapshot(
      businessNameEn: profile?.nameEn ?? 'Business Manager',
      businessNameGu: profile?.nameGu ?? 'બિઝનેસ મેનેજર',
      totalLots: activeLots.length,
      totalDesigns: validDesigns,
      totalColours: colourBalances.length,
      activeProcessesCount: processes.where((p) => p.isActive == 1).length,
      activeWorkersCount: workers.where((w) => w.isActive == 1).length,
      totalInitialStock: initialStock,
      availableGoodStock: availableGood,
      damagedStock: damaged,
      pendingWorkerStock: pending,
      lostStock: lost,
      shortageStock: shortage,
      processPendingList: processSummaries,
      totalEarnedLabourPaise: earnedLabour,
      totalAdjustmentNetPaise: adjNet,
      totalRegularPaymentsPaise: regPay,
      totalAdvancePaymentsPaise: advPay,
      totalAdvanceRefundsPaise: advRef,
      totalOutstandingPayablePaise: outstanding,
      totalAdvanceCreditPaise: advCredit,
      recentActivity: recentActivity,
      todayIstDate: todaySummary.istDateIso,
      todayIssuedQty: todaySummary.issuedQty,
      todayReceivedGoodQty: todaySummary.goodReturnedQty,
      todayDamagedQty: todaySummary.damagedQty,
      todayLostShortageQty: todaySummary.lostAndShortageQty,
      todayLabourEarnedPaise: todaySummary.labourEarnedPaise,
      todayPaymentsPaise: todaySummary.netPaymentsPaise,
      importantPendingIssues: importantPending,
    );
  }

  @override
  Future<DailyWorkshopSummary> getDailyWorkshopSummary({
    int? targetDayUtcMillis,
  }) async {
    final targetUtc = targetDayUtcMillis ?? IstDateTimeHelper.nowUtcMillis();
    final processes = await _db.select(_db.processes).get();
    final workers = await _db.select(_db.members).get();
    final allMovements = (await _db.stockMovementDao.getAllMovements())
        .map(_mapMovement)
        .toList();
    final allLabour = (await _db.labourEntryDao.getAllEntries())
        .map(_mapLabour)
        .toList();
    final allPayments = (await _db.paymentDao.getAllPayments())
        .map(_mapPayment)
        .toList();
    final colourBalances = await _stockRepo.getAllDesignColourBalances();
    final workerFinancials = await _accountingRepo.getAllWorkerSummaries();

    final currentPending = colourBalances.fold<int>(
      0,
      (s, b) => s + b.totalPendingWithWorkers,
    );
    final currentDamaged = colourBalances.fold<int>(
      0,
      (s, b) => s + b.damagedBucket,
    );
    final currentOutstanding = workerFinancials.fold<int>(
      0,
      (s, w) => s + w.outstandingPayablePaise,
    );

    return _dailyCalc.calculateDailySummary(
      targetDayUtcMillis: targetUtc,
      allMovements: allMovements,
      allLabourEntries: allLabour,
      allPayments: allPayments,
      processNamesById: {for (final p in processes) p.id: p.name},
      workerNamesById: {for (final w in workers) w.id: w.name},
      currentTotalPendingQty: currentPending,
      currentTotalDamagedQty: currentDamaged,
      currentTotalOutstandingPayablePaise: currentOutstanding,
    );
  }

  @override
  Future<BusinessReportsBundle> getBusinessReports({
    int? fromUtcMillis,
    int? toUtcMillis,
    String? lotId,
    String? workerId,
    String? processId,
    String? searchQuery,
  }) async {
    final activeLots = await _db.lotDao.getActiveLots();
    final colourBalances = await _stockRepo.getAllDesignColourBalances(
      lotId: lotId,
    );
    final workerStock = await _stockRepo.getWorkerStockSummaries();
    final processStock = await _stockRepo.getProcessStockSummaries();
    final openIssues = await _stockRepo.getOpenIssues(
      lotId: lotId,
      workerId: workerId,
      processId: processId,
    );

    final history = await _stockRepo.getMovementHistory(
      filter: StockMovementFilter(
        lotId: lotId,
        memberId: workerId,
        processId: processId,
        fromUtcMillis: fromUtcMillis,
        toUtcMillis: toUtcMillis,
        searchQuery: searchQuery,
        includeReversed: false,
      ),
    );
    final damagedLostShortage = history.where((v) {
      final t = v.movement.movementType;
      return t == StockMovementType.returnDamaged ||
          t == StockMovementType.settlementLost ||
          t == StockMovementType.settlementShortage ||
          t == StockMovementType.adjustmentDamagedToGood;
    }).toList();

    final labourEntries = await _accountingRepo.getLabourEntries(
      workerId: workerId,
      processId: processId,
      lotId: lotId,
      fromUtcMillis: fromUtcMillis,
      toUtcMillis: toUtcMillis,
    );
    final workerFinancials = await _accountingRepo.getAllWorkerSummaries();
    final payments = await _accountingRepo.getPayments(
      workerId: workerId,
      fromUtcMillis: fromUtcMillis,
      toUtcMillis: toUtcMillis,
    );

    final query = searchQuery?.trim().toLowerCase() ?? '';

    final filteredColours = query.isEmpty
        ? colourBalances
        : colourBalances
              .where(
                (b) =>
                    b.lotNumber.toLowerCase().contains(query) ||
                    b.designName.toLowerCase().contains(query) ||
                    b.colourName.toLowerCase().contains(query),
              )
              .toList();

    final coloursByLot = <String, List<DesignColourStockBalance>>{};
    for (final c in filteredColours) {
      coloursByLot.putIfAbsent(c.lotId, () => []).add(c);
    }

    final lotRows = <LotStockReportRow>[];
    for (final lot in activeLots) {
      if (lotId != null && lot.id != lotId) continue;
      if (query.isNotEmpty &&
          !lot.lotNumber.toLowerCase().contains(query) &&
          !(lot.title?.toLowerCase().contains(query) ?? false) &&
          !(coloursByLot.containsKey(lot.id))) {
        continue;
      }
      final cols = coloursByLot[lot.id] ?? const [];
      final designIds = {for (final c in cols) c.lotDesignId};
      var initQty = 0;
      var avail = 0;
      var pend = 0;
      var dmg = 0;
      var lost = 0;
      var shrt = 0;
      var valuePaise = 0;
      for (final c in cols) {
        initQty += c.initialQuantity;
        avail += c.physicalAvailableInHouse;
        pend += c.totalPendingWithWorkers;
        dmg += c.damagedBucket;
        lost += c.totalLost;
        shrt += c.totalShortage;
        valuePaise += c.totalGoodPhysicalStock * c.unitPricePaise;
      }
      lotRows.add(
        LotStockReportRow(
          lotId: lot.id,
          lotNumber: lot.lotNumber,
          title: lot.title,
          status: LotStatus.fromDbValue(lot.status),
          designCount: designIds.length,
          colourCount: cols.length,
          initialQuantity: initQty,
          availableGoodStock: avail,
          pendingWithWorkers: pend,
          damagedBucket: dmg,
          lostQuantity: lost,
          shortageQuantity: shrt,
          goodStockValuePaise: valuePaise,
        ),
      );
    }

    final filteredWorkerStock = workerStock.where((w) {
      if (workerId != null && w.workerId != workerId) return false;
      if (query.isNotEmpty && !w.workerName.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    final filteredProcessStock = processStock.where((p) {
      if (processId != null && p.processId != processId) return false;
      if (query.isNotEmpty && !p.processName.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    final filteredFinancials = workerFinancials.where((w) {
      if (workerId != null && w.workerId != workerId) return false;
      if (query.isNotEmpty && !w.workerName.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    final filteredPayments = query.isEmpty
        ? payments
        : payments
              .where(
                (p) =>
                    p.workerName.toLowerCase().contains(query) ||
                    (p.payment.referenceNo?.toLowerCase().contains(query) ??
                        false) ||
                    (p.payment.notes?.toLowerCase().contains(query) ?? false),
              )
              .toList();

    return BusinessReportsBundle(
      lotRows: lotRows,
      colourBalances: filteredColours,
      workerStockRows: filteredWorkerStock,
      processStockRows: filteredProcessStock,
      openIssues: openIssues,
      damagedLostShortageMovements: damagedLostShortage,
      labourEntries: labourEntries,
      workerFinancialSummaries: filteredFinancials,
      payments: filteredPayments,
    );
  }
}
