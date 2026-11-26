import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:material_ui/material_ui.dart';

/// Extracted handover timeline row widget for [JobProcessRoutingPage].
final class RoutingHandoverRow extends StatelessWidget {
  const RoutingHandoverRow({
    super.key,
    required this.handover,
    required this.localeCode,
    required this.tone,
    required this.onConfirmReceipt,
    this.colourHex,
  });

  final ProcessHandoverEntity handover;
  final String localeCode;
  final AppStatusTone tone;
  final VoidCallback onConfirmReceipt;
  final String? colourHex;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final h = handover;

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
            AppStatusBadge(label: h.handoverType.label, tone: tone),
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
                '${h.quantityDispatched} ${l10n.piecesUnit}',
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
                '${h.variantLabel} • ${h.quantityReceived}/${h.quantityDispatched} • ${h.status.label}',
                variant: AppTextVariant.bodySmall,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (h.canConfirmReceipt)
              AppButton(
                label: l10n.routingConfirmReceiptAction,
                icon: AppIcons.successOutline,
                variant: AppButtonVariant.text,
                onPressed: onConfirmReceipt,
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

/// Colour-swatch + sequence chip header used in routing operation cards.
final class RoutingOperationHeader extends StatelessWidget {
  const RoutingOperationHeader({
    super.key,
    required this.jobProcess,
    required this.statusTone,
    this.colourHex,
  });

  final JobProcessEntity jobProcess;
  final AppStatusTone statusTone;
  final String? colourHex;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        AppColourSwatch(
          color: AppColourUtils.resolveColor(
            colourHex,
            fallbackName: jobProcess.colourName,
          ),
          size: 26,
          borderRadius: AppRadius.smBorder,
        ),
        const SizedBox(width: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.secondary.withValues(alpha: 0.16),
            borderRadius: AppRadius.smBorder,
          ),
          child: AppText(
            '#${jobProcess.sequenceOrder}',
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
                jobProcess.processName,
                variant: AppTextVariant.bodyLarge,
                fontWeight: FontWeight.w700,
              ),
              AppText(
                '${jobProcess.workerName ?? l10n.routingUnassignedWorker} • ${jobProcess.variantLabel}',
                variant: AppTextVariant.bodySmall,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        AppStatusBadge(label: jobProcess.status.label, tone: statusTone),
      ],
    );
  }
}
