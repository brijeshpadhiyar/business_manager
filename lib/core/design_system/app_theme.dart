import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_elevation.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/design_system/app_typography.dart';
import 'package:material_ui/material_ui.dart';

/// Centralized Material 3 Light and Dark theme definitions built on
/// `package:material_ui/material_ui.dart`.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandNavy,
      secondary: AppColors.brandTeal,
      tertiary: AppColors.brandAmber,
      brightness: brightness,
    );
    final colorScheme = isDark
        ? baseScheme.copyWith(
            secondary: AppColors.brandTeal,
            tertiary: AppColors.brandAmber,
          )
        : baseScheme.copyWith(
            primary: AppColors.brandNavy,
            secondary: AppColors.brandTeal,
            tertiary: AppColors.brandAmber,
            surface: AppColors.brandSoftWhite,
          );
    final textTheme = AppTypography.buildTextTheme(colorScheme);
    final semanticColors = isDark
        ? AppSemanticColors.dark
        : AppSemanticColors.light;

    final outlineBorder = OutlineInputBorder(
      borderRadius: AppRadius.mdBorder,
      borderSide: BorderSide(color: colorScheme.outlineVariant),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: AppTypography.fontFamily,
      textTheme: textTheme,
      extensions: [semanticColors],
      visualDensity: VisualDensity.standard,
      appBarTheme: AppBarTheme(
        toolbarHeight: AppSizing.appBarHeight,
        elevation: AppElevation.none,
        scrolledUnderElevation: AppElevation.low,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: AppElevation.none,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdBorder,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 11,
        ),
        constraints: const BoxConstraints(minHeight: AppSizing.inputHeight),
        border: outlineBorder,
        enabledBorder: outlineBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppSizing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppSizing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppSizing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconTheme: IconThemeData(
        size: AppSizing.iconMd,
        color: colorScheme.onSurfaceVariant,
      ),
      dialogTheme: const DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
