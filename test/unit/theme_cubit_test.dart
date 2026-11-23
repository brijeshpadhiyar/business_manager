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
      'light and dark themes expose correct brightness and semantic tokens',
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
      },
    );
  });

  group('ThemeCubit persistence', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('defaults to System theme when no preference is stored', () {
      final cubit = ThemeCubit(prefs);
      expect(cubit.state.preference, AppThemePreference.system);
      expect(cubit.state.preference.themeMode, ThemeMode.system);
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

    test('restores saved dark theme preference across app restarts', () async {
      SharedPreferences.setMockInitialValues({'app_theme_preference': 'dark'});
      final restoredPrefs = await SharedPreferences.getInstance();
      final restoredCubit = ThemeCubit(restoredPrefs);

      expect(restoredCubit.state.preference, AppThemePreference.dark);
      expect(restoredCubit.state.preference.themeMode, ThemeMode.dark);
    });
  });
}
