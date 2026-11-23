import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:material_ui/material_ui.dart';

/// Compact accessible Material 3 switch tile.
final class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.enabled = true,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SwitchListTile(
      value: value,
      onChanged: enabled ? onChanged : null,
      title: Text(label, style: textTheme.bodyMedium),
      subtitle: subtitle != null
          ? Text(subtitle!, style: textTheme.bodySmall)
          : null,
      dense: true,
      contentPadding: EdgeInsets.zero,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
    );
  }
}
