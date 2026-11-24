import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';

/// Internal sentinel design name for Colour-Only Lots (where Design is optional).
const String kColourOnlyDesignSentinel = '__NO_DESIGN__';

/// Formats a variant label cleanly: `"Red"` for colour-only lots, or
/// `"D-101 • Red"` for design-based lots.
String formatVariantLabel(String designName, String colourName) {
  if (designName == kColourOnlyDesignSentinel || designName.trim().isEmpty) {
    return colourName;
  }
  return '$designName • $colourName';
}

/// Independent lifecycle status for every operation in a Job.
enum JobProcessStatus {
  draft('DRAFT', 'Draft'),
  pending('PENDING', 'Pending'),
  dispatched('DISPATCHED', 'Dispatched'),
  inProgress('IN_PROGRESS', 'In Progress'),
  partiallyCompleted('PARTIALLY_COMPLETED', 'Partially Completed'),
  completed('COMPLETED', 'Completed'),
  partiallyReturned('PARTIALLY_RETURNED', 'Partially Returned'),
  returned('RETURNED', 'Returned'),
  transferred('TRANSFERRED', 'Transferred'),
  cancelled('CANCELLED', 'Cancelled');

  const JobProcessStatus(this.dbValue, this.label);

  final String dbValue;
  final String label;

  bool get isTerminal =>
      this == completed ||
      this == returned ||
      this == transferred ||
      this == cancelled;

  static JobProcessStatus fromDbValue(String raw) {
    return JobProcessStatus.values.firstWhere(
      (e) => e.dbValue == raw,
      orElse: () => JobProcessStatus.draft,
    );
  }
}

/// Payment status for a worker operation or worker summary.
enum ProcessPaymentStatus {
  pending('PENDING', 'Pending'),
  partiallyPaid('PARTIALLY_PAID', 'Partially Paid'),
  paid('PAID', 'Paid');

  const ProcessPaymentStatus(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static ProcessPaymentStatus fromDbValue(String raw) {
    return ProcessPaymentStatus.values.firstWhere(
      (e) => e.dbValue == raw,
      orElse: () => ProcessPaymentStatus.pending,
    );
  }
}

/// Discriminator for additional charges or deductions on a Job operation.
enum ProcessChargeType {
  extraCharge('EXTRA_CHARGE', 'Extra Charge'),
  deduction('DEDUCTION', 'Deduction');

  const ProcessChargeType(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static ProcessChargeType fromDbValue(String raw) {
    return ProcessChargeType.values.firstWhere(
      (e) => e.dbValue == raw,
      orElse: () => ProcessChargeType.extraCharge,
    );
  }
}

/// Discriminator for auditable handover & routing movements.
enum ProcessHandoverType {
  factoryDispatch('FACTORY_DISPATCH', 'Dispatch'),
  directTransfer('DIRECT_TRANSFER', 'Direct Transfer'),
  factoryReturn('FACTORY_RETURN', 'Return to Factory'),
  reassignment('REASSIGNMENT', 'Reassignment'),
  cancellation('CANCELLATION', 'Cancelled');

  const ProcessHandoverType(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static ProcessHandoverType fromDbValue(String raw) {
    return ProcessHandoverType.values.firstWhere(
      (e) => e.dbValue == raw,
      orElse: () => ProcessHandoverType.factoryDispatch,
    );
  }
}

/// Receipt confirmation status for a handover record.
enum ProcessHandoverStatus {
  pendingReceipt('PENDING_RECEIPT', 'Pending Receipt'),
  partiallyReceived('PARTIALLY_RECEIVED', 'Partially Received'),
  received('RECEIVED', 'Received'),
  cancelled('CANCELLED', 'Cancelled');

  const ProcessHandoverStatus(this.dbValue, this.label);

  final String dbValue;
  final String label;

  static ProcessHandoverStatus fromDbValue(String raw) {
    return ProcessHandoverStatus.values.firstWhere(
      (e) => e.dbValue == raw,
      orElse: () => ProcessHandoverStatus.pendingReceipt,
    );
  }
}

/// Configured default rate and pricing unit for a Process.
final class ProcessDefaultPricing {
  const ProcessDefaultPricing({
    required this.processId,
    required this.defaultRatePaise,
    required this.defaultPricingUnit,
  });

