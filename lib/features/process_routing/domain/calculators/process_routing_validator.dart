import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';

/// Pure Dart deterministic validator & status resolver for Multi-Process
/// Routing and Material Handover workflows (Phase 7 validation rules).
final class ProcessRoutingValidator {
  const ProcessRoutingValidator();

  /// Rule 1 & 10: Validate dispatching stock from Factory to a Worker/Operation.
  String? validateFactoryDispatch({
    required String? designColourId,
    required String? processId,
    required String? workerId,
    required int quantity,
    required int availableInHouse,
  }) {
    if (designColourId == null || designColourId.trim().isEmpty) {
      return 'sku_required';
    }
    if (processId == null || processId.trim().isEmpty) {
      return 'process_required';
    }
    if (workerId == null || workerId.trim().isEmpty) {
      return 'worker_required';
    }
    if (quantity <= 0) {
      return 'invalid_quantity';
    }
    if (quantity > availableInHouse) {
      return 'insufficient_good_stock';
    }
    return null;
  }

  /// Rule 2: Cannot receive more than dispatched quantity.
  String? validateReceiptConfirmation({
    required int quantityDispatched,
    required int alreadyReceived,
    required int receiveNow,
    required ProcessHandoverStatus currentStatus,
  }) {
    if (currentStatus == ProcessHandoverStatus.cancelled) {
      return 'handover_cancelled';
    }
    if (currentStatus == ProcessHandoverStatus.received) {
      return 'handover_already_received';
    }
    if (receiveNow <= 0) {
      return 'invalid_quantity';
    }
    if (alreadyReceived + receiveNow > quantityDispatched) {
      return 'exceeds_dispatched_quantity';
    }
    return null;
  }

  /// Rule 3, 7 & 10: Cannot transfer stock not currently held by source worker.
  String? validateDirectTransfer({
    required JobProcessEntity sourceProcess,
    required String? destinationWorkerId,
    required String? destinationProcessId,
    required int transferQuantity,
  }) {
    if (sourceProcess.status.isTerminal) {
      return 'process_already_closed';
    }
    if (destinationWorkerId == null || destinationWorkerId.trim().isEmpty) {
      return 'worker_required';
    }
    if (destinationProcessId == null || destinationProcessId.trim().isEmpty) {
      return 'process_required';
    }
    if (transferQuantity <= 0) {
      return 'invalid_quantity';
    }
    if (sourceProcess.pendingQuantity <= 0 ||
        transferQuantity > sourceProcess.pendingQuantity) {
      return 'exceeds_held_quantity';
    }
    if (sourceProcess.memberId == destinationWorkerId &&
        sourceProcess.processId == destinationProcessId) {
      return 'same_worker_and_process';
    }
    return null;
  }

  /// Rule 4 & 7: Cannot return more than outstanding worker quantity.
  String? validateFactoryReturn({
    required JobProcessEntity sourceProcess,
    required int goodQuantity,
    required int damagedQuantity,
    String? reason,
  }) {
    if (sourceProcess.status.isTerminal) {
      return 'process_already_closed';
    }
    if (goodQuantity < 0 || damagedQuantity < 0) {
      return 'invalid_quantity';
    }
    final total = goodQuantity + damagedQuantity;
    if (total <= 0) {
      return 'invalid_quantity';
    }
    if (total > sourceProcess.pendingQuantity) {
      return 'exceeds_pending_quantity';
    }
    if (damagedQuantity > 0 && (reason == null || reason.trim().isEmpty)) {
      return 'reason_required';
    }
    return null;
  }

  /// Rule 5: Cannot reassign unavailable factory quantity.
  String? validateReassignment({
    required String? designColourId,
    required String? targetProcessId,
    required String? targetWorkerId,
    required int quantity,
    required int availableInHouse,
  }) {
    return validateFactoryDispatch(
      designColourId: designColourId,
      processId: targetProcessId,
      workerId: targetWorkerId,
      quantity: quantity,
      availableInHouse: availableInHouse,
    );
  }

  /// Rule 6: Cannot complete a process while its quantity remains unaccounted for.
  String? validateCompletion(JobProcessEntity process) {
    if (process.status == JobProcessStatus.cancelled) {
      return 'process_already_closed';
    }
    if (process.dispatchedQuantity <= 0) {
      return 'process_not_dispatched';
    }
    if (process.pendingQuantity > 0) {
      return 'unaccounted_quantity_remaining';
    }
    return null;
  }

  /// Validates cancelling an operation: blocked if worker still holds goods.
  String? validateCancellation(JobProcessEntity process) {
    if (process.status == JobProcessStatus.cancelled) {
      return 'process_already_closed';
    }
    if (process.pendingQuantity > 0) {
      return 'cannot_cancel_with_pending_stock';
    }
    return null;
  }

  /// Derives the clearest independent status for a `job_processes` row after a
  /// quantity change (dispatch, receive, partial/full transfer, or return).
  JobProcessStatus resolveStatus({
    required int dispatchedQty,
    required int receivedQty,
    required int returnedQty,
    required int transferredOutQty,
    required int damagedQty,
    required bool isCancelled,
  }) {
    if (isCancelled) return JobProcessStatus.cancelled;
    if (dispatchedQty == 0) return JobProcessStatus.pending;

    final settled = returnedQty + transferredOutQty + damagedQty;
    final pending = dispatchedQty - settled;

    if (pending <= 0) {
      if (transferredOutQty > 0 && returnedQty == 0 && damagedQty == 0) {
        return JobProcessStatus.transferred;
      }
      if (returnedQty > 0 && transferredOutQty == 0) {
        return JobProcessStatus.returned;
      }
      return JobProcessStatus.completed;
    }

    if (transferredOutQty > 0) {
      return JobProcessStatus.partiallyCompleted;
    }
    if (returnedQty > 0 || damagedQty > 0) {
      return JobProcessStatus.partiallyReturned;
    }
    if (receivedQty > 0) {
      return JobProcessStatus.inProgress;
    }
    return JobProcessStatus.dispatched;
  }

  /// Rule 8: Generates a human-readable, globally unique transfer reference
  /// (e.g., `TRF-20261124-A1B2C3`).
  String generateReference({
    required ProcessHandoverType type,
    required int transactionAtUtcMillis,
    required String uniqueId,
  }) {
    final prefix = switch (type) {
      ProcessHandoverType.factoryDispatch => 'DSP',
      ProcessHandoverType.directTransfer => 'TRF',
      ProcessHandoverType.factoryReturn => 'RET',
      ProcessHandoverType.reassignment => 'RAS',
      ProcessHandoverType.cancellation => 'CNL',
    };
    final datePart = IstDateTimeHelper.toIstBusinessDate(transactionAtUtcMillis)
        .replaceAll('-', '');
    final cleaned = uniqueId.replaceAll('-', '').toUpperCase();
    final suffix = cleaned.length >= 8
        ? cleaned.substring(cleaned.length - 8)
        : cleaned.padLeft(8, '0');
    return '$prefix-$datePart-$suffix';
  }
}
