import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_density.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
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
    final d = context.density;
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

    final baseText = d.isCompact
        ? Theme.of(context).textTheme.labelSmall
        : Theme.of(context).textTheme.labelMedium;
    final labelStyle = AppTypography.tabular(
      (baseText ?? TextStyle(fontSize: d.isCompact ? 10.5 : 12)).copyWith(
        color: fg,
        fontWeight: FontWeight.w600,
      ),
    );

    return Semantics(
      label: label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: d.isCompact ? d.xsm + 3 : d.sm + 2,
          vertical: d.isCompact ? d.xxs + 1 : d.xs + 1,
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
              Icon(icon, size: d.iconSm - 2, color: fg),
              SizedBox(width: d.xs),
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
