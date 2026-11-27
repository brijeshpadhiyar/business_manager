import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:material_ui/material_ui.dart';

/// Visual/behavioural flavour of [AppChip].
enum AppChipVariant {
  /// One-of-many selection (replaces `ChoiceChip`).
  choice,

  /// Toggle filter (replaces `FilterChip`).
  filter,

  /// Tap action (replaces `ActionChip`).
  action,

  /// Removable value, e.g. a selected item (replaces `InputChip`).
  input,
}

/// The single chip used across the app. Wraps Material 3 chips with the app
/// radius, sizing and icon conventions.
final class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.variant = AppChipVariant.choice,
    this.selected = false,
    this.icon,
    this.avatar,
    this.onSelected,
    this.onPressed,
    this.onDeleted,
    this.tooltip,
    this.enabled = true,
    this.showCheckmark,
    this.dense = false,
  });

  /// Tap action chip.
  const AppChip.action({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.avatar,
    this.tooltip,
    this.enabled = true,
    this.dense = false,
  }) : variant = AppChipVariant.action,
       selected = false,
       onSelected = null,
       onDeleted = null,
       showCheckmark = null;

  /// Toggle filter chip.
  const AppChip.filter({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.avatar,
    this.tooltip,
    this.enabled = true,
    this.showCheckmark,
    this.dense = false,
  }) : variant = AppChipVariant.filter,
       onPressed = null,
       onDeleted = null;

  /// Removable value chip.
  const AppChip.input({
    super.key,
    required this.label,
    this.onDeleted,
    this.onPressed,
    this.icon,
    this.avatar,
    this.tooltip,
    this.enabled = true,
    this.dense = false,
  }) : variant = AppChipVariant.input,
       selected = false,
       onSelected = null,
       showCheckmark = null;

  final String label;
  final AppChipVariant variant;
  final bool selected;
  final IconData? icon;

  /// Custom leading widget; takes precedence over [icon].
  final Widget? avatar;
  final ValueChanged<bool>? onSelected;
  final VoidCallback? onPressed;
  final VoidCallback? onDeleted;
  final String? tooltip;
  final bool enabled;

  /// Defaults to the Material behaviour (checkmark shown when selected).
  final bool? showCheckmark;

  /// Compact visual density for tight rows.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final leading =
        avatar ?? (icon != null ? Icon(icon, size: AppSizing.iconSm) : null);
    final text = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    const shape = RoundedRectangleBorder(borderRadius: AppRadius.fullBorder);
    const padding = EdgeInsets.symmetric(horizontal: AppSpacing.xs);
    final density = dense ? VisualDensity.compact : null;

    return switch (variant) {
      AppChipVariant.choice => ChoiceChip(
        label: text,
        avatar: leading,
        selected: selected,
        onSelected: enabled ? onSelected : null,
        tooltip: tooltip,
        shape: shape,
        labelPadding: padding,
        visualDensity: density,
        showCheckmark: showCheckmark,
      ),
      AppChipVariant.filter => FilterChip(
        label: text,
        avatar: leading,
        selected: selected,
        onSelected: enabled ? onSelected : null,
        tooltip: tooltip,
        shape: shape,
        labelPadding: padding,
        visualDensity: density,
        showCheckmark: showCheckmark,
      ),
      AppChipVariant.action => ActionChip(
        label: text,
        avatar: leading,
        onPressed: enabled ? onPressed : null,
        tooltip: tooltip,
        shape: shape,
        labelPadding: padding,
        visualDensity: density,
      ),
      AppChipVariant.input => InputChip(
        label: text,
        avatar: leading,
        onPressed: enabled ? onPressed : null,
        onDeleted: enabled ? onDeleted : null,
        tooltip: tooltip,
        shape: shape,
        labelPadding: padding,
        visualDensity: density,
        isEnabled: enabled,
      ),
    };
  }
}

/// A wrapping (or horizontally scrolling) group of selectable chips.
///
/// Single selection: pass [value] + [onChanged].
/// Multi selection: use [AppChipGroup.multi] with [values] + [onChangedMulti].
final class AppChipGroup<T> extends StatelessWidget {
  const AppChipGroup({
    super.key,
    required this.items,
    required this.itemLabelBuilder,
    required this.value,
    required this.onChanged,
    this.itemIconBuilder,
    this.scrollable = false,
    this.spacing = AppSpacing.xs,
    this.enabled = true,
  }) : values = const [],
       onChangedMulti = null,
       multi = false;

  const AppChipGroup.multi({
    super.key,
    required this.items,
    required this.itemLabelBuilder,
    required this.values,
    required this.onChangedMulti,
    this.itemIconBuilder,
    this.scrollable = false,
    this.spacing = AppSpacing.xs,
    this.enabled = true,
  }) : value = null,
       onChanged = null,
       multi = true;

  final List<T> items;
  final String Function(T item) itemLabelBuilder;
  final IconData? Function(T item)? itemIconBuilder;
  final T? value;
  final ValueChanged<T>? onChanged;
  final List<T> values;
  final ValueChanged<List<T>>? onChangedMulti;
  final bool multi;

  /// Single horizontal scrolling row instead of wrapping lines.
  final bool scrollable;
  final double spacing;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final chips = [
      for (final item in items)
        multi
            ? AppChip.filter(
                label: itemLabelBuilder(item),
                icon: itemIconBuilder?.call(item),
                selected: values.contains(item),
                enabled: enabled && onChangedMulti != null,
                onSelected: (sel) {
                  final next = [...values];
                  sel ? next.add(item) : next.remove(item);
                  onChangedMulti?.call(next);
                },
              )
            : AppChip(
                label: itemLabelBuilder(item),
                icon: itemIconBuilder?.call(item),
                selected: value == item,
                enabled: enabled && onChanged != null,
                onSelected: (_) => onChanged?.call(item),
              ),
    ];

    if (scrollable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) SizedBox(width: spacing),
              chips[i],
            ],
          ],
        ),
      );
    }
    return Wrap(spacing: spacing, runSpacing: spacing, children: chips);
  }
}
