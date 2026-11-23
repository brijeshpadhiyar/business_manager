import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:material_ui/material_ui.dart';

part 'theme_state.freezed.dart';

/// Persisted user theme preference options.
enum AppThemePreference {
  system('system'),
  light('light'),
  dark('dark');

  const AppThemePreference(this.storageKey);

  final String storageKey;

  ThemeMode get themeMode => switch (this) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };

  static AppThemePreference fromStorageKey(String? raw) {
    return AppThemePreference.values.firstWhere(
      (value) => value.storageKey == raw,
      orElse: () => AppThemePreference.system,
    );
  }
}

@freezed
sealed class ThemeState with _$ThemeState {
  const factory ThemeState({
    @Default(AppThemePreference.system) AppThemePreference preference,
  }) = _ThemeState;
}
