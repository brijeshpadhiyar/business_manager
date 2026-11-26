import 'package:material_ui/material_ui.dart';

/// Singleton registry mapping logical [GuideTargetId]s to currently mounted
/// [GlobalKey]s so the custom spotlight overlay can measure any button across
/// routes, tabs, and adaptive layouts without duplicate-key collisions.
final class GuideTargetRegistry extends ChangeNotifier {
  GuideTargetRegistry._();

  static final GuideTargetRegistry instance = GuideTargetRegistry._();

  final Map<String, List<GlobalKey>> _keysById = <String, List<GlobalKey>>{};

  void register(String id, GlobalKey key) {
    final list = _keysById.putIfAbsent(id, () => <GlobalKey>[]);
    if (!list.contains(key)) {
      list.add(key);
    }
  }

  void unregister(String id, GlobalKey key) {
    final list = _keysById[id];
    if (list == null) return;
    list.remove(key);
    if (list.isEmpty) {
      _keysById.remove(id);
    }
  }

  /// Returns the most recently mounted [BuildContext] for [targetId].
  BuildContext? contextFor(String targetId) {
    final list = _keysById[targetId];
    if (list == null || list.isEmpty) return null;
    for (var i = list.length - 1; i >= 0; i--) {
      final ctx = list[i].currentContext;
      if (ctx != null && ctx.mounted) {
        final renderObj = ctx.findRenderObject();
        if (renderObj is RenderBox && renderObj.hasSize && renderObj.attached) {
          return ctx;
        }
      }
    }
    return null;
  }

  /// Resolves the global screen-space [Rect] for [targetId], or `null` if the
  /// target widget is not currently mounted/visible.
  Rect? rectFor(String targetId) {
    final ctx = contextFor(targetId);
    if (ctx == null) return null;
    final renderObj = ctx.findRenderObject();
    if (renderObj is! RenderBox || !renderObj.hasSize || !renderObj.attached) {
      return null;
    }
    final offset = renderObj.localToGlobal(Offset.zero);
    if (!offset.dx.isFinite || !offset.dy.isFinite) return null;
    return offset & renderObj.size;
  }

  /// Smoothly scrolls the target widget into view if it lives inside a
  /// scrollable container before locking the spotlight onto it.
  Future<void> scrollIntoView(String targetId) async {
    final ctx = contextFor(targetId);
    if (ctx == null || !ctx.mounted) return;
    try {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: 0.45,
      );
    } catch (_) {
      // Widget is not inside a Scrollable (e.g. AppBar or BottomBar).
    }
  }
}

/// Lightweight wrapper that registers [child] as a spotlightable button or
/// section under [id] without affecting layout or semantics.
final class GuideTarget extends StatefulWidget {
  const GuideTarget({super.key, required this.id, required this.child});

  final String id;
  final Widget child;

  @override
  State<GuideTarget> createState() => _GuideTargetState();
}

final class _GuideTargetState extends State<GuideTarget> {
  final GlobalKey _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    GuideTargetRegistry.instance.register(widget.id, _key);
  }

  @override
  void didUpdateWidget(covariant GuideTarget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      GuideTargetRegistry.instance.unregister(oldWidget.id, _key);
      GuideTargetRegistry.instance.register(widget.id, _key);
    }
  }

  @override
  void dispose() {
    GuideTargetRegistry.instance.unregister(widget.id, _key);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
