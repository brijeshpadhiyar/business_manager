import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_identity.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:business_manager/features/dashboard/presentation/widgets/dashboard_sections.dart';
import 'package:business_manager/features/dashboard/presentation/widgets/setup_checklist_card.dart';
import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';
import 'package:business_manager/features/guidance/presentation/registry/guide_target_registry.dart';
import 'package:business_manager/features/guidance/presentation/widgets/first_time_welcome_card.dart';
import 'package:business_manager/features/search/presentation/quick_actions.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

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
        constraints: const BoxConstraints(maxWidth: AppSizing.wideContentWidth),
        child: BlocBuilder<DashboardCubit, DashboardState>(
          buildWhen: (prev, curr) =>
              prev.status != curr.status ||
              prev.snapshot != curr.snapshot ||
              prev.errorMessage != curr.errorMessage ||
              prev.weekTrend != curr.weekTrend,
          builder: (context, state) {
            final snap = state.snapshot;

            return RefreshIndicator(
              onRefresh: () => context.read<DashboardCubit>().loadDashboard(),
              child: ListView(
                padding: AppSpacing.screenAll,
                children: [
                  if (state.status == DashboardStatus.error) ...[
                    AppCard(
                      child: AppErrorView(
                        title: l10n.errorUnexpected,
                        retryLabel: l10n.actionRetry,
                        onRetry: () =>
                            context.read<DashboardCubit>().loadDashboard(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  // 1. Branded Hero Banner (full glass blur preserved)
                  AppMotionEntrance(
                    index: 0,
                    child: AppCard(
                      glassStyle: AppGlassStyle.full,
                      blurSigma: 12,
                      gradient: isDark
                          ? AppColors.heroGradientDark
                          : AppColors.heroGradientLight,
                      borderColor: AppColors.onHero.withValues(alpha: 0.16),
                      borderRadius: AppRadius.xlBorder,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.onHero.withValues(alpha: 0.14),
                              borderRadius: AppRadius.lgBorder,
                              border: Border.all(
                                color: AppColors.onHero.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Image.asset(
                              AppIdentity.symbolPngAsset,
                              width: 40,
                              height: 40,
                              cacheWidth: 120,
                              cacheHeight: 120,
                              errorBuilder: (_, _, _) => const Icon(
                                AppIcons.brand,
                                color: AppColors.onHero,
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
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        color: AppColors.onHero,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  snap != null
                                      ? (localeCode == 'gu'
                                            ? snap.businessNameGu
                                            : snap.businessNameEn)
                                      : l10n.appTagline,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(color: AppColors.onHeroMuted),
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
                              return AppIconButton(
                                tooltip: l10n.securityLockNowAction,
                                onPressed: () =>
                                    context.read<AppLockCubit>().lockNow(),
                                icon: AppIcons.lock,
                                color: AppColors.onHero,
                              );
                            },
                          ),
                          AppIconButton(
                            tooltip: l10n.actionRetry,
                            onPressed: () =>
                                context.read<DashboardCubit>().loadDashboard(),
                            icon: AppIcons.refresh,
                            color: AppColors.onHero,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (snap != null) FirstTimeWelcomeCard(snapshot: snap),

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
                        // Everyday tasks as large one-tap tiles.
                        QuickActionsPanel(
                          showTitle: false,
                          onReturn: () {
                            if (context.mounted) {
                              context.read<DashboardCubit>().loadDashboard();
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Other screens as lighter secondary links.
                        AppCollapsibleFilters(
                          label: l10n.uxMoreScreens,
                          icon: AppIcons.moreScreens,
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              AppButton(
                                label: l10n.dashboardDailySummaryAction,
                                icon: AppIcons.dailySummary,
                                variant: AppButtonVariant.outlined,
                                onPressed: () => _pushAndRefresh(
                                  context,
                                  RoutePaths.dailySummary,
                                ),
                              ),
                              AppButton(
                                label: l10n.navAccounting,
                                icon: AppIcons.accounting,
                                variant: AppButtonVariant.outlined,
                                onPressed: () => _pushAndRefresh(
                                  context,
                                  RoutePaths.accounting,
                                ),
                              ),
                              AppButton(
                                label: l10n.navStockMovements,
                                icon: AppIcons.stockMovements,
                                variant: AppButtonVariant.outlined,
                                onPressed: () => widget.onNavigateTab(2),
                              ),
                              AppButton(
                                label: l10n.navInventory,
                                icon: AppIcons.inventory,
                                variant: AppButtonVariant.outlined,
                                onPressed: () => _pushAndRefresh(
                                  context,
                                  RoutePaths.inventory,
                                ),
                              ),
                              AppButton(
                                label: l10n.navReports,
                                icon: AppIcons.reports,
                                variant: AppButtonVariant.outlined,
                                onPressed: () => _pushAndRefresh(
                                  context,
                                  RoutePaths.reports,
                                ),
                              ),
                              AppButton(
                                label: l10n.navProductionHistory,
                                icon: AppIcons.productionHistory,
                                variant: AppButtonVariant.outlined,
                                onPressed: () => _pushAndRefresh(
                                  context,
                                  RoutePaths.productionHistory,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  if (snap != null)
                    GuideTarget(
                      id: GuideTargetId.dashSetupChecklist,
                      child: SetupChecklistCard(
                        snapshot: snap,
                        onNavigate: (route) => _pushAndRefresh(context, route),
                      ),
                    ),

                  if (snap != null) ...[
                    // 2B. Today's Workshop Activity (IST Business Day)
                    GuideTarget(
                      id: GuideTargetId.dashTodayKpis,
                      child: AppMotionEntrance(
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
                                    ? (constraints.maxWidth -
                                              AppSpacing.sm * 3) /
                                          4
                                    : (constraints.maxWidth - AppSpacing.sm) /
                                          2;
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
                                        icon: AppIcons.stockIssue,
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
                                        icon: AppIcons.successOutline,
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
                                        icon: AppIcons.work,
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
                                        icon: AppIcons.payment,
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
                            if (snap.todayDamagedQty +
                                    snap.todayLostShortageQty >
                                0) ...[
                              const SizedBox(height: AppSpacing.xs),
                              AppStatusBadge(
                                label:
                                    '${l10n.dashboardTodayDamagedLostAlert}: ${snap.todayDamagedQty + snap.todayLostShortageQty} ${l10n.piecesUnit}',
                                tone: AppStatusTone.damaged,
                                icon: AppIcons.warning,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 2B+. This week's issued vs good-returned trend.
                    if (state.weekTrend.any(
                      (p) => p.issuedQty > 0 || p.goodReturnedQty > 0,
                    )) ...[
                      DashboardWeekTrendSection(
                        weekTrend: state.weekTrend,
                        onPushAndRefresh: (path) =>
                            _pushAndRefresh(context, path),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],

                    // 2C. Important & Oldest Pending Work
                    if (snap.importantPendingIssues.isNotEmpty) ...[
                      DashboardImportantPendingSection(
                        snapshot: snap,
                        onPushAndRefresh: (path) =>
                            _pushAndRefresh(context, path),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ],

                  // 3. Live Stock & Production Health KPIs
                  DashboardStockHealthSection(
                    status: state.status,
                    snapshot: snap,
                    onNavigateTab: widget.onNavigateTab,
                    onPushAndRefresh: (path) => _pushAndRefresh(context, path),
                  ),
                  if (snap != null) ...[
                    const SizedBox(height: AppSpacing.lg),

                    // 4. Live Financial & Worker Accounting Summary
                    DashboardFinanceHealthSection(
                      snapshot: snap,
                      onPushAndRefresh: (path) =>
                          _pushAndRefresh(context, path),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 5. Process-wise Pending Breakdown
                    DashboardProcessPendingSection(
                      snapshot: snap,
                      onPushAndRefresh: (path) =>
                          _pushAndRefresh(context, path),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // 6. Recent Audit Activity (localized labels, clean mobile wrap)
                    DashboardRecentActivitySection(
                      snapshot: snap,
                      localeCode: localeCode,
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
