import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_density.dart';
import 'package:business_manager/core/design_system/app_glass_quality.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_shadows.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/widgets/app_button.dart';
import 'package:material_ui/material_ui.dart';

/// One button of [AppDialog.showChoices]; tapping it pops [value].
final class AppDialogAction<T> {
  const AppDialogAction({
    required this.label,
    required this.value,
    this.variant = AppButtonVariant.text,
  });

  final String label;
  final T value;
  final AppButtonVariant variant;
}

/// Adaptive Material 3 frosted-glass dialog helper with BackdropFilter blur,
/// specular highlight, smooth fade-scale entrance, max-width constraint, and
/// consistent actions.
final class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.content,
    this.icon,
    this.iconColor,
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirm,
    this.isDestructive = false,
    this.actions,
  });

  final String title;
  final Widget content;
  final IconData? icon;
  final Color? iconColor;
  final String? confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final bool isDestructive;

  /// Custom action buttons; replaces the cancel/confirm pair when set.
  final List<Widget>? actions;

  /// Dialog with any number of outcomes. Returns the tapped action's value,
  /// or `null` when dismissed.
  static Future<T?> showChoices<T>(
    BuildContext context, {
    required String title,
    required String message,
    required List<AppDialogAction<T>> choices,
    IconData? icon,
    bool barrierDismissible = true,
  }) {
    return showCustom<T>(
      context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => AppDialog(
        title: title,
        icon: icon,
        content: Text(message),
        actions: [
          for (final c in choices)
            AppButton(
              label: c.label,
              variant: c.variant,
              onPressed: () => Navigator.of(dialogContext).pop(c.value),
            ),
        ],
      ),
    );
  }

  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    bool isDestructive = false,
  }) {
    final reduce = AppMotion.reduceMotion(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModal<bool>(
      context: context,
      configuration: FadeScaleTransitionConfiguration(
        barrierColor: Colors.black.withValues(alpha: isDark ? 0.56 : 0.34),
        transitionDuration: reduce
            ? Duration.zero
            : const Duration(milliseconds: 200),
        reverseTransitionDuration: reduce
            ? Duration.zero
            : const Duration(milliseconds: 150),
      ),
      builder: (dialogContext) => AppDialog(
        title: title,
        content: Text(message),
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: isDestructive,
        onConfirm: () => Navigator.of(dialogContext).pop(true),
      ),
    );
  }

  static Future<T?> showCustom<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    bool barrierDismissible = true,
  }) {
    final reduce = AppMotion.reduceMotion(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return showModal<T>(
      context: context,
      configuration: FadeScaleTransitionConfiguration(
        barrierDismissible: barrierDismissible,
        barrierColor: Colors.black.withValues(alpha: isDark ? 0.56 : 0.34),
        transitionDuration: reduce
            ? Duration.zero
            : const Duration(milliseconds: 200),
        reverseTransitionDuration: reduce
            ? Duration.zero
            : const Duration(milliseconds: 150),
      ),
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.surfaceTokens;
    final theme = Theme.of(context);
    final d = context.density;
    // On phones (and narrow windows) the dialog becomes a full-width panel
    // anchored to the bottom edge: within thumb reach, above the keyboard,
    // and clear of the home indicator.
    final compact = AppBreakpoints.fromWidth(MediaQuery.sizeOf(context).width)
        .isCompact;
    final radius = compact
        ? BorderRadius.vertical(top: Radius.circular(d.radiusXl))
        : d.radiusXlBorder;
    final bottomSafe = compact ? MediaQuery.viewPaddingOf(context).bottom : 0.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: compact
          ? EdgeInsets.only(
              top: MediaQuery.paddingOf(context).top + (d.isCompact ? 12 : 24),
            )
          : EdgeInsets.symmetric(
              horizontal: d.lg,
              vertical: d.xl,
            ),
      alignment: compact ? Alignment.bottomCenter : null,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: compact ? double.infinity : AppSizing.maxDialogWidth,
          minWidth: compact ? MediaQuery.sizeOf(context).width : 0,
        ),
        child: RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: AppShadows.of(context).xl,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: AppGlassQuality.resolve(context).chromeBlurSigma,
                  sigmaY: AppGlassQuality.resolve(context).chromeBlurSigma,
                ),
                enabled: AppGlassQuality.resolve(context).enableBackdropBlur,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.dialogGlassFill,
                    borderRadius: radius,
                    border: Border.all(color: tokens.glassBorder, width: 1.2),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? d.lg : d.dialogPadding,
                      d.dialogPadding,
                      compact ? d.lg : d.dialogPadding,
                      d.lg + bottomSafe,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (icon != null) ...[
                              Icon(
                                icon,
                                size: d.iconMd + 2,
                                color:
                                    iconColor ??
                                    (isDestructive
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.secondary),
                              ),
                              SizedBox(width: d.sm),
                            ],
                            Expanded(
                              child: Text(
                                title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: d.md),
                        Flexible(
                          child: SingleChildScrollView(
                            child: DefaultTextStyle(
                              style:
                                  theme.textTheme.bodyMedium ??
                                  const TextStyle(fontSize: 14),
                              child: content,
                            ),
                          ),
                        ),
                        SizedBox(height: d.xl),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: d.sm,
                          runSpacing: d.sm,
                          children: [
                            ...?actions,
                            if (actions == null && cancelLabel != null)
                              AppButton(
                                label: cancelLabel!,
                                variant: AppButtonVariant.text,
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                              ),
                            if (actions == null && confirmLabel != null)
                              AppButton(
                                label: confirmLabel!,
                                variant: isDestructive
                                    ? AppButtonVariant.destructive
                                    : AppButtonVariant.primary,
                                onPressed:
                                    onConfirm ??
                                    () => Navigator.of(context).pop(true),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
