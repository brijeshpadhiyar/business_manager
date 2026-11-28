import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted display mode for the Web / Desktop Side Navigator.
enum SidebarMode {
  /// Full compact sidebar (`220dp` / `192dp` in compact ERP density).
  expanded('expanded'),

  /// Icon-only compact rail (`60dp` / `52dp` in compact ERP density).
  compactRail('compact_rail'),

  /// Completely hidden (`0dp`), restored via the top-bar toggle or `Ctrl+B`.
  hidden('hidden');

  const SidebarMode(this.storageKey);

  final String storageKey;

  static SidebarMode fromStorageKey(String? raw) {
    return SidebarMode.values.firstWhere(
      (mode) => mode.storageKey == raw,
      orElse: () => SidebarMode.expanded,
    );
  }
}

@immutable
final class NavigationSidebarState {
  const NavigationSidebarState({
    required this.mode,
    this.lastVisibleMode = SidebarMode.expanded,
    this.collapsedSectionIds = const <String>{},
  });

  final SidebarMode mode;
  final SidebarMode lastVisibleMode;
  final Set<String> collapsedSectionIds;

  bool get isExpanded => mode == SidebarMode.expanded;
  bool get isCompactRail => mode == SidebarMode.compactRail;
  bool get isHidden => mode == SidebarMode.hidden;

  bool isSectionCollapsed(String sectionId) =>
      collapsedSectionIds.contains(sectionId);

  NavigationSidebarState copyWith({
    SidebarMode? mode,
    SidebarMode? lastVisibleMode,
    Set<String>? collapsedSectionIds,
  }) {
    return NavigationSidebarState(
      mode: mode ?? this.mode,
      lastVisibleMode: lastVisibleMode ?? this.lastVisibleMode,
      collapsedSectionIds: collapsedSectionIds ?? this.collapsedSectionIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! NavigationSidebarState) return false;
    return other.mode == mode &&
        other.lastVisibleMode == lastVisibleMode &&
        other.collapsedSectionIds.length == collapsedSectionIds.length &&
        other.collapsedSectionIds.containsAll(collapsedSectionIds);
  }

  @override
  int get hashCode => Object.hash(
    mode,
    lastVisibleMode,
    Object.hashAllUnordered(collapsedSectionIds),
  );
}

/// Manages and persists the Web/Desktop Side Navigator mode (`expanded`,
/// `compactRail`, `hidden`) and collapsed section groups in
/// [SharedPreferences].
@lazySingleton
final class NavigationSidebarCubit extends Cubit<NavigationSidebarState> {
  NavigationSidebarCubit(this._prefs)
    : super(_readInitialState(_prefs));

  static const String _modeKey = 'stitchflow_sidebar_mode_v1';
  static const String _collapsedKey = 'stitchflow_sidebar_collapsed_v1';

  final SharedPreferences _prefs;

  static NavigationSidebarState _readInitialState(SharedPreferences prefs) {
    final mode = SidebarMode.fromStorageKey(prefs.getString(_modeKey));
    final collapsed =
        prefs.getStringList(_collapsedKey)?.toSet() ?? const <String>{};
    return NavigationSidebarState(
      mode: mode,
      lastVisibleMode:
          mode == SidebarMode.hidden ? SidebarMode.expanded : mode,
      collapsedSectionIds: collapsed,
    );
  }

  Future<void> setMode(SidebarMode mode) async {
    if (state.mode == mode) return;
    final nextLastVisible =
        mode == SidebarMode.hidden ? state.lastVisibleMode : mode;
    emit(state.copyWith(mode: mode, lastVisibleMode: nextLastVisible));
    await _prefs.setString(_modeKey, mode.storageKey);
  }

  /// Cycles through `expanded -> compactRail -> hidden -> expanded`.
  Future<void> cycleMode() {
    final next = switch (state.mode) {
      SidebarMode.expanded => SidebarMode.compactRail,
      SidebarMode.compactRail => SidebarMode.hidden,
      SidebarMode.hidden => SidebarMode.expanded,
    };
    return setMode(next);
  }

  /// Toggles between `expanded` and `compactRail` (restoring from `hidden`
  /// into `expanded`).
  Future<void> toggleExpandedOrRail() {
    final next = switch (state.mode) {
      SidebarMode.expanded => SidebarMode.compactRail,
      SidebarMode.compactRail => SidebarMode.expanded,
      SidebarMode.hidden => SidebarMode.expanded,
    };
    return setMode(next);
  }

  /// Hides the sidebar or restores the last visible mode (`expanded` or
  /// `compactRail`).
  Future<void> toggleHide() {
    if (state.isHidden) {
      return setMode(state.lastVisibleMode);
    }
    return setMode(SidebarMode.hidden);
  }

  Future<void> toggleSection(String sectionId) async {
    final next = Set<String>.from(state.collapsedSectionIds);
    if (!next.add(sectionId)) {
      next.remove(sectionId);
    }
    emit(state.copyWith(collapsedSectionIds: next));
    await _prefs.setStringList(_collapsedKey, next.toList(growable: false));
  }
}
