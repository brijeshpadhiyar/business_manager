import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/processes/presentation/bloc/process_list_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

final class ProcessListPage extends StatelessWidget {
  const ProcessListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProcessListCubit>(
      create: (_) => getIt<ProcessListCubit>()..loadProcesses(),
      child: const _ProcessListView(),
    );
  }
}

final class _ProcessListView extends StatefulWidget {
  const _ProcessListView();

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
                    l10n.processesHeading,
                    level: AppHeadingLevel.h2,
                    trailing: AppButton(
                      label: l10n.processCreateAction,
                      icon: Icons.add,
                      onPressed: () => _openCreateProcess(context),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: _searchController,
                    label: l10n.processesSearchHint,
                    prefixIcon: Icons.search,
                    onChanged: (q) => context
                        .read<ProcessListCubit>()
                        .loadProcesses(searchQuery: q),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BlocBuilder<ProcessListCubit, ProcessListState>(
                    builder: (context, state) {
                      return Wrap(
                        spacing: AppSpacing.sm,
                        children: [
                          FilterChip(
                            label: Text(l10n.filterAll),
                            selected: state.activeFilter == null,
                            onSelected: (_) => context
                                .read<ProcessListCubit>()
                                .loadProcesses(clearActiveFilter: true),
                          ),
                          FilterChip(
                            label: Text(l10n.filterActive),
                            selected: state.activeFilter == true,
                            onSelected: (_) => context
                                .read<ProcessListCubit>()
                                .loadProcesses(activeFilter: true),
                          ),
                          FilterChip(
                            label: Text(l10n.filterInactive),
                            selected: state.activeFilter == false,
                            onSelected: (_) => context
                                .read<ProcessListCubit>()
                                .loadProcesses(activeFilter: false),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<ProcessListCubit, ProcessListState>(
                builder: (context, state) {
                  if (state.status == ProcessListStatus.loading ||
                      state.status == ProcessListStatus.initial) {
                    return const AppLoader();
                  }
                  if (state.status == ProcessListStatus.error) {
                    return AppErrorView(
                      title: l10n.errorUnexpected,
                      message: state.errorMessage,
                      retryLabel: l10n.actionRetry,
                      onRetry: () =>
                          context.read<ProcessListCubit>().loadProcesses(),
                    );
                  }
                  if (state.processes.isEmpty) {
                    return AppEmptyState(
                      icon: Icons.precision_manufacturing_outlined,
                      title: l10n.processesEmptyTitle,
                      subtitle: l10n.processesEmptySubtitle,
                      actionLabel: l10n.processCreateAction,
                      onAction: () => _openCreateProcess(context),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.sm,
                      AppSpacing.lg,
                      AppSpacing.xl,
                    ),
                    itemCount: state.processes.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final process = state.processes[index];
                      return AppCard(
                        onTap: () async {
                          await context.push(
                            RoutePaths.processDetail(process.id),
                          );
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
