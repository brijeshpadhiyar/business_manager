import 'dart:ui';

import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// Genuine frosted glassmorphism surface powered by Flutter's native
/// [BackdropFilter], specular top-to-bottom highlight gradient, luminous
/// hairline border, dual ambient shadows, [RepaintBoundary] isolation, and
/// tactile press animation when interactive.
final class AppGlassSurface extends StatelessWidget {
  const AppGlassSurface({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.borderRadius = AppRadius.lgBorder,
    this.blurSigma = 14,
    this.tintColor,
    this.borderColor,
    this.gradient,
    this.elevated = true,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double blurSigma;
  final Color? tintColor;
  final Color? borderColor;
  final Gradient? gradient;
  final bool elevated;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.surfaceTokens;

    final Gradient? effectiveGradient =
        gradient ?? (tintColor == null ? tokens.glassGradient : null);

    Widget glassBody = DecoratedBox(
      decoration: BoxDecoration(
        color: effectiveGradient == null
            ? (tintColor ?? tokens.glassFill)
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

    if (blurSigma > 0) {
      glassBody = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: glassBody,
        ),
      );
    }

    Widget container = RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          boxShadow: elevated
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
              : null,
        ),
        child: glassBody,
      ),
    );

    if (onTap != null) {
      container = AppPressable(pressedScale: 0.982, child: container);
    }

    return container;
  }
}
