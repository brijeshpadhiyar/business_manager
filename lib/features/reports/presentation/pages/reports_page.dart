import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/domain_label_localizer.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/reports/domain/entities/dashboard_report_entities.dart';
import 'package:business_manager/features/reports/presentation/bloc/reports_cubit.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Comprehensive 10-report StitchFlow Business Insights module powered by
/// pure domain calculators and live SQLite data.
final class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReportsCubit>(
      create: (_) => getIt<ReportsCubit>()..loadReports(),
      child: _ReportsView(initialTab: initialTab),
    );
  }
}

final class _ReportsView extends StatefulWidget {
  const _ReportsView({required this.initialTab});

  final int initialTab;

  @override
  State<_ReportsView> createState() => _ReportsViewState();
}

final class _ReportsViewState extends State<_ReportsView> {
  late int _tab = widget.initialTab;
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

    final tabs = [
      l10n.reportsTabStockSummary,
      l10n.reportsTabLots,
      l10n.reportsTabColours,
      l10n.reportsTabWorkers,
      l10n.reportsTabProcesses,
      l10n.reportsTabPending,
      l10n.reportsTabDamagedLost,
      l10n.reportsTabLabour,
      l10n.reportsTabWorkerLedger,
      l10n.reportsTabPayments,
    ];

