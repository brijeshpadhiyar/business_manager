import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/lots/presentation/widgets/lot_create_form_models.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Card for one design group inside [LotCreatePage].
final class LotCreateDesignCard extends StatelessWidget {
  const LotCreateDesignCard({
    super.key,
    required this.design,
    required this.onPickColours,
    required this.onRemoveDesign,
    required this.onRemoveColour,
    required this.onValueChanged,
  });

  final DesignBlockState design;
  final VoidCallback onPickColours;
  final VoidCallback onRemoveDesign;
  final ValueChanged<ColourVariantRowState> onRemoveColour;
  final VoidCallback onValueChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppActionRow(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  design.designName,
                  variant: AppTextVariant.bodyLarge,
                  fontWeight: FontWeight.w700,
                ),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    AppText(
                      '${design.colours.length} colour(s) • ${MoneyFormatter.formatQuantity(design.totalQty)} pcs',
                      variant: AppTextVariant.bodySmall,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    if (design.defaultUnitPricePaise > 0)
                      AppStatusBadge(
                        label: context.l10n.lotDefaultPriceValue(
                          MoneyFormatter.formatPaise(
                            design.defaultUnitPricePaise,
                          ),
                        ),
                        tone: AppStatusTone.info,
                      ),
                  ],
                ),
              ],
            ),
            actions: [
              AppButton(
                label: context.l10n.lotColoursLabel,
                icon: AppIcons.colour,
                variant: AppButtonVariant.outlined,
                onPressed: onPickColours,
              ),
              AppIconButton(
                icon: AppIcons.delete,
                tooltip: context.l10n.lotRemoveDesign,
                onPressed: onRemoveDesign,
              ),
            ],
          ),
          if (design.colours.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final c in design.colours)
              LotCreateColourRow(
                key: ValueKey<String>(c.id),
                colour: c,
                onRemove: () => onRemoveColour(c),
                onChanged: onValueChanged,
              ),
          ],
        ],
      ),
    );
  }
}

/// Editable colour variant row inside [LotCreatePage].
final class LotCreateColourRow extends StatelessWidget {
  const LotCreateColourRow({
    super.key,
    required this.colour,
    required this.onRemove,
    required this.onChanged,
  });

  final ColourVariantRowState colour;
  final VoidCallback onRemove;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final lineTotalPaise = colour.quantity * colour.unitPricePaise;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          borderRadius: AppRadius.smBorder,
          color: colorScheme.surfaceContainerLowest.withValues(alpha: 0.45),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.7),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppColourSwatch(
                  color: AppColourUtils.resolveColor(colour.colourHex),
                  size: 26,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppText(
                    colour.colourName,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (lineTotalPaise > 0)
                  AppText(
                    MoneyFormatter.formatPaise(lineTotalPaise),
                    variant: AppTextVariant.numeric,
                    fontWeight: FontWeight.w600,
                  ),
                AppIconButton(
                  icon: AppIcons.close,
                  tooltip: context.l10n.lotRemoveColour,
                  onPressed: onRemove,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: colour.qtyCtrl,
                    validator: ValidationLocalizer.wrap(
                      context.l10n,
                      (v) => AppValidators.quantityValidator(v),
                    ),
                    label: context.l10n.lotQtyPcsLabel,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppTextField(
                    controller: colour.priceCtrl,
                    validator: ValidationLocalizer.wrap(
                      context.l10n,
                      (v) => AppValidators.nonNegativeAmountValidator(
                        v,
                        isRequired: false,
                      ),
                    ),
                    label: context.l10n.lotUnitPriceLabel,
                    hint: '0.00',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [AppInputFormatters.currencyDecimal],
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
