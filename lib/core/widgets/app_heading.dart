import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

enum AppHeadingLevel { h1, h2, h3 }

/// Semantic section or page heading with optional trailing action widget.
final class AppHeading extends StatelessWidget {
  const AppHeading(
    this.text, {
    super.key,
    this.level = AppHeadingLevel.h2,
    this.trailing,
    this.subtitle,
  });

  final String text;
  final AppHeadingLevel level;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final style = switch (level) {
      AppHeadingLevel.h1 => textTheme.headlineSmall,
      AppHeadingLevel.h2 => textTheme.titleLarge,
      AppHeadingLevel.h3 => textTheme.titleMedium,
    };

    return Semantics(
      header: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(text, style: style),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
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
      ),
    );
  }
}
