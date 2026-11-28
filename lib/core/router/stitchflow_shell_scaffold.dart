import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/services/app_message_service.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';
import 'package:business_manager/features/guidance/presentation/registry/guide_target_registry.dart';
import 'package:business_manager/features/guidance/presentation/widgets/guide_quick_menu_sheet.dart';
import 'package:business_manager/features/search/presentation/global_search_dialog.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:business_manager/features/sync/domain/entities/sync_entities.dart';
import 'package:business_manager/features/sync/presentation/bloc/sync_cubit.dart';
import 'package:business_manager/features/sync/presentation/widgets/sync_status_badge.dart';
import 'package:flutter/foundation.dart'
    show ValueListenable, ValueNotifier, defaultTargetPlatform;
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

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

/// Switches to a primary tab route by [index], bumping its silent-refresh bus.
void navigatePrimaryTab(
  BuildContext context,
  int index, [
  PrimaryTabRefreshBus? refreshBus,
]) {
  final safeIndex = index.clamp(0, _primaryTabRoutes.length - 1);
  refreshBus?.onTabSelected(safeIndex);
  context.go(_primaryTabRoutes[safeIndex]);
}

int? _readSyncAttentionBadge(BuildContext context) {
  final syncCubit = context.read<SyncCubit?>();
  if (syncCubit == null) return null;
  final syncState = context.watch<SyncCubit>().state;
  final attentionCount =
      syncState.failedItems.length +
      syncState.unresolvedConflictCount +
      (syncState.phase == SyncPhase.needsAttention &&
              syncState.failedItems.isEmpty
          ? 1
          : 0);
  return attentionCount > 0 ? attentionCount : null;
}

/// 4 core Mobile Bottom Navigation destinations (plus the 5th `More` sheet).
List<ResponsiveNavDestination> _buildMobileCoreDestinations(
  BuildContext context,
) {
  final l10n = context.l10n;
  return [
    ResponsiveNavDestination(
      id: 'dashboard',
      label: l10n.navDashboard,
      icon: AppIcons.dashboard,
      selectedIcon: AppIcons.dashboardSelected,
      guideTargetId: GuideTargetId.navHome,
    ),
    ResponsiveNavDestination(
      id: 'lots',
      label: l10n.navLots,
      icon: AppIcons.lot,
      selectedIcon: AppIcons.lotsSelected,
      guideTargetId: GuideTargetId.navLots,
    ),
    ResponsiveNavDestination(
      id: 'stock',
      label: l10n.navStockShort,
      icon: AppIcons.stockMovements,
      selectedIcon: AppIcons.stockMovements,
      guideTargetId: GuideTargetId.navStock,
    ),
    ResponsiveNavDestination(
      id: 'workers',
      label: l10n.navWorkers,
      icon: AppIcons.workers,
      selectedIcon: AppIcons.workersSelected,
      guideTargetId: GuideTargetId.navWorkers,
    ),
  ];
}

