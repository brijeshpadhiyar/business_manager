import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';

abstract interface class WorkerRepository {
  Future<List<WorkerEntity>> getWorkers({
    String? searchQuery,
    bool? isActiveFilter,
  });

  Future<WorkerDetailAggregate?> getWorkerDetail(
    String workerId, {
    int? asOfUtcMillis,
  });

  Future<WorkerEntity> createWorker({
    required String name,
    String? phone,
    String? address,
    String? notes,
  });

  /// Atomically creates a Worker together with multiple process assignments
  /// and optional worker-specific labour rates in a single database transaction.
  Future<WorkerEntity> createWorkerWithProcesses({
    required String name,
    String? phone,
    String? address,
    String? notes,
    bool isActive = true,
    required List<WorkerProcessConfigInput> processConfigs,
  });

  Future<WorkerEntity> updateWorker({
    required String workerId,
    required String name,
    String? phone,
    String? address,
    String? notes,
  });

  /// Atomically updates Worker details, active status, multi-process
  /// assignments (soft-deactivating removed links while preserving all
  /// historical transactions & rate records), and worker-specific labour rates.
  Future<WorkerEntity> updateWorkerWithProcesses({
    required String workerId,
    required String name,
    String? phone,
    String? address,
    String? notes,
    required bool isActive,
    required List<WorkerProcessConfigInput> processConfigs,
  });

  Future<WorkerEntity> setWorkerActive({
    required String workerId,
    required bool isActive,
  });

  Future<List<WorkerProcessAssignmentEntity>> getAssignmentsForWorker(
    String workerId, {
    bool activeOnly = true,
  });

  Future<WorkerProcessAssignmentEntity> assignProcessToWorker({
    required String workerId,
    required String processId,
  });

  /// Atomically assigns (or reactivates) a process for a worker and optionally
  /// records a worker-specific labour rate (when [customRatePaise] != null).
  Future<WorkerProcessAssignmentEntity> assignProcessWithOptionalRate({
    required String workerId,
    required String processId,
    int? customRatePaise,
    String? notes,
  });

  Future<void> deactivateAssignment({
    required String workerId,
    required String processId,
  });
}
