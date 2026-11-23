import 'package:business_manager/core/theme/theme_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages and locally persists the user's selected theme mode
/// (`System Default`, `Light`, or `Dark`).
@lazySingleton
final class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit(this._prefs)
      : super(
          ThemeState(
            preference: AppThemePreference.fromStorageKey(
              _prefs.getString(_themePreferenceKey),
            ),
          ),
        );

  static const String _themePreferenceKey = 'app_theme_preference';

  final SharedPreferences _prefs;

  Future<void> setPreference(AppThemePreference preference) async {
    await _prefs.setString(_themePreferenceKey, preference.storageKey);
    emit(state.copyWith(preference: preference));
  }
}
