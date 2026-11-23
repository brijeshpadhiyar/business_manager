import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
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
      builder: (ctx) => AlertDialog(
        title: Text(l10n.accountingReversePaymentTitle),
        content: Form(
          key: formKey,
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
        actions: [
          AppButton(
            label: l10n.actionCancel,
            variant: AppButtonVariant.text,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          AppButton(
            label: l10n.stockReverseAction,
            variant: AppButtonVariant.destructive,
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.of(ctx).pop(true);
              }
            },
          ),
        ],
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
    } catch (e) {
      if (mounted) AppFeedback.showError(context, e.toString());
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

    return AppScaffold(
      title: l10n.accountingHeading,
      actions: [
        AppIconButton(
          icon: Icons.refresh_rounded,
          tooltip: l10n.actionRetry,
          onPressed: () => context.read<AccountingOverviewCubit>().load(),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openRecordPayment,
        icon: const Icon(Icons.payments_outlined),
        label: Text(l10n.accountingRecordPaymentAction),
      ),
      padding: EdgeInsets.zero,
      body: BlocBuilder<AccountingOverviewCubit, AccountingOverviewState>(
        builder: (context, state) {
          if (state.status == AccountingOverviewStatus.initial ||
              state.status == AccountingOverviewStatus.loading) {
            return const AppSkeletonList(itemCount: 5);
          }
          if (state.status == AccountingOverviewStatus.error) {
            return AppErrorView(
              title: l10n.errorUnexpected,
              message: state.errorMessage,
              retryLabel: l10n.actionRetry,
              onRetry: () => context.read<AccountingOverviewCubit>().load(),
            );
          }

          final totalEarned = state.workerSummaries.fold<int>(
            0,
            (s, w) => s + w.earnedLabourPaise,
          );
          final totalOutstanding = state.workerSummaries.fold<int>(
            0,
            (s, w) => s + w.outstandingPayablePaise,
          );
          final totalAdvanceCredit = state.workerSummaries.fold<int>(
            0,
            (s, w) => s + w.advanceCreditBalancePaise,
          );
          final totalPaid = state.workerSummaries.fold<int>(
            0,
            (s, w) => s + w.netPaidToWorkerPaise,
          );

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              96,
            ),
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 680;
                  final w = isWide
                      ? (constraints.maxWidth - AppSpacing.sm * 3) / 4
                      : (constraints.maxWidth - AppSpacing.sm) / 2;
                  return Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      SizedBox(
                        width: w,
                        child: AppMetricTile(
                          label: l10n.accountingEarnedLabourLabel,
                          value: totalEarned,
                          isCurrencyPaise: true,
                          icon: Icons.work_outline_rounded,
                          tone: AppStatusTone.good,
                        ),
                      ),
                      SizedBox(
                        width: w,
                        child: AppMetricTile(
                          label: l10n.accountingOutstandingPayableLabel,
                          value: totalOutstanding,
                          isCurrencyPaise: true,
                          icon: Icons.account_balance_wallet_outlined,
                          tone: totalOutstanding > 0
                              ? AppStatusTone.pending
                              : AppStatusTone.good,
                        ),
                      ),
                      SizedBox(
                        width: w,
                        child: AppMetricTile(
                          label: l10n.accountingAdvanceCreditLabel,
                          value: totalAdvanceCredit,
                          isCurrencyPaise: true,
                          icon: Icons.trending_up_rounded,
                          tone: AppStatusTone.info,
                        ),
                      ),
                      SizedBox(
                        width: w,
                        child: AppMetricTile(
                          label: l10n.accountingRegularPaidLabel,
                          value: totalPaid,
                          isCurrencyPaise: true,
                          icon: Icons.payments_outlined,
                          tone: AppStatusTone.neutral,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppText(
                l10n.accountingAdvanceNote,
                variant: AppTextVariant.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              SegmentedButton<int>(
                segments: [
                  ButtonSegment(
                    value: 0,
                    label: Text(l10n.accountingTabWorkers),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text(l10n.accountingTabPayments),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: Text(l10n.accountingTabLabour),
                  ),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => setState(() => _tab = s.first),
              ),
              const SizedBox(height: AppSpacing.md),
              switch (_tab) {
                0 => _buildWorkerBalances(context, state),
                1 => _buildPaymentsList(
                  context,
                  state.recentPayments,
                  localeCode,
                ),
                _ => _buildLabourList(context, state.labourEntries, localeCode),
              },
            ],
          );
        },
      ),
    );
  }

  Widget _buildWorkerBalances(
    BuildContext context,
    AccountingOverviewState state,
  ) {
    final l10n = context.l10n;
    final items = state.filteredSummaries;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: _searchCtrl,
          label: l10n.workersSearchHint,
          prefixIcon: Icons.search_rounded,
          onChanged: (q) =>
              context.read<AccountingOverviewCubit>().updateSearch(q),
        ),
        const SizedBox(height: AppSpacing.md),
        if (items.isEmpty)
          AppEmptyState(
            icon: Icons.people_outline_rounded,
            title: l10n.workersEmptyTitle,
            subtitle: l10n.workersEmptySubtitle,
          )
        else
          for (int i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppMotionEntrance(
                index: i,
                child: AppCard(
                  onTap: () => _openWorkerLedger(items[i].workerId),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  items[i].workerName,
                                  variant: AppTextVariant.bodyLarge,
                                  fontWeight: FontWeight.w700,
                                ),
                                if (items[i].workerPhone != null)
                                  AppText(
                                    items[i].workerPhone!,
                                    variant: AppTextVariant.bodySmall,
                                  ),
                              ],
                            ),
                          ),
                          if (items[i].outstandingPayablePaise > 0)
                            AppStatusBadge(
                              label:
                                  '${l10n.accountingOutstandingPayableLabel}: ${MoneyFormatter.formatPaise(items[i].outstandingPayablePaise)}',
                              tone: AppStatusTone.pending,
                            )
                          else if (items[i].advanceCreditBalancePaise > 0)
                            AppStatusBadge(
                              label:
                                  '${l10n.accountingAdvanceCreditLabel}: ${MoneyFormatter.formatPaise(items[i].advanceCreditBalancePaise)}',
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
                            '${l10n.accountingEarnedLabourLabel}: ${MoneyFormatter.formatPaise(items[i].earnedLabourPaise)}',
                            variant: AppTextVariant.numeric,
                          ),
                          AppText(
                            '${l10n.accountingAdvancePaidLabel}: ${MoneyFormatter.formatPaise(items[i].advancePaymentsPaise)}',
                            variant: AppTextVariant.numeric,
                          ),
                          AppText(
                            '${l10n.accountingRegularPaidLabel}: ${MoneyFormatter.formatPaise(items[i].regularPaymentsPaise)}',
                            variant: AppTextVariant.numeric,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          AppButton(
                            label: l10n.accountingOpenLedgerAction,
                            variant: AppButtonVariant.outlined,
                            onPressed: () =>
                                _openWorkerLedger(items[i].workerId),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AppButton(
                            label: l10n.accountingRecordPaymentAction,
                            variant: AppButtonVariant.secondary,
                            onPressed: () =>
                                _openRecordPayment(workerId: items[i].workerId),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildPaymentsList(
    BuildContext context,
    List<PaymentView> payments,
    String localeCode,
  ) {
    final l10n = context.l10n;
    if (payments.isEmpty) {
      return AppEmptyState(
        icon: Icons.payments_outlined,
        title: l10n.accountingEmptyLedgerTitle,
        subtitle: l10n.accountingEmptyLedgerSubtitle,
        actionLabel: l10n.accountingRecordPaymentAction,
        onAction: _openRecordPayment,
      );
    }

    return Column(
      children: [
        for (final view in payments)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      AppStatusBadge(
                        label: _paymentTypeLabel(
                          context,
                          view.payment.paymentType,
                        ),
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
                      'Ref: ${view.payment.referenceNo!}',
                      variant: AppTextVariant.bodySmall,
                    ),
                  if (view.payment.reason != null)
                    AppText(
                      view.payment.reason!,
                      variant: AppTextVariant.bodySmall,
                    ),
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
            ),
          ),
      ],
    );
  }

  Widget _buildLabourList(
    BuildContext context,
    List<LabourEntryView> entries,
    String localeCode,
  ) {
    final l10n = context.l10n;
    if (entries.isEmpty) {
      return AppEmptyState(
        icon: Icons.work_history_outlined,
        title: l10n.accountingEmptyLedgerTitle,
        subtitle: l10n.accountingEmptyLedgerSubtitle,
      );
    }

    return Column(
      children: [
        for (final view in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppStatusBadge(
                              label: view.entry.isPayable
                                  ? l10n.accountingPayableBadge
                                  : l10n.accountingInfoBadge,
                              tone: view.entry.isPayable
                                  ? AppStatusTone.good
                                  : AppStatusTone.neutral,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            AppStatusBadge(
                              label: view.entry.basisType.dbValue,
                              tone:
                                  view.entry.basisType ==
                                      LabourBasisType.reversal
                                  ? AppStatusTone.damaged
                                  : AppStatusTone.info,
                            ),
                            if (view.isReversed) ...[
                              const SizedBox(width: AppSpacing.xs),
                              AppStatusBadge(
                                label: l10n.stockReversedBadge,
                                tone: AppStatusTone.neutral,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppText(
                          '${view.workerName} • ${view.processName} • Lot ${view.lotNumber}',
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
            ),
          ),
      ],
    );
  }
}
