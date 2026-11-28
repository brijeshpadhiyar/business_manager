import 'dart:math' as math;

import 'package:business_manager/core/design_system/app_density.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:material_ui/material_ui.dart';

/// A selected IST time of day.
typedef AppTimeOfDay = ({int hour, int minute});

/// An inclusive IST date range in UTC epoch ms
/// (`start` = 00:00:00.000 IST, `end` = 23:59:59.999 IST).
typedef AppDateRange = ({int startUtcMillis, int endUtcMillis});

/// The single entry point for date/time picker dialogs.
///
/// Every method works in `Asia/Kolkata` (IST) wall-clock dates and returns
/// UTC epoch milliseconds, matching how the database stores instants.
/// Returns `null` when the user cancels.
///
/// This file (and the widgets in `core/widgets/date_time/`) is the only place
/// allowed to import `calendar_date_picker2` or call `showTimePicker`.
abstract final class AppDateTimeDialogs {
  static final DateTime _defaultFirst = DateTime(2000);
  static final DateTime _defaultLast = DateTime(2100);

  /// Picks one date. Returns 12:00 IST of the chosen day.
  static Future<int?> pickDate(
    BuildContext context, {
    int? initialUtcMillis,
    DateTime? firstDate,
    DateTime? lastDate,
    bool Function(DateTime day)? selectableDayPredicate,
  }) async {
    final picked = await _show(
      context,
      type: CalendarDatePicker2Type.single,
      value: [_istDay(initialUtcMillis ?? IstDateTimeHelper.nowUtcMillis())],
      firstDate: firstDate,
      lastDate: lastDate,
      selectableDayPredicate: selectableDayPredicate,
    );
    final day = picked?.firstOrNull;
    if (day == null) return null;
    return IstDateTimeHelper.istNoonUtcMillis(
      year: day.year,
      month: day.month,
      day: day.day,
    );
  }

  /// Picks a date then a time. Cancelling the time step keeps the previous
  /// (or current) time of day.
  static Future<int?> pickDateTime(
    BuildContext context, {
    int? initialUtcMillis,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final base = IstDateTimeHelper.fromUtcMillisToIst(
      initialUtcMillis ?? IstDateTimeHelper.nowUtcMillis(),
    );
    final picked = await _show(
      context,
      type: CalendarDatePicker2Type.single,
      value: [DateTime(base.year, base.month, base.day)],
      firstDate: firstDate,
      lastDate: lastDate,
    );
    final day = picked?.firstOrNull;
    if (day == null || !context.mounted) return null;

    final time = await pickTime(
      context,
      initial: (hour: base.hour, minute: base.minute),
    );
    return IstDateTimeHelper.istDateTimeToUtcMillis(
      year: day.year,
      month: day.month,
      day: day.day,
      hour: time?.hour ?? base.hour,
      minute: time?.minute ?? base.minute,
    );
  }

  /// Picks an inclusive date range. A single tapped day yields a one-day range.
  static Future<AppDateRange?> pickRange(
    BuildContext context, {
    int? startUtcMillis,
    int? endUtcMillis,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final picked = await _show(
      context,
      type: CalendarDatePicker2Type.range,
      value: [
        if (startUtcMillis != null) _istDay(startUtcMillis),
        if (startUtcMillis != null && endUtcMillis != null)
          _istDay(endUtcMillis),
      ],
      firstDate: firstDate,
      lastDate: lastDate,
    );
    final days = (picked ?? const <DateTime?>[]).nonNulls.toList();
    if (days.isEmpty) return null;
    days.sort();
    final start = days.first;
    final end = days.last;
    final startUtc = IstDateTimeHelper.istDateTimeToUtcMillis(
      year: start.year,
      month: start.month,
      day: start.day,
    );
    final endUtc = IstDateTimeHelper.endOfIstDayUtcMillis(
      IstDateTimeHelper.istNoonUtcMillis(
        year: end.year,
        month: end.month,
        day: end.day,
      ),
    );
    return (startUtcMillis: startUtc, endUtcMillis: endUtc);
  }

  /// Picks any number of separate dates. Each is 12:00 IST of its day,
  /// returned in ascending order.
  static Future<List<int>?> pickDates(
    BuildContext context, {
    List<int> initialUtcMillis = const [],
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final picked = await _show(
      context,
      type: CalendarDatePicker2Type.multi,
      value: initialUtcMillis.map(_istDay).toList(),
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked == null) return null;
    final result =
        picked.nonNulls
            .map(
              (d) => IstDateTimeHelper.istNoonUtcMillis(
                year: d.year,
                month: d.month,
                day: d.day,
              ),
            )
            .toSet()
            .toList()
          ..sort();
    return result;
  }

  /// Picks a time of day.
  static Future<AppTimeOfDay?> pickTime(
    BuildContext context, {
    AppTimeOfDay? initial,
  }) async {
    final now = IstDateTimeHelper.fromUtcMillisToIst(
      IstDateTimeHelper.nowUtcMillis(),
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initial?.hour ?? now.hour,
        minute: initial?.minute ?? now.minute,
      ),
    );
    if (picked == null) return null;
    return (hour: picked.hour, minute: picked.minute);
  }

  static DateTime _istDay(int utcMillis) {
    final ist = IstDateTimeHelper.fromUtcMillisToIst(utcMillis);
    return DateTime(ist.year, ist.month, ist.day);
  }

  static Future<List<DateTime?>?> _show(
    BuildContext context, {
    required CalendarDatePicker2Type type,
    required List<DateTime?> value,
    DateTime? firstDate,
    DateTime? lastDate,
    bool Function(DateTime day)? selectableDayPredicate,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final d = context.density;
    final size = MediaQuery.sizeOf(context);
    final width = math.min(size.width - (d.lg * 2), 400.0);

    final config = CalendarDatePicker2WithActionButtonsConfig(
      calendarType: type,
      firstDate: firstDate ?? _defaultFirst,
      lastDate: lastDate ?? _defaultLast,
      currentDate: _istDay(IstDateTimeHelper.nowUtcMillis()),
      // Indian business week starts on Monday.
      firstDayOfWeek: DateTime.monday,
      selectableDayPredicate: selectableDayPredicate,
      selectedDayHighlightColor: scheme.primary,
      selectedRangeHighlightColor: scheme.primaryContainer,
      selectedDayTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onPrimary,
        fontWeight: FontWeight.w600,
      ),
      selectedRangeDayTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onPrimaryContainer,
      ),
      dayTextStyle: text.bodyMedium,
      todayTextStyle: text.bodyMedium?.copyWith(
        color: scheme.primary,
        fontWeight: FontWeight.w700,
      ),
      disabledDayTextStyle: text.bodyMedium?.copyWith(
        color: scheme.onSurface.withValues(alpha: 0.38),
      ),
      weekdayLabelTextStyle: text.labelSmall?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      controlsTextStyle: text.titleSmall,
      dayBorderRadius: d.radiusMdBorder,
      okButtonTextStyle: text.labelLarge?.copyWith(color: scheme.primary),
      cancelButtonTextStyle: text.labelLarge?.copyWith(
        color: scheme.onSurfaceVariant,
      ),
      // Ranges: allow a single tap to mean a one-day range.
      allowSameValueSelection: type == CalendarDatePicker2Type.range,
    );

    return showCalendarDatePicker2Dialog(
      context: context,
      config: config,
      dialogSize: Size(width, d.isCompact ? 350 : 420),
      value: value,
      borderRadius: d.radiusXlBorder,
      dialogBackgroundColor: scheme.surfaceContainerHigh,
      useRootNavigator: true,
    );
  }
}
