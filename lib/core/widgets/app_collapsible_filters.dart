import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_density.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Filter controls that stay out of the way on phones.
///
/// On compact screens (under 600dp) the [child] filters are hidden behind a
/// "Filters" toggle (showing how many are active), so the list or feed starts
/// near the top of the screen. On tablet and desktop the filters are always
/// shown.
final class AppCollapsibleFilters extends StatefulWidget {
  const AppCollapsibleFilters({
    super.key,
    required this.child,
    this.activeCount = 0,
    this.label,
    this.icon,
  });

  /// Toggle text; defaults to "Filters" / "Filters (n)".
  final String? label;

  /// Toggle icon when collapsed; defaults to a filter icon.
  final IconData? icon;

  final Widget child;

  /// How many filters are set; shown on the toggle.
  final int activeCount;

  @override
  State<AppCollapsibleFilters> createState() => _AppCollapsibleFiltersState();
}

final class _AppCollapsibleFiltersState extends State<AppCollapsibleFilters> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final compact = AppBreakpoints.fromWidth(MediaQuery.sizeOf(context).width)
        .isCompact;
    if (!compact) return widget.child;
    final d = context.density;

    final l10n = context.l10n;
    final label =
        widget.label ??
        (widget.activeCount > 0
            ? l10n.uxFiltersActive(widget.activeCount)
            : l10n.uxFilters);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilterChip(
            visualDensity: d.isCompact ? VisualDensity.compact : null,
            materialTapTargetSize: d.isCompact
                ? MaterialTapTargetSize.shrinkWrap
                : null,
            avatar: Icon(
              _expanded
                  ? AppIcons.expandLess
                  : (widget.icon ?? AppIcons.filter),
              size: d.iconSm + 2,
            ),
            label: Text(label),
            selected: _expanded || widget.activeCount > 0,
            onSelected: (_) => setState(() => _expanded = !_expanded),
          ),
        ),
        AppExpandableSection(
          expanded: _expanded,
          child: Padding(
            padding: EdgeInsets.only(top: d.sm),
            child: widget.child,
          ),
        ),
      ],
    );
  }
}
