import 'package:business_manager/core/platform/share_origin.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/platform/platform_env.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/backup/data/services/web_backup_restore_service.dart';
import 'package:business_manager/features/backup/domain/entities/backup_entities.dart';
import 'package:business_manager/features/backup/presentation/bloc/backup_restore_cubit.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:business_manager/features/security/presentation/widgets/security_reauth_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

final class BackupRestorePage extends StatelessWidget {
  const BackupRestorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BackupRestoreCubit>(
      create: (_) => getIt<BackupRestoreCubit>(),
      child: const _BackupRestoreView(),
    );
  }
}

final class _BackupRestoreView extends StatelessWidget {
  const _BackupRestoreView();

  Future<void> _shareFile(
    BuildContext context,
    BackupExportResult result,
  ) async {
    try {
      if (isDesktopPlatform) {
        // Desktop: let the user choose where to keep the backup (USB drive,
        // another disk) with a normal "Save as" dialog.
        final bytes = await XFile(result.filePath).readAsBytes();
        if (!context.mounted) return;
        final uri = await context.read<AppLockCubit>().runWithSystemPicker(
          () => FilePicker.saveFile(
            fileName: result.fileName,
            bytes: bytes,
            mimeType: 'application/zip',
          ),
        );
        if (uri != null && context.mounted) {
          AppFeedback.showInfo(
            context,
            uri.scheme == 'file' ? uri.toFilePath() : result.fileName,
          );
        }
        return;
      }
      await context.read<AppLockCubit>().runWithSystemPicker(
        () => SharePlus.instance.share(
          ShareParams(
            files: [XFile(result.filePath)],
            text: result.fileName,
            sharePositionOrigin: defaultShareOrigin(),
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        AppFeedback.showInfo(context, result.filePath);
      }
    }
  }

  Future<void> _pickAndInspectBackup(BuildContext context) async {
    final picked = await context.read<AppLockCubit>().runWithSystemPicker(
      () => FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: kIsWeb ? const ['json'] : const ['zip'],
      ),
    );
    if (picked.isEmpty || !context.mounted) return;
    final file = picked.first;
    final String? path;
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;
      path = WebBackupRestoreService.stagePickedBytes(
        bytes,
        fileName: file.name,
      );
    } else {
      path = file.path;
    }
    if (path == null || !context.mounted) return;
    await context.read<BackupRestoreCubit>().inspectBackupZip(path);
  }

