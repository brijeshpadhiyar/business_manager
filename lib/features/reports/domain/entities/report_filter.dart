import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:timezone/timezone.dart' as tz;

/// The 6 unified StitchFlow V1.2 report categories.
enum ReportCategory {
  dailyWorkshop,
  workerPerformance,
  processPerformance,
  inventory,
  labourFinancial,
  businessInsights,
}

/// IST-aligned quick date presets for reports.
enum ReportDatePreset {
  today,
  yesterday,
  thisWeek,
  thisMonth,
  previousMonth,
  allTime,
  custom,
}

/// Deterministic `Asia/Kolkata` (IST, UTC+05:30) date range boundary calculator.
abstract final class IstDateRangePresets {
  /// Returns `(fromUtcMillis, toUtcMillis)` for [preset] relative to [referenceUtcMillis].
  /// All day boundaries span `00:00:00.000 IST` through `23:59:59.999 IST`.
  static ({int? fromUtcMillis, int? toUtcMillis}) resolve(
    ReportDatePreset preset, {
    int? referenceUtcMillis,
  }) {
    final nowUtc = referenceUtcMillis ?? IstDateTimeHelper.nowUtcMillis();
    final ist = IstDateTimeHelper.fromUtcMillisToIst(nowUtc);

    switch (preset) {
      case ReportDatePreset.today:
        return _dayBounds(ist.year, ist.month, ist.day);
      case ReportDatePreset.yesterday:
        final y = tz.TZDateTime(
          IstDateTimeHelper.istLocation,
          ist.year,
          ist.month,
          ist.day - 1,
        );
        return _dayBounds(y.year, y.month, y.day);
      case ReportDatePreset.thisWeek:
        // Standard Indian business week: Monday (1) through Sunday (7)
        final daysFromMonday = ist.weekday - DateTime.monday;
        final mon = tz.TZDateTime(
          IstDateTimeHelper.istLocation,
          ist.year,
          ist.month,
          ist.day - daysFromMonday,
        );
        final sun = tz.TZDateTime(
          IstDateTimeHelper.istLocation,
          mon.year,
          mon.month,
          mon.day + 6,
        );
        return (
          fromUtcMillis: _startOfDay(mon.year, mon.month, mon.day),
          toUtcMillis: _endOfDay(sun.year, sun.month, sun.day),
        );
      case ReportDatePreset.thisMonth:
        final lastDay = tz.TZDateTime(
          IstDateTimeHelper.istLocation,
          ist.year,
          ist.month + 1,
          0,
        );
        return (
          fromUtcMillis: _startOfDay(ist.year, ist.month, 1),
          toUtcMillis: _endOfDay(lastDay.year, lastDay.month, lastDay.day),
        );
      case ReportDatePreset.previousMonth:
        final prevLast = tz.TZDateTime(
          IstDateTimeHelper.istLocation,
          ist.year,
          ist.month,
          0,
        );
        return (
          fromUtcMillis: _startOfDay(prevLast.year, prevLast.month, 1),
          toUtcMillis: _endOfDay(prevLast.year, prevLast.month, prevLast.day),
        );
      case ReportDatePreset.allTime:
      case ReportDatePreset.custom:
        return (fromUtcMillis: null, toUtcMillis: null);
    }
  }

  /// Returns the immediately preceding equal-length IST window for period-over-period
  /// comparisons. For calendar-month presets (`thisMonth` / `previousMonth`),
  /// aligns cleanly to the prior full calendar month.
  static ({int fromUtcMillis, int toUtcMillis})? previousWindow({
    required ReportDatePreset preset,
    required int? fromUtcMillis,
    required int? toUtcMillis,
  }) {
    if (fromUtcMillis == null || toUtcMillis == null) return null;
    if (toUtcMillis < fromUtcMillis) return null;

    if (preset == ReportDatePreset.thisMonth ||
        preset == ReportDatePreset.previousMonth) {
      final startIst = IstDateTimeHelper.fromUtcMillisToIst(fromUtcMillis);
      final prevLast = tz.TZDateTime(
        IstDateTimeHelper.istLocation,
        startIst.year,
        startIst.month,
        0,
      );
      return (
        fromUtcMillis: _startOfDay(prevLast.year, prevLast.month, 1),
        toUtcMillis: _endOfDay(prevLast.year, prevLast.month, prevLast.day),
      );
    }

    final spanMs = toUtcMillis - fromUtcMillis + 1;
    final prevTo = fromUtcMillis - 1;
    final prevFrom = prevTo - spanMs + 1;
    return (fromUtcMillis: prevFrom, toUtcMillis: prevTo);
  }

  static ({int fromUtcMillis, int toUtcMillis}) _dayBounds(
    int year,
    int month,
    int day,
  ) => (
    fromUtcMillis: _startOfDay(year, month, day),
    toUtcMillis: _endOfDay(year, month, day),
  );

