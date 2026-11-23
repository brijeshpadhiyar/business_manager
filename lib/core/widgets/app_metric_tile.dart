import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/widgets/app_animated_number.dart';
import 'package:business_manager/core/widgets/app_card.dart';
import 'package:business_manager/core/widgets/app_status_badge.dart';
import 'package:material_ui/material_ui.dart';

/// Premium KPI summary tile for dashboards, inventory, and accounting headers.
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
    this.isGlass = false,
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
        colorScheme.primaryContainer.withValues(alpha: 0.65),
      ),
    };

    return AppCard(
      isGlass: isGlass,
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accentBg,
                    borderRadius: AppRadius.mdBorder,
                  ),
                  child: Icon(icon, size: 17, color: accent),
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
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AppAnimatedNumber(
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
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}
