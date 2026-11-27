import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/services/app_message_service.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/accounting/presentation/pages/accounting_overview_page.dart';
import 'package:business_manager/features/accounting/presentation/pages/payment_form_page.dart';
import 'package:business_manager/features/accounting/presentation/pages/worker_adjustment_form_page.dart';
import 'package:business_manager/features/accounting/presentation/pages/worker_ledger_page.dart';
import 'package:business_manager/features/auth/presentation/pages/account_settings_page.dart';
import 'package:business_manager/features/auth/presentation/pages/login_page.dart';
import 'package:business_manager/features/backup/presentation/pages/backup_restore_page.dart';
import 'package:business_manager/features/backup/presentation/pages/data_health_page.dart';
import 'package:business_manager/features/sync/domain/entities/sync_entities.dart';
import 'package:business_manager/features/sync/presentation/bloc/sync_cubit.dart';
import 'package:business_manager/features/sync/presentation/pages/sync_conflict_inspector_page.dart';
import 'package:business_manager/features/team/presentation/pages/team_management_page.dart';
import 'package:business_manager/features/business_profile/presentation/pages/business_profile_page.dart';
import 'package:business_manager/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';
import 'package:business_manager/features/guidance/presentation/registry/guide_target_registry.dart';
import 'package:business_manager/features/guidance/presentation/widgets/guide_quick_menu_sheet.dart';
import 'package:business_manager/features/inventory/presentation/pages/inventory_overview_page.dart';
import 'package:business_manager/features/lots/presentation/pages/designs_colours_page.dart';
import 'package:business_manager/features/lots/presentation/pages/lot_colour_detail_page.dart';
import 'package:business_manager/features/lots/presentation/pages/lot_create_page.dart';
import 'package:business_manager/features/lots/presentation/pages/lot_detail_page.dart';
import 'package:business_manager/features/lots/presentation/pages/lot_list_page.dart';
import 'package:business_manager/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:business_manager/features/process_routing/presentation/pages/job_process_routing_page.dart';
import 'package:business_manager/features/processes/presentation/pages/process_detail_page.dart';
import 'package:business_manager/features/processes/presentation/pages/process_form_page.dart';
import 'package:business_manager/features/processes/presentation/pages/process_list_page.dart';
import 'package:business_manager/features/production_history/presentation/pages/inspection_queue_page.dart';
import 'package:business_manager/features/production_history/presentation/pages/lot_history_page.dart';
import 'package:business_manager/features/production_history/presentation/pages/lot_timeline_page.dart';
import 'package:business_manager/features/production_history/presentation/pages/process_history_page.dart';
import 'package:business_manager/features/production_history/presentation/pages/production_history_dashboard_page.dart';
import 'package:business_manager/features/production_history/presentation/pages/production_transaction_detail_page.dart';
import 'package:business_manager/features/production_history/presentation/pages/worker_production_history_page.dart';
import 'package:business_manager/features/rates/presentation/pages/rate_form_page.dart';
import 'package:business_manager/features/rates/presentation/pages/rate_history_page.dart';
import 'package:business_manager/features/reports/presentation/pages/daily_summary_page.dart';
import 'package:business_manager/features/reports/presentation/pages/reports_page.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:business_manager/features/security/presentation/pages/pin_setup_page.dart';
import 'package:business_manager/features/security/presentation/pages/security_settings_page.dart';
import 'package:business_manager/features/settings/presentation/pages/about_stitchflow_page.dart';
import 'package:business_manager/features/settings/presentation/pages/appearance_settings_page.dart';
import 'package:business_manager/features/settings/presentation/pages/help_guidance_page.dart';
import 'package:business_manager/features/settings/presentation/pages/settings_home_page.dart';
import 'package:business_manager/features/settings/presentation/pages/stock_labour_settings_page.dart';
import 'package:business_manager/features/search/presentation/global_search_dialog.dart';
import 'package:business_manager/features/stock_movements/presentation/pages/damaged_repair_page.dart';
import 'package:business_manager/features/stock_movements/presentation/pages/receive_return_picker_page.dart';
import 'package:business_manager/features/stock_movements/presentation/pages/stock_issue_page.dart';
import 'package:business_manager/features/stock_movements/presentation/pages/stock_movements_page.dart';
import 'package:business_manager/features/stock_movements/presentation/pages/stock_settlement_page.dart';
import 'package:business_manager/features/sync/presentation/pages/sync_center_page.dart';
import 'package:business_manager/features/sync/presentation/widgets/sync_status_badge.dart';
import 'package:business_manager/features/workers/presentation/pages/worker_assignments_page.dart';
import 'package:business_manager/features/workers/presentation/pages/worker_detail_page.dart';
import 'package:business_manager/features/workers/presentation/pages/worker_form_page.dart';
import 'package:business_manager/features/workers/presentation/pages/worker_list_page.dart';
import 'package:flutter/foundation.dart'
    show ValueListenable, ValueNotifier, defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

