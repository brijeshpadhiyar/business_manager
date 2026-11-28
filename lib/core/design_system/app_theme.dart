import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_density.dart';
import 'package:business_manager/core/design_system/app_elevation.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_theme_presets.dart';
import 'package:business_manager/core/design_system/app_typography.dart';
import 'package:business_manager/core/theme/theme_state.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoPageTransitionsBuilder;
import 'package:material_ui/material_ui.dart';

/// Centralized Material 3 light and dark themes for StitchFlow's Next-Gen
/// adaptive glass & preset system with WCAG 2.2 AA contrast for bilingual
/// (Gujarati/English) readability.
abstract final class AppTheme {
  static final Map<
    (Brightness, VisualDensity, AppSurfaceStyle, AppThemePreset),
    ThemeData
  >
  _cache = {};

  static ThemeData light({
    VisualDensity? visualDensity,
    AppSurfaceStyle surfaceStyle = AppSurfaceStyle.modernGlass,
    AppThemePreset preset = AppThemePreset.indigoThread,
  }) {
    final vd = visualDensity ?? VisualDensity.standard;
    return _cache.putIfAbsent(
      (Brightness.light, vd, surfaceStyle, preset),
      () => _build(
        Brightness.light,
        visualDensity: vd,
        surfaceStyle: surfaceStyle,
        preset: preset,
      ),
    );
  }

  static ThemeData dark({
    VisualDensity? visualDensity,
    AppSurfaceStyle surfaceStyle = AppSurfaceStyle.modernGlass,
    AppThemePreset preset = AppThemePreset.indigoThread,
  }) {
    final vd = visualDensity ?? VisualDensity.standard;
    return _cache.putIfAbsent(
      (Brightness.dark, vd, surfaceStyle, preset),
      () => _build(
        Brightness.dark,
        visualDensity: vd,
        surfaceStyle: surfaceStyle,
        preset: preset,
      ),
    );
  }

