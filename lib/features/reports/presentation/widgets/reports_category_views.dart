import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/reports/domain/entities/advanced_report_entities.dart';
import 'package:business_manager/features/reports/presentation/widgets/report_trend_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Shared empty state for report tabs and tables.
final class ReportsEmptyView extends StatelessWidget {
  const ReportsEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppEmptyState(
      icon: AppIcons.reports,
      title: l10n.reportsEmptyTitle,
      subtitle: l10n.reportsEmptySubtitle,
    );
  }
}

/// 2-column (mobile) or 3-column (wide) responsive metric tile grid.
final class ReportResponsiveMetricGrid extends StatelessWidget {
  const ReportResponsiveMetricGrid({super.key, required this.tiles});

  final List<Widget> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 700 ? 3 : 2;
        final tileW =
            (constraints.maxWidth - AppSpacing.sm * (cols - 1)) / cols;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [for (final t in tiles) SizedBox(width: tileW, child: t)],
        );
      },
    );
  }
}

/// Category 1: Daily Workshop report view.
final class ReportsDailyCategoryView extends StatelessWidget {
  const ReportsDailyCategoryView({
    super.key,
    required this.bundle,
    required this.localeCode,
  });

  final AdvancedReportsBundle bundle;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final b = bundle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportResponsiveMetricGrid(
          tiles: [
            AppMetricTile(
              label: l10n.stockIssuedLabel,
              value: b.dailyTotalIssued,
              suffix: l10n.piecesUnit,
              icon: AppIcons.stockIssue,
              tone: AppStatusTone.info,
            ),
            AppMetricTile(
              label: l10n.stockGoodReturnedLabel,
              value: b.dailyTotalGoodReturned,
              suffix: l10n.piecesUnit,
              icon: AppIcons.successOutline,
              tone: AppStatusTone.good,
            ),
            AppMetricTile(
              label: l10n.reportLabourCostLabel,
              value: b.dailyTotalLabourPaise,
              isCurrencyPaise: true,
              icon: AppIcons.payment,
              tone: AppStatusTone.good,
            ),
            AppMetricTile(
              label: l10n.reportsTabPayments,
              value: b.dailyTotalNetPaymentsPaise,
              isCurrencyPaise: true,
              icon: AppIcons.accounting,
              tone: AppStatusTone.info,
            ),
            AppMetricTile(
              label: l10n.dailySummaryDamagedLostLabel,
              value: b.dailyTotalDamaged + b.dailyTotalLostShortage,
              suffix: l10n.piecesUnit,
              icon: AppIcons.damaged,
              tone: (b.dailyTotalDamaged + b.dailyTotalLostShortage) > 0
                  ? AppStatusTone.damaged
                  : AppStatusTone.neutral,
            ),
            AppMetricTile(
              label: l10n.stockPendingWorkerLabel,
              value: b.currentTotalPendingQty,
              suffix: l10n.piecesUnit,
              icon: AppIcons.pending,
              tone: b.currentTotalPendingQty > 0
                  ? AppStatusTone.pending
                  : AppStatusTone.good,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (b.dailyRows.isEmpty)
          const ReportsEmptyView()
        else
          AppDataTable<DailyReportRow>(
            enablePagination: true,
            columns: [
              AppDataColumn(label: l10n.dailySummaryPickDateLabel),
              AppDataColumn(label: l10n.stockIssuedLabel, numeric: true),
              AppDataColumn(label: l10n.stockGoodReturnedLabel, numeric: true),
              AppDataColumn(
                label: l10n.dailySummaryDamagedLostLabel,
                numeric: true,
              ),
              AppDataColumn(label: l10n.reportLabourCostLabel, numeric: true),
              AppDataColumn(label: l10n.reportsTabPayments, numeric: true),
            ],
            items: b.dailyRows,
            onRowTap: (row) => context.push(
              '${RoutePaths.dailySummary}?dayUtcMillis=${row.dayStartUtcMillis}',
            ),
            cellsBuilder: (r) => [
              AppText(
                IstDateTimeHelper.formatIstDate(
                  r.dayStartUtcMillis,
                  locale: localeCode,
                ),
                fontWeight: FontWeight.w700,
              ),
              AppText('${r.issuedQty}', variant: AppTextVariant.numeric),
              AppText('${r.goodReturnedQty}', variant: AppTextVariant.numeric),
              AppText(
                '${r.damagedQty + r.lostAndShortageQty}',
                variant: AppTextVariant.numeric,
              ),
              AppText(
                MoneyFormatter.formatPaise(r.labourEarnedPaise),
                variant: AppTextVariant.numeric,
              ),
              AppText(
                MoneyFormatter.formatPaise(r.netPaymentsPaise),
                variant: AppTextVariant.numeric,
              ),
            ],
            mobileCardBuilder: (_, r) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        IstDateTimeHelper.formatIstDate(
                          r.dayStartUtcMillis,
                          locale: localeCode,
                        ),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppText(
                      MoneyFormatter.formatPaise(r.labourEarnedPaise),
                      variant: AppTextVariant.numeric,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    AppStatusBadge(
                      label: '${l10n.stockIssuedLabel}: ${r.issuedQty}',
                      tone: AppStatusTone.info,
                    ),
                    AppStatusBadge(
                      label:
                          '${l10n.stockGoodReturnedLabel}: ${r.goodReturnedQty}',
                      tone: AppStatusTone.good,
                    ),
                    if (r.damagedQty + r.lostAndShortageQty > 0)
                      AppStatusBadge(
                        label:
                            '${l10n.dailySummaryDamagedLostLabel}: ${r.damagedQty + r.lostAndShortageQty}',
                        tone: AppStatusTone.damaged,
                      ),
                    if (r.netPaymentsPaise != 0)
                      AppStatusBadge(
                        label:
                            '${l10n.reportsTabPayments}: ${MoneyFormatter.formatPaise(r.netPaymentsPaise)}',
                        tone: AppStatusTone.neutral,
                      ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Category 2: Worker Performance report view.
final class ReportsWorkersCategoryView extends StatelessWidget {
  const ReportsWorkersCategoryView({super.key, required this.bundle});

  final AdvancedReportsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (bundle.workerPerformance.isEmpty) return const ReportsEmptyView();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final w in bundle.workerPerformance) ...[
          AppCard.listItem(
            key: ValueKey<String>(w.workerId),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () =>
                            context.push(RoutePaths.workerLedger(w.workerId)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(w.workerName, fontWeight: FontWeight.w700),
                            const SizedBox(height: AppSpacing.xxs),
                            AppText(
                              '${l10n.reportPeriodFlowBadge}: '
                              '${l10n.stockIssuedLabel} ${w.periodIssuedQty} • '
                              '${l10n.stockGoodReturnedLabel} ${w.periodGoodReturnedQty}',
                              variant: AppTextVariant.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    AppIconButton(
                      icon: AppIcons.accounting,
                      tooltip: l10n.reportsTabWorkerLedger,
                      onPressed: () =>
                          context.push(RoutePaths.workerLedger(w.workerId)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    AppStatusBadge(
                      label:
                          '${l10n.reportLabourCostLabel}: ${MoneyFormatter.formatPaise(w.periodLabourEarnedPaise)}',
                      tone: AppStatusTone.good,
                    ),
                    AppStatusBadge(
                      label:
                          '${l10n.reportsTabPayments}: ${MoneyFormatter.formatPaise(w.periodNetPaymentsPaise)}',
                      tone: AppStatusTone.info,
                    ),
                    if (w.periodDamagedQty + w.periodLostShortageQty > 0)
                      AppStatusBadge(
                        label:
                            '${l10n.dailySummaryDamagedLostLabel}: ${w.periodDamagedQty + w.periodLostShortageQty}',
                        tone: AppStatusTone.damaged,
                      ),
                    if (w.defectRatePercent != null)
                      AppStatusBadge(
                        label:
                            '${l10n.reportDefectRateLabel}: ${w.defectRatePercent!.toStringAsFixed(1)}%',
                        tone: w.defectRatePercent! > 5
                            ? AppStatusTone.damaged
                            : AppStatusTone.neutral,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                AppText(
                  l10n.reportCurrentStandingBadge,
                  variant: AppTextVariant.label,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    AppStatusBadge(
                      label:
                          '${l10n.stockRemainingPendingLabel}: ${w.currentPendingQty} ${l10n.piecesUnit}',
                      tone: w.currentPendingQty > 0
                          ? AppStatusTone.pending
                          : AppStatusTone.good,
                    ),
                    if (w.currentOutstandingPayablePaise > 0)
                      AppStatusBadge(
                        label:
                            '${l10n.accountingOutstandingPayableLabel}: ${MoneyFormatter.formatPaise(w.currentOutstandingPayablePaise)}',
                        tone: AppStatusTone.pending,
                      ),
                    if (w.currentAdvanceCreditPaise > 0)
                      AppStatusBadge(
                        label:
                            '${l10n.accountingAdvanceCreditLabel}: ${MoneyFormatter.formatPaise(w.currentAdvanceCreditPaise)}',
                        tone: AppStatusTone.info,
                      ),
                  ],
                ),
                if (w.processBreakdown.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(
                      bottom: AppSpacing.xs,
                    ),
                    title: AppText(
                      l10n.reportWorkerProcessBreakdown,
                      variant: AppTextVariant.bodySmall,
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      for (final pb in w.processBreakdown)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xxs,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: AppText(
                                  pb.processName,
                                  variant: AppTextVariant.bodySmall,
                                ),
                              ),
                              AppText(
                                '${pb.goodReturnedQty} ${l10n.piecesUnit} • ${MoneyFormatter.formatPaise(pb.labourEarnedPaise)}',
                                variant: AppTextVariant.numeric,
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
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// Category 3: Process Performance report view.
final class ReportsProcessesCategoryView extends StatelessWidget {
  const ReportsProcessesCategoryView({super.key, required this.bundle});

  final AdvancedReportsBundle bundle;

  String _formatTurnaround(double? hours, String naLabel) {
    if (hours == null) return naLabel;
    return AppDateTimeFormatter.formatDurationHours(hours);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (bundle.processPerformance.isEmpty) return const ReportsEmptyView();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in bundle.processPerformance) ...[
          AppCard.listItem(
            key: ValueKey<String>(p.processId),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        p.processName,
                        fontWeight: FontWeight.w700,
                        maxLines: 2,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: AppStatusBadge(
                        label:
                            '${l10n.stockRemainingPendingLabel}: ${p.currentPendingQty} ${l10n.piecesUnit}',
                        tone: p.currentPendingQty > 0
                            ? AppStatusTone.pending
                            : AppStatusTone.good,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    AppStatusBadge(
                      label: '${l10n.stockIssuedLabel}: ${p.periodIssuedQty}',
                      tone: AppStatusTone.info,
                    ),
                    AppStatusBadge(
                      label:
                          '${l10n.stockGoodReturnedLabel}: ${p.periodGoodReturnedQty}',
                      tone: AppStatusTone.good,
                    ),
                    AppStatusBadge(
                      label:
                          '${l10n.reportLabourCostLabel}: ${MoneyFormatter.formatPaise(p.periodLabourCostPaise)}',
                      tone: AppStatusTone.neutral,
                    ),
                    AppStatusBadge(
                      label:
                          '${l10n.reportAvgTurnaroundLabel}: ${_formatTurnaround(p.averageTurnaroundHours, l10n.reportNotAvailable)}'
                          '${p.settledIssuesCount > 0 ? ' (${l10n.reportTurnaroundSampleCount(p.settledIssuesCount)})' : ''}',
                      tone: AppStatusTone.neutral,
                    ),
                  ],
                ),
                if (p.workerContributions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(
                      bottom: AppSpacing.xs,
                    ),
                    title: AppText(
                      l10n.reportProcessWorkerContribution,
                      variant: AppTextVariant.bodySmall,
                      fontWeight: FontWeight.w600,
                    ),
                    children: [
                      for (final c in p.workerContributions)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xxs,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: AppText(
                                  c.workerName,
                                  variant: AppTextVariant.bodySmall,
                                ),
                              ),
                              AppText(
                                '${c.goodReturnedQty} ${l10n.piecesUnit}'
                                '${c.sharePercent != null ? ' (${c.sharePercent!.toStringAsFixed(0)}%)' : ''}',
                                variant: AppTextVariant.numeric,
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
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

/// Category 6: Business Insights report view.
final class ReportsInsightsCategoryView extends StatelessWidget {
  const ReportsInsightsCategoryView({super.key, required this.bundle});

  final AdvancedReportsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ins = bundle.insights;
    final cmp = ins.periodComparison;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeading(
                l10n.reportInsightsTrendsTitle,
                level: AppHeadingLevel.h3,
              ),
              AppText(
                ins.isWeeklyBuckets
                    ? l10n.reportInsightsWeeklyNote
                    : l10n.reportInsightsDailyNote,
                variant: AppTextVariant.label,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (ins.trendPoints.isEmpty)
                AppText(
                  l10n.reportsEmptySubtitle,
                  variant: AppTextVariant.bodySmall,
                )
              else
                ReportTrendChart(
                  points: ins.trendPoints,
                  issuedLabel: l10n.stockIssuedLabel,
                  goodReturnedLabel: l10n.stockGoodReturnedLabel,
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (cmp != null) ...[
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppHeading(
                  l10n.reportInsightsComparisonTitle,
                  level: AppHeadingLevel.h3,
                ),
                const SizedBox(height: AppSpacing.sm),
                _ComparisonRow(
                  label: l10n.stockIssuedLabel,
                  currentText:
                      '${cmp.issuedQty.currentValue} ${l10n.piecesUnit}',
                  percentChange: cmp.issuedQty.percentChange,
                  noPriorLabel: l10n.reportInsightsNoPriorData,
                ),
                const AppDivider(),
                _ComparisonRow(
                  label: l10n.stockGoodReturnedLabel,
                  currentText:
                      '${cmp.goodReturnedQty.currentValue} ${l10n.piecesUnit}',
                  percentChange: cmp.goodReturnedQty.percentChange,
                  noPriorLabel: l10n.reportInsightsNoPriorData,
                ),
                const AppDivider(),
                _ComparisonRow(
                  label: l10n.reportLabourCostLabel,
                  currentText: MoneyFormatter.formatPaise(
                    cmp.labourCostPaise.currentValue,
                  ),
                  percentChange: cmp.labourCostPaise.percentChange,
                  noPriorLabel: l10n.reportInsightsNoPriorData,
                ),
                const AppDivider(),
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        l10n.reportDefectRateLabel,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    AppText(
                      cmp.currentDefectRatePercent == null
                          ? l10n.reportNotAvailable
                          : '${cmp.currentDefectRatePercent!.toStringAsFixed(1)}%',
                      variant: AppTextVariant.numeric,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeading(
                l10n.reportInsightsBottlenecksTitle,
                level: AppHeadingLevel.h3,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (ins.bottlenecks.isEmpty)
                AppText(
                  l10n.reportInsightsNoBottlenecks,
                  variant: AppTextVariant.bodySmall,
                )
              else
                for (final bn in ins.bottlenecks) ...[
                  InkWell(
                    onTap: () => context.push(
                      '${RoutePaths.stockReturnPicker}?processId=${bn.processId}',
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: AppActionRow(
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              bn.processName,
                              fontWeight: FontWeight.w700,
                            ),
                            AppText(
                              '${bn.currentPendingQty} ${l10n.piecesUnit} • ${bn.openIssuesCount} ${l10n.workerOpenIssuesCountLabel}',
                              variant: AppTextVariant.bodySmall,
                            ),
                          ],
                        ),
                        actions: [
                          AppStatusBadge(
                            label: l10n.pendingAgeDaysBadge(
                              bn.oldestOpenIssueAgeDays,
                            ),
                            tone: bn.oldestOpenIssueAgeDays >= 3
                                ? AppStatusTone.damaged
                                : AppStatusTone.pending,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (ins.workerTrends.isNotEmpty) ...[
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppHeading(
                  l10n.reportInsightsWorkerTrendsTitle,
                  level: AppHeadingLevel.h3,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final wt in ins.workerTrends)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppText(
                            wt.workerName,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AppText(
                          '${wt.currentGoodReturnedQty} ${l10n.piecesUnit}',
                          variant: AppTextVariant.numeric,
                        ),
                        if (wt.percentChange != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          AppStatusBadge(
                            label:
                                '${wt.percentChange! >= 0 ? '+' : ''}${wt.percentChange!.toStringAsFixed(0)}%',
                            tone: wt.percentChange! >= 0
                                ? AppStatusTone.good
                                : AppStatusTone.pending,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (ins.processLabourCostShares.isNotEmpty) ...[
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppHeading(
                  l10n.reportInsightsLabourShareTitle,
                  level: AppHeadingLevel.h3,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final sh in ins.processLabourCostShares) ...[
                  Row(
                    children: [
                      Expanded(
                        child: AppText(
                          sh.processName,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      AppText(
                        '${MoneyFormatter.formatPaise(sh.labourCostPaise)} (${sh.sharePercent.toStringAsFixed(0)}%)',
                        variant: AppTextVariant.numeric,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppProgressBar(value: sh.sharePercent / 100.0, minHeight: 6),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        if (ins.topDefectReasons.isNotEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppHeading(
                  l10n.reportInsightsDefectReasonsTitle,
                  level: AppHeadingLevel.h3,
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final dr in ins.topDefectReasons)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: AppActionRow(
                      content: AppText(dr.reason),
                      actions: [
                        AppStatusBadge(
                          label: '${dr.quantity} ${l10n.piecesUnit}',
                          tone: AppStatusTone.damaged,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

final class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({
    required this.label,
    required this.currentText,
    required this.percentChange,
    required this.noPriorLabel,
  });

  final String label;
  final String currentText;
  final double? percentChange;
  final String noPriorLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: AppText(label, fontWeight: FontWeight.w600, maxLines: 2),
          ),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.xs,
              runSpacing: 4,
              children: [
                AppText(currentText, variant: AppTextVariant.numeric),
                AppStatusBadge(
                  label: percentChange == null
                      ? noPriorLabel
                      : '${percentChange! >= 0 ? '+' : ''}${percentChange!.toStringAsFixed(0)}%',
                  tone: percentChange == null
                      ? AppStatusTone.neutral
                      : (percentChange! >= 0
                            ? AppStatusTone.good
                            : AppStatusTone.pending),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
