import 'package:material_ui/material_ui.dart';

/// Centralized StitchFlow brand palette & semantic status tokens (WCAG AA compliant).
abstract final class AppColors {
  // Official StitchFlow brand colors (FINAL — never replace)
  static const Color brandNavy = Color(0xFF172B4D); // Deep Navy (Primary)
  static const Color brandTeal = Color(0xFF0D9488); // Teal (Secondary)
  static const Color brandAmber = Color(0xFFF4A340); // Amber (Accent)
  static const Color brandSoftWhite = Color(0xFFF5F7FA); // Soft White Surface

  // Refined supporting shades for gradients & dark elevation layers
  static const Color brandNavyDeep = Color(0xFF0F1F3A);
  static const Color brandNavyMid = Color(0xFF1F3B68);
  static const Color brandTealDeep = Color(0xFF0F766E);
  static const Color brandTealSoft = Color(0xFFCCFBF1);
  static const Color brandAmberSoft = Color(0xFFFEF3C7);

  static const Color darkSurface = Color(0xFF0A1220);
  static const Color darkSurfaceLow = Color(0xFF131F33);
  static const Color darkSurfaceHigh = Color(0xFF1B2B45);
  static const Color darkBorder = Color(0xFF2B3D5C);

  static const Color lightBorder = Color(0xFFD5E1EE);
  static const Color lightCardSurface = Color(0xFFFFFFFF);

  // Theme seed aliases
  static const Color primarySeed = brandNavy;
  static const Color secondarySeed = brandTeal;
  static const Color accentSeed = brandAmber;

  // Light semantic colors
  static const Color lightGoodStock = Color(0xFF15803D);
  static const Color lightGoodStockContainer = Color(0xFFDCFCE7);
  static const Color lightPending = Color(0xFFB45309);
  static const Color lightPendingContainer = Color(0xFFFEF3C7);
  static const Color lightDamaged = Color(0xFFB91C1C);
  static const Color lightDamagedContainer = Color(0xFFFEE2E2);
  static const Color lightAdvanceCredit = Color(0xFF0369A1);
  static const Color lightAdvanceCreditContainer = Color(0xFFE0F2FE);

  // Dark semantic colors
  static const Color darkGoodStock = Color(0xFF86EFAC);
  static const Color darkGoodStockContainer = Color(0xFF14532D);
  static const Color darkPending = Color(0xFFFCD34D);
  static const Color darkPendingContainer = Color(0xFF78350F);
  static const Color darkDamaged = Color(0xFFFCA5A5);
  static const Color darkDamagedContainer = Color(0xFF7F1D1D);
  static const Color darkAdvanceCredit = Color(0xFF7DD3FC);
  static const Color darkAdvanceCreditContainer = Color(0xFF0C4A6E);

  /// Refined brand hero gradient (Deep Navy -> Teal accent) with glass depth.
  static const LinearGradient heroGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xE6172B4D), Color(0xE61A4166), Color(0xE60F766E)],
  );

  static const LinearGradient heroGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xDE162C4E), Color(0xDE124255), Color(0xDE0D6660)],
  );

  /// Primary button gradient sheen.
  static const LinearGradient primaryButtonGradientLight = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandNavy, brandNavyMid],
  );

  static const LinearGradient primaryButtonGradientDark = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF14B8A6), brandTealDeep],
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

/// Premium V1.3 Glassmorphism surface tokens providing authentic frosted glass
/// translucency, specular highlight gradients, luminous hairline borders,
/// layered ambient backdrops, and soft depth across Light Glass & Dark Glass.
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
    glassFill: Colors.white.withValues(alpha: 0.62),
    glassFillStrong: Colors.white.withValues(alpha: 0.78),
    glassBorder: Colors.white.withValues(alpha: 0.82),
    glassHighlightTop: Colors.white.withValues(alpha: 0.78),
    glassHighlightBottom: Colors.white.withValues(alpha: 0.42),
    cardShadow: const Color(0xFF172B4D).withValues(alpha: 0.09),
    ambientGlow: const Color(0xFF0D9488).withValues(alpha: 0.08),
    subtleTint: const Color(0xFF0D9488).withValues(alpha: 0.06),
    navGlassFill: Colors.white.withValues(alpha: 0.72),
    navGlassBorder: Colors.white.withValues(alpha: 0.85),
    inputGlassFill: Colors.white.withValues(alpha: 0.66),
    dialogGlassFill: Colors.white.withValues(alpha: 0.82),
    backdropTop: const Color(0xFFDCE9F7),
    backdropMid: const Color(0xFFEFF5FB),
    backdropBottom: const Color(0xFFDAF2EE),
    orbPrimary: const Color(0xFF1D4ED8).withValues(alpha: 0.16),
    orbSecondary: const Color(0xFF0D9488).withValues(alpha: 0.22),
    orbAccent: const Color(0xFFF4A340).withValues(alpha: 0.18),
  );

  static final AppSurfaceTokens dark = AppSurfaceTokens(
    glassFill: const Color(0xFF17263F).withValues(alpha: 0.56),
    glassFillStrong: const Color(0xFF182842).withValues(alpha: 0.74),
    glassBorder: Colors.white.withValues(alpha: 0.18),
    glassHighlightTop: const Color(0xFF283F63).withValues(alpha: 0.62),
    glassHighlightBottom: const Color(0xFF0F1B30).withValues(alpha: 0.52),
    cardShadow: Colors.black.withValues(alpha: 0.36),
    ambientGlow: const Color(0xFF0D9488).withValues(alpha: 0.16),
    subtleTint: const Color(0xFF0D9488).withValues(alpha: 0.12),
    navGlassFill: const Color(0xFF0F1B30).withValues(alpha: 0.72),
    navGlassBorder: Colors.white.withValues(alpha: 0.14),
    inputGlassFill: const Color(0xFF122036).withValues(alpha: 0.62),
    dialogGlassFill: const Color(0xFF14233B).withValues(alpha: 0.82),
    backdropTop: const Color(0xFF070D19),
    backdropMid: const Color(0xFF0C172B),
    backdropBottom: const Color(0xFF091E29),
    orbPrimary: const Color(0xFF2563EB).withValues(alpha: 0.24),
    orbSecondary: const Color(0xFF0D9488).withValues(alpha: 0.28),
    orbAccent: const Color(0xFFF4A340).withValues(alpha: 0.16),
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

  /// Specular diagonal highlight gradient creating genuine glass depth.
  LinearGradient get glassGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [glassHighlightTop, glassFill, glassHighlightBottom],
    stops: const [0.0, 0.45, 1.0],
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
