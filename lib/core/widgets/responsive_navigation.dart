import 'dart:ui';

import 'package:business_manager/core/config/app_identity.dart';
import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_density.dart';
import 'package:business_manager/core/design_system/app_glass_quality.dart';
import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_shadows.dart';
import 'package:business_manager/core/theme/navigation_sidebar_cubit.dart';
import 'package:business_manager/core/widgets/app_breadcrumb_bar.dart';
import 'package:business_manager/core/widgets/app_glass_backdrop.dart';
import 'package:business_manager/core/widgets/app_heading.dart';
import 'package:business_manager/features/guidance/presentation/registry/guide_target_registry.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:motor/motor.dart';

/// Inherited context exposed by [ResponsiveNavigation] so descendant
/// [AppScaffold] instances know when they are already hosted inside a
/// persistent glass shell (preventing duplicate [AppGlassBackdrop] painting
/// and adapting spacing cleanly across Mobile, Tablet, Desktop, and Web).
final class ResponsiveShellScope extends InheritedWidget {
  const ResponsiveShellScope({
    super.key,
    required this.sizeClass,
    required this.hasPersistentChrome,
    required super.child,
  });

  final AppWindowSizeClass sizeClass;
  final bool hasPersistentChrome;

  static ResponsiveShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ResponsiveShellScope>();
  }

  @override
  bool updateShouldNotify(covariant ResponsiveShellScope oldWidget) {
    return sizeClass != oldWidget.sizeClass ||
        hasPersistentChrome != oldWidget.hasPersistentChrome;
  }
}

final class ResponsiveNavDestination {
  const ResponsiveNavDestination({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badgeCount,
    this.id,
    this.guideTargetId,
  });

  final String? id;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final int? badgeCount;
  final String? guideTargetId;
}

final class ResponsiveNavActionItem {
  const ResponsiveNavActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.id,
    this.badgeCount,
    this.isActive = false,
  });

  final String? id;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final int? badgeCount;
  final bool isActive;
}

/// Logical group of navigation items rendered inside [StitchFlowSideNav] and
/// the mobile "More" modules sheet.
final class ResponsiveNavSection {
  const ResponsiveNavSection({
    required this.id,
    required this.title,
    required this.items,
    this.collapsible = true,
  });

  final String id;
  final String title;
  final List<ResponsiveNavSectionItem> items;
  final bool collapsible;
}

/// Single destination row inside a [ResponsiveNavSection].
final class ResponsiveNavSectionItem {
  const ResponsiveNavSectionItem({
    required this.id,
    required this.label,
    required this.icon,
    required this.onTap,
    this.selectedIcon,
    this.badgeCount,
    this.isActive = false,
    this.guideTargetId,
  });

  final String id;
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final VoidCallback onTap;
  final int? badgeCount;
  final bool isActive;
  final String? guideTargetId;
}

/// Sleek, compact frosted-glass Bottom Navigation bar for Mobile (`< 600dp`).
///
/// Renders 4 core tabs plus an optional `More` slot (5 items max) with pill
/// active highlights, animated icons, badge indicators, and single-line labels.
final class StitchFlowBottomNav extends StatelessWidget {
  const StitchFlowBottomNav({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.showMoreButton = false,
    this.moreLabel = 'More',
    this.moreSelected = false,
    this.moreBadgeCount,
    this.onMorePressed,
  });

