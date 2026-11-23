import 'package:flutter/widgets.dart';

/// Centralized spacing tokens (dp) for compact, comfortable business layouts.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8; // Small spacing & standard gap
  static const double md = 12; // Card padding & compact section gap
  static const double lg = 16; // Screen horizontal padding
  static const double xl = 24;

  static const EdgeInsets screenHorizontal = EdgeInsets.symmetric(
    horizontal: lg,
  );
  static const EdgeInsets screenAll = EdgeInsets.all(lg);
  static const EdgeInsets cardPadding = EdgeInsets.all(md);
}
