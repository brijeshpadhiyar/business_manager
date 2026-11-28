import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/process_routing/domain/calculators/process_pricing_calculator.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/process_routing/presentation/bloc/job_routing_cubit.dart';
import 'package:business_manager/features/process_routing/presentation/routing_error_localizer.dart';
import 'package:business_manager/features/process_routing/presentation/widgets/routing_action_sheets.dart';
import 'package:business_manager/features/process_routing/presentation/widgets/routing_handover_row.dart';
import 'package:business_manager/features/process_routing/presentation/widgets/routing_process_card.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// StitchFlow V1.3 Multi-Process Routing, Variant Allocation, Dynamic Pricing,
/// Additional Charges & Cost Summary Hub.
final class JobProcessRoutingPage extends StatelessWidget {
  const JobProcessRoutingPage({
    super.key,
    required this.lotId,
    this.initialDesignColourId,
  });

  final String lotId;
  final String? initialDesignColourId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JobRoutingCubit>(
      create: (_) => getIt<JobRoutingCubit>()..load(lotId),
      child: _JobProcessRoutingView(
        lotId: lotId,
        initialDesignColourId: initialDesignColourId,
      ),
    );
  }
}

final class _JobProcessRoutingView extends StatefulWidget {
  const _JobProcessRoutingView({
    required this.lotId,
    this.initialDesignColourId,
  });

  final String lotId;
  final String? initialDesignColourId;

  @override
  State<_JobProcessRoutingView> createState() => _JobProcessRoutingViewState();
}

final class _JobProcessRoutingViewState extends State<_JobProcessRoutingView> {
  static const _pricingCalc = ProcessPricingCalculator();

  String? _selectedDesignColourId;

  String get lotId => widget.lotId;