  final List<ResponsiveNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool showMoreButton;
  final String moreLabel;
  final bool moreSelected;
  final int? moreBadgeCount;
  final VoidCallback? onMorePressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.surfaceTokens;
    final d = context.density;
    final quality = AppGlassQuality.resolve(context);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final barHeight = d.navBarHeight;
    final topRadius = BorderRadius.vertical(top: Radius.circular(d.radiusLg));

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: topRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: quality.chromeBlurSigma,
            sigmaY: quality.chromeBlurSigma,
          ),
          enabled: quality.enableBackdropBlur,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.navGlassFill,
              borderRadius: topRadius,
              border: Border(
                top: BorderSide(color: tokens.navGlassBorder, width: 1.0),
              ),
              boxShadow: [
                for (final sh in AppShadows.of(context).lg)
                  sh.copyWith(offset: Offset(0, -sh.offset.dy)),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SizedBox(
                height: barHeight,
                child: Row(
                  children: [
                    for (var i = 0; i < destinations.length; i++)
                      Expanded(
                        child: _BottomNavItemTile(
                          label: destinations[i].label,
                          icon: destinations[i].icon,
                          selectedIcon:
                              destinations[i].selectedIcon ??
                              destinations[i].icon,
                          selected: !moreSelected && selectedIndex == i,
                          badgeCount: destinations[i].badgeCount,
                          guideTargetId: destinations[i].guideTargetId,
                          onTap: () => onDestinationSelected(i),
                        ),
                      ),
                    if (showMoreButton && onMorePressed != null)
                      Expanded(
                        child: _BottomNavItemTile(
                          label: moreLabel,
                          icon: AppIcons.moreApps,
                          selectedIcon: AppIcons.moreApps,
                          selected: moreSelected,
                          badgeCount: moreBadgeCount,
                          onTap: onMorePressed!,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _BottomNavItemTile extends StatelessWidget {
  const _BottomNavItemTile({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
    this.badgeCount,
    this.guideTargetId,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;
  final int? badgeCount;
  final String? guideTargetId;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final d = context.density;
    final activeColor = isDark ? colorScheme.secondary : colorScheme.primary;
    final iconColor = selected ? activeColor : colorScheme.onSurfaceVariant;
    final pillColor = selected
        ? (isDark
              ? colorScheme.secondary.withValues(alpha: 0.22)
              : colorScheme.primaryContainer.withValues(alpha: 0.85))
        : Colors.transparent;

    Widget iconWidget = SingleMotionBuilder(
      value: selected ? 1.1 : 1.0,
      from: 1.0,
      motion: AppMotion.spring(context, AppMotion.bouncySpring),
      builder: (context, scale, child) =>
          Transform.scale(scale: scale, child: child),
      child: Icon(
        selected ? selectedIcon : icon,
        size: d.isCompact ? 18 : 20,
        color: iconColor,
      ),
    );

    if (badgeCount != null && badgeCount! > 0) {
      iconWidget = Badge(
        label: Text(badgeCount! > 99 ? '99+' : '$badgeCount'),
        child: iconWidget,
      );
    }

    Widget item = Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: d.radiusMdBorder,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: d.xxs,
              vertical: d.isCompact ? 2 : 4,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: AppMotion.duration(context, AppMotion.fast),
                  curve: AppMotion.standardCurve,
                  padding: EdgeInsets.symmetric(
                    horizontal: d.isCompact ? 10 : 14,
                    vertical: d.isCompact ? 2 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: AppRadius.fullBorder,
                    border: selected
                        ? Border.all(
                            color: activeColor.withValues(alpha: 0.25),
                            width: 0.8,
                          )
                        : null,
                  ),
                  child: iconWidget,
                ),
                SizedBox(height: d.isCompact ? 1 : 3),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: d.isCompact ? 10 : 11,
                    height: 1.1,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? activeColor
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (guideTargetId != null) {
      item = GuideTarget(id: guideTargetId!, child: item);
    }
    return item;
  }
}

/// Compact, grouped, collapsible & hideable Side Navigator for Web / Desktop
/// (`expanded` `220dp` / `192dp` compact, `compactRail` `60dp` / `52dp`
/// compact, `hidden` `0dp`) and Tablet Mini Rail (`compactRail` / `hidden`).
final class StitchFlowSideNav extends StatelessWidget {
  const StitchFlowSideNav({
    super.key,
    required this.title,
    required this.mode,
    required this.sections,
    required this.collapsedSectionIds,
    required this.onToggleSection,
    required this.onToggleCollapseRail,
    required this.onToggleHide,
    this.onSearchPressed,
    this.searchTooltip,
    this.showExpandControl = true,
  });

  final String title;
  final SidebarMode mode;
  final List<ResponsiveNavSection> sections;
  final Set<String> collapsedSectionIds;
  final ValueChanged<String> onToggleSection;
  final VoidCallback onToggleCollapseRail;
  final VoidCallback onToggleHide;
  final VoidCallback? onSearchPressed;
  final String? searchTooltip;
  final bool showExpandControl;

  @override
  Widget build(BuildContext context) {
    final d = context.density;
    final tokens = context.surfaceTokens;
    final quality = AppGlassQuality.resolve(context);
    final l10n = AppLocalizations.of(context);

    final targetWidth = switch (mode) {
      SidebarMode.expanded => d.desktopSidebarWidth,
      SidebarMode.compactRail => d.navigationRailWidth,
      SidebarMode.hidden => 0.0,
    };

    final isHidden = mode == SidebarMode.hidden;
    final isRail = mode == SidebarMode.compactRail;

    return RepaintBoundary(
      child: AnimatedContainer(
        duration: AppMotion.duration(context, AppMotion.normal),
        curve: AppMotion.standardCurve,
        width: targetWidth,
        child: ClipRect(
          child: ExcludeFocus(
            excluding: isHidden,
            child: IgnorePointer(
              ignoring: isHidden,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: isRail
                    ? d.navigationRailWidth
                    : d.desktopSidebarWidth,
                maxWidth: isRail
                    ? d.navigationRailWidth
                    : d.desktopSidebarWidth,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: quality.chromeBlurSigma,
                    sigmaY: quality.chromeBlurSigma,
                  ),
                  enabled: !isHidden && quality.enableBackdropBlur,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tokens.navGlassFill,
                      border: Border(
                        right: BorderSide(
                          color: tokens.navGlassBorder,
                          width: 0.9,
                        ),
                      ),
                    ),
                    child: isRail
                        ? _buildCompactRailContent(context, d, l10n)
                        : _buildExpandedContent(context, d, l10n),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(
    BuildContext context,
    AppDensityTokens d,
    AppLocalizations? l10n,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.surfaceTokens;
    final collapseTip = l10n?.navSidebarCollapse ?? 'Collapse to compact rail';
    final hideTip = l10n?.navSidebarHide ?? 'Hide sidebar';
    final searchLabel = searchTooltip ?? l10n?.uxSearchTooltip ?? 'Search';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Compact Brand Header + Collapse / Hide controls
        SizedBox(
          height: d.isCompact ? 42 : 48,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: d.md),
            child: Row(
              children: [
                Image.asset(
                  AppIdentity.symbolPngAsset,
                  width: d.isCompact ? 20 : 24,
                  height: d.isCompact ? 20 : 24,
                  cacheWidth: 96,
                  cacheHeight: 96,
                  errorBuilder: (_, _, _) =>
                      Icon(AppIcons.brand, size: d.iconMd),
                ),
                SizedBox(width: d.sm),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                _SidebarHeaderIconBtn(
                  icon: AppIcons.sidebarCollapse,
                  tooltip: collapseTip,
                  onTap: onToggleCollapseRail,
                ),
                SizedBox(width: d.xxs),
                _SidebarHeaderIconBtn(
                  icon: AppIcons.sidebarHide,
                  tooltip: hideTip,
                  onTap: onToggleHide,
                ),
              ],
            ),
          ),
        ),
        Divider(height: 1, thickness: 0.8, color: tokens.navGlassBorder),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: d.sm,
              vertical: d.isCompact ? d.xs : d.sm,
            ),
            children: [
              for (var sIdx = 0; sIdx < sections.length; sIdx++) ...[
                _ExpandedNavSectionBlock(
                  section: sections[sIdx],
                  collapsed:
                      sections[sIdx].collapsible &&
                      collapsedSectionIds.contains(sections[sIdx].id),
                  onToggle: () => onToggleSection(sections[sIdx].id),
                ),
                if (sIdx < sections.length - 1)
                  SizedBox(height: d.isCompact ? d.xs : d.sm),
              ],
            ],
          ),
        ),
        if (onSearchPressed != null) ...[
          Divider(height: 1, thickness: 0.8, color: tokens.navGlassBorder),
          Padding(
            padding: EdgeInsets.all(d.sm),
            child: InkWell(
              onTap: onSearchPressed,
              borderRadius: d.radiusMdBorder,
              child: Container(
                height: d.isCompact ? 30 : 34,
                padding: EdgeInsets.symmetric(horizontal: d.sm),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.38,
                  ),
                  borderRadius: d.radiusMdBorder,
                  border: Border.all(
                    color: tokens.navGlassBorder.withValues(alpha: 0.8),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      AppIcons.search,
                      size: d.iconSm,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: d.xs),
                    Expanded(
                      child: Text(
                        searchLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.7),
                        borderRadius: d.radiusSmBorder,
                        border: Border.all(color: tokens.navGlassBorder),
                      ),
                      child: Text(
                        'Ctrl+K',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 9.5,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCompactRailContent(
    BuildContext context,
    AppDensityTokens d,
    AppLocalizations? l10n,
  ) {
    final tokens = context.surfaceTokens;
    final expandTip = l10n?.navSidebarExpand ?? 'Expand sidebar';
    final hideTip = l10n?.navSidebarHide ?? 'Hide sidebar';

    return Column(
      children: [
        SizedBox(
          height: d.isCompact ? 42 : 48,
          child: Center(
            child: Tooltip(
              message: showExpandControl ? expandTip : title,
              child: InkWell(
                onTap: showExpandControl ? onToggleCollapseRail : null,
                borderRadius: d.radiusMdBorder,
                child: Padding(
                  padding: EdgeInsets.all(d.xs),
                  child: Image.asset(
                    AppIdentity.symbolPngAsset,
                    width: d.isCompact ? 20 : 24,
                    height: d.isCompact ? 20 : 24,
                    cacheWidth: 96,
                    cacheHeight: 96,
                    errorBuilder: (_, _, _) =>
                        Icon(AppIcons.brand, size: d.iconMd),
                  ),
                ),
              ),
            ),
          ),
        ),
        Divider(height: 1, thickness: 0.8, color: tokens.navGlassBorder),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(vertical: d.xxs),
            children: [
              for (var sIdx = 0; sIdx < sections.length; sIdx++) ...[
                if (sIdx > 0)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: d.md,
                      vertical: d.isCompact ? 2 : 3,
                    ),
                    child: Divider(
                      height: 1,
                      thickness: 0.8,
                      color: tokens.navGlassBorder,
                    ),
                  ),
                for (final item in sections[sIdx].items)
                  _RailNavItemButton(
                    item: item,
                    sectionTitle: sections[sIdx].title,
                  ),
              ],
            ],
          ),
        ),
        Divider(height: 1, thickness: 0.8, color: tokens.navGlassBorder),
        Padding(
          padding: EdgeInsets.symmetric(vertical: d.xxs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showExpandControl)
                _SidebarHeaderIconBtn(
                  icon: AppIcons.sidebarExpand,
                  tooltip: expandTip,
                  onTap: onToggleCollapseRail,
                ),
              _SidebarHeaderIconBtn(
                icon: AppIcons.sidebarHide,
                tooltip: hideTip,
                onTap: onToggleHide,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _SidebarHeaderIconBtn extends StatelessWidget {
  const _SidebarHeaderIconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = context.density;
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: d.radiusSmBorder,
        child: SizedBox(
          width: d.isCompact ? 26 : 30,
          height: d.isCompact ? 26 : 30,
          child: Icon(icon, size: d.iconSm, color: colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

final class _ExpandedNavSectionBlock extends StatelessWidget {
  const _ExpandedNavSectionBlock({
    required this.section,
    required this.collapsed,
    required this.onToggle,
  });

  final ResponsiveNavSection section;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final d = context.density;
    final colorScheme = Theme.of(context).colorScheme;
    final hasActiveChild = section.items.any((item) => item.isActive);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: section.collapsible ? onToggle : null,
          borderRadius: d.radiusSmBorder,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: d.sm,
              vertical: d.isCompact ? 3 : 4,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    section.title.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: d.isCompact ? 9.5 : 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.7,
                      color: hasActiveChild
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.78,
                            ),
                    ),
                  ),
                ),
                if (section.collapsible)
                  Icon(
                    collapsed ? AppIcons.chevronRight : AppIcons.expandMore,
                    size: 14,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: AppMotion.duration(context, AppMotion.fast),
          firstCurve: AppMotion.standardCurve,
          secondCurve: AppMotion.standardCurve,
          crossFadeState: collapsed
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final item in section.items) _ExpandedNavItemTile(item: item),
            ],
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}

final class _ExpandedNavItemTile extends StatelessWidget {
  const _ExpandedNavItemTile({required this.item});

  final ResponsiveNavSectionItem item;

  @override
  Widget build(BuildContext context) {
    final d = context.density;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = item.isActive;
    final activeColor = isDark ? colorScheme.secondary : colorScheme.primary;
    final fillColor = isActive
        ? (isDark
              ? colorScheme.secondary.withValues(alpha: 0.20)
              : colorScheme.primaryContainer.withValues(alpha: 0.78))
        : Colors.transparent;

    Widget tile = Padding(
      padding: EdgeInsets.symmetric(vertical: d.isCompact ? 1 : 1.5),
      child: Semantics(
        button: true,
        selected: isActive,
        label: item.label,
        child: InkWell(
          onTap: item.onTap,
          borderRadius: d.radiusMdBorder,
          child: AnimatedContainer(
            duration: AppMotion.duration(context, AppMotion.fast),
            height: d.isCompact ? 31 : 36,
            padding: EdgeInsets.symmetric(horizontal: d.sm),
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: d.radiusMdBorder,
              border: isActive
                  ? Border.all(
                      color: activeColor.withValues(alpha: 0.28),
                      width: 0.9,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? (item.selectedIcon ?? item.icon) : item.icon,
                  size: d.isCompact ? 16 : 18,
                  color: isActive ? activeColor : colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: d.sm),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: d.isCompact ? 12 : 13,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive ? activeColor : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (item.badgeCount != null && item.badgeCount! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      borderRadius: AppRadius.fullBorder,
                    ),
                    child: Text(
                      item.badgeCount! > 99 ? '99+' : '${item.badgeCount}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (item.guideTargetId != null) {
      tile = GuideTarget(id: item.guideTargetId!, child: tile);
    }
    return tile;
  }
}

final class _RailNavItemButton extends StatelessWidget {
  const _RailNavItemButton({
    required this.item,
    required this.sectionTitle,
  });

  final ResponsiveNavSectionItem item;
  final String sectionTitle;

  @override
  Widget build(BuildContext context) {
    final d = context.density;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = item.isActive;
    final activeColor = isDark ? colorScheme.secondary : colorScheme.primary;
    final fillColor = isActive
        ? (isDark
              ? colorScheme.secondary.withValues(alpha: 0.22)
              : colorScheme.primaryContainer.withValues(alpha: 0.84))
        : Colors.transparent;

    Widget icon = Icon(
      isActive ? (item.selectedIcon ?? item.icon) : item.icon,
      size: d.isCompact ? 17 : 20,
      color: isActive ? activeColor : colorScheme.onSurfaceVariant,
    );

    if (item.badgeCount != null && item.badgeCount! > 0) {
      icon = Badge(
        label: Text(item.badgeCount! > 99 ? '99+' : '${item.badgeCount}'),
        child: icon,
      );
    }

    Widget button = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: d.xs,
        vertical: d.isCompact ? 1 : 1.5,
      ),
      child: Semantics(
        button: true,
        selected: isActive,
        label: item.label,
        child: Tooltip(
          message: '$sectionTitle • ${item.label}',
          waitDuration: const Duration(milliseconds: 200),
          child: InkWell(
            onTap: item.onTap,
            borderRadius: d.radiusMdBorder,
            child: AnimatedContainer(
              duration: AppMotion.duration(context, AppMotion.fast),
              height: d.isCompact ? 28 : 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: fillColor,
                borderRadius: d.radiusMdBorder,
                border: isActive
                    ? Border.all(
                        color: activeColor.withValues(alpha: 0.30),
                        width: 0.9,
                      )
                    : null,
              ),
              child: icon,
            ),
          ),
        ),
      ),
    );

    if (item.guideTargetId != null) {
      button = GuideTarget(id: item.guideTargetId!, child: button);
    }
    return button;
  }
}

/// Adaptive StitchFlow glassmorphism navigation shell:
/// - Compact (`< 600dp`): Sleek compact frosted-glass Bottom Navigation
///   ([StitchFlowBottomNav]) with 4 core tabs + categorized `More` sheet.
/// - Medium (`600..1023dp`): Compact Mini Rail ([StitchFlowSideNav]) + Drawer
///   for full grouped modules.
/// - Expanded (`>= 1024dp`): Toggleable & hideable grouped Side Navigator
///   ([StitchFlowSideNav]: `expanded` <-> `compactRail` <-> `hidden`),
///   persisted via [NavigationSidebarCubit] and toggleable with `Ctrl+B`.
final class ResponsiveNavigation extends StatefulWidget {
  const ResponsiveNavigation({
    super.key,
    required this.title,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.subtitle,
    this.actions,
    this.sidebarExtraActions = const [],
    this.activeExtraActionId,
    this.sections = const [],
    this.mobileMoreSections = const [],
    this.mobileSheetFooterActions = const [],
    this.isMoreActive = false,
    this.moreLabel,
    this.allModulesTitle,
    this.moreBadgeCount,
    this.onSearchPressed,
    this.searchTooltip,
    this.breadcrumbs = const [],
    this.showMobileChrome = true,
    this.floatingActionButton,
    this.enableBodyTransition = false,
    this.extraShortcuts = const {},
    this.compactActions,
    this.initialSidebarMode = SidebarMode.expanded,
  });

  final String title;
  final String? subtitle;
  final List<ResponsiveNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final List<Widget>? actions;
  final List<ResponsiveNavActionItem> sidebarExtraActions;
  final String? activeExtraActionId;

  /// Categorized sections for the Web/Desktop/Tablet Side Navigator.
  /// When empty, sections are synthesized from [destinations] and
  /// [sidebarExtraActions].
  final List<ResponsiveNavSection> sections;

  /// Categorized sections displayed inside the Mobile `More` modal sheet.
  final List<ResponsiveNavSection> mobileMoreSections;

  /// Optional utility actions at the bottom of the Mobile `More` sheet
  /// (e.g., Lock Now).
  final List<ResponsiveNavActionItem> mobileSheetFooterActions;

  /// Whether the Mobile `More` tab should be highlighted as active.
  final bool isMoreActive;
  final String? moreLabel;
  final String? allModulesTitle;
  final int? moreBadgeCount;

  final VoidCallback? onSearchPressed;
  final String? searchTooltip;
  final List<AppBreadcrumbItem> breadcrumbs;
  final bool showMobileChrome;
  final Widget? floatingActionButton;
  final bool enableBodyTransition;

  /// App-level keyboard shortcuts (for example Ctrl+K search, Esc back).
  final Map<ShortcutActivator, VoidCallback> extraShortcuts;

  /// Toolbar actions for compact screens (phones, narrow windows). Falls back
  /// to [actions] when null.
  final List<Widget>? compactActions;

  /// Fallback mode used when no [NavigationSidebarCubit] is mounted above this
  /// widget (e.g., isolated widget tests).
  final SidebarMode initialSidebarMode;

  @override
  State<ResponsiveNavigation> createState() => _ResponsiveNavigationState();
}

final class _ResponsiveNavigationState extends State<ResponsiveNavigation> {
  final GlobalKey<ScaffoldState> _tabletScaffoldKey =
      GlobalKey<ScaffoldState>();
  late SidebarMode _localMode = widget.initialSidebarMode;
  SidebarMode _localLastVisible = SidebarMode.expanded;
  final Set<String> _localCollapsedSections = <String>{};

  Widget _animatedBody(BuildContext context) {
    if (!widget.enableBodyTransition || AppMotion.reduceMotion(context)) {
      return widget.body;
    }
    return AnimatedSwitcher(
      duration: AppMotion.tabFade,
      switchInCurve: AppMotion.standardCurve,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: KeyedSubtree(
        key: ValueKey<int>(widget.selectedIndex),
        child: widget.body,
      ),
    );
  }

  List<ResponsiveNavSection> _effectiveSections(BuildContext context) {
    if (widget.sections.isNotEmpty) return widget.sections;
    final primaryItems = <ResponsiveNavSectionItem>[
      for (var i = 0; i < widget.destinations.length; i++)
        ResponsiveNavSectionItem(
          id: widget.destinations[i].id ?? 'primary_$i',
          label: widget.destinations[i].label,
          icon: widget.destinations[i].icon,
          selectedIcon: widget.destinations[i].selectedIcon,
          badgeCount: widget.destinations[i].badgeCount,
          guideTargetId: widget.destinations[i].guideTargetId,
          isActive:
              widget.activeExtraActionId == null && widget.selectedIndex == i,
          onTap: () => widget.onDestinationSelected(i),
        ),
    ];
    final l10n = AppLocalizations.of(context);
    final result = <ResponsiveNavSection>[
      ResponsiveNavSection(
        id: 'primary',
        title: l10n?.navSectionOverview ?? 'Navigation',
        collapsible: false,
        items: primaryItems,
      ),
    ];
    if (widget.sidebarExtraActions.isNotEmpty) {
      result.add(
        ResponsiveNavSection(
          id: 'modules',
          title: l10n?.navAllModules ?? 'Modules',
          items: [
            for (final extra in widget.sidebarExtraActions)
              ResponsiveNavSectionItem(
                id: extra.id ?? extra.label,
                label: extra.label,
                icon: extra.icon,
                badgeCount: extra.badgeCount,
                isActive:
                    extra.isActive ||
                    (extra.id != null &&
                        extra.id == widget.activeExtraActionId),
                onTap: extra.onTap,
              ),
          ],
        ),
      );
    }
    return result;
  }

  Widget _brandTitle(BuildContext context) {
    final d = context.density;
    final showLogo = MediaQuery.sizeOf(context).width >= 360;
    final logoSize = d.isCompact ? 20.0 : 24.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLogo) ...[
          Image.asset(
            AppIdentity.symbolPngAsset,
            width: logoSize,
            height: logoSize,
            cacheWidth: 96,
            cacheHeight: 96,
            errorBuilder: (_, _, _) => Icon(AppIcons.brand, size: d.iconMd),
          ),
          SizedBox(width: d.sm),
        ],
        Flexible(
          child: Text(
            widget.title,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildGlassAppBar(
    BuildContext context, {
    bool showTitle = true,
    bool automaticallyImplyLeading = true,
    Widget? leading,
    Widget? customTitle,
    double? toolbarHeight,
    List<Widget>? actionsOverride,
  }) {
    final tokens = context.surfaceTokens;
    final d = context.density;
    final quality = AppGlassQuality.resolve(context);
    return AppBar(
      toolbarHeight: toolbarHeight ?? d.appBarHeight,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: customTitle ?? (showTitle ? _brandTitle(context) : null),
      actions: actionsOverride ?? widget.actions,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: quality.chromeBlurSigma,
            sigmaY: quality.chromeBlurSigma,
          ),
          enabled: quality.enableBackdropBlur,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: tokens.navGlassFill,
              border: Border(
                bottom: BorderSide(color: tokens.navGlassBorder, width: 0.9),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openMobileMoreSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sheetTitle =
        widget.allModulesTitle ?? l10n?.navAllModules ?? 'All Modules';
    final sections = widget.mobileMoreSections;
    final footerActions = widget.mobileSheetFooterActions;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barrierColor = Colors.black.withValues(alpha: isDark ? 0.56 : 0.34);
    final reduce = AppMotion.reduceMotion(context);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: barrierColor,
      sheetAnimationStyle: AnimationStyle(
        duration: reduce ? Duration.zero : const Duration(milliseconds: 220),
        reverseDuration: reduce
            ? Duration.zero
            : const Duration(milliseconds: 160),
        curve: AppMotion.standardCurve,
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (sheetCtx) {
        final tokens = sheetCtx.surfaceTokens;
        final colorScheme = Theme.of(sheetCtx).colorScheme;
        final d = sheetCtx.density;
        final topRadius = BorderRadius.vertical(
          top: Radius.circular(d.radiusXl),
        );
        final quality = AppGlassQuality.resolve(sheetCtx);
        final maxHeight = MediaQuery.sizeOf(sheetCtx).height * 0.78;

        return RepaintBoundary(
          child: ClipRRect(
            borderRadius: topRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: quality.chromeBlurSigma,
                sigmaY: quality.chromeBlurSigma,
              ),
              enabled: quality.enableBackdropBlur,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.dialogGlassFill,
                    borderRadius: topRadius,
                    border: Border(
                      top: BorderSide(color: tokens.glassBorder, width: 1.3),
                      left: BorderSide(color: tokens.glassBorder, width: 0.6),
                      right: BorderSide(color: tokens.glassBorder, width: 0.6),
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            d.lg,
                            d.sm,
                            d.lg,
                            d.xs,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Center(
                                child: Container(
                                  width: d.isCompact ? 32 : 40,
                                  height: 4,
                                  margin: EdgeInsets.only(bottom: d.sm),
                                  decoration: BoxDecoration(
                                    color: colorScheme.onSurfaceVariant
                                        .withValues(alpha: 0.35),
                                    borderRadius: AppRadius.fullBorder,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    AppIcons.moreApps,
                                    size: d.iconMd,
                                    color: colorScheme.primary,
                                  ),
                                  SizedBox(width: d.sm),
                                  Expanded(
                                    child: AppHeading(
                                      sheetTitle,
                                      level: AppHeadingLevel.h3,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: MaterialLocalizations.of(
                                      sheetCtx,
                                    ).closeButtonTooltip,
                                    icon: Icon(AppIcons.close, size: d.iconMd),
                                    onPressed: () =>
                                        Navigator.of(sheetCtx).pop(),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          thickness: 0.8,
                          color: tokens.navGlassBorder,
                        ),
                        Flexible(
                          child: ListView(
                            shrinkWrap: true,
                            padding: EdgeInsets.fromLTRB(
                              d.lg,
                              d.md,
                              d.lg,
                              d.lg,
                            ),
                            children: [
                              for (var i = 0; i < sections.length; i++) ...[
                                _MoreSheetSectionGroup(
                                  section: sections[i],
                                  onItemTap: (item) {
                                    Navigator.of(sheetCtx).pop();
                                    item.onTap();
                                  },
                                ),
                                if (i < sections.length - 1)
                                  SizedBox(height: d.md),
                              ],
                              if (footerActions.isNotEmpty) ...[
                                SizedBox(height: d.md),
                                Divider(
                                  height: 1,
                                  thickness: 0.8,
                                  color: tokens.navGlassBorder,
                                ),
                                SizedBox(height: d.sm),
                                for (final action in footerActions)
                                  ListTile(
                                    dense: d.isCompact,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: d.radiusMdBorder,
                                    ),
                                    leading: Icon(
                                      action.icon,
                                      size: d.iconMd,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    title: Text(action.label),
                                    onTap: () {
                                      Navigator.of(sheetCtx).pop();
                                      action.onTap();
                                    },
                                  ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Map<ShortcutActivator, VoidCallback> _buildKeyboardShortcuts({
    required VoidCallback onToggleSidebar,
  }) {
    final map = <ShortcutActivator, VoidCallback>{};
    const digitKeys = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
    ];
    for (var i = 0; i < widget.destinations.length && i < digitKeys.length; i++) {
      final idx = i;
      map[SingleActivator(digitKeys[i], alt: true)] = () =>
          widget.onDestinationSelected(idx);
    }
    map[const SingleActivator(LogicalKeyboardKey.keyB, control: true)] =
        onToggleSidebar;
    map[const SingleActivator(LogicalKeyboardKey.keyB, meta: true)] =
        onToggleSidebar;
    map.addAll(widget.extraShortcuts);
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final sizeClass = AppBreakpoints.fromWidth(width);
    final sidebarCubit = context.read<NavigationSidebarCubit?>();
    if (sidebarCubit != null) {
      return BlocBuilder<NavigationSidebarCubit, NavigationSidebarState>(
        builder: (context, sidebarState) => _buildWithSidebarState(
          context,
          sizeClass: sizeClass,
          mode: sidebarState.mode,
          collapsedSections: sidebarState.collapsedSectionIds,
          onCycleMode: sidebarCubit.cycleMode,
          onToggleExpandedOrRail: sidebarCubit.toggleExpandedOrRail,
          onToggleHide: sidebarCubit.toggleHide,
          onToggleSection: sidebarCubit.toggleSection,
        ),
      );
    }

    return _buildWithSidebarState(
      context,
      sizeClass: sizeClass,
      mode: _localMode,
      collapsedSections: _localCollapsedSections,
      onCycleMode: () {
        setState(() {
          _localMode = switch (_localMode) {
            SidebarMode.expanded => SidebarMode.compactRail,
            SidebarMode.compactRail => SidebarMode.hidden,
            SidebarMode.hidden => SidebarMode.expanded,
          };
          if (_localMode != SidebarMode.hidden) {
            _localLastVisible = _localMode;
          }
        });
      },
      onToggleExpandedOrRail: () {
        setState(() {
          _localMode = _localMode == SidebarMode.expanded
              ? SidebarMode.compactRail
              : SidebarMode.expanded;
          _localLastVisible = _localMode;
        });
      },
      onToggleHide: () {
        setState(() {
          if (_localMode == SidebarMode.hidden) {
            _localMode = _localLastVisible;
          } else {
            _localLastVisible = _localMode;
            _localMode = SidebarMode.hidden;
          }
        });
      },
      onToggleSection: (id) {
        setState(() {
          if (!_localCollapsedSections.add(id)) {
            _localCollapsedSections.remove(id);
          }
        });
      },
    );
  }

  Widget _buildWithSidebarState(
    BuildContext context, {
    required AppWindowSizeClass sizeClass,
    required SidebarMode mode,
    required Set<String> collapsedSections,
    required VoidCallback onCycleMode,
    required VoidCallback onToggleExpandedOrRail,
    required VoidCallback onToggleHide,
    required ValueChanged<String> onToggleSection,
  }) {
    final d = context.density;
    final l10n = AppLocalizations.of(context);
    final transitionBody = _animatedBody(context);

    Widget buildShell() {
      if (sizeClass.isCompact) {
        if (!widget.showMobileChrome) {
          return ResponsiveShellScope(
            sizeClass: sizeClass,
            hasPersistentChrome: false,
            child: Material(
              type: MaterialType.transparency,
              child: transitionBody,
            ),
          );
        }

        final showMore = widget.mobileMoreSections.isNotEmpty;
        final moreLabel = widget.moreLabel ?? l10n?.navMore ?? 'More';

        return ResponsiveShellScope(
          sizeClass: sizeClass,
          hasPersistentChrome: true,
          child: AppGlassBackdrop(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: _buildGlassAppBar(
                context,
                actionsOverride: widget.compactActions,
              ),
              body: SafeArea(bottom: false, child: transitionBody),
              floatingActionButton: widget.floatingActionButton,
              bottomNavigationBar: StitchFlowBottomNav(
                destinations: widget.destinations,
                selectedIndex: widget.selectedIndex.clamp(
                  0,
                  widget.destinations.length - 1,
                ),
                onDestinationSelected: widget.onDestinationSelected,
                showMoreButton: showMore,
                moreLabel: moreLabel,
                moreSelected: widget.isMoreActive,
                moreBadgeCount: widget.moreBadgeCount,
                onMorePressed: () => _openMobileMoreSheet(context),
              ),
            ),
          ),
        );
      }

      final sections = _effectiveSections(context);

      // Tablet (600..1023dp): Compact Mini Rail (or hidden) + full grouped
      // overlay Drawer triggered from the top bar.
      if (sizeClass.isMedium) {
        final tabletMode =
            mode == SidebarMode.hidden ? SidebarMode.hidden : SidebarMode.compactRail;
        return ResponsiveShellScope(
          sizeClass: sizeClass,
          hasPersistentChrome: true,
          child: AppGlassBackdrop(
            child: Scaffold(
              key: _tabletScaffoldKey,
              backgroundColor: Colors.transparent,
              drawer: Drawer(
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: d.lg,
                          vertical: d.md,
                        ),
                        child: Row(
                          children: [
                            Expanded(child: _brandTitle(context)),
                            IconButton(
                              tooltip: MaterialLocalizations.of(
                                context,
                              ).closeButtonTooltip,
                              icon: Icon(AppIcons.close, size: d.iconMd),
                              onPressed: () =>
                                  Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.all(d.sm),
                          children: [
                            for (final section in sections) ...[
                              _ExpandedNavSectionBlock(
                                section: ResponsiveNavSection(
                                  id: section.id,
                                  title: section.title,
                                  collapsible: false,
                                  items: [
                                    for (final item in section.items)
                                      ResponsiveNavSectionItem(
                                        id: item.id,
                                        label: item.label,
                                        icon: item.icon,
                                        selectedIcon: item.selectedIcon,
                                        badgeCount: item.badgeCount,
                                        isActive: item.isActive,
                                        onTap: () {
                                          Navigator.of(context).pop();
                                          item.onTap();
                                        },
                                      ),
                                  ],
                                ),
                                collapsed: false,
                                onToggle: () {},
                              ),
                              SizedBox(height: d.sm),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              appBar: widget.showMobileChrome
                  ? _buildGlassAppBar(
                      context,
                      automaticallyImplyLeading: false,
                      leading: IconButton(
                        tooltip: l10n?.navAllModules ?? 'Open navigation',
                        icon: Icon(AppIcons.menu, size: d.iconMd),
                        onPressed: () =>
                            _tabletScaffoldKey.currentState?.openDrawer(),
                      ),
                      customTitle: widget.breadcrumbs.length > 1
                          ? AppBreadcrumbBar(items: widget.breadcrumbs)
                          : _brandTitle(context),
                    )
                  : null,
              floatingActionButton: widget.floatingActionButton,
              body: SafeArea(
                child: Row(
                  children: [
                    StitchFlowSideNav(
                      title: widget.title,
                      mode: tabletMode,
                      sections: sections,
                      collapsedSectionIds: collapsedSections,
                      onToggleSection: onToggleSection,
                      showExpandControl: false,
                      onToggleCollapseRail: () =>
                          _tabletScaffoldKey.currentState?.openDrawer(),
                      onToggleHide: onToggleHide,
                      onSearchPressed: widget.onSearchPressed,
                      searchTooltip: widget.searchTooltip,
                    ),
                    Expanded(child: transitionBody),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Expanded Desktop / Web (>= 1024dp): 3-state collapsible & hideable
      // grouped Side Navigator + slim glass Top Bar with sidebar toggle.
      final showTopBar =
          widget.breadcrumbs.isNotEmpty ||
          (widget.actions != null && widget.actions!.isNotEmpty) ||
          mode == SidebarMode.hidden;

      final toggleTip = switch (mode) {
        SidebarMode.expanded =>
          l10n?.navSidebarCollapse ?? 'Collapse to compact rail',
        SidebarMode.compactRail =>
          l10n?.navSidebarHide ?? 'Hide sidebar',
        SidebarMode.hidden =>
          l10n?.navSidebarShow ?? 'Show sidebar (Ctrl+B)',
      };

      return ResponsiveShellScope(
        sizeClass: sizeClass,
        hasPersistentChrome: true,
        child: AppGlassBackdrop(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: widget.floatingActionButton,
            body: SafeArea(
              child: Row(
                children: [
                  StitchFlowSideNav(
                    title: widget.title,
                    mode: mode,
                    sections: sections,
                    collapsedSectionIds: collapsedSections,
                    onToggleSection: onToggleSection,
                    onToggleCollapseRail: onToggleExpandedOrRail,
                    onToggleHide: onToggleHide,
                    onSearchPressed: widget.onSearchPressed,
                    searchTooltip: widget.searchTooltip,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        if (showTopBar)
                          _buildGlassAppBar(
                            context,
                            showTitle: false,
                            automaticallyImplyLeading: false,
                            toolbarHeight: d.isCompact ? 38 : 46,
                            leading: IconButton(
                              tooltip: toggleTip,
                              icon: Icon(
                                mode == SidebarMode.hidden
                                    ? AppIcons.menu
                                    : AppIcons.sidebarToggle,
                                size: d.iconMd,
                              ),
                              onPressed: mode == SidebarMode.hidden
                                  ? onToggleHide
                                  : onCycleMode,
                            ),
                            customTitle: widget.breadcrumbs.isNotEmpty
                                ? AppBreadcrumbBar(items: widget.breadcrumbs)
                                : null,
                          ),
                        Expanded(child: transitionBody),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return CallbackShortcuts(
      bindings: _buildKeyboardShortcuts(onToggleSidebar: onCycleMode),
      child: Focus(autofocus: true, child: buildShell()),
    );
  }
}

final class _MoreSheetSectionGroup extends StatelessWidget {
  const _MoreSheetSectionGroup({
    required this.section,
    required this.onItemTap,
  });

  final ResponsiveNavSection section;
  final ValueChanged<ResponsiveNavSectionItem> onItemTap;

  @override
  Widget build(BuildContext context) {
    final d = context.density;
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.surfaceTokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? colorScheme.secondary : colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: EdgeInsets.only(left: d.xs, bottom: d.xs),
          child: Text(
            section.title.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.7,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final twoCol = constraints.maxWidth >= 320;
            final itemWidth = twoCol
                ? (constraints.maxWidth - d.sm) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: d.sm,
              runSpacing: d.sm,
              children: [
                for (final item in section.items)
                  SizedBox(
                    width: itemWidth,
                    child: InkWell(
                      onTap: () => onItemTap(item),
                      borderRadius: d.radiusMdBorder,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: d.sm,
                          vertical: d.isCompact ? d.xs : d.sm,
                        ),
                        decoration: BoxDecoration(
                          color: item.isActive
                              ? (isDark
                                    ? colorScheme.secondary.withValues(
                                        alpha: 0.20,
                                      )
                                    : colorScheme.primaryContainer.withValues(
                                        alpha: 0.75,
                                      ))
                              : tokens.glassFill,
                          borderRadius: d.radiusMdBorder,
                          border: Border.all(
                            color: item.isActive
                                ? activeColor.withValues(alpha: 0.35)
                                : tokens.glassBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.isActive
                                  ? (item.selectedIcon ?? item.icon)
                                  : item.icon,
                              size: d.iconMd,
                              color: item.isActive
                                  ? activeColor
                                  : colorScheme.primary,
                            ),
                            SizedBox(width: d.sm),
                            Expanded(
                              child: Text(
                                item.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      fontWeight: item.isActive
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: item.isActive
                                          ? activeColor
                                          : colorScheme.onSurface,
                                    ),
                              ),
                            ),
                            if (item.badgeCount != null &&
                                item.badgeCount! > 0) ...[
                              SizedBox(width: d.xs),
                              Badge(
                                label: Text(
                                  item.badgeCount! > 99
                                      ? '99+'
                                      : '${item.badgeCount}',
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
