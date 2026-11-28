import 'dart:convert';

import 'package:business_manager/core/platform/platform_env.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/features/reports/data/services/android_report_print_channel.dart';
import 'package:business_manager/features/reports/data/services/report_export_platform.dart';
import 'package:business_manager/features/reports/data/services/report_html_builder.dart';
import 'package:business_manager/features/reports/domain/entities/advanced_report_entities.dart';
import 'package:business_manager/features/reports/domain/entities/report_filter.dart';
import 'package:business_manager/features/reports/domain/services/report_export_service.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:injectable/injectable.dart';

/// Sendable sheet payload for background Isolate `.xlsx` / `.csv` generation.
final class ExportSheetData {
  const ExportSheetData({
    required this.name,
    required this.headers,
    required this.rows,
  });

  final String name;
  final List<String> headers;
  final List<List<Object?>> rows;
}

/// Offline Gujarati-safe report exporter supporting:
/// - Native Android WebView + PrintManager ("Save as PDF" & print)
/// - MIT-licensed `excel_plus` `.xlsx` multi-sheet workbooks (in Isolate)
/// - Pure-Dart UTF-8 with BOM (`\uFEFF`) `.csv` export (in Isolate)
@LazySingleton(as: ReportExportService)
final class ExcelCsvExportService implements ReportExportService {
  ExcelCsvExportService(this._printChannel, this._appLockCubit);

  final AndroidReportPrintChannel _printChannel;
  final AppLockCubit _appLockCubit;

  static const ReportHtmlBuilder _htmlBuilder = ReportHtmlBuilder();

  @override
  Future<ReportExportResult> printOrSavePdf({
    required AdvancedReportsBundle bundle,
    required ReportCategory category,
    required String localeCode,
    int? subTabIndex,
  }) async {
    final html = _htmlBuilder.buildHtml(
      bundle: bundle,
      category: category,
      localeCode: localeCode,
      subTabIndex: subTabIndex,
    );
    final stamp = IstDateTimeHelper.formatIstFileTimestamp(
      bundle.generatedAtUtcMillis,
    );
    final jobName = 'StitchFlow_${category.name}_$stamp';

    final ok = await printReportHtmlPlatform(
      jobName: jobName,
      html: html,
      androidPrintChannel: _printChannel,
      runWithPicker: (action) => _appLockCubit.runWithSystemPicker(action),
    );
    return ReportExportResult(
      success: ok,
      message: ok
          ? jobName
          : (kIsWeb
                ? 'Please allow pop-ups in your browser to print or Save as PDF.'
                : 'Print dialog is only available on Android and Web browsers.'),
    );
  }

  @override
  Future<ReportExportResult> exportExcel({
    required AdvancedReportsBundle bundle,
    required ReportCategory category,
    required String localeCode,
    bool fullWorkbook = false,
  }) async {
    final sheets = buildSheets(
      bundle: bundle,
      category: category,
      localeCode: localeCode,
      fullWorkbook: fullWorkbook,
    );
    final totalRows = sheets.fold<int>(0, (s, sh) => s + sh.rows.length);
    final bytes = await runComputeIsolate(() => buildXlsxBytes(sheets));

    final stamp = IstDateTimeHelper.formatIstFileTimestamp(
      bundle.generatedAtUtcMillis,
    );
    final slug = fullWorkbook ? 'full_workbook' : category.name;
    final fileName = 'stitchflow_report_${slug}_$stamp.xlsx';
    final filePath = await deliverExportedBytes(
      fileName: fileName,
      bytes: bytes,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      runWithPicker: (action) => _appLockCubit.runWithSystemPicker(action),
    );

    return ReportExportResult(
      success: true,
      filePath: filePath,
      message: fileName,
      rowCount: totalRows,
    );
  }

