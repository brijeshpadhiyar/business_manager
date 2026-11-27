import 'dart:math' as math;

import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/widgets/app_card.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

final class AppDataColumn {
  const AppDataColumn({
    required this.label,
    this.numeric = false,
    this.sortable = false,
    this.minWidthClass = AppWindowSizeClass.medium,
  });

  final String label;
  final bool numeric;

  /// Enables tap-to-sort on this header, either through the table's own
  /// `sortValueBuilder` or a page-managed `onSort`.
  final bool sortable;

  /// Minimum width class required for this column to display in tabular mode.
  /// Defaults to [AppWindowSizeClass.medium] (`>= 600dp`); set to
  /// [AppWindowSizeClass.expanded] (`>= 1024dp`) for lower-priority metadata
  /// columns that should hide cleanly on compact tablets.
  final AppWindowSizeClass minWidthClass;
}

/// Responsive data table v2:
/// - Renders compact scannable lightweight-glass cards on mobile (`< 600dp`)
/// - Renders a clean, accessible Material 3 `DataTable` on tablet/desktop
///   (`>= 600dp`) with optional column sorting, responsive column priority, and
///   built-in pagination (`10 / 25 / 50` rows per page).
/// - Uses available `LayoutBuilder` / `SliverLayoutBuilder` constraints rather
///   than raw screen width so it behaves accurately inside Desktop Sidebars.
final class AppDataTable<T> extends StatefulWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.items,
    required this.cellsBuilder,
    required this.mobileCardBuilder,
    this.onRowTap,
    this.itemKeyBuilder,
    this.sortColumnIndex,
    this.sortAscending = true,
    this.onSort,
    this.sortValueBuilder,
    this.enablePagination = false,
    this.initialPageSize = 25,
    this.pageSizeOptions = const [10, 25, 50],
  });

  final List<AppDataColumn> columns;
  final List<T> items;
  final List<Widget> Function(T item) cellsBuilder;
  final Widget Function(BuildContext context, T item) mobileCardBuilder;
  final ValueChanged<T>? onRowTap;
  final Key Function(T item)? itemKeyBuilder;
  final int? sortColumnIndex;
  final bool sortAscending;
  final void Function(int columnIndex, bool ascending)? onSort;

  /// Built-in sorting: the value to sort [item] by for the sortable column at
  /// [columnIndex] (numbers, strings, dates…; `null` sorts last). When given
  /// and [onSort] is not, the table keeps its own sort state, so pages get
  /// tap-to-sort headers without extra code.
  final Comparable<Object>? Function(T item, int columnIndex)? sortValueBuilder;
  final bool enablePagination;
  final int initialPageSize;
  final List<int> pageSizeOptions;

  /// Builds a sliver-native responsive table driven by available cross-axis
  /// layout constraints (`SliverLayoutBuilder`):
  /// - Lazy `SliverList.separated` cards on `< 600dp`
  /// - Paginated/sortable `AppDataTable` on `>= 600dp`
  static Widget buildSliver<T>(
    BuildContext context, {
    required List<AppDataColumn> columns,
    required List<T> items,
    required List<Widget> Function(T item) cellsBuilder,
    required Widget Function(BuildContext context, T item) mobileCardBuilder,
    ValueChanged<T>? onRowTap,
    Key Function(T item)? itemKeyBuilder,
    int? sortColumnIndex,
    bool sortAscending = true,
    void Function(int columnIndex, bool ascending)? onSort,
    Comparable<Object>? Function(T item, int columnIndex)? sortValueBuilder,
    bool enablePagination = false,
    int initialPageSize = 25,
    List<int> pageSizeOptions = const [10, 25, 50],
  }) {
    return SliverLayoutBuilder(
      builder: (ctx, constraints) {
        final sizeClass = AppBreakpoints.fromWidth(constraints.crossAxisExtent);
        if (sizeClass.isCompact) {
          return SliverList.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (itemCtx, i) {
              final item = items[i];
              return AppCard.listItem(
                key: itemKeyBuilder?.call(item),
                onTap: onRowTap != null ? () => onRowTap(item) : null,
                child: mobileCardBuilder(itemCtx, item),
              );
            },
          );
        }

        return SliverToBoxAdapter(
          child: AppDataTable<T>(
            columns: columns,
            items: items,
            cellsBuilder: cellsBuilder,
            mobileCardBuilder: mobileCardBuilder,
            onRowTap: onRowTap,
            itemKeyBuilder: itemKeyBuilder,
            sortColumnIndex: sortColumnIndex,
            sortAscending: sortAscending,
            onSort: onSort,
            sortValueBuilder: sortValueBuilder,
            enablePagination: enablePagination,
            initialPageSize: initialPageSize,
            pageSizeOptions: pageSizeOptions,
          ),
        );
      },
    );
  }

  @override
  State<AppDataTable<T>> createState() => _AppDataTableState<T>();
}

