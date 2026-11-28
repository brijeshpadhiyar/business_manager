import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_density.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/widgets/app_icon_pop.dart';
import 'package:business_manager/core/widgets/app_loader.dart';

enum AppButtonVariant { primary, secondary, outlined, destructive, text }

/// Touch-friendly Material 3 glass-compatible button with variants, icon,
/// disabled, smooth AnimatedSwitcher loading state, bilingual wrapping, and
/// tactile press-scale feedback.
final class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
    this.foregroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;

  /// Overrides the label and icon colour of the [AppButtonVariant.text] and
  /// [AppButtonVariant.outlined] variants, for buttons drawn on a fixed dark
  /// or coloured surface (such as the lock screen).
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.surfaceTokens;
    final d = context.density;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveOnPressed = isLoading ? null : onPressed;

    final Widget leadingWidget;
    if (isLoading) {
      leadingWidget = SizedBox(
        key: const ValueKey<String>('loading'),
        width: d.iconSm,
        height: d.iconSm,
        child: AppSpinner(
          size: d.iconSm,
          strokeWidth: 2,
          color: switch (variant) {
            AppButtonVariant.primary => colorScheme.onPrimary,
            AppButtonVariant.secondary => colorScheme.onSecondaryContainer,
            AppButtonVariant.destructive => colorScheme.onError,
            AppButtonVariant.outlined ||
            AppButtonVariant.text => colorScheme.primary,
          },
        ),
      );
    } else if (icon != null) {
      leadingWidget = AppIconPop(
        key: ValueKey<IconData>(icon!),
        child: Icon(icon, size: d.iconMd),
      );
    } else {
      leadingWidget = const SizedBox.shrink(key: ValueKey<String>('none'));
    }

    final Widget content = Row(
      mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading || icon != null) ...[
          AnimatedSwitcher(
            duration: AppMotion.duration(context, AppMotion.fast),
            child: leadingWidget,
          ),
          SizedBox(width: d.sm),
        ],
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final minSize = Size(
      isExpanded ? double.infinity : 0,
      d.buttonHeight,
    );
    final shape = RoundedRectangleBorder(borderRadius: d.radiusMdBorder);
    final padding = d.buttonPadding;
    final tapTarget = d.isCompact
        ? MaterialTapTargetSize.shrinkWrap
        : MaterialTapTargetSize.padded;

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          elevation: 2,
          shadowColor: colorScheme.primary.withValues(alpha: 0.28),
          tapTargetSize: tapTarget,
        ),
        child: content,
      ),
      AppButtonVariant.secondary => FilledButton.tonal(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          minimumSize: minSize,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: d.radiusMdBorder,
            side: BorderSide(color: tokens.glassBorder, width: 0.9),
          ),
          backgroundColor: colorScheme.secondaryContainer.withValues(
            alpha: isDark ? 0.72 : 0.82,
          ),
          tapTargetSize: tapTarget,
        ),
        child: content,
      ),
      AppButtonVariant.outlined => OutlinedButton(
        onPressed: effectiveOnPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: minSize,
          padding: padding,
          backgroundColor: tokens.glassFill,
          shape: shape,
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
          foregroundColor: foregroundColor,
          tapTargetSize: tapTarget,
        ),
        child: content,
      ),
      AppButtonVariant.destructive => FilledButton(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          tapTargetSize: tapTarget,
          backgroundColor: colorScheme.error,
          foregroundColor: colorScheme.onError,
        ),
        child: content,
      ),
      AppButtonVariant.text => TextButton(
        onPressed: effectiveOnPressed,
        style: TextButton.styleFrom(
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          foregroundColor: foregroundColor,
          tapTargetSize: tapTarget,
        ),
        child: content,
      ),
    };

    return AppIconPopHost(
      enabled: effectiveOnPressed != null,
      child: AppPressable(
        enabled: effectiveOnPressed != null,
        pressedScale: 0.96,
        child: button,
      ),
    );
  }
}
