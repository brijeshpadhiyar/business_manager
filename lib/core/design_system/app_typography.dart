import 'package:material_ui/material_ui.dart';

/// Material 3 typography powered by offline-bundled `NotoSansGujarati` with
/// calibrated line-heights (`>= 1.38`) and even leading distribution so
/// Gujarati vowel signs (matras), conjuncts, and descenders render cleanly
/// without vertical clipping across Android, iOS, Web, and Desktop.
abstract final class AppTypography {
  static const String fontFamily = 'NotoSansGujarati';
  static const List<String> fontFamilyFallback = <String>[
    'NotoSansGujarati',
    'Roboto',
    'sans-serif',
  ];

  static TextStyle _style({
    required double fontSize,
    required FontWeight fontWeight,
    required double height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: fontFamily,
      fontFamilyFallback: fontFamilyFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      leadingDistribution: TextLeadingDistribution.even,
    );
  }

  static TextTheme buildTextTheme(ColorScheme colorScheme) {
    final base = TextTheme(
      displayLarge: _style(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        height: 1.32,
      ),
      displayMedium: _style(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
      displaySmall: _style(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.36,
      ),
      headlineLarge: _style(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.38,
      ),
      headlineMedium: _style(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.38,
      ),
      headlineSmall: _style(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.4,
      ),
      titleLarge: _style(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.42,
      ),
      titleMedium: _style(
        fontSize: 15.5,
        fontWeight: FontWeight.w600,
        height: 1.42,
      ),
      titleSmall: _style(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        height: 1.42,
      ),
      bodyLarge: _style(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5),
      bodyMedium: _style(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: _style(
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        height: 1.48,
      ),
      labelLarge: _style(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        height: 1.4,
      ),
      labelMedium: _style(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      labelSmall: _style(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        height: 1.38,
      ),
    );

    return base.apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
  }

  /// Applies tabular numerals so quantities, rates, and ledgers align vertically.
  static TextStyle tabular(TextStyle style) {
    return style.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  }
}
