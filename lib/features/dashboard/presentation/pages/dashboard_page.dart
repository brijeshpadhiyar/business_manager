import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_identity.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/domain_label_localizer.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:business_manager/features/reports/domain/calculators/workshop_daily_calculator.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

final class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.config,
    required this.onNavigateTab,
    this.refreshSignal,
  });

  final AppConfig config;
  final ValueChanged<int> onNavigateTab;
  final ValueListenable<int>? refreshSignal;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardCubit>(
      create: (_) => getIt<DashboardCubit>()..loadDashboard(),
      child: _DashboardView(
        config: config,
        onNavigateTab: onNavigateTab,
        refreshSignal: refreshSignal,
      ),
    );
  }
}

final class _DashboardView extends StatefulWidget {
  const _DashboardView({
    required this.config,
    required this.onNavigateTab,
    this.refreshSignal,
  });

  final AppConfig config;
  final ValueChanged<int> onNavigateTab;
  final ValueListenable<int>? refreshSignal;

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

final class _DashboardViewState extends State<_DashboardView> {
  @override
  void initState() {
    super.initState();
    widget.refreshSignal?.addListener(_onSilentRefresh);
  }

  @override
  void didUpdateWidget(covariant _DashboardView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshSignal != widget.refreshSignal) {
      oldWidget.refreshSignal?.removeListener(_onSilentRefresh);
      widget.refreshSignal?.addListener(_onSilentRefresh);
    }
  }

  @override
  void dispose() {
    widget.refreshSignal?.removeListener(_onSilentRefresh);
    super.dispose();
  }

  void _onSilentRefresh() {
    if (mounted) {
      context.read<DashboardCubit>().loadDashboard();
    }
  }

