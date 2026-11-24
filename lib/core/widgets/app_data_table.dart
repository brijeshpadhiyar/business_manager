import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/widgets/app_card.dart';
import 'package:material_ui/material_ui.dart';

final class AppDataColumn {
  const AppDataColumn({required this.label, this.numeric = false});

  final String label;
  final bool numeric;
}

/// Responsive data table: renders compact scannable lightweight-glass cards on
/// mobile (`< 600dp`) and a horizontally scrollable Material 3 `DataTable` with
/// subtle header tint and alternating row depth on tablet/desktop (`>= 600dp`).
final class AppDataTable<T> extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.items,
    required this.cellsBuilder,
    required this.mobileCardBuilder,
    this.onRowTap,
    this.itemKeyBuilder,
  });

  final List<AppDataColumn> columns;
  final List<T> items;
  final List<Widget> Function(T item) cellsBuilder;
  final Widget Function(BuildContext context, T item) mobileCardBuilder;
  final ValueChanged<T>? onRowTap;
  final Key Function(T item)? itemKeyBuilder;

  /// Builds a sliver-native responsive table: lazy `SliverList.separated` with
  /// lightweight glass cards on compact mobile viewports (`< 600dp`) and a
  /// scrollable `DataTable` inside `SliverToBoxAdapter` on tablet/desktop.
  static Widget buildSliver<T>(
    BuildContext context, {
    required List<AppDataColumn> columns,
    required List<T> items,
    required List<Widget> Function(T item) cellsBuilder,
    required Widget Function(BuildContext context, T item) mobileCardBuilder,
    ValueChanged<T>? onRowTap,
    Key Function(T item)? itemKeyBuilder,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final sizeClass = AppBreakpoints.fromWidth(width);
    if (sizeClass.isCompact) {
      return SliverList.separated(
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (ctx, i) {
          final item = items[i];
          return AppCard.listItem(
            key: itemKeyBuilder?.call(item),
            onTap: onRowTap != null ? () => onRowTap(item) : null,
            child: mobileCardBuilder(ctx, item),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass = AppBreakpoints.fromWidth(constraints.maxWidth);
        if (sizeClass.isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < items.length; i++) ...[
                AppCard.listItem(
                  key: itemKeyBuilder?.call(items[i]),
                  onTap: onRowTap != null ? () => onRowTap!(items[i]) : null,
                  child: mobileCardBuilder(context, items[i]),
                ),
                if (i < items.length - 1) const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        }

        return AppCard(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth - 2),
              child: DataTable(
                headingRowHeight: 46,
                dataRowMinHeight: 46,
                dataRowMaxHeight: 60,
                columnSpacing: AppSpacing.xl,
                headingRowColor: WidgetStatePropertyAll(
                  colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
                ),
                headingTextStyle: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
                columns: columns
                    .map(
                      (col) => DataColumn(
                        numeric: col.numeric,
                        label: Text(col.label),
                      ),
                    )
                    .toList(),
                rows: [
                  for (int i = 0; i < items.length; i++)
                    DataRow(
                      color: WidgetStatePropertyAll(
                        i.isOdd
                            ? colorScheme.surfaceContainer.withValues(
                                alpha: 0.45,
                              )
                            : Colors.transparent,
                      ),
                      onSelectChanged: onRowTap != null
                          ? (_) => onRowTap!(items[i])
                          : null,
                      cells: cellsBuilder(items[i])
                          .map((cell) => DataCell(cell))
                          .toList(),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
