import 'dart:ui';

import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// Selective glassmorphism surface using Flutter's native [BackdropFilter].
///
/// Use intentionally on dashboard banners, navigation bars, overlays, and
/// featured summary tiles—never on dense forms or heavy data grids where solid
/// high-contrast surfaces provide better readability and frame performance.
final class AppGlassSurface extends StatelessWidget {
  const AppGlassSurface({
    super.key,
    required this.child,
    this.padding = AppSpacing.cardPadding,
    this.borderRadius = AppRadius.lgBorder,
    this.blurSigma = 12,
    this.tintColor,
    this.borderColor,
    this.gradient,
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadius borderRadius;
  final double blurSigma;
  final Color? tintColor;
  final Color? borderColor;
  final Gradient? gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.surfaceTokens;

    Widget inner = Container(
      decoration: BoxDecoration(
        color: gradient == null ? (tintColor ?? tokens.glassFill) : null,
        gradient: gradient,
        borderRadius: borderRadius,
        border: Border.all(color: borderColor ?? tokens.glassBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: tokens.cardShadow,
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: onTap != null
          ? Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onTap,
                borderRadius: borderRadius,
                child: Padding(padding: padding, child: child),
              ),
            )
          : Padding(padding: padding, child: child),
    );

    if (blurSigma > 0) {
      inner = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: inner,
        ),
      );
    }

    return inner;
  }
}
