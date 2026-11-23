import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_identity.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/localization/locale_cubit.dart';
import 'package:business_manager/core/localization/locale_state.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/theme/theme_cubit.dart';
import 'package:business_manager/core/theme/theme_state.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/dashboard/presentation/bloc/dashboard_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

final class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.config,
    required this.onNavigateTab,
  });

  final AppConfig config;
  final ValueChanged<int> onNavigateTab;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DashboardCubit>(
      create: (_) => getIt<DashboardCubit>()..loadDashboard(),
      child: _DashboardView(config: config, onNavigateTab: onNavigateTab),
    );
  }
}

final class _DashboardView extends StatelessWidget {
  const _DashboardView({required this.config, required this.onNavigateTab});

  final AppConfig config;
  final ValueChanged<int> onNavigateTab;

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
                  // 1. Branded Hero Banner with subtle gradient & glass badge
                  AppMotionEntrance(
                    index: 0,
                    child: AppCard(
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
                                  config.isDev
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
                          IconButton(
                            tooltip: l10n.actionRetry,
                            onPressed: () =>
                                context.read<DashboardCubit>().loadDashboard(),
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

                  // 2. Quick Operations Dock (1-tap access to all core workflows)
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
                        onPressed: () =>
                            _pushAndRefresh(context, RoutePaths.stockIssue()),
                      ),
                      AppButton(
                        label: l10n.navStockMovements,
                        icon: Icons.swap_horiz_rounded,
                        variant: AppButtonVariant.secondary,
                        onPressed: () =>
                            _pushAndRefresh(context, RoutePaths.stockMovements),
                      ),
                      AppButton(
                        label: l10n.navAccounting,
                        icon: Icons.account_balance_wallet_outlined,
                        variant: AppButtonVariant.secondary,
                        onPressed: () =>
                            _pushAndRefresh(context, RoutePaths.accounting),
                      ),
                      AppButton(
                        label: l10n.navReports,
                        icon: Icons.analytics_outlined,
                        variant: AppButtonVariant.outlined,
                        onPressed: () =>
                            _pushAndRefresh(context, RoutePaths.reports),
                      ),
                      AppButton(
                        label: l10n.navBackupRestore,
                        icon: Icons.backup_outlined,
                        variant: AppButtonVariant.outlined,
                        onPressed: () =>
                            _pushAndRefresh(context, RoutePaths.backupRestore),
                      ),
                      if (config.isDev)
                        AppButton(
                          label: l10n.navDesignShowcase,
                          icon: Icons.palette_outlined,
                          variant: AppButtonVariant.text,
                          onPressed: () => context.push(RoutePaths.showcase),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // 3. Live Stock & Production Health KPIs
                  AppHeading(
                    l10n.dashboardStockHealth,
                    level: AppHeadingLevel.h3,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (state.status == DashboardStatus.loading && snap == null)
                    const AppSkeletonList(itemCount: 2)
                  else if (snap != null) ...[
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 700;
                        final tileW = isWide
                            ? (constraints.maxWidth - AppSpacing.sm * 3) / 4
                            : (constraints.maxWidth - AppSpacing.sm) / 2;
                        return Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            SizedBox(
                              width: tileW,
                              child: AppMetricTile(
                                label: l10n.dashboardTotalLotsLabel,
                                value: snap.totalLots,
                                subtitle:
                                    '${snap.totalDesigns} / ${snap.totalColours} ${l10n.dashboardTotalDesignsColoursLabel}',
                                icon: Icons.inventory_2_outlined,
                                tone: AppStatusTone.neutral,
                                onTap: () => onNavigateTab(1),
                              ),
                            ),
                            SizedBox(
                              width: tileW,
                              child: AppMetricTile(
                                label: l10n.stockAvailableGoodLabel,
                                value: snap.availableGoodStock,
                                suffix: l10n.piecesUnit,
                                icon: Icons.check_circle_outline_rounded,
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
                                label: l10n.stockPendingWorkerLabel,
                                value: snap.pendingWorkerStock,
                                suffix: l10n.piecesUnit,
                                icon: Icons.pending_actions_rounded,
                                tone: snap.pendingWorkerStock > 0
                                    ? AppStatusTone.pending
                                    : AppStatusTone.good,
                                onTap: () => _pushAndRefresh(
                                  context,
                                  RoutePaths.stockMovements,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: tileW,
                              child: AppMetricTile(
                                label: l10n.stockDamagedBucketLabel,
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
                    const SizedBox(height: AppSpacing.lg),

                    // 4. Live Financial & Worker Accounting Summary
                    AppHeading(
                      l10n.dashboardFinanceHealth,
                      level: AppHeadingLevel.h3,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 700;
                        final tileW = isWide
                            ? (constraints.maxWidth - AppSpacing.sm * 3) / 4
                            : (constraints.maxWidth - AppSpacing.sm) / 2;
                        return Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            SizedBox(
                              width: tileW,
                              child: AppMetricTile(
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
                                label: l10n.accountingOutstandingPayableLabel,
                                value: snap.totalOutstandingPayablePaise,
                                isCurrencyPaise: true,
                                icon: Icons.account_balance_wallet_outlined,
                                tone: snap.totalOutstandingPayablePaise > 0
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
                    const SizedBox(height: AppSpacing.lg),

                    // 5. Process-wise Pending Breakdown
                    AppHeading(
                      l10n.dashboardProcessPending,
                      level: AppHeadingLevel.h3,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (snap.processPendingList.isEmpty)
                      AppCard(
                        child: AppText(
                          l10n.dashboardNoProcessPending,
                          variant: AppTextVariant.bodySmall,
                        ),
                      )
                    else
                      AppCard(
                        child: Column(
                          children: [
                            for (
                              int i = 0;
                              i < snap.processPendingList.length;
                              i++
                            ) ...[
                              Row(
                                children: [
                                  Expanded(
                                    child: AppText(
                                      snap.processPendingList[i].processName,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  AppText(
                                    '${l10n.stockIssuedLabel}: ${snap.processPendingList[i].issued}',
                                    variant: AppTextVariant.bodySmall,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  AppStatusBadge(
                                    label:
                                        '${snap.processPendingList[i].pending} ${l10n.piecesUnit}',
                                    tone: snap.processPendingList[i].pending > 0
                                        ? AppStatusTone.pending
                                        : AppStatusTone.good,
                                  ),
                                ],
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
                    const SizedBox(height: AppSpacing.lg),

                    // 6. Recent Audit Activity
                    AppHeading(
                      l10n.dashboardRecentActivity,
                      level: AppHeadingLevel.h3,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (snap.recentActivity.isEmpty)
                      AppCard(
                        child: AppText(
                          l10n.dashboardNoRecentActivity,
                          variant: AppTextVariant.bodySmall,
                        ),
                      )
                    else
                      AppCard(
                        child: Column(
                          children: [
                            for (
                              int i = 0;
                              i < snap.recentActivity.length.clamp(0, 6);
                              i++
                            ) ...[
                              Row(
                                children: [
                                  AppStatusBadge(
                                    label: snap.recentActivity[i].actionType,
                                    tone:
                                        snap.recentActivity[i].actionType ==
                                            'REVERSAL'
                                        ? AppStatusTone.damaged
                                        : AppStatusTone.info,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: AppText(
                                      snap.recentActivity[i].entityType,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  AppText(
                                    IstDateTimeHelper.formatIstDateTime(
                                      snap.recentActivity[i].recordedAt,
                                      locale: localeCode,
                                    ),
                                    variant: AppTextVariant.bodySmall,
                                  ),
                                ],
                              ),
                              if (i <
                                  snap.recentActivity.length.clamp(0, 6) - 1)
                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: AppSpacing.xs,
                                  ),
                                  child: Divider(),
                                ),
                            ],
                          ],
                        ),
                      ),
                  ],

                  const SizedBox(height: AppSpacing.lg),
                  AppHeading(
                    l10n.dashboardPreferences,
                    level: AppHeadingLevel.h3,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          l10n.themeSectionTitle,
                          variant: AppTextVariant.label,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        BlocBuilder<ThemeCubit, ThemeState>(
                          builder: (context, themeState) =>
                              SegmentedButton<AppThemePreference>(
                                segments: [
                                  ButtonSegment(
                                    value: AppThemePreference.system,
                                    label: Text(l10n.themeSystem),
                                  ),
                                  ButtonSegment(
                                    value: AppThemePreference.light,
                                    label: Text(l10n.themeLight),
                                  ),
                                  ButtonSegment(
                                    value: AppThemePreference.dark,
                                    label: Text(l10n.themeDark),
                                  ),
                                ],
                                selected: {themeState.preference},
                                onSelectionChanged: (s) => context
                                    .read<ThemeCubit>()
                                    .setPreference(s.first),
                              ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppText(
                          l10n.languageSectionTitle,
                          variant: AppTextVariant.label,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        BlocBuilder<LocaleCubit, LocaleState>(
                          builder: (context, localeState) =>
                              SegmentedButton<AppLocalePreference>(
                                segments: [
                                  ButtonSegment(
                                    value: AppLocalePreference.system,
                                    label: Text(l10n.languageSystemDefault),
                                  ),
                                  ButtonSegment(
                                    value: AppLocalePreference.en,
                                    label: Text(l10n.languageEnglish),
                                  ),
                                  ButtonSegment(
                                    value: AppLocalePreference.gu,
                                    label: Text(l10n.languageGujarati),
                                  ),
                                ],
                                selected: {localeState.preference},
                                onSelectionChanged: (s) => context
                                    .read<LocaleCubit>()
                                    .setPreference(s.first),
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
