import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';

/// App-wide scroll behaviour so lists feel native on every platform.
///
/// * Mouse, trackpad and stylus can drag-scroll lists (web and desktop
///   users expect this on touch screens and laptops).
/// * iOS and macOS keep the bouncing physics; everything else clamps.
/// * Desktop and web show a scrollbar; mobile keeps the overlay default.
final class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return switch (getPlatform(context)) {
      TargetPlatform.iOS || TargetPlatform.macOS => const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      _ => const ClampingScrollPhysics(),
    };
  }
}
