import 'package:material_ui/material_ui.dart';

/// Centralized StitchFlow brand palette & semantic status tokens (WCAG AA compliant).
abstract final class AppColors {
  // Official StitchFlow brand colors (FINAL)
  static const Color brandNavy = Color(0xFF172B4D); // Deep Navy (Primary)
  static const Color brandTeal = Color(0xFF0D9488); // Teal (Secondary)
  static const Color brandAmber = Color(0xFFF4A340); // Amber (Accent)
  static const Color brandSoftWhite = Color(0xFFF5F7FA); // Soft White Surface

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

extension AppSemanticColorsX on BuildContext {
  AppSemanticColors get semanticColors =>
      Theme.of(this).extension<AppSemanticColors>() ?? AppSemanticColors.light;
}
