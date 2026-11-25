import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/production_history/presentation/bloc/lot_history_cubit.dart';
import 'package:business_manager/features/production_history/presentation/bloc/production_history_dashboard_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Screen 2: Complete Permanent Lot Production History.
final class LotHistoryPage extends StatelessWidget {
  const LotHistoryPage({super.key, required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LotHistoryCubit>(
      create: (_) => getIt<LotHistoryCubit>()..loadLot(lotId),
      child: _LotHistoryView(lotId: lotId),
    );
  }
}

final class _LotHistoryView extends StatelessWidget {
  const _LotHistoryView({required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    return BlocBuilder<LotHistoryCubit, LotHistoryState>(
      builder: (context, state) {
        final history = state.history;
        return AppScaffold(
          contentWidth: AppContentWidth.wide,
          title: history != null
              ? '${history.lot.lotNumber} — ${l10n.prodHistoryLotHistoryTitle}'
              : l10n.prodHistoryLotHistoryTitle,
          actions: [
            AppIconButton(
              icon: Icons.timeline_rounded,
              tooltip: l10n.prodHistoryViewTimeline,
              onPressed: () => context.push(RoutePaths.lotTimeline(lotId)),
            ),
            AppIconButton(
              icon: Icons.refresh_rounded,
              tooltip: l10n.actionRetry,
              onPressed: () => context.read<LotHistoryCubit>().loadLot(lotId),
            ),
          ],
          body: switch (state.status) {
            ProductionHistoryLoadStatus.initial ||
            ProductionHistoryLoadStatus.loading => const AppSkeletonList(
              itemCount: 4,
            ),
            ProductionHistoryLoadStatus.error ||
            _ when history == null => AppErrorView(
              title: l10n.errorUnexpected,
              message: state.errorMessage,
              retryLabel: l10n.actionRetry,
              onRetry: () => context.read<LotHistoryCubit>().loadLot(lotId),
            ),
            _ => _buildLoaded(context, history, localeCode),
          },
        );
      },
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    LotCompleteHistory history,
    String localeCode,
  ) {
    final l10n = context.l10n;
    final lot = history.lot;

    return ListView(
      children: [
        // Lot Metadata Header Card
        AppCard(
          isGlass: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppHeading(lot.lotNumber, level: AppHeadingLevel.h2),
                  ),
                  AppStatusBadge(
                    label: lot.status.dbValue,
                    tone: history.isFullyReconciled
                        ? AppStatusTone.good
                        : AppStatusTone.pending,
                  ),
                ],
              ),
              if (lot.title != null && lot.title!.isNotEmpty) ...[
                const SizedBox(height: 2),
                AppText(lot.title!),
              ],
              const SizedBox(height: AppSpacing.xs),
              AppText(
                '${l10n.createdAtLabel}: ${AppDateTimeFormatter.formatDateTime(lot.createdAt, locale: localeCode)}'
                '${history.createdBy != null ? ' • By ${history.createdBy}' : ''}',
                variant: AppTextVariant.bodySmall,
              ),
              if (history.updatedBy != null)
                AppText(
                  '${l10n.updatedAtLabel}: ${AppDateTimeFormatter.formatDateTime(lot.updatedAt, locale: localeCode)} • By ${history.updatedBy}',
                  variant: AppTextVariant.bodySmall,
                ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton(
                    label: l10n.prodHistoryViewTimeline,
                    icon: Icons.timeline_rounded,
                    onPressed: () =>
                        context.push(RoutePaths.lotTimeline(lot.id)),
                  ),
                  AppButton(
                    label: 'Multi-Process Routing',
                    icon: Icons.account_tree_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () =>
                        context.push(RoutePaths.lotRouting(lot.id)),
                  ),
                  AppButton(
                    label: l10n.stockReturnAction,
                    icon: Icons.assignment_return_outlined,
                    variant: AppButtonVariant.outlined,
                    onPressed: () => context.push(
                      RoutePaths.stockReturnPickerFiltered(lotId: lot.id),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Reconciled KPI Summary
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth >= 720 ? 4 : 2;
            final w =
                (constraints.maxWidth - (AppSpacing.sm * (cols - 1))) / cols;
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                SizedBox(
                  width: w,
                  child: AppMetricTile(
                    label: 'Initial Qty',
                    value: history.totalInitialQty,
                    suffix: l10n.piecesUnit,
                    icon: Icons.inventory_2_outlined,
                    tone: AppStatusTone.info,
                  ),
                ),
                SizedBox(
                  width: w,
                  child: AppMetricTile(
                    label: l10n.prodHistoryTotalAccepted,
                    value: history.totalAcceptedQty,
                    suffix: l10n.piecesUnit,
                    icon: Icons.verified_outlined,
                    tone: AppStatusTone.good,
                  ),
                ),
                SizedBox(
                  width: w,
                  child: AppMetricTile(
                    label: l10n.prodHistoryPendingInspection,
                    value: history.totalPendingInspectionQty,
                    suffix: l10n.piecesUnit,
                    icon: Icons.fact_check_outlined,
                    tone: history.totalPendingInspectionQty > 0
                        ? AppStatusTone.pending
                        : AppStatusTone.neutral,
                    onTap: () => context.push(RoutePaths.inspectionQueue),
                  ),
                ),
                SizedBox(
                  width: w,
                  child: AppMetricTile(
                    label: l10n.prodHistoryTotalRejected,
                    value: history.totalRejectedQty,
                    suffix: l10n.piecesUnit,
                    icon: Icons.report_problem_outlined,
                    tone: history.totalRejectedQty > 0
                        ? AppStatusTone.damaged
                        : AppStatusTone.neutral,
                  ),
                ),
                SizedBox(
                  width: w,
                  child: AppMetricTile(
                    label: l10n.prodHistoryOutstandingWork,
                    value: history.totalOutstandingQty,
                    suffix: l10n.piecesUnit,
                    icon: Icons.hourglass_bottom_rounded,
                    tone: history.totalOutstandingQty > 0
                        ? AppStatusTone.pending
                        : AppStatusTone.good,
                  ),
                ),
                SizedBox(
                  width: w,
                  child: AppMetricTile(
                    label: 'Total Production Cost',
                    value: history.totalProductionCostPaise,
                    isCurrencyPaise: true,
                    icon: Icons.currency_rupee_rounded,
                    tone: AppStatusTone.good,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.lg),

        // Design & Colour Stock Conservation Breakdown
        const AppHeading(
          'Designs & Colours Breakdown',
          level: AppHeadingLevel.h3,
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final c in history.colourSummaries) ...[
          AppCard.listItem(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppColourSwatch(
                      color: AppColourUtils.resolveColor(
                        c.colourHex,
                        fallbackName: c.colourName,
                      ),
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: AppText(
                        '${c.designName} • ${c.colourName}',
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    AppText(
                      '${c.initialQuantity} ${l10n.piecesUnit}',
                      variant: AppTextVariant.numeric,
                      fontWeight: FontWeight.w700,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: 4,
                  children: [
                    AppStatusBadge(
                      label: 'In-House: ${c.availableInHouse}',
                      tone: AppStatusTone.good,
                    ),
                    AppStatusBadge(
                      label: 'With Workers: ${c.outstandingWithWorkers}',
                      tone: c.outstandingWithWorkers > 0
                          ? AppStatusTone.pending
                          : AppStatusTone.neutral,
                    ),
                    if (c.pendingInspection > 0)
                      AppStatusBadge(
                        label: 'Pending QC: ${c.pendingInspection}',
                        tone: AppStatusTone.info,
                      ),
                    if (c.damagedBucket > 0)
                      AppStatusBadge(
                        label: 'Damaged: ${c.damagedBucket}',
                        tone: AppStatusTone.damaged,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],

        const SizedBox(height: AppSpacing.lg),
        AppHeading(
          'Process Assignments & Worker Ledger (${history.assignments.length})',
          level: AppHeadingLevel.h3,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (history.assignments.isEmpty)
          const AppCard(
            child: AppText(
              'No process assignments recorded for this lot yet.',
              variant: AppTextVariant.bodySmall,
            ),
          )
        else
          AppLazySection(
            key: const ValueKey('history.assignments'),
            initialCount: 15,
            items: history.assignments,
            itemBuilder: (context, a, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _AssignmentCard(assignment: a, localeCode: localeCode),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),

        if (history.rejections.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          AppHeading(
            'Rejection & Repair Records (${history.rejections.length})',
            level: AppHeadingLevel.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppLazySection(
            key: const ValueKey('history.rejections'),
            initialCount: 15,
            items: history.rejections,
            itemBuilder: (context, r, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard.listItem(
                  onTap: () => context.push(
                    RoutePaths.productionTransactionDetail(
                      ProductionTransactionKind.rejection.routeSegment,
                      r.record.id,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppText(
                              '${r.processName} • ${r.workerName} • ${r.colourName}',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          AppStatusBadge(
                            label: r.record.status.dbValue,
                            tone: r.openUnrepairedQty > 0
                                ? AppStatusTone.damaged
                                : AppStatusTone.good,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      AppText(
                        'Rejected: ${r.record.rejectedQuantity} • Re-Approved: ${r.totalReapprovedQty} • Open: ${r.openUnrepairedQty}',
                        variant: AppTextVariant.bodySmall,
                      ),
                      AppText(
                        'Reason: ${r.record.rejectionReason}',
                        variant: AppTextVariant.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

final class _AssignmentCard extends StatelessWidget {
  const _AssignmentCard({required this.assignment, required this.localeCode});

  final AssignmentReconciliationSummary assignment;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final a = assignment;
    return AppCard.listItem(
      onTap: () => context.push(
        RoutePaths.productionTransactionDetail(
          ProductionTransactionKind.stockMovement.routeSegment,
          a.issueMovementId,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  '${a.processName} • ${a.workerName}',
                  fontWeight: FontWeight.w700,
                ),
              ),
              AppStatusBadge(
                label: a.isCompleted ? 'COMPLETED' : 'IN PROGRESS',
                tone: a.isCompleted
                    ? AppStatusTone.good
                    : AppStatusTone.pending,
              ),
            ],
          ),
          const SizedBox(height: 2),
          AppText(
            '${a.designName} • ${a.colourName} • ${AppDateTimeFormatter.formatDateTime(a.assignedAt, locale: localeCode)}',
            variant: AppTextVariant.bodySmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: 4,
            children: [
              AppStatusBadge(
                label: 'Assigned: ${a.assignedQty}',
                tone: AppStatusTone.info,
              ),
              AppStatusBadge(
                label: 'Returned: ${a.returnedQty}',
                tone: AppStatusTone.neutral,
              ),
              AppStatusBadge(
                label: 'Accepted: ${a.totalAcceptedQty}',
                tone: AppStatusTone.good,
              ),
              if (a.pendingInspectionQty > 0)
                AppStatusBadge(
                  label: 'Pending QC: ${a.pendingInspectionQty}',
                  tone: AppStatusTone.pending,
                ),
              if (a.outstandingQty > 0)
                AppStatusBadge(
                  label: 'Outstanding: ${a.outstandingQty}',
                  tone: AppStatusTone.pending,
                ),
              if (a.netRejectedQty > 0)
                AppStatusBadge(
                  label: 'Rejected: ${a.netRejectedQty}',
                  tone: AppStatusTone.damaged,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: AppText(
                  'Rate: ${MoneyFormatter.formatPaise(a.lockedRatePaise)}/pc • Earned: ${MoneyFormatter.formatPaise(a.earnedAmountPaise)}',
                  variant: AppTextVariant.numeric,
                  fontWeight: FontWeight.w700,
                ),
              ),
              AppButton(
                label: l10n.prodHistoryOpenWorker,
                variant: AppButtonVariant.text,
                onPressed: () =>
                    context.push(RoutePaths.workerDetail(a.workerId)),
              ),
              AppButton(
                label: l10n.prodHistoryOpenProcess,
                variant: AppButtonVariant.text,
                onPressed: () =>
                    context.push(RoutePaths.processDetail(a.processId)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
