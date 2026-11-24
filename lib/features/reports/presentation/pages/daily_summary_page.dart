import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/reports/domain/entities/dashboard_report_entities.dart';
import 'package:business_manager/features/reports/presentation/bloc/daily_summary_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Fast IST Daily Production & Financial Summary page (`/daily-summary`).
/// Supports Today, Yesterday, and any Custom IST date.
final class DailySummaryPage extends StatelessWidget {
  const DailySummaryPage({super.key, this.initialDayUtcMillis});

  final int? initialDayUtcMillis;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DailySummaryCubit>(
      create: (_) {
        final cubit = getIt<DailySummaryCubit>();
        if (initialDayUtcMillis != null) {
          cubit.loadForDay(initialDayUtcMillis!);
        } else {
          cubit.loadToday();
        }
        return cubit;
      },
      child: const _DailySummaryView(),
    );
  }
}

final class _DailySummaryView extends StatelessWidget {
  const _DailySummaryView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    final todayIso = IstDateTimeHelper.toIstBusinessDate(
      IstDateTimeHelper.nowUtcMillis(),
    );
    final nowIst = IstDateTimeHelper.fromUtcMillisToIst(
      IstDateTimeHelper.nowUtcMillis(),
    );
    final yesterdayDate = DateTime.utc(
      nowIst.year,
      nowIst.month,
      nowIst.day,
    ).subtract(const Duration(days: 1));
    final yesterdayIso =
        '${yesterdayDate.year.toString().padLeft(4, '0')}-'
        '${yesterdayDate.month.toString().padLeft(2, '0')}-'
        '${yesterdayDate.day.toString().padLeft(2, '0')}';

