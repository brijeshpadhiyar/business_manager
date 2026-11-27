import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/domain_label_localizer.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/reports/domain/entities/advanced_report_entities.dart';
import 'package:business_manager/features/reports/domain/entities/dashboard_report_entities.dart';
import 'package:business_manager/features/reports/presentation/bloc/reports_cubit.dart';
import 'package:business_manager/features/reports/presentation/widgets/reports_category_views.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Category 4: Inventory Reports view with 4 sub-tabs.
final class ReportsInventoryCategoryView extends StatelessWidget {
  const ReportsInventoryCategoryView({
    super.key,
    required this.state,
    required this.section,
    required this.localeCode,
  });

  final ReportsState state;
  final InventoryReportSection section;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ReportsCubit>();
    final inv = section;
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
              ReportResponsiveMetricGrid(
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
          1 => _LotStockTable(rows: inv.lotRows),
          2 => _ColourBalanceTable(rows: inv.colourBalances),
          _ => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSwitch(
                label: l10n.reportIncludeReversedLabel,
                value: state.filter.includeReversedInHistory,
                onChanged: cubit.setIncludeReversedInHistory,
              ),
              const SizedBox(height: AppSpacing.sm),
              _MovementHistoryTable(
                rows: inv.movementHistory,
                localeCode: localeCode,
              ),
            ],
          ),
        },
      ],
    );
  }
}

/// Category 5: Labour & Financial Reports view with 3 sub-tabs.
final class ReportsFinancialCategoryView extends StatelessWidget {
  const ReportsFinancialCategoryView({
    super.key,
    required this.state,
    required this.section,
    required this.localeCode,
  });

  final ReportsState state;
  final FinancialReportSection section;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<ReportsCubit>();
    final fin = section;
    final subTabs = [
      l10n.reportFinSubLabour,
      l10n.reportFinSubSummary,
      l10n.reportFinSubPayments,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ReportResponsiveMetricGrid(
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
          0 => _LabourEntriesTable(
            rows: fin.labourEntries,
            localeCode: localeCode,
          ),
          1 => _WorkerSummaryTable(rows: fin.workerSummaries),
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
              _PaymentsTable(rows: fin.payments, localeCode: localeCode),
            ],
          ),
        },
      ],
    );
  }
}

final class _LotStockTable extends StatelessWidget {
  const _LotStockTable({required this.rows});

  final List<LotStockReportRow> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (rows.isEmpty) return const ReportsEmptyView();
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
}

final class _ColourBalanceTable extends StatelessWidget {
  const _ColourBalanceTable({required this.rows});

  final List<DesignColourStockBalance> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (rows.isEmpty) return const ReportsEmptyView();
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
}

final class _MovementHistoryTable extends StatelessWidget {
  const _MovementHistoryTable({required this.rows, required this.localeCode});

  final List<StockMovementView> rows;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (rows.isEmpty) return const ReportsEmptyView();
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
}

final class _LabourEntriesTable extends StatelessWidget {
  const _LabourEntriesTable({required this.rows, required this.localeCode});

  final List<LabourEntryView> rows;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (rows.isEmpty) return const ReportsEmptyView();
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
}

final class _WorkerSummaryTable extends StatelessWidget {
  const _WorkerSummaryTable({required this.rows});

  final List<WorkerFinancialSummary> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (rows.isEmpty) return const ReportsEmptyView();
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
}

final class _PaymentsTable extends StatelessWidget {
  const _PaymentsTable({required this.rows, required this.localeCode});

  final List<PaymentView> rows;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    if (rows.isEmpty) return const ReportsEmptyView();
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
}
