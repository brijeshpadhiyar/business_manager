import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/inventory/domain/calculators/inventory_overview_calculator.dart';
import 'package:business_manager/features/inventory/presentation/bloc/inventory_overview_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

final class InventoryOverviewPage extends StatelessWidget {
  const InventoryOverviewPage({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InventoryOverviewCubit>(
      create: (_) => getIt<InventoryOverviewCubit>()..loadOverview(),
      child: _InventoryOverviewView(showAppBar: showAppBar),
    );
  }
}

final class _InventoryOverviewView extends StatefulWidget {
  const _InventoryOverviewView({required this.showAppBar});

  final bool showAppBar;

  @override
  State<_InventoryOverviewView> createState() => _InventoryOverviewViewState();
}

final class _InventoryOverviewViewState extends State<_InventoryOverviewView> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<InventoryOverviewCubit, InventoryOverviewState>(
      builder: (context, state) {
        final overview = state.overview;

        final List<Widget> slivers;
        if (state.status == InventoryOverviewStatus.initial ||
            state.status == InventoryOverviewStatus.loading) {
          slivers = const [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: AppLoader(),
              ),
            ),
          ];
        } else if (state.status == InventoryOverviewStatus.error) {
          slivers = [
            SliverToBoxAdapter(
              child: AppErrorView(
                title: l10n.errorUnexpected,
                message: state.errorMessage,
                retryLabel: l10n.actionRetry,
                onRetry: () =>
                    context.read<InventoryOverviewCubit>().loadOverview(),
              ),
            ),
          ];
        } else {
          slivers = [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppButton(
                      label: l10n.navStockMovements,
                      icon: AppIcons.stockMovements,
                      onPressed: () => context.push(RoutePaths.stockMovements),
                    ),
                    AppButton(
                      label: l10n.stockIssueAction,
                      icon: AppIcons.stockIssue,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => context.push(RoutePaths.stockIssue()),
                    ),
                    AppButton(
                      label: l10n.navReports,
                      icon: AppIcons.reports,
                      variant: AppButtonVariant.outlined,
                      onPressed: () => context.push(RoutePaths.reports),
                    ),
                  ],
                ),
              ),
            ),
            if (overview!.totalActiveLots == 0)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                sliver: SliverToBoxAdapter(
                  child: AppEmptyState(
                    icon: AppIcons.inventory,
                    title: l10n.inventoryEmptyTitle,
                    subtitle: l10n.inventoryEmptySubtitle,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                sliver: switch (_tab) {
                  0 => _buildLotSliver(context, overview.lotSummaries),
                  1 => _buildDesignSliver(context, overview.designSummaries),
                  _ => _buildColourSliver(context, overview.colourSummaries),
                },
              ),
          ];
        }

        return AppScaffold(
          scrollMode: AppScrollMode.collapsible,
          contentWidth: AppContentWidth.wide,
          embedded: !widget.showAppBar,
          onRefresh: () =>
              context.read<InventoryOverviewCubit>().loadOverview(),
          header: AppCollapsibleHeader(
            title: l10n.inventoryHeading,
            subtitle: l10n.inventoryUpdatedNote,
            automaticallyImplyLeading: widget.showAppBar,
            expandedHeight: 184,
            actions: [
              AppIconButton(
                icon: AppIcons.refresh,
                tooltip: l10n.actionRetry,
                onPressed: () =>
                    context.read<InventoryOverviewCubit>().loadOverview(),
              ),
            ],
            summary: overview == null
                ? null
                : AppSummaryStrip(
                    metrics: [
                      AppSummaryMetric(
                        label: l10n.inventoryTotalLots,
                        value: '${overview.totalActiveLots}',
                        tone: AppStatusTone.info,
                      ),
                      AppSummaryMetric(
                        label: l10n.inventoryTotalDesigns,
                        value: '${overview.totalDesigns}',
                        tone: AppStatusTone.neutral,
                      ),
                      AppSummaryMetric(
                        label: l10n.inventoryTotalCombinations,
                        value: '${overview.totalDesignColourCombinations}',
                        tone: AppStatusTone.neutral,
                      ),
                      AppSummaryMetric(
                        label: l10n.inventoryTotalInitialQty,
                        value: '${overview.totalInitialQuantity}',
                        tone: AppStatusTone.good,
                      ),
                    ],
                  ),
          ),
          pinnedHeaderHeight: 58,
          pinnedHeader: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(l10n.inventoryTabLots),
                  selected: _tab == 0,
                  onSelected: (_) => setState(() => _tab = 0),
                ),
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(
                  label: Text(l10n.inventoryTabDesigns),
                  selected: _tab == 1,
                  onSelected: (_) => setState(() => _tab = 1),
                ),
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(
                  label: Text(l10n.inventoryTabColours),
                  selected: _tab == 2,
                  onSelected: (_) => setState(() => _tab = 2),
                ),
              ],
            ),
          ),
          slivers: slivers,
        );
      },
    );
  }

  Widget _buildLotSliver(BuildContext context, List<LotQuantitySummary> items) {
    final l10n = context.l10n;
    return AppDataTable.buildSliver<LotQuantitySummary>(
      context,
      enablePagination: true,
      itemKeyBuilder: (item) => ValueKey<String>(item.lotId),
      columns: [
        AppDataColumn(label: l10n.lotNumberLabel),
        AppDataColumn(label: l10n.inventoryTotalDesigns, numeric: true),
        AppDataColumn(label: l10n.colourInitialQtyLabel, numeric: true),
      ],
      items: items,
      cellsBuilder: (item) => [
        AppText(item.lotNumber, fontWeight: FontWeight.w600),
        AppText('${item.designCount}', variant: AppTextVariant.numeric),
        AppText(
          '${item.totalInitialQuantity} ${l10n.piecesUnit}',
          variant: AppTextVariant.numeric,
        ),
      ],
      mobileCardBuilder: (_, item) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(item.lotNumber, fontWeight: FontWeight.w700),
                AppText(
                  '${item.designCount} ${l10n.inventoryTotalDesigns} • ${item.colourCount} ${l10n.colourNameLabel}',
                  variant: AppTextVariant.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppText(
            '${item.totalInitialQuantity} ${l10n.piecesUnit}',
            variant: AppTextVariant.numeric,
          ),
        ],
      ),
    );
  }

  Widget _buildDesignSliver(
    BuildContext context,
    List<DesignQuantitySummary> items,
  ) {
    final l10n = context.l10n;
    return AppDataTable.buildSliver<DesignQuantitySummary>(
      context,
      enablePagination: true,
      itemKeyBuilder: (item) => ValueKey<String>(item.designId),
      columns: [
        AppDataColumn(label: l10n.lotNumberLabel),
        AppDataColumn(label: l10n.designNameLabel),
        AppDataColumn(label: l10n.colourInitialQtyLabel, numeric: true),
      ],
      items: items,
      cellsBuilder: (item) => [
        AppText(item.lotNumber),
        AppText(item.designName, fontWeight: FontWeight.w600),
        AppText(
          '${item.totalInitialQuantity} ${l10n.piecesUnit}',
          variant: AppTextVariant.numeric,
        ),
      ],
      mobileCardBuilder: (_, item) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(item.designName, fontWeight: FontWeight.w700),
                AppText(item.lotNumber, variant: AppTextVariant.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppText(
            '${item.totalInitialQuantity} ${l10n.piecesUnit}',
            variant: AppTextVariant.numeric,
          ),
        ],
      ),
    );
  }

  Widget _buildColourSliver(
    BuildContext context,
    List<ColourQuantitySummary> items,
  ) {
    final l10n = context.l10n;
    return AppDataTable.buildSliver<ColourQuantitySummary>(
      context,
      enablePagination: true,
      itemKeyBuilder: (item) => ValueKey<String>(item.designColourId),
      columns: [
        AppDataColumn(label: l10n.lotNumberLabel),
        AppDataColumn(label: l10n.designNameLabel),
        AppDataColumn(label: l10n.colourNameLabel),
        AppDataColumn(label: l10n.colourInitialQtyLabel, numeric: true),
        AppDataColumn(label: l10n.colourUnitPriceLabel, numeric: true),
      ],
      items: items,
      cellsBuilder: (item) => [
        AppText(item.lotNumber),
        AppText(item.designName),
        AppText(item.colourName, fontWeight: FontWeight.w600),
        AppText(
          '${item.initialQuantity} ${l10n.piecesUnit}',
          variant: AppTextVariant.numeric,
        ),
        AppText(
          MoneyFormatter.formatPaise(item.unitPricePaise),
          variant: AppTextVariant.numeric,
        ),
      ],
      mobileCardBuilder: (_, item) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  '${item.designName} • ${item.colourName}',
                  fontWeight: FontWeight.w700,
                ),
                AppText(item.lotNumber, variant: AppTextVariant.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(
                '${item.initialQuantity} ${l10n.piecesUnit}',
                variant: AppTextVariant.numeric,
              ),
              AppText(
                MoneyFormatter.formatPaise(item.unitPricePaise),
                variant: AppTextVariant.numeric,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
