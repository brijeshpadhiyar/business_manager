import 'package:animations/animations.dart' show SharedAxisTransitionType;
import 'package:business_manager/core/widgets/app_glass_backdrop.dart';
import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:motor/motor.dart';

/// Centralized StitchFlow motion tokens, `motor` spring physics presets,
/// reduced-motion accessibility helpers, zero-blink Material 3 page transition
/// builders, and reusable micro-motion primitives.
abstract final class AppMotion {
  static const Duration micro = Duration(milliseconds: 110);
  static const Duration tabFade = Duration(milliseconds: 150);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration normal = Duration(milliseconds: 260);
  static const Duration emphasized = Duration(milliseconds: 340);
  static const Duration numberCount = Duration(milliseconds: 420);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve emphasizedCurve = Curves.easeInOutCubicEmphasized;

  /// Snappy spring for tactile buttons, toggles, and chips.
  static const Motion snappySpring = Motion.snappySpring(
    duration: Duration(milliseconds: 280),
    snapToEnd: true,
  );

  /// Bouncy spring for navigation icon highlights and celebratory badges.
  static const Motion bouncySpring = Motion.bouncySpring(
    duration: Duration(milliseconds: 360),
    snapToEnd: true,
  );

  /// Smooth spring for sheets, expandable panels, and card lifts.
  static const Motion smoothSpring = Motion.smoothSpring(
    duration: Duration(milliseconds: 320),
    snapToEnd: true,
  );

  /// Interactive spring for press-and-release micro-physics.
  static const Motion interactiveSpring = Motion.interactiveSpring(
    duration: Duration(milliseconds: 240),
    snapToEnd: true,
  );

  /// Returns [Motion.none] when reduced motion is requested.
  static Motion spring(BuildContext context, [Motion preferred = snappySpring]) {
    return reduceMotion(context) ? const Motion.none() : preferred;
  }

  /// Returns `true` when the platform requests reduced motion.
  static bool reduceMotion(BuildContext context) {
    return MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  }

  /// Resolves a duration that collapses to [Duration.zero] under reduced motion.
  static Duration duration(BuildContext context, Duration preferred) {
    return reduceMotion(context) ? Duration.zero : preferred;
  }

  /// Page for pushed screens (details, forms). Returns a [MaterialPage] so
  /// the theme's platform transitions apply: predictive back on Android,
  /// edge-swipe back on iOS/macOS, and fade-forwards on desktop/web (see
  /// `pageTransitionsTheme` in `AppTheme`). [axis] is kept for API
  /// compatibility.
  static Page<T> buildPage<T>({
    required GoRouterState state,
    required Widget child,
    SharedAxisTransitionType axis = SharedAxisTransitionType.horizontal,
  }) {
    return MaterialPage<T>(key: state.pageKey, child: child);
  }

  /// Page for switching between sibling sidebar/section routes (`context.go`):
  /// a smooth, zero-blank 150ms cross-fade over the outgoing opaque page
  /// (never dipping to 0% empty opacity like `FadeThroughTransition`).
  /// Instant under reduced motion.
  static Page<T> buildTabPage<T>({
    required GoRouterState state,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      transitionDuration: tabFade,
      reverseTransitionDuration: const Duration(milliseconds: 120),
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (reduceMotion(context)) return child;
        final curved = CurvedAnimation(
          parent: animation,
          curve: standardCurve,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(opacity: curved, child: child);
      },
    );
  }
}

/// Keeps all primary tab branches alive in memory (preserving scroll positions,
/// search/filter inputs, and Cubit state) while cross-fading smoothly between
/// tabs over 150ms with zero blank gap and zero widget reparenting.
///
/// Paint-order math guarantees constant 100% composite opacity in both
/// directions:
/// - Switching forward (`next > prev`): `prev` stays opaque below while `next`
///   fades `0 -> 1` on top.
/// - Switching backward (`next < prev`): `next` sits opaque below while `prev`
///   fades `1 -> 0` on top.
/// When idle, every visible slot receives `kAlwaysCompleteAnimation` (`1.0`),
/// allocating zero offscreen opacity layers during 120Hz scrolling.
final class AppCrossFadeIndexedStack extends StatefulWidget {
  const AppCrossFadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = AppMotion.tabFade,
    this.curve = AppMotion.standardCurve,
  });

  final int index;
  final List<Widget> children;
  final Duration duration;
  final Curve curve;

  @override
  State<AppCrossFadeIndexedStack> createState() =>
      _AppCrossFadeIndexedStackState();
}

