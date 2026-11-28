import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/mappers/ledger_row_mappers.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/domain/repositories/accounting_repository.dart';
import 'package:business_manager/features/cashbook/domain/calculators/cashbook_calculator.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/parties/data/repositories/party_repository_impl.dart';
import 'package:business_manager/features/parties/domain/repositories/party_repository.dart';
import 'package:business_manager/features/production_history/domain/calculators/production_history_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/calculators/stock_calculator.dart';
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
  ReportsRepositoryImpl(
    this._db,
    this._stockRepo,
    this._accountingRepo,
    this._partyRepo,
  );

  final AppDatabase _db;
  final StockMovementRepository _stockRepo;
  final AccountingRepository _accountingRepo;
  final PartyRepository _partyRepo;

  static const WorkshopDailyCalculator _dailyCalc = WorkshopDailyCalculator();
  static const ReportsAnalyticsCalculator _analyticsCalc =
      ReportsAnalyticsCalculator();

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
        .map(LedgerRowMappers.stockMovement)
        .toList();
    final allLabour = (await _db.labourEntryDao.getAllEntries())
        .map(LedgerRowMappers.labourEntry)
        .toList();
    final allPayments = (await _db.paymentDao.getAllPayments())
        .map(LedgerRowMappers.payment)
        .toList();
    final allAdjustments = (await _db.workerAdjustmentDao.getAllAdjustments())
        .map(LedgerRowMappers.workerAdjustment)
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
    final dispatchDeltas = await PartyRepositoryImpl.loadStockDeltasByColour(
      _db,
    );
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
      dispatchDeltasByColour: dispatchDeltas,
      pendingInspectionByIssue: const ProductionHistoryCalculator()
          .pendingInspectionByIssue(
            returns: allReturns,
            inspections: allInspections,
            reversedMovementIds: const StockCalculator().reversedMovementIds(
              allMovements,
            ),
          ),
    );
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

    final partySummaries = await _partyRepo.getAllPartySummaries();
    final lotPnlRows = await _partyRepo.getAllLotProfitLoss();

    final cashbookExpenses = (await _db.cashbookDao.getAllExpenses())
        .map(LedgerRowMappers.workshopExpense)
        .toList();
    final cashbookEntries = (await _db.cashbookDao.getAllCashbookEntries())
        .map(LedgerRowMappers.cashbookEntry)
        .toList();
    final partyPayments = (await _db.partyDispatchDao.getAllPartyPayments())
        .map(LedgerRowMappers.partyPayment)
        .toList();
    final challans = (await _db.partyDispatchDao.getAllChallans())
        .map(LedgerRowMappers.dispatchChallan)
        .toList();
    final buyerReturns = (await _db.partyDispatchDao.getAllBuyerReturns())
        .map(LedgerRowMappers.buyerReturn)
        .toList();
    final lotDirectCosts = (await _db.partyDispatchDao.getAllLotDirectCosts())
        .map(LedgerRowMappers.lotDirectCost)
        .toList();
    final nonDeletedParties = await _db.partyDispatchDao.getNonDeletedParties();
    const cashbookCalc = CashbookCalculator();
    final cashbookSummary = cashbookCalc.calculateSummary(
      expenses: cashbookExpenses,
      cashbookEntries: cashbookEntries,
      workerPayments: allPayments,
      partyPayments: partyPayments,
      workerNames: {for (final w in workers) w.id: w.name},
      partyNames: {for (final p in nonDeletedParties) p.id: p.name},
      fromUtcMillis: filter.fromUtcMillis,
      toUtcMillis: filter.toUtcMillis,
    );
    final trueNetProfit = cashbookCalc.calculateTrueNetProfit(
      challans: challans,
      buyerReturns: buyerReturns,
      labourEntries: allLabour,
      workerAdjustments: allAdjustments,
      lotDirectCosts: lotDirectCosts,
      workshopExpenses: cashbookExpenses,
      cashbookEntries: cashbookEntries,
      fromUtcMillis: filter.fromUtcMillis,
      toUtcMillis: filter.toUtcMillis,
    );

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
      partySummaries: partySummaries,
      lotProfitLossRows: lotPnlRows,
      cashbookSummary: cashbookSummary,
      trueNetProfit: trueNetProfit,
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
        .map(LedgerRowMappers.stockMovement)
        .toList();
    final allLabour = (await _db.labourEntryDao.getAllEntries())
        .map(LedgerRowMappers.labourEntry)
        .toList();
    final allPayments = (await _db.paymentDao.getAllPayments())
        .map(LedgerRowMappers.payment)
        .toList();

    final activeLotIds = {for (final l in activeLots) l.id};
    final validDesigns = activeDesigns
        .where((d) => activeLotIds.contains(d.lotId))
        .length;

    var initialStock = 0;
    var availableGood = 0;
    var damaged = 0;
    var pending = 0;
    var pendingInspection = 0;
    var lost = 0;
    var shortage = 0;
    var dispatched = 0;
    for (final b in colourBalances) {
      initialStock += b.initialQuantity;
      availableGood += b.physicalAvailableInHouse;
      damaged += b.damagedBucket;
      pending += b.totalPendingWithWorkers;
      pendingInspection += b.totalPendingInspection;
      lost += b.totalLost;
      shortage += b.totalShortage;
      dispatched += b.netDispatchedQty;
    }

    final partySummaries = await _partyRepo.getAllPartySummaries();
    var totalPartyReceivable = 0;
    var totalPartyAdvanceCredit = 0;
    for (final p in partySummaries) {
      totalPartyReceivable += p.outstandingReceivablePaise;
      totalPartyAdvanceCredit += p.advanceCreditPaise;
    }

    final cashbookExpenses = (await _db.cashbookDao.getAllExpenses())
        .map(LedgerRowMappers.workshopExpense)
        .toList();
    final cashbookEntries = (await _db.cashbookDao.getAllCashbookEntries())
        .map(LedgerRowMappers.cashbookEntry)
        .toList();
    final allPartyPayments = (await _db.partyDispatchDao.getAllPartyPayments())
        .map(LedgerRowMappers.partyPayment)
        .toList();
    final cashbookSummary = const CashbookCalculator().calculateSummary(
      expenses: cashbookExpenses,
      cashbookEntries: cashbookEntries,
      workerPayments: allPayments,
      partyPayments: allPartyPayments,
    );

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
      pendingInspectionStock: pendingInspection,
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
      dispatchedStock: dispatched,
      totalPartyReceivablePaise: totalPartyReceivable,
      totalPartyAdvanceCreditPaise: totalPartyAdvanceCredit,
      cashBalancePaise: cashbookSummary.currentCashBalancePaise,
      bankBalancePaise: cashbookSummary.currentBankBalancePaise,
      todayExpensesPaise: cashbookSummary.todayExpensesPaise,
      unpaidBillsPaise: cashbookSummary.totalExpensesUnpaidPaise,
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
        .map(LedgerRowMappers.stockMovement)
        .toList();
    final allLabour = (await _db.labourEntryDao.getAllEntries())
        .map(LedgerRowMappers.labourEntry)
        .toList();
    final allPayments = (await _db.paymentDao.getAllPayments())
        .map(LedgerRowMappers.payment)
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
      var pendInsp = 0;
      var dmg = 0;
      var lost = 0;
      var shrt = 0;
      var valuePaise = 0;
      for (final c in cols) {
        initQty += c.initialQuantity;
        avail += c.physicalAvailableInHouse;
        pend += c.totalPendingWithWorkers;
        pendInsp += c.totalPendingInspection;
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
          pendingInspection: pendInsp,
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
