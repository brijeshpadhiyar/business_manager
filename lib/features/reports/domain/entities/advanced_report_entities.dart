import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/cashbook/domain/entities/cashbook_entities.dart';
import 'package:business_manager/features/parties/domain/entities/party_entities.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/reports/domain/entities/dashboard_report_entities.dart';
import 'package:business_manager/features/reports/domain/entities/report_filter.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';

/// Dropdown option item for report dimension filters.
final class ReportFilterOption {
  const ReportFilterOption({
    required this.id,
    required this.label,
    this.parentId,
    this.isActive = true,
  });

  final String id;
  final String label;
  final String? parentId;
  final bool isActive;
}

/// All available dimension filter options loaded in a single query pass.
final class ReportFilterOptions {
  const ReportFilterOptions({
    this.workers = const [],
    this.processes = const [],
    this.lots = const [],
    this.designs = const [],
    this.colours = const [],
  });

  final List<ReportFilterOption> workers;
  final List<ReportFilterOption> processes;
  final List<ReportFilterOption> lots;
  final List<ReportFilterOption> designs;
  final List<ReportFilterOption> colours;
}

/// Day-by-day IST workshop activity row (Category 1: Daily Workshop Report).
final class DailyReportRow {
  const DailyReportRow({
    required this.istDateIso,
    required this.dayStartUtcMillis,
    required this.issuedQty,
    required this.goodReturnedQty,
    required this.damagedQty,
    required this.lostQty,
    required this.shortageQty,
    required this.repairedQty,
    required this.labourEarnedPaise,
    required this.regularPaymentsPaise,
    required this.advancePaymentsPaise,
    required this.advanceRefundsPaise,
    required this.netPaymentsPaise,
  });

  final String istDateIso;
  final int dayStartUtcMillis;
  final int issuedQty;
  final int goodReturnedQty;
  final int damagedQty;
  final int lostQty;
  final int shortageQty;
  final int repairedQty;
  final int labourEarnedPaise;
  final int regularPaymentsPaise;
  final int advancePaymentsPaise;
  final int advanceRefundsPaise;
  final int netPaymentsPaise;

  int get lostAndShortageQty => lostQty + shortageQty;
}

/// Worker's productivity within a single process for the selected period.
final class WorkerProcessBreakdownItem {
  const WorkerProcessBreakdownItem({
    required this.processId,
    required this.processName,
    required this.issuedQty,
    required this.goodReturnedQty,
    required this.damagedQty,
    required this.lostShortageQty,
    required this.labourEarnedPaise,
    required this.defectRatePercent,
  });

  final String processId;
  final String processName;
  final int issuedQty;
  final int goodReturnedQty;
  final int damagedQty;
  final int lostShortageQty;
  final int labourEarnedPaise;

  /// `null` when denominator `(good + damaged + lost + shortage) == 0`.
  final double? defectRatePercent;
}

/// Per-worker performance row separating Period Flow from Current Standing (Category 2).
final class WorkerPerformanceRow {
  const WorkerPerformanceRow({
    required this.workerId,
    required this.workerName,
    required this.workerIsActive,
    required this.periodIssuedQty,
    required this.periodGoodReturnedQty,
    required this.periodDamagedQty,
    required this.periodLostShortageQty,
    required this.periodLabourEarnedPaise,
    required this.periodRegularPaymentsPaise,
    required this.periodAdvancePaymentsPaise,
    required this.periodAdvanceRefundsPaise,
    required this.periodNetPaymentsPaise,
    required this.currentPendingQty,
    this.currentPendingInspectionQty = 0,
    required this.currentOpenIssuesCount,
    required this.currentOutstandingPayablePaise,
    required this.currentAdvanceCreditPaise,
    required this.defectRatePercent,
    required this.processBreakdown,
  });

  final String workerId;
  final String workerName;
  final bool workerIsActive;
  final int periodIssuedQty;
  final int periodGoodReturnedQty;
  final int periodDamagedQty;
  final int periodLostShortageQty;
  final int periodLabourEarnedPaise;
  final int periodRegularPaymentsPaise;
  final int periodAdvancePaymentsPaise;
  final int periodAdvanceRefundsPaise;
  final int periodNetPaymentsPaise;
  final int currentPendingQty;
  final int currentPendingInspectionQty;
  final int currentOpenIssuesCount;
  final int currentOutstandingPayablePaise;
  final int currentAdvanceCreditPaise;
  final double? defectRatePercent;
  final List<WorkerProcessBreakdownItem> processBreakdown;
}

