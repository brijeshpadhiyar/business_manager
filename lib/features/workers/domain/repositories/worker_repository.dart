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

  Future<WorkerEntity> updateWorker({
    required String workerId,
    required String name,
    String? phone,
    String? address,
    String? notes,
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

  Future<void> deactivateAssignment({
    required String workerId,
    required String processId,
  });
}
