import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';
import 'package:business_manager/features/guidance/presentation/registry/guide_target_registry.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/production_history/presentation/bloc/worker_production_history_cubit.dart';
import 'package:business_manager/features/reports/domain/calculators/workshop_daily_calculator.dart';
import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';
import 'package:business_manager/features/workers/presentation/bloc/worker_detail_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Worker Profile Summary & Complete Worker Production Account page (Phase 3).
final class WorkerDetailPage extends StatelessWidget {
  const WorkerDetailPage({super.key, required this.workerId});

  final String workerId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<WorkerDetailCubit>(
          create: (_) => getIt<WorkerDetailCubit>()..loadWorker(workerId),
        ),
        BlocProvider<WorkerProductionHistoryCubit>(
          create: (_) =>
              getIt<WorkerProductionHistoryCubit>()..loadWorker(workerId),
        ),
      ],
      child: _WorkerDetailView(workerId: workerId),
    );
  }
}

final class _WorkerDetailView extends StatelessWidget {
  const _WorkerDetailView({required this.workerId});

  final String workerId;

  Future<void> _confirmToggleActive(
    BuildContext context,
    WorkerEntity worker,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<WorkerDetailCubit>();
    if (worker.isActive) {
      final confirmed = await AppDialog.showConfirmation(
        context,
        title: l10n.workerDeactivateConfirmTitle,
        message: l10n.workerDeactivateConfirmMessage,
        confirmLabel: l10n.workerDeactivateAction,
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

    return BlocBuilder<WorkerDetailCubit, WorkerDetailState>(
      builder: (context, state) {
        if (state.status == WorkerDetailStatus.loading ||
            state.status == WorkerDetailStatus.initial) {
          return AppScaffold(
            title: l10n.workerDetailsHeading,
            body: const AppLoader(),
          );
        }
        if (state.status == WorkerDetailStatus.error || state.detail == null) {
          return AppScaffold(
            title: l10n.workerDetailsHeading,
            body: AppErrorView(
              title: l10n.errorUnexpected,
              message: state.errorMessage,
              retryLabel: l10n.actionRetry,
              onRetry: () =>
                  context.read<WorkerDetailCubit>().loadWorker(workerId),
            ),
          );
        }

        final detail = state.detail!;
        final worker = detail.worker;

        return AppScaffold(
          title: worker.name,
          actions: [
            AppIconButton(
              icon: AppIcons.edit,
              tooltip: l10n.workerEditAction,
              onPressed: () async {
                await context.push(RoutePaths.workerEdit(worker.id));
                if (context.mounted) {
                  await context.read<WorkerDetailCubit>().loadWorker(worker.id);
                }
              },
            ),
          ],
          body: ListView(
            children: [
              // Profile header & contact info
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppActionRow(
                      content: AppHeading(
                        worker.name,
                        level: AppHeadingLevel.h2,
                      ),
                      actions: [
                        AppStatusBadge(
                          label: worker.isActive
                              ? l10n.statusActive
                              : l10n.statusInactive,
                          tone: worker.isActive
                              ? AppStatusTone.good
                              : AppStatusTone.neutral,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppText(
                      l10n.workerContactHeading,
                      variant: AppTextVariant.label,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (worker.phone == null && worker.address == null)
                      AppText(
                        l10n.workerNoContactInfo,
                        variant: AppTextVariant.bodySmall,
                      )
                    else ...[
                      if (worker.phone != null)
                        Row(
                          children: [
                            const Icon(AppIcons.phone, size: 16),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(child: AppText(worker.phone!)),
                          ],
                        ),
                      if (worker.address != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(AppIcons.location, size: 16),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(child: AppText(worker.address!)),
                          ],
                        ),
                      ],
                    ],
                    if (worker.notes != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      AppText(worker.notes!, variant: AppTextVariant.bodySmall),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    AppText(
                      '${l10n.createdAtLabel}: ${IstDateTimeHelper.formatIstDateTime(worker.createdAt, locale: localeCode)}',
                      variant: AppTextVariant.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: [
                        GuideTarget(
                          id: GuideTargetId.workerDetailAssignments,
                          child: AppButton(
                            label: l10n.workerManageAssignmentsAction,
                            icon: AppIcons.link,
                            onPressed: () async {
                              await context.push(
                                RoutePaths.workerAssignments(worker.id),
                              );
                              if (context.mounted) {
                                await context
                                    .read<WorkerDetailCubit>()
                                    .loadWorker(worker.id);
                              }
                            },
                          ),
                        ),
                        GuideTarget(
                          id: GuideTargetId.workerDetailRates,
                          child: AppButton(
                            label: l10n.workerViewRateHistoryAction,
                            icon: AppIcons.pieceRate,
                            variant: AppButtonVariant.secondary,
                            onPressed: () async {
                              await context.push(
                                RoutePaths.workerRates(worker.id),
                              );
                              if (context.mounted) {
                                await context
                                    .read<WorkerDetailCubit>()
                                    .loadWorker(worker.id);
                              }
                            },
                          ),
                        ),
                        GuideTarget(
                          id: GuideTargetId.workerDetailLedger,
                          child: AppButton(
                            label: l10n.accountingOpenLedgerAction,
                            icon: AppIcons.accounting,
                            variant: AppButtonVariant.secondary,
                            onPressed: () => context.push(
                              RoutePaths.workerLedger(worker.id),
                            ),
                          ),
                        ),
                        AppButton(
                          label: l10n.accountingRecordPaymentAction,
                          icon: AppIcons.payment,
                          variant: AppButtonVariant.outlined,
                          onPressed: () => context.push(
                            RoutePaths.paymentCreate(workerId: worker.id),
                          ),
                        ),
                        AppButton(
                          label: worker.isActive
                              ? l10n.workerDeactivateAction
                              : l10n.workerActivateAction,
                          icon: worker.isActive
                              ? AppIcons.workerInactive
                              : AppIcons.worker,
                          variant: worker.isActive
                              ? AppButtonVariant.destructive
                              : AppButtonVariant.outlined,
                          onPressed: () =>
                              _confirmToggleActive(context, worker),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // V1.2 Live Worker Work & Financial Overview (reconciled with LedgerCalculator)
              if (state.ledgerDetail != null) ...[
                Builder(
                  builder: (context) {
                    final ledger = state.ledgerDetail!;
                    final fin = ledger.summary;
                    final stock = ledger.stockSummary;
                    final openIssues = state.openIssues;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppHeading(
                          l10n.workerWorkOverviewHeading,
                          level: AppHeadingLevel.h3,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth >= 580;
                            final tileW = isWide
                                ? (constraints.maxWidth - AppSpacing.sm * 3) / 4
                                : (constraints.maxWidth - AppSpacing.sm) / 2;
                            return Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                SizedBox(
                                  width: tileW,
                                  child: AppMetricTile(
                                    label: l10n.stockPendingWorkerLabel,
                                    value: stock.pending,
                                    suffix: l10n.piecesUnit,
                                    subtitle:
                                        '${openIssues.length} ${l10n.workerOpenIssuesCountLabel}',
                                    icon: AppIcons.pending,
                                    tone: stock.pending > 0
                                        ? AppStatusTone.pending
                                        : AppStatusTone.good,
                                    onTap: () => context.push(
                                      RoutePaths.stockReturnPickerFiltered(
                                        workerId: worker.id,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: tileW,
                                  child: AppMetricTile(
                                    label: l10n.accountingEarnedLabourLabel,
                                    value: fin.earnedLabourPaise,
                                    isCurrencyPaise: true,
                                    icon: AppIcons.work,
                                    tone: AppStatusTone.good,
                                    onTap: () => context.push(
                                      RoutePaths.workerLedger(worker.id),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: tileW,
                                  child: AppMetricTile(
                                    label: fin.advanceCreditBalancePaise > 0
                                        ? l10n.accountingAdvanceCreditLabel
                                        : l10n.accountingOutstandingPayableLabel,
                                    value: fin.advanceCreditBalancePaise > 0
                                        ? fin.advanceCreditBalancePaise
                                        : fin.outstandingPayablePaise,
                                    isCurrencyPaise: true,
                                    icon: AppIcons.accounting,
                                    tone: fin.advanceCreditBalancePaise > 0
                                        ? AppStatusTone.info
                                        : (fin.outstandingPayablePaise > 0
                                              ? AppStatusTone.pending
                                              : AppStatusTone.good),
                                    onTap: () => context.push(
                                      RoutePaths.workerLedger(worker.id),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: tileW,
                                  child: AppMetricTile(
                                    label: l10n.stockGoodReturnedLabel,
                                    value: stock.goodReturned,
                                    suffix: l10n.piecesUnit,
                                    icon: AppIcons.successOutline,
                                    tone: AppStatusTone.neutral,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        if (openIssues.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                AppActionRow(
                                  content: AppText(
                                    l10n.workerOpenIssuesHeading,
                                    variant: AppTextVariant.label,
                                  ),
                                  actions: [
                                    AppButton(
                                      label: l10n.dashboardViewAllPendingAction,
                                      variant: AppButtonVariant.text,
                                      onPressed: () async {
                                        await context.push(
                                          RoutePaths.stockReturnPickerFiltered(
                                            workerId: worker.id,
                                          ),
                                        );
                                        if (context.mounted) {
                                          await context
                                              .read<WorkerDetailCubit>()
                                              .loadWorker(worker.id);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                                for (
                                  var i = 0;
                                  i < openIssues.take(3).length;
                                  i++
                                ) ...[
                                  Builder(
                                    builder: (context) {
                                      final issue = openIssues[i];
                                      final v = issue.issueView;
                                      final ageDays =
                                          WorkshopDailyCalculator.pendingAgeDays(
                                            v.movement.transactionAt,
                                            IstDateTimeHelper.nowUtcMillis(),
                                          );
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: AppSpacing.xs,
                                        ),
                                        child: AppActionRow(
                                          content: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              AppText(
                                                '${v.processName ?? '-'} • ${v.lotNumber} • ${v.colourName}',
                                                fontWeight: FontWeight.w600,
                                              ),
                                              AppText(
                                                '${issue.remainingPending} ${l10n.piecesUnit} • ${ageDays == 0 ? l10n.reportPresetToday : l10n.pendingAgeDaysBadge(ageDays)}',
                                                variant:
                                                    AppTextVariant.bodySmall,
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            AppButton(
                                              label: l10n.stockReturnAction,
                                              variant:
                                                  AppButtonVariant.secondary,
                                              onPressed: () async {
                                                await context.push(
                                                  RoutePaths.stockReturn(
                                                    v.movement.id,
                                                  ),
                                                );
                                                if (context.mounted) {
                                                  await context
                                                      .read<WorkerDetailCubit>()
                                                      .loadWorker(worker.id);
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                  if (i < openIssues.take(3).length - 1)
                                    const AppDivider(),
                                ],
                              ],
                            ),
                          ),
                        ],
                        if (ledger.payments
                            .where(
                              (p) =>
                                  !p.isReversed &&
                                  p.payment.paymentType != PaymentType.reversal,
                            )
                            .isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  l10n.workerRecentPaymentsHeading,
                                  variant: AppTextVariant.label,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                for (final p
                                    in ledger.payments
                                        .where(
                                          (p) =>
                                              !p.isReversed &&
                                              p.payment.paymentType !=
                                                  PaymentType.reversal,
                                        )
                                        .take(3))
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: AppSpacing.xs,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: AppText(
                                            AppDateTimeFormatter.formatDate(
                                              p.payment.transactionAt,
                                              locale: localeCode,
                                            ),
                                            variant: AppTextVariant.bodySmall,
                                          ),
                                        ),
                                        AppText(
                                          MoneyFormatter.formatPaise(
                                            p.payment.amountPaise,
                                          ),
                                          variant: AppTextVariant.numeric,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              AppHeading(
                l10n.workerAssignedProcessesHeading,
                level: AppHeadingLevel.h3,
                trailing: AppButton(
                  label: l10n.workerAddRateAction,
                  icon: AppIcons.add,
                  variant: AppButtonVariant.outlined,
                  onPressed: () async {
                    await context.push(RoutePaths.workerRateCreate(worker.id));
                    if (context.mounted) {
                      await context.read<WorkerDetailCubit>().loadWorker(
                        worker.id,
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (detail.assignedProcesses.isEmpty)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        l10n.workerNoAssignedProcesses,
                        variant: AppTextVariant.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppButton(
                        label: l10n.workerManageAssignmentsAction,
                        icon: AppIcons.link,
                        variant: AppButtonVariant.outlined,
                        onPressed: () async {
                          await context.push(
                            RoutePaths.workerAssignments(worker.id),
                          );
                          if (context.mounted) {
                            await context.read<WorkerDetailCubit>().loadWorker(
                              worker.id,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                )
              else
                ...detail.assignedProcesses.map((summary) {
                  final assignment = summary.assignment;
                  final currentRate = summary.currentRate;
                  final hasProcessDefault = summary.processDefaultRatePaise > 0;
                  final String rateDisplay;
                  final String sourceBadgeLabel;
                  final AppStatusTone sourceBadgeTone;

                  if (currentRate != null) {
                    rateDisplay =
                        '${MoneyFormatter.formatPaise(currentRate.ratePaise)} ${l10n.ratesPerPieceSuffix}';
                    sourceBadgeLabel = 'Worker Rate';
                    sourceBadgeTone = AppStatusTone.good;
                  } else if (hasProcessDefault) {
                    rateDisplay = MoneyFormatter.formatRatePaise(
                      summary.processDefaultRatePaise,
                      pricingUnit: summary.processDefaultPricingUnit,
                    );
                    sourceBadgeLabel = 'Process Default';
                    sourceBadgeTone = AppStatusTone.info;
                  } else {
                    rateDisplay = l10n.ratesNoCurrentRate;
                    sourceBadgeLabel = 'No Rate';
                    sourceBadgeTone = AppStatusTone.pending;
                  }

                  final periodText = currentRate != null
                      ? AppDateTimeFormatter.formatIsoDateRange(
                          fromIso: currentRate.effectiveFrom,
                          toIso: currentRate.effectiveTo,
                          ongoingLabel: l10n.ratesOngoingLabel,
                          locale: localeCode,
                        )
                      : (hasProcessDefault
                            ? 'Inherited from ${assignment.processName}'
                            : null);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AppCard.listItem(
                      key: ValueKey<String>(
                        'worker_detail_proc_${assignment.processId}',
                      ),
                      onTap: () async {
                        await context.push(
                          RoutePaths.workerRates(
                            worker.id,
                            processId: assignment.processId,
                          ),
                        );
                        if (context.mounted) {
                          await context.read<WorkerDetailCubit>().loadWorker(
                            worker.id,
                          );
                        }
                      },
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: AppSpacing.xs,
                                  runSpacing: AppSpacing.xs,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    AppText(
                                      assignment.processName,
                                      variant: AppTextVariant.bodyLarge,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    AppStatusBadge(
                                      label: sourceBadgeLabel,
                                      tone: sourceBadgeTone,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                AppText(
                                  '${l10n.ratesCurrentRateLabel}: $rateDisplay',
                                  variant: AppTextVariant.numeric,
                                  fontWeight: FontWeight.w600,
                                ),
                                if (periodText != null) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  AppText(
                                    periodText,
                                    variant: AppTextVariant.bodySmall,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AppStatusBadge(
                                label: '${summary.totalRateHistoryCount}',
                                tone: currentRate != null
                                    ? AppStatusTone.good
                                    : (hasProcessDefault
                                          ? AppStatusTone.info
                                          : AppStatusTone.pending),
                                icon: AppIcons.rateHistory,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              const Icon(AppIcons.chevronRight),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              // Phase 3: Worker Process-Wise History & Worker Lot History
              BlocBuilder<
                WorkerProductionHistoryCubit,
                WorkerProductionHistoryState
              >(
                builder: (context, prodState) {
                  final profile = prodState.selectedProfile;
                  if (profile == null) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppSpacing.lg),
                      AppCard(
                        child: Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: 4,
                          children: [
                            AppStatusBadge(
                              label: l10n.lotLotsValue(
                                profile.totalLotsAssigned,
                              ),
                              tone: AppStatusTone.info,
                            ),
                            AppStatusBadge(
                              label: l10n.lotCompletedValue(
                                profile.totalProcessesCompleted,
                              ),
                              tone: AppStatusTone.good,
                            ),
                            AppStatusBadge(
                              label:
                                  '${l10n.prodHistoryTotalAssigned}: ${profile.assignedQty}',
                              tone: AppStatusTone.neutral,
                            ),
                            AppStatusBadge(
                              label:
                                  '${l10n.prodHistoryTotalAccepted}: ${profile.acceptedQty}',
                              tone: AppStatusTone.good,
                            ),
                            if (profile.pendingInspectionQty > 0)
                              AppStatusBadge(
                                label: l10n.lotPendingQcValue(
                                  profile.pendingInspectionQty,
                                ),
                                tone: AppStatusTone.pending,
                              ),
                            if (profile.rejectedQty > 0)
                              AppStatusBadge(
                                label: l10n.lotRejectedValue(
                                  profile.rejectedQty,
                                ),
                                tone: AppStatusTone.damaged,
                              ),
                          ],
                        ),
                      ),
                      if (profile.processHistory.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        AppHeading(
                          l10n.prodHistoryWorkerProcessHistory,
                          level: AppHeadingLevel.h3,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (final ph in profile.processHistory)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: AppCard.listItem(
                              onTap: () => context.push(
                                RoutePaths.processDetail(ph.processId),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: AppText(
                                          ph.processName,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      AppText(
                                        '${MoneyFormatter.formatQuantity(ph.acceptedQty)} / ${MoneyFormatter.formatQuantity(ph.assignedQty)} ${l10n.piecesUnit}',
                                        variant: AppTextVariant.numeric,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  AppText(
                                    [
                                      l10n.lotLotsValue(ph.totalLots),
                                      l10n.lotEarnedValue(
                                        MoneyFormatter.formatPaise(
                                          ph.earnedAmountPaise,
                                        ),
                                      ),
                                      l10n.lotPendingEstimateValue(
                                        MoneyFormatter.formatPaise(
                                          ph.estimatedPendingPayablePaise,
                                        ),
                                      ),
                                    ].join(' • '),
                                    variant: AppTextVariant.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                      if (profile.lotHistory.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.lg),
                        AppHeading(
                          '${l10n.prodHistoryWorkerLotHistory} (${profile.lotHistory.length})',
                          level: AppHeadingLevel.h3,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (final item in profile.lotHistory.take(25))
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.xs,
                            ),
                            child: AppCard.listItem(
                              onTap: () => context.push(
                                RoutePaths.productionTransactionDetail(
                                  ProductionTransactionKind
                                      .stockMovement
                                      .routeSegment,
                                  item.issueMovementId,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppActionRow(
                                    content: AppText(
                                      '${item.lotNumber} • ${item.processName}',
                                      fontWeight: FontWeight.w700,
                                    ),
                                    actions: [
                                      AppStatusBadge(
                                        label: item.isCompleted
                                            ? 'COMPLETED'
                                            : 'PENDING',
                                        tone: item.isCompleted
                                            ? AppStatusTone.good
                                            : AppStatusTone.pending,
                                      ),
                                    ],
                                  ),
                                  AppText(
                                    '${item.designName} • ${item.colourName} • ${AppDateTimeFormatter.formatDateTime(item.assignedAt, locale: localeCode)}',
                                    variant: AppTextVariant.bodySmall,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  AppText(
                                    'Given: ${item.assignedQty} • Returned: ${item.returnedQty} • Acc: ${item.totalAcceptedQty} • Pending: ${item.outstandingQty} • Rej: ${item.netRejectedQty}',
                                    variant: AppTextVariant.bodySmall,
                                  ),
                                  AppText(
                                    'Rate: ${MoneyFormatter.formatPaise(item.lockedRatePaise)}/pc • Earned: ${MoneyFormatter.formatPaise(item.earnedAmountPaise)}'
                                    '${item.completedAt != null ? ' • Done: ${AppDateTimeFormatter.formatDate(item.completedAt!, locale: localeCode)}' : ''}',
                                    variant: AppTextVariant.numeric,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        );
      },
    );
  }
}
