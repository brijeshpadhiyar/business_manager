import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/process_routing/domain/calculators/process_pricing_calculator.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/process_routing/presentation/bloc/job_routing_cubit.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// StitchFlow V1.3 — Dedicated Colour Detail Screen.
///
/// Displays actual colour preview, HEX/RGB info, design info, quantity
/// breakdown (total, available, completed, pending), Cutting/Stitching/Packing
/// & all process statuses, worker-wise distribution & pricing, total production
/// cost, and full movement history strictly scoped to [colourId].
final class LotColourDetailPage extends StatelessWidget {
  const LotColourDetailPage({
    super.key,
    required this.lotId,
    required this.colourId,
  });

  final String lotId;
  final String colourId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JobRoutingCubit>(
      create: (_) => getIt<JobRoutingCubit>()..load(lotId),
      child: _LotColourDetailView(lotId: lotId, colourId: colourId),
    );
  }
}

final class _LotColourDetailView extends StatelessWidget {
  const _LotColourDetailView({required this.lotId, required this.colourId});

  final String lotId;
  final String colourId;

  static const _pricingCalc = ProcessPricingCalculator();

  AppStatusTone _statusTone(JobProcessStatus status) => switch (status) {
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

  AppStatusTone _paymentTone(ProcessPaymentStatus status) => switch (status) {
    ProcessPaymentStatus.paid => AppStatusTone.good,
    ProcessPaymentStatus.partiallyPaid => AppStatusTone.info,
    ProcessPaymentStatus.pending => AppStatusTone.pending,
  };

  AppStatusTone _handoverTone(ProcessHandoverType type) => switch (type) {
    ProcessHandoverType.directTransfer => AppStatusTone.info,
    ProcessHandoverType.factoryReturn => AppStatusTone.good,
    ProcessHandoverType.factoryDispatch ||
    ProcessHandoverType.reassignment => AppStatusTone.pending,
    ProcessHandoverType.cancellation => AppStatusTone.damaged,
  };

  @override
  Widget build(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;
    return BlocBuilder<JobRoutingCubit, JobRoutingState>(
      builder: (context, state) {
        final overview = state.overview;
        final sku = overview?.skuBalances
            .where((b) => b.designColourId == colourId)
            .firstOrNull;

        return AppScaffold(
          title: sku != null
              ? context.l10n.lotColourDetailsFor(sku.colourName)
              : context.l10n.lotColourDetails,
          actions: [
            AppIconButton(
              icon: AppIcons.refresh,
              tooltip: context.l10n.routingRefreshTooltip,
              onPressed: () => context.read<JobRoutingCubit>().load(lotId),
            ),
          ],
          padding: EdgeInsets.zero,
          body: switch (state.status) {
            JobRoutingStatus.initial ||
            JobRoutingStatus.loading => const AppSkeletonList(itemCount: 4),
            JobRoutingStatus.error => AppErrorView(
              title: context.l10n.lotColourDetailsLoadError,
              message: state.errorMessage,
              retryLabel: context.l10n.actionRetry,
              onRetry: () => context.read<JobRoutingCubit>().load(lotId),
            ),
            JobRoutingStatus.loaded =>
              sku == null
                  ? AppEmptyState(
                      icon: AppIcons.colour,
                      title: context.l10n.lotColourNotFound,
                      subtitle: context.l10n.lotColourNotFoundHelp,
                    )
                  : _buildLoaded(context, overview!, sku, localeCode),
          },
        );
      },
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    JobRoutingOverview overview,
    DesignColourStockBalance sku,
    String localeCode,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final swatchColor = AppColourUtils.resolveColor(
      sku.colourHex,
      fallbackName: sku.colourName,
    );
    final hexLabel =
        AppColourUtils.normalizeHex(sku.colourHex) ??
        AppColourUtils.toHex(swatchColor);
    final rgbLabel = AppColourUtils.formatRgb(swatchColor);
    final onSwatch = AppColourUtils.contrastForeground(swatchColor);
    final isColourOnly =
        sku.designName == kColourOnlyDesignSentinel ||
        sku.designName.trim().isEmpty;

    // Strictly colour-scoped slices — never mix different colours or designs.
    final ops = overview.jobProcesses
        .where((p) => p.designColourId == colourId)
        .toList();
    final activeOps = ops
        .where((p) => p.status != JobProcessStatus.cancelled)
        .toList();
    final charges = overview.additionalCharges
        .where((c) => c.designColourId == colourId)
        .toList();
    final handovers = overview.handovers
        .where((h) => h.designColourId == colourId)
        .toList();
    final costSummary = _pricingCalc.calculateJobCostSummary(
      jobProcesses: ops,
      charges: charges,
    );

    final totalAssigned = activeOps.fold<int>(
      0,
      (sum, op) =>
          sum +
          (op.dispatchedQuantity > 0
              ? op.dispatchedQuantity
              : op.plannedQuantity),
    );
    final completedQty = activeOps.fold<int>(
      0,
      (sum, op) =>
          sum + op.returnedToFactoryQuantity + op.transferredOutQuantity,
    );
    final pendingQty = sku.totalPendingWithWorkers;
    final availableQty = sku.physicalAvailableInHouse;

    // One summary per work stage actually used on this colour.
    final stageSummaries = _buildProcessStageSummaries(context, activeOps);

    return RefreshIndicator(
      onRefresh: () => context.read<JobRoutingCubit>().load(lotId),
      child: ListView(
        padding: AppSpacing.screenAll,
        children: [
          // 1. Colour Hero Card with Actual Colour Banner
          AppMotionEntrance(
            index: 0,
            child: AppCard(
              padding: EdgeInsets.zero,
              borderRadius: AppRadius.xlBorder,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: swatchColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(AppRadius.xl),
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: AppColourUtils.swatchBorderColor(
                            swatchColor,
                            brightness,
                          ),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: onSwatch.withValues(alpha: 0.14),
                            borderRadius: AppRadius.mdBorder,
                            border: Border.all(
                              color: onSwatch.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Icon(
                            AppIcons.colour,
                            color: onSwatch,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sku.colourName,
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: onSwatch,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$hexLabel  •  $rgbLabel',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: onSwatch.withValues(alpha: 0.88),
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isColourOnly
                                    ? 'Lot #${overview.lot.lotNumber}  •  Colour-Only Lot (No Design)'
                                    : context.l10n.lotHashDesign(
                                        overview.lot.lotNumber,
                                        sku.designName,
                                      ),
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: onSwatch.withValues(alpha: 0.92),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            AppStatusBadge(
                              label: context.l10n.lotQtyPcsValue(
                                sku.initialQuantity,
                              ),
                              tone: AppStatusTone.info,
                            ),
                            AppStatusBadge(
                              label: context.l10n.lotTotalAssignedPcs(
                                totalAssigned,
                              ),
                              tone: AppStatusTone.neutral,
                            ),
                            if (sku.unitPricePaise > 0)
                              AppStatusBadge(
                                label: context.l10n.lotUnitValue(
                                  MoneyFormatter.formatPaise(
                                    sku.unitPricePaise,
                                  ),
                                ),
                                tone: AppStatusTone.neutral,
                              ),
                            if (sku.damagedBucket > 0)
                              AppStatusBadge(
                                label: context.l10n.lotDamagedPcs(
                                  sku.damagedBucket,
                                ),
                                tone: AppStatusTone.damaged,
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppButton(
                          label: context.l10n.lotManageStagesFor(
                            sku.colourName,
                          ),
                          icon: AppIcons.routeTransfer,
                          isExpanded: true,
                          onPressed: () => context.push(
                            RoutePaths.lotRouting(
                              lotId,
                              designColourId: colourId,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. Quantity Summary Metric Tiles
          AppMotionEntrance(
            index: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tileW = (constraints.maxWidth - AppSpacing.sm) / 2;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    SizedBox(
                      width: tileW,
                      child: AppMetricTile(
                        label: context.l10n.lotAvailableFactory,
                        value: availableQty,
                        suffix: 'pcs',
                        icon: AppIcons.factory,
                        tone: AppStatusTone.good,
                      ),
                    ),
                    SizedBox(
                      width: tileW,
                      child: AppMetricTile(
                        label: context.l10n.lotPendingWorkers,
                        value: pendingQty,
                        suffix: 'pcs',
                        icon: AppIcons.pending,
                        tone: pendingQty > 0
                            ? AppStatusTone.pending
                            : AppStatusTone.neutral,
                      ),
                    ),
                    SizedBox(
                      width: tileW,
                      child: AppMetricTile(
                        label: context.l10n.lotCompletedHandedOver,
                        value: completedQty,
                        suffix: 'pcs',
                        icon: AppIcons.successOutline,
                        tone: completedQty > 0
                            ? AppStatusTone.good
                            : AppStatusTone.neutral,
                      ),
                    ),
                    SizedBox(
                      width: tileW,
                      child: AppMetricTile(
                        label: context.l10n.routingTotalProductionCostLabel,
                        value: costSummary.totalNetCostPaise,
                        isCurrencyPaise: true,
                        icon: AppIcons.rupee,
                        tone: AppStatusTone.info,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. Stage-wise breakdown of the work stages used on this colour
          AppMotionEntrance(
            index: 2,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeading(
                    context.l10n.lotStageBreakdown,
                    level: AppHeadingLevel.h3,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (stageSummaries.isEmpty)
                    AppText(
                      context.l10n.workerNoAssignedProcesses,
                      variant: AppTextVariant.bodySmall,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  for (var i = 0; i < stageSummaries.length; i++) ...[
                    AppActionRow(
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            stageSummaries[i].processName,
                            fontWeight: FontWeight.w700,
                          ),
                          AppText(
                            stageSummaries[i].assigned == 0
                                ? context.l10n.lotStatusNotStarted
                                : context.l10n.lotStageSummaryLine(
                                    stageSummaries[i].assigned,
                                    stageSummaries[i].completed,
                                    stageSummaries[i].pending,
                                  ),
                            variant: AppTextVariant.bodySmall,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      actions: [
                        AppStatusBadge(
                          label: stageSummaries[i].statusLabel,
                          tone: stageSummaries[i].tone,
                        ),
                      ],
                    ),
                    if (i < stageSummaries.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: AppDivider(),
                      ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 4. Worker-wise Quantity Distribution & Pricing
          AppMotionEntrance(
            index: 3,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeading(
                    context.l10n.lotWorkerDistribution,
                    level: AppHeadingLevel.h3,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (activeOps.isEmpty)
                    AppText(
                      context.l10n.lotNoWorkersAssignedFor(sku.colourName),
                      variant: AppTextVariant.bodySmall,
                      color: colorScheme.onSurfaceVariant,
                    )
                  else
                    for (var i = 0; i < activeOps.length; i++) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  '${activeOps[i].workerName ?? 'Unassigned'} • ${activeOps[i].processName}',
                                  fontWeight: FontWeight.w700,
                                ),
                                const SizedBox(height: 2),
                                AppText(
                                  context.l10n.lotAssignedPendingLine(
                                    activeOps[i].dispatchedQuantity > 0
                                        ? activeOps[i].dispatchedQuantity
                                        : activeOps[i].plannedQuantity,
                                    activeOps[i].pendingQuantity,
                                  ),
                                  variant: AppTextVariant.bodySmall,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(height: 2),
                                AppText(
                                  context.l10n.lotRatePayableLine(
                                    MoneyFormatter.formatPaise(
                                      activeOps[i].agreedRatePaise,
                                    ),
                                    ProcessPricingCalculator.unitLabel(
                                      activeOps[i].pricingUnit,
                                    ),
                                    MoneyFormatter.formatPaise(
                                      activeOps[i].payableAmountPaise,
                                    ),
                                  ),
                                  variant: AppTextVariant.bodySmall,
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AppStatusBadge(
                                label: activeOps[i].status.label,
                                tone: _statusTone(activeOps[i].status),
                              ),
                              const SizedBox(height: 4),
                              AppStatusBadge(
                                label: activeOps[i].paymentStatus.label,
                                tone: _paymentTone(activeOps[i].paymentStatus),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (i < activeOps.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: AppDivider(),
                        ),
                    ],
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 5. Production Cost Summary for this Colour
          AppMotionEntrance(
            index: 4,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeading(
                    context.l10n.lotColourCostSummary,
                    level: AppHeadingLevel.h3,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _CostLine(
                    label: context.l10n.lotBaseStageCost,
                    value: MoneyFormatter.formatPaise(
                      costSummary.totalBasePaise,
                    ),
                  ),
                  _CostLine(
                    label: context.l10n.lotAdditionalCharges,
                    value: MoneyFormatter.formatPaise(
                      costSummary.totalAdditionalChargesPaise,
                    ),
                  ),
                  if (costSummary.totalDeductionsPaise > 0)
                    _CostLine(
                      label: context.l10n.lotDeductions,
                      value:
                          '- ${MoneyFormatter.formatPaise(costSummary.totalDeductionsPaise)}',
                    ),
                  const AppDivider(),
                  _CostLine(
                    label: context.l10n.routingTotalProductionCostLabel,
                    value: MoneyFormatter.formatPaise(
                      costSummary.totalNetCostPaise,
                    ),
                    bold: true,
                  ),
                  _CostLine(
                    label: context.l10n.lotPaidToWorkers,
                    value: MoneyFormatter.formatPaise(
                      costSummary.totalPaidPaise,
                    ),
                  ),
                  _CostLine(
                    label: context.l10n.accountingOutstandingPayableLabel,
                    value: MoneyFormatter.formatPaise(
                      costSummary.totalOutstandingPaise,
                    ),
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 6. Full Colour Movement History
          AppHeading(
            context.l10n.lotMovementHistoryCount(handovers.length),
            level: AppHeadingLevel.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (handovers.isEmpty)
            AppCard(
              child: AppText(
                context.l10n.lotMovementHistoryEmpty(sku.colourName),
                variant: AppTextVariant.bodySmall,
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            AppCard(
              child: Column(
                children: [
                  for (var i = 0; i < handovers.length; i++) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppStatusBadge(
                              label: handovers[i].handoverType.label,
                              tone: _handoverTone(handovers[i].handoverType),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: AppText(
                                handovers[i].transferReference,
                                variant: AppTextVariant.bodySmall,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            AppText(
                              IstDateTimeHelper.formatIstDateTime(
                                handovers[i].transactionAt,
                                locale: localeCode,
                              ),
                              variant: AppTextVariant.bodySmall,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: AppText(
                                '${handovers[i].fromLocationLabel} → ${handovers[i].toLocationLabel} • ${handovers[i].processName}',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (handovers[i].quantityDispatched > 0)
                              AppText(
                                context.l10n.lotPiecesValue(
                                  handovers[i].quantityDispatched,
                                ),
                                fontWeight: FontWeight.w700,
                                color: colorScheme.primary,
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        AppText(
                          context.l10n.lotReceivedOfLine(
                            handovers[i].quantityReceived,
                            handovers[i].quantityDispatched,
                            handovers[i].status.label,
                          ),
                          variant: AppTextVariant.bodySmall,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    if (i < handovers.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: AppDivider(),
                      ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  List<_StageBreakdown> _buildProcessStageSummaries(
    BuildContext context,
    List<JobProcessEntity> activeOps,
  ) {
    final byKey = <String, _StageAccum>{};

    for (final op in activeOps) {
      final key = op.processName.trim().toLowerCase();
      final acc = byKey.putIfAbsent(key, () => _StageAccum(op.processName));
      final qty = op.dispatchedQuantity > 0
          ? op.dispatchedQuantity
          : op.plannedQuantity;
      acc.assigned += qty;
      acc.completed += op.returnedToFactoryQuantity + op.transferredOutQuantity;
      acc.pending += op.pendingQuantity;
    }

    return byKey.values.map((a) {
      if (a.assigned == 0) {
        return _StageBreakdown(
          processName: a.name,
          assigned: 0,
          completed: 0,
          pending: 0,
          statusLabel: context.l10n.lotStatusNotStarted,
          tone: AppStatusTone.neutral,
        );
      }
      if (a.pending == 0 && a.completed > 0) {
        return _StageBreakdown(
          processName: a.name,
          assigned: a.assigned,
          completed: a.completed,
          pending: 0,
          statusLabel: context.l10n.lotsStatusCompleted,
          tone: AppStatusTone.good,
        );
      }
      if (a.completed > 0 && a.pending > 0) {
        return _StageBreakdown(
          processName: a.name,
          assigned: a.assigned,
          completed: a.completed,
          pending: a.pending,
          statusLabel: context.l10n.lotStatusInProgress,
          tone: AppStatusTone.info,
        );
      }
      return _StageBreakdown(
        processName: a.name,
        assigned: a.assigned,
        completed: a.completed,
        pending: a.pending,
        statusLabel: context.l10n.lotStatusPendingCount(a.pending),
        tone: AppStatusTone.pending,
      );
    }).toList();
  }
}

final class _StageAccum {
  _StageAccum(this.name);
  final String name;
  int assigned = 0;
  int completed = 0;
  int pending = 0;
}

final class _StageBreakdown {
  const _StageBreakdown({
    required this.processName,
    required this.assigned,
    required this.completed,
    required this.pending,
    required this.statusLabel,
    required this.tone,
  });

  final String processName;
  final int assigned;
  final int completed;
  final int pending;
  final String statusLabel;
  final AppStatusTone tone;
}

final class _CostLine extends StatelessWidget {
  const _CostLine({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            label,
            variant: bold
                ? AppTextVariant.bodyMedium
                : AppTextVariant.bodySmall,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
          AppText(
            value,
            variant: AppTextVariant.numeric,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
          ),
        ],
      ),
    );
  }
}
