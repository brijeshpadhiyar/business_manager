import 'package:business_manager/core/widgets/selection/app_select_style.dart';
import 'package:business_manager/core/widgets/selection/app_select_types.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:material_ui/material_ui.dart';

/// Searchable single-select field.
///
/// Use it for long or growing lists (workers, lots, processes, colours).
/// For short fixed lists (enums, statuses) [AppDropdown] is still fine.
///
/// Supply exactly one source:
/// * [items] — an in-memory list, filtered locally by label/subtitle.
/// * [loader] — an async, paged, server/DB-side search (see [AppSelectLoader]).
///
/// ```dart
/// AppSelect<WorkerOption>(
///   label: l10n.workerNameLabel,
///   loader: (q, offset, limit) => cubit.searchWorkers(q, offset, limit),
///   itemLabelBuilder: (w) => w.name,
///   itemSubtitleBuilder: (w) => w.phone,
///   compareFn: (a, b) => a.id == b.id,
///   value: state.worker,
///   onChanged: cubit.selectWorker,
/// )
/// ```
final class AppSelect<T> extends StatelessWidget {
  const AppSelect({
    super.key,
    this.fieldKey,
    required this.label,
    required this.itemLabelBuilder,
    this.items,
    this.loader,
    this.value,
    this.onChanged,
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
    this.clearable = false,
    this.presentation = AppSelectPresentation.auto,
    this.pageSize = AppSelectStyle.defaultPageSize,
  }) : assert(
         (items == null) != (loader == null),
         'Provide exactly one of `items` or `loader`.',
       );

  final GlobalKey<FormFieldState<T>>? fieldKey;
  final String label;
  final List<T>? items;
  final AppSelectLoader<T>? loader;
  final String Function(T item) itemLabelBuilder;
  final String? Function(T item)? itemSubtitleBuilder;
  final Widget? Function(T item)? itemLeadingBuilder;
  final bool Function(T item)? itemEnabled;

  /// Equality used to mark the selected row. Defaults to `==`. Provide it
  /// when [value] may be a different instance than the loaded items
  /// (e.g. compare ids).
  final bool Function(T a, T b)? compareFn;

  final T? value;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final String? errorText;
  final FormFieldValidator<T>? validator;
  final AutovalidateMode? autovalidateMode;
  final bool enabled;

  /// Show the search box. Defaults to `true` for [loader] and for lists
  /// longer than 7 items.
  final bool? searchable;

  /// Show a clear (×) button when a value is selected.
  final bool clearable;
  final AppSelectPresentation presentation;
  final int pageSize;

  bool get _isAsync => loader != null;

  bool get _showSearch => searchable ?? (_isAsync || items!.length > 7);

  bool _compare(T a, T b) => compareFn?.call(a, b) ?? a == b;

  Future<List<T>> _find(String filter, LoadProps? loadProps) async {
    if (_isAsync) {
      return loader!(
        filter.trim(),
        loadProps?.skip ?? 0,
        loadProps?.take ?? pageSize,
      );
    }
    return items!
        .where(
          (i) => AppSelectStyle.matches(
            i,
            filter,
            itemLabelBuilder,
            itemSubtitleBuilder,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final resolved = AppSelectStyle.resolve(context, presentation);
    final popup = _popupProps(context, resolved);
    final effectiveAutoValidate =
        autovalidateMode ??
        (validator != null
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled);

    Widget buildDropdown({
      FormFieldState<T>? fieldState,
    }) {
      return DropdownSearch<T>(
        key: ValueKey<Object?>((label, _isAsync, items?.length)),
        items: _find,
        selectedItem: value,
        compareFn: _compare,
        itemAsString: itemLabelBuilder,
        enabled: enabled && onChanged != null,
        onSelected: (v) {
          fieldState?.didChange(v);
          onChanged?.call(v);
        },
        validator: fieldState == null ? validator : null,
        autoValidateMode: fieldState == null
            ? (autovalidateMode ??
                  (validator != null ? AutovalidateMode.onUserInteraction : null))
            : null,
        decoratorProps: DropDownDecoratorProps(
          decoration: AppSelectStyle.fieldDecoration(
            label: label,
            hint: hint,
            errorText: fieldState?.errorText ?? errorText,
            enabled: enabled,
          ),
        ),
        suffixProps: DropdownSuffixProps(
          clearButtonProps: ClearButtonProps(
            isVisible: clearable && value != null && enabled,
          ),
        ),
        popupProps: popup,
      );
    }

    if (fieldKey == null) {
      return buildDropdown();
    }

    return FormField<T>(
      key: fieldKey,
      initialValue: value,
      validator: validator,
      autovalidateMode: effectiveAutoValidate,
      builder: (fieldState) => buildDropdown(fieldState: fieldState),
    );
  }

  PopupProps<T> _popupProps(
    BuildContext context,
    AppSelectPresentation resolved,
  ) {
    final constraints = AppSelectStyle.constraintsFor(context, resolved);
    final search = AppSelectStyle.searchField(context);
    final infinite = _isAsync ? AppSelectStyle.infiniteScroll(pageSize) : null;
    Widget itemBuilder(BuildContext c, T item, bool disabled, bool selected) =>
        AppSelectStyle.item<T>(
          context: c,
          item: item,
          isDisabled: disabled,
          isSelected: selected,
          labelOf: itemLabelBuilder,
          subtitleOf: itemSubtitleBuilder,
          leadingOf: itemLeadingBuilder,
        );
    bool disabledFn(T item) => !(itemEnabled?.call(item) ?? true);
    final title = AppSelectStyle.title(label, resolved);

    return switch (resolved) {
      AppSelectPresentation.bottomSheet => PopupProps<T>.modalBottomSheet(
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
      ),
      AppSelectPresentation.dialog => PopupProps<T>.dialog(
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
      ),
      _ => PopupProps<T>.menu(
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
      ),
    };
  }
}
