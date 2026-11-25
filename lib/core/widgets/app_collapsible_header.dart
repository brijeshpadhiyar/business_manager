import 'dart:ui';

import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/widgets/app_icon_button.dart';
import 'package:business_manager/core/widgets/app_status_badge.dart';
import 'package:material_ui/material_ui.dart';

/// Configuration for a native sliver-based collapsible header rendered inside
/// `AppScaffold(scrollMode: AppScrollMode.collapsible)`.
///
/// Uses Flutter's native `SliverAppBar` + `FlexibleSpaceBar` with smooth
/// collapse-ratio interpolation (zero scroll listeners, zero extra animation
/// controllers, zero `setState` on scroll).
final class AppCollapsibleHeader {
  const AppCollapsibleHeader({
    required this.title,
    this.subtitle,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.summary,
    this.background,
    this.bottom,
    this.expandedHeight = 184,
    this.pinned = true,
    this.floating = false,
    this.snap = false,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final List<Widget>? actions;
  final Widget? summary;
  final Widget? background;
  final PreferredSizeWidget? bottom;
  final double expandedHeight;
  final bool pinned;
  final bool floating;
  final bool snap;

  /// Copy with a different leading widget, actions or pin behaviour.
  AppCollapsibleHeader copyWith({
    Widget? leading,
    List<Widget>? actions,
    bool? pinned,
  }) {
    return AppCollapsibleHeader(
      title: title,
      subtitle: subtitle,
      leading: leading ?? this.leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions ?? this.actions,
      summary: summary,
      background: background,
      bottom: bottom,
      expandedHeight: expandedHeight,
      pinned: pinned ?? this.pinned,
      floating: floating,
      snap: snap,
    );
  }

  /// Space the toolbar actions take, so the collapsed title never runs
  /// under them. Icon buttons are 48dp; labelled buttons are wider.
  double _actionsReserve() {
    final list = actions;
    if (list == null || list.isEmpty) return AppSpacing.lg;
    var width = AppSpacing.sm;
    for (final a in list) {
      final isIcon =
          a is IconButton ||
          a is AppIconButton ||
          a is PopupMenuButton ||
          a is SizedBox;
      width += isIcon ? 48 : 148;
    }
    return width;
  }

  /// Builds the native `SliverAppBar` with frosted glass toolbar, smooth
  /// expanded-to-collapsed title crossfade, and collapsible summary content.
  Widget buildSliver(
    BuildContext context, {
    required bool primary,
    required double effectiveExpandedHeight,
    BackdropKey? backdropKey,
  }) {
    final theme = Theme.of(context);
    final tokens = context.surfaceTokens;
    final topPadding = primary ? MediaQuery.paddingOf(context).top : 0.0;
    const toolbarHeight = AppSizing.appBarHeight;
    final bottomHeight = bottom?.preferredSize.height ?? 0.0;
    final minExtent = toolbarHeight + bottomHeight + topPadding;
    final maxExtent = effectiveExpandedHeight + topPadding;
    final baseCollapsedTitleColor =
        theme.textTheme.titleMedium?.color ?? theme.colorScheme.onSurface;

    return SliverAppBar(
      primary: primary,
      pinned: pinned,
      floating: floating,
      snap: snap,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: toolbarHeight,
      expandedHeight: effectiveExpandedHeight,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      actions: actions,
      bottom: bottom,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final currentHeight = constraints.biggest.height;
          final delta = (maxExtent - minExtent).clamp(1.0, double.infinity);
          final collapseT = ((maxExtent - currentHeight) / delta).clamp(
            0.0,
            1.0,
          );
          final expandedOpacity = (1.0 - (collapseT * 1.85)).clamp(0.0, 1.0);
          final collapsedTitleOpacity = ((collapseT - 0.55) / 0.45).clamp(
            0.0,
            1.0,
          );

          Widget expandedContent = Transform.translate(
            offset: Offset(0, -10 * collapseT),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: expandedOpacity >= 0.5,
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (summary != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  summary!,
                ],
              ],
            ),
          );

          // Avoid allocating an Opacity saveLayer when fully opaque at rest.
          if (expandedOpacity < 0.995) {
            expandedContent = Opacity(
              opacity: expandedOpacity,
              child: expandedContent,
            );
          }

          return RepaintBoundary(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                backdropGroupKey: backdropKey,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      tokens.navGlassFill.withValues(alpha: 0.55),
                      tokens.navGlassFill,
                      collapseT,
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: tokens.navGlassBorder.withValues(
                          alpha: 0.35 + (0.65 * collapseT),
                        ),
                        width: 0.9,
                      ),
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (background != null && expandedOpacity > 0.01)
                        expandedOpacity < 0.995
                            ? Opacity(
                                opacity: expandedOpacity,
                                child: background!,
                              )
                            : background!,
                      // Collapsed compact toolbar title (fades via text alpha — zero saveLayer)
                      if (collapsedTitleOpacity > 0.01)
                        Positioned(
                          top: topPadding,
                          left: leading != null || automaticallyImplyLeading
                              ? 56
                              : AppSpacing.lg,
                          right: _actionsReserve(),
                          height: toolbarHeight,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: IgnorePointer(
                              ignoring: collapsedTitleOpacity < 0.5,
                              child: Semantics(
                                header: collapsedTitleOpacity >= 0.5,
                                child: Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: baseCollapsedTitleColor.withValues(
                                      alpha:
                                          baseCollapsedTitleColor.a *
                                          collapsedTitleOpacity,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Expanded large title + subtitle + summary strip
                      if (expandedOpacity > 0.01)
                        Positioned(
                          left: AppSpacing.lg,
                          right: AppSpacing.lg,
                          bottom: AppSpacing.md + bottomHeight,
                          child: IgnorePointer(
                            ignoring: expandedOpacity < 0.2,
                            child: expandedContent,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Pinned glass persistent header delegate for search bars and filter chips
/// rendered immediately below `AppCollapsibleHeader`.
final class AppPinnedSliverHeader extends SliverPersistentHeaderDelegate {
  const AppPinnedSliverHeader({
    required this.height,
    required this.child,
    this.backdropKey,
  });

  final double height;
  final Widget child;
  final BackdropKey? backdropKey;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final tokens = context.surfaceTokens;
    // Lightweight frosted surface (zero stacked BackdropFilter directly beneath
    // AppCollapsibleHeader) so 120Hz scrolling never executes two overlapping
    // full-width Gaussian blur passes per frame.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.navGlassFill.withValues(
          alpha: (tokens.navGlassFill.a + 0.14).clamp(0.0, 0.94),
        ),
        border: Border(
          bottom: BorderSide(color: tokens.navGlassBorder, width: 0.8),
        ),
      ),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizing.maxContentWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant AppPinnedSliverHeader oldDelegate) {
    return height != oldDelegate.height ||
        child != oldDelegate.child ||
        backdropKey != oldDelegate.backdropKey;
  }
}

/// Single metric item displayed inside [AppSummaryStrip] in a collapsible header.
final class AppSummaryMetric {
  const AppSummaryMetric({
    required this.label,
    required this.value,
    this.tone = AppStatusTone.neutral,
    this.icon,
  });

  final String label;
  final String value;
  final AppStatusTone tone;
  final IconData? icon;
}

/// Compact, responsive glass summary strip designed to live inside an expanded
/// [AppCollapsibleHeader] (or inline on desktop) without vertical bloat or
/// overflow at `360dp`.
final class AppSummaryStrip extends StatelessWidget {
  const AppSummaryStrip({super.key, required this.metrics});

  final List<AppSummaryMetric> metrics;

  Color _accentFor(AppStatusTone tone, bool isDark) => switch (tone) {
    AppStatusTone.good =>
      isDark ? AppColors.darkGoodStock : AppColors.lightGoodStock,
    AppStatusTone.pending =>
      isDark ? AppColors.darkPending : AppColors.lightPending,
    AppStatusTone.damaged =>
      isDark ? AppColors.darkDamaged : AppColors.lightDamaged,
    AppStatusTone.info => AppColors.brandTeal,
    AppStatusTone.neutral =>
      isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
  };

  @override
  Widget build(BuildContext context) {
    if (metrics.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tokens = context.surfaceTokens;

    Widget cell(AppSummaryMetric metric) {
      final accent = _accentFor(metric.tone, isDark);
      return DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.glassFill,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(
            color: accent.withValues(alpha: isDark ? 0.36 : 0.24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                metric.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 1),
              // Amounts shrink to fit rather than being cut off.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  metric.value,
                  maxLines: 1,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = AppSpacing.xs;
        const minCell = 104.0;
        final n = metrics.length;
        final available = constraints.maxWidth;
        final fits =
            !available.isFinite || (available - gap * (n - 1)) / n >= minCell;
        if (fits) {
          return Row(
            children: [
              for (var i = 0; i < n; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(child: cell(metrics[i])),
              ],
            ],
          );
        }
        // Narrow phone: keep one compact row, readable cells, swipe for more.
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < n; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                SizedBox(width: 120, child: cell(metrics[i])),
              ],
            ],
          ),
        );
      },
    );
  }
}
