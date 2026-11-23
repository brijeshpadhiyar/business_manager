import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/inventory/domain/calculators/inventory_overview_calculator.dart';
import 'package:business_manager/features/inventory/presentation/bloc/inventory_overview_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

final class InventoryOverviewPage extends StatelessWidget {
  const InventoryOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InventoryOverviewCubit>(
      create: (_) => getIt<InventoryOverviewCubit>()..loadOverview(),
      child: const _InventoryOverviewView(),
    );
  }
}

final class _InventoryOverviewView extends StatefulWidget {
  const _InventoryOverviewView();

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
        if (state.status == InventoryOverviewStatus.initial ||
            state.status == InventoryOverviewStatus.loading) {
          return const AppLoader();
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
                  subtitle: l10n.inventoryNote,
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
                    _KpiCard(
                      label: l10n.inventoryTotalLots,
                      value: '${overview.totalActiveLots}',
                    ),
                    _KpiCard(
                      label: l10n.inventoryTotalDesigns,
                      value: '${overview.totalDesigns}',
                    ),
                    _KpiCard(
                      label: l10n.inventoryTotalCombinations,
                      value: '${overview.totalDesignColourCombinations}',
                    ),
                    _KpiCard(
                      label: l10n.inventoryTotalInitialQty,
                      value:
                          '${overview.totalInitialQuantity} ${l10n.piecesUnit}',
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                SegmentedButton<int>(
                  segments: [
                    ButtonSegment(value: 0, label: Text(l10n.inventoryTabLots)),
                    ButtonSegment(
                      value: 1,
                      label: Text(l10n.inventoryTabDesigns),
                    ),
                    ButtonSegment(
                      value: 2,
                      label: Text(l10n.inventoryTabColours),
                    ),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(item.lotNumber, fontWeight: FontWeight.w700),
              AppText(
                '${item.designCount} ${l10n.inventoryTotalDesigns} • ${item.colourCount} ${l10n.colourNameLabel}',
                variant: AppTextVariant.bodySmall,
              ),
            ],
          ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(item.designName, fontWeight: FontWeight.w700),
              AppText(item.lotNumber, variant: AppTextVariant.bodySmall),
            ],
          ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                '${item.designName} • ${item.colourName}',
                fontWeight: FontWeight.w700,
              ),
              AppText(item.lotNumber, variant: AppTextVariant.bodySmall),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(
                '${item.initialQuantity} ${l10n.piecesUnit}',
                variant: AppTextVariant.numeric,
              ),
              AppText(
                MoneyFormatter.formatPaise(item.unitPricePaise),
                variant: AppTextVariant.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

final class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 164,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText(label, variant: AppTextVariant.bodySmall),
            const SizedBox(height: AppSpacing.xs),
            AppText(
              value,
              variant: AppTextVariant.numeric,
              fontWeight: FontWeight.w700,
            ),
          ],
        ),
      ),
    );
  }
}
