import 'dart:ui';

import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_density.dart';
import 'package:business_manager/core/design_system/app_glass_quality.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_shadows.dart';
import 'package:material_ui/material_ui.dart';

/// Elevation mode for [AppGlassSurface] and [AppCard].
enum AppGlassStyle {
  /// Raised focal surface (`AppShadows.md`). Hero banners, KPI tiles, dialogs.
  /// Uses live frosted blur when glass mode is active.
  full,

  /// Resting surface (`AppShadows.sm`). Dense list rows and nested cards.
  /// Never runs per-row `BackdropFilter` readbacks so scrolling stays 120Hz.
  lightweight,
}

/// Adaptive StitchFlow surface with 3-tier Next-Gen Glass support:
/// - `Classic Solid`: opaque surface with crisp 1px border & layered shadow.
/// - `Modern Frosted Glass`: clean uniform translucent fill + `BackdropFilter`
///   on [AppGlassStyle.full] surfaces (zero blur on [AppGlassStyle.lightweight]).
/// - `Liquid Aurora Glass`: clean uniform translucent fill + `BackdropFilter`
///   over the subtle single-hue ambient wash (zero diagonal or edge glare).
final class AppGlassSurface extends StatelessWidget {
  const AppGlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
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
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
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
    final d = context.density;
    final resolvedPadding = padding ?? d.cardPadding;
    final resolvedRadius = borderRadius ?? d.radiusLgBorder;
    final tokens = context.surfaceTokens;
    final shadows = AppShadows.of(context);
    final quality = AppGlassQuality.resolve(context);
    final isFull = glassStyle == AppGlassStyle.full;
    final useRepaintBoundary = isolateRepaintBoundary ?? false;

    final useRealBlur =
        isFull && quality.enableBackdropBlur && blurSigma > 0;
    final effectiveSigma = useRealBlur
        ? blurSigma.clamp(0.0, quality.cardBlurSigma).toDouble()
        : 0.0;

    final Widget innerMaterial = onTap != null
        ? Material(
            type: MaterialType.transparency,
            borderRadius: resolvedRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              borderRadius: resolvedRadius,
              child: Padding(padding: resolvedPadding, child: child),
            ),
          )
        : Material(
            type: MaterialType.transparency,
            borderRadius: resolvedRadius,
            child: Padding(padding: resolvedPadding, child: child),
          );

    final resolvedColor =
        tintColor ?? (isFull ? tokens.glassFill : tokens.glassFillStrong);

    final BoxDecoration boxDecoration = BoxDecoration(
      color: gradient == null ? resolvedColor : null,
      gradient: gradient,
      borderRadius: resolvedRadius,
      border: Border.all(color: borderColor ?? tokens.glassBorder),
      boxShadow: elevated ? (isFull ? shadows.md : shadows.sm) : null,
    );

    Widget body;
    if (useRealBlur) {
      body = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: resolvedRadius,
          boxShadow: elevated ? shadows.md : null,
        ),
        child: ClipRRect(
          borderRadius: resolvedRadius,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: effectiveSigma,
              sigmaY: effectiveSigma,
            ),
            backdropGroupKey: backdropKey,
            child: DecoratedBox(
              decoration: boxDecoration.copyWith(boxShadow: const []),
              child: innerMaterial,
            ),
          ),
        ),
      );
    } else {
      body = DecoratedBox(
        decoration: boxDecoration,
        child: innerMaterial,
      );
    }

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
