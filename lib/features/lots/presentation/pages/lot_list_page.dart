import 'package:business_manager/core/utils/app_memo.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';
import 'package:business_manager/features/guidance/presentation/widgets/screen_first_visit_hint.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/presentation/bloc/lot_list_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

final class LotListPage extends StatelessWidget {
  const LotListPage({super.key, this.refreshSignal});

  final ValueListenable<int>? refreshSignal;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LotListCubit>(
      create: (_) => getIt<LotListCubit>()..loadLots(),
      child: _LotListView(refreshSignal: refreshSignal),
    );
  }
}

final class _LotListView extends StatefulWidget {
  const _LotListView({this.refreshSignal});

  final ValueListenable<int>? refreshSignal;

  @override
  State<_LotListView> createState() => _LotListViewState();
}

final class _LotListViewState extends State<_LotListView> {
  // Sorting and counting run only when the lots or sort settings change.
  final _sortMemo = AppMemo<List<LotEntity>>();
  final _countsMemo = AppMemo<(int, int)>();
  final _searchController = TextEditingController();
  int _sortColumnIndex = 2;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    widget.refreshSignal?.addListener(_onSilentRefresh);
  }

  @override
  void didUpdateWidget(covariant _LotListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      oldWidget.refreshSignal?.removeListener(_onSilentRefresh);
      widget.refreshSignal?.addListener(_onSilentRefresh);
    }
  }

  void _onSilentRefresh() {
    if (mounted) {
      context.read<LotListCubit>().loadLots();
    }
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_onSilentRefresh);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreateLotPage(BuildContext context) async {
    final created = await context.push<bool>(RoutePaths.lotCreate);
    if (created == true && context.mounted) {
      await context.read<LotListCubit>().loadLots();
    }
  }

  Future<void> _openLotDetail(BuildContext context, LotEntity lot) async {
    await context.push(RoutePaths.lotDetail(lot.id));
    if (context.mounted) {
      await context.read<LotListCubit>().loadLots();
    }
  }

  List<LotEntity> _sortedLots(List<LotEntity> input) {
    final list = List<LotEntity>.of(input);
    list.sort((a, b) {
      final cmp = switch (_sortColumnIndex) {
        0 => a.lotNumber.toLowerCase().compareTo(b.lotNumber.toLowerCase()),
        1 => (a.title ?? '').toLowerCase().compareTo(
          (b.title ?? '').toLowerCase(),
        ),
        2 => a.transactionAt.compareTo(b.transactionAt),
        3 => a.status.name.compareTo(b.status.name),
        _ => a.transactionAt.compareTo(b.transactionAt),
      };
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  AppStatusBadge _statusBadge(BuildContext context, LotStatus status) {
    final l10n = context.l10n;
    return AppStatusBadge(
      label: switch (status) {
        LotStatus.active => l10n.lotsStatusActive,
        LotStatus.completed => l10n.lotsStatusCompleted,
        LotStatus.archived => l10n.lotsStatusArchived,
      },
      tone: switch (status) {
        LotStatus.active => AppStatusTone.good,
        LotStatus.completed => AppStatusTone.info,
        LotStatus.archived => AppStatusTone.neutral,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    return BlocBuilder<LotListCubit, LotListState>(
      builder: (context, state) {
        final (activeCount, completedCount) = _countsMemo([state.lots], () {
          var active = 0;
          var completed = 0;
          for (final l in state.lots) {
            if (l.status == LotStatus.active) active++;
            if (l.status == LotStatus.completed) completed++;
          }
          return (active, completed);
        });
        final sortedLots = _sortMemo([
          state.lots,
          _sortColumnIndex,
          _sortAscending,
        ], () => _sortedLots(state.lots));

        final List<Widget> slivers;
        if (state.status == LotListStatus.loading ||
            state.status == LotListStatus.initial) {
          slivers = const [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: AppSkeletonList(itemCount: 4),
              ),
            ),
          ];
        } else if (state.status == LotListStatus.error) {
          slivers = [
            SliverToBoxAdapter(
              child: AppErrorView(
                title: l10n.errorUnexpected,
                message: state.errorMessage,
                retryLabel: l10n.actionRetry,
                onRetry: () => context.read<LotListCubit>().loadLots(),
              ),
            ),
          ];
        } else if (sortedLots.isEmpty) {
          slivers = [
            SliverToBoxAdapter(
              child: AppEmptyState(
                icon: AppIcons.lot,
                title: l10n.lotsEmptyTitle,
                subtitle: l10n.lotsEmptySubtitle,
                actionLabel: l10n.lotCreateAction,
                onAction: () => _openCreateLotPage(context),
              ),
            ),
          ];
        } else {
          final d = context.density;
          slivers = [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(d.lg, d.sm, d.lg, d.xl),
              sliver: AppDataTable.buildSliver<LotEntity>(
                context,
                enablePagination: true,
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                onSort: (col, asc) => setState(() {
                  _sortColumnIndex = col;
                  _sortAscending = asc;
                }),
                columns: [
                  AppDataColumn(label: l10n.lotNumberLabel, sortable: true),
                  AppDataColumn(
                    label: l10n.lotTitleLabel,
                    sortable: true,
                    minWidthClass: AppWindowSizeClass.medium,
                  ),
                  AppDataColumn(label: l10n.lotDateLabel, sortable: true),
                  AppDataColumn(label: l10n.lotStatusLabel, sortable: true),
                ],
                items: sortedLots,
                itemKeyBuilder: (lot) => ValueKey<String>(lot.id),
                onRowTap: (lot) => _openLotDetail(context, lot),
                cellsBuilder: (lot) => [
                  AppText(lot.lotNumber, fontWeight: FontWeight.w700),
                  AppText(lot.title ?? '—'),
                  AppText(
                    AppDateTimeFormatter.formatDate(
                      lot.transactionAt,
                      locale: localeCode,
                    ),
                  ),
                  _statusBadge(context, lot.status),
                ],
                mobileCardBuilder: (ctx, lot) => Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            lot.lotNumber,
                            variant: d.isCompact
                                ? AppTextVariant.bodyMedium
                                : AppTextVariant.bodyLarge,
                            fontWeight: FontWeight.w700,
                          ),
                          if (lot.title != null) ...[
                            const AppGap.xs(),
                            AppText(
                              lot.title!,
                              maxLines: d.isCompact ? 1 : null,
                            ),
                          ],
                          const AppGap.xs(),
                          AppText(
                            AppDateTimeFormatter.formatDate(
                              lot.transactionAt,
                              locale: localeCode,
                            ),
                            variant: AppTextVariant.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    _statusBadge(ctx, lot.status),
                    const AppGap.hXs(),
                    Icon(AppIcons.chevronRight, size: d.iconMd),
                  ],
                ),
              ),
            ),
          ];
        }

        return AppScaffold(
          // Main action: floating button on phones, toolbar button on wider screens.
          primaryAction: AppPrimaryAction(
            icon: AppIcons.add,
            label: l10n.lotCreateAction,
            onPressed: () => _openCreateLotPage(context),
            guideTargetId: GuideTargetId.lotNewAction,
          ),
          scrollMode: AppScrollMode.collapsible,
          contentWidth: AppContentWidth.wide,
          embedded: true,
          onRefresh: () => context.read<LotListCubit>().loadLots(),
          header: AppCollapsibleHeader(
            title: l10n.lotsHeading,
            automaticallyImplyLeading: false,
            expandedHeight: 164,
            actions: [
              AppIconButton(
                icon: AppIcons.designs,
                tooltip: l10n.navDesignsColours,
                onPressed: () => context.push(RoutePaths.designsColours),
              ),
            ],
            summary: AppSummaryStrip(
              metrics: [
                AppSummaryMetric(
                  label: l10n.lotsFilterAll,
                  value: '${state.lots.length}',
                  tone: AppStatusTone.info,
                ),
                AppSummaryMetric(
                  label: l10n.lotsStatusActive,
                  value: '$activeCount',
                  tone: AppStatusTone.good,
                ),
                AppSummaryMetric(
                  label: l10n.lotsStatusCompleted,
                  value: '$completedCount',
                  tone: AppStatusTone.neutral,
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
                label: l10n.lotsSearchHint,
                debounceDuration: const Duration(milliseconds: 220),
                onChanged: (q) =>
                    context.read<LotListCubit>().loadLots(searchQuery: q),
              ),
              const AppGap.xs(),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    AppChip.filter(
                      label: l10n.lotsFilterAll,
                      selected: state.statusFilter == null,
                      onSelected: (_) => context.read<LotListCubit>().loadLots(
                        clearStatusFilter: true,
                      ),
                    ),
                    const AppGap.hSm(),
                    AppChip.filter(
                      label: l10n.lotsStatusActive,
                      selected: state.statusFilter == LotStatus.active,
                      onSelected: (_) => context.read<LotListCubit>().loadLots(
                        statusFilter: LotStatus.active,
                      ),
                    ),
                    const AppGap.hSm(),
                    AppChip.filter(
                      label: l10n.lotsStatusCompleted,
                      selected: state.statusFilter == LotStatus.completed,
                      onSelected: (_) => context.read<LotListCubit>().loadLots(
                        statusFilter: LotStatus.completed,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          slivers: [
            const SliverToBoxAdapter(
              child: ScreenFirstVisitHint(
                screenId: GuideScreenId.lots,
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  0,
                ),
              ),
            ),
            ...slivers,
          ],
        );
      },
    );
  }
}