  Future<void> _confirmAndRestore(
    BuildContext context,
    String zipPath,
    BackupManifest manifest,
  ) async {
    final l10n = context.l10n;
    final authed = await SecurityReauthDialog.verify(
      context,
      title: l10n.securityReauthRequiredTitle,
      subtitle: l10n.securityReauthRestoreSubtitle,
      allowBiometric: true,
    );
    if (!authed || !context.mounted) return;

    final confirmed = await AppDialog.showConfirmation(
      context,
      title: l10n.backupConfirmRestoreTitle,
      message:
          '${l10n.backupConfirmRestoreMessage}\n\n'
          '• ${manifest.createdAtIst}\n'
          '• Flavor: ${manifest.flavor} (Schema v${manifest.schemaVersion})\n'
          '• Lots: ${manifest.summaryCounts.lotsCount}, Workers: ${manifest.summaryCounts.workersCount}, '
          'Movements: ${manifest.summaryCounts.movementsCount}, Photos: ${manifest.attachmentsCount}',
      confirmLabel: l10n.backupConfirmRestoreAction,
      cancelLabel: l10n.actionCancel,
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<BackupRestoreCubit>().executeConfirmedRestore(zipPath);
  }

  Future<void> _exportRawSqliteWithAuth(BuildContext context) async {
    final l10n = context.l10n;
    final authed = await SecurityReauthDialog.verify(
      context,
      title: l10n.securityReauthRequiredTitle,
      subtitle: l10n.securityReauthRawSqliteSubtitle,
      allowBiometric: true,
    );
    if (!authed || !context.mounted) return;
    await context.read<BackupRestoreCubit>().exportRawSqlite();
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: l10n.backupHeading,
      contentWidth: AppContentWidth.narrow,
      body: BlocConsumer<BackupRestoreCubit, BackupRestoreState>(
        listener: (context, state) {
          if (state.status == BackupRestoreStatus.exportSuccess) {
            AppFeedback.showSuccess(context, l10n.backupExportSuccess);
          } else if (state.status == BackupRestoreStatus.restoreSuccess) {
            AppFeedback.showSuccess(context, l10n.backupRestoreSuccess);
          } else if (state.status == BackupRestoreStatus.error &&
              state.errorMessage != null) {
            AppFeedback.showError(context, state.errorMessage!);
          }
        },
        builder: (context, state) {
          final isWorking = state.status == BackupRestoreStatus.working;
          final validation = state.pendingValidation;

          return ListView(
            children: [
              // Branded Offline Safety Banner
              AppCard(
                gradient: isDark
                    ? AppColors.heroGradientDark
                    : AppColors.heroGradientLight,
                borderColor: Colors.white.withValues(alpha: 0.14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        AppIcons.shield,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.backupHeading,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.backupSubtitle,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (isWorking) ...[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppText(
                        l10n.backupProgressWorking,
                        fontWeight: FontWeight.w600,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppProgressBar(value: state.progress?.fraction),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),

              // 1. Full ZIP Backup
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(AppIcons.backup, size: 22),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppHeading(
                            l10n.backupCreateFullAction,
                            level: AppHeadingLevel.h3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      l10n.backupCreateFullDesc,
                      variant: AppTextVariant.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: l10n.backupCreateFullAction,
                      icon: AppIcons.backup,
                      isLoading: isWorking,
                      onPressed: () =>
                          context.read<BackupRestoreCubit>().createFullBackup(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 2. Atomic Validated Restore
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(AppIcons.restore, size: 22),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppHeading(
                            l10n.backupRestoreFullAction,
                            level: AppHeadingLevel.h3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      l10n.backupRestoreFullDesc,
                      variant: AppTextVariant.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: l10n.backupRestoreFullAction,
                      icon: AppIcons.folder,
                      variant: AppButtonVariant.secondary,
                      isLoading: isWorking,
                      onPressed: () => _pickAndInspectBackup(context),
                    ),
                    if (validation != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      const AppDivider(),
                      const SizedBox(height: AppSpacing.sm),
                      AppStatusBadge(
                        label: validation.isValid
                            ? l10n.backupValidationPassed
                            : l10n.backupValidationFailed,
                        tone: validation.isValid
                            ? AppStatusTone.good
                            : AppStatusTone.damaged,
                        icon: validation.isValid
                            ? AppIcons.success
                            : AppIcons.error,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (validation.isValid &&
                          validation.manifest != null) ...[
                        AppText(
                          '${validation.manifest!.createdAtIst} • Flavor: ${validation.manifest!.flavor} • Schema v${validation.manifest!.schemaVersion}',
                          variant: AppTextVariant.bodySmall,
                        ),
                        AppText(
                          'Lots: ${validation.manifest!.summaryCounts.lotsCount} • Workers: ${validation.manifest!.summaryCounts.workersCount} • Movements: ${validation.manifest!.summaryCounts.movementsCount} • Photos: ${validation.manifest!.attachmentsCount}',
                          variant: AppTextVariant.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          label: l10n.backupConfirmRestoreAction,
                          icon: AppIcons.warning,
                          variant: AppButtonVariant.destructive,
                          onPressed: state.pendingZipPath == null
                              ? null
                              : () => _confirmAndRestore(
                                  context,
                                  state.pendingZipPath!,
                                  validation.manifest!,
                                ),
                        ),
                      ] else
                        for (final err in validation.errors)
                          AppText(
                            '• $err',
                            color: Theme.of(context).colorScheme.error,
                            variant: AppTextVariant.bodySmall,
                          ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 3. Raw SQLite Inspection Export (Clearly Separated)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(AppIcons.storage, size: 22),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppHeading(
                            l10n.backupRawSqliteAction,
                            level: AppHeadingLevel.h3,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      l10n.backupRawSqliteDesc,
                      variant: AppTextVariant.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      label: l10n.backupRawSqliteAction,
                      icon: AppIcons.download,
                      variant: AppButtonVariant.outlined,
                      isLoading: isWorking,
                      onPressed: () => _exportRawSqliteWithAuth(context),
                    ),
                  ],
                ),
              ),

              // Last exported artifact details & Share button
              if (state.lastExport != null) ...[
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        l10n.backupLastCreatedLabel,
                        variant: AppTextVariant.label,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppText(
                        '${state.lastExport!.fileName} (${_formatSize(state.lastExport!.sizeBytes)})',
                        fontWeight: FontWeight.w700,
                      ),
                      AppText(
                        state.lastExport!.filePath,
                        variant: AppTextVariant.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: l10n.backupShareLastAction,
                        icon: AppIcons.share,
                        variant: AppButtonVariant.secondary,
                        onPressed: () => _shareFile(context, state.lastExport!),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),
              AppCard(
                elevated: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      l10n.backupLimitationsTitle,
                      variant: AppTextVariant.label,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      l10n.backupLimitationsBody,
                      variant: AppTextVariant.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
