import 'package:bloc_test/bloc_test.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/theme/theme_cubit.dart';
import 'package:business_manager/core/theme/theme_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppTheme', () {
    test(
      'light and dark themes expose correct brightness, semantic, and surface tokens',
      () {
        final light = AppTheme.light();
        final dark = AppTheme.dark();

        expect(light.brightness, Brightness.light);
        expect(dark.brightness, Brightness.dark);
        expect(
          light.extension<AppSemanticColors>()?.goodStock,
          AppColors.lightGoodStock,
        );
        expect(
          dark.extension<AppSemanticColors>()?.goodStock,
          AppColors.darkGoodStock,
        );
        expect(
          light.extension<AppSurfaceTokens>()?.surfaceStyle,
          AppSurfaceStyle.modernGlass,
        );
        expect(
          AppTheme.light(
            surfaceStyle: AppSurfaceStyle.classicSolid,
            preset: AppThemePreset.emeraldMint,
          ).extension<AppSurfaceTokens>()?.preset,
          AppThemePreset.emeraldMint,
        );
      },
    );

    test(
      'Modern Frosted Glass and Liquid Aurora Glass use glare-free uniform fills without multi-color backdrop blobs',
      () {
        for (final brightness in [Brightness.light, Brightness.dark]) {
          for (final preset in AppThemePreset.values) {
            final modern = AppSurfaceTokens.resolve(
              brightness: brightness,
              style: AppSurfaceStyle.modernGlass,
              preset: preset,
            );
            expect(modern.glassHighlightTop, modern.glassFill);
            expect(modern.glassHighlightBottom, modern.glassFill);
            expect(modern.orbPrimary.a, 0);
            expect(modern.orbSecondary.a, 0);
            expect(modern.orbAccent.a, 0);
            expect(modern.backdropTop, modern.backdropMid);
            expect(modern.backdropBottom, modern.backdropMid);

            final aurora = AppSurfaceTokens.resolve(
              brightness: brightness,
              style: AppSurfaceStyle.liquidAurora,
              preset: preset,
            );
            expect(aurora.glassHighlightTop, aurora.glassFill);
            expect(aurora.glassHighlightBottom, aurora.glassFill);
            expect(aurora.orbPrimary.a, greaterThan(0));
            expect(aurora.orbSecondary.a, 0);
            expect(aurora.orbAccent.a, 0);
          }
        }
      },
    );
  });

  group('ThemeCubit persistence', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('defaults to System theme, Modern Glass, and Indigo Thread', () {
      final cubit = ThemeCubit(prefs);
      expect(cubit.state.preference, AppThemePreference.system);
      expect(cubit.state.preference.themeMode, ThemeMode.system);
      expect(cubit.state.surfaceStyle, AppSurfaceStyle.modernGlass);
      expect(cubit.state.preset, AppThemePreset.indigoThread);
    });

    blocTest<ThemeCubit, ThemeState>(
      'persists dark, light, and system preferences cleanly',
      build: () => ThemeCubit(prefs),
      act: (cubit) async {
        await cubit.setPreference(AppThemePreference.dark);
        await cubit.setPreference(AppThemePreference.light);
        await cubit.setPreference(AppThemePreference.system);
      },
      expect: () => const [
        ThemeState(preference: AppThemePreference.dark),
        ThemeState(preference: AppThemePreference.light),
        ThemeState(preference: AppThemePreference.system),
      ],
      verify: (_) {
        expect(prefs.getString('app_theme_preference'), 'system');
      },
    );

    blocTest<ThemeCubit, ThemeState>(
      'persists surfaceStyle and color preset cleanly',
      build: () => ThemeCubit(prefs),
      act: (cubit) async {
        await cubit.setSurfaceStyle(AppSurfaceStyle.liquidAurora);
        await cubit.setPreset(AppThemePreset.emeraldMint);
        await cubit.setSurfaceStyle(AppSurfaceStyle.classicSolid);
      },
      expect: () => const [
        ThemeState(surfaceStyle: AppSurfaceStyle.liquidAurora),
        ThemeState(
          surfaceStyle: AppSurfaceStyle.liquidAurora,
          preset: AppThemePreset.emeraldMint,
        ),
        ThemeState(
          surfaceStyle: AppSurfaceStyle.classicSolid,
          preset: AppThemePreset.emeraldMint,
        ),
      ],
      verify: (_) {
        expect(prefs.getString('app_surface_style'), 'classic_solid');
        expect(prefs.getString('app_theme_preset'), 'emerald_mint');
      },
    );

    test('restores saved theme, surface style, and preset across restarts', () async {
      SharedPreferences.setMockInitialValues({
        'app_theme_preference': 'dark',
        'app_surface_style': 'liquid_aurora',
        'app_theme_preset': 'midnight_cyan',
      });
      final restoredPrefs = await SharedPreferences.getInstance();
      final restoredCubit = ThemeCubit(restoredPrefs);

      expect(restoredCubit.state.preference, AppThemePreference.dark);
      expect(restoredCubit.state.preference.themeMode, ThemeMode.dark);
      expect(restoredCubit.state.surfaceStyle, AppSurfaceStyle.liquidAurora);
      expect(restoredCubit.state.preset, AppThemePreset.midnightCyan);
    });
  });
}
