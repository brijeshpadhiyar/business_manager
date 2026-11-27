import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/domain_label_localizer.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:business_manager/features/reports/domain/calculators/workshop_daily_calculator.dart';
import 'package:business_manager/features/reports/domain/entities/advanced_report_entities.dart';
import 'package:business_manager/features/reports/domain/entities/dashboard_report_entities.dart';
import 'package:business_manager/features/reports/presentation/widgets/report_trend_chart.dart';
import 'package:material_ui/material_ui.dart';

typedef DashboardPushAndRefresh = Future<void> Function(String path);

/// Weekly issued vs good-returned trend chart section on [DashboardPage].
final class DashboardWeekTrendSection extends StatelessWidget {
  const DashboardWeekTrendSection({
    super.key,
    required this.weekTrend,
    required this.onPushAndRefresh,
  });

  final List<ProductionTrendPoint> weekTrend;
  final DashboardPushAndRefresh onPushAndRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeading(
            l10n.dashboardWeekTrendHeading,
            level: AppHeadingLevel.h3,
            trailing: AppButton(
              label: l10n.navReports,
              variant: AppButtonVariant.text,
              onPressed: () => onPushAndRefresh(RoutePaths.reports),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ReportTrendChart(
            points: weekTrend,
            issuedLabel: l10n.stockIssuedLabel,
            goodReturnedLabel: l10n.stockGoodReturnedLabel,
          ),
        ],
      ),
    );
  }
}

/// Important and oldest pending worker issues list on [DashboardPage].
final class DashboardImportantPendingSection extends StatelessWidget {
  const DashboardImportantPendingSection({
    super.key,
    required this.snapshot,
    required this.onPushAndRefresh,
  });

