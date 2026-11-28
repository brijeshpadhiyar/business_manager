import 'package:business_manager/core/theme/theme_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages and locally persists the user's selected theme mode
/// (`System Default`, `Light`, `Dark`), surface style (`Modern Glass`,
/// `Liquid Aurora`, `Classic Solid`), and color preset.
@lazySingleton
final class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit(this._prefs)
    : super(
        ThemeState(
          preference: AppThemePreference.fromStorageKey(
            _prefs.getString(_themePreferenceKey),
          ),
          surfaceStyle: AppSurfaceStyle.fromStorageKey(
            _prefs.getString(_surfaceStyleKey),
          ),
          preset: AppThemePreset.fromStorageKey(
            _prefs.getString(_themePresetKey),
          ),
        ),
      );

  static const String _themePreferenceKey = 'app_theme_preference';
  static const String _surfaceStyleKey = 'app_surface_style';
  static const String _themePresetKey = 'app_theme_preset';

  final SharedPreferences _prefs;

  Future<void> setPreference(AppThemePreference preference) async {
    await _prefs.setString(_themePreferenceKey, preference.storageKey);
    emit(state.copyWith(preference: preference));
  }

  Future<void> setSurfaceStyle(AppSurfaceStyle surfaceStyle) async {
    await _prefs.setString(_surfaceStyleKey, surfaceStyle.storageKey);
    emit(state.copyWith(surfaceStyle: surfaceStyle));
  }

  Future<void> setPreset(AppThemePreset preset) async {
    await _prefs.setString(_themePresetKey, preset.storageKey);
    emit(state.copyWith(preset: preset));
  }
}
