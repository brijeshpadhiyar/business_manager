import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_density.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/widgets/app_icon_pop.dart';
import 'package:material_ui/material_ui.dart';

/// Accessible icon button enforcing `20dp` icon size, `48dp` touch target
/// (scaled down in compact density), mandatory localized [tooltip], glass
/// styling, and tactile press feedback.
final class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.isFilled = false,
    this.compact = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isFilled;

  /// Smaller 18dp icon with no inner padding for dense rows (e.g. on
  /// swatches).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tokens = context.surfaceTokens;
    final d = context.density;
    final useTight = compact || d.isCompact;
    final target = d.touchTargetMin;
    final constraints = useTight
        ? BoxConstraints.tightFor(width: target, height: target)
        : BoxConstraints(minWidth: target, minHeight: target);
    final iconWidget = AppIconPop(
      child: Icon(
        icon,
        size: compact ? d.iconSm + 2 : d.iconMd,
        color: color,
      ),
    );
    final padding = useTight ? EdgeInsets.zero : null;
    final tapTarget = d.isCompact
        ? MaterialTapTargetSize.shrinkWrap
        : MaterialTapTargetSize.padded;

    final button = isFilled
        ? IconButton.filledTonal(
            onPressed: onPressed,
            tooltip: tooltip,
            constraints: constraints,
            padding: padding,
            style: IconButton.styleFrom(
              backgroundColor: tokens.glassFill,
              side: BorderSide(color: tokens.glassBorder, width: 0.9),
              tapTargetSize: tapTarget,
            ),
            icon: iconWidget,
          )
        : IconButton(
            onPressed: onPressed,
            tooltip: tooltip,
            constraints: constraints,
            padding: padding,
            style: IconButton.styleFrom(tapTargetSize: tapTarget),
            icon: iconWidget,
          );

    // MergeSemantics: one node for screen readers (label + the IconButton's
    // button/focus flags) instead of two nested buttons.
    return MergeSemantics(
      child: Semantics(
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
      ),
    );
  }
}
