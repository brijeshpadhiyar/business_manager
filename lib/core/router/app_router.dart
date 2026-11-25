import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/design_system_showcase_page.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/services/app_message_service.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/accounting/presentation/pages/accounting_overview_page.dart';
import 'package:business_manager/features/accounting/presentation/pages/payment_form_page.dart';
import 'package:business_manager/features/accounting/presentation/pages/worker_adjustment_form_page.dart';
import 'package:business_manager/features/accounting/presentation/pages/worker_ledger_page.dart';
import 'package:business_manager/features/backup/presentation/pages/backup_restore_page.dart';
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
import 'package:business_manager/features/workers/presentation/pages/worker_assignments_page.dart';
import 'package:business_manager/features/workers/presentation/pages/worker_detail_page.dart';
import 'package:business_manager/features/workers/presentation/pages/worker_form_page.dart';
import 'package:business_manager/features/workers/presentation/pages/worker_list_page.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

const List<String> _primaryTabRoutes = [
  RoutePaths.home,
  RoutePaths.lots,
  RoutePaths.stockMovements,
  RoutePaths.workers,
  RoutePaths.settings,
];

GoRouter createAppRouter(AppConfig config) {
  return GoRouter(
    initialLocation: RoutePaths.home,
    routes: [
      ShellRoute(
        builder: (context, state, child) => StitchFlowShellScaffold(
          config: config,
          location: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: RoutePaths.home,
            pageBuilder: (context, state) => AppMotion.buildTabPage(
              state: state,
              child: DashboardPage(
                config: config,
                onNavigateTab: (idx) => _navigatePrimaryTab(context, idx),
              ),
            ),
          ),
          GoRoute(
            path: RoutePaths.dashboard,
            redirect: (_, _) => RoutePaths.home,
          ),
          GoRoute(
            path: RoutePaths.lots,
            pageBuilder: (context, state) => AppMotion.buildTabPage(
              state: state,
              child: const LotListPage(),
            ),
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
          // Processes & Inventory
          GoRoute(
            path: RoutePaths.processes,
            pageBuilder: (context, state) => AppMotion.buildPage(
              state: state,
              child: const ProcessListPage(showAppBar: true),
            ),
          ),
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
            path: RoutePaths.workers,
            pageBuilder: (context, state) => AppMotion.buildTabPage(
              state: state,
              child: const WorkerListPage(),
            ),
          ),
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
            path: RoutePaths.stockMovements,
            pageBuilder: (context, state) {
              final pushed = GoRouter.of(context).canPop();
              if (pushed) {
                return AppMotion.buildPage(
                  state: state,
                  child: const StockMovementsPage(embedded: false),
                );
              }
              return AppMotion.buildTabPage(
                state: state,
                child: const StockMovementsPage(embedded: true),
              );
            },
          ),
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
            path: RoutePaths.settings,
            pageBuilder: (context, state) {
              final pushed = GoRouter.of(context).canPop();
              if (pushed) {
                return AppMotion.buildPage(
                  state: state,
                  child: SettingsHomePage(config: config, showAppBar: true),
                );
              }
              return AppMotion.buildTabPage(
                state: state,
                child: SettingsHomePage(config: config),
              );
            },
          ),
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
        ],
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

void _navigatePrimaryTab(BuildContext context, int index) {
  final safeIndex = index.clamp(0, _primaryTabRoutes.length - 1);
  context.go(_primaryTabRoutes[safeIndex]);
}

/// Persistent adaptive GoRouter shell:
/// - Keeps Desktop Sidebar & Tablet Rail mounted across all 45+ routes
/// - Computes active primary/secondary destination highlight and clickable
///   breadcrumbs directly from the current URL [location]
/// - On Mobile (`< 600dp`), renders the 5-tab Bottom Bar on root routes and
///   lets detail/form pages render full-screen with standard back navigation.
final class StitchFlowShellScaffold extends StatelessWidget {
  const StitchFlowShellScaffold({
    super.key,
    required this.config,
    required this.location,
    required this.child,
  });

  final AppConfig config;
  final String location;
  final Widget child;

  bool get _isPrimaryRootRoute =>
      location == RoutePaths.home ||
      location == RoutePaths.lots ||
      location == RoutePaths.stockMovements ||
      location == RoutePaths.workers ||
      location == RoutePaths.settings;

  int get _selectedPrimaryIndex {
    if (location.startsWith(RoutePaths.lots)) return 1;
    if (location.startsWith(RoutePaths.stockMovements) &&
        location != RoutePaths.inspectionQueue) {
      return 2;
    }
    if (location.startsWith(RoutePaths.workers)) return 3;
    if (location.startsWith(RoutePaths.settings) &&
        !location.startsWith(RoutePaths.settingsHelp)) {
      return 4;
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
    if (location.startsWith(RoutePaths.processes)) return 'processes';
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
    final l10n = context.l10n;
    final appTitle = config.isDev ? l10n.appTitleDev : l10n.appTitle;
    final router = GoRouter.of(context);
    final isRootChrome = _isPrimaryRootRoute && !router.canPop();

    // Secondary screens: sidebar on desktop, drawer on tablet, and the
    // "More" menu on phones.
    final extraRoutes =
        <({String id, String label, IconData icon, String route})>[
          (
            id: 'productionHistory',
            label: l10n.navProductionHistory,
            icon: Icons.history_rounded,
            route: RoutePaths.productionHistory,
          ),
          (
            id: 'inspectionQueue',
            label: l10n.navInspectionQueue,
            icon: Icons.fact_check_outlined,
            route: RoutePaths.inspectionQueue,
          ),
          (
            id: 'processHistory',
            label: l10n.navProcessHistory,
            icon: Icons.timeline_rounded,
            route: RoutePaths.processProductionHistory,
          ),
          (
            id: 'designsColours',
            label: l10n.navDesignsColours,
            icon: Icons.palette_outlined,
            route: RoutePaths.designsColours,
          ),
          (
            id: 'processes',
            label: l10n.navProcesses,
            icon: Icons.precision_manufacturing_outlined,
            route: RoutePaths.processes,
          ),
          (
            id: 'inventory',
            label: l10n.navInventory,
            icon: Icons.bar_chart_outlined,
            route: RoutePaths.inventory,
          ),
          (
            id: 'accounting',
            label: l10n.navAccounting,
            icon: Icons.account_balance_wallet_outlined,
            route: RoutePaths.accounting,
          ),
          (
            id: 'reports',
            label: l10n.navReports,
            icon: Icons.analytics_outlined,
            route: RoutePaths.reports,
          ),
          (
            id: 'help',
            label: l10n.settingsHelpTitle,
            icon: Icons.menu_book_outlined,
            route: RoutePaths.settingsHelp,
          ),
        ];
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
      child: ResponsiveNavigation(
        title: appTitle,
        subtitle: l10n.appTagline,
        selectedIndex: _selectedPrimaryIndex,
        activeExtraActionId: _activeExtraId,
        showMobileChrome: isRootChrome,
        breadcrumbs: _buildBreadcrumbs(context),
        onDestinationSelected: (idx) => _navigatePrimaryTab(context, idx),
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
        // Phones get Search plus one "More" menu instead of six icons, so the
        // toolbar never overflows at 320dp.
        compactActions: [
          AppIconButton(
            icon: Icons.search_rounded,
            tooltip: l10n.uxSearchTooltip,
            onPressed: () => showGlobalSearch(context),
          ),
          BlocBuilder<AppLockCubit, AppLockState>(
            builder: (context, lockState) {
              return PopupMenuButton<VoidCallback>(
                tooltip: MaterialLocalizations.of(context).showMenuTooltip,
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (action) => action(),
                itemBuilder: (_) => [
                  // Push (not go) so the system back button returns to the
                  // tab the menu was opened from instead of closing the app.
                  for (final item in extraRoutes)
                    PopupMenuItem<VoidCallback>(
                      // Captured router: the open menu makes canPop() true, which rebuilds
                      // the shell and unmounts this menu's own context.
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
                        leading: const Icon(Icons.lock_outline_rounded),
                        title: Text(l10n.securityLockNowAction),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
        actions: [
          AppIconButton(
            icon: Icons.search_rounded,
            tooltip: l10n.uxSearchTooltip,
            onPressed: () => showGlobalSearch(context),
          ),
          BlocBuilder<AppLockCubit, AppLockState>(
            builder: (context, lockState) {
              if (!lockState.isPinEnabled) return const SizedBox.shrink();
              return AppIconButton(
                icon: Icons.lock_outline_rounded,
                tooltip: l10n.securityLockNowAction,
                onPressed: () => context.read<AppLockCubit>().lockNow(),
              );
            },
          ),
          AppIconButton(
            icon: Icons.history_rounded,
            tooltip: l10n.navProductionHistory,
            onPressed: () => context.push(RoutePaths.productionHistory),
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
          AppIconButton(
            icon: Icons.help_outline_rounded,
            tooltip: l10n.settingsHelpTitle,
            onPressed: () => context.push(RoutePaths.settingsHelp),
          ),
        ],
        sidebarExtraActions: extraActions,
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
            label: l10n.navStockShort,
            icon: Icons.swap_horiz_rounded,
            selectedIcon: Icons.swap_horiz_rounded,
          ),
          ResponsiveNavDestination(
            label: l10n.navWorkers,
            icon: Icons.people_outline,
            selectedIcon: Icons.people,
          ),
          ResponsiveNavDestination(
            label: l10n.navSettings,
            icon: Icons.settings_outlined,
            selectedIcon: Icons.settings,
          ),
        ],
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
  const _RootBackGuard({required this.location, required this.child});

  final String location;
  final Widget child;

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
          context.go(RoutePaths.home);
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
