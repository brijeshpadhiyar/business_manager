import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/lots/domain/entities/colour_master_entity.dart';
import 'package:business_manager/features/lots/domain/repositories/colour_master_repository.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Visual Multi-Select Colour Picker, Quantity & Direct SKU Unit Price Sheet.
///
/// Features:
/// - Visual textile swatch grid with actual colour previews & HEX codes
/// - Search by name or HEX
/// - Recently Used swatch strip
/// - Multi-select & deselect with animated check rings
/// - Per-selected-colour Quantity (pcs) AND Unit Price (₹/pc) entry with
///   automatic total quantity & Indian Rupee valuation
/// - Custom colour creation & editing with HEX input + R/G/B sliders
final class VisualColourPickerSheet {
  static Future<List<SelectedColourVariantInput>?> show(
    BuildContext context, {
    required String title,
    Set<String> existingColourNamesLower = const {},
    int defaultUnitPricePaise = 0,
  }) async {
    final repo = getIt<ColourMasterRepository>();
    final allColours = await repo.getAllColours();
    final recentColours = await repo.getRecentColours();
    if (!context.mounted) return null;

    return AppBottomSheet.show<List<SelectedColourVariantInput>>(
      context,
      title: title,
      builder: (sheetCtx) => _VisualColourPickerContent(
        repo: repo,
        initialAllColours: allColours,
        initialRecentColours: recentColours,
        existingColourNamesLower: existingColourNamesLower,
        defaultUnitPricePaise: defaultUnitPricePaise,
      ),
    );
  }
}

final class _VisualColourPickerContent extends StatefulWidget {
  const _VisualColourPickerContent({
    required this.repo,
    required this.initialAllColours,
    required this.initialRecentColours,
    required this.existingColourNamesLower,
    required this.defaultUnitPricePaise,
  });

  final ColourMasterRepository repo;
  final List<ColourMasterEntity> initialAllColours;
  final List<ColourMasterEntity> initialRecentColours;
  final Set<String> existingColourNamesLower;
  final int defaultUnitPricePaise;

  @override
  State<_VisualColourPickerContent> createState() =>
      _VisualColourPickerContentState();
}

