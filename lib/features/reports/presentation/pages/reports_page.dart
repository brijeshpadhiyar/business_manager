import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/domain_label_localizer.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';
import 'package:business_manager/features/guidance/presentation/registry/guide_target_registry.dart';
import 'package:business_manager/features/guidance/presentation/widgets/screen_first_visit_hint.dart';
import 'package:business_manager/features/reports/domain/entities/advanced_report_entities.dart';
import 'package:business_manager/features/reports/domain/entities/dashboard_report_entities.dart';
import 'package:business_manager/features/reports/domain/entities/report_filter.dart';
import 'package:business_manager/features/reports/presentation/bloc/reports_cubit.dart';
import 'package:business_manager/features/reports/presentation/widgets/report_export_sheet.dart';
import 'package:business_manager/features/reports/presentation/widgets/report_filter_bar.dart';
import 'package:business_manager/features/reports/presentation/widgets/report_trend_chart.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// StitchFlow V1.2 unified 6-category Advanced Reports & Business Insights hub.
final class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final initialCategory = ReportCategory
        .values[initialTab.clamp(0, ReportCategory.values.length - 1)];
    return BlocProvider<ReportsCubit>(
      create: (_) => getIt<ReportsCubit>()
        ..selectCategory(initialCategory)
        ..loadReports(),
      child: const _ReportsView(),
    );
  }
}

final class _ReportsView extends StatefulWidget {
  const _ReportsView();

  @override
  State<_ReportsView> createState() => _ReportsViewState();
}

