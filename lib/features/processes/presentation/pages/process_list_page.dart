import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
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
  final _searchController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<ProcessListCubit, ProcessListState>(
      builder: (context, state) {
        final activeCount = state.processes.where((p) => p.isActive).length;
        final inactiveCount = state.processes.length - activeCount;

        final List<Widget> slivers;
        if (state.status == ProcessListStatus.loading ||
            state.status == ProcessListStatus.initial) {
          slivers = const [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: AppLoader(),
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
                onRetry: () =>
                    context.read<ProcessListCubit>().loadProcesses(),
              ),
            ),
          ];
        } else if (state.processes.isEmpty) {
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
              sliver: SliverList.separated(
                itemCount: state.processes.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final process = state.processes[index];
                  return AppCard.listItem(
                    key: ValueKey<String>(process.id),
                    onTap: () async {
                      await context.push(RoutePaths.processDetail(process.id));
                      if (context.mounted) {
                        await context
                            .read<ProcessListCubit>()
                            .loadProcesses();
                      }
                    },
                    child: Row(
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
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
                  );
                },
              ),
            ),
          ];
        }

        return AppScaffold(
          scrollMode: AppScrollMode.collapsible,
          embedded: !widget.showAppBar,
          onRefresh: () => context.read<ProcessListCubit>().loadProcesses(),
          header: AppCollapsibleHeader(
            title: l10n.processesHeading,
            automaticallyImplyLeading: widget.showAppBar,
            expandedHeight: 164,
            actions: [
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
