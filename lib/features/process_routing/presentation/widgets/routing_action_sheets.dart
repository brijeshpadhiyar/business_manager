import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/process_routing/domain/calculators/process_pricing_calculator.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/process_routing/presentation/bloc/job_routing_cubit.dart';
import 'package:business_manager/features/process_routing/presentation/routing_error_localizer.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Bottom sheets and confirmation dialogs for [JobProcessRoutingPage].
abstract final class RoutingActionSheets {
  static const _pricingCalc = ProcessPricingCalculator();

  static int _parseRupeesToPaise(String raw, {bool allowZero = true}) {
    final parsed = AppValidators.parseRupeesToPaiseExact(
      raw,
      isRequired: !allowZero,
      allowZero: allowZero,
    );
    if (!parsed.validation.isValid) return -1;
    return parsed.paise ?? 0;
  }

  static int _parseQuantity(String raw, {bool allowZero = false}) {
    final parsed = AppValidators.parseQuantityExact(
      raw,
      isRequired: !allowZero,
      allowZero: allowZero,
    );
    if (!parsed.validation.isValid) return -1;
    return parsed.value ?? 0;
  }

  static Future<void> showAddOrReassignSheet(
    BuildContext context,
    JobRoutingOverview overview, {
    required String? initialSelectedDesignColourId,
    required bool isReassign,
  }) async {
    final l10n = context.l10n;
    if (overview.skuBalances.isEmpty) {
      AppFeedback.showError(context, l10n.routingAddColourFirstError);
      return;
    }
    if (overview.availableProcesses.isEmpty ||
        overview.availableWorkers.isEmpty) {
      AppFeedback.showError(context, l10n.routingAddProcessWorkerFirstError);
      return;
    }

    final cubit = context.read<JobRoutingCubit>();
    String selectedSkuId =
        (initialSelectedDesignColourId != null &&
            overview.skuBalances.any(
              (b) => b.designColourId == initialSelectedDesignColourId,
            ))
        ? initialSelectedDesignColourId
        : overview.skuBalances.first.designColourId;
    String selectedProcessId = overview.availableProcesses.first.id;
    String selectedWorkerId = overview.availableWorkers.first.id;

    ProcessDefaultPricing defaultFor(String procId) =>
        overview.defaultPricingByProcessId[procId] ??
        ProcessDefaultPricing(
          processId: procId,
          defaultRatePaise: 0,
          defaultPricingUnit: ProcessPricingCalculator.unitPerPiece,
        );

    final initialPricing = defaultFor(selectedProcessId);
    final initialSku = overview.skuBalances.firstWhere(
      (b) => b.designColourId == selectedSkuId,
    );
    String selectedUnit = initialPricing.defaultPricingUnit;
    final qtyCtrl = TextEditingController(
      text: '${initialSku.physicalAvailableInHouse}',
    );
    final rateCtrl = TextEditingController(
      text: MoneyFormatter.formatPaiseForInput(initialPricing.defaultRatePaise),
    );
    final overrideReasonCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool dispatchNow = true;
    String? error;
    bool saving = false;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: isReassign
            ? l10n.routingReassignFromFactoryAction
            : l10n.routingAddOperationTitle,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) {
            final selectedSku = overview.skuBalances.firstWhere(
              (b) => b.designColourId == selectedSkuId,
            );
            final procDefault = defaultFor(selectedProcessId);
            final agreedPaise = _parseRupeesToPaise(rateCtrl.text);
            final isOverridden =
                agreedPaise >= 0 && agreedPaise != procDefault.defaultRatePaise;
            final qtyVal = int.tryParse(qtyCtrl.text.trim()) ?? 0;
            final previewTotal = agreedPaise >= 0 && qtyVal > 0
                ? _pricingCalc.calculateBaseAmountPaise(
                    quantity: qtyVal,
                    ratePaise: agreedPaise,
                    pricingUnit: selectedUnit,
                  )
                : 0;

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSelect<String>(
                    label: l10n.routingVariantLabel,
                    value: selectedSkuId,
                    items: overview.skuBalances
                        .map((b) => b.designColourId)
                        .toList(),
                    itemLabelBuilder: (id) {
                      final b = overview.skuBalances.firstWhere(
                        (e) => e.designColourId == id,
                      );
                      return '${formatVariantLabel(b.designName, b.colourName)} (${b.physicalAvailableInHouse} ${l10n.piecesUnit})';
                    },
                    onChanged: (v) {
                      if (v == null) return;
                      final b = overview.skuBalances.firstWhere(
                        (e) => e.designColourId == v,
                      );
                      setSheetState(() {
                        selectedSkuId = v;
                        qtyCtrl.text = '${b.physicalAvailableInHouse}';
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSelect<String>(
                    label: l10n.routingOperationLabel,
                    value: selectedProcessId,
                    items: overview.availableProcesses
                        .map((p) => p.id)
                        .toList(),
                    itemLabelBuilder: (id) => overview.availableProcesses
                        .firstWhere((p) => p.id == id)
                        .name,
                    onChanged: (v) {
                      if (v == null) return;
                      final dp = defaultFor(v);
                      setSheetState(() {
                        selectedProcessId = v;
                        selectedUnit = dp.defaultPricingUnit;
                        rateCtrl.text = MoneyFormatter.formatPaiseForInput(
                          dp.defaultRatePaise,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSelect<String>(
                    label: l10n.routingAssignWorkerLabel,
                    value: selectedWorkerId,
                    items: overview.availableWorkers.map((w) => w.id).toList(),
                    itemLabelBuilder: (id) => overview.availableWorkers
                        .firstWhere((w) => w.id == id)
                        .name,
                    onChanged: (v) {
                      if (v != null) setSheetState(() => selectedWorkerId = v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: qtyCtrl,
                    validator: ValidationLocalizer.wrap(
                      context.l10n,
                      (v) => AppValidators.quantityValidator(
                        v,
                        max: selectedSku.physicalAvailableInHouse,
                      ),
                    ),
                    label:
                        '${l10n.routingFactoryReadyLabel}: ${selectedSku.physicalAvailableInHouse} ${l10n.piecesUnit}',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: rateCtrl,
                          validator: ValidationLocalizer.wrap(
                            context.l10n,
                            (v) => AppValidators.nonNegativeAmountValidator(v),
                          ),
                          label:
                              '${l10n.ratesAmountLabel} (${MoneyFormatter.formatPaise(procDefault.defaultRatePaise)})',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setSheetState(() {}),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppDropdown<String>(
                          label: l10n.routingPricingUnitLabel,
                          value:
                              ProcessPricingCalculator.standardUnits.contains(
                                selectedUnit,
                              )
                              ? selectedUnit
                              : ProcessPricingCalculator.unitPerPiece,
                          items: ProcessPricingCalculator.standardUnits,
                          itemLabelBuilder: ProcessPricingCalculator.unitLabel,
                          onChanged: (v) {
                            if (v != null) {
                              setSheetState(() => selectedUnit = v);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppStatusBadge(
                    label:
                        '${l10n.routingOutstandingPayableLabel}: ${MoneyFormatter.formatPaise(previewTotal)} (${ProcessPricingCalculator.unitLabel(selectedUnit)})',
                    tone: AppStatusTone.info,
                  ),
                  AppExpandableSection(
                    expanded: isOverridden,
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: AppTextField(
                        controller: overrideReasonCtrl,
                        validator: ValidationLocalizer.wrap(
                          context.l10n,
                          (v) => AppValidators.requiredValidator(v),
                        ),
                        label: l10n.routingRateOverrideReasonLabel,
                      ),
                    ),
                  ),
                  if (!isReassign) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppSwitch(
                      label: l10n.routingDispatchImmediatelyTitle,
                      subtitle: l10n.routingDispatchImmediatelySubtitle,
                      value: dispatchNow,
                      onChanged: (v) => setSheetState(() => dispatchNow = v),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: notesCtrl,
                    label: l10n.routingNotesOptionalLabel,
                    maxLines: 2,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppText(error!, color: Theme.of(ctx).colorScheme.error),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: isReassign
                        ? l10n.routingConfirmReassignmentAction
                        : (dispatchNow
                              ? l10n.routingAddDispatchAction
                              : l10n.routingSavePendingAction),
                    icon: AppIcons.assignWorker,
                    isExpanded: true,
                    isLoading: saving,
                    onPressed: saving
                        ? null
                        : () async {
                            final qty = _parseQuantity(qtyCtrl.text);
                            final paise = _parseRupeesToPaise(rateCtrl.text);
                            if (qty <= 0) {
                              setSheetState(
                                () => error = l10n.routingInvalidQuantityError,
                              );
                              return;
                            }
                            if (paise < 0) {
                              setSheetState(
                                () => error = l10n.routingInvalidRateError,
                              );
                              return;
                            }
                            setSheetState(() {
                              saving = true;
                              error = null;
                            });
                            final err = isReassign
                                ? await cubit.reassignFromFactory(
                                    designColourId: selectedSkuId,
                                    targetProcessId: selectedProcessId,
                                    targetWorkerId: selectedWorkerId,
                                    quantity: qty,
                                    agreedRatePaise: paise,
                                    pricingUnit: selectedUnit,
                                    rateOverrideReason: overrideReasonCtrl.text,
                                    notes: notesCtrl.text,
                                  )
                                : await cubit.addProcess(
                                    designColourId: selectedSkuId,
                                    processId: selectedProcessId,
                                    workerId: selectedWorkerId,
                                    quantity: qty,
                                    dispatchImmediately: dispatchNow,
                                    agreedRatePaise: paise,
                                    pricingUnit: selectedUnit,
                                    rateOverrideReason: overrideReasonCtrl.text,
                                    notes: notesCtrl.text,
                                  );
                            if (err != null) {
                              if (sheetCtx.mounted) {
                                setSheetState(() {
                                  saving = false;
                                  error = RoutingErrorLocalizer.localize(
                                    l10n,
                                    err,
                                  );
                                });
                              }
                            } else if (sheetCtx.mounted) {
                              Navigator.of(sheetCtx).pop();
                              if (context.mounted) {
                                AppFeedback.showSuccess(
                                  context,
                                  l10n.routingOperationAddedSuccess,
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
      qtyCtrl.dispose();
      rateCtrl.dispose();
      overrideReasonCtrl.dispose();
      notesCtrl.dispose();
    }
  }

  static Future<void> showDirectTransferSheet(
    BuildContext context,
    JobRoutingOverview overview,
    JobProcessEntity source,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<JobRoutingCubit>();
    String destProcessId = overview.availableProcesses
        .firstWhere(
          (p) => p.id != source.processId,
          orElse: () => overview.availableProcesses.first,
        )
        .id;
    String destWorkerId = overview.availableWorkers
        .firstWhere(
          (w) => w.id != source.memberId,
          orElse: () => overview.availableWorkers.first,
        )
        .id;
    final defaultPricing = overview.defaultPricingByProcessId[destProcessId];
    final qtyCtrl = TextEditingController(text: '${source.pendingQuantity}');
    final rateCtrl = TextEditingController(
      text: MoneyFormatter.formatPaiseForInput(
        defaultPricing?.defaultRatePaise ?? 0,
      ),
    );
    final reasonCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool autoConfirm = false;
    String? error;
    bool saving = false;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: l10n.routingDirectTransferTitle,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) {
            final dp = overview.defaultPricingByProcessId[destProcessId];
            final defPaise = dp?.defaultRatePaise ?? 0;
            final agreedPaise = _parseRupeesToPaise(rateCtrl.text);
            final overridden = agreedPaise >= 0 && agreedPaise != defPaise;

            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppCard(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          '${source.workerName ?? '-'} (${source.processName})',
                          fontWeight: FontWeight.w700,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        AppText(
                          '${source.variantLabel} • ${source.pendingQuantity} ${l10n.piecesUnit}',
                          variant: AppTextVariant.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSelect<String>(
                    label: l10n.routingNextOperationLabel,
                    value: destProcessId,
                    items: overview.availableProcesses
                        .map((p) => p.id)
                        .toList(),
                    itemLabelBuilder: (id) => overview.availableProcesses
                        .firstWhere((p) => p.id == id)
                        .name,
                    onChanged: (v) {
                      if (v == null) return;
                      final nextDp = overview.defaultPricingByProcessId[v];
                      setSheetState(() {
                        destProcessId = v;
                        rateCtrl.text = MoneyFormatter.formatPaiseForInput(
                          nextDp?.defaultRatePaise ?? 0,
                        );
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppSelect<String>(
                    label: l10n.routingDestinationWorkerLabel,
                    value: destWorkerId,
                    items: overview.availableWorkers.map((w) => w.id).toList(),
                    itemLabelBuilder: (id) => overview.availableWorkers
                        .firstWhere((w) => w.id == id)
                        .name,
                    onChanged: (v) {
                      if (v != null) setSheetState(() => destWorkerId = v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: qtyCtrl,
                    validator: ValidationLocalizer.wrap(
                      context.l10n,
                      (v) => AppValidators.quantityValidator(
                        v,
                        max: source.pendingQuantity,
                      ),
                    ),
                    label:
                        '${l10n.routingDirectTransferAction} (${source.pendingQuantity} ${l10n.piecesUnit})',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: rateCtrl,
                    validator: ValidationLocalizer.wrap(
                      context.l10n,
                      (v) => AppValidators.nonNegativeAmountValidator(v),
                    ),
                    label:
                        '${l10n.ratesAmountLabel} (${MoneyFormatter.formatPaise(defPaise)})',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  AppExpandableSection(
                    expanded: overridden,
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: AppTextField(
                        controller: reasonCtrl,
                        validator: ValidationLocalizer.wrap(
                          context.l10n,
                          (v) => AppValidators.requiredValidator(v),
                        ),
                        label: l10n.routingRateOverrideReasonLabel,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  AppSwitch(
                    label: l10n.routingMarkReceivedImmediatelyTitle,
                    value: autoConfirm,
                    onChanged: (v) => setSheetState(() => autoConfirm = v),
                  ),
                  AppTextField(
                    controller: notesCtrl,
                    label: l10n.routingTransferNotesLabel,
                    maxLines: 2,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppText(error!, color: Theme.of(ctx).colorScheme.error),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: l10n.routingConfirmDirectTransferAction,
                    icon: AppIcons.routeTransfer,
                    isExpanded: true,
                    isLoading: saving,
                    onPressed: saving
                        ? null
                        : () async {
                            final qty = _parseQuantity(qtyCtrl.text);
                            final paise = _parseRupeesToPaise(rateCtrl.text);
                            if (qty <= 0) {
                              setSheetState(
                                () =>
                                    error = l10n.routingInvalidTransferQtyError,
                              );
                              return;
                            }
                            if (paise < 0) {
                              setSheetState(
                                () => error = l10n.routingInvalidDestRateError,
                              );
                              return;
                            }
                            setSheetState(() {
                              saving = true;
                              error = null;
                            });
                            final err = await cubit.directTransfer(
                              sourceJobProcessId: source.id,
                              destinationProcessId: destProcessId,
                              destinationWorkerId: destWorkerId,
                              quantity: qty,
                              autoConfirmReceipt: autoConfirm,
                              agreedRatePaise: paise >= 0 ? paise : null,
                              rateOverrideReason: reasonCtrl.text,
                              notes: notesCtrl.text,
                            );
                            if (err != null) {
                              if (sheetCtx.mounted) {
                                setSheetState(() {
                                  saving = false;
                                  error = RoutingErrorLocalizer.localize(
                                    l10n,
                                    err,
                                  );
                                });
                              }
                            } else if (sheetCtx.mounted) {
                              Navigator.of(sheetCtx).pop();
                              if (context.mounted) {
                                AppFeedback.showSuccess(
                                  context,
                                  l10n.routingOperationAddedSuccess,
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
      qtyCtrl.dispose();
      rateCtrl.dispose();
      reasonCtrl.dispose();
      notesCtrl.dispose();
    }
  }

  static Future<void> showReturnToFactorySheet(
    BuildContext context,
    JobProcessEntity source,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<JobRoutingCubit>();
    final goodCtrl = TextEditingController(text: '${source.pendingQuantity}');
    final damagedCtrl = TextEditingController(text: '0');
    final reasonCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    String? error;
    bool saving = false;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: l10n.routingReturnToFactoryTitle,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText(
                  '${source.workerName ?? '-'} • ${source.processName} (${source.variantLabel}) • ${source.pendingQuantity} ${l10n.piecesUnit}',
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: goodCtrl,
                  validator: ValidationLocalizer.wrap(
                    context.l10n,
                    (v) => AppValidators.nonNegativeQuantityValidator(
                      v,
                      isRequired: true,
                    ),
                  ),
                  label: l10n.routingGoodReturnedLabel,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: damagedCtrl,
                  validator: ValidationLocalizer.wrap(
                    context.l10n,
                    (v) => AppValidators.nonNegativeQuantityValidator(v),
                  ),
                  label: l10n.routingDamagedOptionalLabel,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: reasonCtrl,
                  validator: ValidationLocalizer.wrap(
                    context.l10n,
                    (v) => (int.tryParse(damagedCtrl.text.trim()) ?? 0) > 0
                        ? AppValidators.requiredValidator(v)
                        : const ValidationResult.valid(),
                  ),
                  label: l10n.stockSettlementReasonLabel,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: notesCtrl,
                  label: l10n.routingVerificationNotesLabel,
                  maxLines: 2,
                ),
                if (error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppText(error!, color: Theme.of(ctx).colorScheme.error),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.routingConfirmFactoryReturnAction,
                  icon: AppIcons.factory,
                  isExpanded: true,
                  isLoading: saving,
                  onPressed: saving
                      ? null
                      : () async {
                          final good = int.tryParse(goodCtrl.text.trim()) ?? 0;
                          final dmg =
                              int.tryParse(damagedCtrl.text.trim()) ?? 0;
                          setSheetState(() {
                            saving = true;
                            error = null;
                          });
                          final err = await cubit.returnToFactory(
                            sourceJobProcessId: source.id,
                            goodQuantity: good,
                            damagedQuantity: dmg,
                            reason: reasonCtrl.text,
                            notes: notesCtrl.text,
                          );
                          if (err != null) {
                            if (sheetCtx.mounted) {
                              setSheetState(() {
                                saving = false;
                                error = RoutingErrorLocalizer.localize(
                                  l10n,
                                  err,
                                );
                              });
                            }
                          } else if (sheetCtx.mounted) {
                            Navigator.of(sheetCtx).pop();
                            if (context.mounted) {
                              AppFeedback.showSuccess(
                                context,
                                l10n.routingOperationAddedSuccess,
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
      goodCtrl.dispose();
      damagedCtrl.dispose();
      reasonCtrl.dispose();
      notesCtrl.dispose();
    }
  }

  static Future<void> showAdditionalChargeSheet(
    BuildContext context,
    JobProcessEntity jp,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<JobRoutingCubit>();
    var chargeType = ProcessChargeType.extraCharge;
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String? error;
    bool saving = false;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: l10n.routingAddChargeTitle,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText(
                  '${jp.workerName ?? '-'} • ${jp.processName} (${jp.variantLabel})',
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: AppSpacing.md),
                AppDropdown<ProcessChargeType>(
                  label: l10n.routingChargeTypeLabel,
                  value: chargeType,
                  items: ProcessChargeType.values,
                  itemLabelBuilder: (t) => t.label,
                  onChanged: (v) {
                    if (v != null) setSheetState(() => chargeType = v);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: descCtrl,
                  label: l10n.routingChargeDescLabel,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: amountCtrl,
                  validator: ValidationLocalizer.wrap(
                    context.l10n,
                    (v) => AppValidators.amountValidator(v),
                  ),
                  label: l10n.accountingAmountLabel,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                if (error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppText(error!, color: Theme.of(ctx).colorScheme.error),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.actionSave,
                  icon: AppIcons.addCharge,
                  isExpanded: true,
                  isLoading: saving,
                  onPressed: saving
                      ? null
                      : () async {
                          final paise = _parseRupeesToPaise(
                            amountCtrl.text,
                            allowZero: false,
                          );
                          if (paise <= 0) {
                            setSheetState(
                              () => error = l10n.routingInvalidAmountError,
                            );
                            return;
                          }
                          setSheetState(() {
                            saving = true;
                            error = null;
                          });
                          final err = await cubit.addAdditionalCharge(
                            jobProcessId: jp.id,
                            chargeType: chargeType,
                            description: descCtrl.text,
                            amountPaise: paise,
                          );
                          if (err != null) {
                            if (sheetCtx.mounted) {
                              setSheetState(() {
                                saving = false;
                                error = RoutingErrorLocalizer.localize(
                                  l10n,
                                  err,
                                );
                              });
                            }
                          } else if (sheetCtx.mounted) {
                            Navigator.of(sheetCtx).pop();
                            if (context.mounted) {
                              AppFeedback.showSuccess(
                                context,
                                l10n.routingOperationAddedSuccess,
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
      descCtrl.dispose();
      amountCtrl.dispose();
    }
  }

  static Future<void> showConfirmReceiptSheet(
    BuildContext context,
    ProcessHandoverEntity handover,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<JobRoutingCubit>();
    final qtyCtrl = TextEditingController(
      text: '${handover.pendingReceiptQuantity}',
    );
    String? error;
    bool saving = false;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: l10n.routingConfirmReceiptTitle,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText(
                  '${handover.transferReference} • ${handover.fromLocationLabel} → ${handover.toLocationLabel}',
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: AppSpacing.xs),
                AppText(
                  '${handover.variantLabel} • ${handover.quantityReceived}/${handover.quantityDispatched} ${l10n.piecesUnit}',
                  variant: AppTextVariant.bodySmall,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: qtyCtrl,
                  validator: ValidationLocalizer.wrap(
                    context.l10n,
                    (v) => AppValidators.quantityValidator(
                      v,
                      max: handover.pendingReceiptQuantity,
                    ),
                  ),
                  label:
                      '${l10n.routingConfirmReceiptAction} (${handover.pendingReceiptQuantity} ${l10n.piecesUnit})',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                if (error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppText(error!, color: Theme.of(ctx).colorScheme.error),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: l10n.routingConfirmReceiptAction,
                  icon: AppIcons.successOutline,
                  isExpanded: true,
                  isLoading: saving,
                  onPressed: saving
                      ? null
                      : () async {
                          final qty = _parseQuantity(qtyCtrl.text);
                          if (qty <= 0) {
                            setSheetState(
                              () => error = l10n.routingInvalidReceivedQtyError,
                            );
                            return;
                          }
                          setSheetState(() {
                            saving = true;
                            error = null;
                          });
                          final err = await cubit.confirmReceipt(
                            handoverId: handover.id,
                            receivedQuantity: qty,
                          );
                          if (err != null) {
                            if (sheetCtx.mounted) {
                              setSheetState(() {
                                saving = false;
                                error = RoutingErrorLocalizer.localize(
                                  l10n,
                                  err,
                                );
                              });
                            }
                          } else if (sheetCtx.mounted) {
                            Navigator.of(sheetCtx).pop();
                            if (context.mounted) {
                              AppFeedback.showSuccess(
                                context,
                                l10n.routingOperationAddedSuccess,
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
    }
  }

  static Future<void> showCancelDialog(
    BuildContext context,
    JobProcessEntity process,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<JobRoutingCubit>();
    final reasonCtrl = TextEditingController();
    String? error;
    try {
      await AppDialog.showCustom<void>(
        context,
        builder: (dlgCtx) => StatefulBuilder(
          builder: (ctx, setDlgState) => AppDialog(
            title:
                '${l10n.routingCancelProcessAction} (${process.processName})',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: reasonCtrl,
                  validator: ValidationLocalizer.wrap(
                    context.l10n,
                    (v) => AppValidators.requiredValidator(v),
                  ),
                  label: l10n.routingCancelReasonLabel,
                ),
                if (error != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppText(error!, color: Theme.of(ctx).colorScheme.error),
                ],
              ],
            ),
            cancelLabel: l10n.routingKeepAction,
            confirmLabel: l10n.routingCancelProcessAction,
            isDestructive: true,
            onConfirm: () async {
              final err = await cubit.cancelProcess(
                jobProcessId: process.id,
                reason: reasonCtrl.text,
              );
              if (err != null) {
                if (dlgCtx.mounted) {
                  setDlgState(
                    () => error = RoutingErrorLocalizer.localize(l10n, err),
                  );
                }
              } else if (dlgCtx.mounted) {
                Navigator.of(dlgCtx).pop();
              }
            },
          ),
        ),
      );
    } finally {
      reasonCtrl.dispose();
    }
  }
}
