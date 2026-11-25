import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:material_ui/material_ui.dart';

/// Calm app canvas that sits behind transparent Scaffolds: the page
/// background colour with a very faint brand tint at the top (v1.4 soft
/// elevation system). Static and wrapped in a [RepaintBoundary].
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
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    tokens.backdropTop,
                    tokens.backdropMid,
                    tokens.backdropBottom,
                  ],
                  stops: const [0.0, 0.35, 1.0],
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
