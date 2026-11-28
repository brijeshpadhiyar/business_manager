import 'package:business_manager/core/design_system/app_density.dart';
import 'package:material_ui/material_ui.dart';

/// Density-aware spacing gap (`SizedBox`) backed by [AppDensityTokens].
///
/// Use `const AppGap.sm()`, `const AppGap.md()`, etc. in layouts so spacing
/// automatically tightens when [UiDensityMode.compact] is active.
final class AppGap extends StatelessWidget {
  const AppGap.xxs({super.key}) : _tier = _GapTier.xxs, _horizontal = false;
  const AppGap.xs({super.key}) : _tier = _GapTier.xs, _horizontal = false;
  const AppGap.xsm({super.key}) : _tier = _GapTier.xsm, _horizontal = false;
  const AppGap.sm({super.key}) : _tier = _GapTier.sm, _horizontal = false;
  const AppGap.md({super.key}) : _tier = _GapTier.md, _horizontal = false;
  const AppGap.lg({super.key}) : _tier = _GapTier.lg, _horizontal = false;
  const AppGap.xl({super.key}) : _tier = _GapTier.xl, _horizontal = false;

  const AppGap.hXxs({super.key}) : _tier = _GapTier.xxs, _horizontal = true;
  const AppGap.hXs({super.key}) : _tier = _GapTier.xs, _horizontal = true;
  const AppGap.hXsm({super.key}) : _tier = _GapTier.xsm, _horizontal = true;
  const AppGap.hSm({super.key}) : _tier = _GapTier.sm, _horizontal = true;
  const AppGap.hMd({super.key}) : _tier = _GapTier.md, _horizontal = true;
  const AppGap.hLg({super.key}) : _tier = _GapTier.lg, _horizontal = true;
  const AppGap.hXl({super.key}) : _tier = _GapTier.xl, _horizontal = true;

  final _GapTier _tier;
  final bool _horizontal;

  @override
  Widget build(BuildContext context) {
    final d = context.density;
    final size = switch (_tier) {
      _GapTier.xxs => d.xxs,
      _GapTier.xs => d.xs,
      _GapTier.xsm => d.xsm,
      _GapTier.sm => d.sm,
      _GapTier.md => d.md,
      _GapTier.lg => d.lg,
      _GapTier.xl => d.xl,
    };
    return SizedBox(
      width: _horizontal ? size : null,
      height: _horizontal ? null : size,
    );
  }
}

enum _GapTier { xxs, xs, xsm, sm, md, lg, xl }

/// Density-aware responsive `Wrap` grid that allocates extra columns and tighter
/// spacing in [UiDensityMode.compact] so KPI tiles and cards fit on fewer rows.
final class AppResponsiveGrid extends StatelessWidget {
  const AppResponsiveGrid({
    super.key,
    required this.children,
    this.compactColumns = 2,
    this.mediumColumns = 3,
    this.expandedColumns = 4,
    this.largeExpandedColumns,
    this.compactModeExtraCompact = 1,
    this.compactModeExtraMedium = 1,
    this.compactModeExtraExpanded = 2,
  });

  final List<Widget> children;
  final int compactColumns;
  final int mediumColumns;
  final int expandedColumns;
  final int? largeExpandedColumns;
  final int compactModeExtraCompact;
  final int compactModeExtraMedium;
  final int compactModeExtraExpanded;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final d = context.density;
    final gap = d.sm;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        int cols;
        if (w >= 1440 && largeExpandedColumns != null) {
          cols =
              largeExpandedColumns! +
              (d.isCompact ? compactModeExtraExpanded : 0);
        } else if (w >= 1024) {
          cols = expandedColumns + (d.isCompact ? compactModeExtraExpanded : 0);
        } else if (w >= 600) {
          cols = mediumColumns + (d.isCompact ? compactModeExtraMedium : 0);
        } else {
          cols = compactColumns + (d.isCompact ? compactModeExtraCompact : 0);
        }
        cols = cols.clamp(1, children.length);
        final tileW = (w - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: tileW, child: child),
          ],
        );
      },
    );
  }
}