  final String processId;
  final int defaultRatePaise;
  final String defaultPricingUnit;
}

/// Enriched domain entity for a single operation assigned to a Job, including
/// immutable dynamic pricing snapshots and payment status.
final class JobProcessEntity {
  const JobProcessEntity({
    required this.id,
    required this.lotId,
    required this.lotDesignId,
    required this.designColourId,
    required this.designName,
    required this.colourName,
    required this.processId,
    required this.processName,
    this.memberId,
    this.workerName,
    required this.sequenceOrder,
    required this.plannedQuantity,
    required this.dispatchedQuantity,
    required this.receivedQuantity,
    required this.returnedToFactoryQuantity,
    required this.transferredOutQuantity,
    required this.damagedQuantity,
    required this.status,
    this.sourceJobProcessId,
    this.linkedIssueMovementId,
    this.defaultRatePaise = 0,
    this.agreedRatePaise = 0,
    this.pricingUnit = 'PER_PIECE',
    this.rateOverrideReason,
    this.payableAmountPaise = 0,
    this.paidAmountPaise = 0,
    this.paymentStatus = ProcessPaymentStatus.pending,
    this.notes,
    required this.transactionAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String lotId;
  final String lotDesignId;
  final String designColourId;
  final String designName;
  final String colourName;
  final String processId;
  final String processName;
  final String? memberId;
  final String? workerName;
  final int sequenceOrder;
  final int plannedQuantity;
  final int dispatchedQuantity;
  final int receivedQuantity;
  final int returnedToFactoryQuantity;
  final int transferredOutQuantity;
  final int damagedQuantity;
  final JobProcessStatus status;
  final String? sourceJobProcessId;
  final String? linkedIssueMovementId;
  final int defaultRatePaise;
  final int agreedRatePaise;
  final String pricingUnit;
  final String? rateOverrideReason;
  final int payableAmountPaise;
  final int paidAmountPaise;
  final ProcessPaymentStatus paymentStatus;
  final String? notes;
  final int transactionAt;
  final int createdAt;
  final int updatedAt;

  bool get isColourOnly => designName == kColourOnlyDesignSentinel;

  String get variantLabel => formatVariantLabel(designName, colourName);

  bool get isRateOverridden => agreedRatePaise != defaultRatePaise;

  int get pendingQuantity {
    final rem =
        dispatchedQuantity -
        returnedToFactoryQuantity -
        transferredOutQuantity -
        damagedQuantity;
    return rem < 0 ? 0 : rem;
  }

  int get unreceivedQuantity {
    final rem = dispatchedQuantity - receivedQuantity;
    return rem < 0 ? 0 : rem;
  }

  int get remainingToDispatch {
    final rem = plannedQuantity - dispatchedQuantity;
    return rem < 0 ? 0 : rem;
  }

  int get accountedQuantity =>
      returnedToFactoryQuantity + transferredOutQuantity + damagedQuantity;

  bool get canDispatch =>
      !status.isTerminal && remainingToDispatch > 0 && memberId != null;

  bool get canTransferOrReturn => !status.isTerminal && pendingQuantity > 0;

  bool get canComplete =>
      !status.isTerminal && dispatchedQuantity > 0 && pendingQuantity == 0;

  bool get canCancel => !status.isTerminal && pendingQuantity == 0;
}

/// Process-specific additional charge or deduction linked to a Job operation.
final class ProcessAdditionalChargeEntity {
  const ProcessAdditionalChargeEntity({
    required this.id,
    required this.jobProcessId,
    required this.lotId,
    required this.designColourId,
    required this.memberId,
    required this.chargeType,
    required this.description,
    required this.amountPaise,
    required this.transactionAt,
    required this.createdAt,
  });

  final String id;
  final String jobProcessId;
  final String lotId;
  final String designColourId;
  final String memberId;
  final ProcessChargeType chargeType;
  final String description;
  final int amountPaise;
  final int transactionAt;
  final int createdAt;
}

/// Immutable rate change history entry (Process Default or Job Assignment).
final class ProcessRateHistoryEntity {
  const ProcessRateHistoryEntity({
    required this.id,
    required this.scope,
    required this.processId,
    this.jobProcessId,
    this.memberId,
    this.designColourId,
    required this.previousRatePaise,
    required this.newRatePaise,
    required this.pricingUnit,
    required this.reason,
    this.changedBy,
    required this.changedAt,
  });

  final String id;
  final String scope;
  final String processId;
  final String? jobProcessId;
  final String? memberId;
  final String? designColourId;
  final int previousRatePaise;
  final int newRatePaise;
  final String pricingUnit;
  final String reason;
  final String? changedBy;
  final int changedAt;
}

/// Worker-wise payable, charges, deductions, paid, and outstanding breakdown.
final class WorkerCostBreakdown {
  const WorkerCostBreakdown({
    required this.workerId,
    required this.workerName,
    required this.totalQuantity,
    required this.basePayablePaise,
    required this.additionalChargesPaise,
    required this.deductionsPaise,
    required this.netPayablePaise,
    required this.paidPaise,
    required this.outstandingPaise,
    required this.paymentStatus,
  });

  final String workerId;
  final String workerName;
  final int totalQuantity;
  final int basePayablePaise;
  final int additionalChargesPaise;
  final int deductionsPaise;
  final int netPayablePaise;
  final int paidPaise;
  final int outstandingPaise;
  final ProcessPaymentStatus paymentStatus;
}

/// Generic cost summary bucket for Process-wise, Design-wise, and Colour-wise totals.
final class CostBucketSummary {
  const CostBucketSummary({
    required this.id,
    required this.label,
    required this.quantity,
    required this.totalCostPaise,
  });

  final String id;
  final String label;
  final int quantity;
  final int totalCostPaise;
}

/// Complete Job-level production cost and payment summary.
final class JobCostSummary {
  const JobCostSummary({
    this.totalBasePaise = 0,
    this.totalAdditionalChargesPaise = 0,
    this.totalDeductionsPaise = 0,
    this.totalNetCostPaise = 0,
    this.totalPaidPaise = 0,
    this.totalOutstandingPaise = 0,
    this.workerPayables = const [],
    this.processExpenses = const [],
    this.designCosts = const [],
    this.colourCosts = const [],
  });

  final int totalBasePaise;
  final int totalAdditionalChargesPaise;
  final int totalDeductionsPaise;
  final int totalNetCostPaise;
  final int totalPaidPaise;
  final int totalOutstandingPaise;
  final List<WorkerCostBreakdown> workerPayables;
  final List<CostBucketSummary> processExpenses;
  final List<CostBucketSummary> designCosts;
  final List<CostBucketSummary> colourCosts;
}

/// Enriched chronological handover/transfer event for a Job.
final class ProcessHandoverEntity {
  const ProcessHandoverEntity({
    required this.id,
    required this.transferReference,
    this.clientRequestId,
    required this.lotId,
    required this.lotDesignId,
    required this.designColourId,
    required this.designName,
    required this.colourName,
    required this.handoverType,
    this.fromJobProcessId,
    this.toJobProcessId,
    this.fromMemberId,
    this.fromMemberName,
    this.toMemberId,
    this.toMemberName,
    required this.processId,
    required this.processName,
    required this.quantityDispatched,
    required this.quantityReceived,
    required this.status,
    this.linkedStockMovementId,
    this.notes,
    required this.transactionAt,
    required this.recordedAt,
  });

  final String id;
  final String transferReference;
  final String? clientRequestId;
  final String lotId;
  final String lotDesignId;
  final String designColourId;
  final String designName;
  final String colourName;
  final ProcessHandoverType handoverType;
  final String? fromJobProcessId;
  final String? toJobProcessId;
  final String? fromMemberId;
  final String? fromMemberName;
  final String? toMemberId;
  final String? toMemberName;
  final String processId;
  final String processName;
  final int quantityDispatched;
  final int quantityReceived;
  final ProcessHandoverStatus status;
  final String? linkedStockMovementId;
  final String? notes;
  final int transactionAt;
  final int recordedAt;

  String get variantLabel => formatVariantLabel(designName, colourName);

  int get pendingReceiptQuantity {
    final rem = quantityDispatched - quantityReceived;
    return rem < 0 ? 0 : rem;
  }

  String get fromLocationLabel => fromMemberName ?? 'Factory';

  String get toLocationLabel => toMemberName ?? 'Factory';

  bool get canConfirmReceipt =>
      status != ProcessHandoverStatus.received &&
      status != ProcessHandoverStatus.cancelled &&
      pendingReceiptQuantity > 0;
}

/// Snapshot of where a Job's pieces currently sit across Factory & Workers.
final class GoodsLocationBucket {
  const GoodsLocationBucket({
    required this.locationLabel,
    required this.operationLabel,
    required this.quantity,
    required this.isFactory,
  });

  final String locationLabel;
  final String operationLabel;
  final int quantity;
  final bool isFactory;
}

/// Complete multi-process routing & dynamic pricing aggregate for a Job (`Lot`).
final class JobRoutingOverview {
  const JobRoutingOverview({
    required this.lot,
    required this.skuBalances,
    required this.jobProcesses,
    required this.handovers,
    required this.currentLocations,
    required this.availableProcesses,
    required this.availableWorkers,
    this.defaultPricingByProcessId = const {},
    this.additionalCharges = const [],
    this.costSummary = const JobCostSummary(),
  });

  final LotEntity lot;
  final List<DesignColourStockBalance> skuBalances;
  final List<JobProcessEntity> jobProcesses;
  final List<ProcessEntity> availableProcesses;
  final List<WorkerEntity> availableWorkers;
  final List<ProcessHandoverEntity> handovers;
  final List<GoodsLocationBucket> currentLocations;
  final Map<String, ProcessDefaultPricing> defaultPricingByProcessId;
  final List<ProcessAdditionalChargeEntity> additionalCharges;
  final JobCostSummary costSummary;

  int get totalInitialQuantity =>
      skuBalances.fold(0, (sum, b) => sum + b.initialQuantity);

  int get totalFactoryAvailable =>
      skuBalances.fold(0, (sum, b) => sum + b.physicalAvailableInHouse);

  int get totalPendingWithWorkers =>
      skuBalances.fold(0, (sum, b) => sum + b.totalPendingWithWorkers);

  int get totalDamaged =>
      skuBalances.fold(0, (sum, b) => sum + b.damagedBucket);

  int get activeOperationsCount =>
      jobProcesses.where((p) => !p.status.isTerminal).length;
}
