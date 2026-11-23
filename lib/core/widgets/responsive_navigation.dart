import 'package:animations/animations.dart';
import 'package:business_manager/core/config/app_identity.dart';
import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
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

/// Adaptive StitchFlow navigation shell with smooth Material 3 fade-through
/// tab transitions and branded header:
/// - Compact (`< 600dp`): Mobile Bottom `NavigationBar`
/// - Medium (`600..1023dp`): Tablet scrollable `NavigationRail`
/// - Expanded (`>= 1024dp`): Desktop permanent Sidebar (`NavigationDrawer`)
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
      duration: AppMotion.fast,
      transitionBuilder: (child, primaryAnimation, secondaryAnimation) {
        return FadeThroughTransition(
          animation: primaryAnimation,
          secondaryAnimation: secondaryAnimation,
          fillColor: Theme.of(context).colorScheme.surface,
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

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final sizeClass = AppBreakpoints.fromWidth(width);
    final colorScheme = Theme.of(context).colorScheme;
    final transitionBody = _animatedBody(context);

    if (sizeClass.isCompact) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: AppSizing.appBarHeight,
          title: _brandTitle(context),
          actions: actions,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
        body: SafeArea(child: transitionBody),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: colorScheme.outlineVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: destinations
                .map(
                  (d) => NavigationDestination(
                    icon: Icon(d.icon, size: AppSizing.iconMd),
                    selectedIcon: Icon(
                      d.selectedIcon ?? d.icon,
                      size: AppSizing.iconMd,
                    ),
                    label: d.label,
                  ),
                )
                .toList(),
          ),
        ),
      );
    }

    if (sizeClass.isMedium) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: AppSizing.appBarHeight,
          title: _brandTitle(context),
          actions: actions,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
          ),
        ),
        floatingActionButton: floatingActionButton,
        body: SafeArea(
          child: Row(
            children: [
              LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: NavigationRail(
                        selectedIndex: selectedIndex,
                        onDestinationSelected: onDestinationSelected,
                        labelType: NavigationRailLabelType.all,
                        destinations: destinations
                            .map(
                              (d) => NavigationRailDestination(
                                icon: Icon(d.icon, size: AppSizing.iconMd),
                                selectedIcon: Icon(
                                  d.selectedIcon ?? d.icon,
                                  size: AppSizing.iconMd,
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
              const VerticalDivider(width: 1),
              Expanded(child: transitionBody),
            ],
          ),
        ),
      );
    }

    // Expanded desktop sidebar
    return Scaffold(
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: AppSizing.desktopSidebarWidth,
              child: NavigationDrawer(
                selectedIndex: selectedIndex,
                onDestinationSelected: onDestinationSelected,
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                              if (subtitle != null)
                                Text(
                                  subtitle!,
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
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
                      icon: Icon(d.icon, size: AppSizing.iconMd),
                      selectedIcon: Icon(
                        d.selectedIcon ?? d.icon,
                        size: AppSizing.iconMd,
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
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                          onTap: item.onTap,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  if (actions != null && actions!.isNotEmpty)
                    AppBar(
                      toolbarHeight: AppSizing.appBarHeight,
                      automaticallyImplyLeading: false,
                      actions: actions,
                    ),
                  Expanded(child: transitionBody),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
