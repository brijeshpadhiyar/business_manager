import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

enum AppButtonVariant { primary, secondary, outlined, destructive, text }

/// Touch-friendly Material 3 button with variants, icon, disabled, loading,
/// graceful bilingual wrapping (English & Gujarati), and subtle tactile feedback.
final class AppButton extends StatefulWidget {
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
  State<AppButton> createState() => _AppButtonState();
}

final class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveOnPressed = widget.isLoading ? null : widget.onPressed;

    final Widget content = Row(
      mainAxisSize: widget.isExpanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.isLoading) ...[
          SizedBox(
            width: AppSizing.iconSm,
            height: AppSizing.iconSm,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: switch (widget.variant) {
                AppButtonVariant.primary => colorScheme.onPrimary,
                AppButtonVariant.secondary => colorScheme.onSecondaryContainer,
                AppButtonVariant.destructive => colorScheme.onError,
                AppButtonVariant.outlined ||
                AppButtonVariant.text => colorScheme.primary,
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ] else if (widget.icon != null) ...[
          Icon(widget.icon, size: AppSizing.iconMd),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            softWrap: true,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    final minSize = Size(
      widget.isExpanded ? double.infinity : 0,
      AppSizing.buttonHeight,
    );
    const shape = RoundedRectangleBorder(borderRadius: AppRadius.mdBorder);
    const padding = EdgeInsets.symmetric(
      horizontal: AppSpacing.md + 2,
      vertical: 10,
    );

    final button = switch (widget.variant) {
      AppButtonVariant.primary => FilledButton(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        child: content,
      ),
      AppButtonVariant.secondary => FilledButton.tonal(
        onPressed: effectiveOnPressed,
        style: FilledButton.styleFrom(
          minimumSize: minSize,
          padding: padding,
          shape: shape,
          tapTargetSize: MaterialTapTargetSize.padded,
        ),
        child: content,
      ),
      AppButtonVariant.outlined => OutlinedButton(
        onPressed: effectiveOnPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: minSize,
          padding: padding,
          shape: shape,
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

    if (effectiveOnPressed == null || AppMotion.reduceMotion(context)) {
      return button;
    }

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: button,
      ),
    );
  }
}