final class _AppDataTableState<T> extends State<AppDataTable<T>> {
  int _pageIndex = 0;
  late int _pageSize;

  // Built-in sort state (used only with `sortValueBuilder` and no `onSort`).
  int? _sortIndex;
  bool _sortAscending = true;

  bool get _selfSorting =>
      widget.onSort == null && widget.sortValueBuilder != null;

  int? get _effectiveSortIndex =>
      _selfSorting ? _sortIndex : widget.sortColumnIndex;

  bool get _effectiveSortAscending =>
      _selfSorting ? _sortAscending : widget.sortAscending;

  List<T> get _sortedItems {
    final index = _sortIndex;
    if (!_selfSorting || index == null) return widget.items;
    final valueOf = widget.sortValueBuilder!;
    final sorted = [...widget.items];
    sorted.sort((a, b) {
      final va = valueOf(a, index);
      final vb = valueOf(b, index);
      if (va == null && vb == null) return 0;
      if (va == null) return 1; // nulls last in both directions
      if (vb == null) return -1;
      final c = va is String && vb is String
          ? va.toLowerCase().compareTo(vb.toLowerCase())
          : va.compareTo(vb);
      return _sortAscending ? c : -c;
    });
    return sorted;
  }

  void Function(int, bool)? _sortHandlerFor(int origIdx) {
    if (!widget.columns[origIdx].sortable) return null;
    if (widget.onSort != null) return (_, asc) => widget.onSort!(origIdx, asc);
    if (!_selfSorting) return null;
    return (_, asc) => setState(() {
      _sortIndex = origIdx;
      _sortAscending = asc;
      _pageIndex = 0;
    });
  }

  @override
  void initState() {
    super.initState();
    _pageSize = widget.initialPageSize;
  }

