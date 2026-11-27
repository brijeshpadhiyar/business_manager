import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/widgets/date_time/app_date_time_dialogs.dart';
import 'package:business_manager/core/widgets/date_time/app_picker_field.dart';
import 'package:material_ui/material_ui.dart';

/// What [AppDatePicker] asks the user for.
enum AppDatePickMode {
  /// Calendar date only; stored as 12:00 IST of that day.
  date,

  /// Calendar date followed by a time of day.
  dateTime,
}

/// Date (or date+time) picker field. Shows values in `Asia/Kolkata` (IST) and
/// emits exact UTC epoch milliseconds to callers.
final class AppDatePicker extends StatelessWidget {
  const AppDatePicker({
    super.key,
    required this.label,
    required this.selectedUtcMillis,
    required this.onDateSelectedUtcMillis,
    this.mode,
    this.includeTime = false,
    this.hint,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.errorText,
    this.onCleared,
    this.selectableDayPredicate,
  });

  final String label;
  final int? selectedUtcMillis;
  final ValueChanged<int> onDateSelectedUtcMillis;

  /// Overrides [includeTime] when set.
  final AppDatePickMode? mode;

  /// Legacy shortcut for `mode: AppDatePickMode.dateTime`.
  final bool includeTime;
  final String? hint;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final String? errorText;

  /// When provided, a clear button is shown while a value is set.
  final VoidCallback? onCleared;

  /// Restricts which calendar days can be picked (date mode only).
  final bool Function(DateTime day)? selectableDayPredicate;

  AppDatePickMode get _mode =>
      mode ?? (includeTime ? AppDatePickMode.dateTime : AppDatePickMode.date);

  Future<void> _pick(BuildContext context) async {
    final Future<int?> request = _mode == AppDatePickMode.dateTime
        ? AppDateTimeDialogs.pickDateTime(
            context,
            initialUtcMillis: selectedUtcMillis,
            firstDate: firstDate,
            lastDate: lastDate,
          )
        : AppDateTimeDialogs.pickDate(
            context,
            initialUtcMillis: selectedUtcMillis,
            firstDate: firstDate,
            lastDate: lastDate,
            selectableDayPredicate: selectableDayPredicate,
          );
    final picked = await request;
    if (picked != null) onDateSelectedUtcMillis(picked);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final isDateTime = _mode == AppDatePickMode.dateTime;
    final value = selectedUtcMillis;
    final displayText = value == null
        ? ''
        : (isDateTime
              ? AppDateTimeFormatter.formatDateTime(value, locale: locale)
              : AppDateTimeFormatter.formatDate(value, locale: locale));

    return AppPickerField(
      label: label,
      displayText: displayText,
      icon: isDateTime ? AppIcons.time : AppIcons.date,
      hint: hint,
      errorText: errorText,
      enabled: enabled,
      onClear: onCleared,
      onTap: () => _pick(context),
    );
  }
}
