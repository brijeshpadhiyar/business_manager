import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';

abstract interface class AccountingRepository {
  /// Returns exact financial summaries for all workers (non-deleted).
  Future<List<WorkerFinancialSummary>> getAllWorkerSummaries();

  /// Returns full ledger detail (financial summary, chronological running-balance
  /// lines, stock summary, payments & adjustments) for a worker.
  Future<WorkerLedgerDetail?> getWorkerLedgerDetail(
    String workerId, {
    int? fromUtcMillis,
    int? toUtcMillis,
  });

  /// Returns labour entries with optional filters.
  Future<List<LabourEntryView>> getLabourEntries({
    String? workerId,
    String? processId,
    String? lotId,
    int? fromUtcMillis,
    int? toUtcMillis,
    bool payableOnly = false,
  });

  /// Returns payment history with optional filters.
  Future<List<PaymentView>> getPayments({
    String? workerId,
    PaymentType? paymentType,
    int? fromUtcMillis,
    int? toUtcMillis,
  });

  /// Atomically records a worker payment (`REGULAR`, `ADVANCE`, or `ADVANCE_REFUND`)
  /// with idempotency (`clientRequestId`) and audit logging.
  Future<PaymentEntity> recordPayment({
    required String workerId,
    required PaymentType paymentType,
    required int amountPaise,
    required PaymentMode paymentMode,
    required int transactionAtUtcMillis,
    String? referenceNo,
    String? notes,
    String? clientRequestId,
  });

  /// Atomically reverses an active payment with mandatory reason & audit trail.
  Future<PaymentEntity> reversePayment({
    required String paymentId,
    required String reason,
    required int transactionAtUtcMillis,
    String? notes,
  });

  /// Atomically records an audited worker ledger adjustment (`CREDIT` or `DEBIT`)
  /// with mandatory reason.
  Future<WorkerAdjustmentEntity> recordAdjustment({
    required String workerId,
    required WorkerAdjustmentType adjustmentType,
    required int amountPaise,
    required String reason,
    required int transactionAtUtcMillis,
    String? notes,
    String? clientRequestId,
  });

  /// Atomically reverses an active worker ledger adjustment with mandatory reason.
  Future<WorkerAdjustmentEntity> reverseAdjustment({
    required String adjustmentId,
    required String reason,
    required int transactionAtUtcMillis,
    String? notes,
  });
}