const List<String> _primaryTabRoutes = [
  RoutePaths.home,
  RoutePaths.lots,
  RoutePaths.stockMovements,
  RoutePaths.workers,
  RoutePaths.processes,
  RoutePaths.settings,
];

/// Coordinates silent background data refreshes when revisiting an already-alive
/// primary tab branch inside [StatefulShellRoute], avoiding skeleton flashes.
final class PrimaryTabRefreshBus {
  PrimaryTabRefreshBus()
    : _signals = List<ValueNotifier<int>>.generate(
        _primaryTabRoutes.length,
        (_) => ValueNotifier<int>(0),
        growable: false,
      );

  final List<ValueNotifier<int>> _signals;
  final Set<int> _visited = <int>{0};

  ValueListenable<int> signalFor(int index) => _signals[index];

  void onTabSelected(int index) {
    final safe = index.clamp(0, _signals.length - 1);
    if (_visited.contains(safe)) {
      _signals[safe].value++;
    } else {
      _visited.add(safe);
    }
  }
}

GoRouter createAppRouter(AppConfig config) {
  final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  final shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');
  final tabRefreshBus = PrimaryTabRefreshBus();

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.home,
    routes: [
      ShellRoute(
        navigatorKey: shellNavigatorKey,
        builder: (context, state, child) => StitchFlowShellScaffold(
          config: config,
          location: state.uri.path,
          tabRefreshBus: tabRefreshBus,
          child: child,
        ),
        routes: [
          // 6 primary tabs kept alive in memory via StatefulShellRoute.
          // On mobile (< 600dp), _PrimaryTabsViewport owns the AppBar and
          // Bottom NavigationBar inside this page so pushed sibling routes
          // slide cleanly OVER it without ever unmounting/swapping shell chrome.
          StatefulShellRoute(
            pageBuilder: (context, state, navigationShell) =>
                MaterialPage<void>(key: state.pageKey, child: navigationShell),
            navigatorContainerBuilder: (context, navigationShell, children) {
              return _PrimaryTabsViewport(
                config: config,
                navigationShell: navigationShell,
                tabRefreshBus: tabRefreshBus,
                children: children,
              );
            },
            branches: [
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: RoutePaths.home,
                    pageBuilder: (context, state) => NoTransitionPage<void>(
                      key: state.pageKey,
                      child: DashboardPage(
                        config: config,
                        refreshSignal: tabRefreshBus.signalFor(0),
                        onNavigateTab: (idx) =>
                            _navigatePrimaryTab(context, idx, tabRefreshBus),
                      ),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: RoutePaths.lots,
                    pageBuilder: (context, state) => NoTransitionPage<void>(
                      key: state.pageKey,
                      child: LotListPage(
                        refreshSignal: tabRefreshBus.signalFor(1),
                      ),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: RoutePaths.stockMovements,
                    pageBuilder: (context, state) => NoTransitionPage<void>(
                      key: state.pageKey,
                      child: StockMovementsPage(
                        embedded: true,
                        refreshSignal: tabRefreshBus.signalFor(2),
                      ),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: RoutePaths.workers,
                    pageBuilder: (context, state) => NoTransitionPage<void>(
                      key: state.pageKey,
                      child: WorkerListPage(
                        refreshSignal: tabRefreshBus.signalFor(3),
                      ),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: RoutePaths.processes,
                    pageBuilder: (context, state) => NoTransitionPage<void>(
                      key: state.pageKey,
                      child: ProcessListPage(
                        refreshSignal: tabRefreshBus.signalFor(4),
                      ),
                    ),
                  ),
                ],
              ),
              StatefulShellBranch(
                routes: [
                  GoRoute(
                    path: RoutePaths.settings,
                    pageBuilder: (context, state) => NoTransitionPage<void>(
                      key: state.pageKey,
                      child: SettingsHomePage(config: config),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: RoutePaths.dashboard,
            redirect: (_, _) => RoutePaths.home,
          ),
          GoRoute(
            path: RoutePaths.designsColours,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const DesignsColoursPage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.lotCreate,
            pageBuilder: (context, state) =>
                AppMotion.buildPage(state: state, child: const LotCreatePage()),
          ),
          GoRoute(
            path: RoutePaths.lotDetailPattern,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: LotDetailPage(lotId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: RoutePaths.lotColourDetailPattern,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: LotColourDetailPage(
                lotId: state.pathParameters['id']!,
                colourId: state.pathParameters['colourId']!,
              ),
            ),
          ),
          GoRoute(
            path: RoutePaths.lotRoutingPattern,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: JobProcessRoutingPage(
                lotId: state.pathParameters['id']!,
                initialDesignColourId: state.uri.queryParameters['colourId'],
              ),
            ),
          ),
          // Inventory
          GoRoute(
            path: RoutePaths.inventory,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const InventoryOverviewPage(showAppBar: true),
            ),
          ),
          GoRoute(
            path: RoutePaths.processCreate,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const ProcessFormPage(),
            ),
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
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const WorkerFormPage(),
            ),
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
              child: WorkerAssignmentsPage(
                workerId: state.pathParameters['id']!,
              ),
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
          // Stock Movements, Issue & Receive Return
          GoRoute(
            path: RoutePaths.stockIssuePath,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: StockIssuePage(
                initialDesignColourId:
                    state.uri.queryParameters['designColourId'],
                initialProcessId: state.uri.queryParameters['processId'],
                initialWorkerId: state.uri.queryParameters['workerId'],
              ),
            ),
          ),
          GoRoute(
            path: RoutePaths.stockReturnPicker,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: ReceiveReturnPickerPage(
                initialWorkerId: state.uri.queryParameters['workerId'],
                initialProcessId: state.uri.queryParameters['processId'],
                initialLotId: state.uri.queryParameters['lotId'],
              ),
            ),
          ),
          GoRoute(
            path: RoutePaths.stockReturnPattern,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: StockSettlementPage(
                issueId: state.pathParameters['issueId']!,
              ),
            ),
          ),
          GoRoute(
            path: RoutePaths.stockRepair,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const DamagedRepairPage(),
            ),
          ),
          // Labour, Worker Ledger & Payments
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
          // Backup & Restore (alias)
          GoRoute(
            path: RoutePaths.backupRestore,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const BackupRestorePage(),
            ),
          ),
          // Business Reports & Daily Summary
          GoRoute(
            path: RoutePaths.reports,
            pageBuilder: (context, state) =>
                AppMotion.buildPage(state: state, child: const ReportsPage()),
          ),
          GoRoute(
            path: RoutePaths.dailySummary,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: DailySummaryPage(
                initialDayUtcMillis: int.tryParse(
                  state.uri.queryParameters['dayUtcMillis'] ?? '',
                ),
              ),
            ),
          ),
          // V1.4 — Complete Production History, Lot Tracking, QC Inspection & Ledger
          GoRoute(
            path: RoutePaths.productionHistory,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const ProductionHistoryDashboardPage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.lotHistoryPattern,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: LotHistoryPage(lotId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: RoutePaths.lotTimelinePattern,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: LotTimelinePage(lotId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: RoutePaths.workerProductionHistory,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const WorkerProductionHistoryPage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.processProductionHistory,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const ProcessHistoryPage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.inspectionQueue,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const InspectionQueuePage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.productionTransactionDetailPattern,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: ProductionTransactionDetailPage(
                kindSegment: state.pathParameters['kind']!,
                transactionId: state.pathParameters['id']!,
              ),
            ),
          ),
          // Centralized Settings & Help Hub
          GoRoute(
            path: RoutePaths.settingsAppearance,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const AppearanceSettingsPage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.settingsBusinessProfile,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const BusinessProfilePage(showAppBar: true),
            ),
          ),
          GoRoute(
            path: RoutePaths.settingsStockLabour,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const StockLabourSettingsPage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.settingsSecurity,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const SecuritySettingsPage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.settingsSecurityPinSetup,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const PinSetupPage(isChangeMode: false),
            ),
          ),
          GoRoute(
            path: RoutePaths.settingsSecurityPinChange,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const PinSetupPage(isChangeMode: true),
            ),
          ),
          GoRoute(
            path: RoutePaths.settingsNotifications,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const NotificationSettingsPage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.settingsBackup,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const BackupRestorePage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.settingsHelp,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const HelpGuidancePage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.settingsHelpTopicPattern,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: HelpTopicDetailPage(
                topicId: state.pathParameters['topicId']!,
              ),
            ),
          ),
          GoRoute(
            path: RoutePaths.settingsAbout,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: AboutStitchFlowPage(config: config),
            ),
          ),
          // V1.5 — Cloud Auth & Sync Center
          GoRoute(
            path: RoutePaths.authLogin,
            pageBuilder: (context, state) =>
                AppMotion.buildPage(state: state, child: const LoginPage()),
          ),
          GoRoute(
            path: RoutePaths.settingsAccount,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const AccountSettingsPage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.settingsSync,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const SyncCenterPage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.settingsDataHealth,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const DataHealthPage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.settingsTeam,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const TeamManagementPage(),
            ),
          ),
          GoRoute(
            path: RoutePaths.settingsSyncConflicts,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const SyncConflictInspectorPage(),
            ),
          ),
        ],
      ),
    ],
  );
}

