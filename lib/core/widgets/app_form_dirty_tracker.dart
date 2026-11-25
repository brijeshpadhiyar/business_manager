import 'package:material_ui/material_ui.dart';

/// Tracks whether a form has unsaved changes.
///
/// Text fields are compared with the text they had when [watch] was called,
/// so typing and then deleting back to the original text counts as clean.
/// Pickers, dropdowns and list edits call [markDirty]. After a successful
/// save call [reset] (the page normally closes anyway).
///
/// Pair it with [AppUnsavedChangesGuard.tracked].
final class AppFormDirtyTracker extends ChangeNotifier {
  final Map<TextEditingController, String> _baseline = {};
  bool _manualDirty = false;
  bool _lastReported = false;

  bool get isDirty =>
      _manualDirty || _baseline.entries.any((e) => e.key.text != e.value);

  /// Starts watching [controllers], taking their current text as the saved
  /// value. Call it after edit pages have filled the fields from storage.
  void watch(Iterable<TextEditingController> controllers) {
    for (final c in controllers) {
      if (_baseline.containsKey(c)) {
        _baseline[c] = c.text;
        continue;
      }
      _baseline[c] = c.text;
      c.addListener(_onChanged);
    }
    _onChanged();
  }

  /// Stops watching a controller that is about to be disposed.
  void unwatch(TextEditingController controller) {
    if (_baseline.remove(controller) != null) {
      controller.removeListener(_onChanged);
      _onChanged();
    }
  }

  /// Marks a non-text change, such as picking a worker or adding a row.
  void markDirty() {
    if (_manualDirty) return;
    _manualDirty = true;
    _onChanged();
  }

  /// Treats the current values as saved.
  void reset() {
    _manualDirty = false;
    for (final c in _baseline.keys.toList()) {
      _baseline[c] = c.text;
    }
    _onChanged();
  }

  void _onChanged() {
    final now = isDirty;
    if (now == _lastReported) return;
    _lastReported = now;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final c in _baseline.keys) {
      c.removeListener(_onChanged);
    }
    _baseline.clear();
    super.dispose();
  }
}
