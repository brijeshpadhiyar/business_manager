import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/production_history/presentation/bloc/inspection_queue_cubit.dart';
import 'package:business_manager/features/production_history/presentation/bloc/production_history_dashboard_cubit.dart';
import 'package:business_manager/features/security/presentation/widgets/security_reauth_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Screen 9: QC Inspection Queue & Rejection Repair / Re-Approval Management.
///
/// Enforces:
/// - Rule 1: Earnings strictly `AcceptedQty × HistoricalLockedRate`.
/// - Rule 3: Rejected pieces generate ₹0; repair -> reinspection -> immutable
///   re-approval credits original worker (or zero for in-house repair) without
///   allowing duplicate approvals.
/// - Rule 6: PIN / Biometric authorization via `SecurityReauthDialog` before
///   approving quantities and generating earnings.
final class InspectionQueuePage extends StatelessWidget {
  const InspectionQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InspectionQueueCubit>(
      create: (_) => getIt<InspectionQueueCubit>()..load(),
      child: const _InspectionQueueView(),
    );
  }
}

final class _InspectionQueueView extends StatefulWidget {
  const _InspectionQueueView();

  @override
  State<_InspectionQueueView> createState() => _InspectionQueueViewState();
}

final class _InspectionQueueViewState extends State<_InspectionQueueView> {
  int _tabIndex = 0;

