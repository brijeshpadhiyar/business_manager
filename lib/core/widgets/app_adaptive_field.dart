import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_density.dart';
import 'package:material_ui/material_ui.dart';

/// Sizes a filter or form control for the current window.
///
/// On compact screens (phones) the field takes the full row so it is easy to
/// tap and read. On tablet and desktop it is capped at [maxWidth] so several
/// filters can sit side by side inside a `Wrap`.
final class AppAdaptiveField extends StatelessWidget {
  const AppAdaptiveField({super.key, required this.child, this.maxWidth = 220});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final sizeClass = AppBreakpoints.fromWidth(
      MediaQuery.sizeOf(context).width,
    );
    if (sizeClass.isCompact) {
      return SizedBox(width: double.infinity, child: child);
    }
    final effectiveMax = context.isCompactDensity
        ? (maxWidth * 0.82).clamp(150.0, maxWidth)
        : maxWidth;
    return SizedBox(width: effectiveMax, child: child);
  }
}
