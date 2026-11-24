import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/widgets/app_dialog.dart';
import 'package:business_manager/core/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

/// Semantic tone for confirmation dialogs.
enum AppConfirmationTone { info, warning, destructive }

/// Dedicated reusable confirmation dialog helper built on frosted-glass [AppDialog].
///
/// Use for destructive or consequential business operations such as deleting,
/// cancelling, reversing stock/payments, returning stock, transferring stock,
/// completing processes, or confirming payments.
abstract final class AppConfirmationDialog {
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    String? consequenceNote,
    AppConfirmationTone tone = AppConfirmationTone.info,
    IconData? icon,
  }) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = switch (tone) {
      AppConfirmationTone.destructive =>
        isDark ? AppColors.darkDamaged : AppColors.lightDamaged,
      AppConfirmationTone.warning =>
        isDark ? AppColors.darkPending : AppColors.lightPending,
      AppConfirmationTone.info => AppColors.brandTeal,
    };
    final resolvedIcon =
        icon ??
        switch (tone) {
          AppConfirmationTone.destructive => Icons.warning_amber_rounded,
          AppConfirmationTone.warning => Icons.help_outline_rounded,
          AppConfirmationTone.info => Icons.info_outline_rounded,
        };

    final result = await AppDialog.showCustom<bool>(
      context,
      builder: (dialogCtx) => AppDialog(
        title: title,
        icon: resolvedIcon,
        iconColor: accent,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        isDestructive: tone == AppConfirmationTone.destructive,
        onConfirm: () => Navigator.of(dialogCtx).pop(true),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText(message),
            if (consequenceNote != null && consequenceNote.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: isDark ? 0.16 : 0.10),
                  borderRadius: AppRadius.mdBorder,
                  border: Border.all(
                    color: accent.withValues(alpha: isDark ? 0.35 : 0.25),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(resolvedIcon, size: 18, color: accent),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: AppText(
                        consequenceNote,
                        variant: AppTextVariant.bodySmall,
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
    return result == true;
  }
}
