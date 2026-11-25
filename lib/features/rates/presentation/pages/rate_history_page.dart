import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/rates/presentation/bloc/rate_history_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Displays current per-piece rate and full effective-dated rate history for a
/// worker + process combination.
final class RateHistoryPage extends StatelessWidget {
  const RateHistoryPage({super.key, required this.workerId, this.processId});

  final String workerId;
  final String? processId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RateHistoryCubit>(
      create: (_) =>
          getIt<RateHistoryCubit>()
            ..load(workerId: workerId, processId: processId),
      child: _RateHistoryView(workerId: workerId),
    );
  }
}

final class _RateHistoryView extends StatelessWidget {
  const _RateHistoryView({required this.workerId});

  final String workerId;

  Future<void> _openAddRate(BuildContext context, String? processId) async {
    await context.push(
      RoutePaths.workerRateCreate(workerId, processId: processId),
    );
    if (context.mounted) {
      await context.read<RateHistoryCubit>().load(
        workerId: workerId,
        processId: processId,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<RateHistoryCubit, RateHistoryState>(
      builder: (context, state) {
        if (state.status == RateHistoryStatus.loading ||
            state.status == RateHistoryStatus.initial) {
          return AppScaffold(
            title: l10n.ratesHistoryHeading,
            body: const AppLoader(),
          );
        }
        if (state.status == RateHistoryStatus.error || state.worker == null) {
          return AppScaffold(
            title: l10n.ratesHistoryHeading,
            body: AppErrorView(
              title: l10n.errorUnexpected,
              message: state.errorMessage,
              retryLabel: l10n.actionRetry,
              onRetry: () => context.read<RateHistoryCubit>().load(
                workerId: workerId,
                processId: state.selectedProcessId,
              ),
            ),
          );
        }

        final worker = state.worker!;
        final selectedProcess = state.processes
            .where((p) => p.id == state.selectedProcessId)
            .firstOrNull;

        return AppScaffold(
          title: '${worker.name} — ${l10n.ratesHistoryHeading}',
          actions: [
            AppIconButton(
              icon: Icons.add,
              tooltip: l10n.workerAddRateAction,
              onPressed: () => _openAddRate(context, state.selectedProcessId),
            ),
          ],
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (state.processes.isNotEmpty)
                            AppDropdown<ProcessEntity>(
                              key: ValueKey('rate_proc_${state.selectedProcessId}'),
                              label: l10n.ratesFilterProcessLabel,
                              value: selectedProcess,
                              items: state.processes,
                              itemLabelBuilder: (p) => p.name,
                              onChanged: (p) {
                                if (p != null) {
                                  context.read<RateHistoryCubit>().load(
                                    workerId: workerId,
                                    processId: p.id,
                                  );
                                }
                              },
                            ),
                          const SizedBox(height: AppSpacing.md),
                          AppActionRow(content: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText(
                                      l10n.ratesCurrentRateLabel,
                                      variant: AppTextVariant.label,
                                    ),
                                    const SizedBox(height: AppSpacing.xs),
                                    AppHeading(
                                      state.currentRate != null
                                          ? '${MoneyFormatter.formatPaise(state.currentRate!.ratePaise)} ${l10n.ratesPerPieceSuffix}'
                                          : l10n.ratesNoCurrentRate,
                                      level: AppHeadingLevel.h2,
                                    ),
                                  ],
                                ), actions: [AppButton(
                                label: l10n.workerAddRateAction,
                                icon: Icons.add,
                                onPressed: () =>
                                    _openAddRate(context, state.selectedProcessId),
                              ),],),
                          const SizedBox(height: AppSpacing.sm),
                          AppText(
                            l10n.ratesHistoricalNotice,
                            variant: AppTextVariant.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
              if (state.rates.isEmpty)
                SliverToBoxAdapter(
                  child: AppEmptyState(
                    icon: Icons.currency_rupee,
                    title: l10n.ratesEmptyTitle,
                    subtitle: l10n.ratesEmptySubtitle,
                    actionLabel: l10n.workerAddRateAction,
                    onAction: () =>
                        _openAddRate(context, state.selectedProcessId),
                  ),
                )
              else
                SliverList.separated(
                  itemCount: state.rates.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (ctx, i) {
                    final rate = state.rates[i];
                    final isCurrent = state.currentRate?.id == rate.id;
                    return AppCard.listItem(
                      key: ValueKey<String>(rate.id),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.xs,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    AppText(
                                      '${MoneyFormatter.formatPaise(rate.ratePaise)} ${l10n.ratesPerPieceSuffix}',
                                      variant: AppTextVariant.numeric,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    if (isCurrent)
                                      AppStatusBadge(
                                        label: l10n.ratesCurrentRateLabel,
                                        tone: AppStatusTone.good,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                AppText(
                                  AppDateTimeFormatter.formatIsoDateRange(
                                    fromIso: rate.effectiveFrom,
                                    toIso: rate.effectiveTo,
                                    ongoingLabel: l10n.ratesOngoingLabel,
                                    locale: Localizations.localeOf(
                                      ctx,
                                    ).languageCode,
                                  ),
                                  variant: AppTextVariant.bodySmall,
                                ),
                                if (rate.notes != null) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  AppText(
                                    rate.notes!,
                                    variant: AppTextVariant.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          AppIconButton(
                            icon: Icons.edit_outlined,
                            tooltip: l10n.ratesEditHeading,
                            onPressed: () async {
                              await ctx.push(
                                RoutePaths.workerRateEdit(workerId, rate.id),
                              );
                              if (ctx.mounted) {
                                await ctx.read<RateHistoryCubit>().load(
                                  workerId: workerId,
                                  processId: state.selectedProcessId,
                                );
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