  Future<void> _pushAndRefresh(BuildContext context, String path) async {
    await context.push(path);
    if (context.mounted) {
      await context.read<DashboardCubit>().loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizing.maxContentWidth),
        child: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            final snap = state.snapshot;

            return RefreshIndicator(
              onRefresh: () => context.read<DashboardCubit>().loadDashboard(),
              child: ListView(
                padding: AppSpacing.screenAll,
                children: [
                  // 1. Branded Hero Banner (full glass blur preserved)
                  AppMotionEntrance(
                    index: 0,
                    child: AppCard(
                      glassStyle: AppGlassStyle.full,
                      blurSigma: 12,
                      gradient: isDark
                          ? AppColors.heroGradientDark
                          : AppColors.heroGradientLight,
                        borderColor: Colors.white.withValues(alpha: 0.16),
                        borderRadius: AppRadius.xlBorder,
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: AppRadius.lgBorder,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                              ),
                              child: Image.asset(
                                AppIdentity.symbolPngAsset,
                                width: 40,
                                height: 40,
                                cacheWidth: 120,
                                cacheHeight: 120,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.config.isDev
                                        ? l10n.appTitleDev
                                        : l10n.appTitle,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    snap != null
                                        ? (localeCode == 'gu'
                                              ? snap.businessNameGu
                                              : snap.businessNameEn)
                                        : l10n.appTagline,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Colors.white.withValues(
                                            alpha: 0.88,
                                          ),
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            BlocSelector<AppLockCubit, AppLockState, bool>(
                              selector: (s) => s.isPinEnabled,
                              builder: (context, isPinEnabled) {
                                if (!isPinEnabled) {
                                  return const SizedBox.shrink();
                                }
                                return IconButton(
                                  tooltip: l10n.securityLockNowAction,
                                  onPressed: () =>
                                      context.read<AppLockCubit>().lockNow(),
                                  icon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              tooltip: l10n.actionRetry,
                              onPressed: () => context
                                  .read<DashboardCubit>()
                                  .loadDashboard(),
                              icon: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),

                  // 2. Daily Workshop Quick Operations Dock
                  AppMotionEntrance(
                    index: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppHeading(
                          l10n.dashboardQuickActions,
                          level: AppHeadingLevel.h3,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            AppButton(
                              label: l10n.stockIssueAction,
                              icon: Icons.outbox_rounded,
                              onPressed: () => _pushAndRefresh(
                                context,
                                RoutePaths.stockIssue(),
                              ),
                            ),
                            AppButton(
                              label: l10n.stockReturnAction,
                              icon: Icons.assignment_returned_outlined,
                              variant: AppButtonVariant.secondary,
                              onPressed: () => _pushAndRefresh(
                                context,
                                RoutePaths.stockReturnPicker,
                              ),
                            ),
                            AppButton(
                              label: l10n.dashboardDailySummaryAction,
                              icon: Icons.today_rounded,
                              variant: AppButtonVariant.outlined,
                              onPressed: () => _pushAndRefresh(
                                context,
                                RoutePaths.dailySummary,
                              ),
                            ),
                            AppButton(
                              label: l10n.navAccounting,
                              icon: Icons.account_balance_wallet_outlined,
                              variant: AppButtonVariant.outlined,
                              onPressed: () => _pushAndRefresh(
                                context,
                                RoutePaths.accounting,
                              ),
                            ),
                            AppButton(
                              label: l10n.navStockMovements,
                              icon: Icons.swap_horiz_rounded,
                              variant: AppButtonVariant.outlined,
                              onPressed: () => _pushAndRefresh(
                                context,
                                RoutePaths.stockMovements,
                              ),
                            ),
                            AppButton(
                              label: l10n.navProcesses,
                              icon: Icons.precision_manufacturing_outlined,
                              variant: AppButtonVariant.outlined,
                              onPressed: () => _pushAndRefresh(
                                context,
                                RoutePaths.processes,
                              ),
                            ),
                            AppButton(
                              label: l10n.navInventory,
                              icon: Icons.bar_chart_outlined,
                              variant: AppButtonVariant.outlined,
                              onPressed: () => _pushAndRefresh(
                                context,
                                RoutePaths.inventory,
                              ),
                            ),
                            AppButton(
                              label: l10n.navReports,
                              icon: Icons.analytics_outlined,
                              variant: AppButtonVariant.outlined,
                              onPressed: () => _pushAndRefresh(
                                context,
                                RoutePaths.reports,
                              ),
                            ),
                            AppButton(
                              label: l10n.navProductionHistory,
                              icon: Icons.history_rounded,
                              variant: AppButtonVariant.outlined,
                              onPressed: () => _pushAndRefresh(
                                context,
                                RoutePaths.productionHistory,
                              ),
                            ),
                            AppButton(
                              label: l10n.navInspectionQueue,
                              icon: Icons.fact_check_outlined,
                              variant: AppButtonVariant.outlined,
                              onPressed: () => _pushAndRefresh(
                                context,
                                RoutePaths.inspectionQueue,
                              ),
                            ),
                            if (widget.config.isDev)
                              AppButton(
                                label: l10n.navDesignShowcase,
                                icon: Icons.palette_outlined,
                                variant: AppButtonVariant.text,
                                onPressed: () =>
                                    context.push(RoutePaths.showcase),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (snap != null) ...[
                    // 2B. Today's Workshop Activity (IST Business Day)
                    AppMotionEntrance(
                      index: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppHeading(
                            l10n.dashboardTodayHeading,
                            level: AppHeadingLevel.h3,
                            trailing: AppButton(
                              label: l10n.dashboardDailySummaryAction,
                              variant: AppButtonVariant.text,
                              onPressed: () => _pushAndRefresh(
                                context,
                                RoutePaths.dailySummary,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 700;
                              final tileW = isWide
                                  ? (constraints.maxWidth - AppSpacing.sm * 3) /
                                        4
                                  : (constraints.maxWidth - AppSpacing.sm) / 2;
                              return Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  SizedBox(
                                    width: tileW,
                                    child: AppMetricTile(
                                      label: l10n.dashboardTodayIssuedLabel,
                                      value: snap.todayIssuedQty,
                                      suffix: l10n.piecesUnit,
                                      icon: Icons.outbox_rounded,
                                      tone: AppStatusTone.info,
                                      onTap: () => _pushAndRefresh(
                                        context,
                                        RoutePaths.dailySummary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: tileW,
                                    child: AppMetricTile(
                                      backdropKey: null,
                                      label: l10n.dashboardTodayReturnedLabel,
                                      value: snap.todayReceivedGoodQty,
                                      suffix: l10n.piecesUnit,
                                      icon: Icons.check_circle_outline_rounded,
                                      tone: AppStatusTone.good,
                                      onTap: () => _pushAndRefresh(
                                        context,
                                        RoutePaths.dailySummary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: tileW,
                                    child: AppMetricTile(
                                      backdropKey: null,
                                      label: l10n.dashboardTodayLabourLabel,
                                      value: snap.todayLabourEarnedPaise,
                                      isCurrencyPaise: true,
                                      icon: Icons.work_outline_rounded,
                                      tone: AppStatusTone.good,
                                      onTap: () => _pushAndRefresh(
                                        context,
                                        RoutePaths.dailySummary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: tileW,
                                    child: AppMetricTile(
                                      backdropKey: null,
                                      label: l10n.dashboardTodayPaymentsLabel,
                                      value: snap.todayPaymentsPaise,
                                      isCurrencyPaise: true,
                                      icon: Icons.payments_outlined,
                                      tone: AppStatusTone.neutral,
                                      onTap: () => _pushAndRefresh(
                                        context,
                                        RoutePaths.accounting,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          if (snap.todayDamagedQty + snap.todayLostShortageQty >
                              0) ...[
                            const SizedBox(height: AppSpacing.xs),
                            AppStatusBadge(
                              label:
                                  '${l10n.dashboardTodayDamagedLostAlert}: ${snap.todayDamagedQty + snap.todayLostShortageQty} ${l10n.piecesUnit}',
                              tone: AppStatusTone.damaged,
                              icon: Icons.warning_amber_rounded,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 2C. Important & Oldest Pending Work
                    if (snap.importantPendingIssues.isNotEmpty) ...[
                      AppMotionEntrance(
                        index: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            AppHeading(
                              l10n.dashboardImportantPendingHeading,
                              level: AppHeadingLevel.h3,
                              trailing: AppButton(
                                label: l10n.dashboardViewAllPendingAction,
                                variant: AppButtonVariant.text,
                                onPressed: () => _pushAndRefresh(
                                  context,
                                  RoutePaths.stockReturnPicker,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            AppCard.listItem(
                              child: Column(
                                children: [
                                  for (
                                    var i = 0;
                                    i < snap.importantPendingIssues.length;
                                    i++
                                  ) ...[
                                    Builder(
                                      builder: (context) {
                                        final item =
                                            snap.importantPendingIssues[i];
                                        final v = item.issueView;
                                        final ageDays =
                                            WorkshopDailyCalculator
                                                .pendingAgeDays(
                                                  v.movement.transactionAt,
                                                  IstDateTimeHelper
                                                      .nowUtcMillis(),
                                                );
                                        final ageLabel = ageDays == 0
                                            ? l10n.reportPresetToday
                                            : l10n.pendingAgeDaysBadge(ageDays);
                                        return InkWell(
                                          onTap: () => _pushAndRefresh(
                                            context,
                                            RoutePaths.stockReturn(
                                              v.movement.id,
                                            ),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: AppSpacing.xs,
                                            ),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      AppText(
                                                        '${v.workerName ?? '-'} • ${v.processName ?? '-'}',
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                      AppText(
                                                        '${v.lotNumber} • ${v.designName} • ${v.colourName}',
                                                        variant: AppTextVariant
                                                            .bodySmall,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .onSurfaceVariant,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(
                                                  width: AppSpacing.xs,
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    AppStatusBadge(
                                                      label:
                                                          '${item.remainingPending} ${l10n.piecesUnit}',
                                                      tone:
                                                          AppStatusTone.pending,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    AppText(
                                                      ageLabel,
                                                      variant: AppTextVariant
                                                          .bodySmall,
                                                      color: ageDays >= 7
                                                          ? Theme.of(
                                                              context,
                                                            ).colorScheme.error
                                                          : Theme.of(context)
                                                                .colorScheme
                                                                .onSurfaceVariant,
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    if (i <
                                        snap.importantPendingIssues.length - 1)
                                      const Divider(),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ],

                  // 3. Live Stock & Production Health KPIs
                  AppMotionEntrance(
                    index: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppHeading(
                          l10n.dashboardStockHealth,
                          level: AppHeadingLevel.h3,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        AppStateTransition(
                          stateKey: ValueKey<bool>(
                            state.status == DashboardStatus.loading &&
                                snap == null,
                          ),
                          child:
                              state.status == DashboardStatus.loading &&
                                  snap == null
                              ? const AppSkeletonList(itemCount: 2)
                              : snap == null
                              ? const SizedBox.shrink()
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isWide = constraints.maxWidth >= 700;
                                    final tileW = isWide
                                        ? (constraints.maxWidth -
                                                  AppSpacing.sm * 3) /
                                              4
                                        : (constraints.maxWidth -
                                                  AppSpacing.sm) /
                                              2;
                                    return Wrap(
                                      spacing: AppSpacing.sm,
                                      runSpacing: AppSpacing.sm,
                                      children: [
                                        SizedBox(
                                          width: tileW,
                                          child: AppMetricTile(
                                            backdropKey: null,
                                            label: l10n.dashboardTotalLotsLabel,
                                            value: snap.totalLots,
                                            subtitle:
                                                '${snap.totalDesigns} / ${snap.totalColours} ${l10n.dashboardTotalDesignsColoursLabel}',
                                            icon: Icons.inventory_2_outlined,
                                            tone: AppStatusTone.neutral,
                                            onTap: () => widget.onNavigateTab(1),
                                          ),
                                        ),
                                        SizedBox(
                                          width: tileW,
                                          child: AppMetricTile(
                                            backdropKey: null,
                                            label: l10n.stockAvailableGoodLabel,
                                            value: snap.availableGoodStock,
                                            suffix: l10n.piecesUnit,
                                            icon: Icons
                                                .check_circle_outline_rounded,
                                            tone: AppStatusTone.good,
                                            onTap: () => _pushAndRefresh(
                                              context,
                                              RoutePaths.stockMovements,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: tileW,
                                          child: AppMetricTile(
                                            backdropKey: null,
                                            label:
                                                l10n.stockPendingWorkerLabel,
                                            value: snap.pendingWorkerStock,
                                            suffix: l10n.piecesUnit,
                                            icon: Icons.pending_actions_rounded,
                                            tone: snap.pendingWorkerStock > 0
                                                ? AppStatusTone.pending
                                                : AppStatusTone.good,
                                            onTap: () => _pushAndRefresh(
                                              context,
                                              RoutePaths.stockReturnPicker,
                                            ),
                                          ),
                                        ),
                                        SizedBox(
                                          width: tileW,
                                          child: AppMetricTile(
                                            backdropKey: null,
                                            label:
                                                l10n.stockDamagedBucketLabel,
                                            value: snap.damagedStock,
                                            suffix: l10n.piecesUnit,
                                            icon: Icons.report_problem_outlined,
                                            tone: snap.damagedStock > 0
                                                ? AppStatusTone.damaged
                                                : AppStatusTone.neutral,
                                            onTap: () => _pushAndRefresh(
                                              context,
                                              RoutePaths.stockRepair,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                  if (snap != null) ...[
                    const SizedBox(height: AppSpacing.lg),

                    // 4. Live Financial & Worker Accounting Summary
                    AppMotionEntrance(
                      index: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppHeading(
                            l10n.dashboardFinanceHealth,
                            level: AppHeadingLevel.h3,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 700;
                              final tileW = isWide
                                  ? (constraints.maxWidth - AppSpacing.sm * 3) /
                                        4
                                  : (constraints.maxWidth - AppSpacing.sm) / 2;
                              return Wrap(
                                spacing: AppSpacing.sm,
                                runSpacing: AppSpacing.sm,
                                children: [
                                  SizedBox(
                                    width: tileW,
                                    child: AppMetricTile(
                                      backdropKey: null,
                                      label: l10n.accountingEarnedLabourLabel,
                                      value: snap.totalEarnedLabourPaise,
                                      isCurrencyPaise: true,
                                      icon: Icons.work_outline_rounded,
                                      tone: AppStatusTone.good,
                                      onTap: () => _pushAndRefresh(
                                        context,
                                        RoutePaths.accounting,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: tileW,
                                    child: AppMetricTile(
                                      backdropKey: null,
                                      label: l10n
                                          .accountingOutstandingPayableLabel,
                                      value: snap.totalOutstandingPayablePaise,
                                      isCurrencyPaise: true,
                                      icon: Icons
                                          .account_balance_wallet_outlined,
                                      tone:
                                          snap.totalOutstandingPayablePaise > 0
                                          ? AppStatusTone.pending
                                          : AppStatusTone.good,
                                      onTap: () => _pushAndRefresh(
                                        context,
                                        RoutePaths.accounting,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: tileW,
                                    child: AppMetricTile(
                                      backdropKey: null,
                                      label: l10n.accountingAdvanceCreditLabel,
                                      value: snap.totalAdvanceCreditPaise,
                                      isCurrencyPaise: true,
                                      subtitle:
                                          '${l10n.accountingAdvancePaidLabel}: ${MoneyFormatter.formatPaise(snap.totalAdvancePaymentsPaise)}',
                                      icon: Icons.trending_up_rounded,
                                      tone: AppStatusTone.info,
                                      onTap: () => _pushAndRefresh(
                                        context,
                                        RoutePaths.accounting,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: tileW,
                                    child: AppMetricTile(
                                      backdropKey: null,
                                      label: l10n.accountingRegularPaidLabel,
                                      value: snap.totalRegularPaymentsPaise,
                                      isCurrencyPaise: true,
                                      icon: Icons.payments_outlined,
                                      tone: AppStatusTone.neutral,
                                      onTap: () => _pushAndRefresh(
                                        context,
                                        RoutePaths.accounting,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 5. Process-wise Pending Breakdown
                    AppMotionEntrance(
                      index: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppHeading(
                            l10n.dashboardProcessPending,
                            level: AppHeadingLevel.h3,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (snap.processPendingList.isEmpty)
                            AppCard.listItem(
                              child: AppText(
                                l10n.dashboardNoProcessPending,
                                variant: AppTextVariant.bodySmall,
                              ),
                            )
                          else
                            AppCard.listItem(
                              child: Column(
                                children: [
                                  for (
                                    int i = 0;
                                    i < snap.processPendingList.length;
                                    i++
                                  ) ...[
                                    InkWell(
                                      onTap: () => _pushAndRefresh(
                                        context,
                                        RoutePaths.stockReturnPickerFiltered(
                                          processId: snap
                                              .processPendingList[i]
                                              .processId,
                                        ),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: AppSpacing.xs,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  AppText(
                                                    snap
                                                        .processPendingList[i]
                                                        .processName,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  AppText(
                                                    '${l10n.stockIssuedLabel}: ${snap.processPendingList[i].issued} ${l10n.piecesUnit}',
                                                    variant: AppTextVariant
                                                        .bodySmall,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurfaceVariant,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.sm,
                                            ),
                                            AppStatusBadge(
                                              label:
                                                  '${snap.processPendingList[i].pending} ${l10n.piecesUnit}',
                                              tone:
                                                  snap
                                                          .processPendingList[i]
                                                          .pending >
                                                      0
                                                  ? AppStatusTone.pending
                                                  : AppStatusTone.good,
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.xs,
                                            ),
                                            const Icon(
                                              Icons.chevron_right_rounded,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (i < snap.processPendingList.length - 1)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: AppSpacing.sm,
                                        ),
                                        child: Divider(),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 6. Recent Audit Activity (localized labels, clean mobile wrap)
                    AppMotionEntrance(
                      index: 7,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AppHeading(
                            l10n.dashboardRecentActivity,
                            level: AppHeadingLevel.h3,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          if (snap.recentActivity.isEmpty)
                            AppCard.listItem(
                              child: AppText(
                                l10n.dashboardNoRecentActivity,
                                variant: AppTextVariant.bodySmall,
                              ),
                            )
                          else
                            AppCard.listItem(
                              child: Column(
                                children: [
                                  for (
                                    int i = 0;
                                    i < snap.recentActivity.length.clamp(0, 6);
                                    i++
                                  ) ...[
                                    Wrap(
                                      spacing: AppSpacing.sm,
                                      runSpacing: AppSpacing.xs,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        AppStatusBadge(
                                          label:
                                              DomainLabelLocalizer.auditAction(
                                                l10n,
                                                snap
                                                    .recentActivity[i]
                                                    .actionType,
                                              ),
                                          tone:
                                              snap
                                                      .recentActivity[i]
                                                      .actionType ==
                                                  'REVERSAL'
                                              ? AppStatusTone.damaged
                                              : AppStatusTone.info,
                                        ),
                                        AppText(
                                          DomainLabelLocalizer.auditEntity(
                                            l10n,
                                            snap.recentActivity[i].entityType,
                                          ),
                                          fontWeight: FontWeight.w600,
                                        ),
                                        AppText(
                                          IstDateTimeHelper.formatIstDateTime(
                                            snap.recentActivity[i].recordedAt,
                                            locale: localeCode,
                                          ),
                                          variant: AppTextVariant.bodySmall,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                    if (i <
                                        snap.recentActivity.length.clamp(0, 6) -
                                            1)
                                      const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: AppSpacing.xs + 2,
                                        ),
                                        child: Divider(),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
