import 'package:business_manager/core/design_system/app_density.dart';
import 'package:material_ui/material_ui.dart';

enum AppHeadingLevel { h1, h2, h3 }

/// Semantic section or page heading with optional trailing action widget that
/// gracefully stacks on narrow phones when labels are long (e.g. Gujarati).
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
    final d = context.density;
    final style = switch (level) {
      AppHeadingLevel.h1 => textTheme.headlineSmall,
      AppHeadingLevel.h2 => textTheme.titleLarge,
      AppHeadingLevel.h3 => textTheme.titleMedium,
    };

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text, style: style, softWrap: true),
        if (subtitle != null) ...[
          SizedBox(height: d.xs),
          Text(
            subtitle!,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            softWrap: true,
          ),
        ],
      ],
    );

    if (trailing == null) {
      return Semantics(header: true, child: titleBlock);
    }

    return Semantics(
      header: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 340) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                titleBlock,
                SizedBox(height: d.sm),
                trailing!,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: titleBlock),
              SizedBox(width: d.sm),
              Flexible(flex: 0, child: trailing!),
            ],
          );
        },
      ),
    );
  }
}
