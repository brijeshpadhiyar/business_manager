import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:material_ui/material_ui.dart';

/// Layered ambient glassmorphism canvas that sits behind transparent Scaffolds
/// in both Light Glass and Dark Glass modes.
///
/// Wrapped in a [RepaintBoundary] so scrolling glass surfaces blur this rich,
/// static gradient + luminous brand orb layer smoothly at 60 FPS without
/// repainting the background on every frame.
final class AppGlassBackdrop extends StatelessWidget {
  const AppGlassBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.surfaceTokens;

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tokens.backdropTop,
                    tokens.backdropMid,
                    tokens.backdropBottom,
                  ],
                  stops: const [0.0, 0.52, 1.0],
                ),
              ),
              child: CustomPaint(
                painter: _AmbientOrbPainter(
                  orbPrimary: tokens.orbPrimary,
                  orbSecondary: tokens.orbSecondary,
                  orbAccent: tokens.orbAccent,
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

final class _AmbientOrbPainter extends CustomPainter {
  const _AmbientOrbPainter({
    required this.orbPrimary,
    required this.orbSecondary,
    required this.orbAccent,
  });

  final Color orbPrimary;
  final Color orbSecondary;
  final Color orbAccent;

  @override
  void paint(Canvas canvas, Size size) {
    final maxDim = size.longestSide;

    void paintOrb(Offset center, double radius, Color color) {
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
          stops: const [0.0, 1.0],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    // Top-left cool navy/blue ambient glow
    paintOrb(
      Offset(size.width * 0.12, size.height * 0.10),
      maxDim * 0.42,
      orbPrimary,
    );
    // Mid-right StitchFlow teal luminous glow
    paintOrb(
      Offset(size.width * 0.90, size.height * 0.42),
      maxDim * 0.46,
      orbSecondary,
    );
    // Bottom-left subtle warm amber accent glow
    paintOrb(
      Offset(size.width * 0.20, size.height * 0.86),
      maxDim * 0.38,
      orbAccent,
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientOrbPainter oldDelegate) {
    return orbPrimary != oldDelegate.orbPrimary ||
        orbSecondary != oldDelegate.orbSecondary ||
        orbAccent != oldDelegate.orbAccent;
  }
}
