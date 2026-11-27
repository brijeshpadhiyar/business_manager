import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/process_routing/domain/calculators/process_pricing_calculator.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/process_routing/presentation/bloc/job_routing_cubit.dart';
import 'package:business_manager/features/process_routing/presentation/routing_error_localizer.dart';
import 'package:business_manager/features/process_routing/presentation/widgets/routing_action_sheets.dart';
import 'package:business_manager/features/process_routing/presentation/widgets/routing_handover_row.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

AppStatusTone routingStatusTone(JobProcessStatus status) => switch (status) {
  JobProcessStatus.completed ||
  JobProcessStatus.returned ||
  JobProcessStatus.transferred => AppStatusTone.good,
  JobProcessStatus.dispatched ||
  JobProcessStatus.inProgress ||
  JobProcessStatus.partiallyCompleted ||
  JobProcessStatus.partiallyReturned => AppStatusTone.pending,
  JobProcessStatus.cancelled => AppStatusTone.damaged,
  JobProcessStatus.draft || JobProcessStatus.pending => AppStatusTone.neutral,
};

AppStatusTone routingPaymentTone(ProcessPaymentStatus status) =>
    switch (status) {
      ProcessPaymentStatus.paid => AppStatusTone.good,
      ProcessPaymentStatus.partiallyPaid => AppStatusTone.info,
      ProcessPaymentStatus.pending => AppStatusTone.pending,
    };

AppStatusTone routingHandoverTone(ProcessHandoverType type) => switch (type) {
  ProcessHandoverType.directTransfer => AppStatusTone.info,
  ProcessHandoverType.factoryReturn => AppStatusTone.good,
  ProcessHandoverType.factoryDispatch ||
  ProcessHandoverType.reassignment => AppStatusTone.pending,
  ProcessHandoverType.cancellation => AppStatusTone.damaged,
};

/// Worker payables breakdown card on [JobProcessRoutingPage].
final class RoutingWorkerPayablesCard extends StatelessWidget {
  const RoutingWorkerPayablesCard({super.key, required this.workerPayables});

  final List<WorkerCostBreakdown> workerPayables;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppMotionEntrance(
      index: 2,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppHeading(
              l10n.routingWorkerPayableSummaryHeading,
              level: AppHeadingLevel.h3,
            ),
            const SizedBox(height: AppSpacing.sm),
            for (var i = 0; i < workerPayables.length; i++) ...[
              AppActionRow(
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      workerPayables[i].workerName,
                      fontWeight: FontWeight.w700,
                    ),
                    AppText(
                      '${workerPayables[i].totalQuantity} ${l10n.piecesUnit} • ${MoneyFormatter.formatPaise(workerPayables[i].netPayablePaise)} / ${MoneyFormatter.formatPaise(workerPayables[i].paidPaise)}',
                      variant: AppTextVariant.bodySmall,
                    ),
                  ],
                ),
                actions: [
                  AppStatusBadge(
                    label: workerPayables[i].paymentStatus.label,
                    tone: routingPaymentTone(workerPayables[i].paymentStatus),
                  ),
                ],
              ),
              if (i < workerPayables.length - 1)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xsm),
                  child: AppDivider(),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Live goods location pills card on [JobProcessRoutingPage].
final class RoutingCurrentLocationsCard extends StatelessWidget {
  const RoutingCurrentLocationsCard({super.key, required this.locations});

