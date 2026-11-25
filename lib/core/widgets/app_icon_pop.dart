import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:material_ui/material_ui.dart';

/// Gives an action's icon a short "pop" when the action is tapped, so users
/// get immediate visual confirmation that the tap registered.
///
/// Wrap the tappable control in [AppIconPopHost] and its icon in
/// [AppIconPop]. Disabled hosts don't pop, and reduced motion turns it off.
final class AppIconPopHost extends StatefulWidget {
  const AppIconPopHost({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<AppIconPopHost> createState() => _AppIconPopHostState();
}

class _AppIconPopHostState extends State<AppIconPopHost> {
  final ValueNotifier<int> _taps = ValueNotifier<int>(0);

  @override
  void dispose() {
    _taps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.deferToChild,
      onPointerUp: widget.enabled ? (_) => _taps.value++ : null,
      child: _IconPopScope(taps: _taps, child: widget.child),
    );
  }
}

final class _IconPopScope extends InheritedWidget {
  const _IconPopScope({required this.taps, required super.child});

  final ValueNotifier<int> taps;

  @override
  bool updateShouldNotify(_IconPopScope old) => old.taps != taps;
}

/// The icon side of [AppIconPopHost]: scales 1 → 1.2 → 1 on each tap.
final class AppIconPop extends StatefulWidget {
  const AppIconPop({super.key, required this.child});

  final Widget child;

  @override
  State<AppIconPop> createState() => _AppIconPopState();
}

class _AppIconPopState extends State<AppIconPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1,
        end: 1.2,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
      weight: 40,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: 1.2,
        end: 1,
      ).chain(CurveTween(curve: Curves.elasticOut)),
      weight: 60,
    ),
  ]).animate(_controller);

  ValueNotifier<int>? _taps;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final taps = context
        .dependOnInheritedWidgetOfExactType<_IconPopScope>()
        ?.taps;
    if (taps != _taps) {
      _taps?.removeListener(_pop);
      _taps = taps?..addListener(_pop);
    }
  }

  void _pop() {
    if (!mounted || AppMotion.reduceMotion(context)) return;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _taps?.removeListener(_pop);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _scale, child: widget.child);
  }
}
