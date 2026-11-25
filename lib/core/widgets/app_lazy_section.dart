import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// A long list section for detail pages that stays fast with any amount of
/// data.
///
/// Only the first [initialCount] rows are built. The user can tap
/// "Show N more" to reveal [pageSize] more rows at a time, and "Show less" to
/// collapse again. Rows are built lazily through [itemBuilder], so a section
/// with thousands of records never builds them all in one frame.
///
/// Use [AppLazySection] inside a normal `Column`/`ListView`, or
/// [AppLazySection.sliver] inside a `CustomScrollView`.
final class AppLazySection<T> extends StatefulWidget {
  const AppLazySection({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.initialCount = 10,
    this.pageSize = 20,
    this.separator,
  }) : _sliver = false;

  const AppLazySection.sliver({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.initialCount = 10,
    this.pageSize = 20,
    this.separator,
  }) : _sliver = true;

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int initialCount;
  final int pageSize;
  final Widget? separator;
  final bool _sliver;

  @override
  State<AppLazySection<T>> createState() => _AppLazySectionState<T>();
}

final class _AppLazySectionState<T> extends State<AppLazySection<T>> {
  late int _visible = widget.initialCount;

  int get _shown => _visible.clamp(0, widget.items.length);

  void _showMore() => setState(() => _visible += widget.pageSize);

  void _showLess() => setState(() => _visible = widget.initialCount);

  Widget _row(BuildContext context, int index) {
    final row = widget.itemBuilder(context, widget.items[index], index);
    final separator = widget.separator;
    if (separator == null || index == _shown - 1) return row;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [row, separator],
    );
  }

  Widget? _footer(BuildContext context) {
    final remaining = widget.items.length - _shown;
    final canCollapse =
        _shown > widget.initialCount &&
        widget.items.length > widget.initialCount;
    if (remaining <= 0 && !canCollapse) return null;
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpacing.sm,
        children: [
          if (remaining > 0)
            TextButton.icon(
              onPressed: _showMore,
              icon: const Icon(AppIcons.expandMore),
              label: Text(
                l10n.uxShowMore(
                  remaining < widget.pageSize ? remaining : widget.pageSize,
                ),
              ),
            ),
          if (canCollapse)
            TextButton.icon(
              onPressed: _showLess,
              icon: const Icon(AppIcons.expandLess),
              label: Text(l10n.uxShowLess),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final footer = _footer(context);
    if (widget._sliver) {
      return SliverMainAxisGroup(
        slivers: [
          SliverList.builder(itemCount: _shown, itemBuilder: _row),
          if (footer != null) SliverToBoxAdapter(child: footer),
        ],
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [for (var i = 0; i < _shown; i++) _row(context, i), ?footer],
    );
  }
}
