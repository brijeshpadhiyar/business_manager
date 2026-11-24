import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/presentation/bloc/lot_list_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

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
  final _searchController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    return BlocBuilder<LotListCubit, LotListState>(
      builder: (context, state) {
        final activeCount = state.lots
            .where((l) => l.status == LotStatus.active)
            .length;
        final completedCount = state.lots
            .where((l) => l.status == LotStatus.completed)
            .length;

        final List<Widget> slivers;
        if (state.status == LotListStatus.loading ||
            state.status == LotListStatus.initial) {
          slivers = const [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: AppLoader(),
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
        } else if (state.lots.isEmpty) {
          slivers = [
            SliverToBoxAdapter(
              child: AppEmptyState(
                icon: Icons.inventory_2_outlined,
                title: l10n.lotsEmptyTitle,
                subtitle: l10n.lotsEmptySubtitle,
                actionLabel: l10n.lotCreateAction,
                onAction: () => _openCreateLotPage(context),
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
                itemCount: state.lots.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final lot = state.lots[index];
                  return AppCard.listItem(
                    key: ValueKey<String>(lot.id),
                    onTap: () async {
                      await context.push(RoutePaths.lotDetail(lot.id));
                      if (context.mounted) {
                        await context.read<LotListCubit>().loadLots();
                      }
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                lot.lotNumber,
                                variant: AppTextVariant.bodyLarge,
                                fontWeight: FontWeight.w700,
                              ),
                              if (lot.title != null) ...[
                                const SizedBox(height: AppSpacing.xs),
                                AppText(lot.title!),
                              ],
                              const SizedBox(height: AppSpacing.xs),
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
                        AppStatusBadge(
                          label: switch (lot.status) {
                            LotStatus.active => l10n.lotsStatusActive,
                            LotStatus.completed => l10n.lotsStatusCompleted,
                            LotStatus.archived => l10n.lotsStatusArchived,
                          },
                          tone: switch (lot.status) {
                            LotStatus.active => AppStatusTone.good,
                            LotStatus.completed => AppStatusTone.info,
                            LotStatus.archived => AppStatusTone.neutral,
                          },
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
          embedded: true,
          onRefresh: () => context.read<LotListCubit>().loadLots(),
          header: AppCollapsibleHeader(
            title: l10n.lotsHeading,
            automaticallyImplyLeading: false,
            expandedHeight: 164,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: AppButton(
                  label: l10n.lotCreateAction,
                  icon: Icons.add,
                  onPressed: () => _openCreateLotPage(context),
                ),
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
              const SizedBox(height: AppSpacing.xs),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(l10n.lotsFilterAll),
                      selected: state.statusFilter == null,
                      onSelected: (_) => context
                          .read<LotListCubit>()
                          .loadLots(clearStatusFilter: true),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilterChip(
                      label: Text(l10n.lotsStatusActive),
                      selected: state.statusFilter == LotStatus.active,
                      onSelected: (_) => context
                          .read<LotListCubit>()
                          .loadLots(statusFilter: LotStatus.active),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    FilterChip(
                      label: Text(l10n.lotsStatusCompleted),
                      selected: state.statusFilter == LotStatus.completed,
                      onSelected: (_) => context
                          .read<LotListCubit>()
                          .loadLots(statusFilter: LotStatus.completed),
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
