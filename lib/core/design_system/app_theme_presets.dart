import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/theme/theme_state.dart';
import 'package:material_ui/material_ui.dart';

/// Resolved WCAG 2.2 AA palette definition for an [AppThemePreset].
@immutable
final class AppPresetPalette {
  const AppPresetPalette({
    required this.preset,
    required this.primaryLight,
    required this.onPrimaryLight,
    required this.primaryContainerLight,
    required this.onPrimaryContainerLight,
    required this.secondaryLight,
    required this.onSecondaryLight,
    required this.secondaryContainerLight,
    required this.onSecondaryContainerLight,
    required this.primaryDark,
    required this.onPrimaryDark,
    required this.primaryContainerDark,
    required this.onPrimaryContainerDark,
    required this.secondaryDark,
    required this.onSecondaryDark,
    required this.secondaryContainerDark,
    required this.onSecondaryContainerDark,
    required this.heroGradientLight,
    required this.heroGradientDark,
    required this.primaryButtonGradientLight,
    required this.primaryButtonGradientDark,
    required this.swatchColor,
    required this.accentOrbLight,
    required this.accentOrbDark,
    required this.secondaryOrbLight,
    required this.secondaryOrbDark,
    required this.meshColorsLight,
    required this.meshColorsDark,
  });

  final AppThemePreset preset;

  final Color primaryLight;
  final Color onPrimaryLight;
  final Color primaryContainerLight;
  final Color onPrimaryContainerLight;
  final Color secondaryLight;
  final Color onSecondaryLight;
  final Color secondaryContainerLight;
  final Color onSecondaryContainerLight;

  final Color primaryDark;
  final Color onPrimaryDark;
  final Color primaryContainerDark;
  final Color onPrimaryContainerDark;
  final Color secondaryDark;
  final Color onSecondaryDark;
  final Color secondaryContainerDark;
  final Color onSecondaryContainerDark;

  final LinearGradient heroGradientLight;
  final LinearGradient heroGradientDark;
  final LinearGradient primaryButtonGradientLight;
  final LinearGradient primaryButtonGradientDark;

  final Color swatchColor;
  final Color accentOrbLight;
  final Color accentOrbDark;
  final Color secondaryOrbLight;
  final Color secondaryOrbDark;
  final List<Color> meshColorsLight;
  final List<Color> meshColorsDark;

  Color primaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? primaryDark : primaryLight;

  Color secondaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? secondaryDark : secondaryLight;

  LinearGradient heroGradientFor(Brightness brightness) =>
      brightness == Brightness.dark ? heroGradientDark : heroGradientLight;

  List<Color> meshColorsFor(Brightness brightness) =>
      brightness == Brightness.dark ? meshColorsDark : meshColorsLight;

  static AppPresetPalette of(AppThemePreset preset) => switch (preset) {
    AppThemePreset.indigoThread => _indigoThread,
    AppThemePreset.emeraldMint => _emeraldMint,
    AppThemePreset.midnightCyan => _midnightCyan,
    AppThemePreset.royalSaffron => _royalSaffron,
  };

  static const AppPresetPalette _indigoThread = AppPresetPalette(
    preset: AppThemePreset.indigoThread,
    primaryLight: AppColors.indigo600,
    onPrimaryLight: Colors.white,
    primaryContainerLight: AppColors.indigo100,
    onPrimaryContainerLight: AppColors.indigo900,
    secondaryLight: AppColors.emerald700,
    onSecondaryLight: Colors.white,
    secondaryContainerLight: AppColors.emerald100,
    onSecondaryContainerLight: AppColors.emerald900,
    primaryDark: AppColors.indigo400,
    onPrimaryDark: AppColors.indigo950,
    primaryContainerDark: AppColors.indigo900,
    onPrimaryContainerDark: AppColors.indigo100,
    secondaryDark: AppColors.emerald400,
    onSecondaryDark: AppColors.emerald950,
    secondaryContainerDark: AppColors.emerald900,
    onSecondaryContainerDark: AppColors.emerald100,
    heroGradientLight: AppColors.heroGradientLight,
    heroGradientDark: AppColors.heroGradientDark,
    primaryButtonGradientLight: AppColors.primaryButtonGradientLight,
    primaryButtonGradientDark: AppColors.primaryButtonGradientDark,
    swatchColor: AppColors.indigo600,
    accentOrbLight: AppColors.indigo500,
    accentOrbDark: AppColors.indigo400,
    secondaryOrbLight: AppColors.emerald500,
    secondaryOrbDark: AppColors.emerald400,
    meshColorsLight: [
      Color(0xFFF3F6FC),
      Color(0xFFEEF2FD),
      Color(0xFFF8FAFC),
      Color(0xFFF5F7FC),
    ],
    meshColorsDark: [
      Color(0xFF0B1020),
      Color(0xFF101632),
      Color(0xFF0D1328),
      Color(0xFF0B1020),
    ],
  );

