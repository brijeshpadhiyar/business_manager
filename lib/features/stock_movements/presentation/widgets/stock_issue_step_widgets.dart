import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';

/// Step descriptor used by [StockIssueStepProgressStrip].
final class StockIssueStepItem {
  const StockIssueStepItem({
    required this.number,
    required this.label,
    required this.completed,
    required this.active,
  });

  final int number;
  final String label;
  final bool completed;
  final bool active;
}

/// Horizontal step-progress indicator pill bar for multi-step Stock Issue.
final class StockIssueStepProgressStrip extends StatelessWidget {
  const StockIssueStepProgressStrip({super.key, required this.steps});

  final List<StockIssueStepItem> steps;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < steps.length; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: AppSpacing.xsm,
              ),
              decoration: BoxDecoration(
                color: steps[i].completed
                    ? semantic.goodStockContainer
                    : (steps[i].active
                          ? colorScheme.secondary.withValues(alpha: 0.16)
                          : colorScheme.surfaceContainer),
                borderRadius: AppRadius.fullBorder,
                border: Border.all(
                  color: steps[i].completed
                      ? semantic.goodStock.withValues(alpha: 0.4)
                      : (steps[i].active
                            ? colorScheme.secondary
                            : colorScheme.outlineVariant),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    steps[i].completed
                        ? AppIcons.success
                        : AppIcons.currentStep,
                    size: 14,
                    color: steps[i].completed
                        ? semantic.goodStock
                        : (steps[i].active
                              ? colorScheme.secondary
                              : colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: AppSpacing.xsm),
                  Text(
                    '${steps[i].number}. ${steps[i].label}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: steps[i].active || steps[i].completed
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: steps[i].completed
                          ? semantic.goodStock
                          : (steps[i].active
                                ? colorScheme.onSurface
                                : colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
            if (i < steps.length - 1) const SizedBox(width: AppSpacing.xs),
          ],
        ],
      ),
    );
  }
}

/// Numbered / checkmark circular step badge for guided forms.
final class StockIssueStepBadge extends StatelessWidget {
  const StockIssueStepBadge({
    super.key,
    required this.number,
    required this.completed,
  });

  final int number;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final semantic = context.semanticColors;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: completed ? semantic.goodStock : colorScheme.primary,
        borderRadius: AppRadius.fullBorder,
      ),
      child: completed
          ? const Icon(AppIcons.confirm, size: 16, color: AppColors.onHero)
          : Text(
              '$number',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
    );
  }
}

/// Two-column key/value confirmation row used in Stock Issue summary & success views.
final class StockIssueSummaryRow extends StatelessWidget {
  const StockIssueSummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.isNumeric = false,
    this.highlight = false,
  });

  final String label;
  final String value;
  final bool isNumeric;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: AppText(
              label,
              variant: AppTextVariant.bodySmall,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 3,
            child: AppText(
              value,
              variant: isNumeric
                  ? AppTextVariant.numeric
                  : AppTextVariant.bodyMedium,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              color: highlight ? colorScheme.primary : null,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
