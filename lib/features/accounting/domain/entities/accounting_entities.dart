import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';

/// Matches `labour_entries.basis_type` CHECK constraint.
enum LabourBasisType {
  issued('ISSUED'),
  receivedGood('RECEIVED_GOOD'),
  receivedDamaged('RECEIVED_DAMAGED'),
  reversal('REVERSAL');

  const LabourBasisType(this.dbValue);

  final String dbValue;

  static LabourBasisType fromDbValue(String value) {
    return LabourBasisType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => throw ArgumentError('Unknown LabourBasisType: $value'),
    );
  }
}

/// Matches `payments.payment_type` CHECK constraint.
enum PaymentType {
  regular('REGULAR'),
  advance('ADVANCE'),
  advanceRefund('ADVANCE_REFUND'),
  reversal('REVERSAL');

  const PaymentType(this.dbValue);

  final String dbValue;

  static PaymentType fromDbValue(String value) {
    return PaymentType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => throw ArgumentError('Unknown PaymentType: $value'),
    );
  }
}

/// Matches `payments.payment_mode` CHECK constraint.
enum PaymentMode {
  cash('CASH'),
  upi('UPI'),
  bankTransfer('BANK_TRANSFER'),
  cheque('CHEQUE'),
  other('OTHER');

  const PaymentMode(this.dbValue);

  final String dbValue;

  static PaymentMode fromDbValue(String value) {
    return PaymentMode.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => throw ArgumentError('Unknown PaymentMode: $value'),
    );
  }
}

/// Matches `worker_ledger_adjustments.adjustment_type` CHECK constraint.
enum WorkerAdjustmentType {
  credit('CREDIT'),
  debit('DEBIT'),
  reversal('REVERSAL');

  const WorkerAdjustmentType(this.dbValue);

  final String dbValue;

  static WorkerAdjustmentType fromDbValue(String value) {
    return WorkerAdjustmentType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => throw ArgumentError('Unknown WorkerAdjustmentType: $value'),
    );
  }
}

