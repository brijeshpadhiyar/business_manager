import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/lots/domain/entities/colour_master_entity.dart';
import 'package:business_manager/features/lots/domain/repositories/colour_master_repository.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/lots/presentation/bloc/designs_colours_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Unified Designs & Colours management view backed strictly by existing
/// `lot_designs`, `design_colours`, and `colour_master` tables.
final class DesignsColoursPage extends StatelessWidget {
  const DesignsColoursPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DesignsColoursCubit>(
      create: (_) => DesignsColoursCubit(
        getIt<LotRepository>(),
        getIt<ColourMasterRepository>(),
      )..load(),
      child: const _DesignsColoursView(),
    );
  }
}

final class _DesignsColoursView extends StatefulWidget {
  const _DesignsColoursView();

  @override
  State<_DesignsColoursView> createState() => _DesignsColoursViewState();
}

final class _DesignsColoursViewState extends State<_DesignsColoursView> {
  final _searchController = TextEditingController();
  int _tabIndex = 0;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatPriceRange(int minPaise, int maxPaise) {
    if (minPaise == 0 && maxPaise == 0) return '—';
    if (minPaise == maxPaise) return MoneyFormatter.formatPaise(minPaise);
    return '${MoneyFormatter.formatPaise(minPaise)} – ${MoneyFormatter.formatPaise(maxPaise)}';
  }