/// Worker contribution within a process (Category 3).
final class ProcessWorkerContribution {
  const ProcessWorkerContribution({
    required this.workerId,
    required this.workerName,
    required this.issuedQty,
    required this.goodReturnedQty,
    required this.sharePercent,
  });

  final String workerId;
  final String workerName;
  final int issuedQty;
  final int goodReturnedQty;
  final double? sharePercent;
}

/// Per-process throughput, pending workload, and verified turnaround time (Category 3).
final class ProcessPerformanceRow {
  const ProcessPerformanceRow({
    required this.processId,
    required this.processName,
    required this.periodIssuedQty,
    required this.periodGoodReturnedQty,
    required this.periodDamagedQty,
    required this.periodLostShortageQty,
    required this.periodLabourCostPaise,
    required this.currentPendingQty,
    this.currentPendingInspectionQty = 0,
    required this.currentOpenIssuesCount,
    required this.oldestOpenIssueAgeDays,
    required this.averageTurnaroundHours,
    required this.settledIssuesCount,
    required this.defectRatePercent,
    required this.workerContributions,
  });

  final String processId;
  final String processName;
  final int periodIssuedQty;
  final int periodGoodReturnedQty;
  final int periodDamagedQty;
  final int periodLostShortageQty;
  final int periodLabourCostPaise;
  final int currentPendingQty;
  final int currentPendingInspectionQty;
  final int currentOpenIssuesCount;
  final int? oldestOpenIssueAgeDays;

  /// Strictly verified average hours from ISSUE to final settlement across
  /// 100%-settled non-reversed issues where `t_complete >= t_issue`.
  /// `null` when [settledIssuesCount] == 0.
  final double? averageTurnaroundHours;
  final int settledIssuesCount;
  final double? defectRatePercent;
  final List<ProcessWorkerContribution> workerContributions;
}

/// Category 4: Consolidated Inventory Reports section.
final class InventoryReportSection {
  const InventoryReportSection({
    required this.initialStock,
    required this.availableGoodStock,
    required this.pendingWithWorkers,
    required this.damagedBucket,
    required this.lostStock,
    required this.shortageStock,
    required this.referenceGoodStockValuePaise,
    required this.lotRows,
    required this.colourBalances,
    required this.openIssues,
    required this.movementHistory,
    required this.damagedLostShortageMovements,
    this.pendingInspection = 0,
  });

  final int initialStock;
  final int availableGoodStock;
  final int pendingWithWorkers;
  final int damagedBucket;
  final int lostStock;
  final int shortageStock;

  /// Pieces returned and waiting for QC.
  final int pendingInspection;

  /// `SUM(totalGoodPhysicalStock * unitPricePaise)`. Reference value only — NOT profit/revenue.
  final int referenceGoodStockValuePaise;
  final List<LotStockReportRow> lotRows;
  final List<DesignColourStockBalance> colourBalances;
  final List<OpenIssueSummary> openIssues;
  final List<StockMovementView> movementHistory;
  final List<StockMovementView> damagedLostShortageMovements;
}

/// Category 5: Labour & Financial Reports section.
final class FinancialReportSection {
  const FinancialReportSection({
    required this.periodEarnedLabourPaise,
    required this.periodRegularPaymentsPaise,
    required this.periodAdvancePaymentsPaise,
    required this.periodAdvanceRefundsPaise,
    required this.periodNetPaymentsPaise,
    required this.totalCurrentOutstandingPayablePaise,
    required this.totalCurrentAdvanceCreditPaise,
    required this.labourEntries,
    required this.workerSummaries,
    required this.payments,
  });

  final int periodEarnedLabourPaise;
  final int periodRegularPaymentsPaise;
  final int periodAdvancePaymentsPaise;
  final int periodAdvanceRefundsPaise;
  final int periodNetPaymentsPaise;
  final int totalCurrentOutstandingPayablePaise;
  final int totalCurrentAdvanceCreditPaise;
  final List<LabourEntryView> labourEntries;
  final List<WorkerFinancialSummary> workerSummaries;
  final List<PaymentView> payments;
}