void _navigatePrimaryTab(
  BuildContext context,
  int index, [
  PrimaryTabRefreshBus? refreshBus,
]) {
  final safeIndex = index.clamp(0, _primaryTabRoutes.length - 1);
  refreshBus?.onTabSelected(safeIndex);
  context.go(_primaryTabRoutes[safeIndex]);
}

List<({String id, String label, IconData icon, String route})>
_buildExtraRoutes(BuildContext context) {
  final l10n = context.l10n;
  return <({String id, String label, IconData icon, String route})>[
    (
      id: 'productionHistory',
      label: l10n.navProductionHistory,
      icon: AppIcons.productionHistory,
      route: RoutePaths.productionHistory,
    ),
    (
      id: 'inspectionQueue',
      label: l10n.navInspectionQueue,
      icon: AppIcons.qcInspect,
      route: RoutePaths.inspectionQueue,
    ),
    (
      id: 'processHistory',
      label: l10n.navProcessHistory,
      icon: AppIcons.processHistory,
      route: RoutePaths.processProductionHistory,
    ),
    (
      id: 'designsColours',
      label: l10n.navDesignsColours,
      icon: AppIcons.designs,
      route: RoutePaths.designsColours,
    ),
    (
      id: 'inventory',
      label: l10n.navInventory,
      icon: AppIcons.inventory,
      route: RoutePaths.inventory,
    ),
    (
      id: 'accounting',
      label: l10n.navAccounting,
      icon: AppIcons.accounting,
      route: RoutePaths.accounting,
    ),
    (
      id: 'reports',
      label: l10n.navReports,
      icon: AppIcons.reports,
      route: RoutePaths.reports,
    ),
    (
      id: 'help',
      label: l10n.settingsHelpTitle,
      icon: AppIcons.guide,
      route: RoutePaths.settingsHelp,
    ),
  ];
}

