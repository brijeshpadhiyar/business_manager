import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:material_ui/material_ui.dart';
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
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.surfaceTokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveOnPressed = isLoading ? null : onPressed;

    final Widget leadingWidget;
    if (isLoading) {
      leadingWidget = SizedBox(
        key: const ValueKey<String>('loading'),
        width: AppSizing.iconSm,
        height: AppSizing.iconSm,
        child: AppSpinner(
          size: AppSizing.iconSm,
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
      leadingWidget = Icon(
        icon,
        key: ValueKey<IconData>(icon!),
        size: AppSizing.iconMd,
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
          const SizedBox(width: AppSpacing.sm),
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
      AppSizing.buttonHeight,
    );
    const shape = RoundedRectangleBorder(borderRadius: AppRadius.mdBorder);
    const padding = EdgeInsets.symmetric(
      horizontal: AppSpacing.md + 2,
      vertical: 10,
    );

    final button = switch (variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          elevation: 2,
          shadowColor: colorScheme.primary.withValues(alpha: 0.28),
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        child: content,
      ),
      AppButtonVariant.secondary => FilledButton.tonal(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          minimumSize: minSize,
          padding: padding,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.mdBorder,
            side: BorderSide(color: tokens.glassBorder, width: 0.9),
          ),
          backgroundColor: colorScheme.secondaryContainer.withValues(
            alpha: isDark ? 0.72 : 0.82,
          ),
          tapTargetSize: MaterialTapTargetSize.padded,
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
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        child: content,
      ),
      AppButtonVariant.destructive => FilledButton(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          tapTargetSize: MaterialTapTargetSize.padded,
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
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        child: content,
      ),
    };

    return AppPressable(
      enabled: effectiveOnPressed != null,
      pressedScale: 0.96,
      child: button,
    );
  }
}
