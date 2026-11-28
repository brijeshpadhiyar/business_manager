import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';

enum ProductionReturnMode {
  pendingInspection('PENDING_INSPECTION'),
  immediateInspection('IMMEDIATE_INSPECTION');

  const ProductionReturnMode(this.dbValue);
  final String dbValue;

  static ProductionReturnMode fromDbValue(String value) =>
      ProductionReturnMode.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => ProductionReturnMode.pendingInspection,
      );
}

enum ProductionInspectionType {
  initial('INITIAL'),
  reinspection('REINSPECTION');

  const ProductionInspectionType(this.dbValue);
  final String dbValue;

  static ProductionInspectionType fromDbValue(String value) =>
      ProductionInspectionType.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => ProductionInspectionType.initial,
      );
}

enum RejectionStatus {
  open('OPEN'),
  partiallyRepaired('PARTIALLY_REPAIRED'),
  repairedPendingInspection('REPAIRED_PENDING_INSPECTION'),
  partiallyReapproved('PARTIALLY_REAPPROVED'),
  reapproved('REAPPROVED'),
  scrapped('SCRAPPED');

  const RejectionStatus(this.dbValue);
  final String dbValue;

  bool get isClosed => this == reapproved || this == scrapped;

  static RejectionStatus fromDbValue(String value) =>
      RejectionStatus.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => RejectionStatus.open,
      );
}

enum RepairSource {
  originalWorker('ORIGINAL_WORKER'),
  inHouse('IN_HOUSE');

  const RepairSource(this.dbValue);
  final String dbValue;

  static RepairSource fromDbValue(String value) =>
      RepairSource.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => RepairSource.originalWorker,
      );
}

enum RepairStatus {
  pendingReinspection('PENDING_REINSPECTION'),
  partiallyReinspected('PARTIALLY_REINSPECTED'),
  completed('COMPLETED');

  const RepairStatus(this.dbValue);
  final String dbValue;

  static RepairStatus fromDbValue(String value) =>
      RepairStatus.values.firstWhere(
        (e) => e.dbValue == value,
        orElse: () => RepairStatus.pendingReinspection,
      );
}

