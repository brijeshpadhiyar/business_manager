import 'package:material_ui/material_ui.dart';

/// The app's single divider. Uses the theme's `dividerTheme` unless a [color]
/// is given.
final class AppDivider extends StatelessWidget {
  const AppDivider({
    super.key,
    this.height,
    this.indent,
    this.endIndent,
    this.color,
    this.thickness,
  }) : vertical = false;

  /// Vertical divider for rows; [height] is then the horizontal space taken.
  const AppDivider.vertical({
    super.key,
    this.height,
    this.indent,
    this.endIndent,
    this.color,
    this.thickness,
  }) : vertical = true;

  /// Total extent along the cross axis (space taken, not line thickness).
  final double? height;
  final double? indent;
  final double? endIndent;
  final Color? color;
  final double? thickness;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    if (vertical) {
      return VerticalDivider(
        width: height,
        indent: indent,
        endIndent: endIndent,
        color: color,
        thickness: thickness,
      );
    }
    return Divider(
      height: height,
      indent: indent,
      endIndent: endIndent,
      color: color,
      thickness: thickness,
    );
  }
}
