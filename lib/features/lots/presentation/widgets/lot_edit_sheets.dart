import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/lots/domain/entities/colour_master_entity.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/lots/presentation/bloc/lot_detail_cubit.dart';
import 'package:business_manager/features/lots/presentation/widgets/visual_colour_picker_sheet.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Modal bottom sheets for editing lots, designs, and colour variants on
/// [LotDetailPage].
abstract final class LotEditSheets {
  static Future<void> showEditLotSheet(
    BuildContext context,
    LotEntity lot,
  ) async {
    final l10n = context.l10n;
    final cubit = context.read<LotDetailCubit>();
    final formKey = GlobalKey<FormState>();
    final numberCtrl = TextEditingController(text: lot.lotNumber);
    final titleCtrl = TextEditingController(text: lot.title ?? '');
    final notesCtrl = TextEditingController(text: lot.notes ?? '');
    var status = lot.status;
    var txDateUtc = lot.transactionAt;
    String? submitError;
    bool isSaving = false;
    bool submittedOnce = false;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: l10n.lotEditAction,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) => Form(
            key: formKey,
            autovalidateMode: submittedOnce
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: numberCtrl,
                    label: l10n.lotNumberLabel,
                    maxLength: ValidationLimits.maxShortNameLength,
                    validator: ValidationLocalizer.wrap(
                      l10n,
                      (v) => AppValidators.nameValidator(
                        v,
                        maxLength: ValidationLimits.maxShortNameLength,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: titleCtrl,
                    label: l10n.lotTitleLabel,
                    maxLength: ValidationLimits.maxPersonNameLength,
                    validator: ValidationLocalizer.wrap(
                      l10n,
                      (v) => AppValidators.maxLengthValidator(
                        v,
                        maxLength: ValidationLimits.maxPersonNameLength,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDropdown<LotStatus>(
                    label: l10n.lotStatusLabel,
                    value: status,
                    items: const [LotStatus.active, LotStatus.completed],
                    itemLabelBuilder: (s) => s == LotStatus.active
                        ? l10n.lotsStatusActive
                        : l10n.lotsStatusCompleted,
                    onChanged: (v) {
                      if (v != null) setSheetState(() => status = v);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppDatePicker(
                    label: l10n.lotDateLabel,
                    selectedUtcMillis: txDateUtc,
                    onDateSelectedUtcMillis: (utc) =>
                        setSheetState(() => txDateUtc = utc),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: notesCtrl,
                    label: l10n.lotNotesLabel,
                    maxLines: 2,
                    maxLength: ValidationLimits.maxNotesLength,
                    validator: ValidationLocalizer.wrap(
                      l10n,
                      (v) => AppValidators.maxLengthValidator(
                        v,
                        maxLength: ValidationLimits.maxNotesLength,
                      ),
                    ),
                  ),
                  if (submitError != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppText(
                      submitError!,
                      color: Theme.of(ctx).colorScheme.error,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: l10n.actionSave,
                    isExpanded: true,
                    isLoading: isSaving,
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!submittedOnce) {
                              setSheetState(() => submittedOnce = true);
                            }
                            if (!(formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            setSheetState(() {
                              isSaving = true;
                              submitError = null;
                            });
                            final err = await cubit.updateLot(
                              lotId: lot.id,
                              lotNumber: numberCtrl.text,
                              title: titleCtrl.text,
                              notes: notesCtrl.text,
                              status: status,
                              transactionAtUtcMillis: txDateUtc,
                            );
                            if (err != null) {
                              if (sheetCtx.mounted) {
                                setSheetState(() {
                                  isSaving = false;
                                  submitError = err.contains('UNIQUE')
                                      ? l10n.lotDuplicateError
                                      : ValidationLocalizer.localizeDomainCode(
                                          l10n,
                                          err,
                                          fallback: err,
                                        );
                                });
                              }
                            } else if (sheetCtx.mounted) {
                              Navigator.of(sheetCtx).pop();
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      numberCtrl.dispose();
      titleCtrl.dispose();
      notesCtrl.dispose();
    }
  }

  static Future<void> showDesignSheet(
    BuildContext context, {
    required String lotId,
    LotDesignEntity? existing,
  }) async {
    final l10n = context.l10n;
    final cubit = context.read<LotDetailCubit>();
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.designName ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final defaultPriceCtrl = TextEditingController();
    final initialColours = <SelectedColourVariantInput>[];
    String? submitError;
    bool isSaving = false;
    bool submittedOnce = false;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: existing == null ? l10n.designAddAction : l10n.designEditAction,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) => Form(
            key: formKey,
            autovalidateMode: submittedOnce
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: nameCtrl,
                    label: l10n.designNameLabel,
                    maxLength: ValidationLimits.maxShortNameLength,
                    validator: ValidationLocalizer.wrap(
                      l10n,
                      (v) => AppValidators.nameValidator(
                        v,
                        maxLength: ValidationLimits.maxShortNameLength,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: notesCtrl,
                    label: l10n.lotNotesLabel,
                    maxLines: 2,
                    maxLength: ValidationLimits.maxNotesLength,
                    validator: ValidationLocalizer.wrap(
                      l10n,
                      (v) => AppValidators.maxLengthValidator(
                        v,
                        maxLength: ValidationLimits.maxNotesLength,
                      ),
                    ),
                  ),
                  if (existing == null) ...[
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: defaultPriceCtrl,
                      label: context.l10n.lotDefaultUnitPriceLabel,
                      hint: '0.00',
                      prefixIcon: AppIcons.rupee,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [AppInputFormatters.currencyDecimal],
                      validator: ValidationLocalizer.wrap(
                        l10n,
                        (v) => AppValidators.nonNegativeAmountValidator(
                          v,
                          isRequired: false,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppActionRow(
                      content: AppText(
                        context.l10n.lotInitialColoursCount(
                          initialColours.length,
                        ),
                        fontWeight: FontWeight.w700,
                      ),
                      actions: [
                        AppButton(
                          label: context.l10n.lotAddColours,
                          icon: AppIcons.colour,
                          variant: AppButtonVariant.secondary,
                          onPressed: () async {
                            final parsedDefault =
                                AppValidators.parseRupeesToPaiseExact(
                                  defaultPriceCtrl.text,
                                  isRequired: false,
                                  allowZero: true,
                                );
                            final picked = await VisualColourPickerSheet.show(
                              ctx,
                              title: nameCtrl.text.trim().isNotEmpty
                                  ? 'Select Colours — ${nameCtrl.text.trim()}'
                                  : context.l10n.lotSelectInitialColours,
                              existingColourNamesLower: initialColours
                                  .map((c) => c.colourName.trim().toLowerCase())
                                  .toSet(),
                              defaultUnitPricePaise: parsedDefault.paise ?? 0,
                            );
                            if (picked != null &&
                                picked.isNotEmpty &&
                                sheetCtx.mounted) {
                              setSheetState(() {
                                for (final p in picked) {
                                  if (!initialColours.any(
                                    (c) =>
                                        c.colourName.trim().toLowerCase() ==
                                        p.colourName.trim().toLowerCase(),
                                  )) {
                                    initialColours.add(p);
                                  }
                                }
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (initialColours.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      for (final c in initialColours)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: Row(
                            children: [
                              AppColourSwatch(
                                color: AppColourUtils.resolveColor(c.hexCode),
                                size: 22,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: AppText(
                                  '${c.colourName} • ${MoneyFormatter.formatQuantity(c.quantity)} pcs @ ${MoneyFormatter.formatPaise(c.unitPricePaise)}',
                                  variant: AppTextVariant.bodySmall,
                                ),
                              ),
                              AppIconButton(
                                icon: AppIcons.close,
                                tooltip: context.l10n.actionDelete,
                                onPressed: () => setSheetState(
                                  () => initialColours.remove(c),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                  if (submitError != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppText(
                      submitError!,
                      color: Theme.of(ctx).colorScheme.error,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: l10n.actionSave,
                    isExpanded: true,
                    isLoading: isSaving,
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!submittedOnce) {
                              setSheetState(() => submittedOnce = true);
                            }
                            if (!(formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            setSheetState(() {
                              isSaving = true;
                              submitError = null;
                            });
                            final err = existing == null
                                ? (initialColours.isEmpty
                                      ? await cubit.addDesign(
                                          lotId: lotId,
                                          designName: nameCtrl.text,
                                          notes: notesCtrl.text,
                                        )
                                      : await cubit.addDesignWithColours(
                                          lotId: lotId,
                                          designName: nameCtrl.text,
                                          notes: notesCtrl.text,
                                          colours: initialColours
                                              .map(
                                                (c) => LotColourDraftInput(
                                                  colourName: c.colourName,
                                                  colourHex: c.hexCode,
                                                  initialQuantity: c.quantity,
                                                  unitPricePaise:
                                                      c.unitPricePaise,
                                                ),
                                              )
                                              .toList(),
                                        ))
                                : await cubit.editDesign(
                                    lotId: lotId,
                                    designId: existing.id,
                                    designName: nameCtrl.text,
                                    notes: notesCtrl.text,
                                  );
                            if (err != null) {
                              if (sheetCtx.mounted) {
                                setSheetState(() {
                                  isSaving = false;
                                  submitError = err.contains('UNIQUE')
                                      ? l10n.designDuplicateError
                                      : ValidationLocalizer.localizeDomainCode(
                                          l10n,
                                          err,
                                          fallback: err,
                                        );
                                });
                              }
                            } else if (sheetCtx.mounted) {
                              Navigator.of(sheetCtx).pop();
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      nameCtrl.dispose();
      notesCtrl.dispose();
      defaultPriceCtrl.dispose();
    }
  }

  static Future<void> showColourSheet(
    BuildContext context, {
    required String lotId,
    required String lotDesignId,
    DesignColourEntity? existing,
  }) async {
    final l10n = context.l10n;
    final cubit = context.read<LotDetailCubit>();
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController(text: existing?.colourName ?? '');
    final qtyCtrl = TextEditingController(
      text: existing != null ? '${existing.initialQuantity}' : '',
    );
    final priceCtrl = TextEditingController(
      text: existing != null
          ? MoneyFormatter.formatPaiseForInput(existing.unitPricePaise)
          : '',
    );
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    String? submitError;
    bool isSaving = false;
    bool submittedOnce = false;

    try {
      await AppBottomSheet.show<void>(
        context,
        title: existing == null ? l10n.colourAddAction : l10n.colourEditAction,
        builder: (sheetCtx) => StatefulBuilder(
          builder: (ctx, setSheetState) => Form(
            key: formKey,
            autovalidateMode: submittedOnce
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppTextField(
                    controller: nameCtrl,
                    label: l10n.colourNameLabel,
                    maxLength: ValidationLimits.maxShortNameLength,
                    validator: ValidationLocalizer.wrap(
                      l10n,
                      (v) => AppValidators.nameValidator(
                        v,
                        maxLength: ValidationLimits.maxShortNameLength,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: qtyCtrl,
                    label: l10n.colourInitialQtyLabel,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: ValidationLocalizer.wrap(
                      l10n,
                      (v) => AppValidators.quantityValidator(v),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: priceCtrl,
                    label: l10n.colourUnitPriceLabel,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: ValidationLocalizer.wrap(
                      l10n,
                      (v) => AppValidators.nonNegativeAmountValidator(
                        v,
                        isRequired: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppTextField(
                    controller: notesCtrl,
                    label: l10n.lotNotesLabel,
                    maxLength: ValidationLimits.maxNotesLength,
                    validator: ValidationLocalizer.wrap(
                      l10n,
                      (v) => AppValidators.maxLengthValidator(
                        v,
                        maxLength: ValidationLimits.maxNotesLength,
                      ),
                    ),
                  ),
                  if (submitError != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    AppText(
                      submitError!,
                      color: Theme.of(ctx).colorScheme.error,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: l10n.actionSave,
                    isExpanded: true,
                    isLoading: isSaving,
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (!submittedOnce) {
                              setSheetState(() => submittedOnce = true);
                            }
                            if (!(formKey.currentState?.validate() ?? false)) {
                              return;
                            }
                            final parsedQty = AppValidators.parseQuantityExact(
                              qtyCtrl.text,
                            );
                            final parsedPrice =
                                AppValidators.parseRupeesToPaiseExact(
                                  priceCtrl.text,
                                  isRequired: false,
                                  allowZero: true,
                                );
                            if (parsedQty.value == null ||
                                parsedPrice.paise == null) {
                              return;
                            }
                            setSheetState(() {
                              isSaving = true;
                              submitError = null;
                            });
                            final err = existing == null
                                ? await cubit.addColour(
                                    lotId: lotId,
                                    lotDesignId: lotDesignId,
                                    colourName: nameCtrl.text,
                                    initialQuantity: parsedQty.value!,
                                    unitPricePaise: parsedPrice.paise!,
                                    notes: notesCtrl.text,
                                  )
                                : await cubit.editColour(
                                    lotId: lotId,
                                    designColourId: existing.id,
                                    colourName: nameCtrl.text,
                                    initialQuantity: parsedQty.value!,
                                    unitPricePaise: parsedPrice.paise!,
                                    notes: notesCtrl.text,
                                  );
                            if (err != null) {
                              if (sheetCtx.mounted) {
                                setSheetState(() {
                                  isSaving = false;
                                  submitError = err.contains('UNIQUE')
                                      ? l10n.colourDuplicateError
                                      : ValidationLocalizer.localizeDomainCode(
                                          l10n,
                                          err,
                                          fallback: err,
                                        );
                                });
                              }
                            } else if (sheetCtx.mounted) {
                              Navigator.of(sheetCtx).pop();
                            }
                          },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } finally {
      nameCtrl.dispose();
      qtyCtrl.dispose();
      priceCtrl.dispose();
      notesCtrl.dispose();
    }
  }

  static Future<void> showVisualColourPicker(
    BuildContext context, {
    required String lotId,
    String? lotDesignId,
    String? designDisplayName,
    Set<String> existingColourNames = const {},
  }) async {
    final cubit = context.read<LotDetailCubit>();
    final selected = await VisualColourPickerSheet.show(
      context,
      title: designDisplayName != null
          ? 'Select Colours — $designDisplayName'
          : context.l10n.lotSelectColoursNoDesign,
      existingColourNamesLower: existingColourNames
          .map((n) => n.trim().toLowerCase())
          .toSet(),
    );
    if (selected == null || selected.isEmpty || !context.mounted) return;

    final err = await cubit.addColoursBatch(
      lotId: lotId,
      lotDesignId: lotDesignId,
      colours: selected
          .map(
            (item) => LotColourDraftInput(
              colourName: item.colourName,
              colourHex: item.hexCode,
              initialQuantity: item.quantity,
              unitPricePaise: item.unitPricePaise,
            ),
          )
          .toList(),
    );
    if (!context.mounted) return;
    if (err == null) {
      AppFeedback.showSuccess(
        context,
        'Added ${selected.length} colour${selected.length == 1 ? '' : 's'} to Lot.',
      );
    } else {
      AppFeedback.showError(
        context,
        err.contains('UNIQUE')
            ? context.l10n.colourDuplicateError
            : ValidationLocalizer.localizeDomainCode(
                context.l10n,
                err,
                fallback: err,
              ),
      );
    }
  }
}
