import 'package:business_manager/core/design_system/app_density.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:material_ui/material_ui.dart';
import 'package:motor/motor.dart';

/// Compact accessible Material 3 switch tile with subtle spring micro-motion.
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
    final d = context.density;
    return SingleMotionBuilder(
      value: value ? 1.0 : 0.992,
      from: value ? 1.0 : 0.992,
      motion: AppMotion.spring(context, AppMotion.snappySpring),
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: SwitchListTile(
        value: value,
        onChanged: enabled ? onChanged : null,
        title: Text(label, style: textTheme.bodyMedium),
        subtitle: subtitle != null
            ? Text(subtitle!, style: textTheme.bodySmall)
            : null,
        dense: true,
        visualDensity: d.isCompact
            ? VisualDensity.compact
            : VisualDensity.standard,
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: d.radiusMdBorder),
      ),
    );
  }
}