  @override
  Future<ReportExportResult> exportCsv({
    required AdvancedReportsBundle bundle,
    required ReportCategory category,
    required String localeCode,
  }) async {
    final sheets = buildSheets(
      bundle: bundle,
      category: category,
      localeCode: localeCode,
      fullWorkbook: false,
    );
    final primarySheet = sheets.first;
    final bytes = await runComputeIsolate(
      () => buildCsvBytesWithBom(primarySheet),
    );

    final stamp = IstDateTimeHelper.formatIstFileTimestamp(
      bundle.generatedAtUtcMillis,
    );
    final fileName = 'stitchflow_report_${category.name}_$stamp.csv';
    final filePath = await deliverExportedBytes(
      fileName: fileName,
      bytes: bytes,
      mimeType: 'text/csv;charset=utf-8',
      runWithPicker: (action) => _appLockCubit.runWithSystemPicker(action),
    );

    return ReportExportResult(
      success: true,
      filePath: filePath,
      message: fileName,
      rowCount: primarySheet.rows.length,
    );
  }

  /// Pure-Dart Excel `.xlsx` encoder (safe for `Isolate.run` and unit tests).
  static List<int> buildXlsxBytes(List<ExportSheetData> sheets) {
    final excel = Excel.createExcel();
    final defaultSheet = excel.getDefaultSheet() ?? 'Sheet1';

    for (var i = 0; i < sheets.length; i++) {
      final data = sheets[i];
      final safeName = _sanitizeSheetName(data.name);
      if (i == 0 && excel.tables.containsKey(defaultSheet)) {
        if (defaultSheet != safeName) {
          excel.rename(defaultSheet, safeName);
        }
      }
      final sheet = excel[safeName];

      for (var c = 0; c < data.headers.length; c++) {
        sheet.updateCell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 0),
          TextCellValue(data.headers[c]),
        );
      }

