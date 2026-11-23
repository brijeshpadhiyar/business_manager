import 'package:business_manager/features/processes/domain/entities/process_entities.dart';

abstract interface class ProcessRepository {
  Future<List<ProcessEntity>> getProcesses({
    String? searchQuery,
    bool? isActiveFilter,
  });

  Future<ProcessDetailAggregate?> getProcessDetail(String processId);

  Future<ProcessEntity> createProcess({
    required String name,
    String? description,
    ProcessBillingModeOverride? billingModeOverride,
    bool includeDamagedInLabour = false,
  });

  Future<ProcessEntity> updateProcess({
    required String processId,
    required String name,
    String? description,
    ProcessBillingModeOverride? billingModeOverride,
    required bool includeDamagedInLabour,
  });

  Future<ProcessEntity> setProcessActive({
    required String processId,
    required bool isActive,
  });
}
