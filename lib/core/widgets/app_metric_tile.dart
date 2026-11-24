import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/widgets/app_animated_number.dart';
import 'package:business_manager/core/widgets/app_card.dart';
import 'package:business_manager/core/widgets/app_status_badge.dart';
import 'package:material_ui/material_ui.dart';

/// Frosted glass KPI summary tile for dashboards, inventory, stock, and
/// accounting headers with animated tabular numerals and luminous icon badge.
final class AppMetricTile extends StatelessWidget {
  const AppMetricTile({
    super.key,
    required this.label,
    required this.value,
    this.isCurrencyPaise = false,
    this.suffix,
    this.subtitle,
    this.icon,
    this.tone = AppStatusTone.neutral,
    this.onTap,
    this.isGlass = true,
    this.backdropKey,
  });

  final String label;
  final int value;
  final bool isCurrencyPaise;
  final String? suffix;
  final String? subtitle;
  final IconData? icon;
  final AppStatusTone tone;
  final VoidCallback? onTap;
  final bool isGlass;
  final BackdropKey? backdropKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final semantic = context.semanticColors;

    final (Color accent, Color accentBg) = switch (tone) {
      AppStatusTone.good => (semantic.goodStock, semantic.goodStockContainer),
      AppStatusTone.pending => (semantic.pending, semantic.pendingContainer),
      AppStatusTone.damaged => (semantic.damaged, semantic.damagedContainer),
      AppStatusTone.info => (
        semantic.advanceCredit,
        semantic.advanceCreditContainer,
      ),
      AppStatusTone.neutral => (
        colorScheme.primary,
        colorScheme.primaryContainer.withValues(alpha: 0.72),
      ),
    };

    final semanticValue = isCurrencyPaise
        ? '₹${(value / 100).toStringAsFixed(2)}'
        : '$value${suffix ?? ''}';

    return Semantics(
      container: true,
      button: onTap != null,
      label: subtitle != null && subtitle!.isNotEmpty
          ? '$label: $semanticValue. $subtitle'
          : '$label: $semanticValue',
      child: AppCard(
      isGlass: isGlass,
      backdropKey: backdropKey,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: accentBg.withValues(alpha: 0.85),
                    borderRadius: AppRadius.mdBorder,
                    border: Border.all(
                      color: accent.withValues(alpha: 0.25),
                      width: 0.9,
                    ),
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: AppAnimatedNumber(
              value: value,
              isCurrencyPaise: isCurrencyPaise,
              suffix: suffix,
              color: tone == AppStatusTone.neutral
                  ? colorScheme.onSurface
                  : accent,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 19,
              ),
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      ),
    );
  }
}
