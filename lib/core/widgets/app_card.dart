import 'package:business_manager/core/design_system/app_density.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_shadows.dart';
import 'package:business_manager/core/widgets/app_glass_surface.dart';
import 'package:material_ui/material_ui.dart';

/// Refined Material 3 StitchFlow V1.3 card defaulting to 120Hz lightweight
/// frosted glassmorphism (`glassStyle: AppGlassStyle.lightweight`) with
/// translucent specular highlight, luminous glass border, and soft depth.
///
/// Pass `glassStyle: AppGlassStyle.full, blurSigma: 12` explicitly for showcase
/// Hero banners or standalone focal panels that benefit from live backdrop blur.
final class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderColor,
    this.gradient,
    this.borderRadius,
    this.isGlass = true,
    this.glassStyle = AppGlassStyle.lightweight,
    this.blurSigma = 0,
    this.elevated = true,
    this.enablePressScale = false,
    this.backdropKey,
    this.semanticLabel,
  });

  /// High-refresh-rate lightweight frosted glass card optimized for dense
  /// scrolling lists and nested card grids (zero per-row `BackdropFilter`
  /// readback and zero scroll-start press-scale rebuilds).
  const AppCard.listItem({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderColor,
    this.gradient,
    this.borderRadius,
    this.elevated = true,
    this.semanticLabel,
  }) : isGlass = true,
       glassStyle = AppGlassStyle.lightweight,
       blurSigma = 0,
       enablePressScale = false,
       backdropKey = null;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;
  final BorderRadius? borderRadius;
  final bool isGlass;
  final AppGlassStyle glassStyle;
  final double blurSigma;
  final bool elevated;
  final bool enablePressScale;
  final BackdropKey? backdropKey;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final d = context.density;
    final resolvedPadding = padding ?? d.cardPadding;
    final resolvedRadius = borderRadius ?? d.radiusLgBorder;

    if (isGlass) {
      final glass = AppGlassSurface(
        padding: resolvedPadding,
        borderRadius: resolvedRadius,
        blurSigma: blurSigma,
        glassStyle: glassStyle,
        tintColor: color,
        borderColor: borderColor,
        gradient: gradient,
        elevated: elevated,
        onTap: onTap,
        enablePressScale: enablePressScale,
        backdropKey: backdropKey,
        child: child,
      );
      if (semanticLabel != null || onTap != null) {
        return Semantics(
          container: true,
          label: semanticLabel,
          button: onTap != null,
          child: glass,
        );
      }
      return glass;
    }

    final colorScheme = Theme.of(context).colorScheme;

    Widget surface = Container(
      decoration: BoxDecoration(
        color: gradient == null
            ? (color ?? colorScheme.surfaceContainerLow)
            : null,
        gradient: gradient,
        borderRadius: resolvedRadius,
        border: Border.all(
          color: borderColor ?? colorScheme.outlineVariant,
          width: 1,
        ),
        boxShadow: elevated ? AppShadows.of(context).sm : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: resolvedRadius,
        clipBehavior: Clip.antiAlias,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                borderRadius: resolvedRadius,
                child: Padding(padding: resolvedPadding, child: child),
              )
            : Padding(padding: resolvedPadding, child: child),
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
