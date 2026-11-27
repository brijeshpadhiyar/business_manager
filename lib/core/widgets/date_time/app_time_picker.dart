import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/widgets/date_time/app_date_time_dialogs.dart';
import 'package:business_manager/core/widgets/date_time/app_picker_field.dart';
import 'package:material_ui/material_ui.dart';

/// Time-of-day picker field (hour + minute, no date).
///
/// Shows the time using the platform/locale 12h or 24h convention.
final class AppTimePicker extends StatelessWidget {
  const AppTimePicker({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.onCleared,
    this.hint,
    this.errorText,
    this.enabled = true,
  });

  final String label;
  final AppTimeOfDay? value;
  final ValueChanged<AppTimeOfDay> onChanged;
  final VoidCallback? onCleared;
  final String? hint;
  final String? errorText;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final picked = await AppDateTimeDialogs.pickTime(context, initial: value);
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final v = value;
    final display = v == null
        ? ''
        : MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay(hour: v.hour, minute: v.minute),
            alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
          );

    return AppPickerField(
      label: label,
      displayText: display,
      icon: AppIcons.time,
      hint: hint,
      errorText: errorText,
      enabled: enabled,
      onClear: onCleared,
      onTap: () => _pick(context),
    );
  }
}
