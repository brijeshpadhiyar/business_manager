import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/auth/domain/entities/auth_entities.dart';
import 'package:business_manager/features/sync/domain/entities/sync_entities.dart';
import 'package:material_ui/material_ui.dart';

/// Smart Merge Prompt shown on first sign-in when both local offline records
/// and cloud records exist for the owner's account.
final class FirstLoginMergeDialog extends StatelessWidget {
  const FirstLoginMergeDialog({super.key, required this.summary});

  final FirstLoginMergeSummary summary;

  static Future<FirstLoginMergeChoice?> show(
    BuildContext context,
    FirstLoginMergeSummary summary,
  ) {
    return showDialog<FirstLoginMergeChoice>(
      context: context,
      barrierDismissible: false,
      builder: (_) => FirstLoginMergeDialog(summary: summary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      icon: Icon(AppIcons.merge, color: colorScheme.primary, size: 32),
      title: Text(l10n.syncMergeTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText(
              l10n.syncMergeSubtitle(
                summary.localRowCount,
                summary.cloudRowCount,
              ),
              variant: AppTextVariant.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l10n.syncMergeBothAction,
              icon: AppIcons.merge,
              isExpanded: true,
              onPressed: () =>
                  Navigator.of(context).pop(FirstLoginMergeChoice.mergeBoth),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              l10n.syncMergeBothDesc,
              variant: AppTextVariant.bodySmall,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l10n.syncKeepCloudAction,
              icon: AppIcons.download,
              variant: AppButtonVariant.secondary,
              isExpanded: true,
              onPressed: () => Navigator.of(
                context,
              ).pop(FirstLoginMergeChoice.keepCloudOnly),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              l10n.syncKeepCloudDesc,
              variant: AppTextVariant.bodySmall,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: l10n.syncKeepLocalAction,
              icon: AppIcons.cloudUpload,
              variant: AppButtonVariant.secondary,
              isExpanded: true,
              onPressed: () => Navigator.of(
                context,
              ).pop(FirstLoginMergeChoice.overwriteCloudWithLocal),
            ),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              l10n.syncKeepLocalDesc,
              variant: AppTextVariant.bodySmall,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
