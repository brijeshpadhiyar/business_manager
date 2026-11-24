import 'dart:ui';

import 'package:animations/animations.dart';
import 'package:business_manager/core/config/app_identity.dart';
import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/widgets/app_glass_backdrop.dart';
import 'package:material_ui/material_ui.dart';

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
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

/// Adaptive StitchFlow V1.3 glassmorphism navigation shell with layered ambient
/// backdrop, frosted glass AppBar and Navigation chrome, animated destination
/// selection, and transparent-fill Material 3 fade-through tab transitions:
/// - Compact (`< 600dp`): Mobile frosted glass Bottom `NavigationBar`
/// - Medium (`600..1023dp`): Tablet frosted glass `NavigationRail`
/// - Expanded (`>= 1024dp`): Desktop frosted glass Sidebar (`NavigationDrawer`)
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
    this.floatingActionButton,
  });

  final String title;
  final String? subtitle;
  final List<ResponsiveNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final List<Widget>? actions;
  final List<ResponsiveNavActionItem> sidebarExtraActions;
  final Widget? floatingActionButton;

  Widget _animatedBody(BuildContext context) {
    final reduce = AppMotion.reduceMotion(context);
    if (reduce) {
      return KeyedSubtree(key: ValueKey<int>(selectedIndex), child: body);
    }
    return PageTransitionSwitcher(
      duration: AppMotion.normal,
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          AppIdentity.symbolPngAsset,
          width: 26,
          height: 26,
          errorBuilder: (_, _, _) => const Icon(Icons.auto_awesome, size: 22),
        ),
        const SizedBox(width: AppSpacing.sm),
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
  }) {
    final tokens = context.surfaceTokens;
    return AppBar(
      toolbarHeight: AppSizing.appBarHeight,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: showTitle ? _brandTitle(context) : null,
      actions: actions,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final sizeClass = AppBreakpoints.fromWidth(width);
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = context.surfaceTokens;
    final transitionBody = _animatedBody(context);

    if (sizeClass.isCompact) {
      return AppGlassBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildGlassAppBar(context),
          body: SafeArea(child: transitionBody),
          floatingActionButton: floatingActionButton,
          bottomNavigationBar: RepaintBoundary(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppRadius.xl),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.navGlassFill,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.xl),
                    ),
                    border: Border(
                      top: BorderSide(color: tokens.navGlassBorder, width: 1.1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: tokens.cardShadow,
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: NavigationBar(
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onDestinationSelected,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    animationDuration: AppMotion.duration(
                      context,
                      AppMotion.normal,
                    ),
                    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
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
      );
    }

    if (sizeClass.isMedium) {
      return AppGlassBackdrop(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: _buildGlassAppBar(context),
          floatingActionButton: floatingActionButton,
          body: SafeArea(
            child: Row(
              children: [
                RepaintBoundary(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
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
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minHeight: constraints.maxHeight,
                                  ),
                                  child: IntrinsicHeight(
                                    child: NavigationRail(
                                      selectedIndex: selectedIndex,
                                      onDestinationSelected:
                                          onDestinationSelected,
                                      backgroundColor: Colors.transparent,
                                      labelType: NavigationRailLabelType.all,
                                      destinations: destinations
                                          .map(
                                            (d) => NavigationRailDestination(
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
      );
    }

    // Expanded desktop frosted glass sidebar
    return AppGlassBackdrop(
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
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
                          selectedIndex: selectedIndex,
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
                            const SizedBox(height: AppSpacing.sm),
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
                              ...sidebarExtraActions.map(
                                (item) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: 2,
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    leading: Icon(
                                      item.icon,
                                      size: AppSizing.iconMd,
                                      color: colorScheme.secondary,
                                    ),
                                    title: Text(
                                      item.label,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.labelLarge,
                                    ),
                                    onTap: item.onTap,
                                  ),
                                ),
                              ),
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
                    if (actions != null && actions!.isNotEmpty)
                      _buildGlassAppBar(
                        context,
                        showTitle: false,
                        automaticallyImplyLeading: false,
                      ),
                    Expanded(child: transitionBody),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
