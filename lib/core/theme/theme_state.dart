import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:material_ui/material_ui.dart';

part 'theme_state.freezed.dart';

/// Persisted user theme mode preference options.
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

/// Persisted surface rendering style for StitchFlow's adaptive glass system.
enum AppSurfaceStyle {
  /// Frosted translucent chrome & hero panels with crisp 1px specular borders.
  modernGlass('modern_glass'),

  /// Animated shader mesh backdrop + GPU liquid glass refraction on supported
  /// platforms with graceful frosted-glass fallback on desktop/web.
  liquidAurora('liquid_aurora'),

  /// Opaque v1.4 soft-elevation surfaces (zero backdrop blur).
  classicSolid('classic_solid');

  const AppSurfaceStyle(this.storageKey);

  final String storageKey;

  bool get isGlass => this != AppSurfaceStyle.classicSolid;

  static AppSurfaceStyle fromStorageKey(String? raw) {
    return AppSurfaceStyle.values.firstWhere(
      (value) => value.storageKey == raw,
      orElse: () => AppSurfaceStyle.modernGlass,
    );
  }
}

/// Curated WCAG 2.2 AA brand palette presets.
enum AppThemePreset {
  indigoThread('indigo_thread'),
  emeraldMint('emerald_mint'),
  midnightCyan('midnight_cyan'),
  royalSaffron('royal_saffron');

  const AppThemePreset(this.storageKey);

  final String storageKey;

  static AppThemePreset fromStorageKey(String? raw) {
    return AppThemePreset.values.firstWhere(
      (value) => value.storageKey == raw,
      orElse: () => AppThemePreset.indigoThread,
    );
  }
}

@freezed
sealed class ThemeState with _$ThemeState {
  const factory ThemeState({
    @Default(AppThemePreference.system) AppThemePreference preference,
    @Default(AppSurfaceStyle.modernGlass) AppSurfaceStyle surfaceStyle,
    @Default(AppThemePreset.indigoThread) AppThemePreset preset,
  }) = _ThemeState;
}