  final List<GoodsLocationBucket> locations;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppHeading(
            l10n.routingCurrentGoodsLocationHeading,
            level: AppHeadingLevel.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final loc in locations)
                AppStatusBadge(
                  label:
                      '${loc.locationLabel} (${loc.operationLabel}): ${loc.quantity} ${l10n.piecesUnit}',
                  tone: loc.isFactory
                      ? AppStatusTone.good
                      : AppStatusTone.pending,
                  icon: loc.isFactory ? AppIcons.factory : AppIcons.worker,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Interactive process operation card for a single [JobProcessEntity].
final class RoutingProcessCard extends StatelessWidget {
  const RoutingProcessCard({
    super.key,
    required this.overview,
    required this.jobProcess,
    this.colourHex,
  });

  final JobRoutingOverview overview;
  final JobProcessEntity jobProcess;
  final String? colourHex;

  Future<void> _openWorkerPayment(BuildContext context) async {
    final cubit = context.read<JobRoutingCubit>();
    await context.push(
      RoutePaths.paymentCreate(workerId: jobProcess.memberId),
    );
    await cubit.load(jobProcess.lotId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<JobRoutingCubit>();
    final jp = jobProcess;

    return AppCard.listItem(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RoutingOperationHeader(
            jobProcess: jp,
            statusTone: routingStatusTone(jp.status),
            colourHex: colourHex,
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppStatusBadge(
                label:
                    '${MoneyFormatter.formatPaise(jp.agreedRatePaise)} / ${ProcessPricingCalculator.unitLabel(jp.pricingUnit)}',
                tone: jp.isRateOverridden
                    ? AppStatusTone.info
                    : AppStatusTone.neutral,
              ),
              if (jp.isRateOverridden)
                AppStatusBadge(
                  label: MoneyFormatter.formatPaise(jp.defaultRatePaise),
                  tone: AppStatusTone.neutral,
                ),
              AppStatusBadge(
                label:
                    '${l10n.routingOutstandingPayableLabel}: ${MoneyFormatter.formatPaise(jp.payableAmountPaise)} (${jp.paymentStatus.label})',
                tone: routingPaymentTone(jp.paymentStatus),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppStatusBadge(
                label: '${l10n.stockIssuedLabel}: ${jp.dispatchedQuantity}',
                tone: AppStatusTone.neutral,
              ),
              if (jp.receivedQuantity > 0)
                AppStatusBadge(
                  label:
                      '${l10n.stockGoodReturnedLabel}: ${jp.receivedQuantity}',
                  tone: AppStatusTone.info,
                ),
              if (jp.transferredOutQuantity > 0)
                AppStatusBadge(
                  label:
                      '${l10n.routingDirectTransferAction}: ${jp.transferredOutQuantity}',
                  tone: AppStatusTone.info,
                ),
              if (jp.returnedToFactoryQuantity > 0)
                AppStatusBadge(
                  label:
                      '${l10n.routingReturnToFactoryAction}: ${jp.returnedToFactoryQuantity}',
                  tone: AppStatusTone.good,
                ),
              AppStatusBadge(
                label:
                    '${l10n.stockPendingWorkerLabel}: ${jp.pendingQuantity} ${l10n.piecesUnit}',
                tone: jp.pendingQuantity > 0
                    ? AppStatusTone.pending
                    : AppStatusTone.good,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (jp.canDispatch)
                AppButton(
                  label: '${l10n.stockIssueAction} (${jp.remainingToDispatch})',
                  icon: AppIcons.dispatch,
                  onPressed: () async {
                    final err = await cubit.dispatchProcess(
                      jobProcessId: jp.id,
                      quantity: jp.remainingToDispatch,
                    );
                    if (err != null && context.mounted) {
                      AppFeedback.showError(
                        context,
                        RoutingErrorLocalizer.localize(l10n, err),
                      );
                    }
                  },
                ),
              if (jp.canTransferOrReturn)
                AppButton(
                  label: l10n.routingDirectTransferAction,
                  icon: AppIcons.routeTransfer,
                  onPressed: () => RoutingActionSheets.showDirectTransferSheet(
                    context,
                    overview,
                    jp,
                  ),
                ),
              if (jp.canTransferOrReturn)
                AppButton(
                  label: l10n.routingReturnToFactoryAction,
                  icon: AppIcons.factory,
                  variant: AppButtonVariant.secondary,
                  onPressed: () =>
                      RoutingActionSheets.showReturnToFactorySheet(context, jp),
                ),
              if (jp.status != JobProcessStatus.cancelled)
                AppButton(
                  label: l10n.routingAddChargeTitle,
                  icon: AppIcons.addCharge,
                  variant: AppButtonVariant.outlined,
                  onPressed: () =>
                      RoutingActionSheets.showAdditionalChargeSheet(
                        context,
                        jp,
                      ),
                ),
              if (jp.status != JobProcessStatus.cancelled &&
                  jp.memberId != null)
                AppButton(
                  label: l10n.routingPayAction,
                  icon: AppIcons.payment,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => _openWorkerPayment(context),
                ),
              if (jp.canComplete)
                AppButton(
                  label: l10n.routingMarkCompletedAction,
                  icon: AppIcons.successOutline,
                  variant: AppButtonVariant.outlined,
                  onPressed: () async {
                    final err = await cubit.markCompleted(jp.id);
                    if (err != null && context.mounted) {
                      AppFeedback.showError(
                        context,
                        RoutingErrorLocalizer.localize(l10n, err),
                      );
                    }
                  },
                ),
              if (jp.canCancel)
                AppButton(
                  label: l10n.routingCancelAction,
                  icon: AppIcons.cancel,
                  variant: AppButtonVariant.text,
                  onPressed: () =>
                      RoutingActionSheets.showCancelDialog(context, jp),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
