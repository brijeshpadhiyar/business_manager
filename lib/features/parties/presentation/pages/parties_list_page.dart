import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation_localizer.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/auth/domain/services/rbac_policy.dart';
import 'package:business_manager/features/auth/presentation/widgets/permission_gate.dart';
import 'package:business_manager/features/parties/domain/entities/party_entities.dart';
import 'package:business_manager/features/parties/presentation/bloc/parties_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// `/parties` — Searchable Party / Buyer directory & receivables overview.
final class PartiesListPage extends StatelessWidget {
  const PartiesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PartiesCubit>(
      create: (_) => getIt<PartiesCubit>()..loadParties(),
      child: const _PartiesListView(),
    );
  }
}

final class _PartiesListView extends StatelessWidget {
  const _PartiesListView();

  String _partyTypeLabel(BuildContext context, PartyType type) {
    final l10n = context.l10n;
    return switch (type) {
      PartyType.buyer => l10n.partyTypeBuyer,
      PartyType.jobClient => l10n.partyTypeJobClient,
      PartyType.both => l10n.partyTypeBoth,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final canDispatch = PermissionGate.hasPermission(
      context,
      AppPermission.createDispatchAndReturns,
    );

    return AppScaffold(
      title: l10n.partiesHeading,
      contentWidth: AppContentWidth.standard,
      onRefresh: () => context.read<PartiesCubit>().loadParties(),
      actions: [
        if (canDispatch)
          AppIconButton(
            icon: AppIcons.dispatch,
            tooltip: l10n.dispatchNewAction,
            onPressed: () async {
              await context.push(RoutePaths.dispatchCreate());
              if (context.mounted) {
                context.read<PartiesCubit>().loadParties();
              }
            },
          ),
      ],
      primaryAction: canDispatch
          ? AppPrimaryAction(
              icon: AppIcons.partyAdd,
              label: l10n.partyAddAction,
              onPressed: () async {
                await context.push(RoutePaths.partyCreate);
                if (context.mounted) {
                  context.read<PartiesCubit>().loadParties();
                }
              },
            )
          : null,
      body: BlocBuilder<PartiesCubit, PartiesState>(
        builder: (context, state) {
          if (state.status == PartiesStatus.loading && state.summaries.isEmpty) {
            return const AppSkeletonList(itemCount: 5);
          }
          if (state.status == PartiesStatus.error) {
            return AppErrorView(
              title: l10n.errorUnexpected,
              message:
                  ValidationLocalizer.describeMessage(l10n, state.errorMessage) ??
                  l10n.errorUnexpected,
              onRetry: () => context.read<PartiesCubit>().loadParties(),
            );
          }

          final cubit = context.read<PartiesCubit>();
          final filtered = state.filteredSummaries;
          final d = context.density;

          return ListView(
            children: [
              AppSummaryStrip(
                metrics: [
                  AppSummaryMetric(
                    label: l10n.partyTotalReceivableLabel,
                    value: MoneyFormatter.formatPaise(
                      state.totalReceivablePaise,
                    ),
                    tone: state.totalReceivablePaise > 0
                        ? AppStatusTone.pending
                        : AppStatusTone.good,
                    icon: AppIcons.rupee,
                  ),
                  AppSummaryMetric(
                    label: l10n.partyAdvanceCreditLabel,
                    value: MoneyFormatter.formatPaise(
                      state.totalAdvanceCreditPaise,
                    ),
                    tone: AppStatusTone.info,
                    icon: AppIcons.accounting,
                  ),
                ],
              ),
              const AppGap.md(),
              if (canDispatch) ...[
                Wrap(
                  spacing: d.sm,
                  runSpacing: d.sm,
                  children: [
                    AppButton(
                      label: l10n.dispatchNewAction,
                      icon: AppIcons.dispatch,
                      onPressed: () async {
                        await context.push(RoutePaths.dispatchCreate());
                        if (context.mounted) cubit.loadParties();
                      },
                    ),
                  ],
                ),
                const AppGap.md(),
              ],
              AppSearchField(
                label: l10n.partiesSearchHint,
                onChanged: cubit.setSearchQuery,
              ),
              const AppGap.sm(),
              AppChipGroup<PartyListFilter>(
                scrollable: true,
                items: PartyListFilter.values,
                value: state.filter,
                onChanged: cubit.setFilter,
                itemLabelBuilder: (f) => switch (f) {
                  PartyListFilter.all => l10n.partyFilterAll,
                  PartyListFilter.receivableDue => l10n.partyFilterDue,
                  PartyListFilter.advanceCredit => l10n.partyFilterAdvance,
                },
              ),
              const AppGap.md(),
              if (filtered.isEmpty)
                AppEmptyState(
                  icon: AppIcons.party,
                  title: l10n.partiesEmptyTitle,
                  subtitle: l10n.partiesEmptySubtitle,
                  actionLabel: canDispatch ? l10n.partyAddAction : null,
                  onAction: canDispatch
                      ? () async {
                          await context.push(RoutePaths.partyCreate);
                          if (context.mounted) cubit.loadParties();
                        }
                      : null,
                )
              else
                for (final s in filtered) ...[
                  AppCard.listItem(
                    onTap: () async {
                      await context.push(RoutePaths.partyDetail(s.partyId));
                      if (context.mounted) cubit.loadParties();
                    },
                    child: AppActionRow(
                      content: Row(
                        children: [
                          AppAvatar(name: s.partyName, dimmed: !s.isActive),
                          const AppGap.hSm(),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  s.partyName,
                                  variant: d.isCompact
                                      ? AppTextVariant.bodyMedium
                                      : AppTextVariant.bodyLarge,
                                  fontWeight: FontWeight.w600,
                                ),
                                const AppGap.xxs(),
                                AppText(
                                  [
                                    _partyTypeLabel(context, s.partyType),
                                    if (s.partyPhone != null &&
                                        s.partyPhone!.isNotEmpty)
                                      s.partyPhone!,
                                    '${s.totalDispatchedPieces} ${l10n.piecesUnit}',
                                  ].join(' • '),
                                  variant: AppTextVariant.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        if (s.outstandingReceivablePaise > 0)
                          AppStatusBadge(
                            label: MoneyFormatter.formatPaise(
                              s.outstandingReceivablePaise,
                            ),
                            tone: AppStatusTone.pending,
                          )
                        else if (s.advanceCreditPaise > 0)
                          AppStatusBadge(
                            label: MoneyFormatter.formatPaise(
                              s.advanceCreditPaise,
                            ),
                            tone: AppStatusTone.info,
                          )
                        else
                          AppStatusBadge(
                            label: l10n.partyAccountSettledLabel,
                            tone: AppStatusTone.good,
                          ),
                      ],
                    ),
                  ),
                  const AppGap.sm(),
                ],
            ],
          );
        },
      ),
    );
  }
}
