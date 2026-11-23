import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/design_system_showcase_page.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/accounting/presentation/pages/accounting_overview_page.dart';
import 'package:business_manager/features/accounting/presentation/pages/payment_form_page.dart';
import 'package:business_manager/features/accounting/presentation/pages/worker_adjustment_form_page.dart';
import 'package:business_manager/features/accounting/presentation/pages/worker_ledger_page.dart';
import 'package:business_manager/features/backup/presentation/pages/backup_restore_page.dart';
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
import 'package:business_manager/features/reports/presentation/pages/reports_page.dart';
import 'package:business_manager/features/stock_movements/presentation/pages/damaged_repair_page.dart';
import 'package:business_manager/features/stock_movements/presentation/pages/stock_issue_page.dart';
import 'package:business_manager/features/stock_movements/presentation/pages/stock_movements_page.dart';
import 'package:business_manager/features/stock_movements/presentation/pages/stock_settlement_page.dart';
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
        pageBuilder: (context, state) => AppMotion.buildPage(
          state: state,
          child: LotDetailPage(lotId: state.pathParameters['id']!),
        ),
      ),
      // Processes
      GoRoute(
        path: RoutePaths.processCreate,
        pageBuilder: (context, state) =>
            AppMotion.buildPage(state: state, child: const ProcessFormPage()),
      ),
      GoRoute(
        path: RoutePaths.processDetailPattern,
        pageBuilder: (context, state) => AppMotion.buildPage(
          state: state,
          child: ProcessDetailPage(processId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: RoutePaths.processEditPattern,
        pageBuilder: (context, state) => AppMotion.buildPage(
          state: state,
          child: ProcessFormPage(processId: state.pathParameters['id']!),
        ),
      ),
      // Workers, Assignments & Historical Rates
      GoRoute(
        path: RoutePaths.workerCreate,
        pageBuilder: (context, state) =>
            AppMotion.buildPage(state: state, child: const WorkerFormPage()),
      ),
      GoRoute(
        path: RoutePaths.workerDetailPattern,
        pageBuilder: (context, state) => AppMotion.buildPage(
          state: state,
          child: WorkerDetailPage(workerId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: RoutePaths.workerEditPattern,
        pageBuilder: (context, state) => AppMotion.buildPage(
          state: state,
          child: WorkerFormPage(workerId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: RoutePaths.workerAssignmentsPattern,
        pageBuilder: (context, state) => AppMotion.buildPage(
          state: state,
          child: WorkerAssignmentsPage(workerId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: RoutePaths.workerRatesPattern,
        pageBuilder: (context, state) => AppMotion.buildPage(
          state: state,
          child: RateHistoryPage(
            workerId: state.pathParameters['id']!,
            processId: state.uri.queryParameters['processId'],
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.workerRateCreatePattern,
        pageBuilder: (context, state) => AppMotion.buildPage(
          state: state,
          child: RateFormPage(
            workerId: state.pathParameters['id']!,
            initialProcessId: state.uri.queryParameters['processId'],
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.workerRateEditPattern,
        pageBuilder: (context, state) => AppMotion.buildPage(
          state: state,
          child: RateFormPage(
            workerId: state.pathParameters['id']!,
            rateId: state.pathParameters['rateId']!,
          ),
        ),
      ),
      // Milestone 6 — Stock Movements
      GoRoute(
        path: RoutePaths.stockMovements,
        pageBuilder: (context, state) => AppMotion.buildPage(
          state: state,
          child: const StockMovementsPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.stockIssuePath,
        pageBuilder: (context, state) => AppMotion.buildPage(
          state: state,
          child: StockIssuePage(
            initialDesignColourId: state.uri.queryParameters['designColourId'],
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.stockReturnPattern,
        pageBuilder: (context, state) => AppMotion.buildPage(
          state: state,
          child: StockSettlementPage(issueId: state.pathParameters['issueId']!),
        ),
      ),
      GoRoute(
        path: RoutePaths.stockRepair,
        pageBuilder: (context, state) =>
            AppMotion.buildPage(state: state, child: const DamagedRepairPage()),
      ),
      // Milestone 7 — Labour, Worker Ledger & Payments
      GoRoute(
        path: RoutePaths.accounting,
        pageBuilder: (context, state) => AppMotion.buildPage(
          state: state,
          child: const AccountingOverviewPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.workerLedgerPattern,
        pageBuilder: (context, state) => AppMotion.buildPage(
          state: state,
          child: WorkerLedgerPage(workerId: state.pathParameters['id']!),
        ),
      ),
      GoRoute(
        path: RoutePaths.paymentCreatePath,
        pageBuilder: (context, state) => AppMotion.buildPage(
          state: state,
          child: PaymentFormPage(
            initialWorkerId: state.uri.queryParameters['workerId'],
          ),
        ),
      ),
      GoRoute(
        path: RoutePaths.workerAdjustmentCreatePattern,
        pageBuilder: (context, state) => AppMotion.buildPage(
          state: state,
          child: WorkerAdjustmentFormPage(
            workerId: state.pathParameters['id']!,
          ),
        ),
      ),
      // Milestone 8 — Backup & Restore
      GoRoute(
        path: RoutePaths.backupRestore,
        pageBuilder: (context, state) =>
            AppMotion.buildPage(state: state, child: const BackupRestorePage()),
      ),
      // Milestone 9 — Business Reports
      GoRoute(
        path: RoutePaths.reports,
        pageBuilder: (context, state) =>
            AppMotion.buildPage(state: state, child: const ReportsPage()),
      ),
      GoRoute(
        path: RoutePaths.showcase,
        pageBuilder: (context, state) => AppMotion.buildPage(
          state: state,
          child: DesignSystemShowcasePage(config: config),
        ),
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
      subtitle: l10n.appTagline,
      selectedIndex: _selectedIndex,
      onDestinationSelected: (index) => setState(() => _selectedIndex = index),
      actions: [
        AppIconButton(
          icon: Icons.swap_horiz_rounded,
          tooltip: l10n.navStockMovements,
          onPressed: () => context.push(RoutePaths.stockMovements),
        ),
        AppIconButton(
          icon: Icons.account_balance_wallet_outlined,
          tooltip: l10n.navAccounting,
          onPressed: () => context.push(RoutePaths.accounting),
        ),
        AppIconButton(
          icon: Icons.analytics_outlined,
          tooltip: l10n.navReports,
          onPressed: () => context.push(RoutePaths.reports),
        ),
      ],
      sidebarExtraActions: [
        ResponsiveNavActionItem(
          label: l10n.navStockMovements,
          icon: Icons.swap_horiz_rounded,
          onTap: () => context.push(RoutePaths.stockMovements),
        ),
        ResponsiveNavActionItem(
          label: l10n.navAccounting,
          icon: Icons.account_balance_wallet_outlined,
          onTap: () => context.push(RoutePaths.accounting),
        ),
        ResponsiveNavActionItem(
          label: l10n.navReports,
          icon: Icons.analytics_outlined,
          onTap: () => context.push(RoutePaths.reports),
        ),
        ResponsiveNavActionItem(
          label: l10n.navBackupRestore,
          icon: Icons.backup_outlined,
          onTap: () => context.push(RoutePaths.backupRestore),
        ),
      ],
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
