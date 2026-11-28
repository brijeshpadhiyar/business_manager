import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';

/// Recent activity entry derived from `audit_logs` for the live Dashboard.
final class RecentActivityItem {
  const RecentActivityItem({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.actionType,
    this.actor,
    this.reason,
    required this.transactionAt,
    required this.recordedAt,
  });

  final String id;
  final String entityType;
  final String entityId;
  final String actionType;
  final String? actor;
  final String? reason;
  final int transactionAt;
  final int recordedAt;
}

/// Live database-backed dashboard snapshot (zero hardcoded or misleading metrics).
final class DashboardSnapshot {
  const DashboardSnapshot({
    required this.businessNameEn,
    required this.businessNameGu,
    required this.totalLots,
    required this.totalDesigns,
    required this.totalColours,
    required this.activeProcessesCount,
    required this.activeWorkersCount,
    required this.totalInitialStock,
    required this.availableGoodStock,
    required this.damagedStock,
    required this.pendingWorkerStock,
    required this.lostStock,
    required this.shortageStock,
    required this.processPendingList,
    required this.totalEarnedLabourPaise,
    required this.totalAdjustmentNetPaise,
    required this.totalRegularPaymentsPaise,
    required this.totalAdvancePaymentsPaise,
    required this.totalAdvanceRefundsPaise,
    required this.totalOutstandingPayablePaise,
    required this.totalAdvanceCreditPaise,
    required this.recentActivity,
    this.todayIstDate = '',
    this.todayIssuedQty = 0,
    this.todayReceivedGoodQty = 0,
    this.todayDamagedQty = 0,
    this.todayLostShortageQty = 0,
    this.todayLabourEarnedPaise = 0,
    this.todayPaymentsPaise = 0,
    this.importantPendingIssues = const [],
    this.pendingInspectionStock = 0,
    this.dispatchedStock = 0,
    this.totalPartyReceivablePaise = 0,
    this.totalPartyAdvanceCreditPaise = 0,
    this.cashBalancePaise = 0,
    this.bankBalancePaise = 0,
    this.todayExpensesPaise = 0,
    this.unpaidBillsPaise = 0,
  });

  final String businessNameEn;
  final String businessNameGu;
  final int totalLots;
  final int totalDesigns;
  final int totalColours;
  final int activeProcessesCount;
  final int activeWorkersCount;
  final int totalInitialStock;
  final int availableGoodStock;
  final int damagedStock;
  final int pendingWorkerStock;
  final int lostStock;
  final int shortageStock;
  final List<ProcessStockSummary> processPendingList;
  final int totalEarnedLabourPaise;
  final int totalAdjustmentNetPaise;
  final int totalRegularPaymentsPaise;
  final int totalAdvancePaymentsPaise;
  final int totalAdvanceRefundsPaise;
  final int totalOutstandingPayablePaise;
  final int totalAdvanceCreditPaise;
  final List<RecentActivityItem> recentActivity;
  final String todayIstDate;
  final int todayIssuedQty;
  final int todayReceivedGoodQty;
  final int todayDamagedQty;
  final int todayLostShortageQty;
  final int todayLabourEarnedPaise;
  final int todayPaymentsPaise;
  final List<OpenIssueSummary> importantPendingIssues;

  /// Pieces returned and waiting for QC. Golden rule:
  /// initial = available + withWorkers + pendingInspection + damaged + lost + shortage + dispatched.
  final int pendingInspectionStock;
  final int dispatchedStock;
  final int totalPartyReceivablePaise;
  final int totalPartyAdvanceCreditPaise;
  final int cashBalancePaise;
  final int bankBalancePaise;
  final int todayExpensesPaise;
  final int unpaidBillsPaise;
}

/// Per-process activity totals for a single IST business day.
final class DailyProcessActivity {
  const DailyProcessActivity({
    required this.processId,
    required this.processName,
    required this.issuedQty,
    required this.goodReturnedQty,
    required this.damagedQty,
    required this.lostShortageQty,
  });

