import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_density.dart';
import 'package:material_ui/material_ui.dart';

/// Responsive 1-column (mobile `< 600dp`) / 2-column (tablet & desktop) form
/// row that uses available `LayoutBuilder` constraints rather than full screen
/// width so it never overflows inside dialogs or sidebars.
final class AppFormRow extends StatelessWidget {
  const AppFormRow({
    super.key,
    required this.children,
    this.spacing,
    this.breakpoint = AppBreakpoints.tabletMinWidth,
  });

  final List<Widget> children;
  final double? spacing;
  final double breakpoint;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    if (children.length == 1) return children.first;
    final resolvedSpacing = spacing ?? context.density.md;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= breakpoint;
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: resolvedSpacing),
                children[i],
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) SizedBox(width: resolvedSpacing),
              Expanded(child: children[i]),
            ],
          ],
        );
      },
    );
  }
}
