import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/widgets/app_icon_pop.dart';
import 'package:material_ui/material_ui.dart';

/// Accessible icon button enforcing `20dp` icon size, `48dp` touch target,
/// mandatory localized [tooltip], glass styling, and tactile press feedback.
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
    final tokens = context.surfaceTokens;
    const constraints = BoxConstraints(
      minWidth: AppSizing.touchTargetMin,
      minHeight: AppSizing.touchTargetMin,
    );
    final iconWidget = AppIconPop(
      child: Icon(icon, size: AppSizing.iconMd, color: color),
    );

    final button = isFilled
        ? IconButton.filledTonal(
            onPressed: onPressed,
            tooltip: tooltip,
            constraints: constraints,
            style: IconButton.styleFrom(
              backgroundColor: tokens.glassFill,
              side: BorderSide(color: tokens.glassBorder, width: 0.9),
            ),
            icon: iconWidget,
          )
        : IconButton(
            onPressed: onPressed,
            tooltip: tooltip,
            constraints: constraints,
            icon: iconWidget,
          );

    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: tooltip,
      child: AppIconPopHost(
        enabled: onPressed != null,
        child: AppPressable(
          enabled: onPressed != null,
          pressedScale: 0.92,
          child: button,
        ),
      ),
    );
  }
}