final class _AppCrossFadeIndexedStackState
    extends State<AppCrossFadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late CurvedAnimation _fadeIn;
  late Animation<double> _fadeOut;

  late int _currentIndex;
  int? _previousIndex;

  bool get _isTransitioning =>
      _previousIndex != null && _previousIndex != _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = _safeIndex(widget.index);
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
      value: 1.0,
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: widget.curve);
    _fadeOut = ReverseAnimation(_fadeIn);
    _controller.addStatusListener(_onStatusChanged);
  }

  int _safeIndex(int raw) {
    if (widget.children.isEmpty) return 0;
    return raw.clamp(0, widget.children.length - 1);
  }

  void _onStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed && _previousIndex != null) {
      if (mounted) {
        setState(() {
          _previousIndex = null;
        });
      }
    }
  }

  @override
  void didUpdateWidget(covariant AppCrossFadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
    if (oldWidget.curve != widget.curve) {
      _fadeIn.dispose();
      _fadeIn = CurvedAnimation(parent: _controller, curve: widget.curve);
      _fadeOut = ReverseAnimation(_fadeIn);
    }

    final nextIndex = _safeIndex(widget.index);
    if (nextIndex == _currentIndex) return;

    final effectiveDuration = AppMotion.duration(context, widget.duration);
    if (effectiveDuration == Duration.zero) {
      _controller.value = 1.0;
      _previousIndex = null;
      _currentIndex = nextIndex;
      return;
    }

    _previousIndex = _currentIndex;
    _currentIndex = nextIndex;
    _controller.duration = effectiveDuration;
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onStatusChanged);
    _fadeIn.dispose();
    _controller.dispose();
    super.dispose();
  }

  Animation<double> _opacityForSlot(int i) {
    if (!_isTransitioning) return kAlwaysCompleteAnimation;
    final prev = _previousIndex!;
    if (_currentIndex > prev) {
      // Incoming slot is painted above outgoing slot.
      if (i == _currentIndex) return _fadeIn;
      return kAlwaysCompleteAnimation;
    } else {
      // Outgoing slot is painted above incoming slot.
      if (i == prev) return _fadeOut;
      return kAlwaysCompleteAnimation;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();

    return Stack(
      fit: StackFit.expand,
      children: [
        for (int i = 0; i < widget.children.length; i++)
          Offstage(
            offstage:
                i != _currentIndex &&
                (!_isTransitioning || i != _previousIndex),
            child: TickerMode(
              enabled: i == _currentIndex,
              child: ExcludeFocus(
                excluding: i != _currentIndex,
                child: ExcludeSemantics(
                  excluding: i != _currentIndex,
                  child: IgnorePointer(
                    ignoring: i != _currentIndex,
                    child: FadeTransition(
                      opacity: _opacityForSlot(i),
                      child: RepaintBoundary(
                        child: AppGlassBackdrop(child: widget.children[i]),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Zero-blink entrance wrapper kept for API compatibility across existing
/// pages. Route transitions already animate screens in smoothly; starting inner
/// sections at `opacity: 0` caused visible post-navigation flashes and list
/// re-entry blinks, so this renders [child] immediately.
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
  Widget build(BuildContext context) => child;
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
      child: SingleMotionBuilder(
        value: _pressed ? widget.pressedScale : 1.0,
        from: 1.0,
        motion: AppMotion.spring(context, AppMotion.interactiveSpring),
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
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
      reverseDuration: const Duration(milliseconds: 110),
      switchInCurve: AppMotion.standardCurve,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) => Stack(
        alignment: Alignment.topCenter,
        children: [...previousChildren, ?currentChild],
      ),
      transitionBuilder: (child, animation) {
        return FadeTransition(opacity: animation, child: child);
      },
      child: KeyedSubtree(key: stateKey, child: child),
    );
  }
}