List<ResponsiveNavDestination> _buildPrimaryDestinations(BuildContext context) {
  final l10n = context.l10n;
  int? syncAttentionBadge;
  final syncCubit = context.read<SyncCubit?>();
  if (syncCubit != null) {
    final syncState = context.watch<SyncCubit>().state;
    final attentionCount =
        syncState.failedItems.length +
        (syncState.phase == SyncPhase.needsAttention &&
                syncState.failedItems.isEmpty
            ? 1
            : 0);
    if (attentionCount > 0) {
      syncAttentionBadge = attentionCount;
    }
  }
  return [
    ResponsiveNavDestination(
      label: l10n.navDashboard,
      icon: AppIcons.dashboard,
      selectedIcon: AppIcons.dashboardSelected,
    ),
    ResponsiveNavDestination(
      label: l10n.navLots,
      icon: AppIcons.lot,
      selectedIcon: AppIcons.lotsSelected,
    ),
    ResponsiveNavDestination(
      label: l10n.navStockShort,
      icon: AppIcons.stockMovements,
      selectedIcon: AppIcons.stockMovements,
    ),
    ResponsiveNavDestination(
      label: l10n.navWorkers,
      icon: AppIcons.workers,
      selectedIcon: AppIcons.workersSelected,
    ),
    ResponsiveNavDestination(
      label: l10n.navWorkStagesShort,
      icon: AppIcons.process,
      selectedIcon: AppIcons.process,
    ),
    ResponsiveNavDestination(
      label: l10n.navSettings,
      icon: AppIcons.settings,
      selectedIcon: AppIcons.settingsSelected,
      badgeCount: syncAttentionBadge,
    ),
  ];
}

Map<ShortcutActivator, VoidCallback> _buildGlobalShortcuts(
  BuildContext context, {
  required ValueChanged<int> onSelectTab,
}) {
  const digitKeys = [
    LogicalKeyboardKey.digit1,
    LogicalKeyboardKey.digit2,
    LogicalKeyboardKey.digit3,
    LogicalKeyboardKey.digit4,
    LogicalKeyboardKey.digit5,
    LogicalKeyboardKey.digit6,
  ];
  return <ShortcutActivator, VoidCallback>{
    for (var i = 0; i < digitKeys.length; i++)
      SingleActivator(digitKeys[i], alt: true): () => onSelectTab(i),
    const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
        showGlobalSearch(context),
    const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
        showGlobalSearch(context),
    const SingleActivator(LogicalKeyboardKey.escape): () =>
        GoRouter.of(context).routerDelegate.popRoute(),
  };
}

