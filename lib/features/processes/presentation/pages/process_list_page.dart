import 'package:business_manager/core/utils/app_memo.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/processes/presentation/bloc/process_list_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

final class ProcessListPage extends StatelessWidget {
  const ProcessListPage({super.key, this.showAppBar = false});

  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProcessListCubit>(
      create: (_) => getIt<ProcessListCubit>()..loadProcesses(),
      child: _ProcessListView(showAppBar: showAppBar),
    );
  }
}

final class _ProcessListView extends StatefulWidget {
  const _ProcessListView({required this.showAppBar});

  final bool showAppBar;

  @override
  State<_ProcessListView> createState() => _ProcessListViewState();
}

final class _ProcessListViewState extends State<_ProcessListView> {
  // Sorting and counting run only when the data or sort settings change.
  final _sortMemo = AppMemo<List<ProcessEntity>>();
  final _countMemo = AppMemo<int>();
  final _searchController = TextEditingController();
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreateProcess(BuildContext context) async {
    await context.push(RoutePaths.processCreate);
    if (context.mounted) {
      await context.read<ProcessListCubit>().loadProcesses();
    }
  }

  Future<void> _openProcessDetail(
    BuildContext context,
    ProcessEntity process,
  ) async {
    await context.push(RoutePaths.processDetail(process.id));
    if (context.mounted) {
      await context.read<ProcessListCubit>().loadProcesses();
    }
  }

