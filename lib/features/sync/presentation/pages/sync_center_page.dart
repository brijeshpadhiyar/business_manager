import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:business_manager/features/sync/domain/entities/sync_entities.dart';
import 'package:business_manager/features/sync/presentation/bloc/sync_cubit.dart';
import 'package:business_manager/features/sync/presentation/widgets/first_login_merge_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Dedicated Settings → Cloud Sync Center screen showing live connectivity,
/// last synced IST timestamp, pending outbox & media queue counts, manual
/// "Sync Now", first-login merge prompt, and failed-item retry.
final class SyncCenterPage extends StatelessWidget {
  const SyncCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: l10n.syncCenterTitle,
      constrainMaxWidth: false,
      padding: EdgeInsets.zero,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizing.narrowContentWidth,
          ),
          child: BlocConsumer<SyncCubit, SyncState>(
            listener: (context, state) async {
              final conflictsResolved =
                  state.lastSummary?.conflictsResolved ?? 0;
              if (conflictsResolved > 0 && state.unresolvedConflictCount > 0) {
                AppFeedback.showWarning(
                  context,
                  l10n.syncConflictsDetectedBanner(
                    state.unresolvedConflictCount,
                  ),
                );
              }
              if (state.phase == SyncPhase.awaitingMergeChoice &&
                  state.pendingMergeSummary != null) {
                final choice = await FirstLoginMergeDialog.show(
                  context,
                  state.pendingMergeSummary!,
                );
                if (choice != null && context.mounted) {
                  await context.read<SyncCubit>().resolveFirstLoginMerge(
                    choice,
                  );
                }
              }
            },
            builder: (context, state) {
              final authState = context.watch<AuthCubit>().state;
              final isSyncing = state.phase == SyncPhase.syncing;
              final d = context.density;

              return ListView(
                padding: d.screenAll,
                children: [
                  AppHeading(
                    l10n.syncCenterTitle,
                    level: AppHeadingLevel.h2,
                    subtitle: l10n.syncCenterSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (!authState.isAuthenticated) ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppText(
                            l10n.authSignInPromptCardSubtitle,
                            variant: AppTextVariant.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            label: l10n.authSignInHeading,
                            icon: AppIcons.signIn,
                            isExpanded: true,
                            onPressed: () => context.push(RoutePaths.authLogin),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                state.isOnline
                                    ? (isSyncing
                                          ? AppIcons.cloudSync
                                          : AppIcons.cloudDone)
                                    : AppIcons.cloudOff,
                                size: 32,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText(
                                      switch (state.phase) {
                                        SyncPhase.synced =>
                                          l10n.syncStatusSynced,
                                        SyncPhase.syncing =>
                                          l10n.syncStatusSyncing,
                                        SyncPhase.offline =>
                                          l10n.syncStatusOffline,
                                        SyncPhase.needsAttention =>
                                          l10n.syncStatusNeedsAttention,
                                        SyncPhase.awaitingMergeChoice =>
                                          l10n.syncMergeTitle,
                                        SyncPhase.localOnly =>
                                          l10n.syncStatusLocalOnly,
                                      },
                                      variant: AppTextVariant.bodyLarge,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    AppText(
                                      '${l10n.syncLastSyncedLabel}: '
                                      '${state.lastSyncedAtUtcMillis != null ? IstDateTimeHelper.formatIstDateTime(state.lastSyncedAtUtcMillis!) : l10n.syncNeverSynced}',
                                      variant: AppTextVariant.bodySmall,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const AppDivider(height: AppSpacing.lg),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText(
                                l10n.syncPendingRowsLabel,
                                variant: AppTextVariant.bodyMedium,
                              ),
                              AppStatusBadge(
                                label: '${state.pendingOutboxCount}',
                                tone: state.pendingOutboxCount > 0
                                    ? AppStatusTone.pending
                                    : AppStatusTone.good,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText(
                                l10n.syncPendingMediaLabel,
                                variant: AppTextVariant.bodyMedium,
                              ),
                              AppStatusBadge(
                                label: '${state.pendingMediaCount}',
                                tone: state.pendingMediaCount > 0
                                    ? AppStatusTone.pending
                                    : AppStatusTone.good,
                              ),
                            ],
                          ),
                          if (state.unresolvedConflictCount > 0) ...[
                            const SizedBox(height: AppSpacing.md),
                            AppStatusBadge(
                              label: l10n.syncConflictsDetectedBanner(
                                state.unresolvedConflictCount,
                              ),
                              tone: AppStatusTone.pending,
                              icon: AppIcons.conflict,
                            ),
                          ],
                          if (state.errorMessage != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            AppStatusBadge(
                              label: state.errorMessage!,
                              tone: AppStatusTone.damaged,
                              icon: AppIcons.error,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(
                            label: l10n.syncNowAction,
                            icon: AppIcons.sync,
                            isExpanded: true,
                            isLoading: isSyncing,
                            onPressed: state.isOnline && !isSyncing
                                ? () => context.read<SyncCubit>().syncNow()
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppButton(
                            label: l10n.syncConflictsOpenAction,
                            icon: AppIcons.conflict,
                            variant: AppButtonVariant.outlined,
                            isExpanded: true,
                            onPressed: () =>
                                context.push(RoutePaths.settingsSyncConflicts),
                          ),
                          if (state.failedItems.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            AppButton(
                              label: l10n.syncRetryFailedAction,
                              icon: AppIcons.refresh,
                              variant: AppButtonVariant.secondary,
                              isExpanded: true,
                              onPressed: state.isOnline && !isSyncing
                                  ? () =>
                                        context.read<SyncCubit>().retryFailed()
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (state.failedItems.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      AppHeading(
                        l10n.syncFailedItemsHeading,
                        level: AppHeadingLevel.h3,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppCard(
                        child: Column(
                          children: [
                            for (
                              var i = 0;
                              i < state.failedItems.length;
                              i++
                            ) ...[
                              if (i > 0)
                                const AppDivider(height: AppSpacing.md),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    AppIcons.syncProblem,
                                    color: colorScheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AppText(
                                          '${state.failedItems[i].tableName} • ${state.failedItems[i].rowId}',
                                          variant: AppTextVariant.bodyMedium,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        AppText(
                                          state.failedItems[i].lastError,
                                          variant: AppTextVariant.bodySmall,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
