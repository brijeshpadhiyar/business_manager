import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';

abstract interface class ProcessRoutingRepository {
  /// Loads the complete multi-process operations list, SKU stock balances,
  /// chronological handover timeline, default process pricing, additional
  /// charges, and Job-level cost summary.
  Future<JobRoutingOverview?> getJobRoutingOverview(String lotId);

  /// Updates a Process's default rate & configurable pricing unit while
  /// recording an immutable `process_rate_history` entry. NEVER modifies
  /// existing historical job assignments.
  Future<ProcessDefaultPricing> updateProcessDefaultRate({
    required String processId,
    required int defaultRatePaise,
    required String defaultPricingUnit,
    required String reason,
  });

  /// Returns immutable rate change history for a Process.
  Future<List<ProcessRateHistoryEntity>> getProcessRateHistory(
    String processId,
  );

  /// Adds a new operation to a Job (unlimited operations, repeatable process
  /// types, variant-level allocation) with dynamic pricing snapshot.
  /// If [agreedRatePaise] differs from the process default rate,
  /// [rateOverrideReason] is strictly required.
  Future<JobProcessEntity> addJobProcess({
    required String lotId,
    required String designColourId,
    required String processId,
    required String workerId,
    required int quantity,
    required int transactionAtUtcMillis,
    bool dispatchImmediately = true,
    int? agreedRatePaise,
    String? pricingUnit,
    String? rateOverrideReason,
    String? notes,
    String? clientRequestId,
  });

  /// Edits planned quantity, worker assignment, or notes on a non-terminal
  /// operation with an audit trail.
  Future<JobProcessEntity> editJobProcess({
    required String jobProcessId,
    String? workerId,
    int? plannedQuantity,
    String? notes,
  });

  /// Dispatches remaining planned quantity (or a specified partial quantity)
  /// from Factory inventory to the operation's assigned worker.
  Future<ProcessHandoverEntity> dispatchJobProcess({
    required String jobProcessId,
    required int quantity,
    required int transactionAtUtcMillis,
    String? notes,
    String? clientRequestId,
  });

  /// Confirms full or partial receipt of a dispatched or directly transferred
  /// handover, updating destination operation status to `IN_PROGRESS`.
  Future<ProcessHandoverEntity> confirmHandoverReceipt({
    required String handoverId,
    required int receivedQuantity,
    required int transactionAtUtcMillis,
  });

  /// Direct worker-to-worker material transfer (partial or full), preserving
  /// design & colour variant details and snapshotting destination agreed rate.
  Future<ProcessHandoverEntity> directTransfer({
    required String sourceJobProcessId,
    required String destinationProcessId,
    required String destinationWorkerId,
    required int quantity,
    required int transactionAtUtcMillis,
    bool autoConfirmReceipt = false,
    int? agreedRatePaise,
    String? pricingUnit,
    String? rateOverrideReason,
    String? notes,
    String? clientRequestId,
  });

  /// Returns completed good (and optional damaged) pieces from a worker back
  /// to the Factory, preserving original variant information.
  Future<ProcessHandoverEntity> returnToFactory({
    required String sourceJobProcessId,
    required int goodQuantity,
    int damagedQuantity = 0,
    required int transactionAtUtcMillis,
    String? reason,
    String? notes,
    String? clientRequestId,
  });

  /// Reassigns available Factory in-house quantity to a new operation & worker
  /// with dynamic pricing snapshot.
  Future<ProcessHandoverEntity> reassignFromFactory({
    required String lotId,
    required String designColourId,
    required String targetProcessId,
    required String targetWorkerId,
    required int quantity,
    required int transactionAtUtcMillis,
    int? agreedRatePaise,
    String? pricingUnit,
    String? rateOverrideReason,
    String? notes,
    String? clientRequestId,
  });

  /// Adds an approved extra charge or deduction to a Job operation. It is
  /// written to the worker ledger as a CREDIT / DEBIT adjustment (v1.4), with
  /// idempotent duplicate protection. Payments are recorded in Accounting.
  Future<ProcessAdditionalChargeEntity> addAdditionalCharge({
    required String jobProcessId,
    required ProcessChargeType chargeType,
    required String description,
    required int amountPaise,
    required int transactionAtUtcMillis,
    String? clientRequestId,
  });

  /// Marks an operation as Completed. Strictly blocked if any quantity remains
  /// unaccounted for (`pendingQuantity > 0`).
  Future<JobProcessEntity> markProcessCompleted({
    required String jobProcessId,
    required int transactionAtUtcMillis,
  });

  /// Cancels an operation that holds zero pending stock, recording an auditable
  /// `CANCELLATION` handover entry.
  Future<JobProcessEntity> cancelJobProcess({
    required String jobProcessId,
    required String reason,
    required int transactionAtUtcMillis,
  });
}
