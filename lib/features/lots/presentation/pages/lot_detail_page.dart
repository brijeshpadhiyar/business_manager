import 'package:business_manager/core/platform/platform_env.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';
import 'package:business_manager/features/guidance/presentation/registry/guide_target_registry.dart';
import 'package:business_manager/features/lots/domain/entities/colour_master_entity.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/lots/presentation/bloc/lot_detail_cubit.dart';
import 'package:business_manager/features/lots/presentation/widgets/visual_colour_picker_sheet.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

final class LotDetailPage extends StatelessWidget {
  const LotDetailPage({super.key, required this.lotId});

  final String lotId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LotDetailCubit>(
      create: (_) => getIt<LotDetailCubit>()..loadLot(lotId),
      child: _LotDetailView(lotId: lotId),
    );
  }
}

final class _LotDetailView extends StatelessWidget {
  const _LotDetailView({required this.lotId});

  final String lotId;

  Future<void> _pickAndSavePhoto(
    BuildContext context,
    ImageSource source,
  ) async {
    final cubit = context.read<LotDetailCubit>();
    final picker = ImagePicker();
    final XFile? picked;
    try {
      picked = await getIt<AppLockCubit>().runWithSystemPicker(
        () => picker.pickImage(
          source: source,
          maxWidth: 1600,
          maxHeight: 1600,
          imageQuality: 80,
        ),
      );
    } catch (_) {
      // e.g. no camera / picker unavailable on this device: do nothing.
      return;
    }
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final ext = picked.name.contains('.') ? picked.name.split('.').last : 'jpg';
    final err = await cubit.addPhoto(
      lotId: lotId,
      bytes: bytes,
      fileExtension: ext,
      mimeType: picked.mimeType ?? 'image/jpeg',
    );
    if (err != null && context.mounted) {
      AppFeedback.showError(
        context,
        ValidationLocalizer.localizeDomainCode(
          context.l10n,
          err,
          fallback: context.l10n.errorUnexpected,
        ),
      );
    }
  }

