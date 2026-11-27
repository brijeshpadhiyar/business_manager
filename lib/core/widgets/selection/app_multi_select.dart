import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/widgets/app_button.dart';
import 'package:business_manager/core/widgets/app_chip.dart';
import 'package:business_manager/core/widgets/app_feedback.dart';
import 'package:business_manager/core/widgets/app_text.dart';
import 'package:business_manager/core/widgets/selection/app_select_style.dart';
import 'package:business_manager/core/widgets/selection/app_select_types.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:material_ui/material_ui.dart';

/// Searchable multi-select field. Selected values render as removable chips.
///
/// Same sources as [AppSelect]: an in-memory [items] list or an async, paged
/// [loader]. The popup has Select all (in-memory lists only), Clear and Done
/// actions; the change is committed on Done.
final class AppMultiSelect<T> extends StatefulWidget {
  const AppMultiSelect({
    super.key,
    required this.label,
    required this.itemLabelBuilder,
    required this.values,
    required this.onChanged,
    this.items,
    this.loader,
    this.compareFn,
    this.itemSubtitleBuilder,
    this.itemLeadingBuilder,
    this.itemEnabled,
    this.hint,
    this.errorText,
    this.validator,
    this.autovalidateMode,
    this.enabled = true,
    this.searchable,
    this.maxSelected,
    this.presentation = AppSelectPresentation.auto,
    this.pageSize = AppSelectStyle.defaultPageSize,
  }) : assert(
         (items == null) != (loader == null),
         'Provide exactly one of `items` or `loader`.',
       ),
       assert(maxSelected == null || maxSelected > 0);

  final String label;
  final List<T>? items;
  final AppSelectLoader<T>? loader;
  final String Function(T item) itemLabelBuilder;
  final String? Function(T item)? itemSubtitleBuilder;
  final Widget? Function(T item)? itemLeadingBuilder;
  final bool Function(T item)? itemEnabled;
  final bool Function(T a, T b)? compareFn;
  final List<T> values;
  final ValueChanged<List<T>>? onChanged;
  final String? hint;
  final String? errorText;
  final FormFieldValidator<List<T>>? validator;
  final AutovalidateMode? autovalidateMode;
  final bool enabled;
  final bool? searchable;

  /// Upper bound on how many values can be picked.
  final int? maxSelected;
  final AppSelectPresentation presentation;
  final int pageSize;

  @override
  State<AppMultiSelect<T>> createState() => _AppMultiSelectState<T>();
}

final class _AppMultiSelectState<T> extends State<AppMultiSelect<T>> {
  final _key = GlobalKey<DropdownSearchState<T>>();

  bool get _isAsync => widget.loader != null;

  bool get _showSearch =>
      widget.searchable ?? (_isAsync || widget.items!.length > 7);

  bool get _canEdit => widget.enabled && widget.onChanged != null;

  bool _compare(T a, T b) => widget.compareFn?.call(a, b) ?? a == b;

  Future<List<T>> _find(String filter, LoadProps? loadProps) async {
    if (_isAsync) {
      return widget.loader!(
        filter.trim(),
        loadProps?.skip ?? 0,
        loadProps?.take ?? widget.pageSize,
      );
    }
    return widget.items!
        .where(
          (i) => AppSelectStyle.matches(
            i,
            filter,
            widget.itemLabelBuilder,
            widget.itemSubtitleBuilder,
          ),
        )
        .toList();
  }

  void _remove(T item) {
    widget.onChanged?.call(
      widget.values.where((v) => !_compare(v, item)).toList(),
    );
  }

  void _onItemAdded(List<T> selected, T added) {
    final max = widget.maxSelected;
    if (max == null || selected.length <= max) return;
    _key.currentState?.popupDeselectItems([added]);
    AppFeedback.showWarning(context, context.l10n.selectMaxReached(max));
  }

  @override
  Widget build(BuildContext context) {
    final resolved = AppSelectStyle.resolve(context, widget.presentation);

    return DropdownSearch<T>.multiSelection(
      key: _key,
      items: _find,
      selectedItems: widget.values,
      compareFn: _compare,
      itemAsString: widget.itemLabelBuilder,
      enabled: _canEdit,
      onSelected: widget.onChanged,
      validator: widget.validator,
      autoValidateMode:
          widget.autovalidateMode ??
          (widget.validator != null
              ? AutovalidateMode.onUserInteraction
              : null),
      decoratorProps: DropDownDecoratorProps(
        decoration: AppSelectStyle.fieldDecoration(
          label: widget.label,
          hint: widget.hint,
          errorText: widget.errorText,
          enabled: widget.enabled,
        ),
      ),
      dropdownBuilder: (context, selected) => _SelectedChips<T>(
        selected: selected,
        labelOf: widget.itemLabelBuilder,
        onRemove: _canEdit ? _remove : null,
      ),
      popupProps: _popupProps(context, resolved),
    );
  }

