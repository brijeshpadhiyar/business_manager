import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/widgets/app_heading.dart';
import 'package:business_manager/core/widgets/app_text.dart';
import 'package:material_ui/material_ui.dart';

/// Consistent section header combining [AppHeading], optional subtitle, and
/// optional trailing action widget.
final class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.level = AppHeadingLevel.h3,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final AppHeadingLevel level;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeading(title, level: level),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                AppText(
                  subtitle!,
                  variant: AppTextVariant.bodySmall,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.sm),
          trailing!,
        ],
      ],
    );
  }
}