/// Builds the grouped sections for the Web/Desktop/Tablet Side Navigator
/// (`includeOverview: true`) or the Mobile `More` modules sheet
/// (`includeOverview: false`, omitting the 4 core bottom-bar tabs).
List<ResponsiveNavSection> _buildGroupedSections(
  BuildContext context, {
  required bool includeCoreTabs,
  required int selectedPrimaryIndex,
  required String? activeExtraId,
  required ValueChanged<int> onSelectPrimaryTab,
  required ValueChanged<String> onOpenExtraRoute,
  int? syncAttentionBadge,
}) {
  final l10n = context.l10n;

  bool isPrimaryActive(int idx) =>
      activeExtraId == null && selectedPrimaryIndex == idx;

  final productionItems = <ResponsiveNavSectionItem>[
    if (includeCoreTabs)
      ResponsiveNavSectionItem(
        id: 'lots',
        label: l10n.navLots,
        icon: AppIcons.lot,
        selectedIcon: AppIcons.lotsSelected,
        guideTargetId: GuideTargetId.navLots,
        isActive: isPrimaryActive(1),
        onTap: () => onSelectPrimaryTab(1),
      ),
    ResponsiveNavSectionItem(
      id: 'processes',
      label: l10n.navProcesses,
      icon: AppIcons.process,
      selectedIcon: AppIcons.process,
      isActive: isPrimaryActive(4),
      onTap: () => onSelectPrimaryTab(4),
    ),
    ResponsiveNavSectionItem(
      id: 'designsColours',
      label: l10n.navDesignsColours,
      icon: AppIcons.designs,
      isActive: activeExtraId == 'designsColours',
      onTap: () => onOpenExtraRoute(RoutePaths.designsColours),
    ),
    ResponsiveNavSectionItem(
      id: 'productionHistory',
      label: l10n.navProductionHistory,
      icon: AppIcons.productionHistory,
      isActive: activeExtraId == 'productionHistory',
      onTap: () => onOpenExtraRoute(RoutePaths.productionHistory),
    ),
    ResponsiveNavSectionItem(
      id: 'processHistory',
      label: l10n.navProcessHistory,
      icon: AppIcons.processHistory,
      isActive: activeExtraId == 'processHistory',
      onTap: () => onOpenExtraRoute(RoutePaths.processProductionHistory),
    ),
  ];

  final stockQcItems = <ResponsiveNavSectionItem>[
    if (includeCoreTabs)
      ResponsiveNavSectionItem(
        id: 'stock',
        label: l10n.navStockMovements,
        icon: AppIcons.stockMovements,
        selectedIcon: AppIcons.stockMovements,
        guideTargetId: GuideTargetId.navStock,
        isActive: isPrimaryActive(2),
        onTap: () => onSelectPrimaryTab(2),
      ),
    ResponsiveNavSectionItem(
      id: 'inventory',
      label: l10n.navInventory,
      icon: AppIcons.inventory,
      isActive: activeExtraId == 'inventory',
      onTap: () => onOpenExtraRoute(RoutePaths.inventory),
    ),
    ResponsiveNavSectionItem(
      id: 'inspectionQueue',
      label: l10n.navInspectionQueue,
      icon: AppIcons.qcInspect,
      isActive: activeExtraId == 'inspectionQueue',
      onTap: () => onOpenExtraRoute(RoutePaths.inspectionQueue),
    ),
  ];

  final financePartiesItems = <ResponsiveNavSectionItem>[
    if (includeCoreTabs)
      ResponsiveNavSectionItem(
        id: 'workers',
        label: l10n.navWorkers,
        icon: AppIcons.workers,
        selectedIcon: AppIcons.workersSelected,
        guideTargetId: GuideTargetId.navWorkers,
        isActive: isPrimaryActive(3),
        onTap: () => onSelectPrimaryTab(3),
      ),
    ResponsiveNavSectionItem(
      id: 'accounting',
      label: l10n.navAccounting,
      icon: AppIcons.accounting,
      isActive: activeExtraId == 'accounting',
      onTap: () => onOpenExtraRoute(RoutePaths.accounting),
    ),
    ResponsiveNavSectionItem(
      id: 'parties',
      label: l10n.navPartiesDispatch,
      icon: AppIcons.party,
      isActive: activeExtraId == 'parties',
      onTap: () => onOpenExtraRoute(RoutePaths.parties),
    ),
    ResponsiveNavSectionItem(
      id: 'reports',
      label: l10n.navReports,
      icon: AppIcons.reports,
      isActive: activeExtraId == 'reports',
      onTap: () => onOpenExtraRoute(RoutePaths.reports),
    ),
  ];

  final systemItems = <ResponsiveNavSectionItem>[
    ResponsiveNavSectionItem(
      id: 'settings',
      label: l10n.navSettings,
      icon: AppIcons.settings,
      selectedIcon: AppIcons.settingsSelected,
      badgeCount: syncAttentionBadge,
      guideTargetId: GuideTargetId.navSettings,
      isActive: isPrimaryActive(5),
      onTap: () => onSelectPrimaryTab(5),
    ),
    ResponsiveNavSectionItem(
      id: 'help',
      label: l10n.settingsHelpTitle,
      icon: AppIcons.guide,
      isActive: activeExtraId == 'help',
      onTap: () => onOpenExtraRoute(RoutePaths.settingsHelp),
    ),
  ];

  return [
    if (includeCoreTabs)
      ResponsiveNavSection(
        id: 'overview',
        title: l10n.navSectionOverview,
        collapsible: false,
        items: [
          ResponsiveNavSectionItem(
            id: 'dashboard',
            label: l10n.navDashboard,
            icon: AppIcons.dashboard,
            selectedIcon: AppIcons.dashboardSelected,
            guideTargetId: GuideTargetId.navHome,
            isActive: isPrimaryActive(0),
            onTap: () => onSelectPrimaryTab(0),
          ),
        ],
      ),
    ResponsiveNavSection(
      id: 'production',
      title: l10n.navSectionProduction,
      items: productionItems,
    ),
    ResponsiveNavSection(
      id: 'stock_qc',
      title: l10n.navSectionStockQc,
      items: stockQcItems,
    ),
    ResponsiveNavSection(
      id: 'finance_parties',
      title: l10n.navSectionFinanceParties,
      items: financePartiesItems,
    ),
    ResponsiveNavSection(
      id: 'system',
      title: l10n.navSectionSystem,
      items: systemItems,
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
/// - On Compact mobile (`< 600dp`), renders the Mobile AppBar and compact 4+1
///   frosted-glass Bottom Bar ([StitchFlowBottomNav]) inside this page itself,
///   so pushing any detail/form sibling route transitions cleanly OVER the tab
///   chrome with zero layout jump or unmount blink.
/// - On Tablet / Desktop (`>= 600dp`), renders the tab stack directly because
///   [StitchFlowShellScaffold] already provides the persistent Side Navigator.
final class PrimaryTabsViewport extends StatelessWidget {
  const PrimaryTabsViewport({
    super.key,
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
    final syncAttentionBadge = _readSyncAttentionBadge(context);
    final lockState = context.watch<AppLockCubit?>()?.state;

    final moreSections = _buildGroupedSections(
      context,
      includeCoreTabs: false,
      selectedPrimaryIndex: navigationShell.currentIndex,
      activeExtraId: null,
      onSelectPrimaryTab: _onSelectTab,
      onOpenExtraRoute: (route) => router.push(route),
      syncAttentionBadge: syncAttentionBadge,
    );

    final footerActions = <ResponsiveNavActionItem>[
      if (lockState != null && lockState.isPinEnabled)
        ResponsiveNavActionItem(
          id: 'lock',
          label: l10n.securityLockNowAction,
          icon: AppIcons.lock,
          onTap: () => context.read<AppLockCubit>().lockNow(),
        ),
    ];

    return ResponsiveNavigation(
      title: appTitle,
      subtitle: l10n.appTagline,
      selectedIndex: navigationShell.currentIndex,
      showMobileChrome: true,
      onDestinationSelected: _onSelectTab,
      destinations: _buildMobileCoreDestinations(context),
      mobileMoreSections: moreSections,
      mobileSheetFooterActions: footerActions,
      isMoreActive: navigationShell.currentIndex >= 4,
      moreLabel: l10n.navMore,
      allModulesTitle: l10n.navAllModules,
      moreBadgeCount: syncAttentionBadge,
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
      ],
      body: tabStack,
    );
  }
}

/// Persistent adaptive GoRouter shell:
/// - Keeps Desktop / Web toggleable Side Navigator & Tablet Rail mounted
///   across all 45+ routes
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
    if (location.startsWith(RoutePaths.parties) ||
        location.startsWith('/dispatch')) {
      return 'parties';
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

    if (location.startsWith(RoutePaths.parties) ||
        location.startsWith('/dispatch')) {
      items.add(
        AppBreadcrumbItem(
          label: l10n.navPartiesDispatch,
          onTap: location == RoutePaths.parties
              ? null
              : () => context.go(RoutePaths.parties),
        ),
      );
      if (location == RoutePaths.partyCreate) {
        items.add(AppBreadcrumbItem(label: l10n.partyAddAction));
      } else if (location.startsWith('/dispatch')) {
        items.add(AppBreadcrumbItem(label: l10n.dispatchDetailHeading));
      } else if (location.endsWith('/return')) {
        items.add(AppBreadcrumbItem(label: l10n.buyerReturnNewAction));
      } else if (location.endsWith('/payment')) {
        items.add(AppBreadcrumbItem(label: l10n.partyPaymentNewAction));
      }
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
                navigatePrimaryTab(context, idx, tabRefreshBus),
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
    final syncAttentionBadge = _readSyncAttentionBadge(context);
    final selectedPrimary = _selectedPrimaryIndex;
    final activeExtra = _activeExtraId;

    final groupedSections = _buildGroupedSections(
      context,
      includeCoreTabs: true,
      selectedPrimaryIndex: selectedPrimary,
      activeExtraId: activeExtra,
      onSelectPrimaryTab: (idx) =>
          navigatePrimaryTab(context, idx, tabRefreshBus),
      onOpenExtraRoute: (route) => context.go(route),
      syncAttentionBadge: syncAttentionBadge,
    );

    return _RootBackGuard(
      location: location,
      tabRefreshBus: tabRefreshBus,
      child: ResponsiveNavigation(
        title: appTitle,
        subtitle: l10n.appTagline,
        selectedIndex: selectedPrimary,
        activeExtraActionId: activeExtra,
        showMobileChrome: _isPrimaryRootRoute,
        breadcrumbs: _buildBreadcrumbs(context),
        sections: groupedSections,
        destinations: _buildMobileCoreDestinations(context),
        onDestinationSelected: (idx) =>
            navigatePrimaryTab(context, idx, tabRefreshBus),
        onSearchPressed: () => showGlobalSearch(context),
        searchTooltip: l10n.uxSearchTooltip,
        extraShortcuts: {
          const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
              showGlobalSearch(context),
          const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
              showGlobalSearch(context),
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              GoRouter.of(context).routerDelegate.popRoute(),
          const SingleActivator(LogicalKeyboardKey.digit6, alt: true): () =>
              navigatePrimaryTab(context, 5, tabRefreshBus),
          const SingleActivator(LogicalKeyboardKey.digit5, alt: true): () =>
              navigatePrimaryTab(context, 4, tabRefreshBus),
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
          GuideTarget(
            id: GuideTargetId.appBarGuide,
            child: AppIconButton(
              icon: AppIcons.help,
              tooltip: l10n.guideTooltip,
              onPressed: () => GuideQuickMenuSheet.show(context),
            ),
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
          navigatePrimaryTab(context, 0, tabRefreshBus);
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
