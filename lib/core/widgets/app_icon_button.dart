import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:material_ui/material_ui.dart';

/// Accessible icon button enforcing `20dp` icon size, `48dp` touch target,
/// and mandatory localized [tooltip].
final class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.isFilled = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final constraints = const BoxConstraints(
      minWidth: AppSizing.touchTargetMin,
      minHeight: AppSizing.touchTargetMin,
    );
    final iconWidget = Icon(icon, size: AppSizing.iconMd, color: color);

    if (isFilled) {
      return IconButton.filledTonal(
        onPressed: onPressed,
        tooltip: tooltip,
        constraints: constraints,
        icon: iconWidget,
      );
    }

    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      constraints: constraints,
      icon: iconWidget,
    );
  }
}
