import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/production_history/presentation/bloc/production_history_dashboard_cubit.dart';
import 'package:business_manager/features/production_history/presentation/bloc/worker_production_history_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Screen 6: Worker-Wise Production History Directory.
///
/// Shows every worker (including deactivated workers with historical records)
/// with reconciled lots, pieces, accepted, pending inspection, rejected,
/// earned, paid, and outstanding balance — with direct drill-down into Worker
/// Account Details and Worker Financial Ledger.
final class WorkerProductionHistoryPage extends StatelessWidget {
  const WorkerProductionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkerProductionHistoryCubit>(
      create: (_) => getIt<WorkerProductionHistoryCubit>()..loadAll(),
      child: const _WorkerProductionHistoryView(),
    );
  }
}

final class _WorkerProductionHistoryView extends StatelessWidget {
  const _WorkerProductionHistoryView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<
      WorkerProductionHistoryCubit,
      WorkerProductionHistoryState
    >(
      builder: (context, state) {
        final cubit = context.read<WorkerProductionHistoryCubit>();
        return AppScaffold(
          title: l10n.prodHistoryWorkerHistoryTitle,
          contentWidth: AppContentWidth.wide,
          actions: [
            AppIconButton(
              icon: Icons.refresh_rounded,
              tooltip: l10n.actionRetry,
              onPressed: () => cubit.loadAll(),
            ),
          ],
          body: switch (state.status) {
            ProductionHistoryLoadStatus.initial ||
            ProductionHistoryLoadStatus.loading when state.profiles.isEmpty =>
              const AppSkeletonList(itemCount: 4),
            ProductionHistoryLoadStatus.error when state.profiles.isEmpty =>
              AppErrorView(
                title: l10n.errorUnexpected,
                message: state.errorMessage,
                retryLabel: l10n.actionRetry,
                onRetry: () => cubit.loadAll(),
              ),
            _ => _buildList(context, state),
          },
        );
      },
    );
  }

  Widget _buildList(
    BuildContext context,
    WorkerProductionHistoryState state,
  ) {
    final l10n = context.l10n;
    final cubit = context.read<WorkerProductionHistoryCubit>();
    final filter = state.filter;

    return ListView(
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSearchField(
                label: l10n.prodHistorySearchHint,
                onChanged: (q) => cubit.loadAll(
                  filter: filter.copyWith(searchQuery: q),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 220,
                    child: AppDropdown<String>(
                      label: l10n.navProcesses,
                      value: filter.processId ?? '__ALL__',
                      items: [
                        '__ALL__',
                        ...state.options.processes.map((p) => p.id),
                      ],
                      itemLabelBuilder: (id) => id == '__ALL__'
                          ? l10n.prodHistoryAllEntries
                          : state.options.processes
                              .firstWhere((p) => p.id == id)
                              .label,
                      onChanged: (v) => cubit.loadAll(
                        filter: v == null || v == '__ALL__'
                            ? filter.copyWith(clearProcess: true)
                            : filter.copyWith(processId: v),
                      ),
                    ),
                  ),
                  FilterChip(
                    label: Text(l10n.prodHistoryIncludeInactive),
                    selected: state.includeInactive,
                    onSelected: (v) => cubit.loadAll(includeInactive: v),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.profiles.isEmpty)
          AppEmptyState(
            icon: Icons.people_outline_rounded,
            title: l10n.prodHistoryWorkerHistoryTitle,
          )
        else
          AppDataTable<WorkerCompleteProfile>(
            enablePagination: true,
            columns: [
              AppDataColumn(label: l10n.workerNameLabel),
              const AppDataColumn(label: 'Lots', numeric: true),
              AppDataColumn(label: l10n.prodHistoryTotalAssigned, numeric: true),
              AppDataColumn(label: l10n.prodHistoryTotalAccepted, numeric: true),
              const AppDataColumn(
                label: 'Pending QC',
                numeric: true,
                minWidthClass: AppWindowSizeClass.expanded,
              ),
              const AppDataColumn(
                label: 'Rejected',
                numeric: true,
                minWidthClass: AppWindowSizeClass.expanded,
              ),
              AppDataColumn(label: l10n.prodHistoryTotalEarned, numeric: true),
              AppDataColumn(
                label: l10n.prodHistoryOutstandingPayable,
                numeric: true,
              ),
            ],
            items: state.profiles,
            itemKeyBuilder: (p) => ValueKey<String>(p.workerId),
            onRowTap: (p) =>
                context.push(RoutePaths.workerDetail(p.workerId)),
            cellsBuilder: (p) => [
              AppText(p.workerName, fontWeight: FontWeight.w700),
              AppText('${p.totalLotsAssigned}'),
              AppText('${p.assignedQty}'),
              AppText('${p.acceptedQty}'),
              AppText('${p.pendingInspectionQty}'),
              AppText('${p.rejectedQty}'),
              AppText(
                MoneyFormatter.formatPaise(p.financialSummary.earnedLabourPaise),
              ),
              AppText(
                MoneyFormatter.formatPaise(
                  p.financialSummary.outstandingPayablePaise,
                ),
                fontWeight: FontWeight.w700,
              ),
            ],
            mobileCardBuilder: (_, p) => _WorkerSummaryCard(profile: p),
          ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

final class _WorkerSummaryCard extends StatelessWidget {
  const _WorkerSummaryCard({required this.profile});

  final WorkerCompleteProfile profile;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fin = profile.financialSummary;

    return AppCard.listItem(
      onTap: () => context.push(RoutePaths.workerDetail(profile.workerId)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      profile.workerName,
                      variant: AppTextVariant.bodyLarge,
                      fontWeight: FontWeight.w700,
                    ),
                    if (profile.phone != null)
                      AppText(profile.phone!, variant: AppTextVariant.bodySmall),
                  ],
                ),
              ),
              AppStatusBadge(
                label: profile.isActive
                    ? l10n.statusActive
                    : l10n.statusInactive,
                tone: profile.isActive
                    ? AppStatusTone.good
                    : AppStatusTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: 4,
            children: [
              AppStatusBadge(
                label: 'Lots: ${profile.totalLotsAssigned}',
                tone: AppStatusTone.info,
              ),
              AppStatusBadge(
                label: '${l10n.prodHistoryTotalAssigned}: ${profile.assignedQty}',
                tone: AppStatusTone.neutral,
              ),
              AppStatusBadge(
                label: '${l10n.prodHistoryTotalAccepted}: ${profile.acceptedQty}',
                tone: AppStatusTone.good,
              ),
              if (profile.pendingInspectionQty > 0)
                AppStatusBadge(
                  label: 'Pending QC: ${profile.pendingInspectionQty}',
                  tone: AppStatusTone.pending,
                ),
              if (profile.outstandingQty > 0)
                AppStatusBadge(
                  label: 'Outstanding: ${profile.outstandingQty}',
                  tone: AppStatusTone.pending,
                ),
              if (profile.rejectedQty > 0)
                AppStatusBadge(
                  label: 'Rejected: ${profile.rejectedQty}',
                  tone: AppStatusTone.damaged,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: AppText(
                  'Earned: ${MoneyFormatter.formatPaise(fin.earnedLabourPaise)} • Paid: ${MoneyFormatter.formatPaise(fin.netPaidToWorkerPaise)} • Due: ${MoneyFormatter.formatPaise(fin.outstandingPayablePaise)}',
                  variant: AppTextVariant.numeric,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AppButton(
                label: l10n.accountingOpenLedgerAction,
                variant: AppButtonVariant.text,
                onPressed: () =>
                    context.push(RoutePaths.workerLedger(profile.workerId)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
