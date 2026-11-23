import 'package:business_manager/core/design_system/app_breakpoints.dart';
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

/// Adaptive navigation shell:
/// - Compact (`< 600dp`): Mobile Bottom `NavigationBar`
/// - Medium (`600..1023dp`): Tablet `NavigationRail`
/// - Expanded (`>= 1024dp`): Desktop permanent Sidebar (`NavigationDrawer`)
final class ResponsiveNavigation extends StatelessWidget {
  const ResponsiveNavigation({
    super.key,
    required this.title,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final List<ResponsiveNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final sizeClass = AppBreakpoints.fromWidth(width);

    if (sizeClass.isCompact) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: AppSizing.appBarHeight,
          title: Text(title),
          actions: actions,
        ),
        body: SafeArea(child: body),
        floatingActionButton: floatingActionButton,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
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
      );
    }

    if (sizeClass.isMedium) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: AppSizing.appBarHeight,
          title: Text(title),
          actions: actions,
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
              Expanded(child: body),
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
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge,
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
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
