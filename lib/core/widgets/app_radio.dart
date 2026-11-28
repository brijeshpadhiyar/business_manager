import 'package:business_manager/core/design_system/app_density.dart';
import 'package:material_ui/material_ui.dart';

/// Compact accessible radio option group using Flutter's `RadioGroup<T>` API.
final class AppRadioOption<T> {
  const AppRadioOption({
    required this.value,
    required this.label,
    this.subtitle,
  });

  final T value;
  final String label;
  final String? subtitle;
}

final class AppRadio<T> extends StatelessWidget {
  const AppRadio({
    super.key,
    required this.options,
    required this.groupValue,
    required this.onChanged,
    this.enabled = true,
  });

  final List<AppRadioOption<T>> options;
  final T? groupValue;
  final ValueChanged<T?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final d = context.density;
    return RadioGroup<T>(
      groupValue: groupValue,
      onChanged: (value) {
        if (enabled) onChanged(value);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: options
            .map(
              (option) => RadioListTile<T>(
                value: option.value,
                enabled: enabled,
                title: Text(option.label, style: textTheme.bodyMedium),
                subtitle: option.subtitle != null
                    ? Text(option.subtitle!, style: textTheme.bodySmall)
                    : null,
                dense: true,
                visualDensity: d.isCompact
                    ? VisualDensity.compact
                    : VisualDensity.standard,
                contentPadding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: d.radiusMdBorder),
              ),
            )
            .toList(),
      ),
    );
  }
}
