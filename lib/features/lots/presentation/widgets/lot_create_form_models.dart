import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Mutable form state for a single colour variant row inside [LotCreatePage].
final class ColourVariantRowState {
  ColourVariantRowState({
    required this.id,
    required this.colourName,
    this.colourHex,
    required int initialQuantity,
    required int unitPricePaise,
  }) : qtyCtrl = TextEditingController(text: '$initialQuantity'),
       priceCtrl = TextEditingController(
         text: unitPricePaise > 0
             ? MoneyFormatter.formatPaiseForInput(unitPricePaise)
             : '',
       );

  final String id;
  final String colourName;
  final String? colourHex;
  final TextEditingController qtyCtrl;
  final TextEditingController priceCtrl;

  int get quantity => int.tryParse(qtyCtrl.text.trim()) ?? 0;

  int get unitPricePaise {
    final parsed = AppValidators.parseRupeesToPaiseExact(
      priceCtrl.text,
      isRequired: false,
      allowZero: true,
    );
    return parsed.paise ?? 0;
  }

  void dispose() {
    qtyCtrl.dispose();
    priceCtrl.dispose();
  }
}

/// Mutable form state for one design block and its child colour rows.
final class DesignBlockState {
  DesignBlockState({
    required this.id,
    required this.designName,
    this.notes,
    this.defaultUnitPricePaise = 0,
  });

  final String id;
  final String designName;
  final String? notes;
  final int defaultUnitPricePaise;
  final List<ColourVariantRowState> colours = [];

  int get totalQty => colours.fold(0, (acc, c) => acc + c.quantity);

  int get totalValuePaise =>
      colours.fold(0, (acc, c) => acc + (c.quantity * c.unitPricePaise));

  void dispose() {
    for (final c in colours) {
      c.dispose();
    }
  }
}

/// Modal bottom sheet to add an optional initial process assignment while
/// creating a lot.
Future<InitialLotProcessAssignmentInput?> showAddInitialLotAssignmentSheet(
  BuildContext context, {
  required List<({String designName, String colourName, int qty})> skuOptions,
  required List<ProcessEntity> activeProcesses,
  required List<WorkerEntity> activeWorkers,
}) async {
  if (skuOptions.isEmpty || activeProcesses.isEmpty || activeWorkers.isEmpty) {
    AppFeedback.showError(context, context.l10n.lotNeedVariantStageWorker);
    return null;
  }

  var selectedSkuIdx = 0;
  var selectedProcId = activeProcesses.first.id;
  var selectedWorkerId = activeWorkers.first.id;
  final qtyCtrl = TextEditingController();
  final rateCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  String? err;
  InitialLotProcessAssignmentInput? result;

  try {
    await AppBottomSheet.show<void>(
      context,
      title: context.l10n.prodHistoryAddAssignmentAction,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setSheetState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppDropdown<int>(
                label: context.l10n.lotDesignColourVariantLabel,
                value: selectedSkuIdx,
                items: List<int>.generate(skuOptions.length, (i) => i),
                itemLabelBuilder: (i) {
                  final s = skuOptions[i];
                  return '${formatVariantLabel(s.designName, s.colourName)} (${s.qty} pcs)';
                },
                onChanged: (v) {
                  if (v != null) {
                    setSheetState(() => selectedSkuIdx = v);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppSelect<String>(
                label: context.l10n.navProcesses,
                value: selectedProcId,
                items: activeProcesses.map((p) => p.id).toList(),
                itemLabelBuilder: (id) =>
                    activeProcesses.firstWhere((p) => p.id == id).name,
                onChanged: (v) {
                  if (v != null) setSheetState(() => selectedProcId = v);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              AppSelect<String>(
                label: context.l10n.navWorkers,
                value: selectedWorkerId,
                items: activeWorkers.map((w) => w.id).toList(),
                itemLabelBuilder: (id) =>
                    activeWorkers.firstWhere((w) => w.id == id).name,
                onChanged: (v) {
                  if (v != null) setSheetState(() => selectedWorkerId = v);
                },
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: qtyCtrl,
                      validator: ValidationLocalizer.wrap(
                        context.l10n,
                        (v) => AppValidators.quantityValidator(v),
                      ),
                      label: context.l10n.lotQtyPcsLabel,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      controller: rateCtrl,
                      validator: ValidationLocalizer.wrap(
                        context.l10n,
                        (v) => AppValidators.nonNegativeAmountValidator(v),
                      ),
                      label: context.l10n.lotLockedRateLabel,
                      helperText: () {
                        final rate = activeProcesses
                            .firstWhere((p) => p.id == selectedProcId)
                            .defaultRatePaise;
                        return rate > 0
                            ? context.l10n.lotStageDefaultRateHelper(
                                MoneyFormatter.formatPaise(rate),
                              )
                            : null;
                      }(),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [AppInputFormatters.currencyDecimal],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              AppTextField(
                controller: notesCtrl,
                label: context.l10n.stockNotesLabel,
              ),
              if (err != null) ...[
                const SizedBox(height: AppSpacing.xs),
                AppText(err!, color: Theme.of(ctx).colorScheme.error),
              ],
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: context.l10n.prodHistoryAddAssignmentAction,
                icon: AppIcons.assignWorker,
                isExpanded: true,
                onPressed: () {
                  final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
                  final parsedRate = AppValidators.parseRupeesToPaiseExact(
                    rateCtrl.text,
                    isRequired: true,
                    allowZero: true,
                  );
                  if (qty <= 0) {
                    setSheetState(
                      () => err = context.l10n.lotEnterPositiveQty,
                    );
                    return;
                  }
                  if (!parsedRate.validation.isValid ||
                      parsedRate.paise == null) {
                    setSheetState(() => err = context.l10n.lotEnterValidRate);
                    return;
                  }
                  final sku = skuOptions[selectedSkuIdx];
                  result = InitialLotProcessAssignmentInput(
                    designName: sku.designName,
                    colourName: sku.colourName,
                    processId: selectedProcId,
                    workerId: selectedWorkerId,
                    quantity: qty,
                    agreedRatePaise: parsedRate.paise!,
                    notes: notesCtrl.text,
                  );
                  Navigator.of(sheetCtx).pop();
                },
              ),
            ],
          ),
        ),
      ),
    );
  } finally {
    qtyCtrl.dispose();
    rateCtrl.dispose();
    notesCtrl.dispose();
  }
  return result;
}
