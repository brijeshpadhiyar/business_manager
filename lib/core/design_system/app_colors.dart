import 'package:business_manager/core/design_system/app_theme_presets.dart';
import 'package:business_manager/core/theme/theme_state.dart';
import 'package:material_ui/material_ui.dart';

/// StitchFlow "Indigo Thread" color system and Next-Gen Glass tokens.
///
/// Built like Tailwind / Radix scales: every brand hue has a 50–950 ramp, and
/// UI code should reference *roles* (brandPrimary, surfaces, semantic tokens)
/// rather than raw steps. All text/background pairs target WCAG 2.2 AA.
abstract final class AppColors {
  // ── Indigo (primary) ───────────────────────────────────────────────────────
  static const Color indigo50 = Color(0xFFEEF2FF);
  static const Color indigo100 = Color(0xFFE0E7FF);
  static const Color indigo200 = Color(0xFFC7D2FE);
  static const Color indigo300 = Color(0xFFA5B4FC);
  static const Color indigo400 = Color(0xFF818CF8);
  static const Color indigo500 = Color(0xFF6366F1);
  static const Color indigo600 = Color(0xFF4F46E5);
  static const Color indigo700 = Color(0xFF4338CA);
  static const Color indigo800 = Color(0xFF3730A3);
  static const Color indigo900 = Color(0xFF312E81);
  static const Color indigo950 = Color(0xFF1E1B4B);

  // ── Emerald (secondary) ────────────────────────────────────────────────────
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald200 = Color(0xFFA7F3D0);
  static const Color emerald300 = Color(0xFF6EE7B7);
  static const Color emerald400 = Color(0xFF34D399);
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald700 = Color(0xFF047857);
  static const Color emerald800 = Color(0xFF065F46);
  static const Color emerald900 = Color(0xFF064E3B);
  static const Color emerald950 = Color(0xFF022C22);

  // ── Saffron (accent) ───────────────────────────────────────────────────────
  static const Color saffron50 = Color(0xFFFFFBEB);
  static const Color saffron100 = Color(0xFFFEF3C7);
  static const Color saffron200 = Color(0xFFFDE68A);
  static const Color saffron300 = Color(0xFFFCD34D);
  static const Color saffron400 = Color(0xFFFBBF24);
  static const Color saffron500 = Color(0xFFF59E0B);
  static const Color saffron600 = Color(0xFFD97706);
  static const Color saffron700 = Color(0xFFB45309);
  static const Color saffron800 = Color(0xFF92400E);
  static const Color saffron900 = Color(0xFF78350F);

