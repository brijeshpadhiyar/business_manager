import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-selectable UI density preference for tables, cards, and lists.
enum UiDensityMode {
  comfortable('comfortable'),
  compact('compact');

  const UiDensityMode(this.storageKey);

  final String storageKey;

  VisualDensity get visualDensity => switch (this) {
    UiDensityMode.comfortable => VisualDensity.standard,
    UiDensityMode.compact => VisualDensity.compact,
  };

  static UiDensityMode fromStorageKey(String? raw) {
    return raw == compact.storageKey ? compact : comfortable;
  }
}

@immutable
final class DensityState {
  const DensityState({required this.mode});

  final UiDensityMode mode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DensityState && other.mode == mode;

  @override
  int get hashCode => mode.hashCode;
}

@lazySingleton
final class DensityCubit extends Cubit<DensityState> {
  DensityCubit(this._prefs)
    : super(
        DensityState(
          mode: UiDensityMode.fromStorageKey(_prefs.getString(_prefsKey)),
        ),
      );

  static const String _prefsKey = 'stitchflow_ui_density_v1';

  final SharedPreferences _prefs;

  Future<void> setMode(UiDensityMode mode) async {
    if (state.mode == mode) return;
    emit(DensityState(mode: mode));
    await _prefs.setString(_prefsKey, mode.storageKey);
  }
}