    return AppScaffold(
      title: l10n.dailySummaryHeading,
      actions: [
        AppIconButton(
          icon: Icons.refresh_rounded,
          tooltip: l10n.actionRetry,
          onPressed: () {
            final c = context.read<DailySummaryCubit>();
            c.loadForDay(c.state.selectedDayUtcMillis);
          },
        ),
      ],
      body: BlocBuilder<DailySummaryCubit, DailySummaryState>(
        builder: (context, state) {
          final selectedIso = IstDateTimeHelper.toIstBusinessDate(
            state.selectedDayUtcMillis,
          );
          final isToday = selectedIso == todayIso;
          final isYesterday = selectedIso == yesterdayIso;
          final summary = state.summary;

          return RefreshIndicator(
            onRefresh: () => context.read<DailySummaryCubit>().loadForDay(
              state.selectedDayUtcMillis,
            ),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // IST Date Switcher Strip
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.xs,
                              children: [
                                ChoiceChip(
                                  label: Text(l10n.reportPresetToday),
                                  selected: isToday,
                                  onSelected: (_) => context
                                      .read<DailySummaryCubit>()
                                      .loadToday(),
                                ),
                                ChoiceChip(
                                  label: Text(l10n.reportPresetYesterday),
                                  selected: isYesterday,
                                  onSelected: (_) => context
                                      .read<DailySummaryCubit>()
                                      .loadYesterday(),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            AppDatePicker(
                              label: l10n.dailySummaryPickDateLabel,
                              selectedUtcMillis: state.selectedDayUtcMillis,
                              onDateSelectedUtcMillis: (utc) => context
                                  .read<DailySummaryCubit>()
                                  .loadForDay(utc),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),

                      if (state.status == DailySummaryStatus.initial ||
                          state.status == DailySummaryStatus.loading)
                        const AppSkeletonList(itemCount: 4)
                      else if (state.status == DailySummaryStatus.error ||
                          summary == null)
                        AppErrorView(
                          title: l10n.errorUnexpected,
                          message: state.errorMessage,
                          retryLabel: l10n.actionRetry,
                          onRetry: () => context
                              .read<DailySummaryCubit>()
                              .loadForDay(state.selectedDayUtcMillis),
                        )
                      else ...[
                        AppHeading(
                          IstDateTimeHelper.formatIstDate(
                            state.selectedDayUtcMillis,
                            locale: localeCode,
                          ),
                          level: AppHeadingLevel.h3,
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Production & Financial KPIs
                        _buildKpiGrid(context, summary),
                        const SizedBox(height: AppSpacing.md),

                        if (!summary.hasAnyActivity)
                          AppEmptyState(
                            icon: Icons.event_available_outlined,
                            title: l10n.dailySummaryNoActivityTitle,
                            subtitle: l10n.dailySummaryNoActivitySubtitle,
                            actionLabel: l10n.stockIssueAction,
                            onAction: () =>
                                context.push(RoutePaths.stockIssue()),
                          )
                        else ...[
                          // Process-wise Activity
                          if (summary.processActivities.isNotEmpty) ...[
                            AppHeading(
                              l10n.dailySummaryProcessActivityHeading,
                              level: AppHeadingLevel.h3,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            AppCard(
                              child: Column(
                                children: [
                                  for (
                                    var i = 0;
                                    i < summary.processActivities.length;
                                    i++
                                  ) ...[
                                    _ProcessActivityRow(
                                      item: summary.processActivities[i],
                                    ),
                                    if (i <
                                        summary.processActivities.length - 1)
                                      const Divider(),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          if (summary.workerActivities.isNotEmpty) ...[
                            AppHeading(
                              l10n.dailySummaryWorkerActivityHeading,
                              level: AppHeadingLevel.h3,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                          ],
                        ],
                      ],
                    ],
                  ),
                ),
                if (state.status == DailySummaryStatus.loaded &&
                    summary != null &&
                    summary.hasAnyActivity &&
                    summary.workerActivities.isNotEmpty)
                  SliverList.separated(
                    itemCount: summary.workerActivities.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (ctx, i) {
                      final w = summary.workerActivities[i];
                      return AppCard.listItem(
                        key: ValueKey<String>(w.workerId),
                        onTap: () =>
                            ctx.push(RoutePaths.workerLedger(w.workerId)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: AppText(
                                    w.workerName,
                                    variant: AppTextVariant.bodyLarge,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (w.labourEarnedPaise > 0)
                                  AppStatusBadge(
                                    label: MoneyFormatter.formatPaise(
                                      w.labourEarnedPaise,
                                    ),
                                    tone: AppStatusTone.good,
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: AppSpacing.md,
                              runSpacing: AppSpacing.xs,
                              children: [
                                if (w.issuedQty > 0)
                                  AppText(
                                    '${l10n.stockIssuedLabel}: ${w.issuedQty} ${l10n.piecesUnit}',
                                    variant: AppTextVariant.bodySmall,
                                  ),
                                if (w.goodReturnedQty > 0)
                                  AppText(
                                    '${l10n.stockGoodReturnedLabel}: ${w.goodReturnedQty} ${l10n.piecesUnit}',
                                    variant: AppTextVariant.bodySmall,
                                  ),
                                if (w.damagedQty > 0 || w.lostShortageQty > 0)
                                  AppText(
                                    '${l10n.dailySummaryDamagedLostLabel}: ${w.damagedQty + w.lostShortageQty}',
                                    variant: AppTextVariant.bodySmall,
                                    color: Theme.of(ctx).colorScheme.error,
                                  ),
                                if (w.paymentsPaidPaise != 0)
                                  AppText(
                                    '${l10n.accountingTabPayments}: ${MoneyFormatter.formatPaise(w.paymentsPaidPaise)}',
                                    variant: AppTextVariant.bodySmall,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                if (state.status == DailySummaryStatus.loaded &&
                    summary != null)
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: AppSpacing.md),

                        // Current Live Pending Snapshot + Quick Actions
                        AppCard(
                          color: Theme.of(context).colorScheme.surfaceContainer,
                          elevated: false,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                l10n.dailySummaryLivePendingNote,
                                variant: AppTextVariant.label,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: [
                                  AppStatusBadge(
                                    label:
                                        '${l10n.stockPendingWorkerLabel}: ${summary.currentTotalPendingQty} ${l10n.piecesUnit}',
                                    tone: summary.currentTotalPendingQty > 0
                                        ? AppStatusTone.pending
                                        : AppStatusTone.good,
                                  ),
                                  AppStatusBadge(
                                    label:
                                        '${l10n.accountingOutstandingPayableLabel}: ${MoneyFormatter.formatPaise(summary.currentTotalOutstandingPayablePaise)}',
                                    tone:
                                        summary.currentTotalOutstandingPayablePaise >
                                            0
                                        ? AppStatusTone.pending
                                        : AppStatusTone.good,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  AppButton(
                                    label: l10n.stockIssueAction,
                                    icon: Icons.outbox_rounded,
                                    onPressed: () =>
                                        context.push(RoutePaths.stockIssue()),
                                  ),
                                  AppButton(
                                    label: l10n.stockReturnAction,
                                    icon: Icons.assignment_returned_outlined,
                                    variant: AppButtonVariant.secondary,
                                    onPressed: () => context.push(
                                      RoutePaths.stockReturnPicker,
                                    ),
                                  ),
                                  AppButton(
                                    label: l10n.navReports,
                                    icon: Icons.analytics_outlined,
                                    variant: AppButtonVariant.outlined,
                                    onPressed: () =>
                                        context.push(RoutePaths.reports),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildKpiGrid(BuildContext context, DailyWorkshopSummary summary) {
    final l10n = context.l10n;
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
                label: l10n.stockIssuedLabel,
                value: summary.issuedQty,
                suffix: l10n.piecesUnit,
                icon: Icons.outbox_rounded,
                tone: AppStatusTone.info,
              ),
            ),
            SizedBox(
              width: tileW,
              child: AppMetricTile(
                label: l10n.stockGoodReturnedLabel,
                value: summary.goodReturnedQty,
                suffix: l10n.piecesUnit,
                icon: Icons.check_circle_outline_rounded,
                tone: AppStatusTone.good,
              ),
            ),
            SizedBox(
              width: tileW,
              child: AppMetricTile(
                label: l10n.dailySummaryDamagedLostLabel,
                value: summary.damagedQty + summary.lostAndShortageQty,
                suffix: l10n.piecesUnit,
                icon: Icons.report_problem_outlined,
                tone: (summary.damagedQty + summary.lostAndShortageQty) > 0
                    ? AppStatusTone.damaged
                    : AppStatusTone.neutral,
              ),
            ),
            SizedBox(
              width: tileW,
              child: AppMetricTile(
                label: l10n.accountingEarnedLabourLabel,
                value: summary.labourEarnedPaise,
                isCurrencyPaise: true,
                icon: Icons.work_outline_rounded,
                tone: AppStatusTone.good,
              ),
            ),
            SizedBox(
              width: tileW,
              child: AppMetricTile(
                label: l10n.accountingTabPayments,
                value: summary.netPaymentsPaise,
                isCurrencyPaise: true,
                icon: Icons.payments_outlined,
                tone: AppStatusTone.neutral,
              ),
            ),
            SizedBox(
              width: tileW,
              child: AppMetricTile(
                label: l10n.stockPendingWorkerLabel,
                value: summary.currentTotalPendingQty,
                suffix: l10n.piecesUnit,
                icon: Icons.pending_actions_rounded,
                tone: summary.currentTotalPendingQty > 0
                    ? AppStatusTone.pending
                    : AppStatusTone.good,
              ),
            ),
          ],
        );
      },
    );
  }
}

final class _ProcessActivityRow extends StatelessWidget {
  const _ProcessActivityRow({required this.item});

  final DailyProcessActivity item;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(item.processName, fontWeight: FontWeight.w600),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (item.issuedQty > 0)
                AppStatusBadge(
                  label: '${l10n.stockIssuedLabel}: ${item.issuedQty}',
                  tone: AppStatusTone.info,
                ),
              if (item.goodReturnedQty > 0)
                AppStatusBadge(
                  label:
                      '${l10n.stockGoodReturnedLabel}: ${item.goodReturnedQty}',
                  tone: AppStatusTone.good,
                ),
              if (item.damagedQty > 0)
                AppStatusBadge(
                  label: '${l10n.stockDamagedBucketLabel}: ${item.damagedQty}',
                  tone: AppStatusTone.damaged,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
