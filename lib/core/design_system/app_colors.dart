import 'package:material_ui/material_ui.dart';

/// StitchFlow "Indigo Thread" color system (v1.4).
///
/// Built like Tailwind / Radix scales: every brand hue has a 50–950 ramp, and
/// UI code should reference *roles* (brandPrimary, surfaces, semantic tokens)
/// rather than raw steps. All text/background pairs target WCAG 2.2 AA.
///
/// - Primary  : Indigo 600  #4F46E5 — trust, textile indigo dye heritage
/// - Secondary: Emerald 600 #059669 — money-in, good stock, success
/// - Accent   : Saffron 500 #F59E0B — highlights, badges (fills/icons only,
///              never body text on white: contrast is below 3:1)
/// - Neutral  : Slate 50–950
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

/// Surface tokens for the v1.4 "soft elevation" system.
///
/// Field names are kept from the v1.3 glass system so existing widgets keep
/// compiling, but every value is now an opaque surface: solid cards on a calm
/// Slate (light) or indigo-night (dark) canvas, separated by 1px borders and
/// layered shadows from `AppShadows`. No translucency, no backdrop blur.
@immutable
final class AppSurfaceTokens extends ThemeExtension<AppSurfaceTokens> {
  const AppSurfaceTokens({
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

  static final AppSurfaceTokens light = AppSurfaceTokens(
    glassFill: AppColors.lightCardSurface,
    glassFillStrong: AppColors.lightCardSurface,
    glassBorder: AppColors.lightBorder,
    glassHighlightTop: AppColors.lightCardSurface,
    glassHighlightBottom: AppColors.lightCardSurface,
    cardShadow: AppColors.shadowInk.withValues(alpha: 0.08),
    ambientGlow: AppColors.indigo600.withValues(alpha: 0.06),
    subtleTint: AppColors.indigo600.withValues(alpha: 0.05),
    navGlassFill: AppColors.lightCardSurface,
    navGlassBorder: AppColors.lightBorder,
    inputGlassFill: AppColors.lightCardSurface,
    dialogGlassFill: AppColors.lightCardSurface,
    backdropTop: const Color(0xFFF4F6FE),
    backdropMid: AppColors.lightBackground,
    backdropBottom: AppColors.lightBackground,
    orbPrimary: AppColors.indigo500.withValues(alpha: 0.04),
    orbSecondary: const Color(0x00000000),
    orbAccent: const Color(0x00000000),
  );

  static final AppSurfaceTokens dark = AppSurfaceTokens(
    glassFill: AppColors.darkSurfaceLow,
    glassFillStrong: AppColors.darkSurfaceLow,
    glassBorder: AppColors.darkBorder,
    glassHighlightTop: AppColors.darkSurfaceLow,
    glassHighlightBottom: AppColors.darkSurfaceLow,
    cardShadow: Colors.black.withValues(alpha: 0.40),
    ambientGlow: AppColors.indigo400.withValues(alpha: 0.10),
    subtleTint: AppColors.indigo400.withValues(alpha: 0.08),
    navGlassFill: AppColors.darkSurfaceLow,
    navGlassBorder: AppColors.darkBorder,
    inputGlassFill: const Color(0xFF0E1429),
    dialogGlassFill: AppColors.darkSurfaceHigh,
    backdropTop: const Color(0xFF0E1330),
    backdropMid: AppColors.darkBackground,
    backdropBottom: AppColors.darkBackground,
    orbPrimary: AppColors.indigo500.withValues(alpha: 0.06),
    orbSecondary: const Color(0x00000000),
    orbAccent: const Color(0x00000000),
  );

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

  // Clean Indigo Thread semantic aliases (retiring legacy "glass" terminology)
  Color get surfaceFill => glassFill;
  Color get surfaceFillStrong => glassFillStrong;
  Color get surfaceBorder => glassBorder;
  Color get navBarFill => navGlassFill;
  Color get navBarBorder => navGlassBorder;
  Color get inputFill => inputGlassFill;
  Color get dialogFill => dialogGlassFill;

  /// Surface gradient (flat in v1.4: highlight stops equal the fill).
  LinearGradient get glassGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [glassHighlightTop, glassFill, glassHighlightBottom],
    stops: const [0.0, 0.45, 1.0],
  );

  /// Surface gradient for dense list rows (flat in v1.4).
  LinearGradient get lightweightGlassGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [glassHighlightTop, glassFillStrong, glassHighlightBottom],
    stops: const [0.0, 0.48, 1.0],
  );

  @override
  AppSurfaceTokens copyWith({
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
}
