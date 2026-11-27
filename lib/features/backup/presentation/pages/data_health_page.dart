import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/backup/domain/entities/data_health_entities.dart';
import 'package:business_manager/features/backup/presentation/bloc/data_health_cubit.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:share_plus/share_plus.dart';

/// Settings → Data Health & Reconciliation Center.
///
/// Surfaces SQLite integrity, foreign key checks, golden stock equation
/// reconciliation, worker ledger parity, sync queue counts, and media parity,
/// plus safe audited maintenance actions and shareable diagnostic export.
final class DataHealthPage extends StatelessWidget {
  const DataHealthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DataHealthCubit>(
      create: (_) => getIt<DataHealthCubit>()..runDiagnostics(),
      child: const _DataHealthView(),
    );
  }
}

final class _DataHealthView extends StatelessWidget {
  const _DataHealthView();

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 KB';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    return '${(kb / 1024).toStringAsFixed(2)} MB';
  }

  Future<void> _shareReport(BuildContext context) async {
    final text = context.read<DataHealthCubit>().buildExportText();
    if (text == null) return;
    final box = context.findRenderObject() as RenderBox?;
    final origin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 1, 1);
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'StitchFlow Data Health Report',
        sharePositionOrigin: origin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: l10n.dataHealthHeading,
      constrainMaxWidth: false,
      padding: EdgeInsets.zero,
      actions: [
        BlocBuilder<DataHealthCubit, DataHealthState>(
          builder: (context, state) => AppIconButton(
            icon: AppIcons.refresh,
            tooltip: l10n.dataHealthRunCheckAction,
            onPressed: state.isLoading || state.isMaintenanceBusy
                ? null
                : () => context.read<DataHealthCubit>().runDiagnostics(),
          ),
        ),
      ],
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizing.narrowContentWidth,
          ),
          child: BlocConsumer<DataHealthCubit, DataHealthState>(
            listener: (context, state) {
              if (state.errorMessage != null) {
                AppFeedback.showError(context, state.errorMessage!);
              } else if (state.lastActionMessage != null) {
                final code = state.lastActionMessage!;
                if (code == 'wal_checkpoint') {
                  AppFeedback.showSuccess(
                    context,
                    l10n.dataHealthWalCheckpointSuccess,
                  );
                } else if (code.startsWith('orphan_clean:')) {
                  final count = int.tryParse(code.split(':').last) ?? 0;
                  AppFeedback.showSuccess(
                    context,
                    l10n.dataHealthCleanOrphansSuccess(count),
                  );
                } else if (code.startsWith('sync_retry:')) {
                  final count = int.tryParse(code.split(':').last) ?? 0;
                  AppFeedback.showSuccess(
                    context,
                    l10n.dataHealthRetrySyncSuccess(count),
                  );
                }
              }
            },
            builder: (context, state) {
              if (state.isLoading && state.report == null) {
                return const Padding(
                  padding: AppSpacing.screenAll,
                  child: AppSkeletonList(itemCount: 4),
                );
              }

              final report = state.report;
              if (report == null) {
                return AppErrorView(
                  title: l10n.dataHealthHeading,
                  message: state.errorMessage ?? l10n.dataHealthSubtitle,
                  retryLabel: l10n.dataHealthRunCheckAction,
                  onRetry: () =>
                      context.read<DataHealthCubit>().runDiagnostics(),
                );
              }

              final statusTone = switch (report.status) {
                DataHealthStatus.healthy => AppStatusTone.good,
                DataHealthStatus.warning => AppStatusTone.pending,
                DataHealthStatus.critical => AppStatusTone.damaged,
              };
              final statusLabel = switch (report.status) {
                DataHealthStatus.healthy => l10n.dataHealthStatusHealthy,
                DataHealthStatus.warning => l10n.dataHealthStatusWarning,
                DataHealthStatus.critical => l10n.dataHealthStatusCritical,
              };

              return RefreshIndicator(
                onRefresh: () =>
                    context.read<DataHealthCubit>().runDiagnostics(),
                child: ListView(
                  padding: AppSpacing.screenAll,
                  children: [
                    AppHeading(
                      l10n.dataHealthHeading,
                      level: AppHeadingLevel.h2,
                      subtitle: l10n.dataHealthSubtitle,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Overall Status Summary Card
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppActionRow(
                            content: Row(
                              children: [
                                Icon(
                                  report.status == DataHealthStatus.healthy
                                      ? AppIcons.success
                                      : report.status ==
                                            DataHealthStatus.warning
                                      ? AppIcons.warning
                                      : AppIcons.error,
                                  color: statusTone == AppStatusTone.good
                                      ? colorScheme.secondary
                                      : statusTone == AppStatusTone.damaged
                                      ? colorScheme.error
                                      : colorScheme.primary,
                                  size: AppSizing.iconLg,
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      AppText(
                                        statusLabel,
                                        variant: AppTextVariant.bodyLarge,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      AppText(
                                        '${l10n.dataHealthCheckedAtLabel}: ${IstDateTimeHelper.formatIstDateTime(report.checkedAtUtcMillis, locale: localeCode)}',
                                        variant: AppTextVariant.bodySmall,
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              AppStatusBadge(
                                label: 'v${report.schemaVersion}',
                                tone: AppStatusTone.info,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.xs,
                            children: [
                              AppStatusBadge(
                                label:
                                    '${l10n.dataHealthDbSizeLabel}: ${_formatSize(report.estimatedDbSizeBytes)}',
                                tone: AppStatusTone.neutral,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              AppButton(
                                label: l10n.dataHealthRunCheckAction,
                                icon: AppIcons.refresh,
                                isLoading: state.isLoading,
                                onPressed: state.isMaintenanceBusy
                                    ? null
                                    : () => context
                                          .read<DataHealthCubit>()
                                          .runDiagnostics(),
                              ),
                              AppButton(
                                label: l10n.dataHealthShareReportAction,
                                icon: AppIcons.share,
                                variant: AppButtonVariant.outlined,
                                onPressed: () => _shareReport(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Core Integrity & Reconciliation Checks
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CheckRow(
                            label: l10n.dataHealthSqliteIntegrityLabel,
                            value: report.sqliteIntegrityOk
                                ? l10n.dataHealthSqliteOk
                                : l10n.dataHealthSqliteFailed,
                            tone: report.sqliteIntegrityOk
                                ? AppStatusTone.good
                                : AppStatusTone.damaged,
                          ),
                          const AppDivider(height: AppSpacing.lg),
                          _CheckRow(
                            label: l10n.dataHealthForeignKeysLabel,
                            value: report.foreignKeyViolations.isEmpty
                                ? l10n.dataHealthZeroViolations
                                : l10n.dataHealthViolationsCount(
                                    report.foreignKeyViolations.length,
                                  ),
                            tone: report.foreignKeyViolations.isEmpty
                                ? AppStatusTone.good
                                : AppStatusTone.damaged,
                          ),
                          const AppDivider(height: AppSpacing.lg),
                          _CheckRow(
                            label: l10n.dataHealthStockReconciliationLabel,
                            value: report.stockIssues.isEmpty
                                ? l10n.dataHealthStockAllReconciled(
                                    report.totalColoursChecked,
                                  )
                                : l10n.dataHealthStockIssuesCount(
                                    report.stockIssues.length,
                                  ),
                            tone: report.stockIssues.isEmpty
                                ? AppStatusTone.good
                                : AppStatusTone.damaged,
                          ),
                          if (report.stockIssues.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            for (final issue in report.stockIssues.take(10))
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xs,
                                ),
                                child: AppText(
                                  '• ${issue.lotNumber} / ${issue.designName} / ${issue.colourName} '
                                  '(${issue.reasonCode}: ${issue.reconciledTotalQty} vs ${issue.initialQty})',
                                  variant: AppTextVariant.bodySmall,
                                  color: colorScheme.error,
                                ),
                              ),
                          ],
                          const AppDivider(height: AppSpacing.lg),
                          _CheckRow(
                            label: l10n.dataHealthLedgerParityLabel,
                            value: report.ledgerIssues.isEmpty
                                ? l10n.dataHealthLedgerParityOk
                                : l10n.dataHealthViolationsCount(
                                    report.ledgerIssues.length,
                                  ),
                            tone: report.ledgerIssues.isEmpty
                                ? AppStatusTone.good
                                : AppStatusTone.damaged,
                          ),
                          if (report.ledgerIssues.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            for (final li in report.ledgerIssues.take(10))
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xs,
                                ),
                                child: AppText(
                                  '• ${li.code}: ${li.details}',
                                  variant: AppTextVariant.bodySmall,
                                  color: colorScheme.error,
                                ),
                              ),
                          ],
                          const AppDivider(height: AppSpacing.lg),
                          _CheckRow(
                            label: l10n.dataHealthSyncQueueLabel,
                            value: l10n.dataHealthSyncQueueSummary(
                              report.syncOutboxPending +
                                  report.syncMediaPending,
                              report.syncOutboxFailed + report.syncMediaFailed,
                            ),
                            tone:
                                (report.syncOutboxFailed +
                                        report.syncMediaFailed) >
                                    0
                                ? AppStatusTone.pending
                                : AppStatusTone.good,
                          ),
                          const AppDivider(height: AppSpacing.lg),
                          _CheckRow(
                            label: l10n.dataHealthMediaParityLabel,
                            value: l10n.dataHealthMediaParitySummary(
                              report.orphanMediaPaths.length,
                              report.missingMediaPaths.length,
                            ),
                            tone:
                                report.orphanMediaPaths.isEmpty &&
                                    report.missingMediaPaths.isEmpty
                                ? AppStatusTone.good
                                : AppStatusTone.pending,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Safe Audited Maintenance Actions
                    AppHeading(
                      l10n.dataHealthMaintenanceHeading,
                      level: AppHeadingLevel.h3,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _MaintenanceActionRow(
                            icon: AppIcons.storage,
                            title: l10n.dataHealthWalCheckpointAction,
                            description: l10n.dataHealthWalCheckpointDesc,
                            busy: state.isMaintenanceBusy,
                            onRun: () => context
                                .read<DataHealthCubit>()
                                .runWalCheckpoint(),
                          ),
                          if (!kIsWeb) ...[
                            const AppDivider(height: AppSpacing.lg),
                            _MaintenanceActionRow(
                              icon: AppIcons.maintenance,
                              title: l10n.dataHealthCleanOrphansAction,
                              description: l10n.dataHealthCleanOrphansDesc,
                              busy: state.isMaintenanceBusy,
                              enabled: report.orphanMediaPaths.isNotEmpty,
                              onRun: () => context
                                  .read<DataHealthCubit>()
                                  .cleanOrphanMedia(),
                            ),
                          ],
                          const AppDivider(height: AppSpacing.lg),
                          _MaintenanceActionRow(
                            icon: AppIcons.sync,
                            title: l10n.dataHealthRetrySyncAction,
                            description: l10n.dataHealthRetrySyncDesc,
                            busy: state.isMaintenanceBusy,
                            enabled:
                                (report.syncOutboxFailed +
                                    report.syncMediaFailed) >
                                0,
                            onRun: () => context
                                .read<DataHealthCubit>()
                                .retryFailedSync(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

final class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.value,
    required this.tone,
  });

  final String label;
  final String value;
  final AppStatusTone tone;

  @override
  Widget build(BuildContext context) {
    return AppActionRow(
      content: AppText(label, fontWeight: FontWeight.w600),
      actions: [AppStatusBadge(label: value, tone: tone)],
    );
  }
}

final class _MaintenanceActionRow extends StatelessWidget {
  const _MaintenanceActionRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.busy,
    required this.onRun,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool busy;
  final bool enabled;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppActionRow(
      content: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: AppSizing.iconMd, color: colorScheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(title, fontWeight: FontWeight.w600),
                const SizedBox(height: AppSpacing.xxs),
                AppText(
                  description,
                  variant: AppTextVariant.bodySmall,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        AppButton(
          label: title,
          variant: AppButtonVariant.outlined,
          isLoading: busy,
          onPressed: enabled && !busy ? onRun : null,
        ),
      ],
    );
  }
}
