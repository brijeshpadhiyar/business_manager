import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/cashbook/presentation/widgets/reports_cashbook_pnl_view.dart';
import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';
import 'package:business_manager/features/guidance/presentation/registry/guide_target_registry.dart';
import 'package:business_manager/features/guidance/presentation/widgets/screen_first_visit_hint.dart';
import 'package:business_manager/features/parties/presentation/widgets/reports_parties_pnl_view.dart';
import 'package:business_manager/features/reports/domain/entities/report_filter.dart';
import 'package:business_manager/features/reports/presentation/bloc/reports_cubit.dart';
import 'package:business_manager/features/reports/presentation/widgets/report_export_sheet.dart';
import 'package:business_manager/features/reports/presentation/widgets/report_filter_bar.dart';
import 'package:business_manager/features/reports/presentation/widgets/reports_category_views.dart';
import 'package:business_manager/features/reports/presentation/widgets/reports_tables.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// StitchFlow V1.2 unified 6-category Advanced Reports & Business Insights hub.
final class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    final initialCategory = ReportCategory
        .values[initialTab.clamp(0, ReportCategory.values.length - 1)];
    return BlocProvider<ReportsCubit>(
      create: (_) => getIt<ReportsCubit>()
        ..selectCategory(initialCategory)
        ..loadReports(),
      child: const _ReportsView(),
    );
  }
}

final class _ReportsView extends StatefulWidget {
  const _ReportsView();

  @override
  State<_ReportsView> createState() => _ReportsViewState();
}

final class _ReportsViewState extends State<_ReportsView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;

    final categories = <(ReportCategory, String)>[
      (ReportCategory.dailyWorkshop, l10n.reportCategoryDaily),
      (ReportCategory.workerPerformance, l10n.reportCategoryWorkers),
      (ReportCategory.processPerformance, l10n.reportCategoryProcesses),
      (ReportCategory.inventory, l10n.reportCategoryInventory),
      (ReportCategory.labourFinancial, l10n.reportCategoryFinancial),
      (ReportCategory.businessInsights, l10n.reportCategoryInsights),
      (ReportCategory.partiesAndPnl, l10n.reportCategoryPartiesPnl),
      (ReportCategory.cashbookAndNetProfit, l10n.reportCategoryCashbookNetProfit),
    ];

    return BlocBuilder<ReportsCubit, ReportsState>(
      builder: (context, state) {
        final cubit = context.read<ReportsCubit>();

        return AppScaffold(
          title: l10n.reportsHeading,
          contentWidth: AppContentWidth.wide,
          actions: [
            GuideTarget(
              id: GuideTargetId.reportsExportAction,
              child: AppIconButton(
                icon: AppIcons.share,
                tooltip: l10n.reportExportAction,
                onPressed: state.bundle == null || state.isExporting
                    ? null
                    : () => ReportExportSheet.show(
                        context,
                        cubit: cubit,
                        state: state,
                      ),
              ),
            ),
            AppIconButton(
              icon: AppIcons.refresh,
              tooltip: l10n.actionRetry,
              onPressed: () => cubit.loadReports(),
            ),
          ],
          padding: EdgeInsets.zero,
          body: ListView(
            padding: context.density.screenAll,
            children: [
              const ScreenFirstVisitHint(screenId: GuideScreenId.reports),
              GuideTarget(
                id: GuideTargetId.reportsFilterBar,
                child: AppMotionEntrance(
                  index: 0,
                  child: ReportFilterBar(
                    state: state,
                    searchController: _searchCtrl,
                  ),
                ),
              ),
              const AppGap.md(),
              GuideTarget(
                id: GuideTargetId.reportsCategories,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final (cat, label) in categories) ...[
                        AppChip(
                          label: label,
                          selected: state.category == cat,
                          onSelected: (_) => cubit.selectCategory(cat),
                        ),
                        const AppGap.hXs(),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (state.isExporting) ...[
                const AppProgressBar(),
                const SizedBox(height: AppSpacing.sm),
              ],
              KeyedSubtree(
                key: ValueKey<(ReportsStatus, ReportCategory)>((
                  state.status,
                  state.category,
                )),
                child:
                    state.status == ReportsStatus.initial ||
                        state.status == ReportsStatus.loading
                    ? const AppSkeletonList(itemCount: 4)
                    : state.status == ReportsStatus.error ||
                          state.bundle == null
                    ? AppErrorView(
                        title: l10n.errorUnexpected,
                        message: state.errorMessage,
                        retryLabel: l10n.actionRetry,
                        onRetry: () => cubit.loadReports(),
                      )
                    : switch (state.category) {
                        ReportCategory.dailyWorkshop =>
                          ReportsDailyCategoryView(
                            bundle: state.bundle!,
                            localeCode: localeCode,
                          ),
                        ReportCategory.workerPerformance =>
                          ReportsWorkersCategoryView(bundle: state.bundle!),
                        ReportCategory.processPerformance =>
                          ReportsProcessesCategoryView(bundle: state.bundle!),
                        ReportCategory.inventory =>
                          ReportsInventoryCategoryView(
                            state: state,
                            section: state.bundle!.inventory,
                            localeCode: localeCode,
                          ),
                        ReportCategory.labourFinancial =>
                          ReportsFinancialCategoryView(
                            state: state,
                            section: state.bundle!.financial,
                            localeCode: localeCode,
                          ),
                        ReportCategory.businessInsights =>
                          ReportsInsightsCategoryView(bundle: state.bundle!),
                        ReportCategory.partiesAndPnl =>
                          ReportsPartiesPnlView(bundle: state.bundle!),
                        ReportCategory.cashbookAndNetProfit =>
                          ReportsCashbookPnlView(bundle: state.bundle!),
                      },
              ),
            ],
          ),
        );
      },
    );
  }
}