  // ── Slate (neutral) ────────────────────────────────────────────────────────
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);
  static const Color slate600 = Color(0xFF475569);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate950 = Color(0xFF020617);

  // ── Brand roles ────────────────────────────────────────────────────────────
  static const Color brandPrimary = indigo600;
  static const Color brandSecondary = emerald600;
  static const Color brandAccent = saffron500;
  static const Color brandSurface = slate50;

  /// Ink used for shadows in light mode (tinted, never pure black).
  static const Color shadowInk = slate900;

  // ── Light surfaces ─────────────────────────────────────────────────────────
  static const Color lightBackground = slate50;
  static const Color lightCardSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSunken = slate100;
  static const Color lightBorder = slate200;
  static const Color lightBorderStrong = slate300;

  // ── Dark surfaces (indigo-tinted night) ────────────────────────────────────
  static const Color darkBackground = Color(0xFF0B1020);
  static const Color darkSurfaceLowest = Color(0xFF080C18);
  static const Color darkSurface = Color(0xFF0B1020);
  static const Color darkSurfaceLow = Color(0xFF121833);
  static const Color darkSurfaceContainer = Color(0xFF161D3B);
  static const Color darkSurfaceHigh = Color(0xFF1A2142);
  static const Color darkSurfaceHighest = Color(0xFF222A50);
  static const Color darkBorder = Color(0xFF262E52);
  static const Color darkBorderStrong = Color(0xFF343D68);

  // Theme seed aliases
  static const Color primarySeed = brandPrimary;
  static const Color secondarySeed = brandSecondary;
  static const Color accentSeed = brandAccent;

  // Light semantic colors
  static const Color lightGoodStock = emerald700;
  static const Color lightGoodStockContainer = emerald100;
  static const Color lightPending = saffron700;
  static const Color lightPendingContainer = saffron100;
  static const Color lightDamaged = Color(0xFFB91C1C);
  static const Color lightDamagedContainer = Color(0xFFFEE2E2);
  static const Color lightAdvanceCredit = Color(0xFF0369A1);
  static const Color lightAdvanceCreditContainer = Color(0xFFE0F2FE);
  static const Color lightInfo = indigo700;
  static const Color lightInfoContainer = indigo50;

  // Dark semantic colors
  static const Color darkGoodStock = emerald300;
  static const Color darkGoodStockContainer = emerald900;
  static const Color darkPending = saffron300;
  static const Color darkPendingContainer = saffron900;
  static const Color darkDamaged = Color(0xFFFCA5A5);
  static const Color darkDamagedContainer = Color(0xFF7F1D1D);
  static const Color darkAdvanceCredit = Color(0xFF7DD3FC);
  static const Color darkAdvanceCreditContainer = Color(0xFF0C4A6E);
  static const Color darkInfo = indigo300;
  static const Color darkInfoContainer = indigo950;

  /// Text on the dark-mode error colour (deep red, red-950).
  static const Color darkOnError = Color(0xFF450A0A);

  /// Brand hero gradient: Indigo 700 → Indigo 500 → Emerald 600 (135°).
  static const LinearGradient heroGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigo700, indigo500, emerald600],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient heroGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigo900, indigo950, emerald900],
    stops: [0.0, 0.55, 1.0],
  );

  /// Text, icons and glass on top of [heroGradientLight] / [heroGradientDark]
  /// (and other deep brand surfaces such as the lock screen). Both gradients
  /// are dark, so this stays white in light and dark mode. Use it with an
  /// alpha for secondary text (0.85–0.9), glass fills (0.12–0.15) and
  /// borders (0.16–0.25).
  static const Color onHero = Color(0xFFFFFFFF);

  /// Secondary text on the hero gradient.
  static const Color onHeroMuted = Color(0xE0FFFFFF);

  /// Primary button gradient sheen.
  static const LinearGradient primaryButtonGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigo600, indigo700],
  );

  static const LinearGradient primaryButtonGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [indigo400, indigo500],
  );
}

/// Custom ThemeExtension exposing business-domain semantic colors cleanly
/// across Light and Dark themes.
@immutable
final class AppSemanticColors extends ThemeExtension<AppSemanticColors> {
  const AppSemanticColors({
    required this.goodStock,
    required this.goodStockContainer,
    required this.pending,
    required this.pendingContainer,
    required this.damaged,
    required this.damagedContainer,
    required this.advanceCredit,
    required this.advanceCreditContainer,
  });

  static const AppSemanticColors light = AppSemanticColors(
    goodStock: AppColors.lightGoodStock,
    goodStockContainer: AppColors.lightGoodStockContainer,
    pending: AppColors.lightPending,
    pendingContainer: AppColors.lightPendingContainer,
    damaged: AppColors.lightDamaged,
    damagedContainer: AppColors.lightDamagedContainer,
    advanceCredit: AppColors.lightAdvanceCredit,
    advanceCreditContainer: AppColors.lightAdvanceCreditContainer,
  );

  static const AppSemanticColors dark = AppSemanticColors(
    goodStock: AppColors.darkGoodStock,
    goodStockContainer: AppColors.darkGoodStockContainer,
    pending: AppColors.darkPending,
    pendingContainer: AppColors.darkPendingContainer,
    damaged: AppColors.darkDamaged,
    damagedContainer: AppColors.darkDamagedContainer,
    advanceCredit: AppColors.darkAdvanceCredit,
    advanceCreditContainer: AppColors.darkAdvanceCreditContainer,
  );