  @override
  void didUpdateWidget(covariant AppDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      final maxPage = _totalPages - 1;
      if (_pageIndex > maxPage) {
        _pageIndex = maxPage < 0 ? 0 : maxPage;
      }
    }
  }

  int get _totalPages =>
      widget.items.isEmpty ? 1 : ((widget.items.length - 1) ~/ _pageSize) + 1;

  List<T> get _visibleItems {
    final items = _sortedItems;
    if (!widget.enablePagination || items.length <= _pageSize) {
      return items;
    }
    final start = (_pageIndex * _pageSize).clamp(0, items.length);
    final end = math.min(start + _pageSize, items.length);
    return items.sublist(start, end);
  }

  bool _isColumnVisible(AppDataColumn col, AppWindowSizeClass sizeClass) {
    if (sizeClass.isExpanded) return true;
    return col.minWidthClass != AppWindowSizeClass.expanded;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final pageItems = _visibleItems;
    final showPagination =
        widget.enablePagination &&
        widget.items.length > widget.pageSizeOptions.first;

    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass = AppBreakpoints.fromWidth(constraints.maxWidth);
        if (sizeClass.isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < pageItems.length; i++) ...[
                AppCard.listItem(
                  key: widget.itemKeyBuilder?.call(pageItems[i]),
                  onTap: widget.onRowTap != null
                      ? () => widget.onRowTap!(pageItems[i])
                      : null,
                  child: widget.mobileCardBuilder(context, pageItems[i]),
                ),
                if (i < pageItems.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
              if (showPagination) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildPaginationBar(context),
              ],
            ],
          );
        }

        // Resolve visible column indices according to responsive priority.
        final visibleIndices = <int>[
          for (var i = 0; i < widget.columns.length; i++)
            if (_isColumnVisible(widget.columns[i], sizeClass)) i,
        ];
        if (visibleIndices.isEmpty) {
          visibleIndices.addAll(
            List<int>.generate(widget.columns.length, (i) => i),
          );
        }

        final sortIndex = _effectiveSortIndex;
        final mappedSortIndex = sortIndex == null
            ? null
            : visibleIndices.indexOf(sortIndex);

        return AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: math.max(0, constraints.maxWidth - 2),
                  ),
                  child: DataTable(
                    showCheckboxColumn: false,
                    headingRowHeight: 46,
                    dataRowMinHeight: 48,
                    dataRowMaxHeight: 62,
                    columnSpacing: sizeClass.isExpanded
                        ? AppSpacing.xl
                        : AppSpacing.md,
                    sortColumnIndex:
                        mappedSortIndex != null && mappedSortIndex >= 0
                        ? mappedSortIndex
                        : null,
                    sortAscending: _effectiveSortAscending,
                    headingRowColor: WidgetStatePropertyAll(
                      colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.55,
                      ),
                    ),
                    headingTextStyle: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                    columns: [
                      for (final origIdx in visibleIndices)
                        DataColumn(
                          numeric: widget.columns[origIdx].numeric,
                          onSort: _sortHandlerFor(origIdx),
                          label: Text(widget.columns[origIdx].label),
                        ),
                    ],
                    rows: [
                      for (int i = 0; i < pageItems.length; i++)
                        () {
                          final allCells = widget.cellsBuilder(pageItems[i]);
                          return DataRow(
                            color: WidgetStatePropertyAll(
                              i.isOdd
                                  ? colorScheme.surfaceContainer.withValues(
                                      alpha: 0.45,
                                    )
                                  : Colors.transparent,
                            ),
                            cells: [
                              for (final origIdx in visibleIndices)
                                DataCell(
                                  origIdx < allCells.length
                                      ? allCells[origIdx]
                                      : const SizedBox.shrink(),
                                  onTap: widget.onRowTap != null
                                      ? () => widget.onRowTap!(pageItems[i])
                                      : null,
                                ),
                            ],
                          );
                        }(),
                    ],
                  ),
                ),
              ),
              if (showPagination) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: _buildPaginationBar(context),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaginationBar(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.items.length;
    final start = total == 0 ? 0 : (_pageIndex * _pageSize) + 1;
    final end = math.min((_pageIndex + 1) * _pageSize, total);

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        Text(
          '$start–$end / $total',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<int>(
              value: widget.pageSizeOptions.contains(_pageSize)
                  ? _pageSize
                  : widget.pageSizeOptions.first,
              underline: const SizedBox.shrink(),
              items: widget.pageSizeOptions
                  .map(
                    (size) => DropdownMenuItem<int>(
                      value: size,
                      child: Text(context.l10n.uxPerPage(size)),
                    ),
                  )
                  .toList(),
              onChanged: (next) {
                if (next == null) return;
                setState(() {
                  _pageSize = next;
                  _pageIndex = 0;
                });
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            Semantics(
              button: true,
              label: MaterialLocalizations.of(context).previousPageTooltip,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).previousPageTooltip,
                constraints: const BoxConstraints(
                  minWidth: AppSizing.touchTargetMin,
                  minHeight: AppSizing.touchTargetMin,
                ),
                icon: const Icon(AppIcons.chevronLeft),
                onPressed: _pageIndex > 0
                    ? () => setState(() => _pageIndex--)
                    : null,
              ),
            ),
            Text(
              '${_pageIndex + 1} / $_totalPages',
              style: theme.textTheme.labelMedium,
            ),
            Semantics(
              button: true,
              label: MaterialLocalizations.of(context).nextPageTooltip,
              child: IconButton(
                tooltip: MaterialLocalizations.of(context).nextPageTooltip,
                constraints: const BoxConstraints(
                  minWidth: AppSizing.touchTargetMin,
                  minHeight: AppSizing.touchTargetMin,
                ),
                icon: const Icon(AppIcons.chevronRight),
                onPressed: _pageIndex + 1 < _totalPages
                    ? () => setState(() => _pageIndex++)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
