import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:material_ui/material_ui.dart';

/// Compact accessible checkbox tile with optional subtitle.
final class AppCheckbox extends StatelessWidget {
  const AppCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  }) : _bare = false;

  /// Checkbox only (no label/tile) for custom rows that supply their own text.
  const AppCheckbox.bare({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  }) : label = '',
       subtitle = null,
       _bare = true;

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final bool enabled;
  final bool _bare;

  @override
  Widget build(BuildContext context) {
    if (_bare) {
      return Checkbox(value: value, onChanged: enabled ? onChanged : null);
    }
    return CheckboxListTile(
      value: value,
      onChanged: enabled ? onChanged : null,
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      subtitle: subtitle != null
          ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      dense: true,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
    );
  }
}
