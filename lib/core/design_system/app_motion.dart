import 'package:animations/animations.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

/// Centralized StitchFlow V1.3 motion tokens, reduced-motion accessibility
/// helpers, Material 3 page transition builders, and reusable micro-interaction
/// primitives.
abstract final class AppMotion {
  static const Duration micro = Duration(milliseconds: 110);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 280);
  static const Duration emphasized = Duration(milliseconds: 360);
  static const Duration numberCount = Duration(milliseconds: 480);

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

  /// Builds a lightweight, 120Hz-friendly incoming slide + fade transition for
  /// `go_router` that avoids double-page GPU compositing over glass backdrops.
  static CustomTransitionPage<T> buildPage<T>({
    required GoRouterState state,
    required Widget child,
    SharedAxisTransitionType axis = SharedAxisTransitionType.horizontal,
  }) {
    final beginOffset = switch (axis) {
      SharedAxisTransitionType.horizontal => const Offset(0.04, 0),
      SharedAxisTransitionType.vertical => const Offset(0, 0.04),
      SharedAxisTransitionType.scaled => Offset.zero,
    };
    return CustomTransitionPage<T>(
      key: state.pageKey,
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 160),
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (reduceMotion(context)) {
          return child;
        }
        final curved = CurvedAnimation(
          parent: animation,
          curve: standardCurve,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: beginOffset == Offset.zero
              ? child
              : SlideTransition(
                  position: Tween<Offset>(
                    begin: beginOffset,
                    end: Offset.zero,
                  ).animate(curved),
                  child: child,
                ),
        );
      },
    );
  }
}

/// Snappy, reduced-motion-safe entrance wrapper for top-level screen sections.
/// Uses short 180ms motion and tightly capped stagger (max 60ms) so content
/// never feels delayed when navigating or scrolling at 120Hz.
final class AppMotionEntrance extends StatelessWidget {
  const AppMotionEntrance({
    super.key,
    required this.child,
    this.index = 0,
    this.slideOffsetY = 8,
  });

  final Widget child;
  final int index;
  final double slideOffsetY;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduceMotion(context)) {
      return child;
    }
    final cappedIndex = index.clamp(0, 3);
    final delay = Duration(milliseconds: cappedIndex * 20);
    const enterDuration = Duration(milliseconds: 180);
    return child
        .animate(delay: delay)
        .fadeIn(duration: enterDuration, curve: AppMotion.standardCurve)
        .moveY(
          begin: slideOffsetY,
          end: 0,
          duration: enterDuration,
          curve: AppMotion.standardCurve,
        );
  }
}

/// Tactile press-scale wrapper for interactive glass cards, buttons, and tiles.
/// Respects reduced-motion accessibility preferences.
final class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = 0.975,
  });

  final Widget child;
  final bool enabled;
  final double pressedScale;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

final class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;
  Offset? _downPosition;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || AppMotion.reduceMotion(context)) {
      return widget.child;
    }
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (e) {
        _downPosition = e.position;
        _setPressed(true);
      },
      onPointerMove: (e) {
        if (_pressed && _downPosition != null) {
          if ((e.position - _downPosition!).distanceSquared > 100) {
            _downPosition = null;
            _setPressed(false);
          }
        }
      },
      onPointerUp: (_) {
        _downPosition = null;
        _setPressed(false);
      },
      onPointerCancel: (_) {
        _downPosition = null;
        _setPressed(false);
      },
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: AppMotion.micro,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Smooth expand/collapse container with animated height and opacity.
/// Respects reduced-motion accessibility preferences.
final class AppExpandableSection extends StatelessWidget {
  const AppExpandableSection({
    super.key,
    required this.expanded,
    required this.child,
  });

  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.duration(context, AppMotion.normal);
    if (duration == Duration.zero) {
      return expanded ? child : const SizedBox.shrink();
    }
    return ClipRect(
      child: AnimatedSize(
        duration: duration,
        curve: AppMotion.standardCurve,
        alignment: Alignment.topCenter,
        child: AnimatedOpacity(
          duration: duration,
          curve: AppMotion.standardCurve,
          opacity: expanded ? 1.0 : 0.0,
          child: expanded ? child : const SizedBox(width: double.infinity),
        ),
      ),
    );
  }
}

/// Smooth animated transition when BLoC / view state changes (e.g. loading ->
/// content -> empty -> error, or switching report categories / filters).
final class AppStateTransition extends StatelessWidget {
  const AppStateTransition({
    super.key,
    required this.stateKey,
    required this.child,
  });

  final Key stateKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.duration(
      context,
      const Duration(milliseconds: 180),
    );
    if (duration == Duration.zero) {
      return KeyedSubtree(key: stateKey, child: child);
    }
    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: const Duration(milliseconds: 120),
      switchInCurve: AppMotion.standardCurve,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.025),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(key: stateKey, child: child),
    );
  }
}
