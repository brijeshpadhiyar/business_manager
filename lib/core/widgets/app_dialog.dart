import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
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
        transitionDuration: reduce ? Duration.zero : AppMotion.normal,
        reverseTransitionDuration: reduce ? Duration.zero : AppMotion.fast,
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
        transitionDuration: reduce ? Duration.zero : AppMotion.normal,
        reverseTransitionDuration: reduce ? Duration.zero : AppMotion.fast,
      ),
      builder: builder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.surfaceTokens;
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizing.maxDialogWidth),
        child: RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.xlBorder,
              boxShadow: [
                BoxShadow(
                  color: tokens.cardShadow,
                  blurRadius: 32,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadius.xlBorder,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.dialogGlassFill,
                    borderRadius: AppRadius.xlBorder,
                    border: Border.all(color: tokens.glassBorder, width: 1.2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.xl,
                      AppSpacing.xl,
                      AppSpacing.lg,
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