  final String processId;
  final String processName;
  final int issuedQty;
  final int goodReturnedQty;
  final int damagedQty;
  final int lostShortageQty;
}

/// Per-worker activity totals for a single IST business day.
final class DailyWorkerActivity {
  const DailyWorkerActivity({
    required this.workerId,
    required this.workerName,
    required this.issuedQty,
    required this.goodReturnedQty,
    required this.damagedQty,
    required this.lostShortageQty,
    required this.labourEarnedPaise,
    required this.paymentsPaidPaise,
  });

  final String workerId;
  final String workerName;
  final int issuedQty;
  final int goodReturnedQty;
  final int damagedQty;
  final int lostShortageQty;
  final int labourEarnedPaise;
  final int paymentsPaidPaise;
}

/// Complete IST daily workshop production & financial recap (`/daily-summary`).
final class DailyWorkshopSummary {
  const DailyWorkshopSummary({
    required this.istDateIso,
    required this.dayStartUtcMillis,
    required this.dayEndUtcMillis,
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
    required this.currentTotalPendingQty,
    required this.currentTotalDamagedQty,
    required this.currentTotalOutstandingPayablePaise,
    required this.processActivities,
    required this.workerActivities,
  });

  final String istDateIso;
  final int dayStartUtcMillis;
  final int dayEndUtcMillis;
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
  final int currentTotalPendingQty;
  final int currentTotalDamagedQty;
  final int currentTotalOutstandingPayablePaise;
  final List<DailyProcessActivity> processActivities;
  final List<DailyWorkerActivity> workerActivities;

  int get lostAndShortageQty => lostQty + shortageQty;
  bool get hasAnyActivity =>
      issuedQty > 0 ||
      goodReturnedQty > 0 ||
      damagedQty > 0 ||
      lostQty > 0 ||
      shortageQty > 0 ||
      repairedQty > 0 ||
      labourEarnedPaise > 0 ||
      regularPaymentsPaise > 0 ||
      advancePaymentsPaise > 0 ||
      advanceRefundsPaise > 0;
}

/// Lot-wise stock report row.
final class LotStockReportRow {
  const LotStockReportRow({
    required this.lotId,
    required this.lotNumber,
    this.title,
    required this.status,
    required this.designCount,
    required this.colourCount,
    required this.initialQuantity,
    required this.availableGoodStock,
    required this.pendingWithWorkers,
    required this.damagedBucket,
    required this.lostQuantity,
    required this.shortageQuantity,
    required this.goodStockValuePaise,
    this.pendingInspection = 0,
  });

  final String lotId;
  final String lotNumber;
  final String? title;
  final LotStatus status;
  final int designCount;
  final int colourCount;
  final int initialQuantity;
  final int availableGoodStock;
  final int pendingWithWorkers;
  final int damagedBucket;
  final int lostQuantity;
  final int shortageQuantity;
  final int goodStockValuePaise;

  /// Pieces returned by workers and waiting for QC (not with workers, not in
  /// available stock).
  final int pendingInspection;
}

/// Comprehensive reports bundle filtered by date/search/lot/worker/process.
final class BusinessReportsBundle {
  const BusinessReportsBundle({
    required this.lotRows,
    required this.colourBalances,
    required this.workerStockRows,
    required this.processStockRows,
    required this.openIssues,
    required this.damagedLostShortageMovements,
    required this.labourEntries,
    required this.workerFinancialSummaries,
    required this.payments,
  });

  final List<LotStockReportRow> lotRows;
  final List<DesignColourStockBalance> colourBalances;
  final List<WorkerStockSummary> workerStockRows;
  final List<ProcessStockSummary> processStockRows;
  final List<OpenIssueSummary> openIssues;
  final List<StockMovementView> damagedLostShortageMovements;
  final List<LabourEntryView> labourEntries;
  final List<WorkerFinancialSummary> workerFinancialSummaries;
  final List<PaymentView> payments;
}