      for (var r = 0; r < data.rows.length; r++) {
        final row = data.rows[r];
        for (var c = 0; c < row.length; c++) {
          final val = row[c];
          final CellValue cellVal;
          if (val is int) {
            cellVal = IntCellValue(val);
          } else if (val is double) {
            cellVal = DoubleCellValue(val);
          } else {
            cellVal = TextCellValue(val?.toString() ?? '');
          }
          sheet.updateCell(
            CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r + 1),
            cellVal,
          );
        }
      }
    }

    final encoded = excel.save();
    return encoded ?? const <int>[];
  }

  /// Pure-Dart UTF-8 with BOM (`\uFEFF`) CSV encoder so Microsoft Excel opens
  /// Gujarati Unicode cleanly without garbled Latin-1 decoding.
  static List<int> buildCsvBytesWithBom(ExportSheetData sheet) {
    final buf = StringBuffer('\uFEFF');
    buf.writeln(sheet.headers.map(_csvEscape).join(','));
    for (final row in sheet.rows) {
      buf.writeln(row.map((v) => _csvEscape(v?.toString() ?? '')).join(','));
    }
    return utf8.encode(buf.toString());
  }

  static String _csvEscape(String value) {
    final needsQuotes =
        value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!needsQuotes) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  static String _sanitizeSheetName(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[\[\]:*?/\\]'), '_').trim();
    if (cleaned.isEmpty) return 'Report';
    return cleaned.length > 31 ? cleaned.substring(0, 31) : cleaned;
  }

  /// Converts an [AdvancedReportsBundle] into sendable tabular sheets.
  static List<ExportSheetData> buildSheets({
    required AdvancedReportsBundle bundle,
    required ReportCategory category,
    required String localeCode,
    required bool fullWorkbook,
  }) {
    final isGu = localeCode == 'gu';
    if (fullWorkbook) {
      return [
        _dailySheet(bundle, isGu: isGu),
        _workersSheet(bundle, isGu: isGu),
        _processesSheet(bundle, isGu: isGu),
        _inventoryLotsSheet(bundle, isGu: isGu),
        _inventoryColoursSheet(bundle, isGu: isGu),
        _labourSheet(bundle, isGu: isGu),
        _paymentsSheet(bundle, isGu: isGu),
        _productionHistorySheet(bundle, isGu: isGu),
        _pendingInspectionSheet(bundle, isGu: isGu),
        _rejectionsSheet(bundle, isGu: isGu),
      ];
    }

    return switch (category) {
      ReportCategory.dailyWorkshop => [_dailySheet(bundle, isGu: isGu)],
      ReportCategory.workerPerformance => [_workersSheet(bundle, isGu: isGu)],
      ReportCategory.processPerformance => [
        _processesSheet(bundle, isGu: isGu),
      ],
      ReportCategory.inventory => [
        _inventoryLotsSheet(bundle, isGu: isGu),
        _inventoryColoursSheet(bundle, isGu: isGu),
      ],
      ReportCategory.labourFinancial => [
        _labourSheet(bundle, isGu: isGu),
        _paymentsSheet(bundle, isGu: isGu),
      ],
      ReportCategory.businessInsights => [_insightsSheet(bundle, isGu: isGu)],
      ReportCategory.partiesAndPnl => [_partiesSheet(bundle, isGu: isGu), _lotPnlSheet(bundle, isGu: isGu)],
      ReportCategory.cashbookAndNetProfit => [
        _cashbookPnlSheet(bundle, isGu: isGu),
        _expenseCategoriesSheet(bundle, isGu: isGu),
      ],
    };
  }

  static ExportSheetData _cashbookPnlSheet(
    AdvancedReportsBundle b, {
    required bool isGu,
  }) {
    final cb = b.cashbookSummary;
    final pnl = b.trueNetProfit;
    return ExportSheetData(
      name: isGu ? 'કેશબુક_ચોખ્ખો_નફો' : 'Cashbook_NetProfit',
      headers: isGu
          ? const ['વિગત', 'રકમ (₹)']
          : const ['Metric', 'Amount (INR)'],
      rows: [
        if (pnl != null) ...[
          [
            isGu ? 'ચોખ્ખું વેચાણ' : 'Net Dispatched Sales',
            pnl.netDispatchedSalesPaise / 100.0,
          ],
          [
            isGu ? 'કારીગર મજૂરી' : 'Worker Labour',
            pnl.workerLabourPaise / 100.0,
          ],
          [
            isGu ? 'લોટ સીધો ખર્ચ' : 'Lot Direct Costs',
            pnl.lotDirectCostsPaise / 100.0,
          ],
          [
            isGu ? 'વર્કશોપ ખર્ચ' : 'Workshop Overheads',
            pnl.workshopOverheadExpensesPaise / 100.0,
          ],
          [
            isGu ? 'સાચો ચોખ્ખો નફો' : 'True Net Profit',
            pnl.trueNetProfitPaise / 100.0,
          ],
        ],
        if (cb != null) ...[
          [
            isGu ? 'હાથ પર રોકડ' : 'Cash in Hand',
            cb.currentCashBalancePaise / 100.0,
          ],
          [
            isGu ? 'બેંક / UPI બેલેન્સ' : 'Bank / UPI Balance',
            cb.currentBankBalancePaise / 100.0,
          ],
          [
            isGu ? 'બાકી બિલ' : 'Pending Unpaid Bills',
            cb.totalExpensesUnpaidPaise / 100.0,
          ],
        ],
      ],
    );
  }

  static ExportSheetData _expenseCategoriesSheet(
    AdvancedReportsBundle b, {
    required bool isGu,
  }) {
    final cats = b.cashbookSummary?.categoryBreakdowns ?? const [];
    return ExportSheetData(
      name: isGu ? 'ખર્ચ_કેટેગરી' : 'Expense_Categories',
      headers: isGu
          ? const ['કેટેગરી', 'ચૂકવેલ (₹)', 'બાકી (₹)', 'કુલ (₹)']
          : const ['Category', 'Paid (INR)', 'Unpaid (INR)', 'Total (INR)'],
      rows: [
        for (final c in cats)
          [
            c.category.dbValue,
            c.paidPaise / 100.0,
            c.unpaidPaise / 100.0,
            c.totalPaise / 100.0,
          ],
      ],
    );
  }

  static ExportSheetData _partiesSheet(
    AdvancedReportsBundle b, {
    required bool isGu,
  }) {
    return ExportSheetData(
      name: isGu ? 'પાર્ટી_ખાતા' : 'Parties',
      headers: isGu
          ? ['પાર્ટી', 'કુલ ડિસ્પેચ (₹)', 'માલ પરત (₹)', 'કુલ જમા (₹)', 'બાકી લેણાં (₹)']
          : ['Party', 'Dispatched (₹)', 'Returns (₹)', 'Collected (₹)', 'Receivable (₹)'],
      rows: [
        for (final p in b.partySummaries)
          [
            p.partyName,
            MoneyFormatter.formatPaiseWithoutSymbol(p.totalDispatchedNetPaise),
            MoneyFormatter.formatPaiseWithoutSymbol(p.totalBuyerReturnsPaise),
            MoneyFormatter.formatPaiseWithoutSymbol(p.totalCollectedNetPaise),
            MoneyFormatter.formatPaiseWithoutSymbol(p.outstandingReceivablePaise),
          ],
      ],
    );
  }

  static ExportSheetData _lotPnlSheet(
    AdvancedReportsBundle b, {
    required bool isGu,
  }) {
    return ExportSheetData(
      name: isGu ? 'લોટ_નફો_નુકસાન' : 'Lot_PnL',
      headers: isGu
          ? ['લોટ', 'ચોખ્ખી આવક (₹)', 'મજૂરી (₹)', 'સીધો ખર્ચ (₹)', 'ચોખ્ખો નફો (₹)']
          : ['Lot', 'Net Revenue (₹)', 'Worker Labour (₹)', 'Direct Costs (₹)', 'Net Profit (₹)'],
      rows: [
        for (final l in b.lotProfitLossRows)
          [
            l.lotNumber,
            MoneyFormatter.formatPaiseWithoutSymbol(l.netRevenuePaise),
            MoneyFormatter.formatPaiseWithoutSymbol(l.workerLabourPaise),
            MoneyFormatter.formatPaiseWithoutSymbol(l.directCostsPaise),
            MoneyFormatter.formatPaiseWithoutSymbol(l.netProfitPaise),
          ],
      ],
    );
  }

  static ExportSheetData _dailySheet(
    AdvancedReportsBundle b, {
    required bool isGu,
  }) {
    return ExportSheetData(
      name: isGu ? 'દૈનિક_રિપોર્ટ' : 'Daily',
      headers: isGu
          ? const [
              'તારીખ (IST)',
              'ઇશ્યુ',
              'સારા પરત',
              'નુકસાન',
              'ગુમ/ઘટ',
              'મજૂરી ખર્ચ (₹)',
              'નેટ ચુકવણી (₹)',
            ]
          : const [
              'Date (IST)',
              'Issued',
              'Good Returned',
              'Damaged',
              'Lost & Shortage',
              'Labour Cost (INR)',
              'Net Payments (INR)',
            ],
      rows: [
        for (final r in b.dailyRows)
          [
            r.istDateIso,
            r.issuedQty,
            r.goodReturnedQty,
            r.damagedQty,
            r.lostAndShortageQty,
            r.labourEarnedPaise / 100.0,
            r.netPaymentsPaise / 100.0,
          ],
      ],
    );
  }

  static ExportSheetData _workersSheet(
    AdvancedReportsBundle b, {
    required bool isGu,
  }) {
    return ExportSheetData(
      name: isGu ? 'કારીગર_કામગીરી' : 'Workers',
      headers: isGu
          ? const [
              'કારીગર',
              'ઇશ્યુ',
              'મંજૂર (Accepted)',
              'રિજેક્ટ / નુકસાન',
              'તપાસ બાકી',
              'ગુમ/ઘટ',
              'હાલનું બાકી',
              'સમય મજૂરી (₹)',
              'ચુકવણી (₹)',
              'હાલનું બાકી લેણું (₹)',
              'એડવાન્સ જમા (₹)',
            ]
          : const [
              'Worker',
              'Period Issued',
              'Accepted Qty',
              'Rejected / Damaged Qty',
              'Pending Inspection Qty',
              'Period Lost & Shortage',
              'Current Outstanding Qty',
              'Earned Amount (INR)',
              'Paid Amount (INR)',
              'Outstanding Payable (INR)',
              'Advance Credit (INR)',
            ],
      rows: [
        for (final w in b.workerPerformance)
          [
            w.workerName,
            w.periodIssuedQty,
            w.periodGoodReturnedQty,
            w.periodDamagedQty,
            w.currentPendingInspectionQty,
            w.periodLostShortageQty,
            w.currentPendingQty,
            w.periodLabourEarnedPaise / 100.0,
            w.periodNetPaymentsPaise / 100.0,
            w.currentOutstandingPayablePaise / 100.0,
            w.currentAdvanceCreditPaise / 100.0,
          ],
      ],
    );
  }

  static ExportSheetData _processesSheet(
    AdvancedReportsBundle b, {
    required bool isGu,
  }) {
    return ExportSheetData(
      name: isGu ? 'પ્રક્રિયા_કામગીરી' : 'Processes',
      headers: isGu
          ? const [
              'પ્રક્રિયા',
              'ઇશ્યુ',
              'મંજૂર (Accepted)',
              'રિજેક્ટ / નુકસાન',
              'તપાસ બાકી',
              'ગુમ/ઘટ',
              'હાલનું બાકી',
              'સરેરાશ સમય (કલાક)',
              'પૂર્ણ ઇશ્યુ સંખ્યા',
              'મજૂરી ખર્ચ (₹)',
            ]
          : const [
              'Process',
              'Period Issued',
              'Accepted Qty',
              'Rejected / Damaged Qty',
              'Pending Inspection Qty',
              'Period Lost & Shortage',
              'Current Outstanding Qty',
              'Avg Completion Hours',
              'Settled Issues Count',
              'Production Cost (INR)',
            ],
      rows: [
        for (final p in b.processPerformance)
          [
            p.processName,
            p.periodIssuedQty,
            p.periodGoodReturnedQty,
            p.periodDamagedQty,
            p.currentPendingInspectionQty,
            p.periodLostShortageQty,
            p.currentPendingQty,
            p.averageTurnaroundHours != null
                ? double.parse(p.averageTurnaroundHours!.toStringAsFixed(2))
                : 'N/A',
            p.settledIssuesCount,
            p.periodLabourCostPaise / 100.0,
          ],
      ],
    );
  }

  static ExportSheetData _inventoryLotsSheet(
    AdvancedReportsBundle b, {
    required bool isGu,
  }) {
    return ExportSheetData(
      name: isGu ? 'લોટ_સ્ટોક' : 'Inventory_Lots',
      headers: isGu
          ? const [
              'લોટ નંબર',
              'શીર્ષક',
              'શરૂઆત સ્ટોક',
              'ઉપલબ્ધ સારો સ્ટોક',
              'કારીગર પાસે બાકી',
              'નુકસાન',
              'ગુમ',
              'ઘટ',
              'અંદાજિત સ્ટોક કિંમત (₹)',
            ]
          : const [
              'Lot Number',
              'Title',
              'Initial Stock',
              'Available Good Stock',
              'Pending With Workers',
              'Damaged Bucket',
              'Lost',
              'Shortage',
              'Reference Stock Value (INR)',
            ],
      rows: [
        for (final r in b.inventory.lotRows)
          [
            r.lotNumber,
            r.title ?? '',
            r.initialQuantity,
            r.availableGoodStock,
            r.pendingWithWorkers,
            r.damagedBucket,
            r.lostQuantity,
            r.shortageQuantity,
            r.goodStockValuePaise / 100.0,
          ],
      ],
    );
  }

  static ExportSheetData _inventoryColoursSheet(
    AdvancedReportsBundle b, {
    required bool isGu,
  }) {
    return ExportSheetData(
      name: isGu ? 'રંગ_સ્ટોક' : 'Inventory_Colours',
      headers: isGu
          ? const [
              'લોટ',
              'ડિઝાઇન',
              'રંગ',
              'શરૂઆત',
              'ઉપલબ્ધ સારો',
              'બાકી',
              'નુકસાન',
              'ગુમ',
              'ઘટ',
            ]
          : const [
              'Lot',
              'Design',
              'Colour',
              'Initial',
              'Available Good',
              'Pending',
              'Damaged',
              'Lost',
              'Shortage',
            ],
      rows: [
        for (final c in b.inventory.colourBalances)
          [
            c.lotNumber,
            c.designName,
            c.colourName,
            c.initialQuantity,
            c.physicalAvailableInHouse,
            c.totalPendingWithWorkers,
            c.damagedBucket,
            c.totalLost,
            c.totalShortage,
          ],
      ],
    );
  }

  static ExportSheetData _labourSheet(
    AdvancedReportsBundle b, {
    required bool isGu,
  }) {
    return ExportSheetData(
      name: isGu ? 'મજૂરી_નોંધ' : 'Labour',
      headers: isGu
          ? const [
              'તારીખ (IST)',
              'કારીગર',
              'પ્રક્રિયા',
              'લોટ',
              'નંગ',
              'દર (₹)',
              'રકમ (₹)',
            ]
          : const [
              'Date (IST)',
              'Worker',
              'Process',
              'Lot',
              'Quantity',
              'Locked Rate (INR)',
              'Labour Amount (INR)',
            ],
      rows: [
        for (final l in b.financial.labourEntries)
          [
            IstDateTimeHelper.toIstBusinessDate(l.entry.transactionAt),
            l.workerName,
            l.processName,
            l.lotNumber,
            l.entry.quantity,
            l.entry.ratePaise / 100.0,
            l.entry.amountPaise / 100.0,
          ],
      ],
    );
  }

  static ExportSheetData _paymentsSheet(
    AdvancedReportsBundle b, {
    required bool isGu,
  }) {
    return ExportSheetData(
      name: isGu ? 'ચુકવણી_ઇતિહાસ' : 'Payments',
      headers: isGu
          ? const [
              'તારીખ (IST)',
              'કારીગર',
              'પ્રકાર',
              'માધ્યમ',
              'રકમ (₹)',
              'સંદર્ભ / નોંધ',
            ]
          : const [
              'Date (IST)',
              'Worker',
              'Payment Type',
              'Mode',
              'Amount (INR)',
              'Reference / Notes',
            ],
      rows: [
        for (final p in b.financial.payments)
          [
            IstDateTimeHelper.toIstBusinessDate(p.payment.transactionAt),
            p.workerName,
            p.payment.paymentType.dbValue,
            p.payment.paymentMode.dbValue,
            p.payment.amountPaise / 100.0,
            p.payment.referenceNo ?? p.payment.notes ?? '',
          ],
      ],
    );
  }

  static ExportSheetData _productionHistorySheet(
    AdvancedReportsBundle b, {
    required bool isGu,
  }) {
    return ExportSheetData(
      name: isGu ? 'પ્રોડક્શન_હિસ્ટ્રી' : 'Production_History',
      headers: isGu
          ? const [
              'તારીખ (IST)',
              'લોટ',
              'ડિઝાઇન',
              'રંગ',
              'પ્રક્રિયા',
              'કારીગર',
              'સોંપેલ',
              'પરત',
              'મંજૂર',
              'તપાસ બાકી',
              'રિજેક્ટ',
              'બાકી',
              'લોક દર (₹)',
              'કમાણી (₹)',
              'સ્થિતિ',
            ]
          : const [
              'Assigned Date (IST)',
              'Lot',
              'Design',
              'Colour',
              'Process',
              'Worker',
              'Assigned Qty',
              'Returned Qty',
              'Accepted Qty',
              'Pending Inspection',
              'Rejected Qty',
              'Outstanding Qty',
              'Locked Rate (INR)',
              'Earned Amount (INR)',
              'Status',
            ],
      rows: [
        for (final a in b.productionHistoryRows)
          [
            IstDateTimeHelper.toIstBusinessDate(a.assignedAt),
            a.lotNumber,
            a.designName,
            a.colourName,
            a.processName,
            a.workerName,
            a.assignedQty,
            a.returnedQty,
            a.totalAcceptedQty,
            a.pendingInspectionQty,
            a.netRejectedQty,
            a.outstandingQty,
            a.lockedRatePaise / 100.0,
            a.earnedAmountPaise / 100.0,
            a.isCompleted ? 'COMPLETED' : 'IN_PROGRESS',
          ],
      ],
    );
  }

  static ExportSheetData _pendingInspectionSheet(
    AdvancedReportsBundle b, {
    required bool isGu,
  }) {
    return ExportSheetData(
      name: isGu ? 'તપાસ_બાકી_પરત' : 'Pending_QC_Returns',
      headers: isGu
          ? const [
              'પરત તારીખ',
              'લોટ',
              'પ્રક્રિયા',
              'કારીગર',
              'પરત જથ્થો',
              'તપાસ બાકી',
              'લોક દર (₹)',
            ]
          : const [
              'Return Date (IST)',
              'Lot',
              'Process',
              'Worker',
              'Returned Qty',
              'Pending Inspection Qty',
              'Locked Rate (INR)',
            ],
      rows: [
        for (final r in b.pendingInspectionReturns)
          [
            IstDateTimeHelper.toIstBusinessDate(
              r.productionReturn.transactionAt,
            ),
            r.lotNumber,
            r.processName,
            r.workerName,
            r.productionReturn.returnedQuantity,
            r.remainingPendingInspectionQty,
            r.lockedRatePaise / 100.0,
          ],
      ],
    );
  }

  static ExportSheetData _rejectionsSheet(
    AdvancedReportsBundle b, {
    required bool isGu,
  }) {
    return ExportSheetData(
      name: isGu ? 'રિજેક્ટ_અને_રિપેર' : 'Rejections_Repairs',
      headers: isGu
          ? const [
              'તપાસ તારીખ',
              'લોટ',
              'પ્રક્રિયા',
              'કારીગર',
              'રિજેક્ટ',
              'ફરી મંજૂર',
              'બાકી ખુલ્લા',
              'કારણ',
              'સ્થિતિ',
            ]
          : const [
              'Inspection Date (IST)',
              'Lot',
              'Process',
              'Worker',
              'Rejected Qty',
              'Re-Approved Qty',
              'Open Unrepaired Qty',
              'Rejection Reason',
              'Status',
            ],
      rows: [
        for (final r in b.rejectionRecords)
          [
            IstDateTimeHelper.toIstBusinessDate(r.record.inspectedAt),
            r.lotNumber,
            r.processName,
            r.workerName,
            r.record.rejectedQuantity,
            r.totalReapprovedQty,
            r.openUnrepairedQty,
            r.record.rejectionReason,
            r.record.status.dbValue,
          ],
      ],
    );
  }

  static ExportSheetData _insightsSheet(
    AdvancedReportsBundle b, {
    required bool isGu,
  }) {
    return ExportSheetData(
      name: isGu ? 'વિશ્લેષણ_અવરોધ' : 'Insights',
      headers: isGu
          ? const [
              'પ્રક્રિયા',
              'બાકી નંગ',
              'ખુલ્લા ઇશ્યુ',
              'સૌથી જૂનું (દિવસ)',
              'સમયમાં પૂર્ણ',
              'મજૂરી ખર્ચ',
            ]
          : const [
              'Process',
              'Current Pending Qty',
              'Open Issues',
              'Oldest Pending (Days)',
              'Period Completed Qty',
              'Period Labour Cost',
            ],
      rows: [
        for (final bn in b.insights.bottlenecks)
          [
            bn.processName,
            bn.currentPendingQty,
            bn.openIssuesCount,
            bn.oldestOpenIssueAgeDays,
            bn.periodCompletedQty,
            MoneyFormatter.formatPaise(
              b.processPerformance
                      .where((p) => p.processId == bn.processId)
                      .firstOrNull
                      ?.periodLabourCostPaise ??
                  0,
            ),
          ],
      ],
    );
  }
}