/// Single bar point for Production & Labour Trend charts (Category 6).
final class ProductionTrendPoint {
  const ProductionTrendPoint({
    required this.bucketKey,
    required this.label,
    required this.issuedQty,
    required this.goodReturnedQty,
    required this.damagedLostQty,
    required this.labourCostPaise,
  });

  final String bucketKey;
  final String label;
  final int issuedQty;
  final int goodReturnedQty;
  final int damagedLostQty;
  final int labourCostPaise;
}

/// Period-over-period comparison for an integer metric (zero-division safe).
final class PeriodComparisonMetric {
  const PeriodComparisonMetric({
    required this.currentValue,
    required this.previousValue,
    required this.delta,
    required this.percentChange,
  });

  final int currentValue;
  final int previousValue;
  final int delta;

  /// `null` when [previousValue] == 0 so UI displays "No prior data" cleanly.
  final double? percentChange;
}

/// Period-over-period comparison summary across 4 key workshop metrics.
final class PeriodComparisonSummary {
  const PeriodComparisonSummary({
    required this.previousFromUtcMillis,
    required this.previousToUtcMillis,
    required this.issuedQty,
    required this.goodReturnedQty,
    required this.labourCostPaise,
    required this.currentDefectRatePercent,
    required this.previousDefectRatePercent,
  });

  final int previousFromUtcMillis;
  final int previousToUtcMillis;
  final PeriodComparisonMetric issuedQty;
  final PeriodComparisonMetric goodReturnedQty;
  final PeriodComparisonMetric labourCostPaise;
  final double? currentDefectRatePercent;
  final double? previousDefectRatePercent;
}

/// Ranked process bottleneck derived from live open issues.
final class ProcessBottleneckItem {
  const ProcessBottleneckItem({
    required this.processId,
    required this.processName,
    required this.currentPendingQty,
    required this.openIssuesCount,
    required this.oldestOpenIssueAgeDays,
    required this.periodCompletedQty,
    required this.pendingToCompletedRatio,
  });

  final String processId;
  final String processName;
  final int currentPendingQty;
  final int openIssuesCount;
  final int oldestOpenIssueAgeDays;
  final int periodCompletedQty;

  /// `null` if [periodCompletedQty] == 0.
  final double? pendingToCompletedRatio;
}

/// Worker productivity contributor with period-over-period change.
final class WorkerProductivityTrendItem {
  const WorkerProductivityTrendItem({
    required this.workerId,
    required this.workerName,
    required this.currentGoodReturnedQty,
    required this.previousGoodReturnedQty,
    required this.percentChange,
    required this.defectRatePercent,
  });

  final String workerId;
  final String workerName;
  final int currentGoodReturnedQty;
  final int previousGoodReturnedQty;
  final double? percentChange;
  final double? defectRatePercent;
}

/// Aggregated defect/loss reason count from `stock_movements.reason`.
final class DefectReasonStat {
  const DefectReasonStat({
    required this.reason,
    required this.quantity,
    required this.occurrences,
  });

  final String reason;
  final int quantity;
  final int occurrences;
}

/// Process-wise share of period labour cost (explicitly labour cost, never revenue/profit).
final class ProcessLabourCostShare {
  const ProcessLabourCostShare({
    required this.processId,
    required this.processName,
    required this.labourCostPaise,
    required this.sharePercent,
  });

  final String processId;
  final String processName;
  final int labourCostPaise;
  final double sharePercent;
}

/// Category 6: Actionable, non-speculative Business Insights bundle.
final class BusinessInsightsBundle {
  const BusinessInsightsBundle({
    required this.trendPoints,
    required this.isWeeklyBuckets,
    required this.periodComparison,
    required this.bottlenecks,
    required this.workerTrends,
    required this.overallDefectRatePercent,
    required this.totalPeriodDefectsQty,
    required this.topDefectReasons,
    required this.processLabourCostShares,
    required this.totalPeriodLabourCostPaise,
  });

  final List<ProductionTrendPoint> trendPoints;
  final bool isWeeklyBuckets;
  final PeriodComparisonSummary? periodComparison;
  final List<ProcessBottleneckItem> bottlenecks;
  final List<WorkerProductivityTrendItem> workerTrends;
  final double? overallDefectRatePercent;
  final int totalPeriodDefectsQty;
  final List<DefectReasonStat> topDefectReasons;
  final List<ProcessLabourCostShare> processLabourCostShares;
  final int totalPeriodLabourCostPaise;
}

