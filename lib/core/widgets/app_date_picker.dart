import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Compact date (or date+time) picker field that displays values in
/// `Asia/Kolkata` (IST) and emits exact UTC epoch milliseconds to callers.
final class AppDatePicker extends StatelessWidget {
  const AppDatePicker({
    super.key,
    required this.label,
    required this.selectedUtcMillis,
    required this.onDateSelectedUtcMillis,
    this.includeTime = false,
    this.hint,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.errorText,
  });

  final String label;
  final int? selectedUtcMillis;
  final ValueChanged<int> onDateSelectedUtcMillis;
  final bool includeTime;
  final String? hint;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final String? errorText;

  Future<void> _pickDate(BuildContext context) async {
    final nowIst = IstDateTimeHelper.fromUtcMillisToIst(
      selectedUtcMillis ?? IstDateTimeHelper.nowUtcMillis(),
    );
    final initial = DateTime(nowIst.year, nowIst.month, nowIst.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime(2100),
    );
    if (picked == null) return;

    if (includeTime) {
      if (!context.mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: nowIst.hour, minute: nowIst.minute),
      );
      final hour = pickedTime?.hour ?? nowIst.hour;
      final minute = pickedTime?.minute ?? nowIst.minute;
      final utcMillis = IstDateTimeHelper.istDateTimeToUtcMillis(
        year: picked.year,
        month: picked.month,
        day: picked.day,
        hour: hour,
        minute: minute,
      );
      onDateSelectedUtcMillis(utcMillis);
      return;
    }

    final utcMillis = IstDateTimeHelper.istDateTimeToUtcMillis(
      year: picked.year,
      month: picked.month,
      day: picked.day,
      hour: 12,
    );
    onDateSelectedUtcMillis(utcMillis);
  }

  @override
  Widget build(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final displayText = selectedUtcMillis != null
        ? (includeTime
              ? AppDateTimeFormatter.formatDateTime(
                  selectedUtcMillis!,
                  locale: localeCode,
                )
              : AppDateTimeFormatter.formatDate(
                  selectedUtcMillis!,
                  locale: localeCode,
                ))
        : '';

    return InkWell(
      onTap: enabled ? () => _pickDate(context) : null,
      child: InputDecorator(
        isEmpty: displayText.isEmpty,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: errorText,
          enabled: enabled,
          suffixIcon: Icon(
            includeTime ? AppIcons.time : AppIcons.date,
            size: AppSizing.iconMd,
          ),
        ),
        child: Text(
          displayText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}
