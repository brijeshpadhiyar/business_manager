import 'package:animations/animations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

/// Centralized StitchFlow motion tokens, reduced-motion accessibility helpers,
/// and Material 3 page transition builders.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration normal = Duration(milliseconds: 240);
  static const Duration emphasized = Duration(milliseconds: 340);
  static const Duration numberCount = Duration(milliseconds: 420);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeInOutCubicEmphasized;

  /// Returns `true` when the platform requests reduced motion.
  static bool reduceMotion(BuildContext context) {
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  /// Resolves a duration that collapses to [Duration.zero] under reduced motion.
  static Duration duration(BuildContext context, Duration preferred) {
    return reduceMotion(context) ? Duration.zero : preferred;
  }

  /// Builds a smooth Material 3 shared-axis / fade-through page for `go_router`.
  static CustomTransitionPage<T> buildPage<T>({
    required GoRouterState state,
    required Widget child,
    SharedAxisTransitionType axis = SharedAxisTransitionType.horizontal,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      transitionDuration: normal,
      reverseTransitionDuration: fast,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (reduceMotion(context)) {
          return child;
        }
        return SharedAxisTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          transitionType: axis,
          child: child,
        );
      },
    );
  }
}

/// Subtle, reduced-motion-safe entrance wrapper for cards and list items.
/// Caps stagger delay so long lists remain snappy and responsive.
final class AppMotionEntrance extends StatelessWidget {
  const AppMotionEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.slideOffsetY = 0.04,
  });

  final Widget child;
  final int index;
  final double slideOffsetY;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) {
      return child;
    }
    final cappedIndex = index.clamp(0, 6);
    final delay = Duration(milliseconds: cappedIndex * 28);
    return child
        .animate(delay: delay)
        .fadeIn(duration: AppMotion.normal, curve: AppMotion.standardCurve)
        .slideY(
          begin: slideOffsetY,
          end: 0,
          duration: AppMotion.normal,
          curve: AppMotion.standardCurve,
        );
  }
}
