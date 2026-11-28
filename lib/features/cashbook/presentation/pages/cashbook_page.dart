import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/domain_label_localizer.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/auth/domain/services/rbac_policy.dart';
import 'package:business_manager/features/auth/presentation/widgets/permission_gate.dart';
import 'package:business_manager/features/cashbook/domain/entities/cashbook_entities.dart';
import 'package:business_manager/features/cashbook/presentation/bloc/cashbook_cubit.dart';
import 'package:business_manager/features/cashbook/presentation/widgets/cashbook_opening_balance_dialog.dart';
import 'package:business_manager/features/cashbook/presentation/widgets/expense_detail_sheet.dart';
import 'package:business_manager/features/reports/domain/entities/report_filter.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:timezone/timezone.dart' as tz;

/// `/cashbook` — Unified Cash & Bank Book + Workshop Expenses Hub.
final class CashbookPage extends StatelessWidget {
  const CashbookPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CashbookCubit>(
      create: (_) => getIt<CashbookCubit>()..load(),
      child: const _CashbookView(),
    );
  }
}

final class _CashbookView extends StatelessWidget {
  const _CashbookView();

  Future<void> _openCreateExpense(BuildContext context) async {
    final saved = await context.push<bool>(RoutePaths.expenseCreate);
    if (saved == true && context.mounted) {
      await context.read<CashbookCubit>().load();
    }
  }

  Future<void> _openCreateTransfer(BuildContext context) async {
    final saved = await context.push<bool>(RoutePaths.cashbookTransferCreate);
    if (saved == true && context.mounted) {
      await context.read<CashbookCubit>().load();
    }
  }

  Future<void> _selectDatePreset(
    BuildContext context,
    ReportDatePreset preset,
  ) async {
    final cubit = context.read<CashbookCubit>();
    if (preset != ReportDatePreset.custom) {
      await cubit.setDatePreset(preset);
      return;
    }

    final state = cubit.state;
    final initialStart = state.fromUtcMillis != null
        ? IstDateTimeHelper.fromUtcMillisToIst(state.fromUtcMillis!)
        : IstDateTimeHelper.fromUtcMillisToIst(IstDateTimeHelper.nowUtcMillis());
    final initialEnd = state.toUtcMillis != null
        ? IstDateTimeHelper.fromUtcMillisToIst(state.toUtcMillis!)
        : initialStart;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(
        start: DateTime(
          initialStart.year,
          initialStart.month,
          initialStart.day,
        ),
        end: DateTime(initialEnd.year, initialEnd.month, initialEnd.day),
      ),
    );
    if (picked == null || !context.mounted) return;

    final fromIst = tz.TZDateTime(
      IstDateTimeHelper.istLocation,
      picked.start.year,
      picked.start.month,
      picked.start.day,
    ).millisecondsSinceEpoch;
    final toIst = tz.TZDateTime(
      IstDateTimeHelper.istLocation,
      picked.end.year,
      picked.end.month,
      picked.end.day,
      23,
      59,
      59,
      999,
    ).millisecondsSinceEpoch;

