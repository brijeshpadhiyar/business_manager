import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/design_system/app_typography.dart';
import 'package:material_ui/material_ui.dart';

enum AppStatusTone { good, pending, damaged, info, neutral }

/// Semantic status pill backed by `AppSemanticColors` with crisp tonal border,
/// tabular numerals for quantities/amounts, and safe multi-line wrapping for
/// longer Gujarati labels.
final class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    super.key,
    required this.label,
    this.tone = AppStatusTone.neutral,
    this.icon,
    this.maxLines = 2,
  });

  final String label;
  final AppStatusTone tone;
  final IconData? icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final colorScheme = Theme.of(context).colorScheme;
    final (Color fg, Color bg) = switch (tone) {
      AppStatusTone.good => (semantic.goodStock, semantic.goodStockContainer),
      AppStatusTone.pending => (semantic.pending, semantic.pendingContainer),
      AppStatusTone.damaged => (semantic.damaged, semantic.damagedContainer),
      AppStatusTone.info => (
        semantic.advanceCredit,
        semantic.advanceCreditContainer,
      ),
      AppStatusTone.neutral => (
        colorScheme.onSurfaceVariant,
        colorScheme.surfaceContainerHighest,
      ),
    };

    final labelStyle = AppTypography.tabular(
      (Theme.of(context).textTheme.labelMedium ?? const TextStyle(fontSize: 12))
          .copyWith(color: fg, fontWeight: FontWeight.w600),
    );

    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2,
          vertical: AppSpacing.xs + 1,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.fullBorder,
          border: Border.all(color: fg.withValues(alpha: 0.24), width: 0.8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: AppSizing.iconSm - 2, color: fg),
              const SizedBox(width: AppSpacing.xs),
            ],
            Flexible(
              child: Text(
                label,
                style: labelStyle,
                softWrap: true,
                maxLines: maxLines,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