/// Hosts the 6 alive primary tabs inside [StatefulShellRoute] with a smooth
/// 150ms zero-blank cross-fade.
///
/// - On Compact mobile (`< 600dp`), renders the Mobile AppBar and Bottom
///   NavigationBar inside this page itself, so pushing any detail/form sibling
///   route transitions cleanly OVER the tab chrome with zero layout jump or
///   unmount blink.
/// - On Tablet / Desktop (`>= 600dp`), renders the tab stack directly because
///   [StitchFlowShellScaffold] already provides the persistent Rail / Sidebar.
final class _PrimaryTabsViewport extends StatelessWidget {
  const _PrimaryTabsViewport({
    required this.config,
    required this.navigationShell,
    required this.tabRefreshBus,
    required this.children,
  });

  final AppConfig config;
  final StatefulNavigationShell navigationShell;
  final PrimaryTabRefreshBus tabRefreshBus;
  final List<Widget> children;

  void _onSelectTab(int index) {
    final safeIndex = index.clamp(0, _primaryTabRoutes.length - 1);
    tabRefreshBus.onTabSelected(safeIndex);
    navigationShell.goBranch(
      safeIndex,
      initialLocation: safeIndex == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = AppBreakpoints.fromWidth(width).isCompact;
    final tabStack = AppCrossFadeIndexedStack(
      index: navigationShell.currentIndex,
      children: children,
    );

    if (!isCompact) {
      return tabStack;
    }

    final l10n = context.l10n;
    final appTitle = config.isDev ? l10n.appTitleDev : l10n.appTitle;
    final router = GoRouter.of(context);
    final extraRoutes = _buildExtraRoutes(context);

    return ResponsiveNavigation(
      title: appTitle,
      subtitle: l10n.appTagline,
      selectedIndex: navigationShell.currentIndex,
      showMobileChrome: true,
      onDestinationSelected: _onSelectTab,
      compactActions: [
        const SyncStatusBadge(compact: true),
        GuideTarget(
          id: GuideTargetId.appBarGuide,
          child: AppIconButton(
            icon: AppIcons.help,
            tooltip: l10n.guideTooltip,
            onPressed: () => GuideQuickMenuSheet.show(context),
          ),
        ),
        GuideTarget(
          id: GuideTargetId.appBarSearch,
          child: AppIconButton(
            icon: AppIcons.search,
            tooltip: l10n.uxSearchTooltip,
            onPressed: () => showGlobalSearch(context),
          ),
        ),
        BlocBuilder<AppLockCubit, AppLockState>(
          builder: (context, lockState) {
            return PopupMenuButton<VoidCallback>(
              tooltip: MaterialLocalizations.of(context).showMenuTooltip,
              icon: const Icon(AppIcons.more),
              onSelected: (action) => action(),
              itemBuilder: (_) => [
                for (final item in extraRoutes)
                  PopupMenuItem<VoidCallback>(
                    value: () => router.push(item.route),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(item.icon),
                      title: Text(item.label),
                    ),
                  ),
                if (lockState.isPinEnabled) ...[
                  const PopupMenuDivider(),
                  PopupMenuItem<VoidCallback>(
                    value: () => context.read<AppLockCubit>().lockNow(),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(AppIcons.lock),
                      title: Text(l10n.securityLockNowAction),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
      destinations: _buildPrimaryDestinations(context),
      body: tabStack,
    );
  }
}

/// Persistent adaptive GoRouter shell:
/// - Keeps Desktop Sidebar & Tablet Rail mounted across all 45+ routes
/// - Computes active primary/secondary destination highlight and clickable
///   breadcrumbs directly from the current URL [location]
/// - On Mobile (`< 600dp`), keeps a single stable passthrough tree so the
///   nested Navigator is NEVER reparented or stripped of chrome mid-transition.
final class StitchFlowShellScaffold extends StatelessWidget {
  const StitchFlowShellScaffold({
    super.key,
    required this.config,
    required this.location,
    required this.child,
    this.tabRefreshBus,
  });

  final AppConfig config;
  final String location;
  final Widget child;
  final PrimaryTabRefreshBus? tabRefreshBus;

  bool get _isPrimaryRootRoute =>
      location == RoutePaths.home ||
      location == RoutePaths.lots ||
      location == RoutePaths.stockMovements ||
      location == RoutePaths.workers ||
      location == RoutePaths.processes ||
      location == RoutePaths.settings;

  int get _selectedPrimaryIndex {
    if (location.startsWith(RoutePaths.lots)) return 1;
    if (location.startsWith(RoutePaths.stockMovements) &&
        location != RoutePaths.inspectionQueue) {
      return 2;
    }
    if (location.startsWith(RoutePaths.workers)) return 3;
    if (location.startsWith(RoutePaths.processes)) return 4;
    if (location.startsWith(RoutePaths.settings) &&
        !location.startsWith(RoutePaths.settingsHelp)) {
      return 5;
    }
    return 0;
  }

  String? get _activeExtraId {
    if (location == RoutePaths.inspectionQueue) return 'inspectionQueue';
    if (location == RoutePaths.processProductionHistory) {
      return 'processHistory';
    }
    if (location.startsWith(RoutePaths.productionHistory)) {
      return 'productionHistory';
    }
    if (location.startsWith(RoutePaths.designsColours)) {
      return 'designsColours';
    }
    if (location.startsWith(RoutePaths.inventory)) return 'inventory';
    if (location.startsWith(RoutePaths.accounting) ||
        location.startsWith(RoutePaths.paymentCreatePath)) {
      return 'accounting';
    }
    if (location.startsWith(RoutePaths.reports) ||
        location.startsWith(RoutePaths.dailySummary)) {
      return 'reports';
    }
    if (location.startsWith(RoutePaths.settingsHelp)) return 'help';
    return null;
  }

  List<AppBreadcrumbItem> _buildBreadcrumbs(BuildContext context) {
    final l10n = context.l10n;
    final items = <AppBreadcrumbItem>[
      AppBreadcrumbItem(
        label: l10n.navDashboard,
        onTap: location == RoutePaths.home
            ? null
            : () => context.go(RoutePaths.home),
      ),
    ];

    if (location == RoutePaths.home) return items;

    if (location.startsWith(RoutePaths.lots)) {
      items.add(
        AppBreadcrumbItem(
          label: l10n.navLots,
          onTap: location == RoutePaths.lots
              ? null
              : () => context.go(RoutePaths.lots),
        ),
      );
      if (location == RoutePaths.lotCreate) {
        items.add(AppBreadcrumbItem(label: l10n.lotCreateAction));
      } else if (location.endsWith('/history')) {
        items.add(AppBreadcrumbItem(label: l10n.navProductionHistory));
      } else if (location.endsWith('/timeline')) {
        items.add(AppBreadcrumbItem(label: l10n.navProductionHistory));
      } else if (location.endsWith('/routing')) {
        items.add(AppBreadcrumbItem(label: l10n.navProcesses));
      } else if (location != RoutePaths.lots) {
        items.add(AppBreadcrumbItem(label: l10n.lotsHeading));
      }
      return items;
    }

    if (location.startsWith(RoutePaths.workers)) {
      items.add(
        AppBreadcrumbItem(
          label: l10n.navWorkers,
          onTap: location == RoutePaths.workers
              ? null
              : () => context.go(RoutePaths.workers),
        ),
      );
      if (location == RoutePaths.workerCreate) {
        items.add(AppBreadcrumbItem(label: l10n.workerCreateAction));
      } else if (location.endsWith('/ledger')) {
        items.add(AppBreadcrumbItem(label: l10n.navAccounting));
      } else if (location.contains('/rates')) {
        items.add(AppBreadcrumbItem(label: l10n.ratesHistoryHeading));
      } else if (location != RoutePaths.workers) {
        items.add(AppBreadcrumbItem(label: l10n.workerDetailsHeading));
      }
      return items;
    }

    if (location.startsWith(RoutePaths.stockMovements)) {
      items.add(
        AppBreadcrumbItem(
          label: l10n.navStockShort,
          onTap: location == RoutePaths.stockMovements
              ? null
              : () => context.go(RoutePaths.stockMovements),
        ),
      );
      if (location == RoutePaths.inspectionQueue) {
        items.add(AppBreadcrumbItem(label: l10n.navInspectionQueue));
      } else if (location == RoutePaths.stockIssuePath) {
        items.add(AppBreadcrumbItem(label: l10n.stockIssueAction));
      } else if (location.startsWith(RoutePaths.stockReturnPicker)) {
        items.add(AppBreadcrumbItem(label: l10n.stockReturnAction));
      } else if (location == RoutePaths.stockRepair) {
        items.add(AppBreadcrumbItem(label: l10n.stockRepairHeading));
      }
      return items;
    }

    if (location.startsWith(RoutePaths.productionHistory)) {
      items.add(
        AppBreadcrumbItem(
          label: l10n.navProductionHistory,
          onTap: location == RoutePaths.productionHistory
              ? null
              : () => context.go(RoutePaths.productionHistory),
        ),
      );
      if (location == RoutePaths.workerProductionHistory) {
        items.add(AppBreadcrumbItem(label: l10n.navWorkers));
      } else if (location == RoutePaths.processProductionHistory) {
        items.add(AppBreadcrumbItem(label: l10n.navProcessHistory));
      } else if (location.contains('/tx/')) {
        items.add(AppBreadcrumbItem(label: l10n.navProductionHistory));
      }
      return items;
    }

    if (location.startsWith(RoutePaths.designsColours)) {
      items.add(AppBreadcrumbItem(label: l10n.navDesignsColours));
      return items;
    }

    if (location.startsWith(RoutePaths.processes)) {
      items.add(
        AppBreadcrumbItem(
          label: l10n.navProcesses,
          onTap: location == RoutePaths.processes
              ? null
              : () => context.go(RoutePaths.processes),
        ),
      );
      if (location != RoutePaths.processes) {
        items.add(AppBreadcrumbItem(label: l10n.processDetailsHeading));
      }
      return items;
    }

    if (location.startsWith(RoutePaths.inventory)) {
      items.add(AppBreadcrumbItem(label: l10n.navInventory));
      return items;
    }

    if (location.startsWith(RoutePaths.accounting) ||
        location.startsWith(RoutePaths.paymentCreatePath)) {
      items.add(AppBreadcrumbItem(label: l10n.navAccounting));
      return items;
    }

    if (location.startsWith(RoutePaths.reports) ||
        location.startsWith(RoutePaths.dailySummary)) {
      items.add(AppBreadcrumbItem(label: l10n.navReports));
      return items;
    }

    if (location.startsWith(RoutePaths.settings)) {
      items.add(
        AppBreadcrumbItem(
          label: l10n.navSettings,
          onTap: location == RoutePaths.settings
              ? null
              : () => context.go(RoutePaths.settings),
        ),
      );
      if (location.startsWith(RoutePaths.settingsHelp)) {
        items.add(AppBreadcrumbItem(label: l10n.settingsHelpTitle));
      } else if (location == RoutePaths.settingsBackup) {
        items.add(AppBreadcrumbItem(label: l10n.navBackupRestore));
      } else if (location == RoutePaths.settingsSecurity) {
        items.add(AppBreadcrumbItem(label: l10n.settingsSecurityTitle));
      } else if (location == RoutePaths.settingsStockLabour) {
        items.add(AppBreadcrumbItem(label: l10n.settingsStockLabourTitle));
      } else if (location == RoutePaths.settingsAppearance) {
        items.add(AppBreadcrumbItem(label: l10n.settingsAppearanceTitle));
      } else if (location == RoutePaths.settingsAccount) {
        items.add(AppBreadcrumbItem(label: l10n.authAccountTitle));
      } else if (location == RoutePaths.settingsSync) {
        items.add(AppBreadcrumbItem(label: l10n.syncCenterTitle));
      } else if (location == RoutePaths.settingsDataHealth) {
        items.add(AppBreadcrumbItem(label: l10n.dataHealthHeading));
      } else if (location == RoutePaths.settingsTeam) {
        items.add(AppBreadcrumbItem(label: l10n.teamHeading));
      } else if (location == RoutePaths.settingsSyncConflicts) {
        items.add(AppBreadcrumbItem(label: l10n.syncConflictsTitle));
      }
      return items;
    }

    if (location.startsWith(RoutePaths.backupRestore)) {
      items.add(AppBreadcrumbItem(label: l10n.navBackupRestore));
      return items;
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final sizeClass = AppBreakpoints.fromWidth(width);

    // On mobile (< 600dp), keep the outer shell tree 100% invariant across
    // every route so pushing/popping detail pages or opening menus never
    // reparents the Navigator or snaps the Bottom Bar / AppBar away.
    if (sizeClass.isCompact) {
      return _RootBackGuard(
        location: location,
        tabRefreshBus: tabRefreshBus,
        child: CallbackShortcuts(
          bindings: _buildGlobalShortcuts(
            context,
            onSelectTab: (idx) =>
                _navigatePrimaryTab(context, idx, tabRefreshBus),
          ),
          child: ResponsiveShellScope(
            sizeClass: sizeClass,
            hasPersistentChrome: false,
            child: child,
          ),
        ),
      );
    }

    final l10n = context.l10n;
    final appTitle = config.isDev ? l10n.appTitleDev : l10n.appTitle;
    final extraRoutes = _buildExtraRoutes(context);
    // Sidebar / drawer: sibling sections, so replace the location.
    final extraActions = <ResponsiveNavActionItem>[
      for (final e in extraRoutes)
        ResponsiveNavActionItem(
          id: e.id,
          label: e.label,
          icon: e.icon,
          onTap: () => context.go(e.route),
        ),
    ];

    return _RootBackGuard(
      location: location,
      tabRefreshBus: tabRefreshBus,
      child: ResponsiveNavigation(
        title: appTitle,
        subtitle: l10n.appTagline,
        selectedIndex: _selectedPrimaryIndex,
        activeExtraActionId: _activeExtraId,
        showMobileChrome: _isPrimaryRootRoute,
        breadcrumbs: _buildBreadcrumbs(context),
        onDestinationSelected: (idx) =>
            _navigatePrimaryTab(context, idx, tabRefreshBus),
        extraShortcuts: {
          // Ctrl+K (Cmd+K on Mac): search lots, workers, processes or start a
          // quick action from anywhere.
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
              showGlobalSearch(context),
          const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
              showGlobalSearch(context),
          // Esc goes back like the system back button, so unsaved-changes
          // guards still ask before leaving a form.
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              GoRouter.of(context).routerDelegate.popRoute(),
        },
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Center(child: SyncStatusBadge()),
          ),
          GuideTarget(
            id: GuideTargetId.appBarSearch,
            child: AppIconButton(
              icon: AppIcons.search,
              tooltip: l10n.uxSearchTooltip,
              onPressed: () => showGlobalSearch(context),
            ),
          ),
          BlocBuilder<AppLockCubit, AppLockState>(
            builder: (context, lockState) {
              if (!lockState.isPinEnabled) return const SizedBox.shrink();
              return AppIconButton(
                icon: AppIcons.lock,
                tooltip: l10n.securityLockNowAction,
                onPressed: () => context.read<AppLockCubit>().lockNow(),
              );
            },
          ),
          AppIconButton(
            icon: AppIcons.productionHistory,
            tooltip: l10n.navProductionHistory,
            onPressed: () => context.push(RoutePaths.productionHistory),
          ),
          AppIconButton(
            icon: AppIcons.accounting,
            tooltip: l10n.navAccounting,
            onPressed: () => context.push(RoutePaths.accounting),
          ),
          AppIconButton(
            icon: AppIcons.reports,
            tooltip: l10n.navReports,
            onPressed: () => context.push(RoutePaths.reports),
          ),
          GuideTarget(
            id: GuideTargetId.appBarGuide,
            child: AppIconButton(
              icon: AppIcons.help,
              tooltip: l10n.guideTooltip,
              onPressed: () => GuideQuickMenuSheet.show(context),
            ),
          ),
        ],
        sidebarExtraActions: extraActions,
        destinations: _buildPrimaryDestinations(context),
        body: child,
      ),
    );
  }
}

/// App-level system back handling. It only runs when nothing inside the app
/// can pop (inner pages and form guards always handle back first):
/// - away from Home (another tab, a sidebar section, a deep link) → Home;
/// - on Home (Android) → "Press back again to exit", then exit on a second
///   press within 2 seconds.
/// Without this, back on a screen opened with `go()` closed the whole app.
final class _RootBackGuard extends StatelessWidget {
  const _RootBackGuard({
    required this.location,
    required this.child,
    this.tabRefreshBus,
  });

  final String location;
  final Widget child;
  final PrimaryTabRefreshBus? tabRefreshBus;

  static DateTime? _lastBackOnHome;
  static const Duration _exitWindow = Duration(seconds: 2);

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (location != RoutePaths.home) {
          _lastBackOnHome = null;
          _navigatePrimaryTab(context, 0, tabRefreshBus);
          return;
        }
        if (defaultTargetPlatform != TargetPlatform.android) return;
        final now = DateTime.now();
        final last = _lastBackOnHome;
        if (last != null && now.difference(last) < _exitWindow) {
          _lastBackOnHome = null;
          SystemNavigator.pop();
          return;
        }
        _lastBackOnHome = now;
        AppMessageService.info(
          context,
          context.l10n.navPressBackAgainToExit,
          duration: _exitWindow,
        );
      },
      child: child,
    );
  }
}