  final DashboardSnapshot snapshot;
  final DashboardPushAndRefresh onPushAndRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppMotionEntrance(
      index: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeading(
            l10n.dashboardImportantPendingHeading,
            level: AppHeadingLevel.h3,
            trailing: AppButton(
              label: l10n.dashboardViewAllPendingAction,
              variant: AppButtonVariant.text,
              onPressed: () => onPushAndRefresh(RoutePaths.stockReturnPicker),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          AppCard.listItem(
            child: Column(
              children: [
                for (
                  var i = 0;
                  i < snapshot.importantPendingIssues.length;
                  i++
                ) ...[
                  Builder(
                    builder: (context) {
                      final item = snapshot.importantPendingIssues[i];
                      final v = item.issueView;
                      final ageDays = WorkshopDailyCalculator.pendingAgeDays(
                        v.movement.transactionAt,
                        IstDateTimeHelper.nowUtcMillis(),
                      );
                      final ageLabel = ageDays == 0
                          ? l10n.reportPresetToday
                          : l10n.pendingAgeDaysBadge(ageDays);
                      return InkWell(
                        onTap: () => onPushAndRefresh(
                          RoutePaths.stockReturn(v.movement.id),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xs,
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText(
                                      '${v.workerName ?? '-'} • ${v.processName ?? '-'}',
                                      fontWeight: FontWeight.w700,
                                    ),
                                    AppText(
                                      '${v.lotNumber} • ${v.designName} • ${v.colourName}',
                                      variant: AppTextVariant.bodySmall,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  AppStatusBadge(
                                    label:
                                        '${item.remainingPending} ${l10n.piecesUnit}',
                                    tone: AppStatusTone.pending,
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  AppText(
                                    ageLabel,
                                    variant: AppTextVariant.bodySmall,
                                    color: ageDays >= 7
                                        ? Theme.of(context).colorScheme.error
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  if (i < snapshot.importantPendingIssues.length - 1)
                    const AppDivider(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Live stock & production health KPI grid on [DashboardPage].
final class DashboardStockHealthSection extends StatelessWidget {
  const DashboardStockHealthSection({
    super.key,
    required this.status,
    required this.snapshot,
    required this.onNavigateTab,
    required this.onPushAndRefresh,
  });

  final DashboardStatus status;
  final DashboardSnapshot? snapshot;
  final ValueChanged<int> onNavigateTab;
  final DashboardPushAndRefresh onPushAndRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final snap = snapshot;
    return AppMotionEntrance(
      index: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeading(l10n.dashboardStockHealth, level: AppHeadingLevel.h3),
          const SizedBox(height: AppSpacing.sm),
          AppStateTransition(
            stateKey: ValueKey<bool>(
              status == DashboardStatus.loading && snap == null,
            ),
            child: status == DashboardStatus.loading && snap == null
                ? const AppSkeletonList(itemCount: 2)
                : snap == null
                ? const SizedBox.shrink()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 700;
                      final tileW = isWide
                          ? (constraints.maxWidth - AppSpacing.sm * 3) / 4
                          : (constraints.maxWidth - AppSpacing.sm) / 2;
                      return Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          SizedBox(
                            width: tileW,
                            child: AppMetricTile(
                              backdropKey: null,
                              label: l10n.dashboardTotalLotsLabel,
                              value: snap.totalLots,
                              subtitle:
                                  '${snap.totalDesigns} / ${snap.totalColours} ${l10n.dashboardTotalDesignsColoursLabel}',
                              icon: AppIcons.lot,
                              tone: AppStatusTone.neutral,
                              onTap: () => onNavigateTab(1),
                            ),
                          ),
                          SizedBox(
                            width: tileW,
                            child: AppMetricTile(
                              backdropKey: null,
                              label: l10n.stockAvailableGoodLabel,
                              value: snap.availableGoodStock,
                              suffix: l10n.piecesUnit,
                              icon: AppIcons.successOutline,
                              tone: AppStatusTone.good,
                              onTap: () => onNavigateTab(2),
                            ),
                          ),
                          SizedBox(
                            width: tileW,
                            child: AppMetricTile(
                              backdropKey: null,
                              label: l10n.stockPendingWorkerLabel,
                              value: snap.pendingWorkerStock,
                              suffix: l10n.piecesUnit,
                              icon: AppIcons.pending,
                              tone: snap.pendingWorkerStock > 0
                                  ? AppStatusTone.pending
                                  : AppStatusTone.good,
                              onTap: () => onPushAndRefresh(
                                RoutePaths.stockReturnPicker,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: tileW,
                            child: AppMetricTile(
                              backdropKey: null,
                              label: l10n.stockPendingQcLabel,
                              value: snap.pendingInspectionStock,
                              suffix: l10n.piecesUnit,
                              icon: AppIcons.qcInspect,
                              tone: snap.pendingInspectionStock > 0
                                  ? AppStatusTone.pending
                                  : AppStatusTone.neutral,
                              onTap: () => onPushAndRefresh(
                                RoutePaths.inspectionQueue,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: tileW,
                            child: AppMetricTile(
                              backdropKey: null,
                              label: l10n.stockDamagedBucketLabel,
                              value: snap.damagedStock,
                              suffix: l10n.piecesUnit,
                              icon: AppIcons.damaged,
                              tone: snap.damagedStock > 0
                                  ? AppStatusTone.damaged
                                  : AppStatusTone.neutral,
                              onTap: () =>
                                  onPushAndRefresh(RoutePaths.stockRepair),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Live financial & worker accounting summary KPI grid on [DashboardPage].
final class DashboardFinanceHealthSection extends StatelessWidget {
  const DashboardFinanceHealthSection({
    super.key,
    required this.snapshot,
    required this.onPushAndRefresh,
  });

  final DashboardSnapshot snapshot;
  final DashboardPushAndRefresh onPushAndRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppMotionEntrance(
      index: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeading(l10n.dashboardFinanceHealth, level: AppHeadingLevel.h3),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              final tileW = isWide
                  ? (constraints.maxWidth - AppSpacing.sm * 3) / 4
                  : (constraints.maxWidth - AppSpacing.sm) / 2;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SizedBox(
                    width: tileW,
                    child: AppMetricTile(
                      backdropKey: null,
                      label: l10n.accountingEarnedLabourLabel,
                      value: snapshot.totalEarnedLabourPaise,
                      isCurrencyPaise: true,
                      icon: AppIcons.work,
                      tone: AppStatusTone.good,
                      onTap: () => onPushAndRefresh(RoutePaths.accounting),
                    ),
                  ),
                  SizedBox(
                    width: tileW,
                    child: AppMetricTile(
                      backdropKey: null,
                      label: l10n.accountingOutstandingPayableLabel,
                      value: snapshot.totalOutstandingPayablePaise,
                      isCurrencyPaise: true,
                      icon: AppIcons.accounting,
                      tone: snapshot.totalOutstandingPayablePaise > 0
                          ? AppStatusTone.pending
                          : AppStatusTone.good,
                      onTap: () => onPushAndRefresh(RoutePaths.accounting),
                    ),
                  ),
                  SizedBox(
                    width: tileW,
                    child: AppMetricTile(
                      backdropKey: null,
                      label: l10n.accountingAdvanceCreditLabel,
                      value: snapshot.totalAdvanceCreditPaise,
                      isCurrencyPaise: true,
                      subtitle:
                          '${l10n.accountingAdvancePaidLabel}: ${MoneyFormatter.formatPaise(snapshot.totalAdvancePaymentsPaise)}',
                      icon: AppIcons.trend,
                      tone: AppStatusTone.info,
                      onTap: () => onPushAndRefresh(RoutePaths.accounting),
                    ),
                  ),
                  SizedBox(
                    width: tileW,
                    child: AppMetricTile(
                      backdropKey: null,
                      label: l10n.accountingRegularPaidLabel,
                      value: snapshot.totalRegularPaymentsPaise,
                      isCurrencyPaise: true,
                      icon: AppIcons.payment,
                      tone: AppStatusTone.neutral,
                      onTap: () => onPushAndRefresh(RoutePaths.accounting),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Process-wise pending breakdown card on [DashboardPage].
final class DashboardProcessPendingSection extends StatelessWidget {
  const DashboardProcessPendingSection({
    super.key,
    required this.snapshot,
    required this.onPushAndRefresh,
  });

  final DashboardSnapshot snapshot;
  final DashboardPushAndRefresh onPushAndRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppMotionEntrance(
      index: 6,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeading(l10n.dashboardProcessPending, level: AppHeadingLevel.h3),
          const SizedBox(height: AppSpacing.sm),
          if (snapshot.processPendingList.isEmpty)
            AppCard.listItem(
              child: AppText(
                l10n.dashboardNoProcessPending,
                variant: AppTextVariant.bodySmall,
              ),
            )
          else
            AppCard.listItem(
              child: Column(
                children: [
                  for (
                    int i = 0;
                    i < snapshot.processPendingList.length;
                    i++
                  ) ...[
                    InkWell(
                      onTap: () => onPushAndRefresh(
                        RoutePaths.stockReturnPickerFiltered(
                          processId: snapshot.processPendingList[i].processId,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs,
                        ),
                        child: AppActionRow(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          content: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                snapshot.processPendingList[i].processName,
                                fontWeight: FontWeight.w600,
                              ),
                              AppText(
                                '${l10n.stockIssuedLabel}: ${snapshot.processPendingList[i].issued} ${l10n.piecesUnit}',
                                variant: AppTextVariant.bodySmall,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                          actions: [
                            AppStatusBadge(
                              label:
                                  '${snapshot.processPendingList[i].pending} ${l10n.piecesUnit}',
                              tone: snapshot.processPendingList[i].pending > 0
                                  ? AppStatusTone.pending
                                  : AppStatusTone.good,
                            ),
                            const Icon(AppIcons.chevronRight, size: 18),
                          ],
                        ),
                      ),
                    ),
                    if (i < snapshot.processPendingList.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: AppDivider(),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Recent audit activity feed card on [DashboardPage].
final class DashboardRecentActivitySection extends StatelessWidget {
  const DashboardRecentActivitySection({
    super.key,
    required this.snapshot,
    required this.localeCode,
  });

  final DashboardSnapshot snapshot;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppMotionEntrance(
      index: 7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppHeading(l10n.dashboardRecentActivity, level: AppHeadingLevel.h3),
          const SizedBox(height: AppSpacing.sm),
          if (snapshot.recentActivity.isEmpty)
            AppCard.listItem(
              child: AppText(
                l10n.dashboardNoRecentActivity,
                variant: AppTextVariant.bodySmall,
              ),
            )
          else
            AppCard.listItem(
              child: Column(
                children: [
                  for (
                    int i = 0;
                    i < snapshot.recentActivity.length.clamp(0, 6);
                    i++
                  ) ...[
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AppStatusBadge(
                          label: DomainLabelLocalizer.auditAction(
                            l10n,
                            snapshot.recentActivity[i].actionType,
                          ),
                          tone:
                              snapshot.recentActivity[i].actionType ==
                                  'REVERSAL'
                              ? AppStatusTone.damaged
                              : AppStatusTone.info,
                        ),
                        AppText(
                          DomainLabelLocalizer.auditEntity(
                            l10n,
                            snapshot.recentActivity[i].entityType,
                          ),
                          fontWeight: FontWeight.w600,
                        ),
                        AppText(
                          IstDateTimeHelper.formatIstDateTime(
                            snapshot.recentActivity[i].recordedAt,
                            locale: localeCode,
                          ),
                          variant: AppTextVariant.bodySmall,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    if (i < snapshot.recentActivity.length.clamp(0, 6) - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: AppSpacing.xs + 2,
                        ),
                        child: AppDivider(),
                      ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