final class _ReportsViewState extends State<_ReportsView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    final categories = <(ReportCategory, String)>[
      (ReportCategory.dailyWorkshop, l10n.reportCategoryDaily),
      (ReportCategory.workerPerformance, l10n.reportCategoryWorkers),
      (ReportCategory.processPerformance, l10n.reportCategoryProcesses),
      (ReportCategory.inventory, l10n.reportCategoryInventory),
      (ReportCategory.labourFinancial, l10n.reportCategoryFinancial),
      (ReportCategory.businessInsights, l10n.reportCategoryInsights),
    ];

    return BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        final cubit = context.read<ReportsCubit>();

        return AppScaffold(
          title: l10n.reportsHeading,
          contentWidth: AppContentWidth.wide,
          actions: [
            GuideTarget(
              id: GuideTargetId.reportsExportAction,
              child: AppIconButton(
                icon: AppIcons.share,
                tooltip: l10n.reportExportAction,
                onPressed: state.bundle == null || state.isExporting
                    ? null
                    : () => ReportExportSheet.show(
                        context,
                        cubit: cubit,
                        state: state,
                      ),
              ),
            ),
            AppIconButton(
              icon: AppIcons.refresh,
              tooltip: l10n.actionRetry,
              onPressed: () => cubit.loadReports(),
            ),
          ],
          padding: EdgeInsets.zero,
          body: ListView(
            padding: AppSpacing.screenAll,
            children: [
              const ScreenFirstVisitHint(screenId: GuideScreenId.reports),
              // 1. Unified IST Presets + Collapsible Dimension Filter Bar
              GuideTarget(
                id: GuideTargetId.reportsFilterBar,
                child: AppMotionEntrance(
                  index: 0,
                  child: ReportFilterBar(
                    state: state,
                    searchController: _searchCtrl,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 2. 6 Unified Report Category Selectors
              GuideTarget(
                id: GuideTargetId.reportsCategories,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (cat, label) in categories) ...[
                        AppChip(
                          label: label,
                          selected: state.category == cat,
                          onSelected: (_) => cubit.selectCategory(cat),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              if (state.isExporting) ...[
                const AppProgressBar(),
                const SizedBox(height: AppSpacing.sm),
              ],

              // 3. Active Category Body (instant swap without full-list fade/slide)
              KeyedSubtree(
                key: ValueKey<(ReportsStatus, ReportCategory)>((
                  state.status,
                  state.category,
                )),
                child:
                    state.status == ReportsStatus.initial ||
                        state.status == ReportsStatus.loading
                    ? const AppSkeletonList(itemCount: 4)
                    : state.status == ReportsStatus.error ||
                          state.bundle == null
                    ? AppErrorView(
                        title: l10n.errorUnexpected,
                        message: state.errorMessage,
                        retryLabel: l10n.actionRetry,
                        onRetry: () => cubit.loadReports(),
                      )
                    : switch (state.category) {
                        ReportCategory.dailyWorkshop => _buildDailyCategory(
                          context,
                          state.bundle!,
                          localeCode,
                        ),
                        ReportCategory.workerPerformance =>
                          _buildWorkersCategory(context, state.bundle!),
                        ReportCategory.processPerformance =>
                          _buildProcessesCategory(context, state.bundle!),
                        ReportCategory.inventory => _buildInventoryCategory(
                          context,
                          state,
                          state.bundle!.inventory,
                          localeCode,
                        ),
                        ReportCategory.labourFinancial =>
                          _buildFinancialCategory(
                            context,
                            state,
                            state.bundle!.financial,
                            localeCode,
                          ),
                        ReportCategory.businessInsights =>
                          _buildInsightsCategory(context, state.bundle!),
                      },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _empty(BuildContext context) {
    final l10n = context.l10n;
    return AppEmptyState(
      icon: AppIcons.reports,
      title: l10n.reportsEmptyTitle,
      subtitle: l10n.reportsEmptySubtitle,
    );
  }

  // ---------------------------------------------------------------------------
  // CATEGORY 1: DAILY WORKSHOP REPORT
  // ---------------------------------------------------------------------------
  Widget _buildDailyCategory(
    BuildContext context,
    AdvancedReportsBundle b,
    String localeCode,
  ) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResponsiveMetricGrid(
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
          _empty(context)
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

  // ---------------------------------------------------------------------------
  // CATEGORY 2: WORKER PERFORMANCE
  // ---------------------------------------------------------------------------
  Widget _buildWorkersCategory(BuildContext context, AdvancedReportsBundle b) {
    final l10n = context.l10n;
    if (b.workerPerformance.isEmpty) return _empty(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final w in b.workerPerformance) ...[
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

  // ---------------------------------------------------------------------------
  // CATEGORY 3: PROCESS PERFORMANCE
  // ---------------------------------------------------------------------------
  Widget _buildProcessesCategory(
    BuildContext context,
    AdvancedReportsBundle b,
  ) {
    final l10n = context.l10n;
    if (b.processPerformance.isEmpty) return _empty(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final p in b.processPerformance) ...[
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

  String _formatTurnaround(double? hours, String naLabel) {
    if (hours == null) return naLabel;
    return AppDateTimeFormatter.formatDurationHours(hours);
  }

  // ---------------------------------------------------------------------------
  // CATEGORY 4: INVENTORY REPORTS (4 sub-tabs)
  // ---------------------------------------------------------------------------
  Widget _buildInventoryCategory(
    BuildContext context,
    ReportsState state,
    InventoryReportSection inv,
    String localeCode,
  ) {
    final l10n = context.l10n;
    final cubit = context.read<ReportsCubit>();
    final subTabs = [
      l10n.reportInvSubSummary,
      l10n.reportInvSubLots,
      l10n.reportInvSubColours,
      l10n.reportInvSubHistory,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < subTabs.length; i++) ...[
                AppChip.filter(
                  label: subTabs[i],
                  selected: state.inventorySubTab == i,
                  onSelected: (_) => cubit.selectInventorySubTab(i),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        switch (state.inventorySubTab) {
          0 => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ResponsiveMetricGrid(
                tiles: [
                  AppMetricTile(
                    label: l10n.colourInitialQtyLabel,
                    value: inv.initialStock,
                    suffix: l10n.piecesUnit,
                    icon: AppIcons.lot,
                  ),
                  AppMetricTile(
                    label: l10n.stockAvailableGoodLabel,
                    value: inv.availableGoodStock,
                    suffix: l10n.piecesUnit,
                    icon: AppIcons.successOutline,
                    tone: AppStatusTone.good,
                  ),
                  AppMetricTile(
                    label: l10n.stockPendingWorkerLabel,
                    value: inv.pendingWithWorkers,
                    suffix: l10n.piecesUnit,
                    icon: AppIcons.pending,
                    tone: inv.pendingWithWorkers > 0
                        ? AppStatusTone.pending
                        : AppStatusTone.good,
                  ),
                  AppMetricTile(
                    label: l10n.stockPendingQcLabel,
                    value: inv.pendingInspection,
                    suffix: l10n.piecesUnit,
                    icon: AppIcons.qcInspect,
                    tone: inv.pendingInspection > 0
                        ? AppStatusTone.pending
                        : AppStatusTone.neutral,
                  ),
                  AppMetricTile(
                    label: l10n.stockDamagedBucketLabel,
                    value: inv.damagedBucket,
                    suffix: l10n.piecesUnit,
                    icon: AppIcons.damaged,
                    tone: inv.damagedBucket > 0
                        ? AppStatusTone.damaged
                        : AppStatusTone.neutral,
                  ),
                  AppMetricTile(
                    label: l10n.stockLostLabel,
                    value: inv.lostStock,
                    suffix: l10n.piecesUnit,
                    icon: AppIcons.help,
                    tone: inv.lostStock > 0
                        ? AppStatusTone.info
                        : AppStatusTone.neutral,
                  ),
                  AppMetricTile(
                    label: l10n.stockShortageLabel,
                    value: inv.shortageStock,
                    suffix: l10n.piecesUnit,
                    icon: AppIcons.remove,
                    tone: inv.shortageStock > 0
                        ? AppStatusTone.info
                        : AppStatusTone.neutral,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppMetricTile(
                label: l10n.reportRefStockValueLabel,
                value: inv.referenceGoodStockValuePaise,
                isCurrencyPaise: true,
                icon: AppIcons.inventory,
                tone: AppStatusTone.info,
              ),
              const SizedBox(height: AppSpacing.xs),
              AppText(
                l10n.reportRefStockValueNote,
                variant: AppTextVariant.label,
              ),
            ],
          ),
          1 => _buildLotTable(context, inv.lotRows),
          2 => _buildColourTable(context, inv.colourBalances),
          _ => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSwitch(
                label: l10n.reportIncludeReversedLabel,
                value: state.filter.includeReversedInHistory,
                onChanged: cubit.setIncludeReversedInHistory,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildMovementHistoryTable(
                context,
                inv.movementHistory,
                localeCode,
              ),
            ],
          ),
        },
      ],
    );
  }

  Widget _buildLotTable(BuildContext context, List<LotStockReportRow> rows) {
    final l10n = context.l10n;
    if (rows.isEmpty) return _empty(context);
    return AppDataTable<LotStockReportRow>(
      enablePagination: true,
      columns: [
        AppDataColumn(label: l10n.lotNumberLabel),
        AppDataColumn(label: l10n.stockAvailableGoodLabel, numeric: true),
        AppDataColumn(label: l10n.stockPendingWorkerLabel, numeric: true),
        AppDataColumn(label: l10n.stockPendingQcLabel, numeric: true),
        AppDataColumn(label: l10n.stockDamagedBucketLabel, numeric: true),
        AppDataColumn(label: l10n.reportRefStockValueLabel, numeric: true),
      ],
      items: rows,
      cellsBuilder: (r) => [
        AppText(r.lotNumber, fontWeight: FontWeight.w700),
        AppText('${r.availableGoodStock}', variant: AppTextVariant.numeric),
        AppText('${r.pendingWithWorkers}', variant: AppTextVariant.numeric),
        AppText('${r.pendingInspection}', variant: AppTextVariant.numeric),
        AppText('${r.damagedBucket}', variant: AppTextVariant.numeric),
        AppText(
          MoneyFormatter.formatPaise(r.goodStockValuePaise),
          variant: AppTextVariant.numeric,
        ),
      ],
      mobileCardBuilder: (_, r) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            '${r.lotNumber}${r.title != null ? ' • ${r.title}' : ''}',
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppStatusBadge(
                label:
                    '${l10n.stockAvailableGoodLabel}: ${r.availableGoodStock}',
                tone: AppStatusTone.good,
              ),
              AppStatusBadge(
                label:
                    '${l10n.stockPendingWorkerLabel}: ${r.pendingWithWorkers}',
                tone: AppStatusTone.pending,
              ),
              if (r.pendingInspection > 0)
                AppStatusBadge(
                  label: '${l10n.stockPendingQcLabel}: ${r.pendingInspection}',
                  tone: AppStatusTone.pending,
                ),
              if (r.damagedBucket > 0)
                AppStatusBadge(
                  label: '${l10n.stockDamagedBucketLabel}: ${r.damagedBucket}',
                  tone: AppStatusTone.damaged,
                ),
              AppStatusBadge(
                label: MoneyFormatter.formatPaise(r.goodStockValuePaise),
                tone: AppStatusTone.info,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColourTable(
    BuildContext context,
    List<DesignColourStockBalance> rows,
  ) {
    final l10n = context.l10n;
    if (rows.isEmpty) return _empty(context);
    return AppDataTable<DesignColourStockBalance>(
      enablePagination: true,
      columns: [
        AppDataColumn(label: l10n.lotNumberLabel),
        AppDataColumn(label: l10n.designNameLabel),
        AppDataColumn(label: l10n.colourNameLabel),
        AppDataColumn(label: l10n.stockAvailableGoodLabel, numeric: true),
        AppDataColumn(label: l10n.stockPendingWorkerLabel, numeric: true),
        AppDataColumn(label: l10n.stockPendingQcLabel, numeric: true),
        AppDataColumn(label: l10n.stockDamagedBucketLabel, numeric: true),
      ],
      items: rows,
      cellsBuilder: (r) => [
        AppText(r.lotNumber),
        AppText(r.designName),
        AppText(r.colourName, fontWeight: FontWeight.w600),
        AppText(
          '${r.physicalAvailableInHouse}',
          variant: AppTextVariant.numeric,
        ),
        AppText(
          '${r.totalPendingWithWorkers}',
          variant: AppTextVariant.numeric,
        ),
        AppText('${r.totalPendingInspection}', variant: AppTextVariant.numeric),
        AppText('${r.damagedBucket}', variant: AppTextVariant.numeric),
      ],
      mobileCardBuilder: (_, r) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            '${r.lotNumber} • ${r.designName} • ${r.colourName}',
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppStatusBadge(
                label:
                    '${l10n.stockAvailableGoodLabel}: ${r.physicalAvailableInHouse}',
                tone: AppStatusTone.good,
              ),
              AppStatusBadge(
                label:
                    '${l10n.stockPendingWorkerLabel}: ${r.totalPendingWithWorkers}',
                tone: AppStatusTone.pending,
              ),
              if (r.totalPendingInspection > 0)
                AppStatusBadge(
                  label:
                      '${l10n.stockPendingQcLabel}: ${r.totalPendingInspection}',
                  tone: AppStatusTone.pending,
                ),
              if (r.damagedBucket > 0)
                AppStatusBadge(
                  label: '${l10n.stockDamagedBucketLabel}: ${r.damagedBucket}',
                  tone: AppStatusTone.damaged,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMovementHistoryTable(
    BuildContext context,
    List<StockMovementView> rows,
    String localeCode,
  ) {
    final l10n = context.l10n;
    if (rows.isEmpty) return _empty(context);
    final visible = rows.take(200).toList();
    return AppDataTable<StockMovementView>(
      enablePagination: true,
      columns: [
        AppDataColumn(label: l10n.lotNumberLabel),
        AppDataColumn(label: l10n.stockFilterAllTypes),
        AppDataColumn(label: l10n.workerNameLabel),
        AppDataColumn(label: l10n.piecesUnit, numeric: true),
      ],
      items: visible,
      cellsBuilder: (r) => [
        AppText('${r.lotNumber} / ${r.designName} / ${r.colourName}'),
        AppStatusBadge(
          label: DomainLabelLocalizer.movementType(
            l10n,
            r.movement.movementType,
          ),
          tone: DomainLabelLocalizer.movementTone(r.movement.movementType),
        ),
        AppText(r.workerName ?? '-'),
        AppText('${r.movement.quantity}', variant: AppTextVariant.numeric),
      ],
      mobileCardBuilder: (_, r) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppStatusBadge(
                label: DomainLabelLocalizer.movementType(
                  l10n,
                  r.movement.movementType,
                ),
                tone: DomainLabelLocalizer.movementTone(
                  r.movement.movementType,
                ),
              ),
              AppText(
                '${r.movement.quantity} ${l10n.piecesUnit}',
                variant: AppTextVariant.numeric,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AppText('${r.lotNumber} • ${r.designName} • ${r.colourName}'),
          AppText(
            '${r.workerName ?? '-'} • ${r.processName ?? '-'} • ${IstDateTimeHelper.formatIstDateTime(r.movement.transactionAt, locale: localeCode)}',
            variant: AppTextVariant.bodySmall,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CATEGORY 5: LABOUR & FINANCIAL REPORTS (3 sub-tabs)
  // ---------------------------------------------------------------------------
  Widget _buildFinancialCategory(
    BuildContext context,
    ReportsState state,
    FinancialReportSection fin,
    String localeCode,
  ) {
    final l10n = context.l10n;
    final cubit = context.read<ReportsCubit>();
    final subTabs = [
      l10n.reportFinSubLabour,
      l10n.reportFinSubSummary,
      l10n.reportFinSubPayments,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ResponsiveMetricGrid(
          tiles: [
            AppMetricTile(
              label: l10n.accountingEarnedLabourLabel,
              value: fin.periodEarnedLabourPaise,
              isCurrencyPaise: true,
              icon: AppIcons.work,
              tone: AppStatusTone.good,
            ),
            AppMetricTile(
              label: l10n.reportsTabPayments,
              value: fin.periodNetPaymentsPaise,
              isCurrencyPaise: true,
              icon: AppIcons.payment,
              tone: AppStatusTone.info,
            ),
            AppMetricTile(
              label: l10n.accountingOutstandingPayableLabel,
              value: fin.totalCurrentOutstandingPayablePaise,
              isCurrencyPaise: true,
              icon: AppIcons.pending,
              tone: fin.totalCurrentOutstandingPayablePaise > 0
                  ? AppStatusTone.pending
                  : AppStatusTone.good,
            ),
            AppMetricTile(
              label: l10n.accountingAdvanceCreditLabel,
              value: fin.totalCurrentAdvanceCreditPaise,
              isCurrencyPaise: true,
              icon: AppIcons.accounting,
              tone: AppStatusTone.info,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < subTabs.length; i++) ...[
                AppChip.filter(
                  label: subTabs[i],
                  selected: state.financialSubTab == i,
                  onSelected: (_) => cubit.selectFinancialSubTab(i),
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        switch (state.financialSubTab) {
          0 => _buildLabourTable(context, fin.labourEntries, localeCode),
          1 => _buildWorkerSummaryTable(context, fin.workerSummaries),
          _ => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    AppChip(
                      label: l10n.reportAllOption,
                      selected: state.filter.paymentMode == null,
                      onSelected: (_) => cubit.setPaymentModeFilter(null),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    for (final mode in PaymentMode.values) ...[
                      AppChip(
                        label: DomainLabelLocalizer.paymentMode(l10n, mode),
                        selected: state.filter.paymentMode == mode,
                        onSelected: (_) => cubit.setPaymentModeFilter(mode),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildPaymentsTable(context, fin.payments, localeCode),
            ],
          ),
        },
      ],
    );
  }

  Widget _buildLabourTable(
    BuildContext context,
    List<LabourEntryView> rows,
    String localeCode,
  ) {
    final l10n = context.l10n;
    if (rows.isEmpty) return _empty(context);
    return AppDataTable<LabourEntryView>(
      enablePagination: true,
      columns: [
        AppDataColumn(label: l10n.workerNameLabel),
        AppDataColumn(label: l10n.processNameLabel),
        AppDataColumn(label: l10n.lotNumberLabel),
        AppDataColumn(label: l10n.piecesUnit, numeric: true),
        AppDataColumn(label: l10n.accountingAmountLabel, numeric: true),
      ],
      items: rows.take(200).toList(),
      cellsBuilder: (r) => [
        AppText(r.workerName, fontWeight: FontWeight.w600),
        AppText(r.processName),
        AppText(r.lotNumber),
        AppText('${r.entry.quantity}', variant: AppTextVariant.numeric),
        AppText(
          MoneyFormatter.formatPaise(r.entry.amountPaise),
          variant: AppTextVariant.numeric,
        ),
      ],
      mobileCardBuilder: (_, r) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  '${r.workerName} • ${r.processName}',
                  fontWeight: FontWeight.w700,
                ),
                AppText(
                  '${l10n.lotLabelShort} ${r.lotNumber} • ${r.entry.quantity} ${l10n.piecesUnit} • ${IstDateTimeHelper.formatIstDate(r.entry.transactionAt, locale: localeCode)}',
                  variant: AppTextVariant.bodySmall,
                ),
              ],
            ),
          ),
          AppText(
            MoneyFormatter.formatPaise(r.entry.amountPaise),
            variant: AppTextVariant.numeric,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerSummaryTable(
    BuildContext context,
    List<WorkerFinancialSummary> rows,
  ) {
    final l10n = context.l10n;
    if (rows.isEmpty) return _empty(context);
    return AppDataTable<WorkerFinancialSummary>(
      enablePagination: true,
      columns: [
        AppDataColumn(label: l10n.workerNameLabel),
        AppDataColumn(label: l10n.accountingEarnedLabourLabel, numeric: true),
        AppDataColumn(label: l10n.accountingAdvancePaidLabel, numeric: true),
        AppDataColumn(label: l10n.accountingRegularPaidLabel, numeric: true),
        AppDataColumn(label: l10n.accountingNetBalanceLabel, numeric: true),
      ],
      items: rows,
      onRowTap: (w) => context.push(RoutePaths.workerLedger(w.workerId)),
      cellsBuilder: (w) => [
        AppText(w.workerName, fontWeight: FontWeight.w600),
        AppText(
          MoneyFormatter.formatPaise(w.earnedLabourPaise),
          variant: AppTextVariant.numeric,
        ),
        AppText(
          MoneyFormatter.formatPaise(w.advancePaymentsPaise),
          variant: AppTextVariant.numeric,
        ),
        AppText(
          MoneyFormatter.formatPaise(w.regularPaymentsPaise),
          variant: AppTextVariant.numeric,
        ),
        AppStatusBadge(
          label: MoneyFormatter.formatPaise(w.netBalancePaise),
          tone: w.netBalancePaise > 0
              ? AppStatusTone.pending
              : (w.netBalancePaise < 0
                    ? AppStatusTone.info
                    : AppStatusTone.good),
        ),
      ],
      mobileCardBuilder: (_, w) => AppActionRow(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(w.workerName, fontWeight: FontWeight.w700),
            AppText(
              '${l10n.accountingEarnedLabourLabel}: ${MoneyFormatter.formatPaise(w.earnedLabourPaise)}',
              variant: AppTextVariant.bodySmall,
            ),
          ],
        ),
        actions: [
          AppStatusBadge(
            label: MoneyFormatter.formatPaise(w.netBalancePaise),
            tone: w.netBalancePaise > 0
                ? AppStatusTone.pending
                : (w.netBalancePaise < 0
                      ? AppStatusTone.info
                      : AppStatusTone.good),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentsTable(
    BuildContext context,
    List<PaymentView> rows,
    String localeCode,
  ) {
    final l10n = context.l10n;
    if (rows.isEmpty) return _empty(context);
    return AppDataTable<PaymentView>(
      enablePagination: true,
      columns: [
        AppDataColumn(label: l10n.workerNameLabel),
        AppDataColumn(label: l10n.accountingPaymentTypeLabel),
        AppDataColumn(label: l10n.accountingPaymentModeLabel),
        AppDataColumn(label: l10n.accountingAmountLabel, numeric: true),
      ],
      items: rows.take(200).toList(),
      cellsBuilder: (p) => [
        AppText(p.workerName, fontWeight: FontWeight.w600),
        AppText(DomainLabelLocalizer.paymentType(l10n, p.payment.paymentType)),
        AppText(DomainLabelLocalizer.paymentMode(l10n, p.payment.paymentMode)),
        AppText(
          MoneyFormatter.formatPaise(p.payment.amountPaise),
          variant: AppTextVariant.numeric,
        ),
      ],
      mobileCardBuilder: (_, p) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(p.workerName, fontWeight: FontWeight.w700),
                AppText(
                  '${DomainLabelLocalizer.paymentType(l10n, p.payment.paymentType)} • '
                  '${DomainLabelLocalizer.paymentMode(l10n, p.payment.paymentMode)} • '
                  '${IstDateTimeHelper.formatIstDate(p.payment.transactionAt, locale: localeCode)}',
                  variant: AppTextVariant.bodySmall,
                ),
              ],
            ),
          ),
          AppText(
            MoneyFormatter.formatPaise(p.payment.amountPaise),
            variant: AppTextVariant.numeric,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CATEGORY 6: BUSINESS INSIGHTS
  // ---------------------------------------------------------------------------
  Widget _buildInsightsCategory(BuildContext context, AdvancedReportsBundle b) {
    final l10n = context.l10n;
    final ins = b.insights;
    final cmp = ins.periodComparison;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Production Trends Chart
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

        // 2. Period-over-Period Comparison
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

        // 3. Process Bottlenecks
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

        // 4. Top Worker Productivity Trends
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

        // 5. Labour Cost by Process
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

        // 6. Top Damaged / Lost Reasons
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

final class _ResponsiveMetricGrid extends StatelessWidget {
  const _ResponsiveMetricGrid({required this.tiles});

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
