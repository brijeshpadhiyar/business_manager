import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/widgets/app_chip.dart';
import 'package:business_manager/core/widgets/date_time/app_date_time_dialogs.dart';
import 'package:business_manager/core/widgets/date_time/app_picker_field.dart';
import 'package:material_ui/material_ui.dart';

/// A named quick range shown as a chip above [AppDateRangePicker].
final class AppDateRangePreset {
  const AppDateRangePreset({
    required this.label,
    required this.resolve,
    this.selected = false,
  });

  final String label;

  /// Computes the range at tap time (so "Today" is always today).
  final AppDateRange Function() resolve;

  /// Whether this preset is the currently applied one.
  final bool selected;
}

/// One field for an inclusive IST date range ("From – To").
///
/// Replaces pairs of from/to [AppDatePicker]s. The emitted range spans
/// `00:00:00.000 IST` of the first day through `23:59:59.999 IST` of the last.
final class AppDateRangePicker extends StatelessWidget {
  const AppDateRangePicker({
    super.key,
    required this.label,
    required this.startUtcMillis,
    required this.endUtcMillis,
    required this.onChanged,
    this.onCleared,
    this.presets = const [],
    this.hint,
    this.errorText,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
  });

  final String label;
  final int? startUtcMillis;
  final int? endUtcMillis;
  final ValueChanged<AppDateRange> onChanged;

  /// When provided, a clear button is shown while a range is set.
  final VoidCallback? onCleared;

  /// Optional quick ranges rendered as a scrollable chip row.
  final List<AppDateRangePreset> presets;
  final String? hint;
  final String? errorText;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final range = await AppDateTimeDialogs.pickRange(
      context,
      startUtcMillis: startUtcMillis,
      endUtcMillis: endUtcMillis,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (range != null) onChanged(range);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    String fmt(int? v) =>
        v == null ? '' : AppDateTimeFormatter.formatDate(v, locale: locale);
    final start = fmt(startUtcMillis);
    final end = fmt(endUtcMillis);
    final display = (start.isEmpty && end.isEmpty)
        ? ''
        : (start == end ? start : '$start – $end');

    final field = AppPickerField(
      label: label,
      displayText: display,
      icon: AppIcons.date,
      hint: hint,
      errorText: errorText,
      enabled: enabled,
      onClear: onCleared,
      onTap: () => _pick(context),
    );

    if (presets.isEmpty) return field;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final p in presets) ...[
                AppChip(
                  label: p.label,
                  selected: p.selected,
                  enabled: enabled,
                  onSelected: (_) => onChanged(p.resolve()),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        field,
      ],
    );
  }
}
