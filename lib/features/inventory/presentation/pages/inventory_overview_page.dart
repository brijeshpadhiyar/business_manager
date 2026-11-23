import 'package:business_manager/core/design_system/app_sizing.dart';
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
    final content = BlocBuilder<InventoryOverviewCubit, InventoryOverviewState>(
      builder: (context, state) {
        if (state.status == InventoryOverviewStatus.initial ||
            state.status == InventoryOverviewStatus.loading) {
          return const AppSkeletonList(itemCount: 4);
        }
        if (state.status == InventoryOverviewStatus.error) {
          return AppErrorView(
            title: l10n.errorUnexpected,
            message: state.errorMessage,
            retryLabel: l10n.actionRetry,
            onRetry: () =>
                context.read<InventoryOverviewCubit>().loadOverview(),
          );
        }

        final overview = state.overview!;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppSizing.maxContentWidth,
            ),
            child: ListView(
              padding: AppSpacing.screenAll,
              children: [
                AppHeading(
                  l10n.inventoryHeading,
                  level: AppHeadingLevel.h2,
                  subtitle: l10n.inventoryUpdatedNote,
                  trailing: AppIconButton(
                    icon: Icons.refresh,
                    tooltip: l10n.actionRetry,
                    onPressed: () =>
                        context.read<InventoryOverviewCubit>().loadOverview(),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppButton(
                      label: l10n.navStockMovements,
                      icon: Icons.swap_horiz_rounded,
                      onPressed: () => context.push(RoutePaths.stockMovements),
                    ),
                    AppButton(
                      label: l10n.stockIssueAction,
                      icon: Icons.outbox_rounded,
                      variant: AppButtonVariant.secondary,
                      onPressed: () => context.push(RoutePaths.stockIssue()),
                    ),
                    AppButton(
                      label: l10n.navReports,
                      icon: Icons.analytics_outlined,
                      variant: AppButtonVariant.outlined,
                      onPressed: () => context.push(RoutePaths.reports),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 680;
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
                            label: l10n.inventoryTotalLots,
                            value: overview.totalActiveLots,
                            icon: Icons.inventory_2_outlined,
                          ),
                        ),
                        SizedBox(
                          width: tileW,
                          child: AppMetricTile(
                            label: l10n.inventoryTotalDesigns,
                            value: overview.totalDesigns,
                            icon: Icons.style_outlined,
                            tone: AppStatusTone.info,
                          ),
                        ),
                        SizedBox(
                          width: tileW,
                          child: AppMetricTile(
                            label: l10n.inventoryTotalCombinations,
                            value: overview.totalDesignColourCombinations,
                            icon: Icons.palette_outlined,
                          ),
                        ),
                        SizedBox(
                          width: tileW,
                          child: AppMetricTile(
                            label: l10n.inventoryTotalInitialQty,
                            value: overview.totalInitialQuantity,
                            suffix: l10n.piecesUnit,
                            icon: Icons.check_circle_outline_rounded,
                            tone: AppStatusTone.good,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.inventoryTabLots),
                      selected: _tab == 0,
                      onSelected: (_) => setState(() => _tab = 0),
                    ),
                    ChoiceChip(
                      label: Text(l10n.inventoryTabDesigns),
                      selected: _tab == 1,
                      onSelected: (_) => setState(() => _tab = 1),
                    ),
                    ChoiceChip(
                      label: Text(l10n.inventoryTabColours),
                      selected: _tab == 2,
                      onSelected: (_) => setState(() => _tab = 2),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (overview.totalActiveLots == 0)
                  AppEmptyState(
                    icon: Icons.inventory_outlined,
                    title: l10n.inventoryEmptyTitle,
                    subtitle: l10n.inventoryEmptySubtitle,
                  )
                else
                  switch (_tab) {
                    0 => _buildLotTable(context, overview.lotSummaries),
                    1 => _buildDesignTable(context, overview.designSummaries),
                    _ => _buildColourTable(context, overview.colourSummaries),
                  },
              ],
            ),
          ),
        );
      },
    );

    if (widget.showAppBar) {
      return AppScaffold(
        title: l10n.navInventory,
        padding: EdgeInsets.zero,
        constrainMaxWidth: false,
        body: content,
      );
    }
    return content;
  }

  Widget _buildLotTable(BuildContext context, List<LotQuantitySummary> items) {
    final l10n = context.l10n;
    return AppDataTable<LotQuantitySummary>(
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

  Widget _buildDesignTable(
    BuildContext context,
    List<DesignQuantitySummary> items,
  ) {
    final l10n = context.l10n;
    return AppDataTable<DesignQuantitySummary>(
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

  Widget _buildColourTable(
    BuildContext context,
    List<ColourQuantitySummary> items,
  ) {
    final l10n = context.l10n;
    return AppDataTable<ColourQuantitySummary>(
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
