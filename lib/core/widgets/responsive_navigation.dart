import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:business_manager/core/config/app_identity.dart';
import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_shadows.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/widgets/app_breadcrumb_bar.dart';
import 'package:business_manager/core/widgets/app_glass_backdrop.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

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
  });

  final String label;
  final IconData icon;
  final IconData? selectedIcon;
}

final class ResponsiveNavActionItem {
  const ResponsiveNavActionItem({
    required this.label,
    required this.icon,
    required this.onTap,
    this.id,
  });

  final String? id;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

/// Adaptive StitchFlow glassmorphism navigation shell with layered ambient
/// backdrop, frosted glass AppBar and Navigation chrome, active state tracking,
/// Desktop breadcrumbs, and keyboard shortcuts (`Alt+1..5`):
/// - Compact (`< 600dp`): Mobile frosted glass Bottom `NavigationBar` (on root
///   tabs) or clean full-screen child route when [showMobileChrome] is `false`.
/// - Medium (`600..1023dp`): Persistent Tablet frosted glass `NavigationRail`
///   plus optional overflow drawer for secondary modules.
/// - Expanded (`>= 1024dp`): Persistent Desktop frosted glass Sidebar
///   (`NavigationDrawer`) with active highlight across both primary & secondary
///   destinations and top Breadcrumb bar.
final class ResponsiveNavigation extends StatelessWidget {
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
    this.breadcrumbs = const [],
    this.showMobileChrome = true,
    this.floatingActionButton,
    this.enableBodyTransition = false,
    this.extraShortcuts = const {},
    this.compactActions,
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
  final List<AppBreadcrumbItem> breadcrumbs;
  final bool showMobileChrome;
  final Widget? floatingActionButton;
  final bool enableBodyTransition;

  /// App-level keyboard shortcuts (for example Ctrl+K search, Esc back),
  /// active anywhere inside the shell on desktop and web.
  final Map<ShortcutActivator, VoidCallback> extraShortcuts;

  /// Toolbar actions for compact screens (phones, narrow windows). Falls back
  /// to [actions] when null.
  final List<Widget>? compactActions;

