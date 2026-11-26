import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_shadows.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// Indigo Thread semantic aliases for [AppGlassSurface] and [AppGlassStyle].
typedef AppElevatedSurface = AppGlassSurface;
typedef AppElevationStyle = AppGlassStyle;

/// Elevation mode for [AppElevatedSurface] / [AppGlassSurface] and [AppCard].
enum AppGlassStyle {
  /// Raised surface (`AppShadows.md`). Hero banners, KPI tiles, dialogs.
  full,

  /// Resting surface (`AppShadows.sm`). Dense list rows and nested cards.
  lightweight,
}

/// Opaque card surface with a 1px border, soft layered shadow from
/// `AppShadows`, and optional tactile press animation when interactive.
/// (Name kept from the v1.3 glass system for API compatibility.)
final class AppGlassSurface extends StatelessWidget {
  const AppGlassSurface({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.borderRadius = AppRadius.lgBorder,
    this.blurSigma = 14,
    this.glassStyle = AppGlassStyle.full,
    this.tintColor,
    this.borderColor,
    this.gradient,
    this.elevated = true,
    this.onTap,
    this.enablePressScale = true,
    this.isolateRepaintBoundary,
    this.backdropKey,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double blurSigma;
  final AppGlassStyle glassStyle;
  final Color? tintColor;
  final Color? borderColor;
  final Gradient? gradient;
  final bool elevated;
  final VoidCallback? onTap;
  final bool enablePressScale;
  final bool? isolateRepaintBoundary;
  final BackdropKey? backdropKey;

  @override
  Widget build(BuildContext context) {
    final tokens = context.surfaceTokens;
    final shadows = AppShadows.of(context);
    // v1.4 soft elevation: surfaces are opaque. `blurSigma` / `backdropKey`
    // are accepted for API compatibility but no BackdropFilter is used.
    final isFull = glassStyle == AppGlassStyle.full;
    final useRepaintBoundary = isolateRepaintBoundary ?? false;

    final Widget body = DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null
            ? (tintColor ??
                  (isFull ? tokens.glassFill : tokens.glassFillStrong))
            : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor ?? tokens.glassBorder),
        boxShadow: elevated ? (isFull ? shadows.md : shadows.sm) : null,
      ),
      child: onTap != null
          ? Material(
              type: MaterialType.transparency,
              borderRadius: borderRadius,
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onTap,
                borderRadius: borderRadius,
                child: Padding(padding: padding, child: child),
              ),
            )
          // Own transparent Material so ListTile ink/backgrounds paint on top
          // of the opaque surface instead of being hidden behind it.
          : Material(
              type: MaterialType.transparency,
              borderRadius: borderRadius,
              child: Padding(padding: padding, child: child),
            ),
    );

    Widget container = body;
    if (useRepaintBoundary) {
      container = RepaintBoundary(child: container);
    }

    if (onTap != null && enablePressScale) {
      container = AppPressable(pressedScale: 0.982, child: container);
    }

    return container;
  }
}
