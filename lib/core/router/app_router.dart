import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/router/stitchflow_shell_scaffold.dart';
import 'package:business_manager/features/accounting/presentation/pages/accounting_overview_page.dart';
import 'package:business_manager/features/accounting/presentation/pages/payment_form_page.dart';
import 'package:business_manager/features/accounting/presentation/pages/worker_adjustment_form_page.dart';
import 'package:business_manager/features/accounting/presentation/pages/worker_ledger_page.dart';
import 'package:business_manager/features/auth/presentation/pages/account_settings_page.dart';
import 'package:business_manager/features/auth/presentation/pages/login_page.dart';
import 'package:business_manager/features/backup/presentation/pages/backup_restore_page.dart';
import 'package:business_manager/features/backup/presentation/pages/data_health_page.dart';
import 'package:business_manager/features/sync/presentation/pages/sync_conflict_inspector_page.dart';
import 'package:business_manager/features/team/presentation/pages/team_management_page.dart';
import 'package:business_manager/features/business_profile/presentation/pages/business_profile_page.dart';
import 'package:business_manager/features/dashboard/presentation/pages/dashboard_page.dart';
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
import 'package:business_manager/features/security/presentation/pages/pin_setup_page.dart';
import 'package:business_manager/features/security/presentation/pages/security_settings_page.dart';
import 'package:business_manager/features/settings/presentation/pages/about_stitchflow_page.dart';
import 'package:business_manager/features/settings/presentation/pages/appearance_settings_page.dart';
import 'package:business_manager/features/settings/presentation/pages/help_guidance_page.dart';
import 'package:business_manager/features/settings/presentation/pages/settings_home_page.dart';
import 'package:business_manager/features/settings/presentation/pages/stock_labour_settings_page.dart';
import 'package:business_manager/features/stock_movements/presentation/pages/damaged_repair_page.dart';
import 'package:business_manager/features/stock_movements/presentation/pages/receive_return_picker_page.dart';
import 'package:business_manager/features/stock_movements/presentation/pages/stock_issue_page.dart';
import 'package:business_manager/features/stock_movements/presentation/pages/stock_movements_page.dart';
import 'package:business_manager/features/stock_movements/presentation/pages/stock_settlement_page.dart';
import 'package:business_manager/features/sync/presentation/pages/sync_center_page.dart';
import 'package:business_manager/features/workers/presentation/pages/worker_assignments_page.dart';
import 'package:business_manager/features/workers/presentation/pages/worker_detail_page.dart';
import 'package:business_manager/features/workers/presentation/pages/worker_form_page.dart';
import 'package:business_manager/features/workers/presentation/pages/worker_list_page.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

export 'package:business_manager/core/router/stitchflow_shell_scaffold.dart'
    show PrimaryTabRefreshBus, StitchFlowShellScaffold, navigatePrimaryTab;

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
              return PrimaryTabsViewport(
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
                            navigatePrimaryTab(context, idx, tabRefreshBus),
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