  Widget _animatedBody(BuildContext context) {
    if (!enableBodyTransition || AppMotion.reduceMotion(context)) {
      return body;
    }
    return PageTransitionSwitcher(
      duration: AppMotion.fast,
      transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
        return FadeThroughTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          fillColor: Colors.transparent,
          child: child,
        );
      },
      child: KeyedSubtree(key: ValueKey<int>(selectedIndex), child: body),
    );
  }

  Widget _brandTitle(BuildContext context) {
    final showLogo = MediaQuery.sizeOf(context).width >= 360;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLogo) ...[
          Image.asset(
            AppIdentity.symbolPngAsset,
            width: 26,
            height: 26,
            cacheWidth: 96,
            cacheHeight: 96,
            errorBuilder: (_, _, _) => const Icon(Icons.auto_awesome, size: 22),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Flexible(
          child: Text(title, overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildGlassAppBar(
    BuildContext context, {
    bool showTitle = true,
    bool automaticallyImplyLeading = true,
    Widget? customTitle,
    double toolbarHeight = AppSizing.appBarHeight,
    List<Widget>? actionsOverride,
  }) {
    final tokens = context.surfaceTokens;
    return AppBar(
      toolbarHeight: toolbarHeight,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: customTitle ?? (showTitle ? _brandTitle(context) : null),
      actions: actionsOverride ?? actions,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          enabled: false, // v1.4 soft elevation: opaque surfaces
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

  Widget _animatedNavIcon(
    BuildContext context,
    IconData icon, {
    required bool selected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = selected
        ? (isDark ? colorScheme.secondary : colorScheme.primary)
        : colorScheme.onSurfaceVariant;

    return AnimatedScale(
      scale: selected ? 1.12 : 1.0,
      duration: AppMotion.duration(context, AppMotion.fast),
      curve: AppMotion.standardCurve,
      child: Icon(icon, size: AppSizing.iconMd, color: iconColor),
    );
  }

  Map<ShortcutActivator, VoidCallback> _buildKeyboardShortcuts() {
    final map = <ShortcutActivator, VoidCallback>{};
    const digitKeys = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
    ];
    for (var i = 0; i < destinations.length && i < digitKeys.length; i++) {
      final idx = i;
      map[SingleActivator(digitKeys[i], alt: true)] = () =>
          onDestinationSelected(idx);
    }
    map.addAll(extraShortcuts);
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final sizeClass = AppBreakpoints.fromWidth(width);
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.surfaceTokens;
    final transitionBody = _animatedBody(context);

    Widget buildShell() {
      if (sizeClass.isCompact) {
        if (!showMobileChrome) {
          return ResponsiveShellScope(
            sizeClass: sizeClass,
            hasPersistentChrome: false,
            child: Material(
              type: MaterialType.transparency,
              child: transitionBody,
            ),
          );
        }

        return ResponsiveShellScope(
          sizeClass: sizeClass,
          hasPersistentChrome: true,
          child: AppGlassBackdrop(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: _buildGlassAppBar(
                context,
                actionsOverride: compactActions,
              ),
              body: SafeArea(child: transitionBody),
              floatingActionButton: floatingActionButton,
              bottomNavigationBar: RepaintBoundary(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.xl),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    enabled: false, // v1.4 soft elevation: opaque surfaces
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: tokens.navGlassFill,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.xl),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: tokens.navGlassBorder,
                            width: 1.1,
                          ),
                        ),
                        boxShadow: [
                          for (final sh in AppShadows.of(context).lg)
                            sh.copyWith(offset: Offset(0, -sh.offset.dy)),
                        ],
                      ),
                      child: NavigationBar(
                        selectedIndex: selectedIndex.clamp(
                          0,
                          destinations.length - 1,
                        ),
                        onDestinationSelected: onDestinationSelected,
                        backgroundColor: Colors.transparent,
                        surfaceTintColor: Colors.transparent,
                        elevation: 0,
                        animationDuration: AppMotion.duration(
                          context,
                          AppMotion.normal,
                        ),
                        labelBehavior:
                            NavigationDestinationLabelBehavior.alwaysShow,
                        destinations: [
                          for (int i = 0; i < destinations.length; i++)
                            NavigationDestination(
                              icon: _animatedNavIcon(
                                context,
                                destinations[i].icon,
                                selected: false,
                              ),
                              selectedIcon: _animatedNavIcon(
                                context,
                                destinations[i].selectedIcon ??
                                    destinations[i].icon,
                                selected: true,
                              ),
                              label: destinations[i].label,
                              tooltip: destinations[i].label,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }

      if (sizeClass.isMedium) {
        final safeSelected = activeExtraActionId != null
            ? null
            : selectedIndex.clamp(0, destinations.length - 1);
        return ResponsiveShellScope(
          sizeClass: sizeClass,
          hasPersistentChrome: true,
          child: AppGlassBackdrop(
            child: Scaffold(
              backgroundColor: Colors.transparent,
              drawer: sidebarExtraActions.isNotEmpty
                  ? Drawer(
                      child: SafeArea(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.md,
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.sm,
                              ),
                              child: _brandTitle(context),
                            ),
                            const Divider(),
                            for (final item in sidebarExtraActions)
                              ListTile(
                                selected:
                                    item.id != null &&
                                    item.id == activeExtraActionId,
                                leading: Icon(
                                  item.icon,
                                  size: AppSizing.iconMd,
                                ),
                                title: Text(item.label),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  item.onTap();
                                },
                              ),
                          ],
                        ),
                      ),
                    )
                  : null,
              appBar: showMobileChrome
                  ? _buildGlassAppBar(
                      context,
                      customTitle: breadcrumbs.length > 1
                          ? AppBreadcrumbBar(items: breadcrumbs)
                          : _brandTitle(context),
                    )
                  : null,
              floatingActionButton: floatingActionButton,
              body: SafeArea(
                child: Row(
                  children: [
                    RepaintBoundary(
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          enabled:
                              false, // v1.4 soft elevation: opaque surfaces
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
                            child: LayoutBuilder(
                              builder: (context, railConstraints) =>
                                  SingleChildScrollView(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        minHeight: railConstraints.maxHeight,
                                      ),
                                      child: IntrinsicHeight(
                                        child: NavigationRail(
                                          selectedIndex: safeSelected,
                                          onDestinationSelected:
                                              onDestinationSelected,
                                          backgroundColor: Colors.transparent,
                                          labelType:
                                              NavigationRailLabelType.all,
                                          destinations: destinations
                                              .map(
                                                (d) =>
                                                    NavigationRailDestination(
                                                      icon: _animatedNavIcon(
                                                        context,
                                                        d.icon,
                                                        selected: false,
                                                      ),
                                                      selectedIcon:
                                                          _animatedNavIcon(
                                                            context,
                                                            d.selectedIcon ??
                                                                d.icon,
                                                            selected: true,
                                                          ),
                                                      label: Text(d.label),
                                                    ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(child: transitionBody),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      // Expanded desktop frosted glass sidebar with active extra items &
      // top breadcrumb bar.
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final showTopBar =
          breadcrumbs.isNotEmpty || (actions != null && actions!.isNotEmpty);
      final safeDesktopSelected = activeExtraActionId != null
          ? null
          : selectedIndex.clamp(0, destinations.length - 1);

      return ResponsiveShellScope(
        sizeClass: sizeClass,
        hasPersistentChrome: true,
        child: AppGlassBackdrop(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            floatingActionButton: floatingActionButton,
            body: SafeArea(
              child: Row(
                children: [
                  RepaintBoundary(
                    child: SizedBox(
                      width: AppSizing.desktopSidebarWidth,
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          enabled:
                              false, // v1.4 soft elevation: opaque surfaces
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
                            child: NavigationDrawer(
                              selectedIndex: safeDesktopSelected,
                              onDestinationSelected: onDestinationSelected,
                              backgroundColor: Colors.transparent,
                              surfaceTintColor: Colors.transparent,
                              elevation: 0,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    AppSpacing.lg,
                                    AppSpacing.lg,
                                    AppSpacing.lg,
                                    AppSpacing.md,
                                  ),
                                  child: Row(
                                    children: [
                                      Image.asset(
                                        AppIdentity.symbolPngAsset,
                                        width: 34,
                                        height: 34,
                                        cacheWidth: 96,
                                        cacheHeight: 96,
                                        errorBuilder: (_, _, _) =>
                                            const Icon(Icons.auto_awesome),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              title,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            if (subtitle != null)
                                              Text(
                                                subtitle!,
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(),
                                const SizedBox(height: AppSpacing.xs),
                                ...destinations.map(
                                  (d) => NavigationDrawerDestination(
                                    icon: _animatedNavIcon(
                                      context,
                                      d.icon,
                                      selected: false,
                                    ),
                                    selectedIcon: _animatedNavIcon(
                                      context,
                                      d.selectedIcon ?? d.icon,
                                      selected: true,
                                    ),
                                    label: Flexible(
                                      child: Text(
                                        d.label,
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                if (sidebarExtraActions.isNotEmpty) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                      vertical: AppSpacing.sm,
                                    ),
                                    child: Divider(),
                                  ),
                                  ...sidebarExtraActions.map((item) {
                                    final isActive =
                                        item.id != null &&
                                        item.id == activeExtraActionId;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: 2,
                                      ),
                                      child: ListTile(
                                        dense: true,
                                        selected: isActive,
                                        selectedTileColor: colorScheme.secondary
                                            .withValues(
                                              alpha: isDark ? 0.26 : 0.16,
                                            ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: AppRadius.mdBorder,
                                          side: isActive
                                              ? BorderSide(
                                                  color: colorScheme.secondary
                                                      .withValues(
                                                        alpha: isDark
                                                            ? 0.36
                                                            : 0.24,
                                                      ),
                                                )
                                              : BorderSide.none,
                                        ),
                                        leading: Icon(
                                          item.icon,
                                          size: AppSizing.iconMd,
                                          color: isActive
                                              ? (isDark
                                                    ? colorScheme.secondary
                                                    : colorScheme.primary)
                                              : colorScheme.secondary,
                                        ),
                                        title: Text(
                                          item.label,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelLarge
                                              ?.copyWith(
                                                fontWeight: isActive
                                                    ? FontWeight.w700
                                                    : FontWeight.w500,
                                              ),
                                        ),
                                        onTap: item.onTap,
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        if (showTopBar)
                          _buildGlassAppBar(
                            context,
                            showTitle: false,
                            automaticallyImplyLeading: false,
                            toolbarHeight: 44,
                            customTitle: breadcrumbs.isNotEmpty
                                ? AppBreadcrumbBar(items: breadcrumbs)
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
      bindings: _buildKeyboardShortcuts(),
      child: buildShell(),
    );
  }
}
