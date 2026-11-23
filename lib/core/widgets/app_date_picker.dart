import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:material_ui/material_ui.dart';

/// Compact date picker field that displays selected date in `Asia/Kolkata` (IST)
/// and emits UTC epoch milliseconds to callers.
final class AppDatePicker extends StatelessWidget {
  const AppDatePicker({
    super.key,
    required this.label,
    required this.selectedUtcMillis,
    required this.onDateSelectedUtcMillis,
    this.hint,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.errorText,
  });

  final String label;
  final int? selectedUtcMillis;
  final ValueChanged<int> onDateSelectedUtcMillis;
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
    final utcMillis = DateTime.utc(
      picked.year,
      picked.month,
      picked.day,
    ).millisecondsSinceEpoch;
    onDateSelectedUtcMillis(utcMillis);
  }

  @override
  Widget build(BuildContext context) {
    final displayText = selectedUtcMillis != null
        ? IstDateTimeHelper.toIstBusinessDate(selectedUtcMillis!)
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
          suffixIcon: const Icon(Icons.calendar_today, size: AppSizing.iconMd),
        ),
        child: Text(displayText, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
