import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_elevation.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/design_system/app_typography.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoPageTransitionsBuilder;
import 'package:material_ui/material_ui.dart';

/// Centralized Material 3 light and dark themes for the v1.4 "Indigo Thread"
/// color system: solid surfaces, soft layered shadows (see `AppShadows`) and
/// WCAG AA text contrast for bilingual (Gujarati/English) readability.
abstract final class AppTheme {
  static final ThemeData _lightTheme = _build(Brightness.light);
  static final ThemeData _darkTheme = _build(Brightness.dark);

  static ThemeData light() => _lightTheme;

  static ThemeData dark() => _darkTheme;

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final baseScheme = ColorScheme.fromSeed(
      seedColor: AppColors.brandPrimary,
      secondary: AppColors.brandSecondary,
      tertiary: AppColors.brandAccent,
      brightness: brightness,
    );
    final colorScheme = isDark
        ? baseScheme.copyWith(
            primary: AppColors.indigo400,
            onPrimary: AppColors.indigo950,
            primaryContainer: AppColors.indigo900,
            onPrimaryContainer: AppColors.indigo100,
            secondary: AppColors.emerald400,
            onSecondary: AppColors.emerald950,
            secondaryContainer: AppColors.emerald900,
            onSecondaryContainer: AppColors.emerald100,
            tertiary: AppColors.saffron400,
            onTertiary: AppColors.saffron900,
            error: AppColors.darkDamaged,
            onError: const Color(0xFF450A0A),
            errorContainer: AppColors.darkDamagedContainer,
            onErrorContainer: AppColors.lightDamagedContainer,
            surface: AppColors.darkSurface,
            onSurface: AppColors.slate100,
            onSurfaceVariant: AppColors.slate400,
            surfaceContainerLowest: AppColors.darkSurfaceLowest,
            surfaceContainerLow: AppColors.darkSurfaceLow,
            surfaceContainer: AppColors.darkSurfaceContainer,
            surfaceContainerHigh: AppColors.darkSurfaceHigh,
            surfaceContainerHighest: AppColors.darkSurfaceHighest,
            outline: AppColors.darkBorderStrong,
            outlineVariant: AppColors.darkBorder,
            inverseSurface: AppColors.slate100,
            onInverseSurface: AppColors.slate900,
            inversePrimary: AppColors.indigo600,
          )
        : baseScheme.copyWith(
            primary: AppColors.indigo600,
            onPrimary: Colors.white,
            primaryContainer: AppColors.indigo100,
            onPrimaryContainer: AppColors.indigo900,
            secondary: AppColors.emerald600,
            onSecondary: Colors.white,
            secondaryContainer: AppColors.emerald100,
            onSecondaryContainer: AppColors.emerald900,
            tertiary: AppColors.saffron500,
            onTertiary: AppColors.slate900,
            tertiaryContainer: AppColors.saffron100,
            onTertiaryContainer: AppColors.saffron800,
            error: AppColors.lightDamaged,
            onError: Colors.white,
            errorContainer: AppColors.lightDamagedContainer,
            onErrorContainer: AppColors.darkDamagedContainer,
            surface: AppColors.lightBackground,
            onSurface: AppColors.slate900,
            onSurfaceVariant: AppColors.slate600,
            surfaceContainerLowest: AppColors.lightCardSurface,
            surfaceContainerLow: AppColors.lightCardSurface,
            surfaceContainer: AppColors.slate100,
            surfaceContainerHigh: AppColors.slate100,
            surfaceContainerHighest: AppColors.slate200,
            outline: AppColors.lightBorderStrong,
            outlineVariant: AppColors.lightBorder,
            inverseSurface: AppColors.slate800,
            onInverseSurface: AppColors.slate50,
            inversePrimary: AppColors.indigo300,
          );
    final textTheme = AppTypography.buildTextTheme(colorScheme);
    final semanticColors = isDark
        ? AppSemanticColors.dark
        : AppSemanticColors.light;
    final surfaceTokens = isDark
        ? AppSurfaceTokens.dark
        : AppSurfaceTokens.light;

    final glassInputBorderColor = isDark
        ? AppColors.darkBorderStrong
        : AppColors.lightBorderStrong;

    final outlineBorder = OutlineInputBorder(
      borderRadius: AppRadius.mdBorder,
      borderSide: BorderSide(color: glassInputBorderColor),
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
      // Native-feeling navigation (used by every pushed page via
      // `AppMotion.buildPage`): Android follows the predictive back gesture,
      // iOS/macOS keep edge-swipe back, desktop/web use a light fade-forward.
      // `allowSnapshotting: false` prevents freezing a frame-0 loading spinner
      // bitmap across the transition and snapping to loaded content at t=1.0.
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(
            fallbackColor: colorScheme.surface,
            allowSnapshotting: false,
          ),
          TargetPlatform.iOS: const CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: const CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(
            backgroundColor: colorScheme.surface,
            allowSnapshotting: false,
          ),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(
            backgroundColor: colorScheme.surface,
            allowSnapshotting: false,
          ),
          TargetPlatform.fuchsia: FadeForwardsPageTransitionsBuilder(
            backgroundColor: colorScheme.surface,
            allowSnapshotting: false,
          ),
        },
      ),
      focusColor: colorScheme.primary.withValues(alpha: isDark ? 0.24 : 0.14),
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
          side: BorderSide(color: surfaceTokens.glassBorder),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 70,
        backgroundColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.fullBorder,
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
        backgroundColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: colorScheme.onPrimaryContainer),
        selectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.primary,
        ),
        unselectedLabelTextStyle: textTheme.labelSmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: AppRadius.mdBorder,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceTokens.glassFill,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.fullBorder),
        side: BorderSide(color: colorScheme.outlineVariant),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        selectedColor: colorScheme.primaryContainer,
        checkmarkColor: colorScheme.onPrimaryContainer,
        labelStyle: textTheme.labelMedium,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primaryContainer;
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
          color: colorScheme.primary,
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
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
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
          side: BorderSide(color: colorScheme.outline),
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
          side: BorderSide(color: surfaceTokens.glassBorder),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        showDragHandle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdBorder),
        backgroundColor: colorScheme.inverseSurface,
        actionTextColor: colorScheme.inversePrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
      // Determinate/linear progress (export, backup) matches the brand spinner.
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primary.withValues(alpha: 0.14),
        circularTrackColor: colorScheme.primary.withValues(alpha: 0.14),
        linearMinHeight: 4,
        borderRadius: AppRadius.fullBorder,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
