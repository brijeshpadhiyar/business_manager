import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/process_routing/domain/calculators/process_pricing_calculator.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/process_routing/presentation/bloc/job_routing_cubit.dart';
import 'package:business_manager/features/process_routing/presentation/routing_error_localizer.dart';
import 'package:business_manager/features/process_routing/presentation/widgets/routing_handover_row.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// StitchFlow V1.3 Multi-Process Routing, Variant Allocation, Dynamic Pricing,
/// Additional Charges & Cost Summary Hub.
final class JobProcessRoutingPage extends StatelessWidget {
  const JobProcessRoutingPage({
    super.key,
    required this.lotId,
    this.initialDesignColourId,
  });

  final String lotId;
  final String? initialDesignColourId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JobRoutingCubit>(
      create: (_) => getIt<JobRoutingCubit>()..load(lotId),
      child: _JobProcessRoutingView(
        lotId: lotId,
        initialDesignColourId: initialDesignColourId,
      ),
    );
  }
}

final class _JobProcessRoutingView extends StatefulWidget {
  const _JobProcessRoutingView({
    required this.lotId,
    this.initialDesignColourId,
  });

  final String lotId;
  final String? initialDesignColourId;

  @override
  State<_JobProcessRoutingView> createState() => _JobProcessRoutingViewState();
}

final class _JobProcessRoutingViewState extends State<_JobProcessRoutingView> {
  static const _pricingCalc = ProcessPricingCalculator();

  String? _selectedDesignColourId;

  String get lotId => widget.lotId;

  @override
  void initState() {
    super.initState();
    _selectedDesignColourId = widget.initialDesignColourId;
  }

  AppStatusTone _statusTone(JobProcessStatus status) => switch (status) {
    JobProcessStatus.completed ||
    JobProcessStatus.returned ||
    JobProcessStatus.transferred => AppStatusTone.good,
    JobProcessStatus.dispatched ||
    JobProcessStatus.inProgress ||
    JobProcessStatus.partiallyCompleted ||
    JobProcessStatus.partiallyReturned => AppStatusTone.pending,
    JobProcessStatus.cancelled => AppStatusTone.damaged,
    JobProcessStatus.draft || JobProcessStatus.pending => AppStatusTone.neutral,
  };

  AppStatusTone _paymentTone(ProcessPaymentStatus status) => switch (status) {
    ProcessPaymentStatus.paid => AppStatusTone.good,
    ProcessPaymentStatus.partiallyPaid => AppStatusTone.info,
    ProcessPaymentStatus.pending => AppStatusTone.pending,
  };

  AppStatusTone _handoverTone(ProcessHandoverType type) => switch (type) {
    ProcessHandoverType.directTransfer => AppStatusTone.info,
    ProcessHandoverType.factoryReturn => AppStatusTone.good,
    ProcessHandoverType.factoryDispatch ||
    ProcessHandoverType.reassignment => AppStatusTone.pending,
    ProcessHandoverType.cancellation => AppStatusTone.damaged,
  };

  /// Exact zero-floating-point string-to-paise parser backed by [AppValidators].
  /// Returns `-1` when the entered rate/amount fails strict decimal validation.
  int _parseRupeesToPaise(String raw, {bool allowZero = true}) {
    final parsed = AppValidators.parseRupeesToPaiseExact(
      raw,
      isRequired: !allowZero,
      allowZero: allowZero,
    );
    if (!parsed.validation.isValid) return -1;
    return parsed.paise ?? 0;
  }

  /// Exact integer quantity parser backed by [AppValidators.parseQuantityExact].
  int _parseQuantity(String raw, {bool allowZero = false}) {
    final parsed = AppValidators.parseQuantityExact(
      raw,
      isRequired: !allowZero,
      allowZero: allowZero,
    );
    if (!parsed.validation.isValid) return -1;
    return parsed.value ?? 0;
  }

