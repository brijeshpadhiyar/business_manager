import 'package:flutter/widgets.dart';

/// Centralized spacing tokens (dp) for compact, comfortable business layouts.
abstract final class AppSpacing {
  static const double xxs = 2; // Hairline gap (label ↔ value)
  static const double xs = 4;
  static const double xsm = 6; // Tight row gap in dense lists
  static const double sm = 8; // Small spacing & standard gap
  static const double md = 12; // Card padding & compact section gap
  static const double lg = 16; // Screen horizontal padding
  static const double xl = 24;

  // Component padding used by the theme.
  /// Vertical padding inside filled / outlined / text buttons.
  static const double buttonVertical = 10;

  /// Vertical padding inside text fields (keeps a 48dp field).
  static const double inputVertical = 14;

  /// Horizontal padding inside text fields.
  static const double inputHorizontal = md + 2;

  /// Padding inside chips.
  static const EdgeInsets chipPadding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: xsm,
  );

  /// Padding inside segmented buttons.
  static const EdgeInsets segmentPadding = EdgeInsets.symmetric(
    horizontal: 10,
    vertical: sm,
  );

  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(
    horizontal: lg,
  );
  static const EdgeInsets screenAll = EdgeInsets.all(lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
}