  static ThemeData _build(
    Brightness brightness, {
    VisualDensity visualDensity = VisualDensity.standard,
    AppSurfaceStyle surfaceStyle = AppSurfaceStyle.modernGlass,
    AppThemePreset preset = AppThemePreset.indigoThread,
  }) {
    final isDark = brightness == Brightness.dark;
    final palette = AppPresetPalette.of(preset);
    final baseScheme = ColorScheme.fromSeed(
      seedColor: palette.primaryFor(brightness),
      secondary: palette.secondaryFor(brightness),
      tertiary: AppColors.brandAccent,
      brightness: brightness,
    );
    final colorScheme = isDark
        ? baseScheme.copyWith(
            primary: palette.primaryDark,
            onPrimary: palette.onPrimaryDark,
            primaryContainer: palette.primaryContainerDark,
            onPrimaryContainer: palette.onPrimaryContainerDark,
            secondary: palette.secondaryDark,
            onSecondary: palette.onSecondaryDark,
            secondaryContainer: palette.secondaryContainerDark,
            onSecondaryContainer: palette.onSecondaryContainerDark,
            tertiary: AppColors.saffron400,
            onTertiary: AppColors.saffron900,
            error: AppColors.darkDamaged,
            onError: AppColors.darkOnError,
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
            inversePrimary: palette.primaryLight,
          )
        : baseScheme.copyWith(
            primary: palette.primaryLight,
            onPrimary: palette.onPrimaryLight,
            primaryContainer: palette.primaryContainerLight,
            onPrimaryContainer: palette.onPrimaryContainerLight,
            secondary: palette.secondaryLight,
            onSecondary: palette.onSecondaryLight,
            secondaryContainer: palette.secondaryContainerLight,
            onSecondaryContainer: palette.onSecondaryContainerLight,
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
            inversePrimary: palette.primaryDark,
          );
    final isCompact = visualDensity == VisualDensity.compact;
    final density = isCompact
        ? AppDensityTokens.compact
        : AppDensityTokens.comfortable;
    final textTheme = AppTypography.buildTextTheme(
      colorScheme,
      compact: isCompact,
    );
    final semanticColors = isDark
        ? AppSemanticColors.dark
        : AppSemanticColors.light;
    final surfaceTokens = AppSurfaceTokens.resolve(
      brightness: brightness,
      style: surfaceStyle,
      preset: preset,
    );

    final glassInputBorderColor = isDark
        ? AppColors.darkBorderStrong
        : AppColors.lightBorderStrong;

    final outlineBorder = OutlineInputBorder(
      borderRadius: density.radiusMdBorder,
      borderSide: BorderSide(color: glassInputBorderColor),
    );

    final tapTarget = isCompact
        ? MaterialTapTargetSize.shrinkWrap
        : MaterialTapTargetSize.padded;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      visualDensity: visualDensity,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      textTheme: textTheme,
      extensions: [semanticColors, surfaceTokens, density],
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
        toolbarHeight: density.appBarHeight,
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
          borderRadius: density.radiusLgBorder,
          side: BorderSide(color: surfaceTokens.glassBorder),
        ),
      ),
      listTileTheme: ListTileThemeData(
        dense: isCompact,
        visualDensity: visualDensity,
        minVerticalPadding: isCompact ? 2 : null,
        minLeadingWidth: isCompact ? 24 : null,
        horizontalTitleGap: isCompact ? 8 : null,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: density.navBarHeight,
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
        minWidth: density.navigationRailWidth,
        backgroundColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,
        selectedIconTheme: IconThemeData(
          color: colorScheme.onPrimaryContainer,
          size: density.iconMd,
        ),
        unselectedIconTheme: IconThemeData(
          color: colorScheme.onSurfaceVariant,
          size: density.iconMd,
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
        tileHeight: isCompact ? 38 : null,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: density.radiusMdBorder,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceTokens.glassFill,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.fullBorder),
        side: BorderSide(color: colorScheme.outlineVariant),
        padding: density.chipPadding,
        selectedColor: colorScheme.primaryContainer,
        checkmarkColor: colorScheme.onPrimaryContainer,
        labelStyle: textTheme.labelMedium,
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          tapTargetSize: tapTarget,
          visualDensity: visualDensity,
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primaryContainer;
            }
            return surfaceTokens.glassFill;
          }),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: density.radiusMdBorder),
          ),
          side: WidgetStatePropertyAll(
            BorderSide(color: surfaceTokens.glassBorder),
          ),
          padding: WidgetStatePropertyAll(density.segmentPadding),
          textStyle: WidgetStatePropertyAll(textTheme.labelMedium),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        isDense: isCompact,
        fillColor: surfaceTokens.inputGlassFill,
        contentPadding: EdgeInsets.symmetric(
          horizontal: density.inputHorizontal,
          vertical: density.inputVertical,
        ),
        constraints: BoxConstraints(minHeight: density.inputHeight),
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
          borderRadius: density.radiusMdBorder,
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: density.radiusMdBorder,
          borderSide: BorderSide(color: colorScheme.error, width: 1.3),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: density.radiusMdBorder,
          borderSide: BorderSide(color: colorScheme.error, width: 1.8),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: Size(0, density.buttonHeight),
          tapTargetSize: tapTarget,
          padding: EdgeInsets.symmetric(
            horizontal: density.lg,
            vertical: density.buttonVertical,
          ),
          shape: RoundedRectangleBorder(borderRadius: density.radiusMdBorder),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: Size(0, density.buttonHeight),
          tapTargetSize: tapTarget,
          backgroundColor: surfaceTokens.glassFill,
          padding: EdgeInsets.symmetric(
            horizontal: density.lg,
            vertical: density.buttonVertical,
          ),
          shape: RoundedRectangleBorder(borderRadius: density.radiusMdBorder),
          side: BorderSide(color: colorScheme.outline),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: Size(0, density.buttonHeight),
          tapTargetSize: tapTarget,
          padding: EdgeInsets.symmetric(
            horizontal: density.md,
            vertical: density.buttonVertical,
          ),
          shape: RoundedRectangleBorder(borderRadius: density.radiusMdBorder),
          textStyle: textTheme.labelLarge,
        ),
      ),
      iconTheme: IconThemeData(
        size: density.iconMd,
        color: colorScheme.onSurfaceVariant,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceTokens.dialogGlassFill,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: density.radiusXlBorder,
          side: BorderSide(color: surfaceTokens.glassBorder),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(density.radiusXl),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: density.radiusMdBorder),
        backgroundColor: colorScheme.inverseSurface,
        actionTextColor: colorScheme.inversePrimary,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primary.withValues(alpha: 0.14),
        circularTrackColor: colorScheme.primary.withValues(alpha: 0.14),
        linearMinHeight: isCompact ? 3 : 4,
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