final class ProductionReturnEntity {
  const ProductionReturnEntity({
    required this.id,
    this.clientRequestId,
    required this.parentIssueId,
    this.jobProcessId,
    required this.lotId,
    required this.lotDesignId,
    required this.designColourId,
    required this.processId,
    required this.memberId,
    required this.returnedQuantity,
    required this.returnMode,
    this.notes,
    required this.transactionAt,
    required this.recordedAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? clientRequestId;
  final String parentIssueId;
  final String? jobProcessId;
  final String lotId;
  final String lotDesignId;
  final String designColourId;
  final String processId;
  final String memberId;
  final int returnedQuantity;
  final ProductionReturnMode returnMode;
  final String? notes;
  final int transactionAt;
  final int recordedAt;
  final String? createdBy;
  final int createdAt;
  final int updatedAt;
}

final class ProductionInspectionEntity {
  const ProductionInspectionEntity({
    required this.id,
    this.clientRequestId,
    required this.inspectionType,
    this.productionReturnId,
    this.rejectionRecordId,
    this.rejectionRepairId,
    required this.parentIssueId,
    this.jobProcessId,
    required this.lotId,
    required this.lotDesignId,
    required this.designColourId,
    required this.processId,
    required this.memberId,
    required this.acceptedQuantity,
    required this.rejectedQuantity,
    required this.lockedRatePaise,
    required this.earnedAmountPaise,
    required this.creditWorkerEarnings,
    this.linkedGoodMovementId,
    this.linkedDamagedMovementId,
    this.linkedLabourEntryId,
    this.rejectionReason,
    this.notes,
    this.inspectedBy,
    this.approvedBy,
    required this.authorizedViaPin,
    required this.transactionAt,
    required this.recordedAt,
    required this.createdAt,
  });

  final String id;
  final String? clientRequestId;
  final ProductionInspectionType inspectionType;
  final String? productionReturnId;
  final String? rejectionRecordId;
  final String? rejectionRepairId;
  final String parentIssueId;
  final String? jobProcessId;
  final String lotId;
  final String lotDesignId;
  final String designColourId;
  final String processId;
  final String memberId;
  final int acceptedQuantity;
  final int rejectedQuantity;
  final int lockedRatePaise;
  final int earnedAmountPaise;
  final bool creditWorkerEarnings;
  final String? linkedGoodMovementId;
  final String? linkedDamagedMovementId;
  final String? linkedLabourEntryId;
  final String? rejectionReason;
  final String? notes;
  final String? inspectedBy;
  final String? approvedBy;
  final bool authorizedViaPin;
  final int transactionAt;
  final int recordedAt;
  final int createdAt;

  int get totalInspectedQuantity => acceptedQuantity + rejectedQuantity;
}

final class RejectionRecordEntity {
  const RejectionRecordEntity({
    required this.id,
    required this.lotId,
    required this.lotDesignId,
    required this.designColourId,
    required this.processId,
    required this.memberId,
    required this.parentIssueId,
    this.jobProcessId,
    this.productionReturnId,
    required this.inspectionId,
    required this.stockMovementId,
    required this.rejectedQuantity,
    required this.rejectionReason,
    required this.status,
    required this.inspectedAt,
    this.recordedBy,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String lotId;
  final String lotDesignId;
  final String designColourId;
  final String processId;
  final String memberId;
  final String parentIssueId;
  final String? jobProcessId;
  final String? productionReturnId;
  final String inspectionId;
  final String stockMovementId;
  final int rejectedQuantity;
  final String rejectionReason;
  final RejectionStatus status;
  final int inspectedAt;
  final String? recordedBy;
  final String? notes;
  final int createdAt;
  final int updatedAt;
}

final class RejectionRepairEntity {
  const RejectionRepairEntity({
    required this.id,
    this.clientRequestId,
    required this.rejectionRecordId,
    required this.lotId,
    required this.designColourId,
    required this.processId,
    required this.memberId,
    required this.repairedQuantity,
    required this.repairSource,
    required this.status,
    this.repairedBy,
    this.notes,
    required this.transactionAt,
    required this.recordedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String? clientRequestId;
  final String rejectionRecordId;
  final String lotId;
  final String designColourId;
  final String processId;
  final String memberId;
  final int repairedQuantity;
  final RepairSource repairSource;
  final RepairStatus status;
  final String? repairedBy;
  final String? notes;
  final int transactionAt;
  final int recordedAt;
  final int createdAt;
  final int updatedAt;
}

/// Enriched pending return waiting for QC inspection approval/rejection.
final class PendingReturnView {
  const PendingReturnView({
    required this.productionReturn,
    required this.lotNumber,
    required this.designName,
    required this.colourName,
    this.colourHex,
    required this.processName,
    required this.workerName,
    required this.lockedRatePaise,
    required this.inspectedAcceptedQty,
    required this.inspectedRejectedQty,
    required this.remainingPendingInspectionQty,
  });

  final ProductionReturnEntity productionReturn;
  final String lotNumber;
  final String designName;
  final String colourName;
  final String? colourHex;
  final String processName;
  final String workerName;
  final int lockedRatePaise;
  final int inspectedAcceptedQty;
  final int inspectedRejectedQty;
  final int remainingPendingInspectionQty;
}

/// Enriched repair entry with reinspection reconciliation.
final class RejectionRepairView {
  const RejectionRepairView({
    required this.repair,
    required this.reapprovedQty,
    required this.rejectedAgainQty,
    required this.pendingReinspectionQty,
  });

  final RejectionRepairEntity repair;
  final int reapprovedQty;
  final int rejectedAgainQty;
  final int pendingReinspectionQty;
}

/// Enriched rejection record with full repair and re-approval breakdown.
final class RejectionRecordView {
  const RejectionRecordView({
    required this.record,
    required this.lotNumber,
    required this.designName,
    required this.colourName,
    this.colourHex,
    required this.processName,
    required this.workerName,
    required this.lockedRatePaise,
    required this.totalRepairedSubmittedQty,
    required this.totalReapprovedQty,
    required this.pendingReinspectionQty,
    required this.openUnrepairedQty,
    required this.repairs,
  });

  final RejectionRecordEntity record;
  final String lotNumber;
  final String designName;
  final String colourName;
  final String? colourHex;
  final String processName;
  final String workerName;
  final int lockedRatePaise;
  final int totalRepairedSubmittedQty;
  final int totalReapprovedQty;
  final int pendingReinspectionQty;
  final int openUnrepairedQty;
  final List<RejectionRepairView> repairs;

  int get netRejectedQty => record.rejectedQuantity - totalReapprovedQty;
}

/// Reconciled assignment summary derived strictly from immutable transaction
/// tables (Single Source of Truth).
final class AssignmentReconciliationSummary {
  const AssignmentReconciliationSummary({
    required this.issueMovementId,
    this.jobProcessId,
    required this.lotId,
    required this.lotNumber,
    required this.lotDesignId,
    required this.designName,
    required this.designColourId,
    required this.colourName,
    this.colourHex,
    required this.processId,
    required this.processName,
    required this.processIsActive,
    required this.workerId,
    required this.workerName,
    required this.workerIsActive,
    required this.assignedAt,
    this.completedAt,
    required this.assignedQty,
    required this.returnedQty,
    required this.acceptedInitialQty,
    required this.reapprovedQty,
    required this.rejectedInitialQty,
    required this.pendingInspectionQty,
    required this.pendingReinspectionQty,
    required this.lostQty,
    required this.shortageQty,
    required this.outstandingQty,
    required this.lockedRatePaise,
    required this.earnedAmountPaise,
    required this.isRateOverridden,
    this.overrideReason,
    this.notes,
    this.createdBy,
  });

  final String issueMovementId;
  final String? jobProcessId;
  final String lotId;
  final String lotNumber;
  final String lotDesignId;
  final String designName;
  final String designColourId;
  final String colourName;
  final String? colourHex;
  final String processId;
  final String processName;
  final bool processIsActive;
  final String workerId;
  final String workerName;
  final bool workerIsActive;
  final int assignedAt;
  final int? completedAt;
  final int assignedQty;
  final int returnedQty;
  final int acceptedInitialQty;
  final int reapprovedQty;
  final int rejectedInitialQty;
  final int pendingInspectionQty;
  final int pendingReinspectionQty;
  final int lostQty;
  final int shortageQty;
  final int outstandingQty;
  final int lockedRatePaise;
  final int earnedAmountPaise;
  final bool isRateOverridden;
  final String? overrideReason;
  final String? notes;
  final String? createdBy;

  int get totalAcceptedQty => acceptedInitialQty + reapprovedQty;
  int get netRejectedQty =>
      (rejectedInitialQty - reapprovedQty).clamp(0, rejectedInitialQty);
  bool get isCompleted =>
      outstandingQty == 0 &&
      pendingInspectionQty == 0 &&
      pendingReinspectionQty == 0;
}

enum LotTimelineEventKind {
  lotCreated,
  processAssigned,
  stockIssued,
  handoverTransfer,
  stockReturned,
  inspectionApproved,
  inspectionRejected,
  rejectionRepaired,
  repairReapproved,
  settlementLost,
  settlementShortage,
  movementReversed,
  lotCompleted,
}

enum ProductionTransactionKind {
  stockMovement('stock_movement'),
  productionReturn('production_return'),
  inspection('inspection'),
  rejection('rejection'),
  repair('repair'),
  handover('handover'),
  labourEntry('labour_entry'),
  payment('payment'),
  adjustment('adjustment');

  const ProductionTransactionKind(this.routeSegment);
  final String routeSegment;

  static ProductionTransactionKind fromRouteSegment(String value) =>
      ProductionTransactionKind.values.firstWhere(
        (e) => e.routeSegment == value,
        orElse: () => ProductionTransactionKind.stockMovement,
      );
}

final class LotTimelineEvent {
  const LotTimelineEvent({
    required this.id,
    required this.kind,
    required this.timestampUtcMillis,
    required this.recordedAtUtcMillis,
    required this.title,
    this.subtitle,
    this.traceCode,
    this.traceArgs = const <String, Object?>{},
    this.quantity,
    this.amountPaise,
    this.ratePaise,
    required this.lotId,
    required this.lotNumber,
    this.designName,
    this.colourName,
    this.processId,
    this.processName,
    this.workerId,
    this.workerName,
    this.actor,
    this.reason,
    this.notes,
    required this.transactionKind,
    required this.transactionId,
  });

  final String id;
  final LotTimelineEventKind kind;
  final int timestampUtcMillis;
  final int recordedAtUtcMillis;
  final String title;
  final String? subtitle;
  final String? traceCode;
  final Map<String, Object?> traceArgs;
  final int? quantity;
  final int? amountPaise;
  final int? ratePaise;
  final String lotId;
  final String lotNumber;
  final String? designName;
  final String? colourName;
  final String? processId;
  final String? processName;
  final String? workerId;
  final String? workerName;
  final String? actor;
  final String? reason;
  final String? notes;
  final ProductionTransactionKind transactionKind;
  final String transactionId;
}

final class LotColourHistorySummary {
  const LotColourHistorySummary({
    required this.designColourId,
    required this.designName,
    required this.colourName,
    this.colourHex,
    required this.initialQuantity,
    required this.availableInHouse,
    required this.outstandingWithWorkers,
    required this.pendingInspection,
    required this.damagedBucket,
    required this.lostQty,
    required this.shortageQty,
  });

  final String designColourId;
  final String designName;
  final String colourName;
  final String? colourHex;
  final int initialQuantity;
  final int availableInHouse;
  final int outstandingWithWorkers;
  final int pendingInspection;
  final int damagedBucket;
  final int lostQty;
  final int shortageQty;
}

final class LotCompleteHistory {
  const LotCompleteHistory({
    required this.lot,
    this.createdBy,
    this.updatedBy,
    required this.colourSummaries,
    required this.totalInitialQty,
    required this.totalAssignedQty,
    required this.totalReturnedQty,
    required this.totalAcceptedQty,
    required this.totalRejectedQty,
    required this.totalPendingInspectionQty,
    required this.totalPendingReinspectionQty,
    required this.totalOutstandingQty,
    required this.totalLostShortageQty,
    required this.totalProductionCostPaise,
    required this.assignments,
    required this.timeline,
    required this.rejections,
    required this.pendingReturns,
  });

  final LotEntity lot;
  final String? createdBy;
  final String? updatedBy;
  final List<LotColourHistorySummary> colourSummaries;
  final int totalInitialQty;
  final int totalAssignedQty;
  final int totalReturnedQty;
  final int totalAcceptedQty;
  final int totalRejectedQty;
  final int totalPendingInspectionQty;
  final int totalPendingReinspectionQty;
  final int totalOutstandingQty;
  final int totalLostShortageQty;
  final int totalProductionCostPaise;
  final List<AssignmentReconciliationSummary> assignments;
  final List<LotTimelineEvent> timeline;
  final List<RejectionRecordView> rejections;
  final List<PendingReturnView> pendingReturns;

  bool get isFullyReconciled =>
      totalOutstandingQty == 0 &&
      totalPendingInspectionQty == 0 &&
      totalPendingReinspectionQty == 0;
}

final class WorkerProcessProductionSummary {
  const WorkerProcessProductionSummary({
    required this.processId,
    required this.processName,
    required this.processIsActive,
    required this.totalLots,
    required this.totalAssignments,
    required this.completedAssignments,
    required this.assignedQty,
    required this.returnedQty,
    required this.acceptedQty,
    required this.pendingInspectionQty,
    required this.outstandingQty,
    required this.rejectedQty,
    required this.earnedAmountPaise,
    required this.estimatedPendingPayablePaise,
  });

  final String processId;
  final String processName;
  final bool processIsActive;
  final int totalLots;
  final int totalAssignments;
  final int completedAssignments;
  final int assignedQty;
  final int returnedQty;
  final int acceptedQty;
  final int pendingInspectionQty;
  final int outstandingQty;
  final int rejectedQty;
  final int earnedAmountPaise;
  final int estimatedPendingPayablePaise;
}

final class WorkerCompleteProfile {
  const WorkerCompleteProfile({
    required this.workerId,
    required this.workerName,
    this.phone,
    this.address,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.totalLotsAssigned,
    required this.totalProcessesCompleted,
    required this.assignedQty,
    required this.returnedQty,
    required this.acceptedQty,
    required this.pendingInspectionQty,
    required this.outstandingQty,
    required this.rejectedQty,
    required this.financialSummary,
    required this.lotHistory,
    required this.processHistory,
    required this.rejections,
    required this.pendingReturns,
  });

  final String workerId;
  final String workerName;
  final String? phone;
  final String? address;
  final String? notes;
  final bool isActive;
  final int createdAt;
  final int totalLotsAssigned;
  final int totalProcessesCompleted;
  final int assignedQty;
  final int returnedQty;
  final int acceptedQty;
  final int pendingInspectionQty;
  final int outstandingQty;
  final int rejectedQty;
  final WorkerFinancialSummary financialSummary;
  final List<AssignmentReconciliationSummary> lotHistory;
  final List<WorkerProcessProductionSummary> processHistory;
  final List<RejectionRecordView> rejections;
  final List<PendingReturnView> pendingReturns;
}

final class ProcessDateHistoryRow {
  const ProcessDateHistoryRow({
    required this.istDateIso,
    required this.assignedQty,
    required this.returnedQty,
    required this.acceptedQty,
    required this.rejectedQty,
    required this.earnedPaise,
  });

  final String istDateIso;
  final int assignedQty;
  final int returnedQty;
  final int acceptedQty;
  final int rejectedQty;
  final int earnedPaise;
}

final class ProcessWorkerSummaryRow {
  const ProcessWorkerSummaryRow({
    required this.workerId,
    required this.workerName,
    required this.workerIsActive,
    required this.totalLots,
    required this.assignedQty,
    required this.returnedQty,
    required this.acceptedQty,
    required this.pendingInspectionQty,
    required this.outstandingQty,
    required this.rejectedQty,
    required this.earnedAmountPaise,
  });

  final String workerId;
  final String workerName;
  final bool workerIsActive;
  final int totalLots;
  final int assignedQty;
  final int returnedQty;
  final int acceptedQty;
  final int pendingInspectionQty;
  final int outstandingQty;
  final int rejectedQty;
  final int earnedAmountPaise;
}

final class ProcessLotSummaryRow {
  const ProcessLotSummaryRow({
    required this.lotId,
    required this.lotNumber,
    required this.assignedQty,
    required this.returnedQty,
    required this.acceptedQty,
    required this.pendingInspectionQty,
    required this.outstandingQty,
    required this.rejectedQty,
    required this.earnedAmountPaise,
  });

  final String lotId;
  final String lotNumber;
  final int assignedQty;
  final int returnedQty;
  final int acceptedQty;
  final int pendingInspectionQty;
  final int outstandingQty;
  final int rejectedQty;
  final int earnedAmountPaise;
}

final class ProcessCompleteHistory {
  const ProcessCompleteHistory({
    required this.processId,
    required this.processName,
    required this.isActive,
    required this.totalLots,
    required this.totalWorkersInvolved,
    required this.assignedQty,
    required this.returnedQty,
    required this.acceptedQty,
    required this.pendingInspectionQty,
    required this.outstandingQty,
    required this.rejectedQty,
    required this.completedQty,
    required this.totalProductionCostPaise,
    required this.estimatedPaidPaise,
    required this.estimatedOutstandingPaise,
    required this.lotHistory,
    required this.workerHistory,
    required this.dateHistory,
    required this.pendingAssignments,
    required this.allAssignments,
    required this.rejections,
  });

  final String processId;
  final String processName;
  final bool isActive;
  final int totalLots;
  final int totalWorkersInvolved;
  final int assignedQty;
  final int returnedQty;
  final int acceptedQty;
  final int pendingInspectionQty;
  final int outstandingQty;
  final int rejectedQty;
  final int completedQty;
  final int totalProductionCostPaise;
  final int estimatedPaidPaise;
  final int estimatedOutstandingPaise;
  final List<ProcessLotSummaryRow> lotHistory;
  final List<ProcessWorkerSummaryRow> workerHistory;
  final List<ProcessDateHistoryRow> dateHistory;
  final List<AssignmentReconciliationSummary> pendingAssignments;
  final List<AssignmentReconciliationSummary> allAssignments;
  final List<RejectionRecordView> rejections;
}

final class ProductionHistoryFilter {
  const ProductionHistoryFilter({
    this.fromUtcMillis,
    this.toUtcMillis,
    this.lotId,
    this.workerId,
    this.processId,
    this.designName,
    this.colourName,
    this.searchQuery,
    this.onlyPending = false,
    this.page = 0,
    this.pageSize = 30,
  });

  final int? fromUtcMillis;
  final int? toUtcMillis;
  final String? lotId;
  final String? workerId;
  final String? processId;
  final String? designName;
  final String? colourName;
  final String? searchQuery;
  final bool onlyPending;
  final int page;
  final int pageSize;

  ProductionHistoryFilter copyWith({
    int? fromUtcMillis,
    bool clearFrom = false,
    int? toUtcMillis,
    bool clearTo = false,
    String? lotId,
    bool clearLot = false,
    String? workerId,
    bool clearWorker = false,
    String? processId,
    bool clearProcess = false,
    String? designName,
    bool clearDesign = false,
    String? colourName,
    bool clearColour = false,
    String? searchQuery,
    bool? onlyPending,
    int? page,
    int? pageSize,
  }) {
    return ProductionHistoryFilter(
      fromUtcMillis: clearFrom ? null : (fromUtcMillis ?? this.fromUtcMillis),
      toUtcMillis: clearTo ? null : (toUtcMillis ?? this.toUtcMillis),
      lotId: clearLot ? null : (lotId ?? this.lotId),
      workerId: clearWorker ? null : (workerId ?? this.workerId),
      processId: clearProcess ? null : (processId ?? this.processId),
      designName: clearDesign ? null : (designName ?? this.designName),
      colourName: clearColour ? null : (colourName ?? this.colourName),
      searchQuery: searchQuery ?? this.searchQuery,
      onlyPending: onlyPending ?? this.onlyPending,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

final class ProductionHistoryFeedItem {
  const ProductionHistoryFeedItem({
    required this.id,
    required this.transactionKind,
    required this.transactionId,
    required this.title,
    required this.subtitle,
    required this.badgeLabel,
    this.traceCode,
    this.badgeCode,
    this.traceArgs = const <String, Object?>{},
    required this.isWarning,
    required this.isPositive,
    required this.timestampUtcMillis,
    required this.quantity,
    this.amountPaise,
    this.ratePaise,
    this.lotId,
    this.lotNumber,
    this.designName,
    this.colourName,
    this.processId,
    this.processName,
    this.workerId,
    this.workerName,
    this.actor,
    this.notes,
  });

  final String id;
  final ProductionTransactionKind transactionKind;
  final String transactionId;
  final String title;
  final String subtitle;
  final String badgeLabel;
  final String? traceCode;
  final String? badgeCode;
  final Map<String, Object?> traceArgs;
  final bool isWarning;
  final bool isPositive;
  final int timestampUtcMillis;
  final int quantity;
  final int? amountPaise;
  final int? ratePaise;
  final String? lotId;
  final String? lotNumber;
  final String? designName;
  final String? colourName;
  final String? processId;
  final String? processName;
  final String? workerId;
  final String? workerName;
  final String? actor;
  final String? notes;
}

final class ProductionHistoryDashboardData {
  const ProductionHistoryDashboardData({
    required this.totalLots,
    required this.totalAssignedQty,
    required this.totalReturnedQty,
    required this.totalAcceptedQty,
    required this.totalRejectedQty,
    required this.totalPendingInspectionQty,
    required this.totalOutstandingQty,
    required this.totalEarnedPaise,
    required this.totalPaidPaise,
    required this.totalOutstandingPayablePaise,
    required this.pendingReturnsCount,
    required this.openRejectionsCount,
    required this.items,
    required this.totalItemsCount,
    required this.page,
    required this.pageSize,
    required this.hasMore,
    required this.assignments,
  });

  final int totalLots;
  final int totalAssignedQty;
  final int totalReturnedQty;
  final int totalAcceptedQty;
  final int totalRejectedQty;
  final int totalPendingInspectionQty;
  final int totalOutstandingQty;
  final int totalEarnedPaise;
  final int totalPaidPaise;
  final int totalOutstandingPayablePaise;
  final int pendingReturnsCount;
  final int openRejectionsCount;
  final List<ProductionHistoryFeedItem> items;
  final int totalItemsCount;
  final int page;
  final int pageSize;
  final bool hasMore;
  final List<AssignmentReconciliationSummary> assignments;

  /// This data with [next]'s feed items added after the current ones, for
  /// infinite scrolling. Totals come from [next], the freshest read.
  ProductionHistoryDashboardData appendPage(
    ProductionHistoryDashboardData next,
  ) {
    return ProductionHistoryDashboardData(
      totalLots: next.totalLots,
      totalAssignedQty: next.totalAssignedQty,
      totalReturnedQty: next.totalReturnedQty,
      totalAcceptedQty: next.totalAcceptedQty,
      totalRejectedQty: next.totalRejectedQty,
      totalPendingInspectionQty: next.totalPendingInspectionQty,
      totalOutstandingQty: next.totalOutstandingQty,
      totalEarnedPaise: next.totalEarnedPaise,
      totalPaidPaise: next.totalPaidPaise,
      totalOutstandingPayablePaise: next.totalOutstandingPayablePaise,
      pendingReturnsCount: next.pendingReturnsCount,
      openRejectionsCount: next.openRejectionsCount,
      items: [...items, ...next.items],
      totalItemsCount: next.totalItemsCount,
      page: next.page,
      pageSize: next.pageSize,
      hasMore: next.hasMore,
      assignments: next.assignments,
    );
  }
}

final class ProductionAuditEntryView {
  const ProductionAuditEntryView({
    required this.id,
    required this.actionType,
    this.actor,
    this.reason,
    required this.recordedAt,
    this.newValueJson,
  });

  final String id;
  final String actionType;
  final String? actor;
  final String? reason;
  final int recordedAt;
  final String? newValueJson;
}

final class ProductionRelatedLink {
  const ProductionRelatedLink({
    required this.label,
    required this.kind,
    required this.id,
    this.code,
    this.args = const <String, Object?>{},
  });

  final String label;
  final ProductionTransactionKind kind;
  final String id;
  final String? code;
  final Map<String, Object?> args;
}

final class ProductionTransactionDetail {
  const ProductionTransactionDetail({
    required this.kind,
    required this.id,
    required this.title,
    required this.statusLabel,
    this.titleCode,
    this.statusCode,
    this.traceArgs = const <String, Object?>{},
    required this.transactionAt,
    required this.recordedAt,
    this.actor,
    this.approvedBy,
    this.authorizedViaPin = false,
    this.lotId,
    this.lotNumber,
    this.designName,
    this.colourName,
    this.processId,
    this.processName,
    this.workerId,
    this.workerName,
    this.quantity,
    this.acceptedQuantity,
    this.rejectedQuantity,
    this.lockedRatePaise,
    this.amountPaise,
    this.reason,
    this.notes,
    this.referenceNo,
    this.parentIssueId,
    this.relatedLinks = const [],
    this.auditTrail = const [],
  });

  final ProductionTransactionKind kind;
  final String id;
  final String title;
  final String statusLabel;
  final String? titleCode;
  final String? statusCode;
  final Map<String, Object?> traceArgs;
  final int transactionAt;
  final int recordedAt;
  final String? actor;
  final String? approvedBy;
  final bool authorizedViaPin;
  final String? lotId;
  final String? lotNumber;
  final String? designName;
  final String? colourName;
  final String? processId;
  final String? processName;
  final String? workerId;
  final String? workerName;
  final int? quantity;
  final int? acceptedQuantity;
  final int? rejectedQuantity;
  final int? lockedRatePaise;
  final int? amountPaise;
  final String? reason;
  final String? notes;
  final String? referenceNo;
  final String? parentIssueId;
  final List<ProductionRelatedLink> relatedLinks;
  final List<ProductionAuditEntryView> auditTrail;
}

/// Optional initial process assignment draft during Lot Creation (Phase 5).
final class InitialLotProcessAssignmentInput {
  const InitialLotProcessAssignmentInput({
    required this.designName,
    required this.colourName,
    required this.processId,
    required this.workerId,
    required this.quantity,
    required this.agreedRatePaise,
    this.pricingUnit = 'PER_PIECE',
    this.rateOverrideReason,
    this.notes,
  });

  final String designName;
  final String colourName;
  final String processId;
  final String workerId;
  final int quantity;
  final int agreedRatePaise;
  final String pricingUnit;
  final String? rateOverrideReason;
  final String? notes;
}

/// Pure input bundle for `ProductionHistoryCalculator` (zero Drift imports).
final class ProductionHistoryDataset {
  const ProductionHistoryDataset({
    required this.lots,
    required this.designs,
    required this.colours,
    required this.processes,
    required this.workers,
    required this.movements,
    required this.returns,
    required this.inspections,
    required this.rejections,
    required this.repairs,
    required this.labourEntries,
    required this.payments,
    required this.adjustments,
    required this.handovers,
  });

  final Map<String, ({LotEntity entity, String? createdBy, String? updatedBy})>
  lots;
  final Map<String, LotDesignEntity> designs;
  final Map<String, DesignColourEntity> colours;
  final Map<String, ({String name, bool isActive})> processes;
  final Map<
    String,
    ({
      String name,
      String? phone,
      String? address,
      String? notes,
      bool isActive,
      int createdAt,
    })
  >
  workers;
  final List<StockMovementEntity> movements;
  final List<ProductionReturnEntity> returns;
  final List<ProductionInspectionEntity> inspections;
  final List<RejectionRecordEntity> rejections;
  final List<RejectionRepairEntity> repairs;
  final List<LabourEntryEntity> labourEntries;
  final List<PaymentEntity> payments;
  final List<WorkerAdjustmentEntity> adjustments;
  final List<ProcessHandoverEntity> handovers;
}