  static const AppPresetPalette _emeraldMint = AppPresetPalette(
    preset: AppThemePreset.emeraldMint,
    primaryLight: AppColors.emerald700,
    onPrimaryLight: Colors.white,
    primaryContainerLight: AppColors.emerald100,
    onPrimaryContainerLight: AppColors.emerald900,
    secondaryLight: Color(0xFF0369A1),
    onSecondaryLight: Colors.white,
    secondaryContainerLight: Color(0xFFE0F2FE),
    onSecondaryContainerLight: Color(0xFF0C4A6E),
    primaryDark: AppColors.emerald400,
    onPrimaryDark: AppColors.emerald950,
    primaryContainerDark: AppColors.emerald900,
    onPrimaryContainerDark: AppColors.emerald100,
    secondaryDark: Color(0xFF38BDF8),
    onSecondaryDark: Color(0xFF082F49),
    secondaryContainerDark: Color(0xFF0C4A6E),
    onSecondaryContainerDark: Color(0xFFE0F2FE),
    heroGradientLight: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.emerald800, AppColors.emerald700, Color(0xFF0369A1)],
      stops: [0.0, 0.55, 1.0],
    ),
    heroGradientDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.emerald900, AppColors.emerald950, Color(0xFF0C4A6E)],
      stops: [0.0, 0.55, 1.0],
    ),
    primaryButtonGradientLight: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.emerald700, AppColors.emerald800],
    ),
    primaryButtonGradientDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.emerald400, AppColors.emerald500],
    ),
    swatchColor: AppColors.emerald600,
    accentOrbLight: AppColors.emerald500,
    accentOrbDark: AppColors.emerald400,
    secondaryOrbLight: Color(0xFF0EA5E9),
    secondaryOrbDark: Color(0xFF38BDF8),
    meshColorsLight: [
      Color(0xFFF2FAF7),
      Color(0xFFEDF7F3),
      Color(0xFFF8FAFC),
      Color(0xFFF4FBF8),
    ],
    meshColorsDark: [
      Color(0xFF0B1020),
      Color(0xFF0B1C1E),
      Color(0xFF0C151F),
      Color(0xFF0B1020),
    ],
  );

  static const AppPresetPalette _midnightCyan = AppPresetPalette(
    preset: AppThemePreset.midnightCyan,
    primaryLight: Color(0xFF0369A1),
    onPrimaryLight: Colors.white,
    primaryContainerLight: Color(0xFFE0F2FE),
    onPrimaryContainerLight: Color(0xFF0C4A6E),
    secondaryLight: AppColors.indigo600,
    onSecondaryLight: Colors.white,
    secondaryContainerLight: AppColors.indigo100,
    onSecondaryContainerLight: AppColors.indigo900,
    primaryDark: Color(0xFF38BDF8),
    onPrimaryDark: Color(0xFF082F49),
    primaryContainerDark: Color(0xFF0C4A6E),
    onPrimaryContainerDark: Color(0xFFE0F2FE),
    secondaryDark: AppColors.indigo400,
    onSecondaryDark: AppColors.indigo950,
    secondaryContainerDark: AppColors.indigo900,
    onSecondaryContainerDark: AppColors.indigo100,
    heroGradientLight: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0C4A6E), Color(0xFF0369A1), AppColors.indigo700],
      stops: [0.0, 0.55, 1.0],
    ),
    heroGradientDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF082F49), Color(0xFF0B1020), AppColors.indigo900],
      stops: [0.0, 0.55, 1.0],
    ),
    primaryButtonGradientLight: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
    ),
    primaryButtonGradientDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
    ),
    swatchColor: Color(0xFF0284C7),
    accentOrbLight: Color(0xFF0EA5E9),
    accentOrbDark: Color(0xFF38BDF8),
    secondaryOrbLight: AppColors.indigo500,
    secondaryOrbDark: AppColors.indigo400,
    meshColorsLight: [
      Color(0xFFF1F8FD),
      Color(0xFFECF5FC),
      Color(0xFFF8FAFC),
      Color(0xFFF4F9FD),
    ],
    meshColorsDark: [
      Color(0xFF0B1020),
      Color(0xFF0C1A2E),
      Color(0xFF0B1426),
      Color(0xFF0B1020),
    ],
  );

  static const AppPresetPalette _royalSaffron = AppPresetPalette(
    preset: AppThemePreset.royalSaffron,
    primaryLight: AppColors.saffron700,
    onPrimaryLight: Colors.white,
    primaryContainerLight: AppColors.saffron100,
    onPrimaryContainerLight: AppColors.saffron900,
    secondaryLight: AppColors.indigo600,
    onSecondaryLight: Colors.white,
    secondaryContainerLight: AppColors.indigo100,
    onSecondaryContainerLight: AppColors.indigo900,
    primaryDark: AppColors.saffron400,
    onPrimaryDark: Color(0xFF451A03),
    primaryContainerDark: AppColors.saffron900,
    onPrimaryContainerDark: AppColors.saffron100,
    secondaryDark: AppColors.indigo400,
    onSecondaryDark: AppColors.indigo950,
    secondaryContainerDark: AppColors.indigo900,
    onSecondaryContainerDark: AppColors.indigo100,
    heroGradientLight: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.saffron800, AppColors.saffron700, AppColors.indigo700],
      stops: [0.0, 0.55, 1.0],
    ),
    heroGradientDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF451A03), AppColors.saffron900, AppColors.indigo900],
      stops: [0.0, 0.55, 1.0],
    ),
    primaryButtonGradientLight: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.saffron700, AppColors.saffron800],
    ),
    primaryButtonGradientDark: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.saffron400, AppColors.saffron500],
    ),
    swatchColor: AppColors.saffron600,
    accentOrbLight: AppColors.saffron500,
    accentOrbDark: AppColors.saffron400,
    secondaryOrbLight: AppColors.indigo500,
    secondaryOrbDark: AppColors.indigo400,
    meshColorsLight: [
      Color(0xFFFCF8EE),
      Color(0xFFFAF5E6),
      Color(0xFFF8FAFC),
      Color(0xFFFCF9F2),
    ],
    meshColorsDark: [
      Color(0xFF0B1020),
      Color(0xFF1B1519),
      Color(0xFF12121D),
      Color(0xFF0B1020),
    ],
  );
}

