import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/reports/domain/entities/advanced_report_entities.dart';
import 'package:business_manager/features/reports/domain/entities/report_filter.dart';
import 'package:business_manager/features/reports/domain/services/report_export_service.dart';
import 'package:business_manager/features/reports/presentation/bloc/reports_cubit.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Bottom sheet / adaptive modal offering offline Print/Save-PDF, Excel (.xlsx),
/// Full Multi-Sheet Excel Workbook, and Gujarati-safe UTF-8 BOM CSV export.
final class ReportExportSheet {
  static Future<void> show(
    BuildContext context, {
    required ReportsCubit cubit,
    required ReportsState state,
  }) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    final rowCount = _estimateRowCount(state.bundle, state.category);

    return AppBottomSheet.show<void>(
      context,
      title: l10n.reportExportSheetTitle,
      builder: (sheetCtx) => SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (rowCount > 1000) ...[
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Row(
                  children: [
                    const Icon(AppIcons.info, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppText(
                        l10n.reportExportLargeNotice(rowCount),
                        variant: AppTextVariant.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            _ExportOptionTile(
              icon: AppIcons.print,
              title: l10n.reportExportPrintPdfTitle,
              subtitle: l10n.reportExportPrintPdfSubtitle,
              onTap: () async {
                Navigator.of(sheetCtx).pop();
                final res = await cubit.exportReport(
                  format: ReportExportFormat.printPdf,
                  localeCode: localeCode,
                );
                if (!context.mounted) return;
                if (res.success) {
                  AppFeedback.showSuccess(
                    context,
                    l10n.reportExportPrintOpened,
                  );
                } else if (res.message != null) {
                  AppFeedback.showInfo(context, res.message!);
                }
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            _ExportOptionTile(
              icon: AppIcons.excel,
              title: l10n.reportExportExcelTitle,
              subtitle: l10n.reportExportExcelSubtitle,
              onTap: () async {
                Navigator.of(sheetCtx).pop();
                final res = await cubit.exportReport(
                  format: ReportExportFormat.excelXlsx,
                  localeCode: localeCode,
                );
                if (!context.mounted) return;
                if (res.success) {
                  AppFeedback.showSuccess(
                    context,
                    l10n.reportExportSuccess(res.message ?? '.xlsx'),
                  );
                } else if (res.message != null) {
                  AppFeedback.showError(context, res.message!);
                }
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            _ExportOptionTile(
              icon: AppIcons.pdf,
              title: l10n.reportExportFullWorkbookTitle,
              subtitle: l10n.reportExportFullWorkbookSubtitle,
              onTap: () async {
                Navigator.of(sheetCtx).pop();
                final res = await cubit.exportReport(
                  format: ReportExportFormat.excelXlsx,
                  localeCode: localeCode,
                  fullWorkbook: true,
                );
                if (!context.mounted) return;
                if (res.success) {
                  AppFeedback.showSuccess(
                    context,
                    l10n.reportExportSuccess(res.message ?? '.xlsx'),
                  );
                } else if (res.message != null) {
                  AppFeedback.showError(context, res.message!);
                }
              },
            ),
            const SizedBox(height: AppSpacing.xs),
            _ExportOptionTile(
              icon: AppIcons.document,
              title: l10n.reportExportCsvTitle,
              subtitle: l10n.reportExportCsvSubtitle,
              onTap: () async {
                Navigator.of(sheetCtx).pop();
                final res = await cubit.exportReport(
                  format: ReportExportFormat.csvUtf8Bom,
                  localeCode: localeCode,
                );
                if (!context.mounted) return;
                if (res.success) {
                  AppFeedback.showSuccess(
                    context,
                    l10n.reportExportSuccess(res.message ?? '.csv'),
                  );
                } else if (res.message != null) {
                  AppFeedback.showError(context, res.message!);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  static int _estimateRowCount(
    AdvancedReportsBundle? b,
    ReportCategory category,
  ) {
    if (b == null) return 0;
    return switch (category) {
      ReportCategory.dailyWorkshop => b.dailyRows.length,
      ReportCategory.workerPerformance => b.workerPerformance.length,
      ReportCategory.processPerformance => b.processPerformance.length,
      ReportCategory.inventory =>
        b.inventory.colourBalances.length + b.inventory.movementHistory.length,
      ReportCategory.labourFinancial =>
        b.financial.labourEntries.length + b.financial.payments.length,
      ReportCategory.businessInsights => b.insights.trendPoints.length,
      ReportCategory.partiesAndPnl =>
        b.partySummaries.length + b.lotProfitLossRows.length,
    };
  }
}

final class _ExportOptionTile extends StatelessWidget {
  const _ExportOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(title, fontWeight: FontWeight.w700),
                const SizedBox(height: AppSpacing.xxs),
                AppText(subtitle, variant: AppTextVariant.bodySmall),
              ],
            ),
          ),
          const Icon(AppIcons.chevronRight, size: 20),
        ],
      ),
    );
  }
}