/// Complete single-pass StitchFlow V1.2 Advanced Reports & Insights bundle.
final class AdvancedReportsBundle {
  const AdvancedReportsBundle({
    required this.filter,
    required this.filterOptions,
    required this.businessNameEn,
    required this.businessNameGu,
    required this.generatedAtUtcMillis,
    required this.dailyRows,
    required this.dailyTotalIssued,
    required this.dailyTotalGoodReturned,
    required this.dailyTotalDamaged,
    required this.dailyTotalLostShortage,
    required this.dailyTotalLabourPaise,
    required this.dailyTotalNetPaymentsPaise,
    required this.currentTotalPendingQty,
    required this.workerPerformance,
    required this.processPerformance,
    required this.inventory,
    required this.financial,
    required this.insights,
    this.currentTotalPendingInspectionQty = 0,
    this.productionHistoryRows = const [],
    this.pendingInspectionReturns = const [],
    this.rejectionRecords = const [],
    this.partySummaries = const [],
    this.lotProfitLossRows = const [],
    this.cashbookSummary,
    this.trueNetProfit,
  });

  final ReportFilter filter;
  final ReportFilterOptions filterOptions;
  final String businessNameEn;
  final String businessNameGu;
  final int generatedAtUtcMillis;
  final List<DailyReportRow> dailyRows;
  final int dailyTotalIssued;
  final int dailyTotalGoodReturned;
  final int dailyTotalDamaged;
  final int dailyTotalLostShortage;
  final int dailyTotalLabourPaise;
  final int dailyTotalNetPaymentsPaise;
  final int currentTotalPendingQty;
  final int currentTotalPendingInspectionQty;
  final List<WorkerPerformanceRow> workerPerformance;
  final List<ProcessPerformanceRow> processPerformance;
  final InventoryReportSection inventory;
  final FinancialReportSection financial;
  final BusinessInsightsBundle insights;
  final List<AssignmentReconciliationSummary> productionHistoryRows;
  final List<PendingReturnView> pendingInspectionReturns;
  final List<RejectionRecordView> rejectionRecords;
  final List<PartyFinancialSummary> partySummaries;
  final List<LotProfitLossSummary> lotProfitLossRows;
  final CashbookSummary? cashbookSummary;
  final TrueWorkshopNetProfitSummary? trueNetProfit;

  AdvancedReportsBundle copyWithPartiesAndPnl({
    List<PartyFinancialSummary>? partySummaries,
    List<LotProfitLossSummary>? lotProfitLossRows,
    CashbookSummary? cashbookSummary,
    TrueWorkshopNetProfitSummary? trueNetProfit,
  }) => AdvancedReportsBundle(
    filter: filter,
    filterOptions: filterOptions,
    businessNameEn: businessNameEn,
    businessNameGu: businessNameGu,
    generatedAtUtcMillis: generatedAtUtcMillis,
    dailyRows: dailyRows,
    dailyTotalIssued: dailyTotalIssued,
    dailyTotalGoodReturned: dailyTotalGoodReturned,
    dailyTotalDamaged: dailyTotalDamaged,
    dailyTotalLostShortage: dailyTotalLostShortage,
    dailyTotalLabourPaise: dailyTotalLabourPaise,
    dailyTotalNetPaymentsPaise: dailyTotalNetPaymentsPaise,
    currentTotalPendingQty: currentTotalPendingQty,
    currentTotalPendingInspectionQty: currentTotalPendingInspectionQty,
    workerPerformance: workerPerformance,
    processPerformance: processPerformance,
    inventory: inventory,
    financial: financial,
    insights: insights,
    productionHistoryRows: productionHistoryRows,
    pendingInspectionReturns: pendingInspectionReturns,
    rejectionRecords: rejectionRecords,
    partySummaries: partySummaries ?? this.partySummaries,
    lotProfitLossRows: lotProfitLossRows ?? this.lotProfitLossRows,
    cashbookSummary: cashbookSummary ?? this.cashbookSummary,
    trueNetProfit: trueNetProfit ?? this.trueNetProfit,
  );
}
