import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_elevation.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/design_system/app_typography.dart';
import 'package:material_ui/material_ui.dart';

/// Centralized Material 3 Light and Dark theme definitions built on
/// `package:material_ui/material_ui.dart` with StitchFlow's brand identity,
/// selective glass tokens, and high-contrast bilingual readability.
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
            surfaceContainer: const Color(0xFFF0F4F8),
            outlineVariant: AppColors.lightBorder,
          );
    final textTheme = AppTypography.buildTextTheme(colorScheme);
    final semanticColors = isDark
        ? AppSemanticColors.dark
        : AppSemanticColors.light;
    final surfaceTokens = isDark
        ? AppSurfaceTokens.dark
        : AppSurfaceTokens.light;

    final outlineBorder = OutlineInputBorder(
      borderRadius: AppRadius.mdBorder,
      borderSide: BorderSide(color: colorScheme.outlineVariant),
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
      appBarTheme: AppBarTheme(
        toolbarHeight: AppSizing.appBarHeight,
        elevation: AppElevation.none,
        scrolledUnderElevation: AppElevation.low,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        backgroundColor: surfaceTokens.navGlassFill,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        elevation: AppElevation.none,
        margin: EdgeInsets.zero,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgBorder,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: surfaceTokens.navGlassFill,
        indicatorColor: colorScheme.secondary.withValues(
          alpha: isDark ? 0.24 : 0.16,
        ),
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.none,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        indicatorColor: colorScheme.secondary.withValues(
          alpha: isDark ? 0.24 : 0.16,
        ),
        selectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
        ),
        unselectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        indicatorColor: colorScheme.secondary.withValues(
          alpha: isDark ? 0.24 : 0.15,
        ),
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.mdBorder,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.fullBorder),
        side: BorderSide(color: colorScheme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        selectedColor: colorScheme.secondary.withValues(
          alpha: isDark ? 0.26 : 0.14,
        ),
        checkmarkColor: colorScheme.secondary,
        labelStyle: textTheme.labelMedium,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: colorScheme.outlineVariant),
          ),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLowest,
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
          borderSide: BorderSide(color: colorScheme.secondary, width: 1.6),
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
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 10,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
          side: BorderSide(color: colorScheme.outlineVariant),
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
        backgroundColor: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgBorder,
          side: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: colorScheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        backgroundColor: isDark
            ? AppColors.darkSurfaceHigh
            : AppColors.brandNavy,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