  List<ProcessEntity> _sortedProcesses(List<ProcessEntity> input) {
    final list = List<ProcessEntity>.of(input);
    list.sort((a, b) {
      final cmp = switch (_sortColumnIndex) {
        0 => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        2 => a.defaultRatePaise.compareTo(b.defaultRatePaise),
        3 => (a.isActive ? 0 : 1).compareTo(b.isActive ? 0 : 1),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ProcessListCubit, ProcessListState>(
      builder: (context, state) {
        final activeCount = _countMemo([
          state.processes,
        ], () => state.processes.where((p) => p.isActive).length);
        final inactiveCount = state.processes.length - activeCount;
        final sortedProcesses = _sortMemo([
          state.processes,
          _sortColumnIndex,
          _sortAscending,
        ], () => _sortedProcesses(state.processes));

        final List<Widget> slivers;
        if (state.status == ProcessListStatus.loading ||
            state.status == ProcessListStatus.initial) {
          slivers = const [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: AppSkeletonList(itemCount: 4),
              ),
            ),
          ];
        } else if (state.status == ProcessListStatus.error) {
          slivers = [
            SliverToBoxAdapter(
              child: AppErrorView(
                title: l10n.errorUnexpected,
                message: state.errorMessage,
                retryLabel: l10n.actionRetry,
                onRetry: () => context.read<ProcessListCubit>().loadProcesses(),
              ),
            ),
          ];
        } else if (sortedProcesses.isEmpty) {
          slivers = [
            SliverToBoxAdapter(
              child: AppEmptyState(
                icon: Icons.precision_manufacturing_outlined,
                title: l10n.processesEmptyTitle,
                subtitle: l10n.processesEmptySubtitle,
                actionLabel: l10n.processCreateAction,
                onAction: () => _openCreateProcess(context),
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
              sliver: AppDataTable.buildSliver<ProcessEntity>(
                context,
                enablePagination: true,
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                onSort: (col, asc) => setState(() {
                  _sortColumnIndex = col;
                  _sortAscending = asc;
                }),
                columns: [
                  AppDataColumn(label: l10n.processNameLabel, sortable: true),
                  AppDataColumn(
                    label: l10n.processDescriptionLabel,
                    minWidthClass: AppWindowSizeClass.expanded,
                  ),
                  const AppDataColumn(
                    label: 'Default Rate',
                    numeric: true,
                    sortable: true,
                  ),
                  AppDataColumn(label: l10n.lotStatusLabel, sortable: true),
                ],
                items: sortedProcesses,
                itemKeyBuilder: (p) => ValueKey<String>(p.id),
                onRowTap: (p) => _openProcessDetail(context, p),
                cellsBuilder: (p) => [
                  AppText(p.name, fontWeight: FontWeight.w700),
                  AppText(p.description ?? '—'),
                  AppText(
                    p.defaultRatePaise > 0
                        ? MoneyFormatter.formatRatePaise(
                            p.defaultRatePaise,
                            pricingUnit: p.defaultPricingUnit,
                          )
                        : '—',
                  ),
                  AppStatusBadge(
                    label: p.isActive ? l10n.statusActive : l10n.statusInactive,
                    tone: p.isActive
                        ? AppStatusTone.good
                        : AppStatusTone.neutral,
                  ),
                ],
                mobileCardBuilder: (ctx, process) => Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            process.name,
                            variant: AppTextVariant.bodyLarge,
                            fontWeight: FontWeight.w700,
                          ),
                          if (process.description != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            AppText(
                              process.description!,
                              variant: AppTextVariant.bodySmall,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xs),
                          AppText(
                            process.defaultRatePaise > 0
                                ? 'Default Rate: ${MoneyFormatter.formatRatePaise(process.defaultRatePaise, pricingUnit: process.defaultPricingUnit)}'
                                : 'No default labour rate',
                            variant: AppTextVariant.bodySmall,
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppStatusBadge(
                      label: process.isActive
                          ? l10n.statusActive
                          : l10n.statusInactive,
                      tone: process.isActive
                          ? AppStatusTone.good
                          : AppStatusTone.neutral,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ];
        }

        return AppScaffold(
          scrollMode: AppScrollMode.collapsible,
          contentWidth: AppContentWidth.wide,
          embedded: !widget.showAppBar,
          onRefresh: () => context.read<ProcessListCubit>().loadProcesses(),
          header: AppCollapsibleHeader(
            title: l10n.processesHeading,
            automaticallyImplyLeading: widget.showAppBar,
            expandedHeight: 164,
            actions: [
              AppIconButton(
                icon: Icons.timeline_rounded,
                tooltip: l10n.navProcessHistory,
                onPressed: () =>
                    context.push(RoutePaths.processProductionHistory),
              ),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: AppButton(
                  label: l10n.processCreateAction,
                  icon: Icons.add,
                  onPressed: () => _openCreateProcess(context),
                ),
              ),
            ],
            summary: AppSummaryStrip(
              metrics: [
                AppSummaryMetric(
                  label: l10n.filterAll,
                  value: '${state.processes.length}',
                  tone: AppStatusTone.info,
                ),
                AppSummaryMetric(
                  label: l10n.filterActive,
                  value: '$activeCount',
                  tone: AppStatusTone.good,
                ),
                AppSummaryMetric(
                  label: l10n.filterInactive,
                  value: '$inactiveCount',
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
                label: l10n.processesSearchHint,
                debounceDuration: const Duration(milliseconds: 220),
                onChanged: (q) => context
                    .read<ProcessListCubit>()
                    .loadProcesses(searchQuery: q),
              ),
              const SizedBox(height: AppSpacing.xs),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(l10n.filterAll),
                      selected: state.activeFilter == null,
                      onSelected: (_) => context
                          .read<ProcessListCubit>()
                          .loadProcesses(clearActiveFilter: true),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilterChip(
                      label: Text(l10n.filterActive),
                      selected: state.activeFilter == true,
                      onSelected: (_) => context
                          .read<ProcessListCubit>()
                          .loadProcesses(activeFilter: true),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilterChip(
                      label: Text(l10n.filterInactive),
                      selected: state.activeFilter == false,
                      onSelected: (_) => context
                          .read<ProcessListCubit>()
                          .loadProcesses(activeFilter: false),
                    ),
                  ],
                ),
              ),
            ],
          ),
          slivers: slivers,
        );
      },
    );
  }
}
