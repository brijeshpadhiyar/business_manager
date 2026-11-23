import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/design_system/design_system_showcase_page.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/business_profile/presentation/pages/business_profile_page.dart';
import 'package:business_manager/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:business_manager/features/inventory/presentation/pages/inventory_overview_page.dart';
import 'package:business_manager/features/lots/presentation/pages/lot_detail_page.dart';
import 'package:business_manager/features/lots/presentation/pages/lot_list_page.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

GoRouter createAppRouter(AppConfig config) {
  return GoRouter(
    initialLocation: RoutePaths.home,
    routes: [
      GoRoute(
        path: RoutePaths.home,
        builder: (context, state) => StitchFlowShellPage(config: config),
      ),
      GoRoute(
        path: RoutePaths.lotDetailPattern,
        builder: (context, state) =>
            LotDetailPage(lotId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.showcase,
        builder: (context, state) => DesignSystemShowcasePage(config: config),
      ),
    ],
  );
}

final class StitchFlowShellPage extends StatefulWidget {
  const StitchFlowShellPage({super.key, required this.config});

  final AppConfig config;

  @override
  State<StitchFlowShellPage> createState() => _StitchFlowShellPageState();
}

final class _StitchFlowShellPageState extends State<StitchFlowShellPage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appTitle = widget.config.isDev ? l10n.appTitleDev : l10n.appTitle;

    return ResponsiveNavigation(
      title: appTitle,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      destinations: [
        ResponsiveNavDestination(
          label: l10n.navDashboard,
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
        ),
        ResponsiveNavDestination(
          label: l10n.navLots,
          icon: Icons.inventory_2_outlined,
          selectedIcon: Icons.inventory_2,
        ),
        ResponsiveNavDestination(
          label: l10n.navInventory,
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart,
        ),
        ResponsiveNavDestination(
          label: l10n.navBusinessProfile,
          icon: Icons.storefront_outlined,
          selectedIcon: Icons.storefront,
        ),
      ],
      body: switch (_selectedIndex) {
        0 => DashboardPage(
          config: widget.config,
          onNavigateTab: (idx) => setState(() => _selectedIndex = idx),
        ),
        1 => const LotListPage(),
        2 => const InventoryOverviewPage(),
        _ => const BusinessProfilePage(),
      },
    );
  }
}