    return AppScaffold(
      title: l10n.reportsHeading,
      actions: [
        AppIconButton(
          icon: Icons.refresh_rounded,
          tooltip: l10n.actionRetry,
          onPressed: () => context.read<ReportsCubit>().loadReports(),
        ),
      ],
      padding: EdgeInsets.zero,
      body: BlocBuilder<ReportsCubit, ReportsState>(
        builder: (context, state) {
          return ListView(
            padding: AppSpacing.screenAll,
            children: [
              // Filters bar
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: _searchCtrl,
                      label: l10n.reportsSearchHint,
                      prefixIcon: Icons.search_rounded,
                      onChanged: (q) => context
                          .read<ReportsCubit>()
                          .loadReports(searchQuery: q),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: AppDatePicker(
                            label: l10n.accountingFromDateLabel,
                            selectedUtcMillis: state.fromUtcMillis,
                            onDateSelectedUtcMillis: (utc) {
                              final ist = IstDateTimeHelper.fromUtcMillisToIst(
                                utc,
                              );
                              context.read<ReportsCubit>().loadReports(
                                fromUtcMillis:
                                    IstDateTimeHelper.istDateTimeToUtcMillis(
                                      year: ist.year,
                                      month: ist.month,
                                      day: ist.day,
                                    ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppDatePicker(
                            label: l10n.accountingToDateLabel,
                            selectedUtcMillis: state.toUtcMillis,
                            onDateSelectedUtcMillis: (utc) {
                              final ist = IstDateTimeHelper.fromUtcMillisToIst(
                                utc,
                              );
                              context.read<ReportsCubit>().loadReports(
                                toUtcMillis:
                                    IstDateTimeHelper.istDateTimeToUtcMillis(
                                      year: ist.year,
                                      month: ist.month,
                                      day: ist.day,
                                      hour: 23,
                                      minute: 59,
                                      second: 59,
                                    ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    if (state.fromUtcMillis != null ||
                        state.toUtcMillis != null ||
                        state.searchQuery.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Align(
                        alignment: Alignment.centerRight,
                        child: AppButton(
                          label: l10n.accountingClearFilters,
                          variant: AppButtonVariant.text,
                          onPressed: () {
                            _searchCtrl.clear();
                            context.read<ReportsCubit>().loadReports(
                              searchQuery: '',
                              clearFrom: true,
                              clearTo: true,
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // 10 Report Selectors
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (int i = 0; i < tabs.length; i++) ...[
                      ChoiceChip(
                        label: Text(tabs[i]),
                        selected: _tab == i,
                        onSelected: (_) => setState(() => _tab = i),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              if (state.status == ReportsStatus.initial ||
                  state.status == ReportsStatus.loading)
                const AppSkeletonList(itemCount: 4)
              else if (state.status == ReportsStatus.error ||
                  state.bundle == null)
                AppErrorView(
                  title: l10n.errorUnexpected,
                  message: state.errorMessage,
                  retryLabel: l10n.actionRetry,
                  onRetry: () => context.read<ReportsCubit>().loadReports(),
                )
              else
                switch (_tab) {
                  0 => _buildStockSummary(context, state.bundle!),
                  1 => _buildLotReport(context, state.bundle!.lotRows),
                  2 => _buildColourReport(
                    context,
                    state.bundle!.colourBalances,
                  ),
                  3 => _buildWorkerStockReport(
                    context,
                    state.bundle!.workerStockRows,
                  ),
                  4 => _buildProcessStockReport(
                    context,
                    state.bundle!.processStockRows,
                  ),
                  5 => _buildPendingReport(
                    context,
                    state.bundle!.openIssues,
                    localeCode,
                  ),
                  6 => _buildDamagedLostReport(
                    context,
                    state.bundle!.damagedLostShortageMovements,
                    localeCode,
                  ),
                  7 => _buildLabourReport(
                    context,
                    state.bundle!.labourEntries,
                    localeCode,
                  ),
                  8 => _buildWorkerAccountsReport(
                    context,
                    state.bundle!.workerFinancialSummaries,
                  ),
                  _ => _buildPaymentsReport(
                    context,
                    state.bundle!.payments,
                    localeCode,
                  ),
                },
            ],
          );
        },
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final l10n = context.l10n;
    return AppEmptyState(
      icon: Icons.analytics_outlined,
      title: l10n.reportsEmptyTitle,
      subtitle: l10n.reportsEmptySubtitle,
    );
  }

  Widget _buildStockSummary(
    BuildContext context,
    BusinessReportsBundle bundle,
  ) {
    final l10n = context.l10n;
    final initQty = bundle.colourBalances.fold<int>(
      0,
      (s, b) => s + b.initialQuantity,
    );
    final good = bundle.colourBalances.fold<int>(
      0,
      (s, b) => s + b.physicalAvailableInHouse,
    );
    final pending = bundle.colourBalances.fold<int>(
      0,
      (s, b) => s + b.totalPendingWithWorkers,
    );
    final damaged = bundle.colourBalances.fold<int>(
      0,
      (s, b) => s + b.damagedBucket,
    );
    final lost = bundle.colourBalances.fold<int>(0, (s, b) => s + b.totalLost);
    final shortage = bundle.colourBalances.fold<int>(
      0,
      (s, b) => s + b.totalShortage,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 700 ? 3 : 2;
        final tileW =
            (constraints.maxWidth - AppSpacing.sm * (cols - 1)) / cols;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            SizedBox(
              width: tileW,
              child: AppMetricTile(
                label: l10n.colourInitialQtyLabel,
                value: initQty,
                suffix: l10n.piecesUnit,
                icon: Icons.inventory_2_outlined,
              ),
            ),
            SizedBox(
              width: tileW,
              child: AppMetricTile(
                label: l10n.stockAvailableGoodLabel,
                value: good,
                suffix: l10n.piecesUnit,
                icon: Icons.check_circle_outline_rounded,
                tone: AppStatusTone.good,
              ),
            ),
            SizedBox(
              width: tileW,
              child: AppMetricTile(
                label: l10n.stockPendingWorkerLabel,
                value: pending,
                suffix: l10n.piecesUnit,
                icon: Icons.pending_actions_rounded,
                tone: AppStatusTone.pending,
              ),
            ),
            SizedBox(
              width: tileW,
              child: AppMetricTile(
                label: l10n.stockDamagedBucketLabel,
                value: damaged,
                suffix: l10n.piecesUnit,
                icon: Icons.report_problem_outlined,
                tone: damaged > 0
                    ? AppStatusTone.damaged
                    : AppStatusTone.neutral,
              ),
            ),
            SizedBox(
              width: tileW,
              child: AppMetricTile(
                label: l10n.stockLostLabel,
                value: lost,
                suffix: l10n.piecesUnit,
                icon: Icons.help_outline_rounded,
                tone: lost > 0 ? AppStatusTone.info : AppStatusTone.neutral,
              ),
            ),
            SizedBox(
              width: tileW,
              child: AppMetricTile(
                label: l10n.stockShortageLabel,
                value: shortage,
                suffix: l10n.piecesUnit,
                icon: Icons.remove_circle_outline_rounded,
                tone: shortage > 0 ? AppStatusTone.info : AppStatusTone.neutral,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLotReport(BuildContext context, List<LotStockReportRow> rows) {
    final l10n = context.l10n;
    if (rows.isEmpty) return _empty(context);
    return AppDataTable<LotStockReportRow>(
      columns: [
        AppDataColumn(label: l10n.lotNumberLabel),
        AppDataColumn(label: l10n.colourInitialQtyLabel, numeric: true),
        AppDataColumn(label: l10n.stockAvailableGoodLabel, numeric: true),
        AppDataColumn(label: l10n.stockPendingWorkerLabel, numeric: true),
        AppDataColumn(label: l10n.stockDamagedBucketLabel, numeric: true),
      ],
      items: rows,
      cellsBuilder: (r) => [
        AppText(r.lotNumber, fontWeight: FontWeight.w700),
        AppText('${r.initialQuantity}', variant: AppTextVariant.numeric),
        AppText('${r.availableGoodStock}', variant: AppTextVariant.numeric),
        AppText('${r.pendingWithWorkers}', variant: AppTextVariant.numeric),
        AppText('${r.damagedBucket}', variant: AppTextVariant.numeric),
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

  Widget _buildColourReport(
    BuildContext context,
    List<DesignColourStockBalance> rows,
  ) {
    final l10n = context.l10n;
    if (rows.isEmpty) return _empty(context);
    return AppDataTable<DesignColourStockBalance>(
      columns: [
        AppDataColumn(label: l10n.lotNumberLabel),
        AppDataColumn(label: l10n.designNameLabel),
        AppDataColumn(label: l10n.colourNameLabel),
        AppDataColumn(label: l10n.stockAvailableGoodLabel, numeric: true),
        AppDataColumn(label: l10n.stockPendingWorkerLabel, numeric: true),
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
        AppText('${r.damagedBucket}', variant: AppTextVariant.numeric),
      ],
      mobileCardBuilder: (_, r) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  '${r.lotNumber} • ${r.designName} • ${r.colourName}',
                  fontWeight: FontWeight.w700,
                ),
                AppText(
                  '${l10n.colourInitialQtyLabel}: ${r.initialQuantity}',
                  variant: AppTextVariant.bodySmall,
                ),
              ],
            ),
          ),
          AppStatusBadge(
            label:
                '${r.physicalAvailableInHouse} / ${r.totalPendingWithWorkers}',
            tone: AppStatusTone.good,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkerStockReport(
    BuildContext context,
    List<WorkerStockSummary> rows,
  ) {
    final l10n = context.l10n;
    if (rows.isEmpty) return _empty(context);
    return AppDataTable<WorkerStockSummary>(
      columns: [
        AppDataColumn(label: l10n.workerNameLabel),
        AppDataColumn(label: l10n.stockIssuedLabel, numeric: true),
        AppDataColumn(label: l10n.stockGoodReturnedLabel, numeric: true),
        AppDataColumn(label: l10n.stockDamagedBucketLabel, numeric: true),
        AppDataColumn(label: l10n.stockRemainingPendingLabel, numeric: true),
      ],
      items: rows,
      cellsBuilder: (r) => [
        AppText(r.workerName, fontWeight: FontWeight.w600),
        AppText('${r.issued}', variant: AppTextVariant.numeric),
        AppText('${r.goodReturned}', variant: AppTextVariant.numeric),
        AppText('${r.damaged}', variant: AppTextVariant.numeric),
        AppText('${r.pending}', variant: AppTextVariant.numeric),
      ],
      mobileCardBuilder: (_, r) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(r.workerName, fontWeight: FontWeight.w700),
                AppText(
                  '${l10n.stockIssuedLabel}: ${r.issued} • ${l10n.stockGoodReturnedLabel}: ${r.goodReturned}',
                  variant: AppTextVariant.bodySmall,
                ),
              ],
            ),
          ),
          AppStatusBadge(
            label: '${r.pending} ${l10n.piecesUnit}',
            tone: r.pending > 0 ? AppStatusTone.pending : AppStatusTone.good,
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStockReport(
    BuildContext context,
    List<ProcessStockSummary> rows,
  ) {
    final l10n = context.l10n;
    if (rows.isEmpty) return _empty(context);
    return AppDataTable<ProcessStockSummary>(
      columns: [
        AppDataColumn(label: l10n.processNameLabel),
        AppDataColumn(label: l10n.stockIssuedLabel, numeric: true),
        AppDataColumn(label: l10n.stockGoodReturnedLabel, numeric: true),
        AppDataColumn(label: l10n.stockDamagedBucketLabel, numeric: true),
        AppDataColumn(label: l10n.stockRemainingPendingLabel, numeric: true),
      ],
      items: rows,
      cellsBuilder: (r) => [
        AppText(r.processName, fontWeight: FontWeight.w600),
        AppText('${r.issued}', variant: AppTextVariant.numeric),
        AppText('${r.goodReturned}', variant: AppTextVariant.numeric),
        AppText('${r.damaged}', variant: AppTextVariant.numeric),
        AppText('${r.pending}', variant: AppTextVariant.numeric),
      ],
      mobileCardBuilder: (_, r) => Row(
        children: [
          Expanded(child: AppText(r.processName, fontWeight: FontWeight.w700)),
          AppStatusBadge(
            label: '${r.pending} ${l10n.piecesUnit}',
            tone: r.pending > 0 ? AppStatusTone.pending : AppStatusTone.good,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReport(
    BuildContext context,
    List<OpenIssueSummary> rows,
    String localeCode,
  ) {
    final l10n = context.l10n;
    if (rows.isEmpty) return _empty(context);
    return AppDataTable<OpenIssueSummary>(
      columns: [
        AppDataColumn(label: l10n.lotNumberLabel),
        AppDataColumn(label: l10n.processNameLabel),
        AppDataColumn(label: l10n.workerNameLabel),
        AppDataColumn(label: l10n.stockIssuedLabel, numeric: true),
        AppDataColumn(label: l10n.stockRemainingPendingLabel, numeric: true),
      ],
      items: rows,
      onRowTap: (item) =>
          context.push(RoutePaths.stockReturn(item.issueView.movement.id)),
      cellsBuilder: (r) => [
        AppText(
          '${r.issueView.lotNumber} / ${r.issueView.designName} / ${r.issueView.colourName}',
        ),
        AppText(r.issueView.processName ?? '-'),
        AppText(r.issueView.workerName ?? '-'),
        AppText('${r.issuedQuantity}', variant: AppTextVariant.numeric),
        AppStatusBadge(
          label: '${r.remainingPending}',
          tone: AppStatusTone.pending,
        ),
      ],
      mobileCardBuilder: (_, r) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  '${r.issueView.lotNumber} • ${r.issueView.colourName}',
                  fontWeight: FontWeight.w700,
                ),
                AppText(
                  '${r.issueView.workerName ?? '-'} • ${r.issueView.processName ?? '-'} • ${IstDateTimeHelper.formatIstDate(r.issueView.movement.transactionAt, locale: localeCode)}',
                  variant: AppTextVariant.bodySmall,
                ),
              ],
            ),
          ),
          AppStatusBadge(
            label: '${r.remainingPending} ${l10n.piecesUnit}',
            tone: AppStatusTone.pending,
          ),
        ],
      ),
    );
  }

  Widget _buildDamagedLostReport(
    BuildContext context,
    List<StockMovementView> rows,
    String localeCode,
  ) {
    final l10n = context.l10n;
    if (rows.isEmpty) return _empty(context);
    return AppDataTable<StockMovementView>(
      columns: [
        AppDataColumn(label: l10n.lotNumberLabel),
        AppDataColumn(label: l10n.stockFilterAllTypes),
        AppDataColumn(label: l10n.workerNameLabel),
        AppDataColumn(label: l10n.piecesUnit, numeric: true),
        AppDataColumn(label: l10n.stockSettlementReasonLabel),
      ],
      items: rows,
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
        AppText(r.movement.reason ?? '-'),
      ],
      mobileCardBuilder: (_, r) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: AppStatusBadge(
                  label: DomainLabelLocalizer.movementType(
                    l10n,
                    r.movement.movementType,
                  ),
                  tone: DomainLabelLocalizer.movementTone(
                    r.movement.movementType,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppText(
                '${r.movement.quantity} ${l10n.piecesUnit}',
                variant: AppTextVariant.numeric,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AppText('${r.lotNumber} • ${r.designName} • ${r.colourName}'),
          if (r.movement.reason != null)
            AppText(r.movement.reason!, variant: AppTextVariant.bodySmall),
          AppText(
            IstDateTimeHelper.formatIstDateTime(
              r.movement.transactionAt,
              locale: localeCode,
            ),
            variant: AppTextVariant.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildLabourReport(
    BuildContext context,
    List<LabourEntryView> rows,
    String localeCode,
  ) {
    final l10n = context.l10n;
    if (rows.isEmpty) return _empty(context);
    final totalPayable = rows.fold<int>(
      0,
      (s, r) =>
          (r.entry.isPayable && !r.isReversed) ? s + r.entry.amountPaise : s,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppMetricTile(
          label: l10n.accountingEarnedLabourLabel,
          value: totalPayable,
          isCurrencyPaise: true,
          tone: AppStatusTone.good,
        ),
        const SizedBox(height: AppSpacing.md),
        AppDataTable<LabourEntryView>(
          columns: [
            AppDataColumn(label: l10n.workerNameLabel),
            AppDataColumn(label: l10n.processNameLabel),
            AppDataColumn(label: l10n.lotNumberLabel),
            AppDataColumn(label: l10n.piecesUnit, numeric: true),
            AppDataColumn(label: l10n.accountingAmountLabel, numeric: true),
          ],
          items: rows,
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
        ),
      ],
    );
  }

  Widget _buildWorkerAccountsReport(
    BuildContext context,
    List<WorkerFinancialSummary> rows,
  ) {
    final l10n = context.l10n;
    if (rows.isEmpty) return _empty(context);
    return AppDataTable<WorkerFinancialSummary>(
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
      mobileCardBuilder: (_, w) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(w.workerName, fontWeight: FontWeight.w700),
                AppText(
                  '${l10n.accountingEarnedLabourLabel}: ${MoneyFormatter.formatPaise(w.earnedLabourPaise)}',
                  variant: AppTextVariant.bodySmall,
                ),
              ],
            ),
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
      ),
    );
  }

  Widget _buildPaymentsReport(
    BuildContext context,
    List<PaymentView> rows,
    String localeCode,
  ) {
    final l10n = context.l10n;
    if (rows.isEmpty) return _empty(context);
    return AppDataTable<PaymentView>(
      columns: [
        AppDataColumn(label: l10n.workerNameLabel),
        AppDataColumn(label: l10n.accountingPaymentTypeLabel),
        AppDataColumn(label: l10n.accountingPaymentModeLabel),
        AppDataColumn(label: l10n.accountingAmountLabel, numeric: true),
      ],
      items: rows,
      cellsBuilder: (r) => [
        AppText(r.workerName, fontWeight: FontWeight.w600),
        AppText(r.payment.paymentType.dbValue),
        AppText(r.payment.paymentMode.dbValue),
        AppText(
          MoneyFormatter.formatPaise(r.payment.amountPaise),
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
                  '${r.workerName} • ${r.payment.paymentType.dbValue}',
                  fontWeight: FontWeight.w700,
                ),
                AppText(
                  '${r.payment.paymentMode.dbValue} • ${IstDateTimeHelper.formatIstDateTime(r.payment.transactionAt, locale: localeCode)}',
                  variant: AppTextVariant.bodySmall,
                ),
              ],
            ),
          ),
          AppText(
            MoneyFormatter.formatPaise(r.payment.amountPaise),
            variant: AppTextVariant.numeric,
            fontWeight: FontWeight.w700,
          ),
        ],
      ),
    );
  }
}
