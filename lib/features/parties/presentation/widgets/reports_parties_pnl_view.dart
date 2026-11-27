import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/reports/domain/entities/advanced_report_entities.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Category 7 on ReportsPage: Party Receivables & Lot Profit/Loss.
final class ReportsPartiesPnlView extends StatelessWidget {
  const ReportsPartiesPnlView({super.key, required this.bundle});

  final AdvancedReportsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final parties = bundle.partySummaries;
    final lots = bundle.lotProfitLossRows;

    final totalReceivable = parties.fold<int>(
      0,
      (s, p) => s + p.outstandingReceivablePaise,
    );
    final totalNetRevenue = lots.fold<int>(
      0,
      (s, l) => s + l.netRevenuePaise,
    );
    final totalNetProfit = lots.fold<int>(
      0,
      (s, l) => s + l.netProfitPaise,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSummaryStrip(
          metrics: [
            AppSummaryMetric(
              label: l10n.partyTotalReceivableLabel,
              value: MoneyFormatter.formatPaise(totalReceivable),
              tone: totalReceivable > 0
                  ? AppStatusTone.pending
                  : AppStatusTone.good,
              icon: AppIcons.rupee,
            ),
            AppSummaryMetric(
              label: l10n.lotPnlNetRevenueLabel,
              value: MoneyFormatter.formatPaise(totalNetRevenue),
              tone: AppStatusTone.info,
              icon: AppIcons.dispatch,
            ),
            AppSummaryMetric(
              label: l10n.lotPnlNetProfitLabel,
              value: MoneyFormatter.formatPaise(totalNetProfit),
              tone: totalNetProfit >= 0
                  ? AppStatusTone.good
                  : AppStatusTone.damaged,
              icon: AppIcons.profitLoss,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppHeading(l10n.partiesHeading, level: AppHeadingLevel.h3),
        const SizedBox(height: AppSpacing.xs),
        if (parties.isEmpty)
          AppEmptyState(
            icon: AppIcons.party,
            title: l10n.partiesEmptyTitle,
            subtitle: l10n.partiesEmptySubtitle,
          )
        else
          for (final p in parties) ...[
            AppCard.listItem(
              onTap: () => context.push(RoutePaths.partyDetail(p.partyId)),
              child: AppActionRow(
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(p.partyName, fontWeight: FontWeight.w600),
                    AppText(
                      '${l10n.partyDispatchedNetLabel}: ${MoneyFormatter.formatPaise(p.totalDispatchedNetPaise)} • ${l10n.partyCollectedNetLabel}: ${MoneyFormatter.formatPaise(p.totalCollectedNetPaise)}',
                      variant: AppTextVariant.bodySmall,
                    ),
                  ],
                ),
                actions: [
                  AppStatusBadge(
                    label: p.outstandingReceivablePaise > 0
                        ? MoneyFormatter.formatPaise(
                            p.outstandingReceivablePaise,
                          )
                        : p.advanceCreditPaise > 0
                        ? MoneyFormatter.formatPaise(p.advanceCreditPaise)
                        : l10n.partyAccountSettledLabel,
                    tone: p.outstandingReceivablePaise > 0
                        ? AppStatusTone.pending
                        : p.advanceCreditPaise > 0
                        ? AppStatusTone.info
                        : AppStatusTone.good,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
        const SizedBox(height: AppSpacing.md),
        AppHeading(l10n.lotPnlHeading, level: AppHeadingLevel.h3),
        const SizedBox(height: AppSpacing.xs),
        for (final lot in lots) ...[
          AppCard.listItem(
            onTap: () => context.push(RoutePaths.lotDetail(lot.lotId)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppActionRow(
                  content: AppText(
                    lot.lotTitle != null && lot.lotTitle!.isNotEmpty
                        ? '${lot.lotNumber} • ${lot.lotTitle}'
                        : lot.lotNumber,
                    fontWeight: FontWeight.w600,
                  ),
                  actions: [
                    AppStatusBadge(
                      label: MoneyFormatter.formatPaise(lot.netProfitPaise),
                      tone: lot.netProfitPaise >= 0
                          ? AppStatusTone.good
                          : AppStatusTone.damaged,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                AppText(
                  '${l10n.lotPnlNetRevenueLabel}: ${MoneyFormatter.formatPaise(lot.netRevenuePaise)} • ${l10n.lotPnlWorkerLabourLabel}: ${MoneyFormatter.formatPaise(lot.workerLabourPaise)} • ${l10n.lotPnlDirectCostsLabel}: ${MoneyFormatter.formatPaise(lot.directCostsPaise)}',
                  variant: AppTextVariant.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }
}
