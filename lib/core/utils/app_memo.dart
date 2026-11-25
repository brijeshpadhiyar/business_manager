/// Caches the result of a costly computation (sorting, filtering, totals)
/// done while building a widget.
///
/// The value is recomputed only when one of the [deps] changes. Lists, maps
/// and other objects are compared by identity (a cubit emits a new list when
/// data changes), and strings, numbers, booleans, enums and null are compared
/// by value. This keeps scrolling and typing smooth on pages that rebuild
/// often but whose data has not changed.
///
/// ```dart
/// final _sorted = AppMemo<List<LotEntity>>();
/// ...
/// final lots = _sorted(
///   [state.lots, _sortColumn, _ascending],
///   () => _sortLots(state.lots),
/// );
/// ```
final class AppMemo<R> {
  List<Object?>? _deps;
  late R _value;

  R call(List<Object?> deps, R Function() compute) {
    final previous = _deps;
    if (previous != null && _same(previous, deps)) return _value;
    _value = compute();
    _deps = List<Object?>.of(deps, growable: false);
    return _value;
  }

  /// Forgets the cached value so the next call recomputes it.
  void clear() => _deps = null;

  static bool _same(List<Object?> a, List<Object?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final x = a[i];
      final y = b[i];
      if (identical(x, y)) continue;
      final byValue =
          x is String || x is num || x is bool || x is Enum || x is DateTime;
      if (!byValue || x != y) return false;
    }
    return true;
  }
}