  Future<void> _openColourEditor(
    BuildContext context, {
    ColourMasterEntity? existing,
  }) async {
    final l10n = context.l10n;
    final nameController = TextEditingController(text: existing?.name ?? '');
    final hexController = TextEditingController(
      text: existing?.hexCode ?? '#0D9488',
    );
    final formKey = GlobalKey<FormState>();
    const presetHexes = [
      '#DC2626',
      '#EA580C',
      '#D97706',
      '#16A34A',
      '#0D9488',
      '#2563EB',
      '#4F46E5',
      '#9333EA',
      '#DB2777',
      '#172B4D',
      '#334155',
      '#F8FAFC',
    ];

    final saved = await AppDialog.showCustom<bool>(
      context,
      builder: (dialogCtx) {
        var submitting = false;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final currentHex = hexController.text.trim();
            return AppDialog(
              title: existing == null
                  ? l10n.colourAddAction
                  : l10n.colourEditAction,
              icon: Icons.palette_outlined,
              cancelLabel: l10n.actionCancel,
              confirmLabel: submitting ? l10n.backupProgressWorking : l10n.actionSave,
              onConfirm: submitting
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => submitting = true);
                      try {
                        await context.read<DesignsColoursCubit>().saveColour(
                          id: existing?.id,
                          name: nameController.text.trim(),
                          hexCode: hexController.text.trim().toUpperCase(),
                        );
                        if (dialogCtx.mounted) {
                          Navigator.of(dialogCtx).pop(true);
                        }
                      } catch (e) {
                        setDialogState(() => submitting = false);
                        if (context.mounted) {
                          AppFeedback.showError(context, e.toString());
                        }
                      }
                    },
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTextField(
                      controller: nameController,
                      label: '${l10n.colourNameLabel} *',
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l10n.validationRequired
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        AppColourSwatch(
                          color: AppColourUtils.resolveColor(currentHex),
                          size: 32,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppTextField(
                            controller: hexController,
                            label: '${l10n.colourHexLabel} *',
                            onChanged: (_) => setDialogState(() {}),
                            validator: (v) {
                              final raw = (v ?? '').trim();
                              if (!RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(raw)) {
                                return 'Use #RRGGBB format';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final hex in presetHexes)
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              hexController.text = hex;
                              setDialogState(() {});
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: AppColourSwatch(
                                color: AppColourUtils.resolveColor(hex),
                                size: 26,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppText(
                      l10n.historicalPricePreservedNote,
                      variant: AppTextVariant.bodySmall,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    hexController.dispose();
    if (saved == true && context.mounted) {
      AppFeedback.showSuccess(context, l10n.colourSavedSuccess);
    }
  }

  void _openDesignRelationshipsSheet(
    BuildContext context,
    DesignCatalogItem item,
  ) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    AppBottomSheet.show<void>(
      context,
      title: item.designName,
      builder: (sheetCtx) => ListView(
        shrinkWrap: true,
        children: [
          AppText(
            l10n.historicalPricePreservedNote,
            variant: AppTextVariant.bodySmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final ref in item.lotRefs)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AppCard.listItem(
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  context.push(RoutePaths.lotDetail(ref.lotId));
                },
                child: Row(
                  children: [
                    AppColourSwatch(
                      color: AppColourUtils.resolveColor(
                        ref.colourHex,
                        fallbackName: ref.colourName,
                      ),
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            '${ref.lotNumber} • ${ref.colourName}',
                            fontWeight: FontWeight.w700,
                          ),
                          AppText(
                            '${ref.initialQuantity} pcs • ${AppDateTimeFormatter.formatDate(ref.transactionAt, locale: localeCode)}',
                            variant: AppTextVariant.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    AppText(
                      ref.unitPricePaise > 0
                          ? MoneyFormatter.formatPaise(ref.unitPricePaise)
                          : '—',
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    return BlocBuilder<DesignsColoursCubit, DesignsColoursState>(
      builder: (context, state) {
        final List<Widget> slivers;
        if (state.status == DesignsColoursStatus.loading ||
            state.status == DesignsColoursStatus.initial) {
          slivers = const [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: AppSkeletonList(itemCount: 4),
              ),
            ),
          ];
        } else if (state.status == DesignsColoursStatus.error) {
          slivers = [
            SliverToBoxAdapter(
              child: AppErrorView(
                title: l10n.errorUnexpected,
                message: state.errorMessage,
                retryLabel: l10n.actionRetry,
                onRetry: () => context.read<DesignsColoursCubit>().load(),
              ),
            ),
          ];
        } else if (_tabIndex == 0) {
          if (state.designs.isEmpty) {
            slivers = [
              SliverToBoxAdapter(
                child: AppEmptyState(
                  icon: Icons.style_outlined,
                  title: l10n.designsEmptyTitle,
                  subtitle: l10n.designsEmptySubtitle,
                  actionLabel: l10n.lotCreateAction,
                  onAction: () => context.push(RoutePaths.lotCreate),
                ),
              ),
            ];
          } else {
            slivers = [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                sliver: AppDataTable.buildSliver<DesignCatalogItem>(
                  context,
                  enablePagination: true,
                  columns: [
                    AppDataColumn(label: l10n.designsTabLabel),
                    AppDataColumn(label: l10n.lotsHeading, numeric: true),
                    AppDataColumn(
                      label: l10n.coloursTabLabel,
                      minWidthClass: AppWindowSizeClass.medium,
                    ),
                    const AppDataColumn(label: 'Qty', numeric: true),
                    const AppDataColumn(
                      label: 'Historical Price',
                      numeric: true,
                      minWidthClass: AppWindowSizeClass.expanded,
                    ),
                    AppDataColumn(
                      label: l10n.lotDateLabel,
                      minWidthClass: AppWindowSizeClass.expanded,
                    ),
                  ],
                  items: state.designs,
                  itemKeyBuilder: (d) => ValueKey<String>('design_${d.designName}'),
                  onRowTap: (item) => _openDesignRelationshipsSheet(context, item),
                  cellsBuilder: (d) => [
                    AppText(d.designName, fontWeight: FontWeight.w700),
                    AppText('${d.lotCount}'),
                    AppText(
                      d.colourNames.take(4).join(', ') +
                          (d.colourNames.length > 4
                              ? ' +${d.colourNames.length - 4}'
                              : ''),
                    ),
                    AppText('${d.totalInitialQuantity}'),
                    AppText(
                      _formatPriceRange(
                        d.minUnitPricePaise,
                        d.maxUnitPricePaise,
                      ),
                    ),
                    AppText(
                      AppDateTimeFormatter.formatDate(
                        d.latestTransactionAt,
                        locale: localeCode,
                      ),
                    ),
                  ],
                  mobileCardBuilder: (ctx, d) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppText(
                              d.designName,
                              variant: AppTextVariant.bodyLarge,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          AppStatusBadge(
                            label: '${d.lotCount} ${l10n.lotsHeading}',
                            tone: AppStatusTone.info,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppText(
                        '${d.colourVariantCount} variants • ${d.totalInitialQuantity} pcs • ${_formatPriceRange(d.minUnitPricePaise, d.maxUnitPricePaise)}',
                        variant: AppTextVariant.bodySmall,
                      ),
                      if (d.colourNames.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xs),
                        AppText(
                          d.colourNames.take(5).join(', '),
                          variant: AppTextVariant.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ];
          }
        } else {
          if (state.colours.isEmpty) {
            slivers = [
              SliverToBoxAdapter(
                child: AppEmptyState(
                  icon: Icons.palette_outlined,
                  title: l10n.coloursEmptyTitle,
                  subtitle: l10n.coloursEmptySubtitle,
                  actionLabel: l10n.colourAddAction,
                  onAction: () => _openColourEditor(context),
                ),
              ),
            ];
          } else {
            slivers = [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                sliver: AppDataTable.buildSliver<ColourCatalogItem>(
                  context,
                  enablePagination: true,
                  columns: [
                    AppDataColumn(label: l10n.colourNameLabel),
                    const AppDataColumn(label: 'Hex'),
                    const AppDataColumn(label: 'Lot Uses', numeric: true),
                    const AppDataColumn(
                      label: 'Total Qty',
                      numeric: true,
                      minWidthClass: AppWindowSizeClass.expanded,
                    ),
                    const AppDataColumn(
                      label: 'Historical Price',
                      numeric: true,
                      minWidthClass: AppWindowSizeClass.medium,
                    ),
                    AppDataColumn(
                      label: l10n.designsTabLabel,
                      minWidthClass: AppWindowSizeClass.expanded,
                    ),
                  ],
                  items: state.colours,
                  itemKeyBuilder: (c) => ValueKey<String>('colour_${c.master.id}'),
                  onRowTap: (item) =>
                      _openColourEditor(context, existing: item.master),
                  cellsBuilder: (c) => [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppColourSwatch(
                          color: AppColourUtils.resolveColor(
                            c.master.hexCode,
                            fallbackName: c.master.name,
                          ),
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        AppText(c.master.name, fontWeight: FontWeight.w700),
                      ],
                    ),
                    AppText(c.master.hexCode),
                    AppText('${c.usageCount}'),
                    AppText('${c.totalQuantity}'),
                    AppText(
                      _formatPriceRange(
                        c.minUnitPricePaise,
                        c.maxUnitPricePaise,
                      ),
                    ),
                    AppText(
                      c.relatedDesigns.isEmpty
                          ? '—'
                          : c.relatedDesigns.take(3).join(', '),
                    ),
                  ],
                  mobileCardBuilder: (ctx, c) => Row(
                    children: [
                      AppColourSwatch(
                        color: AppColourUtils.resolveColor(
                          c.master.hexCode,
                          fallbackName: c.master.name,
                        ),
                        size: 28,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              c.master.name,
                              variant: AppTextVariant.bodyLarge,
                              fontWeight: FontWeight.w700,
                            ),
                            AppText(
                              '${c.master.hexCode} • ${c.usageCount} lot uses • ${_formatPriceRange(c.minUnitPricePaise, c.maxUnitPricePaise)}',
                              variant: AppTextVariant.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_outlined, size: 18),
                    ],
                  ),
                ),
              ),
            ];
          }
        }

        return AppScaffold(
          scrollMode: AppScrollMode.collapsible,
          contentWidth: AppContentWidth.wide,
          onRefresh: () => context.read<DesignsColoursCubit>().load(),
          header: AppCollapsibleHeader(
            title: l10n.navDesignsColours,
            subtitle: l10n.designsColoursSubtitle,
            expandedHeight: 168,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: AppButton(
                  label: l10n.colourAddAction,
                  icon: Icons.add_rounded,
                  onPressed: () => _openColourEditor(context),
                ),
              ),
            ],
            summary: AppSummaryStrip(
              metrics: [
                AppSummaryMetric(
                  label: l10n.designsTabLabel,
                  value: '${state.designs.length}',
                  tone: AppStatusTone.info,
                ),
                AppSummaryMetric(
                  label: l10n.coloursTabLabel,
                  value: '${state.colours.length}',
                  tone: AppStatusTone.good,
                ),
              ],
            ),
          ),
          pinnedHeaderHeight: 122,
          pinnedHeader: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSearchField(
                controller: _searchController,
                label: l10n.designsSearchHint,
                debounceDuration: const Duration(milliseconds: 200),
                onChanged: (q) =>
                    context.read<DesignsColoursCubit>().load(searchQuery: q),
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  FilterChip(
                    label: Text(l10n.designsTabLabel),
                    selected: _tabIndex == 0,
                    onSelected: (_) => setState(() => _tabIndex = 0),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  FilterChip(
                    label: Text(l10n.coloursTabLabel),
                    selected: _tabIndex == 1,
                    onSelected: (_) => setState(() => _tabIndex = 1),
                  ),
                ],
              ),
            ],
          ),
          slivers: slivers,
        );
      },
    );
  }
}