  @override
  void initState() {
    super.initState();
    _selectedDesignColourId = widget.initialDesignColourId;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<JobRoutingCubit, JobRoutingState>(
      builder: (context, state) {
        final overview = state.overview;
        return AppScaffold(
          title: overview != null
              ? '${overview.lot.lotNumber} • ${l10n.routingTitle}'
              : l10n.routingTitle,
          actions: [
            AppIconButton(
              icon: AppIcons.refresh,
              tooltip: l10n.routingRefreshTooltip,
              onPressed: () => context.read<JobRoutingCubit>().load(lotId),
            ),
          ],
          padding: EdgeInsets.zero,
          body: AppStateTransition(
            stateKey: ValueKey<JobRoutingStatus>(state.status),
            child: switch (state.status) {
              JobRoutingStatus.initial ||
              JobRoutingStatus.loading => const AppSkeletonList(itemCount: 4),
              JobRoutingStatus.error => AppErrorView(
                title: l10n.routingLoadErrorTitle,
                message: state.errorMessage != null
                    ? RoutingErrorLocalizer.localize(l10n, state.errorMessage!)
                    : null,
                retryLabel: l10n.actionRetry,
                onRetry: () => context.read<JobRoutingCubit>().load(lotId),
              ),
              JobRoutingStatus.loaded => _buildLoaded(
                context,
                overview!,
                localeCode,
                isDark,
              ),
            },
          ),
        );
      },
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    JobRoutingOverview overview,
    String localeCode,
    bool isDark,
  ) {
    final l10n = context.l10n;
    final cubit = context.read<JobRoutingCubit>();
    final activeFilterId =
        (_selectedDesignColourId != null &&
            overview.skuBalances.any(
              (b) => b.designColourId == _selectedDesignColourId,
            ))
        ? _selectedDesignColourId
        : null;

    final filteredSkus = activeFilterId == null
        ? overview.skuBalances
        : overview.skuBalances
              .where((b) => b.designColourId == activeFilterId)
              .toList();
    final filteredProcesses = activeFilterId == null
        ? overview.jobProcesses
        : overview.jobProcesses
              .where((p) => p.designColourId == activeFilterId)
              .toList();
    final filteredHandovers = activeFilterId == null
        ? overview.handovers
        : overview.handovers
              .where((h) => h.designColourId == activeFilterId)
              .toList();
    final filteredCharges = activeFilterId == null
        ? overview.additionalCharges
        : overview.additionalCharges
              .where((c) => c.designColourId == activeFilterId)
              .toList();

    final costs = activeFilterId == null
        ? overview.costSummary
        : _pricingCalc.calculateJobCostSummary(
            jobProcesses: filteredProcesses,
            charges: filteredCharges,
          );

    final totalInitial = filteredSkus.fold<int>(
      0,
      (s, b) => s + b.initialQuantity,
    );
    final totalFactory = filteredSkus.fold<int>(
      0,
      (s, b) => s + b.physicalAvailableInHouse,
    );
    final totalWithWorkers = filteredSkus.fold<int>(
      0,
      (s, b) => s + b.totalPendingWithWorkers,
    );

    final hexByColourId = <String, String?>{
      for (final b in overview.skuBalances) b.designColourId: b.colourHex,
    };

    return RefreshIndicator(
      onRefresh: () => cubit.load(lotId),
      child: ListView(
        padding: AppSpacing.screenAll,
        children: [
          AppMotionEntrance(
            index: 0,
            child: AppCard(
              gradient: isDark
                  ? AppColors.heroGradientDark
                  : AppColors.heroGradientLight,
              borderColor: AppColors.onHero.withValues(alpha: 0.18),
              borderRadius: AppRadius.xlBorder,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppActionRow(
                    content: Text(
                      '#${overview.lot.lotNumber}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.onHero,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    actions: [
                      AppStatusBadge(
                        label: '$totalInitial ${l10n.piecesUnit}',
                        tone: AppStatusTone.info,
                      ),
                    ],
                  ),
                  if (overview.lot.title != null &&
                      overview.lot.title!.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      overview.lot.title!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onHeroMuted,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      AppButton(
                        label: l10n.routingAddProcessAction,
                        icon: AppIcons.assignWorker,
                        onPressed: () =>
                            RoutingActionSheets.showAddOrReassignSheet(
                              context,
                              overview,
                              initialSelectedDesignColourId:
                                  _selectedDesignColourId,
                              isReassign: false,
                            ),
                      ),
                      AppButton(
                        label: l10n.routingReassignFromFactoryAction,
                        icon: AppIcons.assignWorker,
                        variant: AppButtonVariant.secondary,
                        onPressed: overview.totalFactoryAvailable > 0
                            ? () => RoutingActionSheets.showAddOrReassignSheet(
                                context,
                                overview,
                                initialSelectedDesignColourId:
                                    _selectedDesignColourId,
                                isReassign: true,
                              )
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          if (overview.skuBalances.isNotEmpty) ...[
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: AppChip(
                      label:
                          '${l10n.filterAll} (${overview.skuBalances.length})',
                      selected: activeFilterId == null,
                      onSelected: (_) =>
                          setState(() => _selectedDesignColourId = null),
                    ),
                  ),
                  for (final sku in overview.skuBalances)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: AppChip(
                        avatar: AppColourSwatch(
                          color: AppColourUtils.resolveColor(
                            sku.colourHex,
                            fallbackName: sku.colourName,
                          ),
                          size: 16,
                          borderRadius: AppRadius.smBorder,
                        ),
                        label:
                            '${formatVariantLabel(sku.designName, sku.colourName)} (${sku.totalPendingWithWorkers})',
                        selected: activeFilterId == sku.designColourId,
                        onSelected: (_) => setState(
                          () => _selectedDesignColourId = sku.designColourId,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          AppMotionEntrance(
            index: 1,
            child: AppResponsiveGrid(
              compactColumns: 2,
              mediumColumns: 4,
              expandedColumns: 4,
              compactModeExtraCompact: 1,
              compactModeExtraMedium: 0,
              compactModeExtraExpanded: 0,
              children: [
                AppMetricTile(
                  label: l10n.routingFactoryReadyLabel,
                  value: totalFactory,
                  suffix: l10n.piecesUnit,
                  icon: AppIcons.factory,
                  tone: AppStatusTone.good,
                ),
                AppMetricTile(
                  label: l10n.routingWithWorkersLabel,
                  value: totalWithWorkers,
                  suffix: l10n.piecesUnit,
                  icon: AppIcons.pending,
                  tone: totalWithWorkers > 0
                      ? AppStatusTone.pending
                      : AppStatusTone.neutral,
                ),
                AppMetricTile(
                  label: l10n.routingTotalProductionCostLabel,
                  value: costs.totalNetCostPaise,
                  isCurrencyPaise: true,
                  icon: AppIcons.rupee,
                  tone: AppStatusTone.info,
                ),
                AppMetricTile(
                  label: l10n.routingOutstandingPayableLabel,
                  value: costs.totalOutstandingPaise,
                  isCurrencyPaise: true,
                  icon: AppIcons.accounting,
                  tone: costs.totalOutstandingPaise > 0
                      ? AppStatusTone.pending
                      : AppStatusTone.good,
                ),
              ],
            ),
          ),
          const AppGap.md(),

          if (costs.workerPayables.isNotEmpty) ...[
            RoutingWorkerPayablesCard(workerPayables: costs.workerPayables),
            const SizedBox(height: AppSpacing.md),
          ],

          if (activeFilterId == null &&
              overview.currentLocations.isNotEmpty) ...[
            RoutingCurrentLocationsCard(locations: overview.currentLocations),
            const SizedBox(height: AppSpacing.lg),
          ],

          AppHeading(
            '${l10n.routingOperationLabel} (${filteredProcesses.length})',
            level: AppHeadingLevel.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (filteredProcesses.isEmpty)
            AppCard(
              child: AppEmptyState(
                icon: AppIcons.routeTransfer,
                title: activeFilterId == null
                    ? l10n.routingNoOperationsTitle
                    : l10n.routingNoOperationsForColourTitle,
                subtitle: l10n.routingNoOperationsSubtitle,
                actionLabel: l10n.routingAddProcessAction,
                onAction: () => RoutingActionSheets.showAddOrReassignSheet(
                  context,
                  overview,
                  initialSelectedDesignColourId: _selectedDesignColourId,
                  isReassign: false,
                ),
              ),
            )
          else
            for (final jp in filteredProcesses) ...[
              RoutingProcessCard(
                key: ValueKey<String>(jp.id),
                overview: overview,
                jobProcess: jp,
                colourHex: hexByColourId[jp.designColourId],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

          const SizedBox(height: AppSpacing.lg),

          AppHeading(
            '${l10n.navProcessHistory} (${filteredHandovers.length})',
            level: AppHeadingLevel.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (filteredHandovers.isEmpty)
            AppCard(
              child: AppText(
                l10n.routingNoHandoversSubtitle,
                variant: AppTextVariant.bodySmall,
              ),
            )
          else
            AppCard(
              child: Column(
                children: [
                  for (var i = 0; i < filteredHandovers.length; i++) ...[
                    RoutingHandoverRow(
                      handover: filteredHandovers[i],
                      localeCode: localeCode,
                      tone: routingHandoverTone(
                        filteredHandovers[i].handoverType,
                      ),
                      colourHex:
                          hexByColourId[filteredHandovers[i].designColourId],
                      onConfirmReceipt: () =>
                          RoutingActionSheets.showConfirmReceiptSheet(
                            context,
                            filteredHandovers[i],
                          ),
                    ),
                    if (i < filteredHandovers.length - 1)
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
}