  final Color goodStock;
  final Color goodStockContainer;
  final Color pending;
  final Color pendingContainer;
  final Color damaged;
  final Color damagedContainer;
  final Color advanceCredit;
  final Color advanceCreditContainer;

  @override
  AppSemanticColors copyWith({
    Color? goodStock,
    Color? goodStockContainer,
    Color? pending,
    Color? pendingContainer,
    Color? damaged,
    Color? damagedContainer,
    Color? advanceCredit,
    Color? advanceCreditContainer,
  }) {
    return AppSemanticColors(
      goodStock: goodStock ?? this.goodStock,
      goodStockContainer: goodStockContainer ?? this.goodStockContainer,
      pending: pending ?? this.pending,
      pendingContainer: pendingContainer ?? this.pendingContainer,
      damaged: damaged ?? this.damaged,
      damagedContainer: damagedContainer ?? this.damagedContainer,
      advanceCredit: advanceCredit ?? this.advanceCredit,
      advanceCreditContainer:
          advanceCreditContainer ?? this.advanceCreditContainer,
    );
  }

  @override
  AppSemanticColors lerp(ThemeExtension<AppSemanticColors>? other, double t) {
    if (other is! AppSemanticColors) return this;
    return AppSemanticColors(
      goodStock: Color.lerp(goodStock, other.goodStock, t)!,
      goodStockContainer: Color.lerp(
        goodStockContainer,
        other.goodStockContainer,
        t,
      )!,
      pending: Color.lerp(pending, other.pending, t)!,
      pendingContainer: Color.lerp(
        pendingContainer,
        other.pendingContainer,
        t,
      )!,
      damaged: Color.lerp(damaged, other.damaged, t)!,
      damagedContainer: Color.lerp(
        damagedContainer,
        other.damagedContainer,
        t,
      )!,
      advanceCredit: Color.lerp(advanceCredit, other.advanceCredit, t)!,
      advanceCreditContainer: Color.lerp(
        advanceCreditContainer,
        other.advanceCreditContainer,
        t,
      )!,
    );
  }
}

/// Surface tokens for StitchFlow's Next-Gen adaptive glass & soft-elevation
/// system (`Classic Solid`, `Modern Frosted Glass`, `Liquid Aurora Glass`).
@immutable
final class AppSurfaceTokens extends ThemeExtension<AppSurfaceTokens> {
  const AppSurfaceTokens({
    required this.surfaceStyle,
    required this.preset,
    required this.glassFill,
    required this.glassFillStrong,
    required this.glassBorder,
    required this.glassHighlightTop,
    required this.glassHighlightBottom,
    required this.cardShadow,
    required this.ambientGlow,
    required this.subtleTint,
    required this.navGlassFill,
    required this.navGlassBorder,
    required this.inputGlassFill,
    required this.dialogGlassFill,
    required this.backdropTop,
    required this.backdropMid,
    required this.backdropBottom,
    required this.orbPrimary,
    required this.orbSecondary,
    required this.orbAccent,
  });

