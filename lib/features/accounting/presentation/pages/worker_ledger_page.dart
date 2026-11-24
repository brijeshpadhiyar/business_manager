import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/accounting/domain/repositories/accounting_repository.dart';
import 'package:business_manager/features/accounting/presentation/bloc/worker_ledger_cubit.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Complete worker financial & stock ledger with date filtering,
/// transaction-type filtering, running balance (supporting negative advance
/// credit), transaction drill-down, and audited reversals.
final class WorkerLedgerPage extends StatelessWidget {
  const WorkerLedgerPage({super.key, required this.workerId});

  final String workerId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkerLedgerCubit>(
      create: (_) => getIt<WorkerLedgerCubit>()..loadLedger(workerId),
      child: _WorkerLedgerView(workerId: workerId),
    );
  }
}

enum _LedgerTypeFilter { all, earnings, payments, advances, adjustments }

final class _WorkerLedgerView extends StatefulWidget {
  const _WorkerLedgerView({required this.workerId});

  final String workerId;

  @override
  State<_WorkerLedgerView> createState() => _WorkerLedgerViewState();
}

final class _WorkerLedgerViewState extends State<_WorkerLedgerView> {
  _LedgerTypeFilter _typeFilter = _LedgerTypeFilter.all;

  String get workerId => widget.workerId;

  bool _matchesFilter(WorkerLedgerLine line) => switch (_typeFilter) {
    _LedgerTypeFilter.all => true,
    _LedgerTypeFilter.earnings =>
      line.kind == WorkerLedgerEntryKind.labourPayable ||
          line.kind == WorkerLedgerEntryKind.labourInformational ||
          line.kind == WorkerLedgerEntryKind.labourReversal,
    _LedgerTypeFilter.payments =>
      line.kind == WorkerLedgerEntryKind.regularPayment ||
          line.kind == WorkerLedgerEntryKind.paymentReversal,
    _LedgerTypeFilter.advances =>
      line.kind == WorkerLedgerEntryKind.advancePayment ||
          line.kind == WorkerLedgerEntryKind.advanceRefund,
    _LedgerTypeFilter.adjustments =>
      line.kind == WorkerLedgerEntryKind.adjustmentCredit ||
          line.kind == WorkerLedgerEntryKind.adjustmentDebit ||
          line.kind == WorkerLedgerEntryKind.adjustmentReversal,
  };

  ProductionTransactionKind _txKindForLine(WorkerLedgerLine line) =>
      switch (line.kind) {
        WorkerLedgerEntryKind.labourPayable ||
        WorkerLedgerEntryKind.labourInformational ||
        WorkerLedgerEntryKind.labourReversal =>
          ProductionTransactionKind.labourEntry,
        WorkerLedgerEntryKind.regularPayment ||
        WorkerLedgerEntryKind.advancePayment ||
        WorkerLedgerEntryKind.advanceRefund ||
        WorkerLedgerEntryKind.paymentReversal =>
          ProductionTransactionKind.payment,
        WorkerLedgerEntryKind.adjustmentCredit ||
        WorkerLedgerEntryKind.adjustmentDebit ||
        WorkerLedgerEntryKind.adjustmentReversal =>
          ProductionTransactionKind.adjustment,
      };

  Future<void> _reverseLine(BuildContext context, WorkerLedgerLine line) async {
    final l10n = context.l10n;
    final isPayment =
        line.kind == WorkerLedgerEntryKind.regularPayment ||
        line.kind == WorkerLedgerEntryKind.advancePayment ||
        line.kind == WorkerLedgerEntryKind.advanceRefund;
    final isAdj =
        line.kind == WorkerLedgerEntryKind.adjustmentCredit ||
        line.kind == WorkerLedgerEntryKind.adjustmentDebit;
    if (!isPayment && !isAdj) return;

    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await AppDialog.showCustom<bool>(
      context,
      builder: (ctx) => AppDialog(
        title: isPayment
            ? l10n.accountingReversePaymentTitle
            : l10n.accountingReverseAdjustmentTitle,
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
          child: AppTextField(
            controller: reasonCtrl,
            label: l10n.stockReverseReasonLabel,
            maxLines: 2,
            maxLength: ValidationLimits.maxNotesLength,
            validator: ValidationLocalizer.wrap(
              l10n,
              (v) => AppValidators.nameValidator(
                v,
                maxLength: ValidationLimits.maxNotesLength,
              ),
            ),
          ),
        ),
      ),
    );

    if (confirmed != true || !context.mounted) {
      reasonCtrl.dispose();
      return;
    }

