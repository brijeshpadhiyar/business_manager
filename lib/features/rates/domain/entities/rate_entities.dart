import 'package:freezed_annotation/freezed_annotation.dart';

part 'rate_entities.freezed.dart';

@freezed
sealed class MemberProcessRateEntity with _$MemberProcessRateEntity {
  const factory MemberProcessRateEntity({
    required String id,
    required String memberId,
    required String processId,
    required int ratePaise,
    required String effectiveFrom,
    String? effectiveTo,
    String? notes,
    required int createdAt,
    required int updatedAt,
  }) = _MemberProcessRateEntity;
}

/// Sealed result for pure Dart rate resolution (`MemberProcessRateResolver`).
sealed class RateResolutionResult {
  const RateResolutionResult({
    required this.workerId,
    required this.processId,
    required this.businessDateIst,
  });

  final String workerId;
  final String processId;
  final String businessDateIst;
}

final class RateResolutionFound extends RateResolutionResult {
  const RateResolutionFound({
    required super.workerId,
    required super.processId,
    required super.businessDateIst,
    required this.rate,
  });

  final MemberProcessRateEntity rate;
}

final class RateResolutionMissing extends RateResolutionResult {
  const RateResolutionMissing({
    required super.workerId,
    required super.processId,
    required super.businessDateIst,
  });
}

final class RateResolutionConflict extends RateResolutionResult {
  const RateResolutionConflict({
    required super.workerId,
    required super.processId,
    required super.businessDateIst,
    required this.conflictingRates,
  });

  final List<MemberProcessRateEntity> conflictingRates;
}

/// Validation outcome for creating or updating a historical rate interval.
enum RateValidationErrorCode {
  negativeRate,
  invalidEffectiveFrom,
  invalidEffectiveTo,
  effectiveToBeforeFrom,
  overlappingPeriod,
  multipleOpenEndedRates,
}

final class RateValidationResult {
  const RateValidationResult.valid() : isValid = true, errorCode = null;

  const RateValidationResult.invalid(this.errorCode) : isValid = false;

  final bool isValid;
  final RateValidationErrorCode? errorCode;
}