  static int _startOfDay(int year, int month, int day) {
    return IstDateTimeHelper.istDateTimeToUtcMillis(
      year: year,
      month: month,
      day: day,
    );
  }

  static int _endOfDay(int year, int month, int day) {
    return IstDateTimeHelper.istDateTimeToUtcMillis(
          year: year,
          month: month,
          day: day,
          hour: 23,
          minute: 59,
          second: 59,
        ) +
        999;
  }

  /// Normalizes any UTC millis to the start (`00:00:00.000 IST`) of its IST day.
  static int startOfIstDay(int utcMillis) {
    final ist = IstDateTimeHelper.fromUtcMillisToIst(utcMillis);
    return _startOfDay(ist.year, ist.month, ist.day);
  }

  /// Normalizes any UTC millis to the end (`23:59:59.999 IST`) of its IST day.
  static int endOfIstDay(int utcMillis) {
    final ist = IstDateTimeHelper.fromUtcMillisToIst(utcMillis);
    return _endOfDay(ist.year, ist.month, ist.day);
  }
}

/// Unified filter criteria for all 6 report categories & exports.
final class ReportFilter {
  const ReportFilter({
    this.preset = ReportDatePreset.thisMonth,
    this.fromUtcMillis,
    this.toUtcMillis,
    this.workerId,
    this.processId,
    this.lotId,
    this.lotDesignId,
    this.designColourId,
    this.searchQuery = '',
    this.includeReversedInHistory = false,
    this.paymentMode,
    this.paymentType,
  });

  factory ReportFilter.forPreset(
    ReportDatePreset preset, {
    int? referenceUtcMillis,
  }) {
    final bounds = IstDateRangePresets.resolve(
      preset,
      referenceUtcMillis: referenceUtcMillis,
    );
    return ReportFilter(
      preset: preset,
      fromUtcMillis: bounds.fromUtcMillis,
      toUtcMillis: bounds.toUtcMillis,
    );
  }

  final ReportDatePreset preset;
  final int? fromUtcMillis;
  final int? toUtcMillis;
  final String? workerId;
  final String? processId;
  final String? lotId;
  final String? lotDesignId;
  final String? designColourId;
  final String searchQuery;
  final bool includeReversedInHistory;
  final PaymentMode? paymentMode;
  final PaymentType? paymentType;

  bool get hasDimensionFilters =>
      workerId != null ||
      processId != null ||
      lotId != null ||
      lotDesignId != null ||
      designColourId != null ||
      paymentMode != null ||
      paymentType != null ||
      searchQuery.trim().isNotEmpty;

  bool get hasAnyActiveFilter =>
      preset != ReportDatePreset.allTime || hasDimensionFilters;

  bool matchesTimestamp(int transactionAtUtcMillis) {
    if (fromUtcMillis != null && transactionAtUtcMillis < fromUtcMillis!) {
      return false;
    }
    if (toUtcMillis != null && transactionAtUtcMillis > toUtcMillis!) {
      return false;
    }
    return true;
  }

  ReportFilter copyWith({
    ReportDatePreset? preset,
    int? fromUtcMillis,
    int? toUtcMillis,
    String? workerId,
    String? processId,
    String? lotId,
    String? lotDesignId,
    String? designColourId,
    String? searchQuery,
    bool? includeReversedInHistory,
    PaymentMode? paymentMode,
    PaymentType? paymentType,
    bool clearFrom = false,
    bool clearTo = false,
    bool clearWorker = false,
    bool clearProcess = false,
    bool clearLot = false,
    bool clearDesign = false,
    bool clearColour = false,
    bool clearPaymentMode = false,
    bool clearPaymentType = false,
  }) {
    return ReportFilter(
      preset: preset ?? this.preset,
      fromUtcMillis: clearFrom ? null : (fromUtcMillis ?? this.fromUtcMillis),
      toUtcMillis: clearTo ? null : (toUtcMillis ?? this.toUtcMillis),
      workerId: clearWorker ? null : (workerId ?? this.workerId),
      processId: clearProcess ? null : (processId ?? this.processId),
      lotId: clearLot ? null : (lotId ?? this.lotId),
      lotDesignId: clearDesign ? null : (lotDesignId ?? this.lotDesignId),
      designColourId: clearColour
          ? null
          : (designColourId ?? this.designColourId),
      searchQuery: searchQuery ?? this.searchQuery,
      includeReversedInHistory:
          includeReversedInHistory ?? this.includeReversedInHistory,
      paymentMode: clearPaymentMode ? null : (paymentMode ?? this.paymentMode),
      paymentType: clearPaymentType ? null : (paymentType ?? this.paymentType),
    );
  }
}
