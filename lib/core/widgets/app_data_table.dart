import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/widgets/app_card.dart';
import 'package:material_ui/material_ui.dart';

final class AppDataColumn {
  const AppDataColumn({required this.label, this.numeric = false});

  final String label;
  final bool numeric;
}

/// Responsive data table: renders compact scannable cards on mobile (`< 600dp`)
/// and a horizontally scrollable Material 3 `DataTable` on tablet/desktop (`>= 600dp`).
final class AppDataTable<T> extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.items,
    required this.cellsBuilder,
    required this.mobileCardBuilder,
    this.onRowTap,
  });

  final List<AppDataColumn> columns;
  final List<T> items;
  final List<Widget> Function(T item) cellsBuilder;
  final Widget Function(BuildContext context, T item) mobileCardBuilder;
  final ValueChanged<T>? onRowTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sizeClass = AppBreakpoints.fromWidth(constraints.maxWidth);
        if (sizeClass.isCompact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < items.length; i++) ...[
                AppCard(
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
            child: DataTable(
              headingRowHeight: 44,
              dataRowMinHeight: 44,
              dataRowMaxHeight: 56,
              columnSpacing: AppSpacing.xl,
              columns: columns
                  .map(
                    (col) => DataColumn(
                      numeric: col.numeric,
                      label: Text(col.label),
                    ),
                  )
                  .toList(),
              rows: items
                  .map(
                    (item) => DataRow(
                      onSelectChanged: onRowTap != null
                          ? (_) => onRowTap!(item)
                          : null,
                      cells: cellsBuilder(item)
                          .map((cell) => DataCell(cell))
                          .toList(),
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}