/// Immutable domain entity for a row in `labour_entries`.
final class LabourEntryEntity {
  const LabourEntryEntity({
    required this.id,
    required this.stockMovementId,
    this.reversesLabourEntryId,
    required this.memberId,
    required this.processId,
    required this.lotId,
    required this.basisType,
    required this.quantity,
    required this.ratePaise,
    required this.amountPaise,
    required this.isPayable,
    required this.transactionAt,
    required this.recordedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String stockMovementId;
  final String? reversesLabourEntryId;
  final String memberId;
  final String processId;
  final String lotId;
  final LabourBasisType basisType;
  final int quantity;
  final int ratePaise;
  final int amountPaise;
  final bool isPayable;
  final int transactionAt;
  final int recordedAt;
  final int createdAt;
  final int updatedAt;
}

/// Enriched labour entry view with human-readable lot, process, and worker names.
final class LabourEntryView {
  const LabourEntryView({
    required this.entry,
    required this.workerName,
    required this.processName,
    required this.lotNumber,
    required this.isReversed,
  });

  final LabourEntryEntity entry;
  final String workerName;
  final String processName;
  final String lotNumber;
  final bool isReversed;
}

/// Pure Dart calculation output specifying the labour entry to insert atomically.
final class PlannedLabourEntry {
  const PlannedLabourEntry({
    required this.basisType,
    required this.quantity,
    required this.ratePaise,
    required this.amountPaise,
    required this.isPayable,
    this.reversesLabourEntryId,
  });

  final LabourBasisType basisType;
  final int quantity;
  final int ratePaise;
  final int amountPaise;
  final bool isPayable;
  final String? reversesLabourEntryId;
}

/// Immutable domain entity for a row in `payments`.
final class PaymentEntity {
  const PaymentEntity({
    required this.id,
    required this.memberId,
    required this.paymentType,
    this.reversesPaymentId,
    this.clientRequestId,
    required this.amountPaise,
    required this.paymentMode,
    this.referenceNo,
    this.reason,
    this.notes,
    required this.transactionAt,
    required this.recordedAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String memberId;
  final PaymentType paymentType;
  final String? reversesPaymentId;
  final String? clientRequestId;
  final int amountPaise;
  final PaymentMode paymentMode;
  final String? referenceNo;
  final String? reason;
  final String? notes;
  final int transactionAt;
  final int recordedAt;
  final String? createdBy;
  final int createdAt;
  final int updatedAt;
}

final class PaymentView {
  const PaymentView({
    required this.payment,
    required this.workerName,
    required this.isReversed,
  });

  final PaymentEntity payment;
  final String workerName;
  final bool isReversed;
}

/// Immutable domain entity for a row in `worker_ledger_adjustments`.
final class WorkerAdjustmentEntity {
  const WorkerAdjustmentEntity({
    required this.id,
    required this.memberId,
    required this.adjustmentType,
    this.reversesAdjustmentId,
    this.clientRequestId,
    required this.amountPaise,
    required this.reason,
    this.notes,
    required this.transactionAt,
    required this.recordedAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String memberId;
  final WorkerAdjustmentType adjustmentType;
  final String? reversesAdjustmentId;
  final String? clientRequestId;
  final int amountPaise;
  final String reason;
  final String? notes;
  final int transactionAt;
  final int recordedAt;
  final String? createdBy;
  final int createdAt;
  final int updatedAt;
}

/// Categorized line type inside a worker's chronological financial ledger.
enum WorkerLedgerEntryKind {
  labourPayable,
  labourInformational,
  labourReversal,
  regularPayment,
  advancePayment,
  advanceRefund,
  paymentReversal,
  adjustmentCredit,
  adjustmentDebit,
  adjustmentReversal,
}

/// Single chronological row in a worker's ledger with running balance in paise.
final class WorkerLedgerLine {
  const WorkerLedgerLine({
    required this.id,
    required this.sourceEntityId,
    required this.kind,
    required this.title,
    this.subtitle,
    required this.transactionAt,
    required this.recordedAt,
    required this.amountPaise,
    required this.balanceDeltaPaise,
    required this.runningBalancePaise,
    required this.isInformational,
    required this.isReversed,
    this.paymentMode,
    this.referenceNo,
    this.reason,
    this.notes,
  });

  final String id;
  final String sourceEntityId;
  final WorkerLedgerEntryKind kind;
  final String title;
  final String? subtitle;
  final int transactionAt;
  final int recordedAt;
  final int amountPaise;

  /// Signed impact on worker net balance (`+` increases owner liability to worker,
  /// `-` decreases owner liability / increases worker advance credit).
  final int balanceDeltaPaise;

  /// Cumulative signed net balance after this transaction (negative = advance credit).
  final int runningBalancePaise;
  final bool isInformational;
  final bool isReversed;
  final PaymentMode? paymentMode;
  final String? referenceNo;
  final String? reason;
  final String? notes;
}

/// Exact financial summary for a worker in integer paise.
/// Clearly distinguishes earned labour, advances, regular payments, adjustments,
/// outstanding payable, and advance credit balance.
final class WorkerFinancialSummary {
  const WorkerFinancialSummary({
    required this.workerId,
    required this.workerName,
    this.workerPhone,
    required this.workerIsActive,
    required this.totalIssuedLabourPaise,
    required this.totalReceivedLabourPaise,
    required this.earnedLabourPaise,
    required this.adjustmentCreditsPaise,
    required this.adjustmentDebitsPaise,
    required this.regularPaymentsPaise,
    required this.advancePaymentsPaise,
    required this.advanceRefundsPaise,
    required this.netPaidToWorkerPaise,
    required this.netBalancePaise,
    required this.outstandingPayablePaise,
    required this.advanceCreditBalancePaise,
  });

  final String workerId;
  final String workerName;
  final String? workerPhone;
  final bool workerIsActive;
  final int totalIssuedLabourPaise;
  final int totalReceivedLabourPaise;
  final int earnedLabourPaise;
  final int adjustmentCreditsPaise;
  final int adjustmentDebitsPaise;
  final int regularPaymentsPaise;
  final int advancePaymentsPaise;
  final int advanceRefundsPaise;
  final int netPaidToWorkerPaise;

  /// Signed net balance (`earnedLabour + adjustmentCredits - adjustmentDebits - netPaidToWorker`).
  /// Positive = business owes worker; Negative = worker holds advance credit.
  final int netBalancePaise;

  /// `max(0, netBalancePaise)` — amount business owes worker.
  final int outstandingPayablePaise;

  /// `max(0, -netBalancePaise)` — unused advance credit carried forward.
  final int advanceCreditBalancePaise;

  int get netAdjustmentsPaise => adjustmentCreditsPaise - adjustmentDebitsPaise;
}

/// Full worker ledger aggregate combining financial summary, running ledger lines,
/// and worker stock summary.
final class WorkerLedgerDetail {
  const WorkerLedgerDetail({
    required this.summary,
    required this.lines,
    required this.openingBalancePaise,
    required this.stockSummary,
    required this.processBreakdown,
    required this.payments,
    required this.adjustments,
  });

  final WorkerFinancialSummary summary;
  final List<WorkerLedgerLine> lines;
  final int openingBalancePaise;
  final WorkerStockSummary stockSummary;
  final List<ProcessStockSummary> processBreakdown;
  final List<PaymentView> payments;
  final List<WorkerAdjustmentEntity> adjustments;
}
