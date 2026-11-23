import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/rates/domain/entities/rate_entities.dart';

/// Pure Dart domain service for historical per-piece rate lookup and
/// non-overlapping effective-date range validation (`docs/11_member_pricing_rules.md`).
///
/// Strictly independent of Flutter widgets, BLoCs, and Drift.
/// Always resolves rates using `transactionAt` converted to `Asia/Kolkata`
/// business date (`YYYY-MM-DD`) — never `recordedAt`.
final class MemberProcessRateResolver {
  const MemberProcessRateResolver();

  static final RegExp _isoDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Validates that [isoDate] is a real calendar date in strict `YYYY-MM-DD` format.
  bool isValidIsoDate(String isoDate) {
    if (!_isoDatePattern.hasMatch(isoDate)) return false;
    final parts = isoDate.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    if (month < 1 || month > 12 || day < 1 || day > 31) return false;
    final dt = DateTime.utc(year, month, day);
    return dt.year == year && dt.month == month && dt.day == day;
  }

  /// Returns the ISO `YYYY-MM-DD` date immediately preceding [isoDate].
  /// Example: `2026-12-01` -> `2026-11-30`.
  String previousDayIso(String isoDate) {
    if (!isValidIsoDate(isoDate)) {
      throw ArgumentError.value(isoDate, 'isoDate', 'Invalid YYYY-MM-DD date.');
    }
    final parts = isoDate.split('-');
    final dt = DateTime.utc(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    ).subtract(const Duration(days: 1));
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Returns `true` iff two closed/half-open inclusive ISO date intervals
  /// `[start1, end1]` and `[start2, end2]` (with `null` = $+\infty$) overlap.
  bool rangesOverlap({
    required String start1,
    String? end1,
    required String start2,
    String? end2,
  }) {
    final s1LeE2 = end2 == null || start1.compareTo(end2) <= 0;
    final s2LeE1 = end1 == null || start2.compareTo(end1) <= 0;
    return s1LeE2 && s2LeE1;
  }

  /// Resolves the applicable per-piece rate for `(workerId, processId)` at
  /// [transactionAtUtcMillis] by converting to `Asia/Kolkata` business date.
  ///
  /// Rejects missing or conflicting (overlapping) rate records.
  RateResolutionResult resolve({
    required String workerId,
    required String processId,
    required int transactionAtUtcMillis,
    required List<MemberProcessRateEntity> rates,
  }) {
    final businessDateIst = IstDateTimeHelper.toIstBusinessDate(
      transactionAtUtcMillis,
    );
    return resolveForBusinessDate(
      workerId: workerId,
      processId: processId,
      businessDateIst: businessDateIst,
      rates: rates,
    );
  }

  /// Resolves the applicable rate for an explicit `Asia/Kolkata` `YYYY-MM-DD` date.
  RateResolutionResult resolveForBusinessDate({
    required String workerId,
    required String processId,
    required String businessDateIst,
    required List<MemberProcessRateEntity> rates,
  }) {
    if (!isValidIsoDate(businessDateIst)) {
      throw ArgumentError.value(
        businessDateIst,
        'businessDateIst',
        'Invalid YYYY-MM-DD business date.',
      );
    }

    final matches = rates.where((rate) {
      if (rate.memberId != workerId || rate.processId != processId) {
        return false;
      }
      final afterStart = rate.effectiveFrom.compareTo(businessDateIst) <= 0;
      final beforeEnd =
          rate.effectiveTo == null ||
          rate.effectiveTo!.compareTo(businessDateIst) >= 0;
      return afterStart && beforeEnd;
    }).toList();

    if (matches.isEmpty) {
      return RateResolutionMissing(
        workerId: workerId,
        processId: processId,
        businessDateIst: businessDateIst,
      );
    }
    if (matches.length > 1) {
      return RateResolutionConflict(
        workerId: workerId,
        processId: processId,
        businessDateIst: businessDateIst,
        conflictingRates: matches,
      );
    }
    return RateResolutionFound(
      workerId: workerId,
      processId: processId,
      businessDateIst: businessDateIst,
      rate: matches.single,
    );
  }

  /// Finds an existing open-ended (`effectiveTo == null`) rate whose
  /// `effectiveFrom` is strictly earlier than [newEffectiveFrom], so it can be
  /// safely auto-closed to `previousDayIso(newEffectiveFrom)` on user confirmation.
  MemberProcessRateEntity? findAutoClosableOpenRate({
    required String newEffectiveFrom,
    required List<MemberProcessRateEntity> existingRates,
    String? excludeRateId,
  }) {
    if (!isValidIsoDate(newEffectiveFrom)) return null;
    for (final rate in existingRates) {
      if (excludeRateId != null && rate.id == excludeRateId) continue;
      if (rate.effectiveTo == null &&
          rate.effectiveFrom.compareTo(newEffectiveFrom) < 0) {
        return rate;
      }
    }
    return null;
  }

  /// Validates a candidate rate interval against [existingRates] for the same
  /// `(memberId, processId)` pair.
  ///
  /// When [autoCloseRateId] is provided, that open-ended rate is evaluated as
  /// closed on `previousDayIso(effectiveFrom)` to guarantee zero overlap with
  /// any other historical rate.
  RateValidationResult validateCandidateRate({
    required int ratePaise,
    required String effectiveFrom,
    String? effectiveTo,
    required List<MemberProcessRateEntity> existingRates,
    String? excludeRateId,
    String? autoCloseRateId,
  }) {
    if (ratePaise < 0) {
      return const RateValidationResult.invalid(
        RateValidationErrorCode.negativeRate,
      );
    }
    if (!isValidIsoDate(effectiveFrom)) {
      return const RateValidationResult.invalid(
        RateValidationErrorCode.invalidEffectiveFrom,
      );
    }
    if (effectiveTo != null) {
      if (!isValidIsoDate(effectiveTo)) {
        return const RateValidationResult.invalid(
          RateValidationErrorCode.invalidEffectiveTo,
        );
      }
      if (effectiveTo.compareTo(effectiveFrom) < 0) {
        return const RateValidationResult.invalid(
          RateValidationErrorCode.effectiveToBeforeFrom,
        );
      }
    }

    for (final existing in existingRates) {
      if (excludeRateId != null && existing.id == excludeRateId) continue;

      String? simulatedExistingTo = existing.effectiveTo;
      if (autoCloseRateId != null &&
          existing.id == autoCloseRateId &&
          existing.effectiveTo == null &&
          existing.effectiveFrom.compareTo(effectiveFrom) < 0) {
        simulatedExistingTo = previousDayIso(effectiveFrom);
      }

      if (effectiveTo == null && simulatedExistingTo == null) {
        return const RateValidationResult.invalid(
          RateValidationErrorCode.multipleOpenEndedRates,
        );
      }

      if (rangesOverlap(
        start1: effectiveFrom,
        end1: effectiveTo,
        start2: existing.effectiveFrom,
        end2: simulatedExistingTo,
      )) {
        return const RateValidationResult.invalid(
          RateValidationErrorCode.overlappingPeriod,
        );
      }
    }

    return const RateValidationResult.valid();
  }
}
