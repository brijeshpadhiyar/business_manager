import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/process_routing/domain/calculators/process_pricing_calculator.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/process_routing/presentation/bloc/job_routing_cubit.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

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
    if (overview.skuBalances.isEmpty) {
      AppFeedback.showError(
        context,
        'Add at least one Colour or Design variant to this Lot first.',
      );
      return;
    }
    if (overview.availableProcesses.isEmpty ||
        overview.availableWorkers.isEmpty) {
      AppFeedback.showError(
        context,
        'Please create at least one active Process and Worker first.',
      );
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
      text: (initialPricing.defaultRatePaise / 100).toStringAsFixed(2),
    );
    final overrideReasonCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool dispatchNow = true;
    String? error;
    bool saving = false;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: isReassign ? 'Reassign from Factory' : 'Add Process Operation',
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
                    label: 'Variant (Design / Colour)',
                    value: selectedSkuId,
                    items: overview.skuBalances
                        .map((b) => b.designColourId)
                        .toList(),
                    itemLabelBuilder: (id) {
                      final b = overview.skuBalances.firstWhere(
                        (e) => e.designColourId == id,
                      );
                      return '${formatVariantLabel(b.designName, b.colourName)} (${b.physicalAvailableInHouse} pcs ready)';
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
                    label: 'Operation / Process',
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
                        rateCtrl.text = (dp.defaultRatePaise / 100)
                            .toStringAsFixed(2);
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDropdown<String>(
                    label: 'Assign Worker / Department',
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
                    label:
                        'Quantity (Factory Ready: ${selectedSku.physicalAvailableInHouse} pcs)',
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
                          label:
                              'Agreed Rate (Default: ${MoneyFormatter.formatPaise(procDefault.defaultRatePaise)})',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) => setSheetState(() {}),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppDropdown<String>(
                          label: 'Pricing Unit',
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
                        'Estimated Payable: ${MoneyFormatter.formatPaise(previewTotal)} (${ProcessPricingCalculator.unitLabel(selectedUnit)})',
                    tone: AppStatusTone.info,
                  ),
                  AppExpandableSection(
                    expanded: isOverridden,
                    child: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: AppTextField(
                        controller: overrideReasonCtrl,
                        label: 'Reason for Changing Default Rate (Required)',
                      ),
                    ),
                  ),
                  if (!isReassign) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Dispatch immediately from Factory'),
                      subtitle: const Text(
                        'Turn off to save as Pending and dispatch later',
                      ),
                      value: dispatchNow,
                      onChanged: (v) => setSheetState(() => dispatchNow = v),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: notesCtrl,
                    label: 'Notes (Optional)',
                    maxLines: 2,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppText(error!, color: Theme.of(ctx).colorScheme.error),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: isReassign
                        ? 'Confirm Reassignment'
                        : (dispatchNow
                              ? 'Add & Dispatch Process'
                              : 'Save Pending Process'),
                    icon: isReassign
                        ? Icons.assignment_ind_outlined
                        : Icons.add_task_rounded,
                    isExpanded: true,
                    isLoading: saving,
                    onPressed: saving
                        ? null
                        : () async {
                            final qty = _parseQuantity(qtyCtrl.text);
                            final paise = _parseRupeesToPaise(rateCtrl.text);
                            if (qty <= 0) {
                              setSheetState(
                                () => error =
                                    'Enter a valid positive whole quantity.',
                              );
                              return;
                            }
                            if (paise < 0) {
                              setSheetState(
                                () => error =
                                    'Enter a valid non-negative rate (max 2 decimals).',
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
                                  error = err;
                                });
                              }
                            } else if (sheetCtx.mounted) {
                              Navigator.of(sheetCtx).pop();
                              if (context.mounted) {
                                AppFeedback.showSuccess(
                                  context,
                                  isReassign
                                      ? 'Reassigned $qty pcs successfully.'
                                      : 'Operation added successfully.',
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
      text: ((defaultPricing?.defaultRatePaise ?? 0) / 100).toStringAsFixed(2),
    );
    final reasonCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool autoConfirm = false;
    String? error;
    bool saving = false;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: 'Direct Worker-to-Worker Transfer',
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
                          'From: ${source.workerName ?? '-'} (${source.processName})',
                          fontWeight: FontWeight.w700,
                        ),
                        const SizedBox(height: 2),
                        AppText(
                          '${source.variantLabel} • Held: ${source.pendingQuantity} pcs',
                          variant: AppTextVariant.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDropdown<String>(
                    label: 'Next Operation / Process',
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
                        rateCtrl.text = ((nextDp?.defaultRatePaise ?? 0) / 100)
                            .toStringAsFixed(2);
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDropdown<String>(
                    label: 'Destination Worker / Department',
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
                    label:
                        'Transfer Quantity (Max ${source.pendingQuantity} pcs)',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: rateCtrl,
                    label:
                        'Destination Rate (Default: ${MoneyFormatter.formatPaise(defPaise)})',
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
                        label: 'Reason for Changing Default Rate (Required)',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Mark received immediately'),
                    value: autoConfirm,
                    onChanged: (v) => setSheetState(() => autoConfirm = v),
                  ),
                  AppTextField(
                    controller: notesCtrl,
                    label: 'Transfer Notes (Optional)',
                    maxLines: 2,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppText(error!, color: Theme.of(ctx).colorScheme.error),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: 'Confirm Direct Transfer',
                    icon: Icons.compare_arrows_rounded,
                    isExpanded: true,
                    isLoading: saving,
                    onPressed: saving
                        ? null
                        : () async {
                            final qty = _parseQuantity(qtyCtrl.text);
                            final paise = _parseRupeesToPaise(rateCtrl.text);
                            if (qty <= 0) {
                              setSheetState(
                                () => error =
                                    'Enter a valid positive transfer quantity.',
                              );
                              return;
                            }
                            if (paise < 0) {
                              setSheetState(
                                () => error =
                                    'Enter a valid destination rate (max 2 decimals).',
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
                                  error = err;
                                });
                              }
                            } else if (sheetCtx.mounted) {
                              Navigator.of(sheetCtx).pop();
                              if (context.mounted) {
                                AppFeedback.showSuccess(
                                  context,
                                  'Transferred $qty pcs directly.',
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
        title: 'Return to Factory',
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppText(
                  '${source.workerName ?? '-'} • ${source.processName} (${source.variantLabel}) • Outstanding: ${source.pendingQuantity} pcs',
                  fontWeight: FontWeight.w600,
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: goodCtrl,
                  label: 'Good Quantity Returned to Factory',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: damagedCtrl,
                  label: 'Damaged Quantity (Optional)',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: reasonCtrl,
                  label: 'Damage Reason (Required if Damaged > 0)',
                ),
                const SizedBox(height: AppSpacing.md),
                AppTextField(
                  controller: notesCtrl,
                  label: 'Verification Notes (Optional)',
                  maxLines: 2,
                ),
                if (error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  AppText(error!, color: Theme.of(ctx).colorScheme.error),
                ],
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Confirm Factory Return',
                  icon: Icons.warehouse_outlined,
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
                                error = err;
                              });
                            }
                          } else if (sheetCtx.mounted) {
                            Navigator.of(sheetCtx).pop();
                            if (context.mounted) {
                              AppFeedback.showSuccess(
                                context,
                                'Returned ${good + dmg} pcs to Factory.',
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
    final cubit = context.read<JobRoutingCubit>();
    var chargeType = ProcessChargeType.extraCharge;
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String? error;
    bool saving = false;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: 'Add Extra Charge / Deduction',
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(
                '${jp.workerName ?? '-'} • ${jp.processName} (${jp.variantLabel})',
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: AppSpacing.md),
              AppDropdown<ProcessChargeType>(
                label: 'Type',
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
                label: 'Description (e.g. Urgent work, Special cutting)',
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: amountCtrl,
                label: 'Amount (₹)',
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
                label: 'Save ${chargeType.label}',
                icon: Icons.add_card_rounded,
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
                            () => error =
                                'Enter a valid positive amount (max 2 decimals).',
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
                              error = err;
                            });
                          }
                        } else if (sheetCtx.mounted) {
                          Navigator.of(sheetCtx).pop();
                          if (context.mounted) {
                            AppFeedback.showSuccess(
                              context,
                              '${chargeType.label} saved.',
                            );
                          }
                        }
                      },
              ),
            ],
          ),
        ),
      );
    } finally {
      descCtrl.dispose();
      amountCtrl.dispose();
    }
  }

  Future<void> _showRecordPaymentSheet(
    BuildContext context,
    JobProcessEntity jp,
  ) async {
    final cubit = context.read<JobRoutingCubit>();
    final amountCtrl = TextEditingController();
    final refCtrl = TextEditingController();
    String mode = 'CASH';
    String? error;
    bool saving = false;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: 'Record Worker Payment',
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(
                '${jp.workerName ?? '-'} • ${jp.processName} • Paid: ${MoneyFormatter.formatPaise(jp.paidAmountPaise)}',
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: amountCtrl,
                label: 'Payment Amount (₹)',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              AppDropdown<String>(
                label: 'Payment Mode',
                value: mode,
                items: const ['CASH', 'UPI', 'BANK_TRANSFER', 'CHEQUE'],
                itemLabelBuilder: (m) => m.replaceAll('_', ' '),
                onChanged: (v) {
                  if (v != null) setSheetState(() => mode = v);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: refCtrl,
                label: 'Reference No (Optional)',
              ),
              if (error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                AppText(error!, color: Theme.of(ctx).colorScheme.error),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Confirm Payment',
                icon: Icons.payments_outlined,
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
                            () => error =
                                'Enter a valid positive amount (max 2 decimals).',
                          );
                          return;
                        }
                        setSheetState(() {
                          saving = true;
                          error = null;
                        });
                        final err = await cubit.recordPayment(
                          jobProcessId: jp.id,
                          amountPaise: paise,
                          paymentMode: mode,
                          referenceNo: refCtrl.text,
                        );
                        if (err != null) {
                          if (sheetCtx.mounted) {
                            setSheetState(() {
                              saving = false;
                              error = err;
                            });
                          }
                        } else if (sheetCtx.mounted) {
                          Navigator.of(sheetCtx).pop();
                          if (context.mounted) {
                            AppFeedback.showSuccess(
                              context,
                              'Payment recorded.',
                            );
                          }
                        }
                      },
              ),
            ],
          ),
        ),
      );
    } finally {
      amountCtrl.dispose();
      refCtrl.dispose();
    }
  }

  Future<void> _showConfirmReceiptSheet(
    BuildContext context,
    ProcessHandoverEntity handover,
  ) async {
    final cubit = context.read<JobRoutingCubit>();
    final qtyCtrl = TextEditingController(
      text: '${handover.pendingReceiptQuantity}',
    );
    String? error;
    bool saving = false;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: 'Confirm Material Receipt',
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(
                '${handover.transferReference} • ${handover.fromLocationLabel} → ${handover.toLocationLabel}',
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: AppSpacing.xs),
              AppText(
                '${handover.variantLabel} • Dispatched: ${handover.quantityDispatched} pcs • Received: ${handover.quantityReceived} pcs',
                variant: AppTextVariant.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: qtyCtrl,
                label:
                    'Received Now (Max ${handover.pendingReceiptQuantity} pcs)',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              if (error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                AppText(error!, color: Theme.of(ctx).colorScheme.error),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Confirm Receipt',
                icon: Icons.check_circle_outline_rounded,
                isExpanded: true,
                isLoading: saving,
                onPressed: saving
                    ? null
                    : () async {
                        final qty = _parseQuantity(qtyCtrl.text);
                        if (qty <= 0) {
                          setSheetState(
                            () => error =
                                'Enter a valid positive received quantity.',
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
                              error = err;
                            });
                          }
                        } else if (sheetCtx.mounted) {
                          Navigator.of(sheetCtx).pop();
                          if (context.mounted) {
                            AppFeedback.showSuccess(
                              context,
                              'Confirmed receipt of $qty pcs.',
                            );
                          }
                        }
                      },
              ),
            ],
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
    final cubit = context.read<JobRoutingCubit>();
    final reasonCtrl = TextEditingController();
    String? error;
    try {
      await AppDialog.showCustom<void>(
        context,
        builder: (dlgCtx) => StatefulBuilder(
          builder: (ctx, setDlgState) => AppDialog(
            title: 'Cancel ${process.processName}?',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: reasonCtrl,
                  label: 'Cancellation Reason',
                ),
                if (error != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  AppText(error!, color: Theme.of(ctx).colorScheme.error),
                ],
              ],
            ),
            cancelLabel: 'Keep',
            confirmLabel: 'Cancel Process',
            isDestructive: true,
            onConfirm: () async {
              final err = await cubit.cancelProcess(
                jobProcessId: process.id,
                reason: reasonCtrl.text,
              );
              if (err != null) {
                if (dlgCtx.mounted) setDlgState(() => error = err);
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
    final localeCode = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<JobRoutingCubit, JobRoutingState>(
      builder: (context, state) {
        final overview = state.overview;
        return AppScaffold(
          title: overview != null
              ? 'Job #${overview.lot.lotNumber} Routing'
              : 'Process Routing',
          actions: [
            AppIconButton(
              icon: Icons.refresh_rounded,
              tooltip: 'Refresh',
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
                title: 'Unable to load Job Routing',
                message: state.errorMessage,
                retryLabel: 'Retry',
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Job #${overview.lot.lotNumber}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      AppStatusBadge(
                        label: '$totalInitial pcs Total',
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
                        label: 'Add Process',
                        icon: Icons.add_task_rounded,
                        onPressed: () => _showAddOrReassignSheet(
                          context,
                          overview,
                          isReassign: false,
                        ),
                      ),
                      AppButton(
                        label: 'Reassign from Factory',
                        icon: Icons.assignment_ind_outlined,
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
                      label: Text('All Colours (${overview.skuBalances.length})'),
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
                          '${formatVariantLabel(sku.designName, sku.colourName)} (${sku.totalPendingWithWorkers}p)',
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
                        label: 'Factory Ready',
                        value: totalFactory,
                        suffix: 'pcs',
                        icon: Icons.warehouse_outlined,
                        tone: AppStatusTone.good,
                      ),
                    ),
                    SizedBox(
                      width: tileW,
                      child: AppMetricTile(
                        label: 'With Workers',
                        value: totalWithWorkers,
                        suffix: 'pcs',
                        icon: Icons.pending_actions_rounded,
                        tone: totalWithWorkers > 0
                            ? AppStatusTone.pending
                            : AppStatusTone.neutral,
                      ),
                    ),
                    SizedBox(
                      width: tileW,
                      child: AppMetricTile(
                        label: 'Total Production Cost',
                        value: costs.totalNetCostPaise,
                        isCurrencyPaise: true,
                        icon: Icons.currency_rupee_rounded,
                        tone: AppStatusTone.info,
                      ),
                    ),
                    SizedBox(
                      width: tileW,
                      child: AppMetricTile(
                        label: 'Outstanding Payable',
                        value: costs.totalOutstandingPaise,
                        isCurrencyPaise: true,
                        icon: Icons.account_balance_wallet_outlined,
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
                    const AppHeading(
                      'Worker Payable Summary',
                      level: AppHeadingLevel.h3,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (var i = 0; i < costs.workerPayables.length; i++) ...[
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppText(
                                  costs.workerPayables[i].workerName,
                                  fontWeight: FontWeight.w700,
                                ),
                                AppText(
                                  '${costs.workerPayables[i].totalQuantity} pcs • Net: ${MoneyFormatter.formatPaise(costs.workerPayables[i].netPayablePaise)} • Paid: ${MoneyFormatter.formatPaise(costs.workerPayables[i].paidPaise)}',
                                  variant: AppTextVariant.bodySmall,
                                ),
                              ],
                            ),
                          ),
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
          if (activeFilterId == null && overview.currentLocations.isNotEmpty) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppHeading(
                    'Current Goods Location',
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
                              '${loc.locationLabel} (${loc.operationLabel}): ${loc.quantity} pcs',
                          tone: loc.isFactory
                              ? AppStatusTone.good
                              : AppStatusTone.pending,
                          icon: loc.isFactory
                              ? Icons.warehouse_outlined
                              : Icons.person_pin_circle_outlined,
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
            'Operations (${filteredProcesses.length})',
            level: AppHeadingLevel.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (filteredProcesses.isEmpty)
            AppCard(
              child: AppEmptyState(
                icon: Icons.account_tree_outlined,
                title: activeFilterId == null
                    ? 'No Operations Added Yet'
                    : 'No Operations for Selected Colour',
                subtitle:
                    'Assign Cutting, Stitching, Checking, Finishing, Ironing, or Packing at variant level with custom worker rates.',
                actionLabel: 'Add Process',
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
            'Process Movement History (${filteredHandovers.length})',
            level: AppHeadingLevel.h3,
          ),
          const SizedBox(height: AppSpacing.sm),
          if (filteredHandovers.isEmpty)
            const AppCard(
              child: AppText(
                'Dispatches, direct transfers, returns, and reassignments will appear here chronologically.',
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
    final cubit = context.read<JobRoutingCubit>();
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard.listItem(
      key: ValueKey<String>(jp.id),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppColourSwatch(
                  color: AppColourUtils.resolveColor(
                    colourHex,
                    fallbackName: jp.colourName,
                  ),
                  size: 26,
                  borderRadius: AppRadius.smBorder,
                ),
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha: 0.16),
                    borderRadius: AppRadius.smBorder,
                  ),
                  child: AppText(
                    '#${jp.sequenceOrder}',
                    variant: AppTextVariant.bodySmall,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        jp.processName,
                        variant: AppTextVariant.bodyLarge,
                        fontWeight: FontWeight.w700,
                      ),
                      AppText(
                        '${jp.workerName ?? 'Unassigned'} • ${jp.variantLabel}',
                        variant: AppTextVariant.bodySmall,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
                AppStatusBadge(
                  label: jp.status.label,
                  tone: _statusTone(jp.status),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            // Default vs Agreed Rate & Payment Status Line
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                AppStatusBadge(
                  label:
                      'Rate: ${MoneyFormatter.formatPaise(jp.agreedRatePaise)} / ${ProcessPricingCalculator.unitLabel(jp.pricingUnit)}',
                  tone: jp.isRateOverridden
                      ? AppStatusTone.info
                      : AppStatusTone.neutral,
                ),
                if (jp.isRateOverridden)
                  AppStatusBadge(
                    label:
                        'Default: ${MoneyFormatter.formatPaise(jp.defaultRatePaise)}',
                    tone: AppStatusTone.neutral,
                  ),
                AppStatusBadge(
                  label:
                      'Payable: ${MoneyFormatter.formatPaise(jp.payableAmountPaise)} (${jp.paymentStatus.label})',
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
                  label: 'Dispatched: ${jp.dispatchedQuantity}',
                  tone: AppStatusTone.neutral,
                ),
                if (jp.receivedQuantity > 0)
                  AppStatusBadge(
                    label: 'Received: ${jp.receivedQuantity}',
                    tone: AppStatusTone.info,
                  ),
                if (jp.transferredOutQuantity > 0)
                  AppStatusBadge(
                    label: 'Transferred: ${jp.transferredOutQuantity}',
                    tone: AppStatusTone.info,
                  ),
                if (jp.returnedToFactoryQuantity > 0)
                  AppStatusBadge(
                    label: 'Returned: ${jp.returnedToFactoryQuantity}',
                    tone: AppStatusTone.good,
                  ),
                AppStatusBadge(
                  label: 'Pending: ${jp.pendingQuantity} pcs',
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
                    label: 'Dispatch (${jp.remainingToDispatch})',
                    icon: Icons.local_shipping_outlined,
                    onPressed: () async {
                      final err = await cubit.dispatchProcess(
                        jobProcessId: jp.id,
                        quantity: jp.remainingToDispatch,
                      );
                      if (err != null && context.mounted) {
                        AppFeedback.showError(context, err);
                      }
                    },
                  ),
                if (jp.canTransferOrReturn)
                  AppButton(
                    label: 'Direct Transfer',
                    icon: Icons.compare_arrows_rounded,
                    onPressed: () =>
                        _showDirectTransferSheet(context, overview, jp),
                  ),
                if (jp.canTransferOrReturn)
                  AppButton(
                    label: 'Return to Factory',
                    icon: Icons.warehouse_outlined,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _showReturnToFactorySheet(context, jp),
                  ),
                if (jp.status != JobProcessStatus.cancelled)
                  AppButton(
                    label: '+ Charge',
                    icon: Icons.add_card_outlined,
                    variant: AppButtonVariant.outlined,
                    onPressed: () => _showAdditionalChargeSheet(context, jp),
                  ),
                if (jp.status != JobProcessStatus.cancelled &&
                    jp.paymentStatus != ProcessPaymentStatus.paid)
                  AppButton(
                    label: 'Pay',
                    icon: Icons.payments_outlined,
                    variant: AppButtonVariant.outlined,
                    onPressed: () => _showRecordPaymentSheet(context, jp),
                  ),
                if (jp.canComplete)
                  AppButton(
                    label: 'Mark Completed',
                    icon: Icons.check_circle_outline_rounded,
                    variant: AppButtonVariant.outlined,
                    onPressed: () async {
                      final err = await cubit.markCompleted(jp.id);
                      if (err != null && context.mounted) {
                        AppFeedback.showError(context, err);
                      }
                    },
                  ),
                if (jp.canCancel)
                  AppButton(
                    label: 'Cancel',
                    icon: Icons.cancel_outlined,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppColourSwatch(
              color: AppColourUtils.resolveColor(
                colourHex,
                fallbackName: h.colourName,
              ),
              size: 16,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(width: 6),
            AppStatusBadge(
              label: h.handoverType.label,
              tone: _handoverTone(h.handoverType),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: AppText(
                h.transferReference,
                variant: AppTextVariant.bodySmall,
                fontWeight: FontWeight.w700,
              ),
            ),
            AppText(
              IstDateTimeHelper.formatIstDateTime(
                h.transactionAt,
                locale: localeCode,
              ),
              variant: AppTextVariant.bodySmall,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            Expanded(
              child: AppText(
                '${h.fromLocationLabel}  →  ${h.toLocationLabel}  •  ${h.processName}',
                fontWeight: FontWeight.w600,
              ),
            ),
            if (h.quantityDispatched > 0)
              AppText(
                '${h.quantityDispatched} pcs',
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Expanded(
              child: AppText(
                '${h.variantLabel} • Received: ${h.quantityReceived}/${h.quantityDispatched} • ${h.status.label}',
                variant: AppTextVariant.bodySmall,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (h.canConfirmReceipt)
              AppButton(
                label: 'Confirm Receipt',
                variant: AppButtonVariant.text,
                onPressed: () => _showConfirmReceiptSheet(context, h),
              ),
          ],
        ),
        if (h.notes != null && h.notes!.isNotEmpty) ...[
          const SizedBox(height: 2),
          AppText(
            h.notes!,
            variant: AppTextVariant.bodySmall,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ],
    );
  }
}