  Future<void> _showEditLotSheet(BuildContext context, LotEntity lot) async {
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

  Future<void> _showDesignSheet(
    BuildContext context, {
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

  Future<void> _showColourSheet(
    BuildContext context, {
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocSelector<
      LotDetailCubit,
      LotDetailState,
      ({LotDetailStatus status, LotDetailAggregate? detail, String? error})
    >(
      selector: (s) =>
          (status: s.status, detail: s.detail, error: s.errorMessage),
      builder: (context, slice) {
        final detail = slice.detail;
        return AppScaffold(
          title: detail?.lot.lotNumber ?? l10n.lotsHeading,
          actions: detail == null
              ? null
              : [
                  AppIconButton(
                    icon: AppIcons.edit,
                    tooltip: l10n.lotEditAction,
                    onPressed: () => _showEditLotSheet(context, detail.lot),
                  ),
                  AppIconButton(
                    icon: AppIcons.archive,
                    tooltip: l10n.lotArchiveAction,
                    onPressed: () async {
                      final confirmed = await AppDialog.showConfirmation(
                        context,
                        title: l10n.lotArchiveConfirmTitle,
                        message: l10n.lotArchiveConfirmMessage,
                        confirmLabel: l10n.lotArchiveAction,
                        cancelLabel: l10n.actionCancel,
                        isDestructive: true,
                      );
                      if (confirmed == true && context.mounted) {
                        await context.read<LotDetailCubit>().archiveLot(
                          detail.lot.id,
                        );
                        if (context.mounted) context.pop();
                      }
                    },
                  ),
                ],
          padding: EdgeInsets.zero,
          body: switch (slice.status) {
            LotDetailStatus.initial ||
            LotDetailStatus.loading => const AppLoader(),
            LotDetailStatus.error => AppErrorView(
              title: l10n.errorUnexpected,
              message: slice.error,
              retryLabel: l10n.actionRetry,
              onRetry: () => context.read<LotDetailCubit>().loadLot(lotId),
            ),
            LotDetailStatus.loaded => _buildLoaded(context, detail!),
          },
        );
      },
    );
  }

  Future<void> _showVisualColourPicker(
    BuildContext context, {
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

  Widget _buildLoaded(BuildContext context, LotDetailAggregate detail) {
    final l10n = context.l10n;
    final totalInitialPieces = detail.designs.fold<int>(
      0,
      (s, d) => s + d.colours.fold<int>(0, (cs, c) => cs + c.initialQuantity),
    );

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppActionRow(
                        content: AppText(
                          detail.lot.lotNumber,
                          variant: AppTextVariant.bodyLarge,
                          fontWeight: FontWeight.w700,
                        ),
                        actions: [
                          AppStatusBadge(
                            label: detail.lot.status == LotStatus.active
                                ? l10n.lotsStatusActive
                                : l10n.lotsStatusCompleted,
                            tone: detail.lot.status == LotStatus.active
                                ? AppStatusTone.good
                                : AppStatusTone.info,
                          ),
                        ],
                      ),
                      if (detail.lot.title != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        AppText(detail.lot.title!),
                      ],
                      const SizedBox(height: AppSpacing.xs),
                      AppText(
                        '${l10n.lotDateLabel}: ${IstDateTimeHelper.toIstBusinessDate(detail.lot.transactionAt)}',
                        variant: AppTextVariant.bodySmall,
                      ),
                      if (detail.lot.notes != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        AppText(
                          detail.lot.notes!,
                          variant: AppTextVariant.bodySmall,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: context.l10n.lotRoutingHandovers,
                        icon: AppIcons.routeTransfer,
                        isExpanded: true,
                        onPressed: () =>
                            context.push(RoutePaths.lotRouting(lotId)),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: l10n.prodHistoryViewLotHistory,
                              icon: AppIcons.productionHistory,
                              variant: AppButtonVariant.secondary,
                              onPressed: () =>
                                  context.push(RoutePaths.lotHistory(lotId)),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: AppButton(
                              label: l10n.prodHistoryViewTimeline,
                              icon: AppIcons.timeline,
                              variant: AppButtonVariant.outlined,
                              onPressed: () =>
                                  context.push(RoutePaths.lotTimeline(lotId)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                AppHeading(l10n.lotPhotosHeading, level: AppHeadingLevel.h3),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    // Desktop builds (Windows / macOS / Linux) have no camera
                    // capture: only "choose from files" is offered there.
                    if (supportsCameraCapture)
                      AppButton(
                        label: l10n.lotAddPhotoCamera,
                        icon: AppIcons.camera,
                        variant: AppButtonVariant.outlined,
                        onPressed: () =>
                            _pickAndSavePhoto(context, ImageSource.camera),
                      ),
                    AppButton(
                      label: l10n.lotAddPhotoGallery,
                      icon: AppIcons.gallery,
                      variant: AppButtonVariant.secondary,
                      onPressed: () =>
                          _pickAndSavePhoto(context, ImageSource.gallery),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (detail.photos.isEmpty)
                  AppCard.listItem(
                    child: AppText(
                      l10n.lotPhotosEmpty,
                      variant: AppTextVariant.bodySmall,
                    ),
                  )
                else
                  SizedBox(
                    height: 112,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: detail.photos.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: AppSpacing.sm),
                      itemBuilder: (ctx, i) {
                        final photo = detail.photos[i];
                        return _LotPhotoTile(
                          key: ValueKey<String>(photo.id),
                          photo: photo,
                          onRemove: () async {
                            final ok = await AppDialog.showConfirmation(
                              ctx,
                              title: l10n.actionDelete,
                              message: l10n.lotPhotoRemoveConfirm,
                              confirmLabel: l10n.actionDelete,
                              cancelLabel: l10n.actionCancel,
                              isDestructive: true,
                            );
                            if (ok == true && ctx.mounted) {
                              await ctx.read<LotDetailCubit>().removePhoto(
                                lotId,
                                photo.id,
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                const SizedBox(height: AppSpacing.lg),
                AppHeading(
                  '${l10n.designsHeading} ($totalInitialPieces pcs)',
                  level: AppHeadingLevel.h3,
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppButton(
                      label: context.l10n.lotAddColourNoDesign,
                      icon: AppIcons.colour,
                      variant: AppButtonVariant.secondary,
                      onPressed: () {
                        final colourOnlyGroup = detail.designs
                            .where(
                              (d) =>
                                  d.design.designName ==
                                  kColourOnlyDesignSentinel,
                            )
                            .firstOrNull;
                        final existingNames = colourOnlyGroup == null
                            ? const <String>{}
                            : colourOnlyGroup.colours
                                  .map((c) => c.colourName)
                                  .toSet();
                        _showVisualColourPicker(
                          context,
                          existingColourNames: existingNames,
                        );
                      },
                    ),
                    GuideTarget(
                      id: GuideTargetId.lotDetailAddDesign,
                      child: AppButton(
                        label: l10n.designAddAction,
                        icon: AppIcons.add,
                        onPressed: () => _showDesignSheet(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                if (detail.designs.isNotEmpty) ...[
                  AppSearchField(
                    label: l10n.designsSearchHint,
                    debounceDuration: const Duration(milliseconds: 120),
                    onChanged: context.read<LotDetailCubit>().setDesignSearch,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
        ),
        // Only the filtered designs sliver rebuilds on Design Search typing —
        // zero database reads, zero disk reads, zero photo/header rebuilds.
        BlocSelector<
          LotDetailCubit,
          LotDetailState,
          ({
            String query,
            Map<String, DesignColourStockBalance> balancesByColourId,
            Map<String, List<JobProcessEntity>> operationsByColourId,
          })
        >(
          selector: (s) => (
            query: s.designSearchQuery,
            balancesByColourId: s.balancesByColourId,
            operationsByColourId: s.operationsByColourId,
          ),
          builder: (context, slice) {
            final query = slice.query.trim().toLowerCase();
            final filteredDesigns = query.isEmpty
                ? detail.designs
                : detail.designs
                      .where(
                        (d) =>
                            d.design.designName.toLowerCase().contains(query) ||
                            d.colours.any(
                              (c) => c.colourName.toLowerCase().contains(query),
                            ),
                      )
                      .toList(growable: false);

            if (filteredDesigns.isEmpty) {
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                sliver: SliverToBoxAdapter(
                  child: AppEmptyState(
                    icon: AppIcons.designs,
                    title: l10n.designsEmptyTitle,
                    subtitle: l10n.designsEmptySubtitle,
                    actionLabel: l10n.designAddAction,
                    onAction: () => _showDesignSheet(context),
                  ),
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              sliver: SliverList.separated(
                itemCount: filteredDesigns.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (ctx, i) {
                  final item = filteredDesigns[i];
                  return _buildDesignSectionCard(
                    ctx,
                    item,
                    slice.balancesByColourId,
                    slice.operationsByColourId,
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDesignSectionCard(
    BuildContext context,
    DesignWithColours item,
    Map<String, DesignColourStockBalance> balancesByColourId,
    Map<String, List<JobProcessEntity>> operationsByColourId,
  ) {
    final l10n = context.l10n;
    final isColourOnly = item.design.designName == kColourOnlyDesignSentinel;
    final designLabel = isColourOnly
        ? 'Colours (No Design)'
        : item.design.designName;

    return AppCard.listItem(
      key: ValueKey<String>(item.design.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      designLabel,
                      variant: AppTextVariant.bodyLarge,
                      fontWeight: FontWeight.w700,
                    ),
                    AppText(
                      'Total: ${item.colours.fold<int>(0, (s, c) => s + c.initialQuantity)} pcs • ${item.colours.length} colour${item.colours.length == 1 ? '' : 's'}',
                      variant: AppTextVariant.bodySmall,
                    ),
                  ],
                ),
              ),
              if (!isColourOnly)
                AppIconButton(
                  icon: AppIcons.edit,
                  tooltip: l10n.designEditAction,
                  onPressed: () =>
                      _showDesignSheet(context, existing: item.design),
                ),
              AppIconButton(
                icon: AppIcons.delete,
                tooltip: l10n.actionDelete,
                onPressed: () async {
                  final ok = await AppDialog.showConfirmation(
                    context,
                    title: l10n.designDeleteConfirmTitle,
                    message: l10n.designDeleteConfirmMessage,
                    confirmLabel: l10n.actionDelete,
                    cancelLabel: l10n.actionCancel,
                    isDestructive: true,
                  );
                  if (ok == true && context.mounted) {
                    await context.read<LotDetailCubit>().deleteDesign(
                      lotId,
                      item.design.id,
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: l10n.colourAddAction,
              icon: AppIcons.colour,
              variant: AppButtonVariant.secondary,
              onPressed: () => _showVisualColourPicker(
                context,
                lotDesignId: isColourOnly ? null : item.design.id,
                designDisplayName: isColourOnly ? null : item.design.designName,
                existingColourNames: item.colours
                    .map((c) => c.colourName)
                    .toSet(),
              ),
            ),
          ),
          if (item.colours.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth >= 680
                    ? 3
                    : (constraints.maxWidth >= 340 ? 2 : 1);
                final cardWidth =
                    (constraints.maxWidth - (AppSpacing.sm * (cols - 1))) /
                    cols;
                return Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    for (final c in item.colours)
                      SizedBox(
                        width: cardWidth,
                        child: _PremiumLotColourCard(
                          key: ValueKey<String>(c.id),
                          colour: c,
                          designName: isColourOnly
                              ? null
                              : item.design.designName,
                          balance: balancesByColourId[c.id],
                          operations:
                              operationsByColourId[c.id] ??
                              const <JobProcessEntity>[],
                          onTap: () async {
                            await context.push(
                              RoutePaths.lotColourDetail(lotId, c.id),
                            );
                            if (context.mounted) {
                              await context.read<LotDetailCubit>().loadLot(
                                lotId,
                              );
                            }
                          },
                          onEdit: () => _showColourSheet(
                            context,
                            lotDesignId: item.design.id,
                            existing: c,
                          ),
                          onDelete: () async {
                            final ok = await AppDialog.showConfirmation(
                              context,
                              title: l10n.colourDeleteConfirmTitle,
                              message: l10n.colourDeleteConfirmMessage,
                              confirmLabel: l10n.actionDelete,
                              cancelLabel: l10n.actionCancel,
                              isDestructive: true,
                            );
                            if (ok == true && context.mounted) {
                              await context.read<LotDetailCubit>().deleteColour(
                                lotId,
                                c.id,
                              );
                            }
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

/// StitchFlow V1.3 — Premium Clickable Lot Colour Card with large actual
/// colour preview banner, HEX code, design label, quantities, current stage,
/// and current stock location.
final class _PremiumLotColourCard extends StatelessWidget {
  const _PremiumLotColourCard({
    super.key,
    required this.colour,
    this.designName,
    this.balance,
    required this.operations,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final DesignColourEntity colour;
  final String? designName;
  final DesignColourStockBalance? balance;
  final List<JobProcessEntity> operations;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _resolveCurrentStage() {
    if (operations.isEmpty) return 'Not Started';
    final active = operations.where((op) => !op.status.isTerminal).toList();
    if (active.isNotEmpty) {
      return active.last.processName;
    }
    return '${operations.last.processName} (Done)';
  }

  String _resolveStockLocation() {
    final inHouse = balance?.physicalAvailableInHouse ?? colour.initialQuantity;
    final withWorkers = balance?.totalPendingWithWorkers ?? 0;
    if (withWorkers == 0) {
      return 'Factory ($inHouse pcs)';
    }
    final activeHolders = operations
        .where((op) => op.pendingQuantity > 0 && op.workerName != null)
        .map((op) => op.workerName!)
        .toSet()
        .toList();
    if (inHouse == 0 && activeHolders.length == 1) {
      return '${activeHolders.first} ($withWorkers pcs)';
    }
    return 'Factory $inHouse • Workers $withWorkers';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final swatch = AppColourUtils.resolveColor(
      colour.colourHex,
      fallbackName: colour.colourName,
    );
    final hexLabel =
        AppColourUtils.normalizeHex(colour.colourHex) ??
        AppColourUtils.toHex(swatch);
    final onSwatch = AppColourUtils.contrastForeground(swatch);
    final borderColor = AppColourUtils.swatchBorderColor(swatch, brightness);

    final totalQty = colour.initialQuantity;
    final pendingQty = balance?.totalPendingWithWorkers ?? 0;
    final completedQty = operations.fold<int>(
      0,
      (sum, op) =>
          sum + op.returnedToFactoryQuantity + op.transferredOutQuantity,
    );
    final stageLabel = _resolveCurrentStage();
    final locationLabel = _resolveStockLocation();

    return AppCard.listItem(
      padding: EdgeInsets.zero,
      borderRadius: AppRadius.lgBorder,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Large Actual Colour Preview Banner (tall enough for 44dp
          // edit / delete touch targets plus the colour name).
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xsm,
            ),
            decoration: BoxDecoration(
              color: swatch,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.lg),
              ),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xsm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: onSwatch.withValues(alpha: 0.14),
                          borderRadius: AppRadius.smBorder,
                          border: Border.all(
                            color: onSwatch.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Text(
                          hexLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: onSwatch,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // 44dp touch targets (were ~24dp) so edit/delete are
                    // easy to hit on a phone.
                    AppIconButton(
                      onPressed: onEdit,
                      tooltip: context.l10n.colourEditAction,
                      compact: true,
                      color: onSwatch,
                      icon: AppIcons.edit,
                    ),
                    AppIconButton(
                      onPressed: onDelete,
                      tooltip: MaterialLocalizations.of(context)
                          .deleteButtonTooltip,
                      compact: true,
                      color: onSwatch,
                      icon: AppIcons.delete,
                    ),
                  ],
                ),
                Text(
                  colour.colourName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(color: onSwatch, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          // Card Body Metrics
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (designName != null && designName!.isNotEmpty) ...[
                  AppText(
                    context.l10n.lotDesignValue(designName!),
                    variant: AppTextVariant.bodySmall,
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                ],
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: AppSpacing.sm,
                  runSpacing: 4,
                  children: [
                    _MiniMetric(
                      label: context.l10n.lotTotalLabel,
                      value: '$totalQty',
                    ),
                    _MiniMetric(
                      label: context.l10n.lotDoneLabel,
                      value: '$completedQty',
                    ),
                    _MiniMetric(
                      label: context.l10n.statusPending,
                      value: '$pendingQty',
                      highlight: pendingQty > 0,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xsm),
                Row(
                  children: [
                    Icon(
                      AppIcons.processIcon(stageLabel),
                      size: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: AppText(
                        stageLabel,
                        variant: AppTextVariant.bodySmall,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Icon(
                      AppIcons.location,
                      size: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: AppText(
                        locationLabel,
                        variant: AppTextVariant.bodySmall,
                        color: colorScheme.onSurfaceVariant,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          variant: AppTextVariant.bodySmall,
          color: colorScheme.onSurfaceVariant,
        ),
        AppText(
          value,
          variant: AppTextVariant.numeric,
          fontWeight: FontWeight.w700,
          color: highlight ? colorScheme.tertiary : colorScheme.onSurface,
        ),
      ],
    );
  }
}

final class _LotPhotoTile extends StatefulWidget {
  const _LotPhotoTile({super.key, required this.photo, required this.onRemove});

  final LotAttachmentEntity photo;
  final VoidCallback onRemove;

  @override
  State<_LotPhotoTile> createState() => _LotPhotoTileState();
}

final class _LotPhotoTileState extends State<_LotPhotoTile> {
  late Future<Uint8List?> _photoFuture;

  @override
  void initState() {
    super.initState();
    _photoFuture = context.read<LotDetailCubit>().readPhotoBytes(
      widget.photo.relativePath,
    );
  }

  @override
  void didUpdateWidget(covariant _LotPhotoTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photo.relativePath != widget.photo.relativePath) {
      _photoFuture = context.read<LotDetailCubit>().readPhotoBytes(
        widget.photo.relativePath,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final thumbCachePx = (112 * dpr).round().clamp(112, 448);

    return FutureBuilder<Uint8List?>(
      future: _photoFuture,
      builder: (context, snapshot) {
        Widget preview;
        if (snapshot.connectionState == ConnectionState.waiting) {
          preview = const AppLoader.inline(size: 20);
        } else if (snapshot.data == null) {
          preview = Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(AppIcons.imageError),
                  AppText(
                    l10n.lotPhotoMissing,
                    variant: AppTextVariant.bodySmall,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          );
        } else {
          final bytes = snapshot.data!;
          preview = InkWell(
            onTap: () => AppDialog.showCustom<void>(
              context,
              builder: (dlgCtx) => AppDialog(
                title: l10n.lotPhotosHeading,
                cancelLabel: l10n.actionClose,
                content: InteractiveViewer(
                  child: ClipRRect(
                    borderRadius: AppRadius.mdBorder,
                    child: Image(
                      // Decode at most 2x screen width (zoom headroom), not
                      // the camera's full size, so large photos open quickly
                      // and use far less memory. Small photos are not upscaled.
                      image: ResizeImage(
                        MemoryImage(bytes),
                        width:
                            (MediaQuery.sizeOf(dlgCtx).width *
                                    MediaQuery.devicePixelRatioOf(dlgCtx) *
                                    2)
                                .round(),
                        policy: ResizeImagePolicy.fit,
                      ),
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
            ),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              cacheWidth: thumbCachePx,
              gaplessPlayback: true,
            ),
          );
        }

        return SizedBox(
          width: 112,
          height: 112,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: AppRadius.mdBorder,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                  ),
                  child: preview,
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: AppIconButton(
                  isFilled: true,
                  compact: true,
                  tooltip: l10n.actionDelete,
                  icon: AppIcons.close,
                  onPressed: widget.onRemove,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
