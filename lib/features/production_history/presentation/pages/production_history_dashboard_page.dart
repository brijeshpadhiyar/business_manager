import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/production_history/presentation/bloc/production_history_dashboard_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Screen 1: StitchFlow Production History Dashboard.
///
/// Unified searchable, filterable, paginated hub reconciling Lot, Worker,
/// Process, Quality Inspection, Rejection, and Financial Ledger metrics with
/// one-tap cross-navigation to every entity and transaction receipt.
final class ProductionHistoryDashboardPage extends StatelessWidget {
  const ProductionHistoryDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProductionHistoryDashboardCubit>(
      create: (_) => getIt<ProductionHistoryDashboardCubit>()..load(),
      child: const _ProductionHistoryDashboardView(),
    );
  }
}

final class _ProductionHistoryDashboardView extends StatelessWidget {
  const _ProductionHistoryDashboardView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    return BlocBuilder<
      ProductionHistoryDashboardCubit,
      ProductionHistoryDashboardState
    >(
      builder: (context, state) {
        final cubit = context.read<ProductionHistoryDashboardCubit>();
        return AppScaffold(
          title: l10n.prodHistoryDashboardTitle,
          contentWidth: AppContentWidth.wide,
          actions: [
            AppIconButton(
              icon: AppIcons.qcInspect,
              tooltip: l10n.navInspectionQueue,
              onPressed: () async {
                await context.push(RoutePaths.inspectionQueue);
                if (context.mounted) await cubit.load();
              },
            ),
            AppIconButton(
              icon: AppIcons.refresh,
              tooltip: l10n.actionRetry,
              onPressed: () => cubit.load(),
            ),
          ],
          body: switch (state.status) {
            ProductionHistoryLoadStatus.initial ||
            ProductionHistoryLoadStatus.loading when state.data == null =>
              const AppSkeletonList(itemCount: 4),
            ProductionHistoryLoadStatus.error when state.data == null =>
              AppErrorView(
                title: l10n.errorUnexpected,
                message: state.errorMessage,
                retryLabel: l10n.actionRetry,
                onRetry: () => cubit.load(),
              ),
            _ => _buildContent(context, state, localeCode),
          },
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ProductionHistoryDashboardState state,
    String localeCode,
  ) {
    final l10n = context.l10n;
    final cubit = context.read<ProductionHistoryDashboardCubit>();
    final data = state.data!;
    final filter = state.filter;
    final options = state.options;

    return RefreshIndicator(
      onRefresh: () => cubit.load(),
      child: ListView(
        children: [
          // Quick Navigation Strip to Worker History, Process History, Inspection Queue
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                label:
                    '${l10n.navInspectionQueue} (${data.pendingReturnsCount + data.openRejectionsCount})',
                icon: AppIcons.qcInspect,
                onPressed: () async {
                  await context.push(RoutePaths.inspectionQueue);
                  if (context.mounted) await cubit.load();
                },
              ),
              AppButton(
                label: l10n.navWorkerHistory,
                icon: AppIcons.worker,
                variant: AppButtonVariant.secondary,
                onPressed: () =>
                    context.push(RoutePaths.workerProductionHistory),
              ),
              AppButton(
                label: l10n.navProcessHistory,
                icon: AppIcons.process,
                variant: AppButtonVariant.secondary,
                onPressed: () =>
                    context.push(RoutePaths.processProductionHistory),
              ),
              AppButton(
                label: l10n.navReports,
                icon: AppIcons.reports,
                variant: AppButtonVariant.outlined,
                onPressed: () => context.push(RoutePaths.reports),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Reconciled KPI Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth >= 900
                  ? 4
                  : (constraints.maxWidth >= 560 ? 3 : 2);
              final tileW =
                  (constraints.maxWidth - (AppSpacing.sm * (cols - 1))) / cols;
              return Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SizedBox(
                    width: tileW,
                    child: AppMetricTile(
                      label: l10n.prodHistoryTotalAssigned,
                      value: data.totalAssignedQty,
                      suffix: l10n.piecesUnit,
                      icon: AppIcons.stockIssue,
                      tone: AppStatusTone.info,
                    ),
                  ),
                  SizedBox(
                    width: tileW,
                    child: AppMetricTile(
                      label: l10n.prodHistoryTotalAccepted,
                      value: data.totalAcceptedQty,
                      suffix: l10n.piecesUnit,
                      icon: AppIcons.qcPassed,
                      tone: AppStatusTone.good,
                    ),
                  ),
                  SizedBox(
                    width: tileW,
                    child: AppMetricTile(
                      label: l10n.prodHistoryPendingInspection,
                      value: data.totalPendingInspectionQty,
                      suffix: l10n.piecesUnit,
                      icon: AppIcons.qcInspect,
                      tone: data.totalPendingInspectionQty > 0
                          ? AppStatusTone.pending
                          : AppStatusTone.neutral,
                      onTap: () => context.push(RoutePaths.inspectionQueue),
                    ),
                  ),
                  SizedBox(
                    width: tileW,
                    child: AppMetricTile(
                      label: l10n.prodHistoryOutstandingWork,
                      value: data.totalOutstandingQty,
                      suffix: l10n.piecesUnit,
                      icon: AppIcons.pending,
                      tone: data.totalOutstandingQty > 0
                          ? AppStatusTone.pending
                          : AppStatusTone.good,
                    ),
                  ),
                  SizedBox(
                    width: tileW,
                    child: AppMetricTile(
                      label: l10n.prodHistoryTotalRejected,
                      value: data.totalRejectedQty,
                      suffix: l10n.piecesUnit,
                      icon: AppIcons.damaged,
                      tone: data.totalRejectedQty > 0
                          ? AppStatusTone.damaged
                          : AppStatusTone.neutral,
                      onTap: () => context.push(RoutePaths.inspectionQueue),
                    ),
                  ),
                  SizedBox(
                    width: tileW,
                    child: AppMetricTile(
                      label: l10n.prodHistoryTotalEarned,
                      value: data.totalEarnedPaise,
                      isCurrencyPaise: true,
                      icon: AppIcons.work,
                      tone: AppStatusTone.good,
                    ),
                  ),
                  SizedBox(
                    width: tileW,
                    child: AppMetricTile(
                      label: l10n.prodHistoryTotalPaid,
                      value: data.totalPaidPaise,
                      isCurrencyPaise: true,
                      icon: AppIcons.payment,
                      tone: AppStatusTone.info,
                    ),
                  ),
                  SizedBox(
                    width: tileW,
                    child: AppMetricTile(
                      label: l10n.prodHistoryOutstandingPayable,
                      value: data.totalOutstandingPayablePaise,
                      isCurrencyPaise: true,
                      icon: AppIcons.accounting,
                      tone: data.totalOutstandingPayablePaise > 0
                          ? AppStatusTone.pending
                          : AppStatusTone.good,
                      onTap: () => context.push(RoutePaths.accounting),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),

          // Search & Multi-Dimension Filters Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppSearchField(
                  label: l10n.prodHistorySearchHint,
                  onChanged: (q) =>
                      cubit.updateFilter(filter.copyWith(searchQuery: q)),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Phones: filters fold behind one toggle so the feed starts
                // near the top of the screen.
                AppCollapsibleFilters(
                  activeCount:
                      [
                        filter.fromUtcMillis,
                        filter.toUtcMillis,
                        filter.lotId,
                        filter.workerId,
                        filter.processId,
                        filter.designName,
                        filter.colourName,
                      ].where((v) => v != null).length +
                      (filter.onlyPending ? 1 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          AppAdaptiveField(
                            maxWidth: 210,
                            child: AppDropdown<String>(
                              label: l10n.lotsHeading,
                              value: filter.lotId ?? '__ALL__',
                              items: [
                                '__ALL__',
                                ...options.lots.map((o) => o.id),
                              ],
                              itemLabelBuilder: (id) {
                                if (id == '__ALL__') {
                                  return l10n.prodHistoryAllEntries;
                                }
                                final item = options.lots.firstWhere(
                                  (o) => o.id == id,
                                );
                                return item.isActive
                                    ? item.label
                                    : '${item.label} (${l10n.statusInactive})';
                              },
                              onChanged: (v) => cubit.updateFilter(
                                v == null || v == '__ALL__'
                                    ? filter.copyWith(clearLot: true)
                                    : filter.copyWith(lotId: v),
                              ),
                            ),
                          ),
                          AppAdaptiveField(
                            maxWidth: 210,
                            child: AppDropdown<String>(
                              label: l10n.navWorkers,
                              value: filter.workerId ?? '__ALL__',
                              items: [
                                '__ALL__',
                                ...options.workers.map((o) => o.id),
                              ],
                              itemLabelBuilder: (id) {
                                if (id == '__ALL__') {
                                  return l10n.prodHistoryAllEntries;
                                }
                                final item = options.workers.firstWhere(
                                  (o) => o.id == id,
                                );
                                return item.isActive
                                    ? item.label
                                    : '${item.label} (${l10n.statusInactive})';
                              },
                              onChanged: (v) => cubit.updateFilter(
                                v == null || v == '__ALL__'
                                    ? filter.copyWith(clearWorker: true)
                                    : filter.copyWith(workerId: v),
                              ),
                            ),
                          ),
                          AppAdaptiveField(
                            maxWidth: 210,
                            child: AppDropdown<String>(
                              label: l10n.navProcesses,
                              value: filter.processId ?? '__ALL__',
                              items: [
                                '__ALL__',
                                ...options.processes.map((o) => o.id),
                              ],
                              itemLabelBuilder: (id) {
                                if (id == '__ALL__') {
                                  return l10n.prodHistoryAllEntries;
                                }
                                final item = options.processes.firstWhere(
                                  (o) => o.id == id,
                                );
                                return item.isActive
                                    ? item.label
                                    : '${item.label} (${l10n.statusInactive})';
                              },
                              onChanged: (v) => cubit.updateFilter(
                                v == null || v == '__ALL__'
                                    ? filter.copyWith(clearProcess: true)
                                    : filter.copyWith(processId: v),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppFormRow(
                        spacing: AppSpacing.sm,
                        children: [
                          AppDatePicker(
                            label: l10n.accountingFromDateLabel,
                            selectedUtcMillis: filter.fromUtcMillis,
                            onDateSelectedUtcMillis: (utc) {
                              final ist = IstDateTimeHelper.fromUtcMillisToIst(
                                utc,
                              );
                              final start =
                                  IstDateTimeHelper.istDateTimeToUtcMillis(
                                    year: ist.year,
                                    month: ist.month,
                                    day: ist.day,
                                  );
                              cubit.updateFilter(
                                filter.copyWith(fromUtcMillis: start),
                              );
                            },
                          ),
                          AppDatePicker(
                            label: l10n.accountingToDateLabel,
                            selectedUtcMillis: filter.toUtcMillis,
                            onDateSelectedUtcMillis: (utc) {
                              final ist = IstDateTimeHelper.fromUtcMillisToIst(
                                utc,
                              );
                              final end =
                                  IstDateTimeHelper.istDateTimeToUtcMillis(
                                    year: ist.year,
                                    month: ist.month,
                                    day: ist.day,
                                    hour: 23,
                                    minute: 59,
                                    second: 59,
                                  );
                              cubit.updateFilter(
                                filter.copyWith(toUtcMillis: end),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          AppChip.filter(
                            label: l10n.prodHistoryOnlyPending,
                            selected: filter.onlyPending,
                            onSelected: (v) => cubit.updateFilter(
                              filter.copyWith(onlyPending: v),
                            ),
                          ),
                          AppButton(
                            label: l10n.accountingClearFilters,
                            variant: AppButtonVariant.text,
                            onPressed: () => cubit.clearFilters(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Unified Paginated Transaction Feed
          AppHeading(
            '${l10n.prodHistoryDashboardTitle} (${data.totalItemsCount})',
            level: AppHeadingLevel.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (data.items.isEmpty)
            AppEmptyState(
              icon: AppIcons.productionHistory,
              title: l10n.prodHistoryDashboardTitle,
              subtitle: l10n.prodHistoryDashboardSubtitle,
            )
          else ...[
            for (final item in data.items) ...[
              _HistoryFeedCard(item: item, localeCode: localeCode),
              const SizedBox(height: AppSpacing.sm),
            ],
            // Pagination Controls
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppButton(
                  label: 'Previous',
                  icon: AppIcons.chevronLeft,
                  variant: AppButtonVariant.outlined,
                  onPressed: data.page > 0 ? () => cubit.previousPage() : null,
                ),
                AppText(
                  'Page ${data.page + 1} (${data.items.length} / ${data.totalItemsCount})',
                  variant: AppTextVariant.bodySmall,
                ),
                AppButton(
                  label: 'Next',
                  icon: AppIcons.chevronRight,
                  variant: AppButtonVariant.outlined,
                  onPressed: data.hasMore ? () => cubit.nextPage() : null,
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

final class _HistoryFeedCard extends StatelessWidget {
  const _HistoryFeedCard({required this.item, required this.localeCode});

  final ProductionHistoryFeedItem item;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tone = item.isWarning
        ? AppStatusTone.pending
        : (item.isPositive ? AppStatusTone.good : AppStatusTone.info);

    return AppCard.listItem(
      onTap: () => context.push(
        RoutePaths.productionTransactionDetail(
          item.transactionKind.routeSegment,
          item.transactionId,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppStatusBadge(label: item.badgeLabel, tone: tone),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: AppText(
                  item.title,
                  fontWeight: FontWeight.w700,
                  maxLines: 1,
                ),
              ),
              AppText(
                '${MoneyFormatter.formatQuantity(item.quantity)} ${l10n.piecesUnit}',
                variant: AppTextVariant.numeric,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
          const SizedBox(height: 4),
          AppText(item.subtitle, variant: AppTextVariant.bodySmall),
          if (item.amountPaise != null && item.amountPaise! > 0) ...[
            const SizedBox(height: 2),
            AppText(
              '${MoneyFormatter.formatPaise(item.amountPaise!)}${item.ratePaise != null ? ' @ ${MoneyFormatter.formatPaise(item.ratePaise!)}/pc' : ''}',
              variant: AppTextVariant.numeric,
              fontWeight: FontWeight.w600,
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppText(
                AppDateTimeFormatter.formatDateTime(
                  item.timestampUtcMillis,
                  locale: localeCode,
                ),
                variant: AppTextVariant.bodySmall,
              ),
              if (item.lotId != null)
                AppChip.action(
                  dense: true,
                  label: '${l10n.prodHistoryOpenLot}: ${item.lotNumber ?? ''}',
                  onPressed: () =>
                      context.push(RoutePaths.lotHistory(item.lotId!)),
                ),
              if (item.workerId != null)
                AppChip.action(
                  dense: true,
                  label: item.workerName ?? l10n.prodHistoryOpenWorker,
                  onPressed: () =>
                      context.push(RoutePaths.workerDetail(item.workerId!)),
                ),
              if (item.processId != null)
                AppChip.action(
                  dense: true,
                  label: item.processName ?? l10n.prodHistoryOpenProcess,
                  onPressed: () =>
                      context.push(RoutePaths.processDetail(item.processId!)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