  /// Resolves surface tokens for [brightness], [style], and [preset].
  factory AppSurfaceTokens.resolve({
    required Brightness brightness,
    AppSurfaceStyle style = AppSurfaceStyle.modernGlass,
    AppThemePreset preset = AppThemePreset.indigoThread,
  }) {
    final isDark = brightness == Brightness.dark;
    final palette = AppPresetPalette.of(preset);
    final primaryAccent = palette.primaryFor(brightness);
    final orb1 = isDark ? palette.accentOrbDark : palette.accentOrbLight;

    if (style == AppSurfaceStyle.classicSolid) {
      if (isDark) {
        return AppSurfaceTokens(
          surfaceStyle: style,
          preset: preset,
          glassFill: AppColors.darkSurfaceLow,
          glassFillStrong: AppColors.darkSurfaceLow,
          glassBorder: AppColors.darkBorder,
          glassHighlightTop: AppColors.darkSurfaceLow,
          glassHighlightBottom: AppColors.darkSurfaceLow,
          cardShadow: Colors.black.withValues(alpha: 0.40),
          ambientGlow: primaryAccent.withValues(alpha: 0.10),
          subtleTint: primaryAccent.withValues(alpha: 0.08),
          navGlassFill: AppColors.darkSurfaceLow,
          navGlassBorder: AppColors.darkBorder,
          inputGlassFill: const Color(0xFF0E1429),
          dialogGlassFill: AppColors.darkSurfaceHigh,
          backdropTop: Color.alphaBlend(
            orb1.withValues(alpha: 0.06),
            AppColors.darkBackground,
          ),
          backdropMid: AppColors.darkBackground,
          backdropBottom: AppColors.darkBackground,
          orbPrimary: orb1.withValues(alpha: 0.06),
          orbSecondary: const Color(0x00000000),
          orbAccent: const Color(0x00000000),
        );
      }
      return AppSurfaceTokens(
        surfaceStyle: style,
        preset: preset,
        glassFill: AppColors.lightCardSurface,
        glassFillStrong: AppColors.lightCardSurface,
        glassBorder: AppColors.lightBorder,
        glassHighlightTop: AppColors.lightCardSurface,
        glassHighlightBottom: AppColors.lightCardSurface,
        cardShadow: AppColors.shadowInk.withValues(alpha: 0.08),
        ambientGlow: primaryAccent.withValues(alpha: 0.06),
        subtleTint: primaryAccent.withValues(alpha: 0.05),
        navGlassFill: AppColors.lightCardSurface,
        navGlassBorder: AppColors.lightBorder,
        inputGlassFill: AppColors.lightCardSurface,
        dialogGlassFill: AppColors.lightCardSurface,
        backdropTop: Color.alphaBlend(
          orb1.withValues(alpha: 0.04),
          AppColors.lightBackground,
        ),
        backdropMid: AppColors.lightBackground,
        backdropBottom: AppColors.lightBackground,
        orbPrimary: orb1.withValues(alpha: 0.04),
        orbSecondary: const Color(0x00000000),
        orbAccent: const Color(0x00000000),
      );
    }

    final isAurora = style == AppSurfaceStyle.liquidAurora;
    if (isDark) {
      final darkFill = AppColors.darkSurfaceLow.withValues(
        alpha: isAurora ? 0.72 : 0.78,
      );
      final darkFillStrong = AppColors.darkSurfaceContainer.withValues(
        alpha: isAurora ? 0.80 : 0.86,
      );
      return AppSurfaceTokens(
        surfaceStyle: style,
        preset: preset,
        glassFill: darkFill,
        glassFillStrong: darkFillStrong,
        glassBorder: Colors.white.withValues(alpha: isAurora ? 0.12 : 0.10),
        glassHighlightTop: darkFill,
        glassHighlightBottom: darkFill,
        cardShadow: Colors.black.withValues(alpha: 0.45),
        ambientGlow: primaryAccent.withValues(alpha: isAurora ? 0.12 : 0.08),
        subtleTint: primaryAccent.withValues(alpha: isAurora ? 0.10 : 0.08),
        navGlassFill: AppColors.darkSurfaceLow.withValues(
          alpha: isAurora ? 0.78 : 0.84,
        ),
        navGlassBorder: Colors.white.withValues(alpha: 0.10),
        inputGlassFill: const Color(0xFF0E1429).withValues(alpha: 0.84),
        dialogGlassFill: AppColors.darkSurfaceHigh.withValues(
          alpha: isAurora ? 0.84 : 0.90,
        ),
        backdropTop: isAurora
            ? Color.alphaBlend(
                primaryAccent.withValues(alpha: 0.06),
                AppColors.darkBackground,
              )
            : AppColors.darkBackground,
        backdropMid: AppColors.darkBackground,
        backdropBottom: AppColors.darkBackground,
        orbPrimary: isAurora
            ? primaryAccent.withValues(alpha: 0.07)
            : const Color(0x00000000),
        orbSecondary: const Color(0x00000000),
        orbAccent: const Color(0x00000000),
      );
    }

    final lightFill = Colors.white.withValues(alpha: isAurora ? 0.80 : 0.86);
    final lightFillStrong = Colors.white.withValues(
      alpha: isAurora ? 0.88 : 0.92,
    );
    return AppSurfaceTokens(
      surfaceStyle: style,
      preset: preset,
      glassFill: lightFill,
      glassFillStrong: lightFillStrong,
      glassBorder: AppColors.slate300.withValues(alpha: 0.60),
      glassHighlightTop: lightFill,
      glassHighlightBottom: lightFill,
      cardShadow: AppColors.shadowInk.withValues(alpha: 0.07),
      ambientGlow: primaryAccent.withValues(alpha: isAurora ? 0.08 : 0.05),
      subtleTint: primaryAccent.withValues(alpha: isAurora ? 0.07 : 0.05),
      navGlassFill: Colors.white.withValues(alpha: isAurora ? 0.82 : 0.88),
      navGlassBorder: AppColors.slate300.withValues(alpha: 0.65),
      inputGlassFill: Colors.white.withValues(alpha: 0.90),
      dialogGlassFill: Colors.white.withValues(alpha: isAurora ? 0.90 : 0.94),
      backdropTop: isAurora
          ? Color.alphaBlend(
              primaryAccent.withValues(alpha: 0.04),
              AppColors.lightBackground,
            )
          : AppColors.lightBackground,
      backdropMid: AppColors.lightBackground,
      backdropBottom: AppColors.lightBackground,
      orbPrimary: isAurora
          ? primaryAccent.withValues(alpha: 0.05)
          : const Color(0x00000000),
      orbSecondary: const Color(0x00000000),
      orbAccent: const Color(0x00000000),
    );
  }

