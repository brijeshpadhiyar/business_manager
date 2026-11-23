import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// Compact, theme-aware Material 3 card with `12dp` padding and `8dp` radius.
final class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.onTap,
    this.color,
    this.borderColor,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final card = Card(
      color: color ?? colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdBorder,
        side: BorderSide(color: borderColor ?? colorScheme.outlineVariant),
      ),
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: AppRadius.mdBorder,
              child: Padding(padding: padding, child: child),
            )
          : Padding(padding: padding, child: child),
    );

    if (semanticLabel != null) {
      return Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: card,
      );
    }
    return card;
  }
}
