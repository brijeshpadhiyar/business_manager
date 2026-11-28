import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_glass_quality.dart';
import 'package:business_manager/core/theme/theme_state.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mesh/mesh.dart';

/// Adaptive app canvas behind transparent Scaffolds:
/// - `Classic Solid`: calm static vertical gradient.
/// - `Modern Frosted Glass`: clean neutral dark/light canvas (no colored blobs).
/// - `Liquid Aurora Glass`: subtle single-hue [OMeshGradient] wash (on
///   supported platforms when motion is enabled) with soft single-hue fallback.
final class AppGlassBackdrop extends StatefulWidget {
  const AppGlassBackdrop({super.key, required this.child});

  final Widget child;

  @override
  State<AppGlassBackdrop> createState() => _AppGlassBackdropState();
}

final class _AppGlassBackdropState extends State<AppGlassBackdrop>
    with SingleTickerProviderStateMixin {
  AnimationController? _meshController;

  void _syncAnimation(bool shouldAnimate) {
    if (shouldAnimate) {
      _meshController ??= AnimationController(
        vsync: this,
        duration: const Duration(seconds: 14),
      )..repeat(reverse: true);
    } else {
      _meshController?.dispose();
      _meshController = null;
    }
  }

  @override
  void dispose() {
    _meshController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.surfaceTokens;
    final quality = AppGlassQuality.resolve(context);
    final palette = context.themePresetPalette;
    final brightness = Theme.of(context).brightness;
    final isGlass = quality.style != AppSurfaceStyle.classicSolid;

    _syncAnimation(quality.enableAnimatedMesh);

    final baseGradient = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            tokens.backdropTop,
            tokens.backdropMid,
            tokens.backdropBottom,
          ],
          stops: const [0.0, 0.38, 1.0],
        ),
      ),
    );

    Widget canvas = baseGradient;

    final hasAnyOrb =
        tokens.orbPrimary.a > 0.001 ||
        tokens.orbSecondary.a > 0.001 ||
        tokens.orbAccent.a > 0.001;

    if (quality.enableAnimatedMesh && _meshController != null) {
      final meshColors = palette.meshColorsFor(brightness);
      canvas = Stack(
        fit: StackFit.expand,
        children: [
          baseGradient,
          AnimatedBuilder(
            animation: _meshController!,
            builder: (context, _) {
              final t = Curves.easeInOutSine.transform(_meshController!.value);
              final cX = 0.42 + (0.16 * t);
              final cY = 0.36 + (0.18 * (1 - t));
              return OMeshGradient(
                tessellation: 10,
                mesh: OMeshRect(
                  width: 3,
                  height: 3,
                  colorSpace: OMeshColorSpace.lab,
                  smoothColors: true,
                  vertices: [
                    (0.0, 0.0).v,
                    (0.5, 0.0).v,
                    (1.0, 0.0).v,
                    (0.0, 0.45 + 0.1 * t).v,
                    (cX, cY).v,
                    (1.0, 0.55 - 0.1 * t).v,
                    (0.0, 1.0).v,
                    (0.5, 1.0).v,
                    (1.0, 1.0).v,
                  ],
                  colors: [
                    meshColors[0],
                    meshColors[1],
                    meshColors[2],
                    meshColors[1],
                    meshColors[2],
                    meshColors[3],
                    meshColors[3],
                    meshColors[0],
                    meshColors[3],
                  ],
                ),
              );
            },
          ),
        ],
      );
    } else if (isGlass && hasAnyOrb) {
      canvas = Stack(
        fit: StackFit.expand,
        children: [
          baseGradient,
          Positioned(
            top: -90,
            left: -60,
            child: _AmbientOrb(size: 320, color: tokens.orbPrimary),
          ),
          Positioned(
            top: 140,
            right: -80,
            child: _AmbientOrb(size: 280, color: tokens.orbSecondary),
          ),
          Positioned(
            bottom: -100,
            left: 40,
            child: _AmbientOrb(size: 260, color: tokens.orbAccent),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(child: IgnorePointer(child: canvas)),
        widget.child,
      ],
    );
  }
}

final class _AmbientOrb extends StatelessWidget {
  const _AmbientOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (color.a <= 0.001) return const SizedBox.shrink();
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0.0, 1.0],
          ),
        ),
      ),
    );
  }
}
