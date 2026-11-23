import 'package:business_manager/features/reports/domain/entities/advanced_report_entities.dart';
import 'package:business_manager/features/reports/domain/entities/report_filter.dart';

/// Export format options supported offline in StitchFlow V1.2.
enum ReportExportFormat { printPdf, excelXlsx, csvUtf8Bom }

/// Result of a report export or native Android print action.
final class ReportExportResult {
  const ReportExportResult({
    required this.success,
    this.filePath,
    this.message,
    this.rowCount = 0,
  });

  final bool success;
  final String? filePath;
  final String? message;
  final int rowCount;
}

/// Offline report export & print service contract.
abstract interface class ReportExportService {
  /// Opens Android native Print / "Save as PDF" dialog via WebView + PrintManager
  /// using bundled `NotoSansGujarati` for 100% accurate Gujarati shaping.
  Future<ReportExportResult> printOrSavePdf({
    required AdvancedReportsBundle bundle,
    required ReportCategory category,
    required String localeCode,
    int? subTabIndex,
  });

  /// Generates a styled multi-sheet `.xlsx` workbook in a background isolate
  /// and shares it via Android Share Sheet.
  Future<ReportExportResult> exportExcel({
    required AdvancedReportsBundle bundle,
    required ReportCategory category,
    required String localeCode,
    bool fullWorkbook = false,
  });

  /// Generates a UTF-8 with BOM (`\uFEFF`) `.csv` file in a background isolate
  /// for Gujarati-safe Excel opening and large-dataset exports.
  Future<ReportExportResult> exportCsv({
    required AdvancedReportsBundle bundle,
    required ReportCategory category,
    required String localeCode,
  });
}