  Future<void> _showAddOrReassignSheet(
    BuildContext context,
    JobRoutingOverview overview, {
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
        (_selectedDesignColourId != null &&
            overview.skuBalances.any(
              (b) => b.designColourId == _selectedDesignColourId,
            ))
        ? _selectedDesignColourId!
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
                  AppDropdown<String>(
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
                  AppDropdown<String>(
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
                  AppDropdown<String>(
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
                    validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.quantityValidator(v, max: selectedSku.physicalAvailableInHouse)),
                    label:
                        '${l10n.routingFactoryReadyLabel}: ${selectedSku.physicalAvailableInHouse} ${l10n.piecesUnit}',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // Dynamic Pricing Section
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: rateCtrl,
                          validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.nonNegativeAmountValidator(v)),
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
                        validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.requiredValidator(v)),
                        label: l10n.routingRateOverrideReasonLabel,
                      ),
                    ),
                  ),
                  if (!isReassign) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.routingDispatchImmediatelyTitle),
                      subtitle: Text(l10n.routingDispatchImmediatelySubtitle),
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
                    icon: isReassign
                        ? AppIcons.assignWorker
                        : AppIcons.assignWorker,
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

  Future<void> _showDirectTransferSheet(
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
                        const SizedBox(height: 2),
                        AppText(
                          '${source.variantLabel} • ${source.pendingQuantity} ${l10n.piecesUnit}',
                          variant: AppTextVariant.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDropdown<String>(
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
                  AppDropdown<String>(
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
                    validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.quantityValidator(v, max: source.pendingQuantity)),
                    label:
                        '${l10n.routingDirectTransferAction} (${source.pendingQuantity} ${l10n.piecesUnit})',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: rateCtrl,
                    validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.nonNegativeAmountValidator(v)),
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
                        validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.requiredValidator(v)),
                        label: l10n.routingRateOverrideReasonLabel,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.routingMarkReceivedImmediatelyTitle),
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
                                () => error = l10n.routingInvalidTransferQtyError,
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

  Future<void> _showReturnToFactorySheet(
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
                  validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.nonNegativeQuantityValidator(v, isRequired: true)),
                  label: l10n.routingGoodReturnedLabel,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: damagedCtrl,
                  validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.nonNegativeQuantityValidator(v)),
                  label: l10n.routingDamagedOptionalLabel,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: reasonCtrl,
                  validator: ValidationLocalizer.wrap(context.l10n, (v) => (int.tryParse(damagedCtrl.text.trim()) ?? 0) > 0 ? AppValidators.requiredValidator(v) : const ValidationResult.valid()),
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

  Future<void> _showAdditionalChargeSheet(
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
            // Scrolls when the keyboard is open on a short phone.
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
                validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.amountValidator(v)),
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
                              error = RoutingErrorLocalizer.localize(l10n, err);
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

  /// Payments are recorded only in the worker ledger (Accounting), so Stock,
  /// Routing, Ledger and Reports always agree. Refreshes on return.
  Future<void> _openWorkerPayment(
    BuildContext context,
    JobProcessEntity jp,
  ) async {
    final cubit = context.read<JobRoutingCubit>();
    await context.push(RoutePaths.paymentCreate(workerId: jp.memberId));
    await cubit.load(jp.lotId);
  }

  Future<void> _showConfirmReceiptSheet(
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
            // Scrolls when the keyboard is open on a short phone.
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
                validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.quantityValidator(v, max: handover.pendingReceiptQuantity)),
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
                              error = RoutingErrorLocalizer.localize(l10n, err);
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

  Future<void> _showCancelDialog(
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
            title: '${l10n.routingCancelProcessAction} (${process.processName})',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: reasonCtrl,
                  validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.requiredValidator(v)),
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<JobRoutingCubit, JobRoutingState>(
      builder: (context, state) {
        final overview = state.overview;
        return AppScaffold(
          title: overview != null
              ? '${overview.lot.lotNumber} • ${l10n.routingTitle}'
              : l10n.routingTitle,
          actions: [
            AppIconButton(
              icon: AppIcons.refresh,
              tooltip: l10n.routingRefreshTooltip,
              onPressed: () => context.read<JobRoutingCubit>().load(lotId),
            ),
          ],
          padding: EdgeInsets.zero,
          body: AppStateTransition(
            stateKey: ValueKey<JobRoutingStatus>(state.status),
            child: switch (state.status) {
              JobRoutingStatus.initial ||
              JobRoutingStatus.loading => const AppSkeletonList(itemCount: 4),
              JobRoutingStatus.error => AppErrorView(
                title: l10n.routingLoadErrorTitle,
                message: state.errorMessage != null
                    ? RoutingErrorLocalizer.localize(l10n, state.errorMessage!)
                    : null,
                retryLabel: l10n.actionRetry,
                onRetry: () => context.read<JobRoutingCubit>().load(lotId),
              ),
              JobRoutingStatus.loaded => _buildLoaded(
                context,
                overview!,
                localeCode,
                isDark,
              ),
            },
          ),
        );
      },
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    JobRoutingOverview overview,
    String localeCode,
    bool isDark,
  ) {
    final l10n = context.l10n;
    final cubit = context.read<JobRoutingCubit>();
    final activeFilterId =
        (_selectedDesignColourId != null &&
            overview.skuBalances.any(
              (b) => b.designColourId == _selectedDesignColourId,
            ))
        ? _selectedDesignColourId
        : null;

    final filteredSkus = activeFilterId == null
        ? overview.skuBalances
        : overview.skuBalances
              .where((b) => b.designColourId == activeFilterId)
              .toList();
    final filteredProcesses = activeFilterId == null
        ? overview.jobProcesses
        : overview.jobProcesses
              .where((p) => p.designColourId == activeFilterId)
              .toList();
    final filteredHandovers = activeFilterId == null
        ? overview.handovers
        : overview.handovers
              .where((h) => h.designColourId == activeFilterId)
              .toList();
    final filteredCharges = activeFilterId == null
        ? overview.additionalCharges
        : overview.additionalCharges
              .where((c) => c.designColourId == activeFilterId)
              .toList();

    final costs = activeFilterId == null
        ? overview.costSummary
        : _pricingCalc.calculateJobCostSummary(
            jobProcesses: filteredProcesses,
            charges: filteredCharges,
          );

    final totalInitial = filteredSkus.fold<int>(
      0,
      (s, b) => s + b.initialQuantity,
    );
    final totalFactory = filteredSkus.fold<int>(
      0,
      (s, b) => s + b.physicalAvailableInHouse,
    );
    final totalWithWorkers = filteredSkus.fold<int>(
      0,
      (s, b) => s + b.totalPendingWithWorkers,
    );

    final hexByColourId = <String, String?>{
      for (final b in overview.skuBalances) b.designColourId: b.colourHex,
    };

    return RefreshIndicator(
      onRefresh: () => cubit.load(lotId),
      child: ListView(
        padding: AppSpacing.screenAll,
        children: [
          // 1. Job Quantity Summary Hero & Actions
          AppMotionEntrance(
            index: 0,
            child: AppCard(
              gradient: isDark
                  ? AppColors.heroGradientDark
                  : AppColors.heroGradientLight,
              borderColor: Colors.white.withValues(alpha: 0.18),
              borderRadius: AppRadius.xlBorder,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppActionRow(
                    content: Text(
                      '#${overview.lot.lotNumber}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    actions: [
                      AppStatusBadge(
                        label: '$totalInitial ${l10n.piecesUnit}',
                        tone: AppStatusTone.info,
                      ),
                    ],
                  ),
                  if (overview.lot.title != null &&
                      overview.lot.title!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      overview.lot.title!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      AppButton(
                        label: l10n.routingAddProcessAction,
                        icon: AppIcons.assignWorker,
                        onPressed: () => _showAddOrReassignSheet(
                          context,
                          overview,
                          isReassign: false,
                        ),
                      ),
                      AppButton(
                        label: l10n.routingReassignFromFactoryAction,
                        icon: AppIcons.assignWorker,
                        variant: AppButtonVariant.secondary,
                        onPressed: overview.totalFactoryAvailable > 0
                            ? () => _showAddOrReassignSheet(
                                context,
                                overview,
                                isReassign: true,
                              )
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 1B. Colour-Wise Filter Bar (never mixes quantities across colours/designs)
          if (overview.skuBalances.isNotEmpty) ...[
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: ChoiceChip(
                      label: Text(
                        '${l10n.filterAll} (${overview.skuBalances.length})',
                      ),
                      selected: activeFilterId == null,
                      onSelected: (_) =>
                          setState(() => _selectedDesignColourId = null),
                    ),
                  ),
                  for (final sku in overview.skuBalances)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        avatar: AppColourSwatch(
                          color: AppColourUtils.resolveColor(
                            sku.colourHex,
                            fallbackName: sku.colourName,
                          ),
                          size: 16,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        label: Text(
                          '${formatVariantLabel(sku.designName, sku.colourName)} (${sku.totalPendingWithWorkers})',
                        ),
                        selected: activeFilterId == sku.designColourId,
                        onSelected: (_) => setState(
                          () => _selectedDesignColourId = sku.designColourId,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // 2. Quantity & Cost Summary Glass Metric Tiles
          AppMotionEntrance(
            index: 1,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final tileW = (constraints.maxWidth - AppSpacing.sm) / 2;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    SizedBox(
                      width: tileW,
                      child: AppMetricTile(
                        label: l10n.routingFactoryReadyLabel,
                        value: totalFactory,
                        suffix: l10n.piecesUnit,
                        icon: AppIcons.factory,
                        tone: AppStatusTone.good,
                      ),
                    ),
                    SizedBox(
                      width: tileW,
                      child: AppMetricTile(
                        label: l10n.routingWithWorkersLabel,
                        value: totalWithWorkers,
                        suffix: l10n.piecesUnit,
                        icon: AppIcons.pending,
                        tone: totalWithWorkers > 0
                            ? AppStatusTone.pending
                            : AppStatusTone.neutral,
                      ),
                    ),
                    SizedBox(
                      width: tileW,
                      child: AppMetricTile(
                        label: l10n.routingTotalProductionCostLabel,
                        value: costs.totalNetCostPaise,
                        isCurrencyPaise: true,
                        icon: AppIcons.rupee,
                        tone: AppStatusTone.info,
                      ),
                    ),
                    SizedBox(
                      width: tileW,
                      child: AppMetricTile(
                        label: l10n.routingOutstandingPayableLabel,
                        value: costs.totalOutstandingPaise,
                        isCurrencyPaise: true,
                        icon: AppIcons.accounting,
                        tone: costs.totalOutstandingPaise > 0
                            ? AppStatusTone.pending
                            : AppStatusTone.good,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. Worker Payment & Cost Breakdown Card
          if (costs.workerPayables.isNotEmpty) ...[
            AppMotionEntrance(
              index: 2,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppHeading(
                      l10n.routingWorkerPayableSummaryHeading,
                      level: AppHeadingLevel.h3,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (var i = 0; i < costs.workerPayables.length; i++) ...[
                      AppActionRow(
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              costs.workerPayables[i].workerName,
                              fontWeight: FontWeight.w700,
                            ),
                            AppText(
                              '${costs.workerPayables[i].totalQuantity} ${l10n.piecesUnit} • ${MoneyFormatter.formatPaise(costs.workerPayables[i].netPayablePaise)} / ${MoneyFormatter.formatPaise(costs.workerPayables[i].paidPaise)}',
                              variant: AppTextVariant.bodySmall,
                            ),
                          ],
                        ),
                        actions: [
                          AppStatusBadge(
                            label: costs.workerPayables[i].paymentStatus.label,
                            tone: _paymentTone(
                              costs.workerPayables[i].paymentStatus,
                            ),
                          ),
                        ],
                      ),
                      if (i < costs.workerPayables.length - 1)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 6),
                          child: Divider(),
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // 4. Live Goods Location Summary
          if (activeFilterId == null &&
              overview.currentLocations.isNotEmpty) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeading(
                    l10n.routingCurrentGoodsLocationHeading,
                    level: AppHeadingLevel.h3,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final loc in overview.currentLocations)
                        AppStatusBadge(
                          label:
                              '${loc.locationLabel} (${loc.operationLabel}): ${loc.quantity} ${l10n.piecesUnit}',
                          tone: loc.isFactory
                              ? AppStatusTone.good
                              : AppStatusTone.pending,
                          icon: loc.isFactory
                              ? AppIcons.factory
                              : AppIcons.worker,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // 5. Operations List (Variant-Level + Dynamic Pricing + Colour-Filtered)
          AppHeading(
            '${l10n.routingOperationLabel} (${filteredProcesses.length})',
            level: AppHeadingLevel.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (filteredProcesses.isEmpty)
            AppCard(
              child: AppEmptyState(
                icon: AppIcons.routeTransfer,
                title: activeFilterId == null
                    ? l10n.routingNoOperationsTitle
                    : l10n.routingNoOperationsForColourTitle,
                subtitle: l10n.routingNoOperationsSubtitle,
                actionLabel: l10n.routingAddProcessAction,
                onAction: () => _showAddOrReassignSheet(
                  context,
                  overview,
                  isReassign: false,
                ),
              ),
            )
          else
            for (var i = 0; i < filteredProcesses.length; i++) ...[
              _buildProcessCard(
                context,
                overview,
                filteredProcesses[i],
                i,
                colourHex: hexByColourId[filteredProcesses[i].designColourId],
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

          const SizedBox(height: AppSpacing.lg),

          // 6. Chronological Process Movement Timeline
          AppHeading(
            '${l10n.navProcessHistory} (${filteredHandovers.length})',
            level: AppHeadingLevel.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (filteredHandovers.isEmpty)
            AppCard(
              child: AppText(
                l10n.routingNoHandoversSubtitle,
                variant: AppTextVariant.bodySmall,
              ),
            )
          else
            AppCard(
              child: Column(
                children: [
                  for (var i = 0; i < filteredHandovers.length; i++) ...[
                    _buildHandoverRow(
                      context,
                      filteredHandovers[i],
                      localeCode,
                      colourHex:
                          hexByColourId[filteredHandovers[i].designColourId],
                    ),
                    if (i < filteredHandovers.length - 1)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Divider(),
                      ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildProcessCard(
    BuildContext context,
    JobRoutingOverview overview,
    JobProcessEntity jp,
    int index, {
    String? colourHex,
  }) {
    final l10n = context.l10n;
    final cubit = context.read<JobRoutingCubit>();

    return AppCard.listItem(
      key: ValueKey<String>(jp.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RoutingOperationHeader(
            jobProcess: jp,
            statusTone: _statusTone(jp.status),
            colourHex: colourHex,
          ),
          const SizedBox(height: AppSpacing.xs),
          // Default vs Agreed Rate & Payment Status Line
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppStatusBadge(
                label:
                    '${MoneyFormatter.formatPaise(jp.agreedRatePaise)} / ${ProcessPricingCalculator.unitLabel(jp.pricingUnit)}',
                tone: jp.isRateOverridden
                    ? AppStatusTone.info
                    : AppStatusTone.neutral,
              ),
              if (jp.isRateOverridden)
                AppStatusBadge(
                  label: MoneyFormatter.formatPaise(jp.defaultRatePaise),
                  tone: AppStatusTone.neutral,
                ),
              AppStatusBadge(
                label:
                    '${l10n.routingOutstandingPayableLabel}: ${MoneyFormatter.formatPaise(jp.payableAmountPaise)} (${jp.paymentStatus.label})',
                tone: _paymentTone(jp.paymentStatus),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              AppStatusBadge(
                label: '${l10n.stockIssuedLabel}: ${jp.dispatchedQuantity}',
                tone: AppStatusTone.neutral,
              ),
              if (jp.receivedQuantity > 0)
                AppStatusBadge(
                  label: '${l10n.stockGoodReturnedLabel}: ${jp.receivedQuantity}',
                  tone: AppStatusTone.info,
                ),
              if (jp.transferredOutQuantity > 0)
                AppStatusBadge(
                  label:
                      '${l10n.routingDirectTransferAction}: ${jp.transferredOutQuantity}',
                  tone: AppStatusTone.info,
                ),
              if (jp.returnedToFactoryQuantity > 0)
                AppStatusBadge(
                  label:
                      '${l10n.routingReturnToFactoryAction}: ${jp.returnedToFactoryQuantity}',
                  tone: AppStatusTone.good,
                ),
              AppStatusBadge(
                label:
                    '${l10n.stockPendingWorkerLabel}: ${jp.pendingQuantity} ${l10n.piecesUnit}',
                tone: jp.pendingQuantity > 0
                    ? AppStatusTone.pending
                    : AppStatusTone.good,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (jp.canDispatch)
                AppButton(
                  label:
                      '${l10n.stockIssueAction} (${jp.remainingToDispatch})',
                  icon: AppIcons.dispatch,
                  onPressed: () async {
                    final err = await cubit.dispatchProcess(
                      jobProcessId: jp.id,
                      quantity: jp.remainingToDispatch,
                    );
                    if (err != null && context.mounted) {
                      AppFeedback.showError(
                        context,
                        RoutingErrorLocalizer.localize(l10n, err),
                      );
                    }
                  },
                ),
              if (jp.canTransferOrReturn)
                AppButton(
                  label: l10n.routingDirectTransferAction,
                  icon: AppIcons.routeTransfer,
                  onPressed: () =>
                      _showDirectTransferSheet(context, overview, jp),
                ),
              if (jp.canTransferOrReturn)
                AppButton(
                  label: l10n.routingReturnToFactoryAction,
                  icon: AppIcons.factory,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _showReturnToFactorySheet(context, jp),
                ),
              if (jp.status != JobProcessStatus.cancelled)
                AppButton(
                  label: l10n.routingAddChargeTitle,
                  icon: AppIcons.addCharge,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => _showAdditionalChargeSheet(context, jp),
                ),
              if (jp.status != JobProcessStatus.cancelled &&
                  jp.memberId != null)
                AppButton(
                  label: l10n.routingPayAction,
                  icon: AppIcons.payment,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => _openWorkerPayment(context, jp),
                ),
              if (jp.canComplete)
                AppButton(
                  label: l10n.routingMarkCompletedAction,
                  icon: AppIcons.successOutline,
                  variant: AppButtonVariant.outlined,
                  onPressed: () async {
                    final err = await cubit.markCompleted(jp.id);
                    if (err != null && context.mounted) {
                      AppFeedback.showError(
                        context,
                        RoutingErrorLocalizer.localize(l10n, err),
                      );
                    }
                  },
                ),
              if (jp.canCancel)
                AppButton(
                  label: l10n.routingCancelAction,
                  icon: AppIcons.cancel,
                  variant: AppButtonVariant.text,
                  onPressed: () => _showCancelDialog(context, jp),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHandoverRow(
    BuildContext context,
    ProcessHandoverEntity h,
    String localeCode, {
    String? colourHex,
  }) {
    return RoutingHandoverRow(
      handover: h,
      localeCode: localeCode,
      tone: _handoverTone(h.handoverType),
      colourHex: colourHex,
      onConfirmReceipt: () => _showConfirmReceiptSheet(context, h),
    );
  }
}
