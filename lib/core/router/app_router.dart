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
import 'package:business_manager/features/processes/presentation/pages/process_detail_page.dart';
import 'package:business_manager/features/processes/presentation/pages/process_form_page.dart';
import 'package:business_manager/features/processes/presentation/pages/process_list_page.dart';
import 'package:business_manager/features/rates/presentation/pages/rate_form_page.dart';
import 'package:business_manager/features/rates/presentation/pages/rate_history_page.dart';
import 'package:business_manager/features/workers/presentation/pages/worker_assignments_page.dart';
import 'package:business_manager/features/workers/presentation/pages/worker_detail_page.dart';
import 'package:business_manager/features/workers/presentation/pages/worker_form_page.dart';
import 'package:business_manager/features/workers/presentation/pages/worker_list_page.dart';
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
      // Processes
      GoRoute(
        path: RoutePaths.processCreate,
        builder: (context, state) => const ProcessFormPage(),
      ),
      GoRoute(
        path: RoutePaths.processDetailPattern,
        builder: (context, state) =>
            ProcessDetailPage(processId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.processEditPattern,
        builder: (context, state) =>
            ProcessFormPage(processId: state.pathParameters['id']!),
      ),
      // Workers, Assignments & Historical Rates
      GoRoute(
        path: RoutePaths.workerCreate,
        builder: (context, state) => const WorkerFormPage(),
      ),
      GoRoute(
        path: RoutePaths.workerDetailPattern,
        builder: (context, state) =>
            WorkerDetailPage(workerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.workerEditPattern,
        builder: (context, state) =>
            WorkerFormPage(workerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.workerAssignmentsPattern,
        builder: (context, state) =>
            WorkerAssignmentsPage(workerId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: RoutePaths.workerRatesPattern,
        builder: (context, state) => RateHistoryPage(
          workerId: state.pathParameters['id']!,
          processId: state.uri.queryParameters['processId'],
        ),
      ),
      GoRoute(
        path: RoutePaths.workerRateCreatePattern,
        builder: (context, state) => RateFormPage(
          workerId: state.pathParameters['id']!,
          initialProcessId: state.uri.queryParameters['processId'],
        ),
      ),
      GoRoute(
        path: RoutePaths.workerRateEditPattern,
        builder: (context, state) => RateFormPage(
          workerId: state.pathParameters['id']!,
          rateId: state.pathParameters['rateId']!,
        ),
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
          label: l10n.navProcesses,
          icon: Icons.precision_manufacturing_outlined,
          selectedIcon: Icons.precision_manufacturing,
        ),
        ResponsiveNavDestination(
          label: l10n.navWorkers,
          icon: Icons.people_outline,
          selectedIcon: Icons.people,
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
        2 => const ProcessListPage(),
        3 => const WorkerListPage(),
        4 => const InventoryOverviewPage(),
        _ => const BusinessProfilePage(),
      },
    );
  }
}
