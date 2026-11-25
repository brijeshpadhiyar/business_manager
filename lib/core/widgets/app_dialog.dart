import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_shadows.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/widgets/app_button.dart';
import 'package:material_ui/material_ui.dart';

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
  });

  final String title;
  final Widget content;
  final IconData? icon;
  final Color? iconColor;
  final String? confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final bool isDestructive;

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
    // On phones (and narrow windows) the dialog becomes a full-width panel
    // anchored to the bottom edge: within thumb reach, above the keyboard,
    // and clear of the home indicator.
    final compact = AppBreakpoints.fromWidth(MediaQuery.sizeOf(context).width)
        .isCompact;
    final radius = compact
        ? const BorderRadius.vertical(top: Radius.circular(AppRadius.xl))
        : AppRadius.xlBorder;
    final bottomSafe = compact ? MediaQuery.viewPaddingOf(context).bottom : 0.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: compact
          ? EdgeInsets.only(top: MediaQuery.paddingOf(context).top + 24)
          : const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xl,
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
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                enabled: false, // v1.4 soft elevation: opaque surfaces
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.dialogGlassFill,
                    borderRadius: radius,
                    border: Border.all(color: tokens.glassBorder, width: 1.2),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      compact ? AppSpacing.lg : AppSpacing.xl,
                      AppSpacing.xl,
                      compact ? AppSpacing.lg : AppSpacing.xl,
                      AppSpacing.lg + bottomSafe,
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
                                size: 22,
                                color:
                                    iconColor ??
                                    (isDestructive
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.secondary),
                              ),
                              const SizedBox(width: AppSpacing.sm),
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
                        const SizedBox(height: AppSpacing.md),
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
                        const SizedBox(height: AppSpacing.xl),
                        Wrap(
                          alignment: WrapAlignment.end,
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            if (cancelLabel != null)
                              AppButton(
                                label: cancelLabel!,
                                variant: AppButtonVariant.text,
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                              ),
                            if (confirmLabel != null)
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
