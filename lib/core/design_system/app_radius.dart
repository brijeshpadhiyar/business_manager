import 'package:flutter/widgets.dart';

/// Centralized corner radius tokens (dp).
abstract final class AppRadius {
  static const double sm = 6;
  static const double md =
      8; // Default radius (cards, buttons, inputs, dialogs)
  static const double lg = 12; // Bottom sheets & modal containers
  static const double full = 999;

  static const BorderRadius smBorder = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdBorder = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgBorder = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius fullBorder = BorderRadius.all(
    Radius.circular(full),
  );
}
