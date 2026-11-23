import 'package:business_manager/features/rates/domain/entities/rate_entities.dart';

abstract interface class RateRepository {
  Future<List<MemberProcessRateEntity>> getRateHistory({
    required String workerId,
    required String processId,
  });

  Future<List<MemberProcessRateEntity>> getAllRatesForWorker(String workerId);

  Future<MemberProcessRateEntity?> getRateById(String rateId);

  Future<bool> isRateLockedByHistory(String rateId);

  Future<MemberProcessRateEntity?> findAutoClosableOpenRate({
    required String workerId,
    required String processId,
    required String newEffectiveFrom,
  });

  Future<MemberProcessRateEntity> addRate({
    required String workerId,
    required String processId,
    required int ratePaise,
    required String effectiveFrom,
    String? effectiveTo,
    String? notes,
    bool autoClosePreviousOpenRate = false,
  });

  Future<MemberProcessRateEntity> updateRate({
    required String rateId,
    required int ratePaise,
    required String effectiveFrom,
    String? effectiveTo,
    String? notes,
  });

  Future<RateResolutionResult> resolveRate({
    required String workerId,
    required String processId,
    required int transactionAtUtcMillis,
  });
}
