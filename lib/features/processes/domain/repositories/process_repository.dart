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
    bool isActive = true,
    ProcessBillingModeOverride? billingModeOverride,
    bool includeDamagedInLabour = false,
    int defaultRatePaise = 0,
    String defaultPricingUnit = 'PER_PIECE',
  });

  Future<ProcessEntity> updateProcess({
    required String processId,
    required String name,
    String? description,
    bool? isActive,
    ProcessBillingModeOverride? billingModeOverride,
    required bool includeDamagedInLabour,
    int? defaultRatePaise,
    String? defaultPricingUnit,
  });

  Future<ProcessEntity> setProcessActive({
    required String processId,
    required bool isActive,
  });
}
