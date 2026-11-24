import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/widgets/app_glass_surface.dart';
import 'package:material_ui/material_ui.dart';

/// Refined Material 3 StitchFlow V1.3 card defaulting to genuine frosted
/// glassmorphism (`isGlass: true`) with BackdropFilter blur, specular highlight,
/// subtle glass border, soft depth, and tactile press animation when tappable.
final class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.onTap,
    this.color,
    this.borderColor,
    this.gradient,
    this.borderRadius = AppRadius.lgBorder,
    this.isGlass = true,
    this.blurSigma = 14,
    this.elevated = true,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;
  final BorderRadius borderRadius;
  final bool isGlass;
  final double blurSigma;
  final bool elevated;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    if (isGlass) {
      final glass = AppGlassSurface(
        padding: padding,
        borderRadius: borderRadius,
        blurSigma: blurSigma,
        tintColor: color,
        borderColor: borderColor,
        gradient: gradient,
        elevated: elevated,
        onTap: onTap,
        child: child,
      );
      if (semanticLabel != null) {
        return Semantics(
          label: semanticLabel,
          button: onTap != null,
          child: glass,
        );
      }
      return glass;
    }

    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.surfaceTokens;

    Widget surface = Container(
      decoration: BoxDecoration(
        color: gradient == null
            ? (color ?? colorScheme.surfaceContainerLow)
            : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(
          color: borderColor ?? colorScheme.outlineVariant,
          width: 1,
        ),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: tokens.cardShadow,
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: borderRadius,
                child: Padding(padding: padding, child: child),
              )
            : Padding(padding: padding, child: child),
      ),
    );

    if (onTap != null) {
      surface = AppPressable(pressedScale: 0.982, child: surface);
    }

    if (semanticLabel != null) {
      return Semantics(
        label: semanticLabel,
        button: onTap != null,
        child: surface,
      );
    }
    return surface;
  }
}
