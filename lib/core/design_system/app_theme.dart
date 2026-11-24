import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_elevation.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/design_system/app_typography.dart';
import 'package:material_ui/material_ui.dart';

/// Centralized Material 3 Light Glass and Dark Glass theme definitions built on
/// `package:material_ui/material_ui.dart` with StitchFlow's brand identity,
/// genuine frosted glass tokens, and high-contrast bilingual readability.
abstract final class AppTheme {
  static final ThemeData _lightTheme = _build(Brightness.light);
  static final ThemeData _darkTheme = _build(Brightness.dark);

  static ThemeData light() => _lightTheme;

  static ThemeData dark() => _darkTheme;

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
            primary: const Color(0xFF7DD3FC),
            onPrimary: const Color(0xFF082032),
            secondary: AppColors.brandTeal,
            onSecondary: Colors.white,
            tertiary: AppColors.brandAmber,
            error: const Color(0xFFFCA5A5),
            onError: const Color(0xFF450A0A),
            errorContainer: AppColors.darkDamagedContainer,
            onErrorContainer: const Color(0xFFFEE2E2),
            surface: AppColors.darkSurface,
            surfaceContainerLowest: const Color(0xFF0A101C),
            surfaceContainerLow: AppColors.darkSurfaceLow,
            surfaceContainer: const Color(0xFF162235),
            surfaceContainerHigh: AppColors.darkSurfaceHigh,
            outlineVariant: AppColors.darkBorder,
          )
        : baseScheme.copyWith(
            primary: AppColors.brandNavy,
            secondary: AppColors.brandTeal,
            tertiary: AppColors.brandAmber,
            error: AppColors.lightDamaged,
            onError: Colors.white,
            errorContainer: AppColors.lightDamagedContainer,
            onErrorContainer: const Color(0xFF7F1D1D),
            surface: AppColors.brandSoftWhite,
            surfaceContainerLowest: AppColors.lightCardSurface,
            surfaceContainerLow: AppColors.lightCardSurface,
            surfaceContainer: const Color(0xFFEDF3F9),
            outlineVariant: AppColors.lightBorder,
          );
    final textTheme = AppTypography.buildTextTheme(colorScheme);
    final semanticColors = isDark
        ? AppSemanticColors.dark
        : AppSemanticColors.light;
    final surfaceTokens = isDark
        ? AppSurfaceTokens.dark
        : AppSurfaceTokens.light;

    final glassInputBorderColor = isDark
        ? Colors.white.withValues(alpha: 0.16)
        : const Color(0xFF172B4D).withValues(alpha: 0.14);

    final outlineBorder = OutlineInputBorder(
      borderRadius: AppRadius.mdBorder,
      borderSide: BorderSide(color: glassInputBorderColor, width: 1.1),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      textTheme: textTheme,
      extensions: [semanticColors, surfaceTokens],
      visualDensity: VisualDensity.standard,
      focusColor: colorScheme.secondary.withValues(alpha: isDark ? 0.24 : 0.16),
      hoverColor: colorScheme.primary.withValues(alpha: isDark ? 0.10 : 0.05),
      appBarTheme: AppBarTheme(
        toolbarHeight: AppSizing.appBarHeight,
        elevation: AppElevation.none,
        scrolledUnderElevation: AppElevation.none,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: AppElevation.none,
        margin: EdgeInsets.zero,
        color: surfaceTokens.glassFill,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgBorder,
          side: BorderSide(color: surfaceTokens.glassBorder, width: 1.1),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: Colors.transparent,
        indicatorColor: colorScheme.secondary.withValues(
          alpha: isDark ? 0.28 : 0.18,
        ),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: AppRadius.fullBorder,
          side: BorderSide(
            color: colorScheme.secondary.withValues(alpha: isDark ? 0.42 : 0.28),
            width: 1,
          ),
        ),
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.none,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? (isDark ? colorScheme.secondary : colorScheme.primary)
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: colorScheme.secondary.withValues(
          alpha: isDark ? 0.28 : 0.18,
        ),
        selectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: isDark ? colorScheme.secondary : colorScheme.primary,
        ),
        unselectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.secondary.withValues(
          alpha: isDark ? 0.26 : 0.16,
        ),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdBorder,
          side: BorderSide(
            color: colorScheme.secondary.withValues(alpha: isDark ? 0.36 : 0.24),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceTokens.glassFill,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.fullBorder),
        side: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.15)
              : const Color(0xFF172B4D).withValues(alpha: 0.12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        selectedColor: colorScheme.secondary.withValues(
          alpha: isDark ? 0.30 : 0.18,
        ),
        checkmarkColor: colorScheme.secondary,
        labelStyle: textTheme.labelMedium,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.secondary.withValues(
                alpha: isDark ? 0.30 : 0.18,
              );
            }
            return surfaceTokens.glassFill;
          }),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: surfaceTokens.glassBorder),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceTokens.inputGlassFill,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 2,
          vertical: 14,
        ),
        constraints: const BoxConstraints(minHeight: AppSizing.inputHeight),
        labelStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        floatingLabelStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.secondary,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
        ),
        helperMaxLines: 3,
        errorMaxLines: 3,
        errorStyle: textTheme.bodySmall?.copyWith(
          color: colorScheme.error,
          fontWeight: FontWeight.w500,
        ),
        border: outlineBorder,
        enabledBorder: outlineBorder,
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: BorderSide(color: colorScheme.secondary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: BorderSide(color: colorScheme.error, width: 1.3),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdBorder,
          borderSide: BorderSide(color: colorScheme.error, width: 1.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, AppSizing.buttonHeight),
          tapTargetSize: MaterialTapTargetSize.padded,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 10,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppSizing.buttonHeight),
          tapTargetSize: MaterialTapTargetSize.padded,
          backgroundColor: surfaceTokens.glassFill,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 10,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.22)
                : const Color(0xFF172B4D).withValues(alpha: 0.16),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(0, AppSizing.buttonHeight),
          tapTargetSize: MaterialTapTargetSize.padded,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconTheme: IconThemeData(
        size: AppSizing.iconMd,
        color: colorScheme.onSurfaceVariant,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceTokens.dialogGlassFill,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.xlBorder,
          side: BorderSide(color: surfaceTokens.glassBorder, width: 1.2),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdBorder,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
        ),
        backgroundColor: isDark
            ? const Color(0xEB182B47)
            : const Color(0xEB172B4D),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
      dividerTheme: DividerThemeData(
        color: isDark
            ? Colors.white.withValues(alpha: 0.10)
            : const Color(0xFF172B4D).withValues(alpha: 0.10),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
