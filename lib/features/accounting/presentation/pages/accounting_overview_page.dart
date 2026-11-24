import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/domain_label_localizer.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/accounting/domain/repositories/accounting_repository.dart';
import 'package:business_manager/features/accounting/presentation/bloc/accounting_overview_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

final class AccountingOverviewPage extends StatelessWidget {
  const AccountingOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AccountingOverviewCubit>(
      create: (_) => getIt<AccountingOverviewCubit>()..load(),
      child: const _AccountingOverviewView(),
    );
  }
}

final class _AccountingOverviewView extends StatefulWidget {
  const _AccountingOverviewView();

  @override
  State<_AccountingOverviewView> createState() =>
      _AccountingOverviewViewState();
}

final class _AccountingOverviewViewState
    extends State<_AccountingOverviewView> {
  int _tab = 0;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openRecordPayment({String? workerId}) async {
    final saved = await context.push<bool>(
      RoutePaths.paymentCreate(workerId: workerId),
    );
    if (saved == true && mounted) {
      await context.read<AccountingOverviewCubit>().load();
    }
  }

  Future<void> _openWorkerLedger(String workerId) async {
    await context.push(RoutePaths.workerLedger(workerId));
    if (mounted) {
      await context.read<AccountingOverviewCubit>().load();
    }
  }

  Future<void> _confirmReversePayment(PaymentView view) async {
    final l10n = context.l10n;
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await AppDialog.showCustom<bool>(
      context,
      builder: (ctx) => AppDialog(
        title: l10n.accountingReversePaymentTitle,
        icon: Icons.warning_amber_rounded,
        isDestructive: true,
        cancelLabel: l10n.actionCancel,
        confirmLabel: l10n.stockReverseAction,
        onConfirm: () {
          if (formKey.currentState?.validate() ?? false) {
            Navigator.of(ctx).pop(true);
          }
        },
        content: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                '${view.workerName} • ${MoneyFormatter.formatPaise(view.payment.amountPaise)}',
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: reasonCtrl,
                label: l10n.stockReverseReasonLabel,
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.validationRequired
                    : null,
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) {
      reasonCtrl.dispose();
      return;
    }

    try {
      await getIt<AccountingRepository>().reversePayment(
        paymentId: view.payment.id,
        reason: reasonCtrl.text,
        transactionAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
      );
      if (mounted) {
        AppFeedback.showSuccess(context, l10n.accountingReversePaymentSuccess);
        await context.read<AccountingOverviewCubit>().load();
      }
    } catch (_) {
      if (mounted) AppFeedback.showError(context, l10n.errorUnexpected);
    } finally {
      reasonCtrl.dispose();
    }
  }

  String _paymentTypeLabel(BuildContext context, PaymentType t) {
    final l10n = context.l10n;
    return switch (t) {
      PaymentType.regular => l10n.accountingPaymentTypeRegular,
      PaymentType.advance => l10n.accountingPaymentTypeAdvance,
      PaymentType.advanceRefund => l10n.accountingPaymentTypeRefund,
      PaymentType.reversal => l10n.stockTypeReversal,
    };
  }

  String _paymentModeLabel(BuildContext context, PaymentMode m) {
    final l10n = context.l10n;
    return switch (m) {
      PaymentMode.cash => l10n.accountingModeCash,
      PaymentMode.upi => l10n.accountingModeUpi,
      PaymentMode.bankTransfer => l10n.accountingModeBank,
      PaymentMode.cheque => l10n.accountingModeCheque,
      PaymentMode.other => l10n.accountingModeOther,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    return BlocBuilder<AccountingOverviewCubit, AccountingOverviewState>(
      builder: (context, state) {
        final totalEarned = state.totalEarnedPaise;
        final totalOutstanding = state.totalOutstandingPaise;
        final totalAdvanceCredit = state.totalAdvanceCreditPaise;
        final totalPaid = state.totalPaidPaise;

        final List<Widget> slivers;
        if (state.status == AccountingOverviewStatus.initial ||
            state.status == AccountingOverviewStatus.loading) {
          slivers = const [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: AppLoader(),
              ),
            ),
          ];
        } else if (state.status == AccountingOverviewStatus.error) {
          slivers = [
            SliverToBoxAdapter(
              child: AppErrorView(
                title: l10n.errorUnexpected,
                message: state.errorMessage,
                retryLabel: l10n.actionRetry,
                onRetry: () => context.read<AccountingOverviewCubit>().load(),
              ),
            ),
          ];
        } else {
          slivers = [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (totalAdvanceCredit > 0) ...[
                      AppMetricTile(
                        label: l10n.accountingAdvanceCreditLabel,
                        value: totalAdvanceCredit,
                        isCurrencyPaise: true,
                        icon: Icons.trending_up_rounded,
                        tone: AppStatusTone.info,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    AppText(
                      l10n.accountingAdvanceNote,
                      variant: AppTextVariant.bodySmall,
                    ),
                    if (_tab == 0) ...[
                      const SizedBox(height: AppSpacing.md),
                      AppSearchField(
                        controller: _searchCtrl,
                        label: l10n.workersSearchHint,
                        debounceDuration: const Duration(milliseconds: 160),
                        onChanged: (q) => context
                            .read<AccountingOverviewCubit>()
                            .updateSearch(q),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                96,
              ),
              sliver: switch (_tab) {
                0 => _buildWorkerBalancesSliver(context, state),
                1 => _buildPaymentsSliver(
                  context,
                  state.recentPayments,
                  localeCode,
                ),
                _ => _buildLabourSliver(
                  context,
                  state.labourEntries,
                  localeCode,
                ),
              },
            ),
          ];
        }

        return AppScaffold(
          scrollMode: AppScrollMode.collapsible,
          contentWidth: AppContentWidth.wide,
          onRefresh: () => context.read<AccountingOverviewCubit>().load(),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openRecordPayment,
            icon: const Icon(Icons.payments_outlined),
            label: Text(l10n.accountingRecordPaymentAction),
          ),
          header: AppCollapsibleHeader(
            title: l10n.accountingHeading,
            expandedHeight: 176,
            actions: [
              AppIconButton(
                icon: Icons.refresh_rounded,
                tooltip: l10n.actionRetry,
                onPressed: () => context.read<AccountingOverviewCubit>().load(),
              ),
            ],
            summary: state.status == AccountingOverviewStatus.loaded
                ? AppSummaryStrip(
                    metrics: [
                      AppSummaryMetric(
                        label: l10n.accountingEarnedLabourLabel,
                        value: MoneyFormatter.formatPaise(totalEarned),
                        tone: AppStatusTone.good,
                      ),
                      AppSummaryMetric(
                        label: l10n.accountingOutstandingPayableLabel,
                        value: MoneyFormatter.formatPaise(totalOutstanding),
                        tone: totalOutstanding > 0
                            ? AppStatusTone.pending
                            : AppStatusTone.good,
                      ),
                      AppSummaryMetric(
                        label: l10n.accountingRegularPaidLabel,
                        value: MoneyFormatter.formatPaise(totalPaid),
                        tone: AppStatusTone.info,
                      ),
                    ],
                  )
                : null,
          ),
          pinnedHeaderHeight: 58,
          pinnedHeader: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(l10n.accountingTabWorkers),
                  selected: _tab == 0,
                  onSelected: (_) => setState(() => _tab = 0),
                ),
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(
                  label: Text(l10n.accountingTabPayments),
                  selected: _tab == 1,
                  onSelected: (_) => setState(() => _tab = 1),
                ),
                const SizedBox(width: AppSpacing.sm),
                ChoiceChip(
                  label: Text(l10n.accountingTabLabour),
                  selected: _tab == 2,
                  onSelected: (_) => setState(() => _tab = 2),
                ),
              ],
            ),
          ),
          slivers: slivers,
        );
      },
    );
  }

  Widget _buildWorkerBalancesSliver(
    BuildContext context,
    AccountingOverviewState state,
  ) {
    final l10n = context.l10n;
    final items = state.filteredSummaries;

    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: AppEmptyState(
          icon: Icons.people_outline_rounded,
          title: l10n.workersEmptyTitle,
          subtitle: l10n.workersEmptySubtitle,
        ),
      );
    }

    return SliverList.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final item = items[i];
        return AppCard.listItem(
          key: ValueKey<String>(item.workerId),
          onTap: () => _openWorkerLedger(item.workerId),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        item.workerName,
                        variant: AppTextVariant.bodyLarge,
                        fontWeight: FontWeight.w700,
                      ),
                      if (item.workerPhone != null)
                        AppText(
                          item.workerPhone!,
                          variant: AppTextVariant.bodySmall,
                        ),
                    ],
                  ),
                  if (item.outstandingPayablePaise > 0)
                    AppStatusBadge(
                      label:
                          '${l10n.accountingOutstandingPayableLabel}: ${MoneyFormatter.formatPaise(item.outstandingPayablePaise)}',
                      tone: AppStatusTone.pending,
                    )
                  else if (item.advanceCreditBalancePaise > 0)
                    AppStatusBadge(
                      label:
                          '${l10n.accountingAdvanceCreditLabel}: ${MoneyFormatter.formatPaise(item.advanceCreditBalancePaise)}',
                      tone: AppStatusTone.info,
                    )
                  else
                    AppStatusBadge(
                      label: MoneyFormatter.formatPaise(0),
                      tone: AppStatusTone.good,
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  AppText(
                    '${l10n.accountingEarnedLabourLabel}: ${MoneyFormatter.formatPaise(item.earnedLabourPaise)}',
                    variant: AppTextVariant.numeric,
                  ),
                  AppText(
                    '${l10n.accountingAdvancePaidLabel}: ${MoneyFormatter.formatPaise(item.advancePaymentsPaise)}',
                    variant: AppTextVariant.numeric,
                  ),
                  AppText(
                    '${l10n.accountingRegularPaidLabel}: ${MoneyFormatter.formatPaise(item.regularPaymentsPaise)}',
                    variant: AppTextVariant.numeric,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.end,
                children: [
                  AppButton(
                    label: l10n.accountingOpenLedgerAction,
                    variant: AppButtonVariant.outlined,
                    onPressed: () => _openWorkerLedger(item.workerId),
                  ),
                  AppButton(
                    label: l10n.accountingRecordPaymentAction,
                    variant: AppButtonVariant.secondary,
                    onPressed: () =>
                        _openRecordPayment(workerId: item.workerId),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaymentsSliver(
    BuildContext context,
    List<PaymentView> payments,
    String localeCode,
  ) {
    final l10n = context.l10n;
    if (payments.isEmpty) {
      return SliverToBoxAdapter(
        child: AppEmptyState(
          icon: Icons.payments_outlined,
          title: l10n.accountingEmptyLedgerTitle,
          subtitle: l10n.accountingEmptyLedgerSubtitle,
          actionLabel: l10n.accountingRecordPaymentAction,
          onAction: _openRecordPayment,
        ),
      );
    }

    return SliverList.separated(
      itemCount: payments.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final view = payments[i];
        return AppCard.listItem(
          key: ValueKey<String>(view.payment.id),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppStatusBadge(
                    label: _paymentTypeLabel(context, view.payment.paymentType),
                    tone: switch (view.payment.paymentType) {
                      PaymentType.advance => AppStatusTone.info,
                      PaymentType.regular => AppStatusTone.good,
                      PaymentType.advanceRefund => AppStatusTone.pending,
                      PaymentType.reversal => AppStatusTone.neutral,
                    },
                  ),
                  if (view.isReversed) ...[
                    const SizedBox(width: AppSpacing.xs),
                    AppStatusBadge(
                      label: l10n.stockReversedBadge,
                      tone: AppStatusTone.neutral,
                    ),
                  ],
                  const Spacer(),
                  AppText(
                    MoneyFormatter.formatPaise(view.payment.amountPaise),
                    variant: AppTextVariant.numeric,
                    fontWeight: FontWeight.w700,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              AppText(
                '${view.workerName} • ${_paymentModeLabel(context, view.payment.paymentMode)}',
                fontWeight: FontWeight.w600,
              ),
              if (view.payment.referenceNo != null)
                AppText(
                  '${l10n.refLabelShort}: ${view.payment.referenceNo!}',
                  variant: AppTextVariant.bodySmall,
                ),
              if (view.payment.reason != null)
                AppText(view.payment.reason!, variant: AppTextVariant.bodySmall),
              Row(
                children: [
                  Expanded(
                    child: AppText(
                      IstDateTimeHelper.formatIstDateTime(
                        view.payment.transactionAt,
                        locale: localeCode,
                      ),
                      variant: AppTextVariant.bodySmall,
                    ),
                  ),
                  if (!view.isReversed &&
                      view.payment.paymentType != PaymentType.reversal)
                    AppButton(
                      label: l10n.stockReverseAction,
                      variant: AppButtonVariant.text,
                      onPressed: () => _confirmReversePayment(view),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLabourSliver(
    BuildContext context,
    List<LabourEntryView> entries,
    String localeCode,
  ) {
    final l10n = context.l10n;
    if (entries.isEmpty) {
      return SliverToBoxAdapter(
        child: AppEmptyState(
          icon: Icons.work_history_outlined,
          title: l10n.accountingEmptyLedgerTitle,
          subtitle: l10n.accountingEmptyLedgerSubtitle,
        ),
      );
    }

    return SliverList.separated(
      itemCount: entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, i) {
        final view = entries[i];
        return AppCard.listItem(
          key: ValueKey<String>(view.entry.id),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        AppStatusBadge(
                          label: view.entry.isPayable
                              ? l10n.accountingPayableBadge
                              : l10n.accountingInfoBadge,
                          tone: view.entry.isPayable
                              ? AppStatusTone.good
                              : AppStatusTone.neutral,
                        ),
                        AppStatusBadge(
                          label: DomainLabelLocalizer.labourBasis(
                            l10n,
                            view.entry.basisType,
                          ),
                          tone: view.entry.basisType == LabourBasisType.reversal
                              ? AppStatusTone.damaged
                              : AppStatusTone.info,
                        ),
                        if (view.isReversed)
                          AppStatusBadge(
                            label: l10n.stockReversedBadge,
                            tone: AppStatusTone.neutral,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      '${view.workerName} • ${view.processName} • ${l10n.lotLabelShort} ${view.lotNumber}',
                      fontWeight: FontWeight.w600,
                    ),
                    AppText(
                      '${view.entry.quantity} ${l10n.piecesUnit} × ${MoneyFormatter.formatPaise(view.entry.ratePaise)} • ${IstDateTimeHelper.formatIstDateTime(view.entry.transactionAt, locale: localeCode)}',
                      variant: AppTextVariant.bodySmall,
                    ),
                  ],
                ),
              ),
              AppText(
                MoneyFormatter.formatPaise(view.entry.amountPaise),
                variant: AppTextVariant.numeric,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
        );
      },
    );
  }
}
