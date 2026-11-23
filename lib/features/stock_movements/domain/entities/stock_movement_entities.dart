import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';

/// Strict discriminator matching `stock_movements.movement_type` CHECK constraint.
enum StockMovementType {
  issue('ISSUE'),
  returnGood('RETURN_GOOD'),
  returnDamaged('RETURN_DAMAGED'),
  settlementLost('SETTLEMENT_LOST'),
  settlementShortage('SETTLEMENT_SHORTAGE'),
  adjustmentDamagedToGood('ADJUSTMENT_DAMAGED_TO_GOOD'),
  reversal('REVERSAL');

  const StockMovementType(this.dbValue);

  final String dbValue;

  bool get isSettlement =>
      this == returnGood ||
      this == returnDamaged ||
      this == settlementLost ||
      this == settlementShortage;

  bool get requiresReason =>
      this == returnDamaged ||
      this == settlementLost ||
      this == settlementShortage ||
      this == adjustmentDamagedToGood ||
      this == reversal;

  static StockMovementType fromDbValue(String value) {
    return StockMovementType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => throw ArgumentError('Unknown StockMovementType: $value'),
    );
  }
}

/// Immutable domain entity for a single row in `stock_movements`.
final class StockMovementEntity {
  const StockMovementEntity({
    required this.id,
    required this.lotId,
    required this.lotDesignId,
    required this.designColourId,
    this.processId,
    this.memberId,
    this.parentIssueId,
    this.reversesMovementId,
    this.clientRequestId,
    required this.movementType,
    required this.quantity,
    this.sourceRateId,
    required this.appliedRatePaise,
    required this.isRateOverridden,
    this.overrideReason,
    this.lockedBillingMode,
    required this.lockedIncludeDamaged,
    this.reason,
    this.notes,
    required this.transactionAt,
    required this.recordedAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String lotId;
  final String lotDesignId;
  final String designColourId;
  final String? processId;
  final String? memberId;
  final String? parentIssueId;
  final String? reversesMovementId;
  final String? clientRequestId;
  final StockMovementType movementType;
  final int quantity;
  final String? sourceRateId;
  final int appliedRatePaise;
  final bool isRateOverridden;
  final String? overrideReason;
  final BillingMode? lockedBillingMode;
  final bool lockedIncludeDamaged;
  final String? reason;
  final String? notes;
  final int transactionAt;
  final int recordedAt;
  final String? createdBy;
  final int createdAt;
  final int updatedAt;
}

/// Enriched stock movement view for UI lists, timelines, and details.
final class StockMovementView {
  const StockMovementView({
    required this.movement,
    required this.lotNumber,
    required this.designName,
    required this.colourName,
    this.colourHex,
    this.processName,
    this.workerName,
    required this.isReversed,
    this.reversedByMovementId,
    this.returnedGoodQty = 0,
    this.returnedDamagedQty = 0,
    this.lostQty = 0,
    this.shortageQty = 0,
    this.remainingPendingQty = 0,
  });

  final StockMovementEntity movement;
  final String lotNumber;
  final String designName;
  final String colourName;
  final String? colourHex;
  final String? processName;
  final String? workerName;
  final bool isReversed;
  final String? reversedByMovementId;
  final int returnedGoodQty;
  final int returnedDamagedQty;
  final int lostQty;
  final int shortageQty;
  final int remainingPendingQty;

  int get totalSettledQty =>
      returnedGoodQty + returnedDamagedQty + lostQty + shortageQty;
}

/// Per-process breakdown for a single `design_colour_id` or across all lots.
final class ProcessStockSummary {
  const ProcessStockSummary({
    required this.processId,
    required this.processName,
    required this.issued,
    required this.goodReturned,
    required this.damaged,
    required this.lost,
    required this.shortage,
    required this.pending,
  });

  final String processId;
  final String processName;
  final int issued;
  final int goodReturned;
  final int damaged;
  final int lost;
  final int shortage;
  final int pending;
}

/// Worker-wise stock summary (issued, returned, settled, and pending).
final class WorkerStockSummary {
  const WorkerStockSummary({
    required this.workerId,
    required this.workerName,
    required this.issued,
    required this.goodReturned,
    required this.damaged,
    required this.lost,
    required this.shortage,
    required this.pending,
    required this.openIssuesCount,
  });

  final String workerId;
  final String workerName;
  final int issued;
  final int goodReturned;
  final int damaged;
  final int lost;
  final int shortage;
  final int pending;
  final int openIssuesCount;
}

/// Exact live stock balances for a single `design_colour_id`.
final class DesignColourStockBalance {
  const DesignColourStockBalance({
    required this.designColourId,
    required this.lotId,
    required this.lotNumber,
    required this.lotDesignId,
    required this.designName,
    required this.colourName,
    this.colourHex,
    required this.unitPricePaise,
    required this.initialQuantity,
    required this.damagedBucket,
    required this.totalLost,
    required this.totalShortage,
    required this.totalGoodPhysicalStock,
    required this.totalPendingWithWorkers,
    required this.physicalAvailableInHouse,
    required this.totalIssued,
    required this.totalGoodReturned,
    required this.totalRepairedToGood,
    required this.processBreakdown,
  });

  final String designColourId;
  final String lotId;
  final String lotNumber;
  final String lotDesignId;
  final String designName;
  final String colourName;
  final String? colourHex;
  final int unitPricePaise;
  final int initialQuantity;
  final int damagedBucket;
  final int totalLost;
  final int totalShortage;
  final int totalGoodPhysicalStock;
  final int totalPendingWithWorkers;
  final int physicalAvailableInHouse;
  final int totalIssued;
  final int totalGoodReturned;
  final int totalRepairedToGood;
  final List<ProcessStockSummary> processBreakdown;
}

/// Open issue ready for partial or full return/settlement.
final class OpenIssueSummary {
  const OpenIssueSummary({
    required this.issueView,
    required this.childSettlements,
  });

  final StockMovementView issueView;
  final List<StockMovementView> childSettlements;

  int get issuedQuantity => issueView.movement.quantity;
  int get remainingPending => issueView.remainingPendingQty;
}

/// Filter criteria for stock movement history queries.
final class StockMovementFilter {
  const StockMovementFilter({
    this.lotId,
    this.designId,
    this.designColourId,
    this.memberId,
    this.processId,
    this.movementType,
    this.fromUtcMillis,
    this.toUtcMillis,
    this.searchQuery,
    this.includeReversed = true,
  });

  final String? lotId;
  final String? designId;
  final String? designColourId;
  final String? memberId;
  final String? processId;
  final StockMovementType? movementType;
  final int? fromUtcMillis;
  final int? toUtcMillis;
  final String? searchQuery;
  final bool includeReversed;
}

/// Result of chronological prefix replay reversal validation.
sealed class StockReversalValidationResult {
  const StockReversalValidationResult();
}

final class StockReversalAllowed extends StockReversalValidationResult {
  const StockReversalAllowed({required this.targetMovement});

  final StockMovementEntity targetMovement;
}

final class StockReversalBlocked extends StockReversalValidationResult {
  const StockReversalBlocked({
    required this.code,
    required this.message,
    this.blockingMovementId,
  });

  final String code;
  final String message;
  final String? blockingMovementId;
}

/// Result of posting a combined settlement batch against an issue.
final class SettlementBatchResult {
  const SettlementBatchResult({
    required this.createdMovements,
    required this.remainingPending,
    required this.wasIdempotentReplay,
  });

  final List<StockMovementEntity> createdMovements;
  final int remainingPending;
  final bool wasIdempotentReplay;
}
