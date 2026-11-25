import 'package:business_manager/core/design_system/app_spacing.dart';
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
    final actionWrap = Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
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
              const SizedBox(height: AppSpacing.xs),
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
            const SizedBox(width: AppSpacing.sm),
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
