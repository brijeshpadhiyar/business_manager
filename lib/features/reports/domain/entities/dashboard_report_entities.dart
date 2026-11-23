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
