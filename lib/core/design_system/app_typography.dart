import 'package:material_ui/material_ui.dart';

/// Compact Material 3 typography powered by offline-bundled `NotoSansGujarati`
/// for clean bilingual English & Gujarati rendering across all platforms.
abstract final class AppTypography {
  static const String fontFamily = 'NotoSansGujarati';

  static TextTheme buildTextTheme(ColorScheme colorScheme) {
    final base = TextTheme(
      headlineSmall: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      titleLarge: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      titleMedium: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      titleSmall: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      bodyLarge: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 15,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      bodyMedium: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.45,
      ),
      bodySmall: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.4,
      ),
      labelLarge: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.25,
      ),
      labelMedium: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
        height: 1.25,
      ),
      labelSmall: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 11,
        fontWeight: FontWeight.w500,
        height: 1.2,
      ),
    );

    return base.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
  }

  /// Applies tabular numerals so quantities, rates, and ledgers align vertically.
  static TextStyle tabular(TextStyle style) {
    return style.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }
}
