import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Single crumb entry rendered inside [AppBreadcrumbBar].
final class AppBreadcrumbItem {
  const AppBreadcrumbItem({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;
}

/// Accessible, keyboard-focusable breadcrumb trail for Desktop & Tablet views.
final class AppBreadcrumbBar extends StatelessWidget {
  const AppBreadcrumbBar({super.key, required this.items});

  final List<AppBreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: items.map((e) => e.label).join(' / '),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < items.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    AppIcons.chevronRight,
                    size: 16,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              _BreadcrumbChip(item: items[i], isCurrent: i == items.length - 1),
            ],
          ],
        ),
      ),
    );
  }
}

final class _BreadcrumbChip extends StatelessWidget {
  const _BreadcrumbChip({required this.item, required this.isCurrent});

  final AppBreadcrumbItem item;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle = theme.textTheme.labelMedium?.copyWith(
      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
      color: isCurrent ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
    );

    if (isCurrent || item.onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs + 2,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          item.label,
          style: textStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    return Semantics(
      button: true,
      label: item.label,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: AppRadius.smBorder,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: AppSizing.iconLg + 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs + 2,
              vertical: AppSpacing.xs,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                item.label,
                style: textStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
