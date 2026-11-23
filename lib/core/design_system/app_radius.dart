import 'package:flutter/widgets.dart';

/// Centralized corner radius tokens (dp).
abstract final class AppRadius {
  static const double sm = 6;
  static const double md =
      10; // Default radius (buttons, inputs, dialogs, compact cards)
  static const double lg = 14; // Cards, bottom sheets & glass containers
  static const double xl = 18; // Hero banners & featured dashboard surfaces
  static const double full = 999;

  static const BorderRadius smBorder = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdBorder = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgBorder = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlBorder = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius fullBorder = BorderRadius.all(
    Radius.circular(full),
  );
}