final class _VisualColourPickerContentState
    extends State<_VisualColourPickerContent> {
  late List<ColourMasterEntity> allColours;
  late List<ColourMasterEntity> recentColours;
  final Set<String> selectedIds = <String>{};
  final Map<String, TextEditingController> qtyControllers =
      <String, TextEditingController>{};
  final Map<String, TextEditingController> priceControllers =
      <String, TextEditingController>{};
  final TextEditingController searchCtrl = TextEditingController();
  String? error;

  ColourMasterRepository get repo => widget.repo;
  Set<String> get existingColourNamesLower => widget.existingColourNamesLower;

  String get _defaultPriceText => widget.defaultUnitPricePaise > 0
      ? MoneyFormatter.formatPaiseForInput(widget.defaultUnitPricePaise)
      : '';

  @override
  void initState() {
    super.initState();
    allColours = List<ColourMasterEntity>.of(widget.initialAllColours);
    recentColours = List<ColourMasterEntity>.of(widget.initialRecentColours);
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    for (final c in qtyControllers.values) {
      c.dispose();
    }
    for (final c in priceControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sheetCtx = context;
    final ctx = context;
    void setSheetState(VoidCallback fn) {
      if (mounted) setState(fn);
    }

    final q = searchCtrl.text.trim().toLowerCase();
    final filtered = allColours
        .where(
          (c) =>
              q.isEmpty ||
              c.name.toLowerCase().contains(q) ||
              c.hexCode.toLowerCase().contains(q),
        )
        .toList();

    final selectedList = allColours
        .where((c) => selectedIds.contains(c.id))
        .toList();
    var totalQty = 0;
    var totalValuePaise = 0;
    for (final c in selectedList) {
      final qty = int.tryParse(qtyControllers[c.id]?.text.trim() ?? '') ?? 0;
      final parsedPrice = AppValidators.parseRupeesToPaiseExact(
        priceControllers[c.id]?.text ?? '',
        isRequired: false,
        allowZero: true,
      );
      final pricePaise = parsedPrice.paise ?? 0;
      totalQty += qty;
      totalValuePaise += qty * pricePaise;
    }

    void toggleColour(ColourMasterEntity c) {
      setSheetState(() {
        error = null;
        if (selectedIds.contains(c.id)) {
          selectedIds.remove(c.id);
        } else {
          selectedIds.add(c.id);
          qtyControllers.putIfAbsent(
            c.id,
            () => TextEditingController(text: '100'),
          );
          priceControllers.putIfAbsent(
            c.id,
            () => TextEditingController(text: _defaultPriceText),
          );
        }
      });
    }

    Future<void> openCustomColourDialog({
      ColourMasterEntity? editTarget,
    }) async {
      final initColor = editTarget != null
          ? AppColourUtils.resolveColor(editTarget.hexCode)
          : const Color(0xFF0D9488);
      final nameCtrl = TextEditingController(text: editTarget?.name ?? '');
      final hexCtrl = TextEditingController(
        text: editTarget?.hexCode ?? AppColourUtils.toHex(initColor),
      );
      var r = (initColor.r * 255).round();
      var g = (initColor.g * 255).round();
      var b = (initColor.b * 255).round();
      String? dlgError;

      try {
        final saved = await AppDialog.showCustom<ColourMasterEntity>(
          ctx,
          builder: (dCtx) => StatefulBuilder(
            builder: (innerCtx, setDlgState) {
              final previewColor = Color.fromARGB(255, r, g, b);
              return AppDialog(
                title: editTarget == null ? 'Add Custom Colour' : 'Edit Colour',
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          AppColourSwatch(
                            color: previewColor,
                            size: 52,
                            borderRadius: AppRadius.lgBorder,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppTextField(
                              controller: nameCtrl,
                              validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.requiredValidator(v)),
                              label: 'Colour Name',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppTextField(
                        controller: hexCtrl,
                        validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.hexColorValidator(v)),
                        label: 'HEX Code (e.g. #DC2626)',
                        onChanged: (val) {
                          final norm = AppColourUtils.normalizeHex(val);
                          if (norm != null) {
                            final parsed = AppColourUtils.resolveColor(norm);
                            setDlgState(() {
                              r = (parsed.r * 255).round();
                              g = (parsed.g * 255).round();
                              b = (parsed.b * 255).round();
                            });
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _RgbSlider(
                        label: 'R',
                        value: r,
                        activeColor: Colors.red,
                        onChanged: (v) => setDlgState(() {
                          r = v;
                          hexCtrl.text = AppColourUtils.rgbToHex(r, g, b);
                        }),
                      ),
                      _RgbSlider(
                        label: 'G',
                        value: g,
                        activeColor: Colors.green,
                        onChanged: (v) => setDlgState(() {
                          g = v;
                          hexCtrl.text = AppColourUtils.rgbToHex(r, g, b);
                        }),
                      ),
                      _RgbSlider(
                        label: 'B',
                        value: b,
                        activeColor: Colors.blue,
                        onChanged: (v) => setDlgState(() {
                          b = v;
                          hexCtrl.text = AppColourUtils.rgbToHex(r, g, b);
                        }),
                      ),
                      if (dlgError != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        AppText(
                          dlgError!,
                          color: Theme.of(innerCtx).colorScheme.error,
                        ),
                      ],
                    ],
                  ),
                ),
                cancelLabel: 'Cancel',
                confirmLabel: 'Save Colour',
                onConfirm: () async {
                  try {
                    final result = editTarget == null
                        ? await repo.createCustomColour(
                            name: nameCtrl.text,
                            hexCode: hexCtrl.text,
                          )
                        : await repo.updateColour(
                            id: editTarget.id,
                            name: nameCtrl.text,
                            hexCode: hexCtrl.text,
                          );
                    if (dCtx.mounted) Navigator.of(dCtx).pop(result);
                  } on DomainValidationException catch (e) {
                    if (dCtx.mounted) {
                      setDlgState(() => dlgError = e.message);
                    }
                  }
                },
              );
            },
          ),
        );
        if (saved != null) {
          allColours = await repo.getAllColours();
          recentColours = await repo.getRecentColours();
          setSheetState(() {
            selectedIds.add(saved.id);
            qtyControllers.putIfAbsent(
              saved.id,
              () => TextEditingController(text: '100'),
            );
            priceControllers.putIfAbsent(
              saved.id,
              () => TextEditingController(text: _defaultPriceText),
            );
          });
        }
      } finally {
        nameCtrl.dispose();
        hexCtrl.dispose();
      }
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(ctx).height * 0.82,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppActionRow(content: AppTextField(
                    controller: searchCtrl,
                    label: 'Search colour name or HEX',
                    prefixIcon: AppIcons.search,
                    onChanged: (_) => setSheetState(() {}),
                  ), actions: [AppButton(
                  label: 'Custom',
                  icon: AppIcons.add,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => openCustomColourDialog(),
                ),],),
            if (recentColours.isNotEmpty && q.isEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              const AppText(
                'Recently Used',
                variant: AppTextVariant.bodySmall,
                fontWeight: FontWeight.w700,
              ),
              const SizedBox(height: AppSpacing.xs),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentColours.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(width: AppSpacing.xs),
                  itemBuilder: (_, idx) {
                    final c = recentColours[idx];
                    final isSel = selectedIds.contains(c.id);
                    return InkWell(
                      borderRadius: AppRadius.fullBorder,
                      onTap: () => toggleColour(c),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: AppRadius.fullBorder,
                          border: Border.all(
                            color: isSel
                                ? Theme.of(ctx).colorScheme.secondary
                                : Theme.of(ctx).colorScheme.outlineVariant,
                            width: isSel ? 1.6 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AppColourSwatch(
                              color: AppColourUtils.resolveColor(c.hexCode),
                              size: 20,
                              borderRadius: AppRadius.fullBorder,
                              isSelected: isSel,
                            ),
                            const SizedBox(width: 6),
                            AppText(c.name, variant: AppTextVariant.bodySmall),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            const AppText(
              'Colour Palette (Tap to select, long-press to edit)',
              variant: AppTextVariant.bodySmall,
              fontWeight: FontWeight.w700,
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final c in filtered)
                  _PaletteSwatchChip(
                    colour: c,
                    isSelected: selectedIds.contains(c.id),
                    alreadyInDesign: existingColourNamesLower.contains(
                      c.name.toLowerCase(),
                    ),
                    onTap: () => toggleColour(c),
                    onLongPress: () => openCustomColourDialog(editTarget: c),
                  ),
              ],
            ),
            if (selectedList.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.spaceBetween,
                children: [
                  AppText(
                    'Selected Colours (${selectedList.length})',
                    fontWeight: FontWeight.w700,
                  ),
                  Wrap(
                    spacing: AppSpacing.xs,
                    children: [
                      AppStatusBadge(
                        label: '${MoneyFormatter.formatQuantity(totalQty)} pcs',
                        tone: AppStatusTone.good,
                      ),
                      if (totalValuePaise > 0)
                        AppStatusBadge(
                          label: MoneyFormatter.formatPaise(totalValuePaise),
                          tone: AppStatusTone.info,
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final c in selectedList) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      borderRadius: AppRadius.mdBorder,
                      border: Border.all(
                        color: Theme.of(ctx).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppColourSwatch(
                              color: AppColourUtils.resolveColor(c.hexCode),
                              size: 30,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(c.name, fontWeight: FontWeight.w600),
                                  AppText(
                                    c.hexCode,
                                    variant: AppTextVariant.bodySmall,
                                    color: Theme.of(
                                      ctx,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                            AppIconButton(
                              icon: AppIcons.close,
                              tooltip: 'Remove',
                              onPressed: () => toggleColour(c),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Expanded(
                              child: AppTextField(
                                controller: qtyControllers[c.id],
                                validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.quantityValidator(v)),
                                label: 'Qty (pcs)',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                onChanged: (_) => setSheetState(() {
                                  error = null;
                                }),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: AppTextField(
                                controller: priceControllers[c.id],
                                validator: ValidationLocalizer.wrap(context.l10n, (v) => AppValidators.nonNegativeAmountValidator(v, isRequired: false)),
                                label: 'Unit Price (₹)',
                                hint: '0.00',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  AppInputFormatters.currencyDecimal,
                                ],
                                onChanged: (_) => setSheetState(() {
                                  error = null;
                                }),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
            if (error != null) ...[
              const SizedBox(height: AppSpacing.xs),
              AppText(error!, color: Theme.of(ctx).colorScheme.error),
            ],
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: selectedList.isEmpty
                  ? 'Select Colours Above'
                  : 'Add ${selectedList.length} Colour(s) • ${MoneyFormatter.formatQuantity(totalQty)} pcs${totalValuePaise > 0 ? ' • ${MoneyFormatter.formatPaise(totalValuePaise)}' : ''}',
              icon: AppIcons.confirm,
              isExpanded: true,
              onPressed: selectedList.isEmpty
                  ? null
                  : () async {
                      final results = <SelectedColourVariantInput>[];
                      for (final c in selectedList) {
                        final qty =
                            int.tryParse(
                              qtyControllers[c.id]?.text.trim() ?? '',
                            ) ??
                            0;
                        if (qty <= 0) {
                          setSheetState(
                            () => error =
                                'Enter a positive quantity for ${c.name}.',
                          );
                          return;
                        }
                        if (qty > ValidationLimits.maxQuantity) {
                          setSheetState(
                            () => error =
                                'Quantity for ${c.name} exceeds maximum limit.',
                          );
                          return;
                        }
                        final parsedPrice =
                            AppValidators.parseRupeesToPaiseExact(
                              priceControllers[c.id]?.text ?? '',
                              isRequired: false,
                              allowZero: true,
                            );
                        if (!parsedPrice.validation.isValid ||
                            parsedPrice.paise == null) {
                          setSheetState(
                            () => error =
                                'Enter a valid non-negative price for ${c.name}.',
                          );
                          return;
                        }
                        results.add(
                          SelectedColourVariantInput(
                            colourName: c.name,
                            hexCode: c.hexCode,
                            quantity: qty,
                            unitPricePaise: parsedPrice.paise!,
                          ),
                        );
                      }
                      await repo.markColoursUsed(
                        results.map((e) => e.colourName).toList(),
                      );
                      if (sheetCtx.mounted) {
                        Navigator.of(sheetCtx).pop(results);
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}

final class _PaletteSwatchChip extends StatelessWidget {
  const _PaletteSwatchChip({
    required this.colour,
    required this.isSelected,
    required this.alreadyInDesign,
    required this.onTap,
    required this.onLongPress,
  });

  final ColourMasterEntity colour;
  final bool isSelected;
  final bool alreadyInDesign;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final swatchColor = AppColourUtils.resolveColor(colour.hexCode);
    return InkWell(
      borderRadius: AppRadius.mdBorder,
      onTap: alreadyInDesign ? null : onTap,
      onLongPress: onLongPress,
      child: Opacity(
        opacity: alreadyInDesign ? 0.45 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: AppRadius.mdBorder,
            color: isSelected
                ? colorScheme.secondary.withValues(alpha: 0.16)
                : colorScheme.surface.withValues(alpha: 0.35),
            border: Border.all(
              color: isSelected
                  ? colorScheme.secondary
                  : colorScheme.outlineVariant,
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppColourSwatch(
                color: swatchColor,
                size: 24,
                borderRadius: AppRadius.smBorder,
                isSelected: isSelected,
                semanticLabel: colour.name,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppText(
                    colour.name,
                    variant: AppTextVariant.bodySmall,
                    fontWeight: FontWeight.w600,
                  ),
                  AppText(
                    alreadyInDesign ? 'Added' : colour.hexCode,
                    variant: AppTextVariant.bodySmall,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _RgbSlider extends StatelessWidget {
  const _RgbSlider({
    required this.label,
    required this.value,
    required this.activeColor,
    required this.onChanged,
  });

  final String label;
  final int value;
  final Color activeColor;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 22, child: AppText(label, fontWeight: FontWeight.w700)),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 0,
            max: 255,
            activeColor: activeColor,
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        SizedBox(
          width: 34,
          child: AppText(
            '$value',
            variant: AppTextVariant.bodySmall,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
