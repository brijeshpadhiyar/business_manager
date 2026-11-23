import 'package:business_manager/features/rates/domain/entities/rate_entities.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'worker_entities.freezed.dart';

@freezed
sealed class WorkerEntity with _$WorkerEntity {
  const factory WorkerEntity({
    required String id,
    required String name,
    String? phone,
    String? address,
    String? notes,
    required bool isActive,
    required int createdAt,
    required int updatedAt,
  }) = _WorkerEntity;
}

@freezed
sealed class WorkerProcessAssignmentEntity
    with _$WorkerProcessAssignmentEntity {
  const factory WorkerProcessAssignmentEntity({
    required String id,
    required String workerId,
    required String processId,
    required String processName,
    required bool processIsActive,
    required bool isActive,
    required int createdAt,
    required int updatedAt,
  }) = _WorkerProcessAssignmentEntity;
}

@freezed
sealed class WorkerProcessRateSummary with _$WorkerProcessRateSummary {
  const factory WorkerProcessRateSummary({
    required WorkerProcessAssignmentEntity assignment,
    MemberProcessRateEntity? currentRate,
    required int totalRateHistoryCount,
  }) = _WorkerProcessRateSummary;
}

@freezed
sealed class WorkerDetailAggregate with _$WorkerDetailAggregate {
  const factory WorkerDetailAggregate({
    required WorkerEntity worker,
    required List<WorkerProcessRateSummary> assignedProcesses,
    required List<MemberProcessRateEntity> allRates,
  }) = _WorkerDetailAggregate;
}