    try {
      final repo = getIt<AccountingRepository>();
      if (isPayment) {
        await repo.reversePayment(
          paymentId: line.sourceEntityId,
          reason: reasonCtrl.text,
          transactionAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
        );
        if (context.mounted) {
          AppFeedback.showSuccess(
            context,
            l10n.accountingReversePaymentSuccess,
          );
        }
      } else {
        await repo.reverseAdjustment(
          adjustmentId: line.sourceEntityId,
          reason: reasonCtrl.text,
          transactionAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
        );
        if (context.mounted) {
          AppFeedback.showSuccess(
            context,
            l10n.accountingReverseAdjustmentSuccess,
          );
        }
      }
      if (context.mounted) {
        await context.read<WorkerLedgerCubit>().reload();
      }
    } on DomainValidationException catch (e) {
      if (context.mounted) {
        AppFeedback.showError(
          context,
          ValidationLocalizer.localizeDomainException(l10n, e),
        );
      }
    } catch (_) {
      if (context.mounted) AppFeedback.showError(context, l10n.errorUnexpected);
    } finally {
      reasonCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    return BlocBuilder<WorkerLedgerCubit, WorkerLedgerState>(
      builder: (context, state) {
        if (state.status == WorkerLedgerStatus.initial ||
            state.status == WorkerLedgerStatus.loading) {
          return AppScaffold(
            title: l10n.accountingLedgerHeading,
            body: const AppSkeletonList(),
          );
        }
        if (state.status == WorkerLedgerStatus.error || state.detail == null) {
          return AppScaffold(
            title: l10n.accountingLedgerHeading,
            body: AppErrorView(
              title: l10n.errorUnexpected,
              message: state.errorMessage,
              retryLabel: l10n.actionRetry,
              onRetry: () => context.read<WorkerLedgerCubit>().reload(),
            ),
          );
        }

        final detail = state.detail!;
        final summary = detail.summary;

        return AppScaffold(
          title: '${summary.workerName} — ${l10n.accountingLedgerHeading}',
          actions: [
            AppIconButton(
              icon: Icons.refresh_rounded,
              tooltip: l10n.actionRetry,
              onPressed: () => context.read<WorkerLedgerCubit>().reload(),
            ),
          ],
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Financial KPI Grid
                    LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 680;
                  final tileW = isWide
                      ? (constraints.maxWidth - AppSpacing.sm * 3) / 4
                      : (constraints.maxWidth - AppSpacing.sm) / 2;
                  return Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      SizedBox(
                        width: tileW,
                        child: AppMetricTile(
                          label: l10n.accountingEarnedLabourLabel,
                          value: summary.earnedLabourPaise,
                          isCurrencyPaise: true,
                          icon: Icons.work_outline_rounded,
                          tone: AppStatusTone.good,
                        ),
                      ),
                      SizedBox(
                        width: tileW,
                        child: AppMetricTile(
                          label: l10n.accountingAdvancePaidLabel,
                          value: summary.advancePaymentsPaise,
                          isCurrencyPaise: true,
                          icon: Icons.request_quote_outlined,
                          tone: AppStatusTone.info,
                        ),
                      ),
                      SizedBox(
                        width: tileW,
                        child: AppMetricTile(
                          label: l10n.accountingRegularPaidLabel,
                          value: summary.regularPaymentsPaise,
                          isCurrencyPaise: true,
                          icon: Icons.payments_outlined,
                          tone: AppStatusTone.neutral,
                        ),
                      ),
                      SizedBox(
                        width: tileW,
                        child: summary.advanceCreditBalancePaise > 0
                            ? AppMetricTile(
                                label: l10n.accountingAdvanceCreditLabel,
                                value: summary.advanceCreditBalancePaise,
                                isCurrencyPaise: true,
                                icon: Icons.trending_up_rounded,
                                tone: AppStatusTone.info,
                              )
                            : AppMetricTile(
                                label: l10n.accountingOutstandingPayableLabel,
                                value: summary.outstandingPayablePaise,
                                isCurrencyPaise: true,
                                icon: Icons.account_balance_wallet_outlined,
                                tone: summary.outstandingPayablePaise > 0
                                    ? AppStatusTone.pending
                                    : AppStatusTone.good,
                              ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton(
                    label: l10n.accountingRecordPaymentAction,
                    icon: Icons.payments_outlined,
                    onPressed: () async {
                      final saved = await context.push<bool>(
                        RoutePaths.paymentCreate(workerId: workerId),
                      );
                      if (saved == true && context.mounted) {
                        await context.read<WorkerLedgerCubit>().reload();
                      }
                    },
                  ),
                  AppButton(
                    label: l10n.accountingAddAdjustmentAction,
                    icon: Icons.tune_rounded,
                    variant: AppButtonVariant.secondary,
                    onPressed: () async {
                      final saved = await context.push<bool>(
                        RoutePaths.workerAdjustmentCreate(workerId),
                      );
                      if (saved == true && context.mounted) {
                        await context.read<WorkerLedgerCubit>().reload();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Stock summary bar
              AppCard(
                child: Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: [
                    AppStatusBadge(
                      label:
                          '${l10n.stockIssuedLabel}: ${detail.stockSummary.issued}',
                      tone: AppStatusTone.info,
                    ),
                    AppStatusBadge(
                      label:
                          '${l10n.stockGoodReturnedLabel}: ${detail.stockSummary.goodReturned}',
                      tone: AppStatusTone.good,
                    ),
                    AppStatusBadge(
                      label:
                          '${l10n.stockRemainingPendingLabel}: ${detail.stockSummary.pending}',
                      tone: detail.stockSummary.pending > 0
                          ? AppStatusTone.pending
                          : AppStatusTone.good,
                    ),
                    if (summary.netAdjustmentsPaise != 0)
                      AppStatusBadge(
                        label:
                            '${l10n.accountingAdjustmentsLabel}: ${MoneyFormatter.formatPaise(summary.netAdjustmentsPaise)}',
                        tone: AppStatusTone.neutral,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              // Date range filter
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppDatePicker(
                            label: l10n.accountingFromDateLabel,
                            selectedUtcMillis: state.fromUtcMillis,
                            onDateSelectedUtcMillis: (utc) {
                              final ist = IstDateTimeHelper.fromUtcMillisToIst(
                                utc,
                              );
                              final startOfDayUtc =
                                  IstDateTimeHelper.istDateTimeToUtcMillis(
                                    year: ist.year,
                                    month: ist.month,
                                    day: ist.day,
                                  );
                              context.read<WorkerLedgerCubit>().loadLedger(
                                workerId,
                                fromUtcMillis: startOfDayUtc,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: AppDatePicker(
                            label: l10n.accountingToDateLabel,
                            selectedUtcMillis: state.toUtcMillis,
                            errorText: state.dateRangeErrorCode != null
                                ? ValidationLocalizer.localizeDomainCode(
                                    l10n,
                                    state.dateRangeErrorCode!,
                                  )
                                : null,
                            onDateSelectedUtcMillis: (utc) {
                              final ist = IstDateTimeHelper.fromUtcMillisToIst(
                                utc,
                              );
                              final endOfDayUtc =
                                  IstDateTimeHelper.istDateTimeToUtcMillis(
                                    year: ist.year,
                                    month: ist.month,
                                    day: ist.day,
                                    hour: 23,
                                    minute: 59,
                                    second: 59,
                                  );
                              context.read<WorkerLedgerCubit>().loadLedger(
                                workerId,
                                toUtcMillis: endOfDayUtc,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    if (state.fromUtcMillis != null ||
                        state.toUtcMillis != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          AppText(
                            '${l10n.accountingOpeningBalanceLabel}: ${MoneyFormatter.formatPaise(detail.openingBalancePaise)}',
                            variant: AppTextVariant.numeric,
                            fontWeight: FontWeight.w600,
                          ),
                          AppButton(
                            label: l10n.accountingClearFilters,
                            variant: AppButtonVariant.text,
                            onPressed: () =>
                                context.read<WorkerLedgerCubit>().loadLedger(
                                  workerId,
                                  clearFrom: true,
                                  clearTo: true,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // Transaction-type filter chips (Phase 3 Worker Financial Ledger)
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  ChoiceChip(
                    label: Text(l10n.prodHistoryAllEntries),
                    selected: _typeFilter == _LedgerTypeFilter.all,
                    onSelected: (_) =>
                        setState(() => _typeFilter = _LedgerTypeFilter.all),
                  ),
                  ChoiceChip(
                    label: Text(l10n.accountingEarnedLabourLabel),
                    selected: _typeFilter == _LedgerTypeFilter.earnings,
                    onSelected: (_) => setState(
                      () => _typeFilter = _LedgerTypeFilter.earnings,
                    ),
                  ),
                  ChoiceChip(
                    label: Text(l10n.accountingPaymentTypeRegular),
                    selected: _typeFilter == _LedgerTypeFilter.payments,
                    onSelected: (_) => setState(
                      () => _typeFilter = _LedgerTypeFilter.payments,
                    ),
                  ),
                  ChoiceChip(
                    label: Text(l10n.accountingPaymentTypeAdvance),
                    selected: _typeFilter == _LedgerTypeFilter.advances,
                    onSelected: (_) => setState(
                      () => _typeFilter = _LedgerTypeFilter.advances,
                    ),
                  ),
                  ChoiceChip(
                    label: Text(l10n.accountingAdjustmentsLabel),
                    selected: _typeFilter == _LedgerTypeFilter.adjustments,
                    onSelected: (_) => setState(
                      () => _typeFilter = _LedgerTypeFilter.adjustments,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
              if (detail.lines.where(_matchesFilter).isEmpty)
                SliverToBoxAdapter(
                  child: AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: l10n.accountingEmptyLedgerTitle,
                    subtitle: l10n.accountingEmptyLedgerSubtitle,
                  ),
                )
              else
                Builder(
                  builder: (context) {
                    final visibleLines = detail.lines
                        .where(_matchesFilter)
                        .toList(growable: false);
                    return SliverList.separated(
                      itemCount: visibleLines.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (ctx, i) => _buildLedgerLineCard(
                        ctx,
                        visibleLines[i],
                        localeCode,
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLedgerLineCard(
    BuildContext context,
    WorkerLedgerLine line,
    String localeCode,
  ) {
    final l10n = context.l10n;
    final canReverse =
        !line.isReversed &&
        (line.kind == WorkerLedgerEntryKind.regularPayment ||
            line.kind == WorkerLedgerEntryKind.advancePayment ||
            line.kind == WorkerLedgerEntryKind.advanceRefund ||
            line.kind == WorkerLedgerEntryKind.adjustmentCredit ||
            line.kind == WorkerLedgerEntryKind.adjustmentDebit);

    final (String badgeText, AppStatusTone tone) = switch (line.kind) {
      WorkerLedgerEntryKind.labourPayable => (
        l10n.accountingEarnedLabourLabel,
        AppStatusTone.good,
      ),
      WorkerLedgerEntryKind.labourInformational => (
        l10n.accountingInfoBadge,
        AppStatusTone.neutral,
      ),
      WorkerLedgerEntryKind.labourReversal => (
        l10n.stockTypeReversal,
        AppStatusTone.damaged,
      ),
      WorkerLedgerEntryKind.regularPayment => (
        l10n.accountingPaymentTypeRegular,
        AppStatusTone.good,
      ),
      WorkerLedgerEntryKind.advancePayment => (
        l10n.accountingPaymentTypeAdvance,
        AppStatusTone.info,
      ),
      WorkerLedgerEntryKind.advanceRefund => (
        l10n.accountingPaymentTypeRefund,
        AppStatusTone.pending,
      ),
      WorkerLedgerEntryKind.paymentReversal ||
      WorkerLedgerEntryKind.adjustmentReversal => (
        l10n.stockTypeReversal,
        AppStatusTone.damaged,
      ),
      WorkerLedgerEntryKind.adjustmentCredit => (
        l10n.accountingAdjustmentCredit,
        AppStatusTone.good,
      ),
      WorkerLedgerEntryKind.adjustmentDebit => (
        l10n.accountingAdjustmentDebit,
        AppStatusTone.damaged,
      ),
    };

    return AppCard.listItem(
      key: ValueKey<String>('${line.kind.name}_${line.sourceEntityId}'),
      onTap: () => context.push(
        RoutePaths.productionTransactionDetail(
          _txKindForLine(line).routeSegment,
          line.sourceEntityId,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppStatusBadge(label: badgeText, tone: tone),
              if (line.isReversed)
                AppStatusBadge(
                  label: l10n.stockReversedBadge,
                  tone: AppStatusTone.neutral,
                ),
              AppText(
                line.isInformational
                    ? MoneyFormatter.formatPaise(line.amountPaise)
                    : MoneyFormatter.formatSignedPaise(line.balanceDeltaPaise),
                variant: AppTextVariant.numeric,
                fontWeight: FontWeight.w700,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AppText(line.title, fontWeight: FontWeight.w600),
          if (line.subtitle != null && line.subtitle!.isNotEmpty)
            AppText(line.subtitle!, variant: AppTextVariant.bodySmall),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppText(
                IstDateTimeHelper.formatIstDateTime(
                  line.transactionAt,
                  locale: localeCode,
                ),
                variant: AppTextVariant.bodySmall,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: AppText(
                      '${l10n.accountingRunningBalanceLabel}: ${MoneyFormatter.formatPaise(line.runningBalancePaise)}',
                      variant: AppTextVariant.numeric,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (canReverse) ...[
                    const SizedBox(width: AppSpacing.xs),
                    AppIconButton(
                      icon: Icons.undo_rounded,
                      tooltip: l10n.stockReverseAction,
                      onPressed: () => _reverseLine(context, line),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