    await cubit.setDatePreset(
      ReportDatePreset.custom,
      customFromUtcMillis: fromIst,
      customToUtcMillis: toIst,
    );
  }

  Future<void> _editOpeningBalances(
    BuildContext context,
    CashbookSummary summary,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<CashbookCubit>();
    final res = await CashbookOpeningBalanceDialog.show(
      context,
      initialCashPaise: summary.openingCashPaise,
      initialBankPaise: summary.openingBankPaise,
    );
    if (res == null || !context.mounted) return;
    try {
      await cubit.setOpeningBalances(
        openingCashPaise: res.openingCashPaise,
        openingBankPaise: res.openingBankPaise,
        transactionAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
      );
      if (!context.mounted) return;
      AppFeedback.showSuccess(context, l10n.cashbookOpeningSavedSuccess);
    } catch (e) {
      if (!context.mounted) return;
      AppFeedback.showError(
        context,
        ValidationLocalizer.describeError(l10n, e),
      );
    }
  }

  Future<void> _markBillPaid(
    BuildContext context,
    WorkshopExpenseView view,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<CashbookCubit>();
    final result = await AppDialog.showCustom<
      ({int amountPaise, PaymentMode mode, String referenceNo})
    >(
      context,
      builder: (_) => _MarkBillPaidDialog(view: view),
    );
    if (result == null || !context.mounted) return;

    try {
      await cubit.markExpensePaid(
        expenseId: view.expense.id,
        paymentMode: result.mode,
        amountPaise: result.amountPaise,
        referenceNo: result.referenceNo,
        transactionAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
      );
      if (!context.mounted) return;
      AppFeedback.showSuccess(context, l10n.cashbookPaidSuccess);
    } catch (e) {
      if (!context.mounted) return;
      AppFeedback.showError(
        context,
        ValidationLocalizer.describeError(l10n, e),
      );
    }
  }

  Future<void> _confirmReverse({
    required BuildContext context,
    required String title,
    required String summaryText,
    required Future<void> Function(String reason) onConfirmed,
  }) async {
    final l10n = context.l10n;
    final reason = await AppDialog.showCustom<String>(
      context,
      builder: (_) => _ReverseReasonDialog(
        title: title,
        summaryText: summaryText,
      ),
    );
    if (reason == null || reason.isEmpty || !context.mounted) return;

    try {
      await onConfirmed(reason);
      if (!context.mounted) return;
      AppFeedback.showSuccess(context, l10n.cashbookReversedSuccess);
    } catch (e) {
      if (!context.mounted) return;
      AppFeedback.showError(
        context,
        ValidationLocalizer.describeError(l10n, e),
      );
    }
  }

  Future<void> _showReceiptPreview(
    BuildContext context,
    WorkshopExpenseView view,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<CashbookCubit>();
    final bytes = await cubit.readReceiptBytes(view.expense.id);
    if (!context.mounted) return;
    if (bytes == null || bytes.isEmpty) {
      AppFeedback.showError(context, l10n.errorUnexpected);
      return;
    }
    await AppDialog.showCustom<void>(
      context,
      builder: (dialogCtx) => AppDialog(
        title: view.expense.title,
        confirmLabel: l10n.actionClose,
        onConfirm: () => Navigator.of(dialogCtx).pop(),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 380),
          child: ClipRRect(
            borderRadius: context.density.radiusMdBorder,
            child: Image.memory(bytes, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  Future<void> _openExpenseDetail(
    BuildContext context,
    WorkshopExpenseView view,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<CashbookCubit>();
    await ExpenseDetailSheet.show(
      context,
      view: view,
      cubit: cubit,
      onMarkPaid: () => _markBillPaid(context, view),
      onReverseExpense: () => _confirmReverse(
        context: context,
        title: l10n.cashbookReverseExpenseTitle,
        summaryText:
            '${view.expense.title} • ${MoneyFormatter.formatPaise(view.expense.amountPaise)}',
        onConfirmed: (reason) => cubit.reverseExpense(
          expenseId: view.expense.id,
          reason: reason,
          transactionAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
        ),
      ),
      onReverseSettlement: (entry) => _confirmReverse(
        context: context,
        title: l10n.cashbookReverseEntryTitle,
        summaryText:
            '${DomainLabelLocalizer.cashbookEntryType(l10n, entry.entryType)} • ${MoneyFormatter.formatPaise(entry.amountPaise)}',
        onConfirmed: (reason) => cubit.reverseCashbookEntry(
          entryId: entry.id,
          reason: reason,
          transactionAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
        ),
      ),
    );
  }

  String _datePresetLabel(AppLocalizations l10n, ReportDatePreset preset) {
    return switch (preset) {
      ReportDatePreset.allTime => l10n.reportPresetAllTime,
      ReportDatePreset.today => l10n.reportPresetToday,
      ReportDatePreset.thisWeek => l10n.reportPresetThisWeek,
      ReportDatePreset.thisMonth => l10n.reportPresetThisMonth,
      ReportDatePreset.custom => l10n.reportPresetCustom,
      ReportDatePreset.yesterday => l10n.reportPresetYesterday,
      ReportDatePreset.previousMonth => l10n.reportPresetPreviousMonth,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = context.density;

    return BlocBuilder<CashbookCubit, CashbookState>(
      builder: (context, state) {
        final cubit = context.read<CashbookCubit>();
        final summary = state.summary;

        return AppScaffold(
          title: l10n.cashbookHeading,
          contentWidth: AppContentWidth.wide,
          actions: [
            AppIconButton(
              icon: AppIcons.refresh,
              tooltip: l10n.actionRetry,
              onPressed: () => cubit.load(),
            ),
          ],
          primaryAction: PermissionGate.hasPermission(
            context,
            AppPermission.recordCashExpense,
          )
              ? AppPrimaryAction(
                  label: l10n.cashbookRecordExpenseAction,
                  icon: AppIcons.add,
                  onPressed: () => _openCreateExpense(context),
                )
              : null,
          body: state.status == CashbookStatus.loading && summary == null
              ? const AppSkeletonList(itemCount: 4)
              : state.status == CashbookStatus.error && summary == null
              ? AppErrorView(
                  title: l10n.errorUnexpected,
                  message: ValidationLocalizer.describeMessage(
                    l10n,
                    state.errorMessage,
                  ),
                  retryLabel: l10n.actionRetry,
                  onRetry: () => cubit.load(),
                )
              : summary == null
              ? const SizedBox.shrink()
              : RefreshIndicator(
                  onRefresh: () => cubit.load(),
                  child: ListView(
                    padding: d.screenAll,
                    children: [
                      AppSummaryStrip(
                        metrics: [
                          AppSummaryMetric(
                            label: l10n.cashbookCashInHandLabel,
                            value: MoneyFormatter.formatPaise(
                              summary.currentCashBalancePaise,
                            ),
                            tone: summary.currentCashBalancePaise >= 0
                                ? AppStatusTone.good
                                : AppStatusTone.damaged,
                          ),
                          AppSummaryMetric(
                            label: l10n.cashbookBankBalanceLabel,
                            value: MoneyFormatter.formatPaise(
                              summary.currentBankBalancePaise,
                            ),
                            tone: summary.currentBankBalancePaise >= 0
                                ? AppStatusTone.info
                                : AppStatusTone.damaged,
                          ),
                          AppSummaryMetric(
                            label: l10n.cashbookTotalBalanceLabel,
                            value: MoneyFormatter.formatPaise(
                              summary.totalLiquidBalancePaise,
                            ),
                            tone: AppStatusTone.neutral,
                          ),
                          AppSummaryMetric(
                            label: l10n.cashbookPendingBillsLabel,
                            value: MoneyFormatter.formatPaise(
                              summary.totalExpensesUnpaidPaise,
                            ),
                            tone: summary.totalExpensesUnpaidPaise > 0
                                ? AppStatusTone.pending
                                : AppStatusTone.good,
                          ),
                        ],
                      ),
                      if (state.datePreset != ReportDatePreset.allTime) ...[
                        const AppGap.sm(),
                        AppSummaryStrip(
                          metrics: [
                            AppSummaryMetric(
                              label: l10n.cashbookPeriodCashFlow,
                              value: l10n.cashbookPeriodInOutValue(
                                MoneyFormatter.formatPaise(
                                  summary.cashInflowPaise,
                                ),
                                MoneyFormatter.formatPaise(
                                  summary.cashOutflowPaise,
                                ),
                              ),
                              tone: AppStatusTone.good,
                            ),
                            AppSummaryMetric(
                              label: l10n.cashbookPeriodBankFlow,
                              value: l10n.cashbookPeriodInOutValue(
                                MoneyFormatter.formatPaise(
                                  summary.bankInflowPaise,
                                ),
                                MoneyFormatter.formatPaise(
                                  summary.bankOutflowPaise,
                                ),
                              ),
                              tone: AppStatusTone.info,
                            ),
                          ],
                        ),
                      ],
                      const AppGap.md(),
                      Wrap(
                        spacing: d.sm,
                        runSpacing: d.sm,
                        children: [
                          PermissionGate(
                            permission:
                                AppPermission.recordNonCashExpenseAndTransfers,
                            child: AppButton(
                              label: l10n.cashbookTransferAction,
                              icon: AppIcons.transfer,
                              variant: AppButtonVariant.outlined,
                              onPressed: () => _openCreateTransfer(context),
                            ),
                          ),
                          PermissionGate(
                            permission: AppPermission.manageOpeningBalances,
                            child: AppButton(
                              label: l10n.cashbookOpeningBalanceAction,
                              icon: AppIcons.bank,
                              variant: AppButtonVariant.outlined,
                              onPressed: () =>
                                  _editOpeningBalances(context, summary),
                            ),
                          ),
                        ],
                      ),
                      const AppGap.md(),
                      AppChipGroup<ReportDatePreset>(
                        scrollable: true,
                        items: const [
                          ReportDatePreset.allTime,
                          ReportDatePreset.today,
                          ReportDatePreset.thisWeek,
                          ReportDatePreset.thisMonth,
                          ReportDatePreset.custom,
                        ],
                        value: state.datePreset,
                        onChanged: (preset) =>
                            _selectDatePreset(context, preset),
                        itemLabelBuilder: (p) {
                          if (p == ReportDatePreset.custom &&
                              state.datePreset == ReportDatePreset.custom &&
                              state.fromUtcMillis != null &&
                              state.toUtcMillis != null) {
                            return '${AppDateTimeFormatter.formatDate(state.fromUtcMillis!)} – ${AppDateTimeFormatter.formatDate(state.toUtcMillis!)}';
                          }
                          return _datePresetLabel(l10n, p);
                        },
                      ),
                      const AppGap.sm(),
                      AppSearchField(
                        label: l10n.cashbookSearchHint,
                        debounceDuration: const Duration(milliseconds: 150),
                        onChanged: cubit.setSearchQuery,
                      ),
                      const AppGap.md(),
                      AppChipGroup<int>(
                        items: const [0, 1, 2],
                        value: state.activeTab,
                        onChanged: cubit.selectTab,
                        itemLabelBuilder: (tab) => switch (tab) {
                          0 => l10n.cashbookTabAll,
                          1 => l10n.cashbookTabExpenses,
                          _ =>
                            '${l10n.cashbookTabPendingBills} (${summary.pendingBills.length})',
                        },
                      ),
                      const AppGap.md(),
                      if (state.activeTab == 0)
                        _AllCashbookTab(
                          summary: summary,
                          state: state,
                          onOpenExpenseDetail: (view) =>
                              _openExpenseDetail(context, view),
                          onConfirmReverseEntry: (entry) => _confirmReverse(
                            context: context,
                            title: l10n.cashbookReverseEntryTitle,
                            summaryText:
                                '${DomainLabelLocalizer.cashbookEntryType(l10n, entry.entryType)} • ${MoneyFormatter.formatPaise(entry.amountPaise)}',
                            onConfirmed: (reason) =>
                                cubit.reverseCashbookEntry(
                                  entryId: entry.id,
                                  reason: reason,
                                  transactionAtUtcMillis:
                                      IstDateTimeHelper.nowUtcMillis(),
                                ),
                          ),
                          onConfirmReverseExpense: (view) => _confirmReverse(
                            context: context,
                            title: l10n.cashbookReverseExpenseTitle,
                            summaryText:
                                '${view.expense.title} • ${MoneyFormatter.formatPaise(view.expense.amountPaise)}',
                            onConfirmed: (reason) => cubit.reverseExpense(
                              expenseId: view.expense.id,
                              reason: reason,
                              transactionAtUtcMillis:
                                  IstDateTimeHelper.nowUtcMillis(),
                            ),
                          ),
                        )
                      else if (state.activeTab == 1)
                        _ExpensesTab(
                          summary: summary,
                          state: state,
                          onOpenDetail: (v) => _openExpenseDetail(context, v),
                          onMarkPaid: (v) => _markBillPaid(context, v),
                          onShowReceipt: (v) => _showReceiptPreview(context, v),
                          onConfirmReverse: (v) => _confirmReverse(
                            context: context,
                            title: l10n.cashbookReverseExpenseTitle,
                            summaryText:
                                '${v.expense.title} • ${MoneyFormatter.formatPaise(v.expense.amountPaise)}',
                            onConfirmed: (reason) => cubit.reverseExpense(
                              expenseId: v.expense.id,
                              reason: reason,
                              transactionAtUtcMillis:
                                  IstDateTimeHelper.nowUtcMillis(),
                            ),
                          ),
                        )
                      else
                        _PendingBillsTab(
                          pendingBills: summary.pendingBills,
                          searchQuery: state.searchQuery,
                          onOpenDetail: (v) => _openExpenseDetail(context, v),
                          onMarkPaid: (v) => _markBillPaid(context, v),
                        ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

(String, AppStatusTone) _expenseStatusBadge(
  AppLocalizations l10n,
  WorkshopExpenseView view,
) {
  if (view.isReversed) {
    return (l10n.dispatchReversedBadge, AppStatusTone.neutral);
  }
  if (view.isFullySettled) {
    return (l10n.cashbookExpensePaidBadge, AppStatusTone.good);
  }
  if (view.settledPaise > 0) {
    return (l10n.cashbookExpensePartialBadge, AppStatusTone.info);
  }
  return (l10n.cashbookExpenseUnpaidBadge, AppStatusTone.pending);
}

bool _matchesExpenseQuery(
  AppLocalizations l10n,
  WorkshopExpenseView view,
  String rawQuery,
) {
  final q = rawQuery.trim().toLowerCase();
  if (q.isEmpty) return true;
  final e = view.expense;
  final catLabel = DomainLabelLocalizer.expenseCategory(l10n, e.category);
  return _anyContains(q, [
    e.title,
    e.payeeName,
    e.referenceNo,
    e.notes,
    catLabel,
  ]);
}

bool _matchesTimelineQuery(
  AppLocalizations l10n,
  CashbookTimelineItem item,
  String rawQuery,
) {
  final q = rawQuery.trim().toLowerCase();
  if (q.isEmpty) return true;
  final typeLabel = item.cashbookEntry != null
      ? DomainLabelLocalizer.cashbookEntryType(
          l10n,
          item.cashbookEntry!.entryType,
        )
      : item.expenseView != null
      ? DomainLabelLocalizer.expenseCategory(
          l10n,
          item.expenseView!.expense.category,
        )
      : null;
  return _anyContains(q, [
    item.title,
    item.subtitle,
    typeLabel,
    item.cashbookEntry?.referenceNo,
    item.cashbookEntry?.notes,
    item.expenseView?.expense.referenceNo,
    item.expenseView?.expense.notes,
    DomainLabelLocalizer.paymentMode(l10n, item.paymentMode),
  ]);
}

bool _anyContains(String lowerQuery, List<String?> candidates) {
  for (final c in candidates) {
    if (c != null && c.toLowerCase().contains(lowerQuery)) {
      return true;
    }
  }
  return false;
}

final class _AllCashbookTab extends StatelessWidget {
  const _AllCashbookTab({
    required this.summary,
    required this.state,
    required this.onOpenExpenseDetail,
    required this.onConfirmReverseEntry,
    required this.onConfirmReverseExpense,
  });

  final CashbookSummary summary;
  final CashbookState state;
  final ValueChanged<WorkshopExpenseView> onOpenExpenseDetail;
  final ValueChanged<CashbookEntryEntity> onConfirmReverseEntry;
  final ValueChanged<WorkshopExpenseView> onConfirmReverseExpense;

  String _itemTitle(BuildContext context, CashbookTimelineItem item) {
    final l10n = context.l10n;
    if (item.source == CashbookTimelineSource.cashbookEntry &&
        item.cashbookEntry != null) {
      final typeLabel = DomainLabelLocalizer.cashbookEntryType(
        l10n,
        item.cashbookEntry!.entryType,
      );
      if (item.title == item.cashbookEntry!.entryType.dbValue) {
        return typeLabel;
      }
      return '$typeLabel • ${item.title}';
    }
    if (item.source == CashbookTimelineSource.workerPayment) {
      return '${l10n.cashbookSourceWorkerPayment} • ${item.title}';
    }
    if (item.source == CashbookTimelineSource.partyPayment) {
      return '${l10n.cashbookSourcePartyReceipt} • ${item.title}';
    }
    return item.title;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CashbookCubit>();

    final filtered = summary.timeline.where((item) {
      if (state.bucketFilter != null &&
          item.accountBucket != CashbookAccountBucket.both &&
          item.accountBucket != state.bucketFilter) {
        return false;
      }
      if (state.sourceFilter != null && item.source != state.sourceFilter) {
        return false;
      }
      if (!_matchesTimelineQuery(l10n, item, state.searchQuery)) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppChipGroup<CashbookAccountBucket?>(
          items: const [
            null,
            CashbookAccountBucket.cash,
            CashbookAccountBucket.bank,
          ],
          value: state.bucketFilter,
          onChanged: cubit.setBucketFilter,
          itemLabelBuilder: (b) => switch (b) {
            null => l10n.cashbookFilterAllBuckets,
            CashbookAccountBucket.cash => l10n.cashbookFilterCash,
            CashbookAccountBucket.bank ||
            CashbookAccountBucket.both => l10n.cashbookFilterBank,
          },
        ),
        const AppGap.xs(),
        AppChipGroup<CashbookTimelineSource?>(
          scrollable: true,
          items: const [
            null,
            CashbookTimelineSource.workshopExpense,
            CashbookTimelineSource.workerPayment,
            CashbookTimelineSource.partyPayment,
            CashbookTimelineSource.cashbookEntry,
          ],
          value: state.sourceFilter,
          onChanged: cubit.setSourceFilter,
          itemLabelBuilder: (s) => switch (s) {
            null => l10n.cashbookFilterAllSources,
            CashbookTimelineSource.workshopExpense => l10n.cashbookSourceExpense,
            CashbookTimelineSource.workerPayment =>
              l10n.cashbookSourceWorkerPayment,
            CashbookTimelineSource.partyPayment =>
              l10n.cashbookSourcePartyReceipt,
            CashbookTimelineSource.cashbookEntry =>
              l10n.cashbookSourceTransfer,
          },
        ),
        const AppGap.md(),
        if (filtered.isEmpty)
          AppEmptyState(
            icon: AppIcons.cashbook,
            title: l10n.cashbookEmptyTitle,
            subtitle: l10n.cashbookEmptySubtitle,
          )
        else
          AppLazySection<CashbookTimelineItem>(
            items: filtered,
            initialCount: 25,
            itemBuilder: (context, item, index) {
              final netDelta = item.cashDeltaPaise + item.bankDeltaPaise;
              final isTransfer =
                  item.accountBucket == CashbookAccountBucket.both;
              final tone = (item.isReversed || item.isReversal)
                  ? AppStatusTone.neutral
                  : isTransfer
                  ? AppStatusTone.info
                  : netDelta >= 0
                  ? AppStatusTone.good
                  : AppStatusTone.damaged;
              final amountPrefix = isTransfer
                  ? ''
                  : item.isReversal
                  ? (netDelta == 0 ? '' : (netDelta > 0 ? '+' : '-'))
                  : (netDelta >= 0 ? '+' : '-');
              final canReverseEntry =
                  !item.isReversed &&
                  !item.isReversal &&
                  item.cashbookEntry != null &&
                  item.cashbookEntry!.entryType !=
                      CashbookEntryType.openingCash &&
                  item.cashbookEntry!.entryType !=
                      CashbookEntryType.openingBank &&
                  PermissionGate.hasPermission(
                    context,
                    AppPermission.recordNonCashExpenseAndTransfers,
                  );
              final canReverseExp =
                  !item.isReversed &&
                  !item.isReversal &&
                  item.expenseView != null &&
                  PermissionGate.hasPermission(
                    context,
                    AppPermission.recordNonCashExpenseAndTransfers,
                  );
              final subtitleText =
                  '${AppDateTimeFormatter.formatDateTime(item.transactionAt)} • ${DomainLabelLocalizer.paymentMode(l10n, item.paymentMode)}'
                  '${item.subtitle != null && item.subtitle!.isNotEmpty ? ' • ${item.subtitle}' : ''}';

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: AppCard.listItem(
                  onTap: item.expenseView != null
                      ? () => onOpenExpenseDetail(item.expenseView!)
                      : null,
                  child: AppActionRow(
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppText(
                          _itemTitle(context, item),
                          fontWeight: FontWeight.w700,
                        ),
                        AppText(
                          subtitleText,
                          variant: AppTextVariant.bodySmall,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                    actions: [
                      AppStatusBadge(
                        label:
                            '$amountPrefix${MoneyFormatter.formatPaise(item.grossAmountPaise)}',
                        tone: tone,
                      ),
                      if (item.isReversed || item.isReversal)
                        AppStatusBadge(
                          label: l10n.dispatchReversedBadge,
                          tone: AppStatusTone.neutral,
                        ),
                      if (canReverseEntry)
                        AppIconButton(
                          icon: AppIcons.reverse,
                          tooltip: l10n.stockReverseAction,
                          onPressed: () =>
                              onConfirmReverseEntry(item.cashbookEntry!),
                        ),
                      if (canReverseExp)
                        AppIconButton(
                          icon: AppIcons.reverse,
                          tooltip: l10n.stockReverseAction,
                          onPressed: () =>
                              onConfirmReverseExpense(item.expenseView!),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

final class _ExpensesTab extends StatelessWidget {
  const _ExpensesTab({
    required this.summary,
    required this.state,
    required this.onOpenDetail,
    required this.onMarkPaid,
    required this.onShowReceipt,
    required this.onConfirmReverse,
  });

  final CashbookSummary summary;
  final CashbookState state;
  final ValueChanged<WorkshopExpenseView> onOpenDetail;
  final ValueChanged<WorkshopExpenseView> onMarkPaid;
  final ValueChanged<WorkshopExpenseView> onShowReceipt;
  final ValueChanged<WorkshopExpenseView> onConfirmReverse;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cubit = context.read<CashbookCubit>();

    final filtered = summary.expenses.where((v) {
      if (state.categoryFilter != null &&
          v.expense.category != state.categoryFilter) {
        return false;
      }
      if (!_matchesExpenseQuery(l10n, v, state.searchQuery)) {
        return false;
      }
      return true;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppChipGroup<ExpenseCategory?>(
          scrollable: true,
          items: const [null, ...ExpenseCategory.values],
          value: state.categoryFilter,
          onChanged: cubit.setCategoryFilter,
          itemLabelBuilder: (cat) => cat == null
              ? l10n.cashbookFilterAllBuckets
              : DomainLabelLocalizer.expenseCategory(l10n, cat),
        ),
        if (summary.categoryBreakdowns.isNotEmpty) ...[
          const AppGap.md(),
          AppHeading(
            l10n.cashbookCategoryBreakdownHeading,
            level: AppHeadingLevel.h3,
          ),
          const AppGap.xs(),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final b in summary.categoryBreakdowns)
                AppStatusBadge(
                  label:
                      '${DomainLabelLocalizer.expenseCategory(l10n, b.category)}: ${MoneyFormatter.formatPaise(b.totalPaise)}',
                  tone: b.unpaidPaise > 0
                      ? AppStatusTone.pending
                      : AppStatusTone.neutral,
                ),
            ],
          ),
        ],
        const AppGap.md(),
        if (filtered.isEmpty)
          AppEmptyState(
            icon: AppIcons.expense,
            title: l10n.cashbookEmptyTitle,
            subtitle: l10n.cashbookEmptySubtitle,
          )
        else
          AppLazySection<WorkshopExpenseView>(
            items: filtered,
            initialCount: 25,
            itemBuilder: (context, view, index) {
              final e = view.expense;
              final (statusLabel, statusTone) = _expenseStatusBadge(l10n, view);
              final isPartial =
                  !view.isReversed &&
                  view.settledPaise > 0 &&
                  view.remainingUnpaidPaise > 0;
              final subtitleParts = <String>[
                DomainLabelLocalizer.expenseCategory(l10n, e.category),
                AppDateTimeFormatter.formatDateTime(e.transactionAt),
                if (e.payeeName != null && e.payeeName!.isNotEmpty)
                  e.payeeName!,
                if (e.paymentMode != null)
                  DomainLabelLocalizer.paymentMode(l10n, e.paymentMode!),
                if (isPartial)
                  l10n.cashbookExpenseSettledValue(
                    MoneyFormatter.formatPaise(view.settledPaise),
                    MoneyFormatter.formatPaise(e.amountPaise),
                  ),
              ];
              final canAct = PermissionGate.hasPermission(
                context,
                AppPermission.recordNonCashExpenseAndTransfers,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: AppCard.listItem(
                  onTap: () => onOpenDetail(view),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppActionRow(
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppText(e.title, fontWeight: FontWeight.w700),
                            AppText(
                              subtitleParts.join(' • '),
                              variant: AppTextVariant.bodySmall,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        actions: [
                          AppStatusBadge(
                            label: MoneyFormatter.formatPaise(e.amountPaise),
                            tone: AppStatusTone.neutral,
                          ),
                          AppStatusBadge(label: statusLabel, tone: statusTone),
                        ],
                      ),
                      if (view.hasReceiptAttachment ||
                          (!view.isReversed && canAct)) ...[
                        const AppGap.xs(),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            if (view.hasReceiptAttachment)
                              AppButton(
                                label: l10n.cashbookExpenseHasReceiptBadge,
                                icon: AppIcons.gallery,
                                variant: AppButtonVariant.text,
                                onPressed: () => onShowReceipt(view),
                              ),
                            if (!view.isReversed &&
                                !view.isFullySettled &&
                                canAct)
                              AppButton(
                                label: l10n.cashbookMarkPaidAction,
                                icon: AppIcons.confirm,
                                variant: AppButtonVariant.outlined,
                                onPressed: () => onMarkPaid(view),
                              ),
                            if (!view.isReversed && canAct)
                              AppButton(
                                label: l10n.stockReverseAction,
                                icon: AppIcons.reverse,
                                variant: AppButtonVariant.text,
                                onPressed: () => onConfirmReverse(view),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

final class _PendingBillsTab extends StatelessWidget {
  const _PendingBillsTab({
    required this.pendingBills,
    required this.searchQuery,
    required this.onOpenDetail,
    required this.onMarkPaid,
  });

  final List<WorkshopExpenseView> pendingBills;
  final String searchQuery;
  final ValueChanged<WorkshopExpenseView> onOpenDetail;
  final ValueChanged<WorkshopExpenseView> onMarkPaid;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filtered = pendingBills
        .where((v) => _matchesExpenseQuery(l10n, v, searchQuery))
        .toList();

    if (filtered.isEmpty) {
      return AppEmptyState(
        icon: AppIcons.confirm,
        title: l10n.cashbookPendingBillsEmptyTitle,
        subtitle: l10n.cashbookPendingBillsEmptySubtitle,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final view in filtered)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: AppCard.listItem(
              onTap: () => onOpenDetail(view),
              child: AppActionRow(
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(view.expense.title, fontWeight: FontWeight.w700),
                    AppText(
                      '${DomainLabelLocalizer.expenseCategory(l10n, view.expense.category)} • ${AppDateTimeFormatter.formatDateTime(view.expense.transactionAt)}'
                      '${view.expense.payeeName != null ? ' • ${view.expense.payeeName}' : ''}'
                      '${view.settledPaise > 0 ? ' • ${l10n.cashbookExpenseSettledValue(MoneyFormatter.formatPaise(view.settledPaise), MoneyFormatter.formatPaise(view.expense.amountPaise))}' : ''}',
                      variant: AppTextVariant.bodySmall,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                actions: [
                  if (view.settledPaise > 0)
                    AppStatusBadge(
                      label: l10n.cashbookExpensePartialBadge,
                      tone: AppStatusTone.info,
                    ),
                  AppStatusBadge(
                    label: MoneyFormatter.formatPaise(
                      view.remainingUnpaidPaise,
                    ),
                    tone: AppStatusTone.pending,
                  ),
                  PermissionGate(
                    permission: AppPermission.recordNonCashExpenseAndTransfers,
                    child: AppButton(
                      label: l10n.cashbookMarkPaidAction,
                      icon: AppIcons.confirm,
                      variant: AppButtonVariant.primary,
                      onPressed: () => onMarkPaid(view),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

final class _MarkBillPaidDialog extends StatefulWidget {
  const _MarkBillPaidDialog({required this.view});

  final WorkshopExpenseView view;

  @override
  State<_MarkBillPaidDialog> createState() => _MarkBillPaidDialogState();
}

final class _MarkBillPaidDialogState extends State<_MarkBillPaidDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  final _refCtrl = TextEditingController();
  PaymentMode _selectedMode = PaymentMode.cash;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
      text: MoneyFormatter.formatPaiseForInput(
        widget.view.remainingUnpaidPaise,
      ),
    );
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final view = widget.view;
    return AppDialog(
      title: l10n.cashbookMarkPaidTitle,
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText(
              '${view.expense.title} • ${l10n.cashbookRemainingDueLabel}: ${MoneyFormatter.formatPaise(view.remainingUnpaidPaise)}',
              fontWeight: FontWeight.w700,
            ),
            const AppGap.sm(),
            AppTextField(
              controller: _amountCtrl,
              label: l10n.cashbookSettlementAmountLabel,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [AppInputFormatters.currencyDecimal],
              validator: (v) {
                final parsed = AppValidators.parseRupeesToPaiseExact(v);
                if (!parsed.validation.isValid ||
                    parsed.paise == null ||
                    parsed.paise! <= 0) {
                  return ValidationLocalizer.localize(l10n, parsed.validation);
                }
                if (parsed.paise! > view.remainingUnpaidPaise) {
                  return l10n.cashbookSettlementExceedsError;
                }
                return null;
              },
            ),
            const AppGap.sm(),
            AppDropdown<PaymentMode>(
              label: l10n.accountingPaymentModeLabel,
              value: _selectedMode,
              items: const [
                PaymentMode.cash,
                PaymentMode.upi,
                PaymentMode.bankTransfer,
                PaymentMode.cheque,
              ],
              itemLabelBuilder: (m) => DomainLabelLocalizer.paymentMode(l10n, m),
              onChanged: (v) {
                if (v != null) setState(() => _selectedMode = v);
              },
            ),
            const AppGap.sm(),
            AppTextField(
              controller: _refCtrl,
              label: l10n.accountingReferenceLabel,
            ),
          ],
        ),
      ),
      confirmLabel: l10n.cashbookMarkPaidAction,
      cancelLabel: l10n.actionCancel,
      onConfirm: () {
        if (!(_formKey.currentState?.validate() ?? false)) return;
        final parsed = AppValidators.parseRupeesToPaiseExact(_amountCtrl.text);
        if (!parsed.validation.isValid ||
            parsed.paise == null ||
            parsed.paise! <= 0) {
          return;
        }
        Navigator.of(context).pop((
          amountPaise: parsed.paise!,
          mode: _selectedMode,
          referenceNo: _refCtrl.text,
        ));
      },
    );
  }
}

final class _ReverseReasonDialog extends StatefulWidget {
  const _ReverseReasonDialog({
    required this.title,
    required this.summaryText,
  });

  final String title;
  final String summaryText;

  @override
  State<_ReverseReasonDialog> createState() => _ReverseReasonDialogState();
}

final class _ReverseReasonDialogState extends State<_ReverseReasonDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AppDialog(
      title: widget.title,
      icon: AppIcons.warning,
      isDestructive: true,
      confirmLabel: l10n.stockReverseAction,
      cancelLabel: l10n.actionCancel,
      onConfirm: () {
        if (!(_formKey.currentState?.validate() ?? false)) return;
        Navigator.of(context).pop(_reasonCtrl.text.trim());
      },
      content: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppText(widget.summaryText, fontWeight: FontWeight.w600),
            const AppGap.sm(),
            AppTextField(
              controller: _reasonCtrl,
              label: l10n.stockReverseReasonLabel,
              maxLines: 2,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? l10n.validationRequired
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
