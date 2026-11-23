import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/workers/presentation/bloc/worker_list_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

final class WorkerListPage extends StatelessWidget {
  const WorkerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkerListCubit>(
      create: (_) => getIt<WorkerListCubit>()..loadWorkers(),
      child: const _WorkerListView(),
    );
  }
}

final class _WorkerListView extends StatefulWidget {
  const _WorkerListView();

  @override
  State<_WorkerListView> createState() => _WorkerListViewState();
}

final class _WorkerListViewState extends State<_WorkerListView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openCreateWorker(BuildContext context) async {
    await context.push(RoutePaths.workerCreate);
    if (context.mounted) {
      await context.read<WorkerListCubit>().loadWorkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizing.maxContentWidth),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppHeading(
                    l10n.workersHeading,
                    level: AppHeadingLevel.h2,
                    trailing: AppButton(
                      label: l10n.workerCreateAction,
                      icon: Icons.person_add_outlined,
                      onPressed: () => _openCreateWorker(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _searchController,
                    label: l10n.workersSearchHint,
                    prefixIcon: Icons.search,
                    onChanged: (q) => context
                        .read<WorkerListCubit>()
                        .loadWorkers(searchQuery: q),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BlocBuilder<WorkerListCubit, WorkerListState>(
                    builder: (context, state) {
                      return Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          FilterChip(
                            label: Text(l10n.filterAll),
                            selected: state.activeFilter == null,
                            onSelected: (_) => context
                                .read<WorkerListCubit>()
                                .loadWorkers(clearActiveFilter: true),
                          ),
                          FilterChip(
                            label: Text(l10n.filterActive),
                            selected: state.activeFilter == true,
                            onSelected: (_) => context
                                .read<WorkerListCubit>()
                                .loadWorkers(activeFilter: true),
                          ),
                          FilterChip(
                            label: Text(l10n.filterInactive),
                            selected: state.activeFilter == false,
                            onSelected: (_) => context
                                .read<WorkerListCubit>()
                                .loadWorkers(activeFilter: false),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<WorkerListCubit, WorkerListState>(
                builder: (context, state) {
                  if (state.status == WorkerListStatus.loading ||
                      state.status == WorkerListStatus.initial) {
                    return const AppLoader();
                  }
                  if (state.status == WorkerListStatus.error) {
                    return AppErrorView(
                      title: l10n.errorUnexpected,
                      message: state.errorMessage,
                      retryLabel: l10n.actionRetry,
                      onRetry: () =>
                          context.read<WorkerListCubit>().loadWorkers(),
                    );
                  }
                  if (state.workers.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.people_outline,
                      title: l10n.workersEmptyTitle,
                      subtitle: l10n.workersEmptySubtitle,
                      actionLabel: l10n.workerCreateAction,
                      onAction: () => _openCreateWorker(context),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    itemCount: state.workers.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final worker = state.workers[index];
                      return AppCard(
                        onTap: () async {
                          await context.push(
                            RoutePaths.workerDetail(worker.id),
                          );
                          if (context.mounted) {
                            await context.read<WorkerListCubit>().loadWorkers();
                          }
                        },
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
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
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            AppStatusBadge(
                              label: worker.isActive
                                  ? l10n.statusActive
                                  : l10n.statusInactive,
                              tone: worker.isActive
                                  ? AppStatusTone.good
                                  : AppStatusTone.neutral,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
