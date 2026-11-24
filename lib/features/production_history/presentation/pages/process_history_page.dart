import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/production_history/presentation/bloc/process_history_cubit.dart';
import 'package:business_manager/features/production_history/presentation/bloc/production_history_dashboard_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Screen 7: Process-Wise Production History.
///
/// Displays every process (preserving inactive processes with history),
/// totals (lots, assigned, returned, accepted, pending inspection, outstanding,
/// rejected, completed, workers involved, production cost, paid, outstanding),
/// plus Lot-wise, Worker-wise, Date-wise, and Pending filters.
final class ProcessHistoryPage extends StatelessWidget {
  const ProcessHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProcessHistoryCubit>(
      create: (_) => getIt<ProcessHistoryCubit>()..loadAll(),
      child: const _ProcessHistoryView(),
    );
  }
}

final class _ProcessHistoryView extends StatelessWidget {
  const _ProcessHistoryView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ProcessHistoryCubit, ProcessHistoryState>(
      builder: (context, state) {
        final cubit = context.read<ProcessHistoryCubit>();
        return AppScaffold(
          title: l10n.prodHistoryProcessHistoryTitle,
          actions: [
            AppIconButton(
              icon: Icons.refresh_rounded,
              tooltip: l10n.actionRetry,
              onPressed: () => cubit.loadAll(),
            ),
          ],
          body: switch (state.status) {
            ProductionHistoryLoadStatus.initial ||
            ProductionHistoryLoadStatus.loading when state.processes.isEmpty =>
              const AppSkeletonList(itemCount: 4),
            ProductionHistoryLoadStatus.error when state.processes.isEmpty =>
              AppErrorView(
                title: l10n.errorUnexpected,
                message: state.errorMessage,
                retryLabel: l10n.actionRetry,
                onRetry: () => cubit.loadAll(),
              ),
            _ => _buildContent(context, state),
          },
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ProcessHistoryState state) {
    final l10n = context.l10n;
    final cubit = context.read<ProcessHistoryCubit>();
    final filter = state.filter;
    final options = state.options;

    return ListView(
      children: [
        // Filters: Date range, Worker, Lot, Design, Colour
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  SizedBox(
                    width: 200,
                    child: AppDropdown<String>(
                      label: l10n.navWorkers,
                      value: filter.workerId ?? '__ALL__',
                      items: ['__ALL__', ...options.workers.map((w) => w.id)],
                      itemLabelBuilder: (id) => id == '__ALL__'
                          ? l10n.prodHistoryAllEntries
                          : options.workers
                              .firstWhere((w) => w.id == id)
                              .label,
                      onChanged: (v) => cubit.loadAll(
                        filter: v == null || v == '__ALL__'
                            ? filter.copyWith(clearWorker: true)
                            : filter.copyWith(workerId: v),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 200,
                    child: AppDropdown<String>(
                      label: l10n.lotsHeading,
                      value: filter.lotId ?? '__ALL__',
                      items: ['__ALL__', ...options.lots.map((l) => l.id)],
                      itemLabelBuilder: (id) => id == '__ALL__'
                          ? l10n.prodHistoryAllEntries
                          : options.lots.firstWhere((l) => l.id == id).label,
                      onChanged: (v) => cubit.loadAll(
                        filter: v == null || v == '__ALL__'
                            ? filter.copyWith(clearLot: true)
                            : filter.copyWith(lotId: v),
                      ),
                    ),
                  ),
                  if (options.designNames.isNotEmpty)
                    SizedBox(
                      width: 200,
                      child: AppDropdown<String>(
                        label: l10n.designsHeading,
                        value: filter.designName ?? '__ALL__',
                        items: ['__ALL__', ...options.designNames],
                        itemLabelBuilder: (d) =>
                            d == '__ALL__' ? l10n.prodHistoryAllEntries : d,
                        onChanged: (v) => cubit.loadAll(
                          filter: v == null || v == '__ALL__'
                              ? filter.copyWith(clearDesign: true)
                              : filter.copyWith(designName: v),
                        ),
                      ),
                    ),
                  if (options.colourNames.isNotEmpty)
                    SizedBox(
                      width: 200,
                      child: AppDropdown<String>(
                        label: l10n.colourNameLabel,
                        value: filter.colourName ?? '__ALL__',
                        items: ['__ALL__', ...options.colourNames],
                        itemLabelBuilder: (c) =>
                            c == '__ALL__' ? l10n.prodHistoryAllEntries : c,
                        onChanged: (v) => cubit.loadAll(
                          filter: v == null || v == '__ALL__'
                              ? filter.copyWith(clearColour: true)
                              : filter.copyWith(colourName: v),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppDatePicker(
                      label: l10n.accountingFromDateLabel,
                      selectedUtcMillis: filter.fromUtcMillis,
                      onDateSelectedUtcMillis: (utc) {
                        final ist = IstDateTimeHelper.fromUtcMillisToIst(utc);
                        cubit.loadAll(
                          filter: filter.copyWith(
                            fromUtcMillis:
                                IstDateTimeHelper.istDateTimeToUtcMillis(
                                  year: ist.year,
                                  month: ist.month,
                                  day: ist.day,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppDatePicker(
                      label: l10n.accountingToDateLabel,
                      selectedUtcMillis: filter.toUtcMillis,
                      onDateSelectedUtcMillis: (utc) {
                        final ist = IstDateTimeHelper.fromUtcMillisToIst(utc);
                        cubit.loadAll(
                          filter: filter.copyWith(
                            toUtcMillis:
                                IstDateTimeHelper.istDateTimeToUtcMillis(
                                  year: ist.year,
                                  month: ist.month,
                                  day: ist.day,
                                  hour: 23,
                                  minute: 59,
                                  second: 59,
                                ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerRight,
                child: AppButton(
                  label: l10n.accountingClearFilters,
                  variant: AppButtonVariant.text,
                  onPressed: () =>
                      cubit.loadAll(filter: const ProductionHistoryFilter()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        if (state.processes.isEmpty)
          AppEmptyState(
            icon: Icons.precision_manufacturing_outlined,
            title: l10n.prodHistoryProcessHistoryTitle,
          )
        else
          for (final proc in state.processes) ...[
            _ProcessHistoryCard(proc: proc),
            const SizedBox(height: AppSpacing.sm),
          ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

final class _ProcessHistoryCard extends StatelessWidget {
  const _ProcessHistoryCard({required this.proc});

  final ProcessCompleteHistory proc;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard.listItem(
      onTap: () => context.push(RoutePaths.processDetail(proc.processId)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  proc.processName,
                  variant: AppTextVariant.bodyLarge,
                  fontWeight: FontWeight.w700,
                ),
              ),
              AppStatusBadge(
                label: proc.isActive ? l10n.statusActive : l10n.statusInactive,
                tone: proc.isActive
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
                label: 'Lots: ${proc.totalLots}',
                tone: AppStatusTone.info,
              ),
              AppStatusBadge(
                label: 'Workers: ${proc.totalWorkersInvolved}',
                tone: AppStatusTone.neutral,
              ),
              AppStatusBadge(
                label: 'Assigned: ${proc.assignedQty}',
                tone: AppStatusTone.info,
              ),
              AppStatusBadge(
                label: 'Accepted: ${proc.acceptedQty}',
                tone: AppStatusTone.good,
              ),
              if (proc.pendingInspectionQty > 0)
                AppStatusBadge(
                  label: 'Pending QC: ${proc.pendingInspectionQty}',
                  tone: AppStatusTone.pending,
                ),
              if (proc.outstandingQty > 0)
                AppStatusBadge(
                  label: 'Outstanding: ${proc.outstandingQty}',
                  tone: AppStatusTone.pending,
                ),
              if (proc.rejectedQty > 0)
                AppStatusBadge(
                  label: 'Rejected: ${proc.rejectedQty}',
                  tone: AppStatusTone.damaged,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AppText(
            'Cost: ${MoneyFormatter.formatPaise(proc.totalProductionCostPaise)} • Paid (est): ${MoneyFormatter.formatPaise(proc.estimatedPaidPaise)} • Outstanding (est): ${MoneyFormatter.formatPaise(proc.estimatedOutstandingPaise)}',
            variant: AppTextVariant.numeric,
            fontWeight: FontWeight.w600,
          ),
        ],
      ),
    );
  }
}
