import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/domain_label_localizer.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/processes/presentation/bloc/process_detail_cubit.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/production_history/presentation/bloc/process_history_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

final class ProcessDetailPage extends StatelessWidget {
  const ProcessDetailPage({super.key, required this.processId});

  final String processId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProcessDetailCubit>(
          create: (_) => getIt<ProcessDetailCubit>()..loadProcess(processId),
        ),
        BlocProvider<ProcessHistoryCubit>(
          create: (_) => getIt<ProcessHistoryCubit>()..loadProcess(processId),
        ),
      ],
      child: _ProcessDetailView(processId: processId),
    );
  }
}

final class _ProcessDetailView extends StatefulWidget {
  const _ProcessDetailView({required this.processId});

  final String processId;

  @override
  State<_ProcessDetailView> createState() => _ProcessDetailViewState();
}

final class _ProcessDetailViewState extends State<_ProcessDetailView> {
  int _historyTab = 0;

  String get processId => widget.processId;

  Future<void> _confirmToggleActive(
    BuildContext context,
    ProcessEntity process,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<ProcessDetailCubit>();
    if (process.isActive) {
      final confirmed = await AppDialog.showConfirmation(
        context,
        title: l10n.processDeactivateConfirmTitle,
        message: l10n.processDeactivateConfirmMessage,
        confirmLabel: l10n.processDeactivateAction,
        cancelLabel: l10n.actionCancel,
        isDestructive: true,
      );
      if (confirmed == true) {
        await cubit.setActive(false);
      }
    } else {
      await cubit.setActive(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    return BlocBuilder<ProcessDetailCubit, ProcessDetailState>(
      builder: (context, state) {
        if (state.status == ProcessDetailStatus.loading ||
            state.status == ProcessDetailStatus.initial) {
          return AppScaffold(
            title: l10n.processDetailsHeading,
            body: const AppLoader(),
          );
        }
        if (state.status == ProcessDetailStatus.error || state.detail == null) {
          return AppScaffold(
            title: l10n.processDetailsHeading,
            body: AppErrorView(
              title: l10n.errorUnexpected,
              message: state.errorMessage,
              retryLabel: l10n.actionRetry,
              onRetry: () =>
                  context.read<ProcessDetailCubit>().loadProcess(processId),
            ),
          );
        }

        final detail = state.detail!;
        final proc = detail.process;

        final billingLabel = switch (proc.billingModeOverride) {
          ProcessBillingModeOverride.receivedQty => l10n.billingModeReceivedQty,
          ProcessBillingModeOverride.givenQty => l10n.billingModeGivenQty,
          null => l10n.processBillingInheritGlobal,
        };

        return AppScaffold(
          title: proc.name,
          actions: [
            AppIconButton(
              icon: AppIcons.edit,
              tooltip: l10n.processEditAction,
              onPressed: () async {
                await context.push(RoutePaths.processEdit(proc.id));
                if (context.mounted) {
                  await context.read<ProcessDetailCubit>().loadProcess(proc.id);
                }
              },
            ),
          ],
          body: ListView(
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppActionRow(
                      content: AppHeading(proc.name, level: AppHeadingLevel.h2),
                      actions: [
                        AppStatusBadge(
                          label: proc.isActive
                              ? l10n.statusActive
                              : l10n.statusInactive,
                          tone: proc.isActive
                              ? AppStatusTone.good
                              : AppStatusTone.neutral,
                        ),
                      ],
                    ),
                    if (proc.description != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppText(proc.description!),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    AppText(
                      'Default Labour Rate: ${proc.defaultRatePaise > 0 ? MoneyFormatter.formatRatePaise(proc.defaultRatePaise, pricingUnit: proc.defaultPricingUnit) : 'Not set'}',
                      variant: AppTextVariant.bodySmall,
                      fontWeight: FontWeight.w600,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      '${l10n.processBillingOverrideLabel}: $billingLabel',
                      variant: AppTextVariant.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      '${l10n.processIncludeDamagedLabel}: ${proc.includeDamagedInLabour ? l10n.statusEnabled : l10n.statusDisabled}',
                      variant: AppTextVariant.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      '${l10n.createdAtLabel}: ${AppDateTimeFormatter.formatDateTime(proc.createdAt, locale: localeCode)}',
                      variant: AppTextVariant.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      '${l10n.updatedAtLabel}: ${AppDateTimeFormatter.formatDateTime(proc.updatedAt, locale: localeCode)}',
                      variant: AppTextVariant.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        AppButton(
                          label: l10n.processEditAction,
                          icon: AppIcons.edit,
                          variant: AppButtonVariant.outlined,
                          onPressed: () async {
                            await context.push(RoutePaths.processEdit(proc.id));
                            if (context.mounted) {
                              await context
                                  .read<ProcessDetailCubit>()
                                  .loadProcess(proc.id);
                            }
                          },
                        ),
                        AppButton(
                          label: proc.isActive
                              ? l10n.processDeactivateAction
                              : l10n.processActivateAction,
                          icon: proc.isActive
                              ? AppIcons.pause
                              : AppIcons.resume,
                          variant: proc.isActive
                              ? AppButtonVariant.destructive
                              : AppButtonVariant.secondary,
                          onPressed: () => _confirmToggleActive(context, proc),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Phase 4: Process-Wise Production KPIs & Lot/Worker/Date/Pending History
              BlocBuilder<ProcessHistoryCubit, ProcessHistoryState>(
                builder: (context, histState) {
                  final ph = histState.selectedProcess;
                  if (ph == null) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppHeading(
                        l10n.prodHistoryProcessDetailsTitle,
                        level: AppHeadingLevel.h3,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: 4,
                              children: [
                                AppStatusBadge(
                                  label: 'Lots: ${ph.totalLots}',
                                  tone: AppStatusTone.info,
                                ),
                                AppStatusBadge(
                                  label: 'Workers: ${ph.totalWorkersInvolved}',
                                  tone: AppStatusTone.neutral,
                                ),
                                AppStatusBadge(
                                  label: 'Assigned: ${ph.assignedQty}',
                                  tone: AppStatusTone.info,
                                ),
                                AppStatusBadge(
                                  label: 'Accepted: ${ph.acceptedQty}',
                                  tone: AppStatusTone.good,
                                ),
                                AppStatusBadge(
                                  label:
                                      'Pending QC: ${ph.pendingInspectionQty}',
                                  tone: ph.pendingInspectionQty > 0
                                      ? AppStatusTone.pending
                                      : AppStatusTone.neutral,
                                ),
                                AppStatusBadge(
                                  label: 'Outstanding: ${ph.outstandingQty}',
                                  tone: ph.outstandingQty > 0
                                      ? AppStatusTone.pending
                                      : AppStatusTone.good,
                                ),
                                AppStatusBadge(
                                  label: 'Rejected: ${ph.rejectedQty}',
                                  tone: ph.rejectedQty > 0
                                      ? AppStatusTone.damaged
                                      : AppStatusTone.neutral,
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            AppText(
                              'Production Cost: ${MoneyFormatter.formatPaise(ph.totalProductionCostPaise)} • Paid (est): ${MoneyFormatter.formatPaise(ph.estimatedPaidPaise)} • Due (est): ${MoneyFormatter.formatPaise(ph.estimatedOutstandingPaise)}',
                              variant: AppTextVariant.numeric,
                              fontWeight: FontWeight.w600,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          AppChip(
                            label:
                                '${l10n.prodHistoryTabLotWise} (${ph.lotHistory.length})',
                            selected: _historyTab == 0,
                            onSelected: (_) => setState(() => _historyTab = 0),
                          ),
                          AppChip(
                            label:
                                '${l10n.prodHistoryTabWorkerWise} (${ph.workerHistory.length})',
                            selected: _historyTab == 1,
                            onSelected: (_) => setState(() => _historyTab = 1),
                          ),
                          AppChip(
                            label:
                                '${l10n.prodHistoryTabDateWise} (${ph.dateHistory.length})',
                            selected: _historyTab == 2,
                            onSelected: (_) => setState(() => _historyTab = 2),
                          ),
                          AppChip(
                            label:
                                '${l10n.prodHistoryTabPending} (${ph.pendingAssignments.length})',
                            selected: _historyTab == 3,
                            onSelected: (_) => setState(() => _historyTab = 3),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      if (_historyTab == 0)
                        AppLazySection(
                          key: const ValueKey('ph.lotHistory'),
                          initialCount: 15,
                          items: ph.lotHistory,
                          itemBuilder: (context, r, _) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: AppCard.listItem(
                              onTap: () =>
                                  context.push(RoutePaths.lotHistory(r.lotId)),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AppText(
                                          r.lotNumber,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        AppText(
                                          'Assigned: ${r.assignedQty} • Acc: ${r.acceptedQty} • Out: ${r.outstandingQty} • Rej: ${r.rejectedQty}',
                                          variant: AppTextVariant.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppText(
                                    MoneyFormatter.formatPaise(
                                      r.earnedAmountPaise,
                                    ),
                                    variant: AppTextVariant.numeric,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else if (_historyTab == 1)
                        AppLazySection(
                          key: const ValueKey('ph.workerHistory'),
                          initialCount: 15,
                          items: ph.workerHistory,
                          itemBuilder: (context, w, _) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: AppCard.listItem(
                              onTap: () => context.push(
                                RoutePaths.workerDetail(w.workerId),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AppText(
                                          w.workerName,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        AppText(
                                          'Lots: ${w.totalLots} • Assigned: ${w.assignedQty} • Acc: ${w.acceptedQty} • Rej: ${w.rejectedQty}',
                                          variant: AppTextVariant.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppText(
                                    MoneyFormatter.formatPaise(
                                      w.earnedAmountPaise,
                                    ),
                                    variant: AppTextVariant.numeric,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else if (_historyTab == 2)
                        AppLazySection(
                          key: const ValueKey('ph.dateHistory'),
                          initialCount: 15,
                          items: ph.dateHistory,
                          itemBuilder: (context, d, _) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: AppCard.listItem(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AppText(
                                          d.istDateIso,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        AppText(
                                          'Assigned: ${d.assignedQty} • Returned: ${d.returnedQty} • Acc: ${d.acceptedQty} • Rej: ${d.rejectedQty}',
                                          variant: AppTextVariant.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppText(
                                    MoneyFormatter.formatPaise(d.earnedPaise),
                                    variant: AppTextVariant.numeric,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        AppLazySection(
                          key: const ValueKey('ph.pendingAssignments'),
                          initialCount: 15,
                          items: ph.pendingAssignments,
                          itemBuilder: (context, p, _) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: AppCard.listItem(
                              onTap: () => context.push(
                                RoutePaths.productionTransactionDetail(
                                  ProductionTransactionKind
                                      .stockMovement
                                      .routeSegment,
                                  p.issueMovementId,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        AppText(
                                          '${p.lotNumber} • ${p.workerName}',
                                          fontWeight: FontWeight.w700,
                                        ),
                                        AppText(
                                          '${p.designName} • ${p.colourName} • Out: ${p.outstandingQty} • Pending QC: ${p.pendingInspectionQty}',
                                          variant: AppTextVariant.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(AppIcons.chevronRight),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.lg),
              AppHeading(
                l10n.processAssignedWorkersHeading,
                level: AppHeadingLevel.h3,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (detail.assignedWorkers.isEmpty)
                AppCard(
                  child: AppText(
                    l10n.processNoAssignedWorkers,
                    variant: AppTextVariant.bodySmall,
                  ),
                )
              else
                ...detail.assignedWorkers.map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard(
                      onTap: () =>
                          context.push(RoutePaths.workerDetail(w.workerId)),
                      child: AppActionRow(
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              w.workerName,
                              variant: AppTextVariant.bodyLarge,
                              fontWeight: FontWeight.w600,
                            ),
                            if (w.workerPhone != null)
                              AppText(
                                w.workerPhone!,
                                variant: AppTextVariant.bodySmall,
                              ),
                          ],
                        ),
                        actions: [
                          AppStatusBadge(
                            label: w.workerIsActive
                                ? l10n.statusActive
                                : l10n.statusInactive,
                            tone: w.workerIsActive
                                ? AppStatusTone.good
                                : AppStatusTone.neutral,
                          ),
                          const Icon(AppIcons.chevronRight),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              AppHeading(
                l10n.processAuditHistoryHeading,
                level: AppHeadingLevel.h3,
              ),
              const SizedBox(height: AppSpacing.sm),
              if (detail.auditHistory.isEmpty)
                AppCard(
                  child: AppText(
                    l10n.processNoAuditHistory,
                    variant: AppTextVariant.bodySmall,
                  ),
                )
              else
                AppCard(
                  child: Column(
                    children: detail.auditHistory
                        .map(
                          (entry) => AppListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(AppIcons.rateHistory),
                            title: Text(
                              DomainLabelLocalizer.auditAction(
                                l10n,
                                entry.actionType,
                              ),
                            ),
                            subtitle: Text(
                              AppDateTimeFormatter.formatDateTime(
                                entry.recordedAt,
                                locale: localeCode,
                              ),
                            ),
                            trailing: entry.actor != null
                                ? Text(entry.actor!)
                                : null,
                          ),
                        )
                        .toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