  Future<void> _showInspectReturnSheet(
    BuildContext context,
    PendingReturnView item,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<InspectionQueueCubit>();
    final idGen = getIt<IdGenerator>();
    final reqId = idGen.nextRequestId();
    final accCtrl = TextEditingController(
      text: '${item.remainingPendingInspectionQty}',
    );
    final rejCtrl = TextEditingController(text: '0');
    final reasonCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String? error;
    bool saving = false;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: l10n.prodHistoryApproveAction,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) {
            final acc = int.tryParse(accCtrl.text.trim()) ?? 0;
            final rej = int.tryParse(rejCtrl.text.trim()) ?? 0;
            final previewEarn = acc * item.lockedRatePaise;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppText(
                    '${item.lotNumber} • ${item.designName} • ${item.colourName}',
                    fontWeight: FontWeight.w700,
                  ),
                  AppText(
                    '${item.workerName} • ${item.processName} • Pending QC: ${item.remainingPendingInspectionQty} pcs @ ${MoneyFormatter.formatPaise(item.lockedRatePaise)}/pc',
                    variant: AppTextVariant.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: accCtrl,
                    validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.nonNegativeQuantityValidator(v, isRequired: true)),
                    label: l10n.prodHistoryTotalAccepted,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setSheetState(() => error = null),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: rejCtrl,
                    validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.nonNegativeQuantityValidator(v)),
                    label: l10n.prodHistoryTotalRejected,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setSheetState(() => error = null),
                  ),
                  if (rej > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      controller: reasonCtrl,
                      validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.requiredValidator(v)),
                      label: l10n.stockSettlementReasonLabel,
                      maxLines: 2,
                      onChanged: (_) => setSheetState(() => error = null),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: notesCtrl,
                    label: l10n.stockNotesLabel,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppStatusBadge(
                    label:
                        'Earnings generated: ${MoneyFormatter.formatPaise(previewEarn)} (Rejected earns ₹0)',
                    tone: AppStatusTone.good,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AppText(error!, color: Theme.of(ctx).colorScheme.error),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: l10n.prodHistoryApproveAction,
                    icon: Icons.verified_rounded,
                    isExpanded: true,
                    isLoading: saving,
                    onPressed: saving
                        ? null
                        : () async {
                            if (acc + rej <= 0) {
                              setSheetState(
                                () => error = l10n.stockSettlementEmptyError,
                              );
                              return;
                            }
                            if (acc + rej >
                                item.remainingPendingInspectionQty) {
                              setSheetState(
                                () => error =
                                    l10n.validationExceedsPendingInspection,
                              );
                              return;
                            }
                            if (rej > 0 && reasonCtrl.text.trim().isEmpty) {
                              setSheetState(
                                () => error =
                                    l10n.stockSettlementReasonRequiredError,
                              );
                              return;
                            }

                            final auth =
                                await SecurityReauthDialog.verifyForApproval(
                                  context,
                                  title: l10n.prodHistoryApprovalAuthTitle,
                                  subtitle:
                                      l10n.prodHistoryApprovalAuthSubtitle,
                                );
                            if (!auth.approved || !sheetCtx.mounted) return;

                            setSheetState(() => saving = true);
                            final err = await cubit.approveReturn(
                              productionReturnId: item.productionReturn.id,
                              acceptedQuantity: acc,
                              rejectedQuantity: rej,
                              rejectionReason: reasonCtrl.text,
                              notes: notesCtrl.text,
                              authorizedViaPin: auth.authorizedViaPin,
                              clientRequestId: reqId,
                            );
                            if (err != null) {
                              if (sheetCtx.mounted) {
                                setSheetState(() {
                                  saving = false;
                                  error =
                                      ValidationLocalizer.localizeDomainCode(
                                        l10n,
                                        err,
                                        fallback: err,
                                      );
                                });
                              }
                            } else if (sheetCtx.mounted) {
                              Navigator.of(sheetCtx).pop();
                              if (context.mounted) {
                                AppFeedback.showSuccess(
                                  context,
                                  'Approved $acc pcs • Rejected $rej pcs.',
                                );
                              }
                            }
                          },
                  ),
                ],
              ),
            );
          },
        ),
      );
    } finally {
      accCtrl.dispose();
      rejCtrl.dispose();
      reasonCtrl.dispose();
      notesCtrl.dispose();
    }
  }

  Future<void> _showLogRepairSheet(
    BuildContext context,
    RejectionRecordView rej,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<InspectionQueueCubit>();
    final reqId = getIt<IdGenerator>().nextRequestId();
    final qtyCtrl = TextEditingController(text: '${rej.openUnrepairedQty}');
    final notesCtrl = TextEditingController();
    var source = RepairSource.originalWorker;
    String? error;
    bool saving = false;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: l10n.prodHistoryRecordRepairAction,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText(
                  '${rej.lotNumber} • ${rej.processName} • ${rej.workerName}',
                  fontWeight: FontWeight.w700,
                ),
                AppText(
                  'Open rejected: ${rej.openUnrepairedQty} pcs • Reason: ${rej.record.rejectionReason}',
                  variant: AppTextVariant.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: qtyCtrl,
                  validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.quantityValidator(v)),
                  label: l10n.stockRepairQuantityLabel,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppRadio<RepairSource>(
                  groupValue: source,
                  onChanged: (v) {
                    if (v != null) setSheetState(() => source = v);
                  },
                  options: [
                    AppRadioOption(
                      value: RepairSource.originalWorker,
                      label: l10n.prodHistoryRepairSourceOriginal,
                    ),
                    AppRadioOption(
                      value: RepairSource.inHouse,
                      label: l10n.prodHistoryRepairSourceInHouse,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: notesCtrl,
                  label: l10n.stockNotesLabel,
                  maxLines: 2,
                ),
                if (error != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppText(error!, color: Theme.of(ctx).colorScheme.error),
                ],
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: l10n.prodHistoryRecordRepairAction,
                  icon: Icons.build_outlined,
                  isExpanded: true,
                  isLoading: saving,
                  onPressed: saving
                      ? null
                      : () async {
                          final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                          if (qty <= 0 || qty > rej.openUnrepairedQty) {
                            setSheetState(
                              () => error = l10n.validationExceedsRejectedQty,
                            );
                            return;
                          }
                          setSheetState(() => saving = true);
                          final err = await cubit.recordRepair(
                            rejectionRecordId: rej.record.id,
                            repairedQuantity: qty,
                            repairSource: source,
                            notes: notesCtrl.text,
                            clientRequestId: reqId,
                          );
                          if (err != null) {
                            if (sheetCtx.mounted) {
                              setSheetState(() {
                                saving = false;
                                error = ValidationLocalizer.localizeDomainCode(
                                  l10n,
                                  err,
                                  fallback: err,
                                );
                              });
                            }
                          } else if (sheetCtx.mounted) {
                            Navigator.of(sheetCtx).pop();
                            if (context.mounted) {
                              AppFeedback.showSuccess(
                                context,
                                'Logged repair for $qty pcs — awaiting QC Re-Inspection.',
                              );
                            }
                          }
                        },
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      qtyCtrl.dispose();
      notesCtrl.dispose();
    }
  }

  Future<void> _showReinspectSheet(
    BuildContext context,
    RejectionRecordView rej,
    RejectionRepairView repairView,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<InspectionQueueCubit>();
    final reqId = getIt<IdGenerator>().nextRequestId();
    final accCtrl = TextEditingController(
      text: '${repairView.pendingReinspectionQty}',
    );
    final rejAgainCtrl = TextEditingController(text: '0');
    final reasonCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String? error;
    bool saving = false;
    final creditWorker =
        repairView.repair.repairSource == RepairSource.originalWorker;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: l10n.prodHistoryReinspectAction,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) {
            final acc = int.tryParse(accCtrl.text.trim()) ?? 0;
            final rejAgain = int.tryParse(rejAgainCtrl.text.trim()) ?? 0;
            final earnPreview = creditWorker ? acc * rej.lockedRatePaise : 0;
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppText(
                    '${rej.lotNumber} • ${rej.processName} • ${rej.workerName}',
                    fontWeight: FontWeight.w700,
                  ),
                  AppText(
                    'Pending Re-Inspection: ${repairView.pendingReinspectionQty} pcs • Locked Rate: ${MoneyFormatter.formatPaise(rej.lockedRatePaise)}/pc',
                    variant: AppTextVariant.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: accCtrl,
                    validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.nonNegativeQuantityValidator(v, isRequired: true)),
                    label: l10n.prodHistoryTotalAccepted,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setSheetState(() => error = null),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: rejAgainCtrl,
                    validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.nonNegativeQuantityValidator(v)),
                    label: 'Still Defective / Rejected Again',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setSheetState(() => error = null),
                  ),
                  if (rejAgain > 0) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      controller: reasonCtrl,
                      validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.requiredValidator(v)),
                      label: l10n.stockSettlementReasonLabel,
                      maxLines: 2,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: notesCtrl,
                    label: l10n.stockNotesLabel,
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppStatusBadge(
                    label: creditWorker
                        ? 'Worker earning generated: ${MoneyFormatter.formatPaise(earnPreview)}'
                        : 'In-House Repair: ₹0 worker earning',
                    tone: creditWorker
                        ? AppStatusTone.good
                        : AppStatusTone.info,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AppText(error!, color: Theme.of(ctx).colorScheme.error),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: l10n.prodHistoryReinspectAction,
                    icon: Icons.verified_rounded,
                    isExpanded: true,
                    isLoading: saving,
                    onPressed: saving
                        ? null
                        : () async {
                            if (acc + rejAgain <= 0 ||
                                acc + rejAgain >
                                    repairView.pendingReinspectionQty) {
                              setSheetState(
                                () => error = l10n.validationExceedsRepairedQty,
                              );
                              return;
                            }
                            if (rejAgain > 0 &&
                                reasonCtrl.text.trim().isEmpty) {
                              setSheetState(
                                () => error =
                                    l10n.stockSettlementReasonRequiredError,
                              );
                              return;
                            }
                            final auth =
                                await SecurityReauthDialog.verifyForApproval(
                                  context,
                                  title: l10n.prodHistoryApprovalAuthTitle,
                                  subtitle:
                                      l10n.prodHistoryApprovalAuthSubtitle,
                                );
                            if (!auth.approved || !sheetCtx.mounted) return;

                            setSheetState(() => saving = true);
                            final err = await cubit.approveReinspection(
                              rejectionRepairId: repairView.repair.id,
                              acceptedQuantity: acc,
                              rejectedAgainQuantity: rejAgain,
                              rejectionReason: reasonCtrl.text,
                              notes: notesCtrl.text,
                              authorizedViaPin: auth.authorizedViaPin,
                              clientRequestId: reqId,
                            );
                            if (err != null) {
                              if (sheetCtx.mounted) {
                                setSheetState(() {
                                  saving = false;
                                  error =
                                      ValidationLocalizer.localizeDomainCode(
                                        l10n,
                                        err,
                                        fallback: err,
                                      );
                                });
                              }
                            } else if (sheetCtx.mounted) {
                              Navigator.of(sheetCtx).pop();
                              if (context.mounted) {
                                AppFeedback.showSuccess(
                                  context,
                                  'Re-approved $acc pcs successfully.',
                                );
                              }
                            }
                          },
                  ),
                ],
              ),
            );
          },
        ),
      );
    } finally {
      accCtrl.dispose();
      rejAgainCtrl.dispose();
      reasonCtrl.dispose();
      notesCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    return BlocBuilder<InspectionQueueCubit, InspectionQueueState>(
      builder: (context, state) {
        final cubit = context.read<InspectionQueueCubit>();
        return AppScaffold(
          title: l10n.prodHistoryInspectionQueueTitle,
          contentWidth: AppContentWidth.wide,
          actions: [
            AppIconButton(
              icon: Icons.assignment_return_outlined,
              tooltip: l10n.stockReturnAction,
              onPressed: () async {
                await context.push(RoutePaths.stockReturnPicker);
                if (context.mounted) await cubit.load();
              },
            ),
            AppIconButton(
              icon: Icons.refresh_rounded,
              tooltip: l10n.actionRetry,
              onPressed: () => cubit.load(),
            ),
          ],
          body: switch (state.status) {
            ProductionHistoryLoadStatus.initial ||
            ProductionHistoryLoadStatus.loading
                when state.pendingReturns.isEmpty && state.rejections.isEmpty =>
              const AppSkeletonList(itemCount: 4),
            ProductionHistoryLoadStatus.error => AppErrorView(
              title: l10n.errorUnexpected,
              message: state.errorMessage,
              retryLabel: l10n.actionRetry,
              onRetry: () => cubit.load(),
            ),
            _ => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    ChoiceChip(
                      label: Text(
                        '${l10n.prodHistoryTabPendingInspection} (${state.pendingReturns.length})',
                      ),
                      selected: _tabIndex == 0,
                      onSelected: (_) => setState(() => _tabIndex = 0),
                    ),
                    ChoiceChip(
                      label: Text(
                        '${l10n.prodHistoryTabRejections} (${state.rejections.length})',
                      ),
                      selected: _tabIndex == 1,
                      onSelected: (_) => setState(() => _tabIndex = 1),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: _tabIndex == 0
                      ? _buildPendingReturnsTab(context, state, localeCode)
                      : _buildRejectionsTab(context, state, localeCode),
                ),
              ],
            ),
          },
        );
      },
    );
  }

  Widget _buildPendingReturnsTab(
    BuildContext context,
    InspectionQueueState state,
    String localeCode,
  ) {
    final l10n = context.l10n;
    if (state.pendingReturns.isEmpty) {
      return AppEmptyState(
        icon: Icons.verified_outlined,
        title: 'No Pending QC Inspections',
        subtitle: 'All returned pieces have been inspected and reconciled.',
        actionLabel: l10n.stockReturnAction,
        onAction: () => context.push(RoutePaths.stockReturnPicker),
      );
    }

    return ListView.separated(
      itemCount: state.pendingReturns.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (ctx, i) {
        final item = state.pendingReturns[i];
        return AppCard.listItem(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppActionRow(
                content: AppText(
                  '${item.workerName} • ${item.processName}',
                  fontWeight: FontWeight.w700,
                ),
                actions: [
                  AppStatusBadge(
                    label:
                        '${item.remainingPendingInspectionQty} pcs Pending QC',
                    tone: AppStatusTone.pending,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              AppText(
                '${item.lotNumber} • ${item.designName} • ${item.colourName}',
                variant: AppTextVariant.bodySmall,
              ),
              AppText(
                'Returned: ${item.productionReturn.returnedQuantity} • Locked Rate: ${MoneyFormatter.formatPaise(item.lockedRatePaise)}/pc • ${AppDateTimeFormatter.formatDateTime(item.productionReturn.transactionAt, locale: localeCode)}',
                variant: AppTextVariant.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  AppButton(
                    label: l10n.prodHistoryApproveAction,
                    icon: Icons.fact_check_rounded,
                    onPressed: () => _showInspectReturnSheet(context, item),
                  ),
                  AppButton(
                    label: l10n.prodHistoryOpenLot,
                    variant: AppButtonVariant.text,
                    onPressed: () => context.push(
                      RoutePaths.lotHistory(item.productionReturn.lotId),
                    ),
                  ),
                  AppButton(
                    label: l10n.prodHistoryOpenWorker,
                    variant: AppButtonVariant.text,
                    onPressed: () => context.push(
                      RoutePaths.workerDetail(item.productionReturn.memberId),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRejectionsTab(
    BuildContext context,
    InspectionQueueState state,
    String localeCode,
  ) {
    final l10n = context.l10n;
    final cubit = context.read<InspectionQueueCubit>();

    return ListView(
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: FilterChip(
            label: Text(l10n.prodHistoryOnlyPending),
            selected: state.showOnlyOpenRejections,
            onSelected: (v) => cubit.load(onlyOpenRejections: v),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (state.rejections.isEmpty)
          AppEmptyState(
            icon: Icons.verified_outlined,
            title: l10n.stockNoDamagedAvailable,
          )
        else
          AppLazySection(
            key: const ValueKey('state.rejections'),
            initialCount: 15,
            items: state.rejections,
            itemBuilder: (context, rej, _) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard.listItem(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppActionRow(
                        content: AppText(
                          '${rej.lotNumber} • ${rej.processName} • ${rej.workerName}',
                          fontWeight: FontWeight.w700,
                        ),
                        actions: [
                          AppStatusBadge(
                            label: rej.record.status.dbValue,
                            tone: rej.openUnrepairedQty > 0
                                ? AppStatusTone.damaged
                                : (rej.pendingReinspectionQty > 0
                                      ? AppStatusTone.pending
                                      : AppStatusTone.good),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      AppText(
                        '${rej.designName} • ${rej.colourName} • Reason: ${rej.record.rejectionReason}',
                        variant: AppTextVariant.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: 4,
                        children: [
                          AppStatusBadge(
                            label: 'Rejected: ${rej.record.rejectedQuantity}',
                            tone: AppStatusTone.damaged,
                          ),
                          AppStatusBadge(
                            label: 'Open: ${rej.openUnrepairedQty}',
                            tone: rej.openUnrepairedQty > 0
                                ? AppStatusTone.pending
                                : AppStatusTone.neutral,
                          ),
                          AppStatusBadge(
                            label: 'Re-Approved: ${rej.totalReapprovedQty}',
                            tone: AppStatusTone.good,
                          ),
                          if (rej.pendingReinspectionQty > 0)
                            AppStatusBadge(
                              label:
                                  'Awaiting Re-QC: ${rej.pendingReinspectionQty}',
                              tone: AppStatusTone.info,
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (rej.openUnrepairedQty > 0)
                            AppButton(
                              label: l10n.prodHistoryRecordRepairAction,
                              icon: Icons.build_outlined,
                              variant: AppButtonVariant.secondary,
                              onPressed: () =>
                                  _showLogRepairSheet(context, rej),
                            ),
                          for (final rep in rej.repairs)
                            if (rep.pendingReinspectionQty > 0)
                              AppButton(
                                label:
                                    '${l10n.prodHistoryReinspectAction} (${rep.pendingReinspectionQty})',
                                icon: Icons.verified_rounded,
                                onPressed: () =>
                                    _showReinspectSheet(context, rej, rep),
                              ),
                          AppButton(
                            label: l10n.prodHistoryTxDetailTitle,
                            variant: AppButtonVariant.text,
                            onPressed: () => context.push(
                              RoutePaths.productionTransactionDetail(
                                ProductionTransactionKind
                                    .rejection
                                    .routeSegment,
                                rej.record.id,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
      ],
    );
  }
}