  Widget _actions(BuildContext context, List<T> popupSelection) {
    final l10n = context.l10n;
    final state = _key.currentState;
    final count = popupSelection.length;
    final canSelectAll = !_isAsync && widget.maxSelected == null;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Expanded(
              child: AppText(
                l10n.selectSelectedCount(count),
                variant: AppTextVariant.bodySmall,
              ),
            ),
            if (canSelectAll)
              AppButton(
                label: l10n.selectSelectAll,
                variant: AppButtonVariant.text,
                onPressed: () => state?.popupSelectAllItems(),
              ),
            AppButton(
              label: l10n.selectClearAll,
              variant: AppButtonVariant.text,
              onPressed: () => state?.popupDeselectAllItems(),
            ),
            const SizedBox(width: AppSpacing.xs),
            AppButton(
              label: l10n.actionDone,
              onPressed: () => state?.popupOnValidate(),
            ),
          ],
        ),
      ),
    );
  }

  MultiSelectionPopupProps<T> _popupProps(
    BuildContext context,
    AppSelectPresentation resolved,
  ) {
    final constraints = AppSelectStyle.constraintsFor(context, resolved);
    final search = AppSelectStyle.searchField(context);
    final infinite = _isAsync
        ? AppSelectStyle.infiniteScroll(widget.pageSize)
        : null;
    Widget itemBuilder(BuildContext c, T item, bool disabled, bool selected) =>
        AppSelectStyle.item<T>(
          context: c,
          item: item,
          isDisabled: disabled,
          isSelected: selected,
          labelOf: widget.itemLabelBuilder,
          subtitleOf: widget.itemSubtitleBuilder,
          leadingOf: widget.itemLeadingBuilder,
          showCheck: false,
        );
    bool disabledFn(T item) => !(widget.itemEnabled?.call(item) ?? true);
    final title = AppSelectStyle.title(widget.label, resolved);

    return switch (resolved) {
      AppSelectPresentation.bottomSheet =>
        MultiSelectionPopupProps<T>.modalBottomSheet(
          modalBottomSheetProps: AppSelectStyle.sheet(context),
          title: title,
          showSearchBox: _showSearch,
          searchFieldProps: search,
          searchDelay: AppSelectStyle.searchDelay,
          disableFilter: true,
          cacheItems: false,
          showSelectedItems: true,
          itemBuilder: itemBuilder,
          disabledItemFn: disabledFn,
          emptyBuilder: AppSelectStyle.empty,
          errorBuilder: AppSelectStyle.error,
          loadingBuilder: AppSelectStyle.loading,
          infiniteScrollProps: infinite,
          constraints: constraints,
          validationBuilder: _actions,
          onItemAdded: _onItemAdded,
        ),
      AppSelectPresentation.dialog => MultiSelectionPopupProps<T>.dialog(
        dialogProps: AppSelectStyle.dialog(context),
        title: title,
        showSearchBox: _showSearch,
        searchFieldProps: search,
        searchDelay: AppSelectStyle.searchDelay,
        disableFilter: true,
        cacheItems: false,
        showSelectedItems: true,
        itemBuilder: itemBuilder,
        disabledItemFn: disabledFn,
        emptyBuilder: AppSelectStyle.empty,
        errorBuilder: AppSelectStyle.error,
        loadingBuilder: AppSelectStyle.loading,
        infiniteScrollProps: infinite,
        constraints: constraints,
        validationBuilder: _actions,
        onItemAdded: _onItemAdded,
      ),
      _ => MultiSelectionPopupProps<T>.menu(
        menuProps: AppSelectStyle.menu(context),
        fit: FlexFit.loose,
        showSearchBox: _showSearch,
        searchFieldProps: search,
        searchDelay: AppSelectStyle.searchDelay,
        disableFilter: true,
        cacheItems: false,
        showSelectedItems: true,
        itemBuilder: itemBuilder,
        disabledItemFn: disabledFn,
        emptyBuilder: AppSelectStyle.empty,
        errorBuilder: AppSelectStyle.error,
        loadingBuilder: AppSelectStyle.loading,
        infiniteScrollProps: infinite,
        constraints: constraints,
        validationBuilder: _actions,
        onItemAdded: _onItemAdded,
      ),
    };
  }
}

final class _SelectedChips<T> extends StatelessWidget {
  const _SelectedChips({
    required this.selected,
    required this.labelOf,
    required this.onRemove,
  });

  final List<T> selected;
  final String Function(T) labelOf;
  final ValueChanged<T>? onRemove;

  @override
  Widget build(BuildContext context) {
    if (selected.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final item in selected)
          AppChip.input(
            label: labelOf(item),
            onDeleted: onRemove == null ? null : () => onRemove!(item),
          ),
      ],
    );
  }
}