  static final AppSurfaceTokens light = AppSurfaceTokens.resolve(
    brightness: Brightness.light,
  );

  static final AppSurfaceTokens dark = AppSurfaceTokens.resolve(
    brightness: Brightness.dark,
  );

  final AppSurfaceStyle surfaceStyle;
  final AppThemePreset preset;
  final Color glassFill;
  final Color glassFillStrong;
  final Color glassBorder;
  final Color glassHighlightTop;
  final Color glassHighlightBottom;
  final Color cardShadow;
  final Color ambientGlow;
  final Color subtleTint;
  final Color navGlassFill;
  final Color navGlassBorder;
  final Color inputGlassFill;
  final Color dialogGlassFill;
  final Color backdropTop;
  final Color backdropMid;
  final Color backdropBottom;
  final Color orbPrimary;
  final Color orbSecondary;
  final Color orbAccent;

  Color get surfaceFill => glassFill;
  Color get surfaceFillStrong => glassFillStrong;
  Color get surfaceBorder => glassBorder;
  Color get navBarFill => navGlassFill;
  Color get navBarBorder => navGlassBorder;
  Color get inputFill => inputGlassFill;
  Color get dialogFill => dialogGlassFill;

  /// Uniform glass gradient for focal panels (glare-free).
  LinearGradient get glassGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [glassHighlightTop, glassFill, glassHighlightBottom],
    stops: const [0.0, 0.45, 1.0],
  );

  /// Uniform lightweight glass gradient for dense list rows (glare-free).
  LinearGradient get lightweightGlassGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [glassFillStrong, glassFillStrong],
    stops: const [0.0, 1.0],
  );

  @override
  AppSurfaceTokens copyWith({
    AppSurfaceStyle? surfaceStyle,
    AppThemePreset? preset,
    Color? glassFill,
    Color? glassFillStrong,
    Color? glassBorder,
    Color? glassHighlightTop,
    Color? glassHighlightBottom,
    Color? cardShadow,
    Color? ambientGlow,
    Color? subtleTint,
    Color? navGlassFill,
    Color? navGlassBorder,
    Color? inputGlassFill,
    Color? dialogGlassFill,
    Color? backdropTop,
    Color? backdropMid,
    Color? backdropBottom,
    Color? orbPrimary,
    Color? orbSecondary,
    Color? orbAccent,
  }) {
    return AppSurfaceTokens(
      surfaceStyle: surfaceStyle ?? this.surfaceStyle,
      preset: preset ?? this.preset,
      glassFill: glassFill ?? this.glassFill,
      glassFillStrong: glassFillStrong ?? this.glassFillStrong,
      glassBorder: glassBorder ?? this.glassBorder,
      glassHighlightTop: glassHighlightTop ?? this.glassHighlightTop,
      glassHighlightBottom: glassHighlightBottom ?? this.glassHighlightBottom,
      cardShadow: cardShadow ?? this.cardShadow,
      ambientGlow: ambientGlow ?? this.ambientGlow,
      subtleTint: subtleTint ?? this.subtleTint,
      navGlassFill: navGlassFill ?? this.navGlassFill,
      navGlassBorder: navGlassBorder ?? this.navGlassBorder,
      inputGlassFill: inputGlassFill ?? this.inputGlassFill,
      dialogGlassFill: dialogGlassFill ?? this.dialogGlassFill,
      backdropTop: backdropTop ?? this.backdropTop,
      backdropMid: backdropMid ?? this.backdropMid,
      backdropBottom: backdropBottom ?? this.backdropBottom,
      orbPrimary: orbPrimary ?? this.orbPrimary,
      orbSecondary: orbSecondary ?? this.orbSecondary,
      orbAccent: orbAccent ?? this.orbAccent,
    );
  }

  @override
  AppSurfaceTokens lerp(ThemeExtension<AppSurfaceTokens>? other, double t) {
    if (other is! AppSurfaceTokens) return this;
    return AppSurfaceTokens(
      surfaceStyle: t < 0.5 ? surfaceStyle : other.surfaceStyle,
      preset: t < 0.5 ? preset : other.preset,
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassFillStrong: Color.lerp(glassFillStrong, other.glassFillStrong, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      glassHighlightTop: Color.lerp(
        glassHighlightTop,
        other.glassHighlightTop,
        t,
      )!,
      glassHighlightBottom: Color.lerp(
        glassHighlightBottom,
        other.glassHighlightBottom,
        t,
      )!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      ambientGlow: Color.lerp(ambientGlow, other.ambientGlow, t)!,
      subtleTint: Color.lerp(subtleTint, other.subtleTint, t)!,
      navGlassFill: Color.lerp(navGlassFill, other.navGlassFill, t)!,
      navGlassBorder: Color.lerp(navGlassBorder, other.navGlassBorder, t)!,
      inputGlassFill: Color.lerp(inputGlassFill, other.inputGlassFill, t)!,
      dialogGlassFill: Color.lerp(dialogGlassFill, other.dialogGlassFill, t)!,
      backdropTop: Color.lerp(backdropTop, other.backdropTop, t)!,
      backdropMid: Color.lerp(backdropMid, other.backdropMid, t)!,
      backdropBottom: Color.lerp(backdropBottom, other.backdropBottom, t)!,
      orbPrimary: Color.lerp(orbPrimary, other.orbPrimary, t)!,
      orbSecondary: Color.lerp(orbSecondary, other.orbSecondary, t)!,
      orbAccent: Color.lerp(orbAccent, other.orbAccent, t)!,
    );
  }
}

extension AppSemanticColorsX on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;

  AppSurfaceTokens get surfaceTokens =>
      Theme.of(this).extension<AppSurfaceTokens>() ??
      (Theme.of(this).brightness == Brightness.dark
          ? AppSurfaceTokens.dark
          : AppSurfaceTokens.light);

  AppPresetPalette get themePresetPalette =>
      AppPresetPalette.of(surfaceTokens.preset);
}
