import 'package:material_ui/material_ui.dart';

/// Anchor rectangle for the system share sheet.
///
/// iPad shows sharing as a popover and throws if no anchor is given; phones
/// and other platforms ignore it. Centre of the current window, 1x1.
Rect defaultShareOrigin() {
  final view = WidgetsBinding.instance.platformDispatcher.views.first;
  final size = view.physicalSize / view.devicePixelRatio;
  return Rect.fromLTWH(size.width / 2, size.height / 2, 1, 1);
}
