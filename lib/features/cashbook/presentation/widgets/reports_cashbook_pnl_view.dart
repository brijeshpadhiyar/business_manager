import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/localization/domain_label_localizer.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/cashbook/domain/entities/cashbook_entities.dart';
import 'package:business_manager/features/reports/domain/entities/advanced_report_entities.dart';
import 'package:material_ui/material_ui.dart';

/// 8th Reports category view: Cashbook Summary, Expense Breakdown & True
/// Workshop Net Profit.
final class ReportsCashbookPnlView extends StatelessWidget {
  const ReportsCashbookPnlView({super.key, required this.bundle});

  final AdvancedReportsBundle bundle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cb = bundle.cashbookSummary;
    final pnl = bundle.trueNetProfit;

    if (cb == null || pnl == null) {
      return AppEmptyState(
        icon: AppIcons.cashbook,
        title: l10n.cashbookEmptyTitle,
        subtitle: l10n.cashbookEmptySubtitle,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppHeading(
          l10n.reportTrueNetProfitHeading,
          level: AppHeadingLevel.h3,
        ),
        const AppGap.sm(),
        AppSummaryStrip(
          metrics: [
            AppSummaryMetric(
              label: l10n.lotPnlNetRevenueLabel,
              value: MoneyFormatter.formatPaise(pnl.netDispatchedSalesPaise),
              tone: AppStatusTone.info,
            ),
            AppSummaryMetric(
              label: l10n.lotPnlWorkerLabourLabel,
              value: MoneyFormatter.formatPaise(pnl.workerLabourPaise),
              tone: AppStatusTone.neutral,
            ),
            AppSummaryMetric(
              label: l10n.lotPnlDirectCostsLabel,
              value: MoneyFormatter.formatPaise(pnl.lotDirectCostsPaise),
              tone: AppStatusTone.neutral,
            ),
            AppSummaryMetric(
              label: l10n.reportOverheadExpensesLabel,
              value: MoneyFormatter.formatPaise(
                pnl.workshopOverheadExpensesPaise,
              ),
              tone: pnl.workshopExpensesUnpaidPaise > 0
                  ? AppStatusTone.pending
                  : AppStatusTone.neutral,
            ),
            AppSummaryMetric(
              label: l10n.lotPnlNetProfitLabel,
              value:
                  '${MoneyFormatter.formatPaise(pnl.trueNetProfitPaise)} (${pnl.netMarginPercent.toStringAsFixed(1)}%)',
              tone: pnl.trueNetProfitPaise >= 0
                  ? AppStatusTone.good
                  : AppStatusTone.damaged,
            ),
          ],
        ),
        const AppGap.lg(),
        AppHeading(
          l10n.reportCashflowSummaryHeading,
          level: AppHeadingLevel.h3,
        ),
        const AppGap.sm(),
        AppSummaryStrip(
          metrics: [
            AppSummaryMetric(
              label: l10n.cashbookCashInHandLabel,
              value: MoneyFormatter.formatPaise(cb.currentCashBalancePaise),
              tone: cb.currentCashBalancePaise >= 0
                  ? AppStatusTone.good
                  : AppStatusTone.damaged,
            ),
            AppSummaryMetric(
              label: l10n.cashbookBankBalanceLabel,
              value: MoneyFormatter.formatPaise(cb.currentBankBalancePaise),
              tone: cb.currentBankBalancePaise >= 0
                  ? AppStatusTone.info
                  : AppStatusTone.damaged,
            ),
            AppSummaryMetric(
              label: l10n.reportTotalInflowsLabel,
              value: MoneyFormatter.formatPaise(
                cb.cashInflowPaise + cb.bankInflowPaise,
              ),
              tone: AppStatusTone.good,
            ),
            AppSummaryMetric(
              label: l10n.reportTotalOutflowsLabel,
              value: MoneyFormatter.formatPaise(
                cb.cashOutflowPaise + cb.bankOutflowPaise,
              ),
              tone: AppStatusTone.pending,
            ),
          ],
        ),
        const AppGap.lg(),
        AppHeading(
          l10n.cashbookCategoryBreakdownHeading,
          level: AppHeadingLevel.h3,
        ),
        const AppGap.sm(),
        if (cb.categoryBreakdowns.isEmpty)
          AppEmptyState(
            icon: AppIcons.expense,
            title: l10n.cashbookEmptyTitle,
            subtitle: l10n.cashbookEmptySubtitle,
          )
        else
          AppDataTable<ExpenseCategoryBreakdown>(
            items: cb.categoryBreakdowns,
            columns: [
              AppDataColumn(label: l10n.cashbookExpenseCategoryLabel),
              AppDataColumn(label: l10n.cashbookExpensePaidBadge, numeric: true),
              AppDataColumn(
                label: l10n.cashbookExpenseUnpaidBadge,
                numeric: true,
              ),
              AppDataColumn(label: l10n.accountingAmountLabel, numeric: true),
            ],
            cellsBuilder: (r) => [
              Text(DomainLabelLocalizer.expenseCategory(l10n, r.category)),
              Text(MoneyFormatter.formatPaise(r.paidPaise)),
              Text(MoneyFormatter.formatPaise(r.unpaidPaise)),
              Text(MoneyFormatter.formatPaise(r.totalPaise)),
            ],
            mobileCardBuilder: (context, r) => AppCard.listItem(
              child: AppActionRow(
                content: AppText(
                  DomainLabelLocalizer.expenseCategory(l10n, r.category),
                  fontWeight: FontWeight.w700,
                ),
                actions: [
                  AppStatusBadge(
                    label: MoneyFormatter.formatPaise(r.totalPaise),
                    tone: r.unpaidPaise > 0
                        ? AppStatusTone.pending
                        : AppStatusTone.neutral,
                  ),
                ],
              ),
            ),
          ),
        const AppGap.md(),
      ],
    );
  }
}
