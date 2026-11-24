import 'dart:ui';

import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// Rendering mode for [AppGlassSurface] and [AppCard].
enum AppGlassStyle {
  /// Full frosted glassmorphism with native [BackdropFilter] blur, specular
  /// highlight gradient, luminous border, and dual ambient shadows.
  /// Best for hero banners, KPI tiles, navigation chrome, dialogs, and sheets.
  full,

  /// High-refresh-rate (120Hz) lightweight frosted glass with translucent
  /// specular gradient, luminous border, and soft single shadow — skipping
  /// per-card GPU backdrop readback (`BackdropFilter`) and extra layer
  /// allocations. Best for dense scrolling list rows and nested cards.
  lightweight,
}

/// Genuine frosted glassmorphism surface powered by Flutter's native
/// [BackdropFilter] (or lightweight specular translucency for 120Hz scrolling
/// lists), luminous hairline border, ambient shadow depth, and optional tactile
/// press animation when interactive.
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
    final useBlur = glassStyle == AppGlassStyle.full && blurSigma > 0;
    final useRepaintBoundary = isolateRepaintBoundary ?? useBlur;

    final Gradient? effectiveGradient =
        gradient ??
        (tintColor == null
            ? (useBlur ? tokens.glassGradient : tokens.lightweightGlassGradient)
            : null);

    Widget glassBody = DecoratedBox(
      decoration: BoxDecoration(
        color: effectiveGradient == null
            ? (tintColor ?? (useBlur ? tokens.glassFill : tokens.glassFillStrong))
            : null,
        gradient: effectiveGradient,
        borderRadius: borderRadius,
        border: Border.all(
          color: borderColor ?? tokens.glassBorder,
          width: 1.15,
        ),
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
          : Padding(padding: padding, child: child),
    );

    if (useBlur) {
      final filter = ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma);
      glassBody = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: filter,
          backdropGroupKey: backdropKey,
          child: glassBody,
        ),
      );
    }

    Widget container = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: elevated
            ? (useBlur
                  ? [
                      BoxShadow(
                        color: tokens.cardShadow,
                        blurRadius: 20,
                        spreadRadius: -2,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: tokens.ambientGlow,
                        blurRadius: 12,
                        spreadRadius: -4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: tokens.cardShadow,
                        blurRadius: 12,
                        spreadRadius: -2,
                        offset: const Offset(0, 4),
                      ),
                    ])
            : null,
      ),
      child: glassBody,
    );

    if (useRepaintBoundary) {
      container = RepaintBoundary(child: container);
    }

    if (onTap != null && enablePressScale) {
      container = AppPressable(pressedScale: 0.982, child: container);
    }

    return container;
  }
}
