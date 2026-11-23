import 'package:freezed_annotation/freezed_annotation.dart';

part 'process_entities.freezed.dart';

/// Optional per-process labour billing override (`NULL` inherits global default).
enum ProcessBillingModeOverride {
  receivedQty('RECEIVED_QTY'),
  givenQty('GIVEN_QTY');

  const ProcessBillingModeOverride(this.dbValue);

  final String dbValue;

  static ProcessBillingModeOverride? fromDbValue(String? value) {
    return switch (value) {
      'RECEIVED_QTY' => ProcessBillingModeOverride.receivedQty,
      'GIVEN_QTY' => ProcessBillingModeOverride.givenQty,
      _ => null,
    };
  }
}

@freezed
sealed class ProcessEntity with _$ProcessEntity {
  const factory ProcessEntity({
    required String id,
    required String name,
    String? description,
    required bool isActive,
    ProcessBillingModeOverride? billingModeOverride,
    required bool includeDamagedInLabour,
    required int createdAt,
    required int updatedAt,
  }) = _ProcessEntity;
}

@freezed
sealed class ProcessAuditEntry with _$ProcessAuditEntry {
  const factory ProcessAuditEntry({
    required String id,
    required String actionType,
    String? actor,
    String? previousValueJson,
    String? newValueJson,
    required int recordedAt,
  }) = _ProcessAuditEntry;
}

@freezed
sealed class ProcessAssignedWorkerSummary with _$ProcessAssignedWorkerSummary {
  const factory ProcessAssignedWorkerSummary({
    required String workerId,
    required String workerName,
    String? workerPhone,
    required bool workerIsActive,
    required int assignedAt,
  }) = _ProcessAssignedWorkerSummary;
}

@freezed
sealed class ProcessDetailAggregate with _$ProcessDetailAggregate {
  const factory ProcessDetailAggregate({
    required ProcessEntity process,
    required List<ProcessAssignedWorkerSummary> assignedWorkers,
    required List<ProcessAuditEntry> auditHistory,
  }) = _ProcessDetailAggregate;
}
