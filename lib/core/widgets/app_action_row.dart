import 'package:business_manager/core/design_system/app_density.dart';
import 'package:material_ui/material_ui.dart';

/// A heading or text with one or more buttons beside it, that never
/// overflows.
///
/// On very narrow space (under [breakpoint]) the actions move under the
/// text, aligned to the end. Otherwise they sit to the right, capped at half
/// the width, so a long (e.g. Gujarati) button label wraps instead of pushing
/// past the screen edge, while the text keeps all remaining space.
final class AppActionRow extends StatelessWidget {
  const AppActionRow({
    super.key,
    required this.content,
    required this.actions,
    this.breakpoint = 260,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final Widget content;
  final List<Widget> actions;
  final double breakpoint;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return content;
    final d = context.density;
    final actionWrap = Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: d.xs,
      runSpacing: d.xs,
      children: actions,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              content,
              SizedBox(height: d.xs),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: actionWrap,
              ),
            ],
          );
        }
        return Row(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            Expanded(child: content),
            SizedBox(width: d.sm),
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth / 2),
              child: actionWrap,
            ),
          ],
        );
      },
    );
  }
}
