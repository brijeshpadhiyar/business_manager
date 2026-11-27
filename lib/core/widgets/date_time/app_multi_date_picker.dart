import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/widgets/app_chip.dart';
import 'package:business_manager/core/widgets/date_time/app_date_time_dialogs.dart';
import 'package:business_manager/core/widgets/date_time/app_picker_field.dart';
import 'package:material_ui/material_ui.dart';

/// Picks several separate dates (e.g. holidays, non-working days).
///
/// Values are 12:00 IST of each day in UTC epoch ms, ascending. Selected dates
/// are listed as removable chips under the field.
final class AppMultiDatePicker extends StatelessWidget {
  const AppMultiDatePicker({
    super.key,
    required this.label,
    required this.valuesUtcMillis,
    required this.onChanged,
    this.hint,
    this.errorText,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
  });

  final String label;
  final List<int> valuesUtcMillis;
  final ValueChanged<List<int>> onChanged;
  final String? hint;
  final String? errorText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final picked = await AppDateTimeDialogs.pickDates(
      context,
      initialUtcMillis: valuesUtcMillis,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final count = valuesUtcMillis.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppPickerField(
          label: label,
          displayText: count == 0
              ? ''
              : AppDateTimeFormatter.formatDate(
                      valuesUtcMillis.first,
                      locale: locale,
                    ) +
                    (count > 1 ? '  +${count - 1}' : ''),
          icon: AppIcons.date,
          hint: hint,
          errorText: errorText,
          enabled: enabled,
          onClear: count == 0 ? null : () => onChanged(const []),
          onTap: () => _pick(context),
        ),
        if (count > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final v in valuesUtcMillis)
                AppChip.input(
                  label: AppDateTimeFormatter.formatDate(v, locale: locale),
                  enabled: enabled,
                  onDeleted: () =>
                      onChanged(valuesUtcMillis.where((x) => x != v).toList()),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
