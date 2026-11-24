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
import 'package:business_manager/features/lots/presentation/pages/lot_colour_detail_page.dart';
import 'package:business_manager/features/lots/presentation/pages/lot_detail_page.dart';
import 'package:business_manager/features/lots/presentation/pages/lot_list_page.dart';
import 'package:business_manager/features/process_routing/presentation/pages/job_process_routing_page.dart';
import 'package:business_manager/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:business_manager/features/processes/presentation/pages/process_detail_page.dart';
import 'package:business_manager/features/processes/presentation/pages/process_form_page.dart';
import 'package:business_manager/features/processes/presentation/pages/process_list_page.dart';
import 'package:business_manager/features/rates/presentation/pages/rate_form_page.dart';
import 'package:business_manager/features/rates/presentation/pages/rate_history_page.dart';
import 'package:business_manager/features/reports/presentation/pages/daily_summary_page.dart';
import 'package:business_manager/features/reports/presentation/pages/reports_page.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:business_manager/features/security/presentation/pages/pin_setup_page.dart';
import 'package:business_manager/features/security/presentation/pages/security_settings_page.dart';
import 'package:business_manager/features/settings/presentation/pages/about_stitchflow_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:business_manager/features/settings/presentation/pages/appearance_settings_page.dart';
import 'package:business_manager/features/settings/presentation/pages/help_guidance_page.dart';
import 'package:business_manager/features/settings/presentation/pages/settings_home_page.dart';
import 'package:business_manager/features/settings/presentation/pages/stock_labour_settings_page.dart';
import 'package:business_manager/features/stock_movements/presentation/pages/damaged_repair_page.dart';
import 'package:business_manager/features/stock_movements/presentation/pages/receive_return_picker_page.dart';
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
      // Processes & Inventory standalone screens
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
      // Stock Movements, Issue & Receive Return
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
          child: StockSettlementPage(issueId: state.pathParameters['issueId']!),
        ),
      ),
      GoRoute(
        path: RoutePaths.stockRepair,
        pageBuilder: (context, state) =>
            AppMotion.buildPage(state: state, child: const DamagedRepairPage()),
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
        pageBuilder: (context, state) =>
            AppMotion.buildPage(state: state, child: const BackupRestorePage()),
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
      // Centralized Settings & Help Hub
      GoRoute(
        path: RoutePaths.settings,
        pageBuilder: (context, state) => AppMotion.buildPage(
          state: state,
          child: SettingsHomePage(config: config, showAppBar: true),
        ),
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
        pageBuilder: (context, state) =>
            AppMotion.buildPage(state: state, child: const BackupRestorePage()),
      ),
      GoRoute(
        path: RoutePaths.settingsHelp,
        pageBuilder: (context, state) =>
            AppMotion.buildPage(state: state, child: const HelpGuidancePage()),
      ),
      GoRoute(
        path: RoutePaths.settingsHelpTopicPattern,
        pageBuilder: (context, state) => AppMotion.buildPage(
          state: state,
          child: HelpTopicDetailPage(topicId: state.pathParameters['topicId']!),
        ),
      ),
      GoRoute(
        path: RoutePaths.settingsAbout,
        pageBuilder: (context, state) => AppMotion.buildPage(
          state: state,
          child: AboutStitchFlowPage(config: config),
        ),
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
      sidebarExtraActions: [
        ResponsiveNavActionItem(
          label: l10n.navProcesses,
          icon: Icons.precision_manufacturing_outlined,
          onTap: () => context.push(RoutePaths.processes),
        ),
        ResponsiveNavActionItem(
          label: l10n.navInventory,
          icon: Icons.bar_chart_outlined,
          onTap: () => context.push(RoutePaths.inventory),
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
          label: l10n.settingsHelpTitle,
          icon: Icons.menu_book_outlined,
          onTap: () => context.push(RoutePaths.settingsHelp),
        ),
      ],
      // 5 spacious primary tabs (72dp each on 360dp phones — zero Gujarati clipping!)
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
      body: switch (_selectedIndex) {
        0 => DashboardPage(
          config: widget.config,
          onNavigateTab: (idx) => setState(() => _selectedIndex = idx),
        ),
        1 => const LotListPage(),
        2 => const StockMovementsPage(embedded: true),
        3 => const WorkerListPage(),
        _ => SettingsHomePage(config: widget.config),
      },
    );
  }
}
