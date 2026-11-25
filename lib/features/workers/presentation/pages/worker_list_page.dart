import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';
import 'package:business_manager/features/workers/presentation/bloc/worker_list_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

final class WorkerListPage extends StatelessWidget {
  const WorkerListPage({super.key, this.refreshSignal});

  final ValueListenable<int>? refreshSignal;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkerListCubit>(
      create: (_) => getIt<WorkerListCubit>()..loadWorkers(),
      child: _WorkerListView(refreshSignal: refreshSignal),
    );
  }
}

final class _WorkerListView extends StatefulWidget {
  const _WorkerListView({this.refreshSignal});

  final ValueListenable<int>? refreshSignal;

  @override
  State<_WorkerListView> createState() => _WorkerListViewState();
}

final class _WorkerListViewState extends State<_WorkerListView> {
  final _searchController = TextEditingController();
  int _sortColumnIndex = 0;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    widget.refreshSignal?.addListener(_onSilentRefresh);
  }

  @override
  void didUpdateWidget(covariant _WorkerListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      oldWidget.refreshSignal?.removeListener(_onSilentRefresh);
      widget.refreshSignal?.addListener(_onSilentRefresh);
    }
  }

  void _onSilentRefresh() {
    if (mounted) {
      context.read<WorkerListCubit>().loadWorkers();
    }
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_onSilentRefresh);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreateWorker(BuildContext context) async {
    await context.push(RoutePaths.workerCreate);
    if (context.mounted) {
      await context.read<WorkerListCubit>().loadWorkers();
    }
  }

  Future<void> _openWorkerDetail(
    BuildContext context,
    WorkerEntity worker,
  ) async {
    await context.push(RoutePaths.workerDetail(worker.id));
    if (context.mounted) {
      await context.read<WorkerListCubit>().loadWorkers();
    }
  }

  List<WorkerEntity> _sortedWorkers(List<WorkerEntity> input) {
    final list = List<WorkerEntity>.of(input);
    list.sort((a, b) {
      final cmp = switch (_sortColumnIndex) {
        0 => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        1 => (a.phone ?? '').compareTo(b.phone ?? ''),
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
    return BlocBuilder<WorkerListCubit, WorkerListState>(
      builder: (context, state) {
        final activeCount = state.workers.where((w) => w.isActive).length;
        final inactiveCount = state.workers.length - activeCount;
        final sortedWorkers = _sortedWorkers(state.workers);

        final List<Widget> slivers;
        if (state.status == WorkerListStatus.loading ||
            state.status == WorkerListStatus.initial) {
          slivers = const [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: AppSkeletonList(itemCount: 4),
              ),
            ),
          ];
        } else if (state.status == WorkerListStatus.error) {
          slivers = [
            SliverToBoxAdapter(
              child: AppErrorView(
                title: l10n.errorUnexpected,
                message: state.errorMessage,
                retryLabel: l10n.actionRetry,
                onRetry: () => context.read<WorkerListCubit>().loadWorkers(),
              ),
            ),
          ];
        } else if (sortedWorkers.isEmpty) {
          slivers = [
            SliverToBoxAdapter(
              child: AppEmptyState(
                icon: AppIcons.workers,
                title: l10n.workersEmptyTitle,
                subtitle: l10n.workersEmptySubtitle,
                actionLabel: l10n.workerCreateAction,
                onAction: () => _openCreateWorker(context),
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
              sliver: AppDataTable.buildSliver<WorkerEntity>(
                context,
                enablePagination: true,
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                onSort: (col, asc) => setState(() {
                  _sortColumnIndex = col;
                  _sortAscending = asc;
                }),
                columns: [
                  AppDataColumn(label: l10n.workerNameLabel, sortable: true),
                  AppDataColumn(label: l10n.workerPhoneLabel, sortable: true),
                  AppDataColumn(
                    label: l10n.workerAddressLabel,
                    minWidthClass: AppWindowSizeClass.expanded,
                  ),
                  AppDataColumn(label: l10n.lotStatusLabel, sortable: true),
                ],
                items: sortedWorkers,
                itemKeyBuilder: (w) => ValueKey<String>(w.id),
                onRowTap: (w) => _openWorkerDetail(context, w),
                cellsBuilder: (w) => [
                  AppText(w.name, fontWeight: FontWeight.w700),
                  AppText(w.phone ?? '—'),
                  AppText(w.address ?? '—'),
                  AppStatusBadge(
                    label: w.isActive ? l10n.statusActive : l10n.statusInactive,
                    tone: w.isActive
                        ? AppStatusTone.good
                        : AppStatusTone.neutral,
                  ),
                ],
                mobileCardBuilder: (ctx, worker) => AppActionRow(content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            worker.name,
                            variant: AppTextVariant.bodyLarge,
                            fontWeight: FontWeight.w700,
                          ),
                          if (worker.phone != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            AppText(
                              worker.phone!,
                              variant: AppTextVariant.bodySmall,
                            ),
                          ],
                          if (worker.address != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            AppText(
                              worker.address!,
                              variant: AppTextVariant.bodySmall,
                            ),
                          ],
                        ],
                      ), actions: [AppStatusBadge(
                      label: worker.isActive
                          ? l10n.statusActive
                          : l10n.statusInactive,
                      tone: worker.isActive
                          ? AppStatusTone.good
                          : AppStatusTone.neutral,
                    ), const Icon(AppIcons.chevronRight),],),
              ),
            ),
          ];
        }

        return AppScaffold(
          // Main action: floating button on phones, toolbar button on wider screens.
          primaryAction: AppPrimaryAction(
            icon: AppIcons.workerAdd,
            label: l10n.workerCreateAction,
            onPressed: () => _openCreateWorker(context),
          ),
          scrollMode: AppScrollMode.collapsible,
          contentWidth: AppContentWidth.wide,
          embedded: true,
          onRefresh: () => context.read<WorkerListCubit>().loadWorkers(),
          header: AppCollapsibleHeader(
            title: l10n.workersHeading,
            automaticallyImplyLeading: false,
            expandedHeight: 164,
            actions: [
            ],
            summary: AppSummaryStrip(
              metrics: [
                AppSummaryMetric(
                  label: l10n.filterAll,
                  value: '${state.workers.length}',
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
                label: l10n.workersSearchHint,
                debounceDuration: const Duration(milliseconds: 220),
                onChanged: (q) =>
                    context.read<WorkerListCubit>().loadWorkers(searchQuery: q),
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
                          .read<WorkerListCubit>()
                          .loadWorkers(clearActiveFilter: true),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilterChip(
                      label: Text(l10n.filterActive),
                      selected: state.activeFilter == true,
                      onSelected: (_) => context
                          .read<WorkerListCubit>()
                          .loadWorkers(activeFilter: true),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilterChip(
                      label: Text(l10n.filterInactive),
                      selected: state.activeFilter == false,
                      onSelected: (_) => context
                          .read<WorkerListCubit>()
                          .loadWorkers(activeFilter: false),
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
