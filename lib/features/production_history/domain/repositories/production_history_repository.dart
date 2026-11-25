import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';

/// Filter option item for Production History screens (includes inactive
/// workers and processes so historical records remain accessible).
final class HistoryFilterOption {
  const HistoryFilterOption({
    required this.id,
    required this.label,
    required this.isActive,
  });

  final String id;
  final String label;
  final bool isActive;
}

final class ProductionHistoryFilterOptions {
  const ProductionHistoryFilterOptions({
    this.lots = const [],
    this.workers = const [],
    this.processes = const [],
    this.designNames = const [],
    this.colourNames = const [],
  });

  final List<HistoryFilterOption> lots;
  final List<HistoryFilterOption> workers;
  final List<HistoryFilterOption> processes;
  final List<String> designNames;
  final List<String> colourNames;
}

/// Result of recording a return (either `PENDING_INSPECTION` or
/// `IMMEDIATE_INSPECTION`).
final class ProductionReturnResult {
  const ProductionReturnResult({
    required this.productionReturn,
    this.immediateInspection,
    required this.remainingOutstandingQty,
    required this.remainingPendingInspectionQty,
    required this.wasIdempotentReplay,
  });

  final ProductionReturnEntity productionReturn;
  final ProductionInspectionEntity? immediateInspection;
  final int remainingOutstandingQty;
  final int remainingPendingInspectionQty;
  final bool wasIdempotentReplay;
}

/// Result of approving / rejecting a pending inspection or repair reinspection.
final class InspectionApprovalResult {
  const InspectionApprovalResult({
    required this.inspection,
    this.createdRejection,
    required this.earnedAmountPaise,
    required this.wasIdempotentReplay,
  });

  final ProductionInspectionEntity inspection;
  final RejectionRecordEntity? createdRejection;
  final int earnedAmountPaise;
  final bool wasIdempotentReplay;
}

abstract interface class ProductionHistoryRepository {
  /// Records a worker production return against an `ISSUE` assignment.
  ///
  /// When [inspectImmediately] is `false`, logs pieces into `Pending Inspection`
  /// with ₹0 worker earnings until QC inspects. When `true`, records the return
  /// AND atomically performs an initial QC inspection splitting into accepted
  /// (earns `accepted * lockedRate`) and rejected (₹0 + `RejectionRecord`),
  /// leaving any uninspected remainder in `Pending Inspection`.
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
  });

  /// Approves and/or rejects quantities on an existing pending return.
  /// Generates worker earnings strictly for `acceptedQuantity * lockedRatePaise`.
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
  });

  /// Records a repair operation against a specific [RejectionRecordEntity].
  Future<RejectionRepairEntity> recordRejectionRepair({
    required String rejectionRecordId,
    required int repairedQuantity,
    required RepairSource repairSource,
    required int transactionAtUtcMillis,
    String? repairedBy,
    String? notes,
    String? clientRequestId,
  });

  /// Re-inspects repaired pieces and generates earnings ONLY for newly
  /// accepted pieces when `repairSource == RepairSource.originalWorker`.
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
  });

  Future<ProductionHistoryDashboardData> getDashboard({
    ProductionHistoryFilter filter = const ProductionHistoryFilter(),
  });

  Future<LotCompleteHistory?> getLotCompleteHistory(String lotId);

  Future<List<LotTimelineEvent>> getLotTimeline(String lotId);

  Future<WorkerCompleteProfile?> getWorkerCompleteProfile(
    String workerId, {
    ProductionHistoryFilter? filter,
  });

  Future<List<WorkerCompleteProfile>> getAllWorkerProfiles({
    ProductionHistoryFilter? filter,
  });

  Future<List<ProcessCompleteHistory>> getAllProcessHistories({
    ProductionHistoryFilter? filter,
  });

  Future<ProcessCompleteHistory?> getProcessCompleteHistory(
    String processId, {
    ProductionHistoryFilter? filter,
  });

  Future<List<PendingReturnView>> getPendingReturns({
    String? lotId,
    String? workerId,
    String? processId,
  });

  Future<List<RejectionRecordView>> getRejectionRecords({
    String? lotId,
    String? workerId,
    String? processId,
    bool onlyOpen = false,
  });

  Future<ProductionTransactionDetail?> getTransactionDetail({
    required ProductionTransactionKind kind,
    required String id,
  });

  Future<ProductionHistoryFilterOptions> getFilterOptions();
}
