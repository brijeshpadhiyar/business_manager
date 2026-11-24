import 'dart:convert';

import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/features/reports/domain/entities/advanced_report_entities.dart';
import 'package:business_manager/features/reports/domain/entities/report_filter.dart';

/// Pure-Dart bilingual (English & Gujarati) HTML report generator for Android
/// WebView + PrintManager ("Save as PDF" and physical/Wi-Fi printing).
///
/// Uses `@font-face` pointing to Flutter's bundled `NotoSansGujarati` assets so
/// Android Chromium's HarfBuzz engine shapes Gujarati conjuncts and matras with
/// 100% typographic fidelity offline.
final class ReportHtmlBuilder {
  const ReportHtmlBuilder();

  static const HtmlEscape _esc = HtmlEscape();

  String buildHtml({
    required AdvancedReportsBundle bundle,
    required ReportCategory category,
    required String localeCode,
    int? subTabIndex,
  }) {
    final isGu = localeCode == 'gu';
    final shopName = isGu ? bundle.businessNameGu : bundle.businessNameEn;
    final title = _categoryTitle(category, isGu: isGu);
    final periodLabel = _formatPeriod(bundle.filter, isGu: isGu);
    final generatedAt = IstDateTimeHelper.formatIstIsoDateTime(
      bundle.generatedAtUtcMillis,
    );

    final bodyHtml = switch (category) {
      ReportCategory.dailyWorkshop => _buildDailySection(bundle, isGu: isGu),
      ReportCategory.workerPerformance => _buildWorkerSection(
        bundle,
        isGu: isGu,
      ),
      ReportCategory.processPerformance => _buildProcessSection(
        bundle,
        isGu: isGu,
      ),
      ReportCategory.inventory => _buildInventorySection(
        bundle,
        isGu: isGu,
        subTabIndex: subTabIndex,
      ),
      ReportCategory.labourFinancial => _buildFinancialSection(
        bundle,
        isGu: isGu,
        subTabIndex: subTabIndex,
      ),
      ReportCategory.businessInsights => _buildInsightsSection(
        bundle,
        isGu: isGu,
      ),
    };

    final disclaimer = isGu
        ? 'સ્ટિચફ્લો (StitchFlow) દ્વારા ઓફલાઇન તૈયાર કરાયેલ — સ્થાનિક વર્કશોપ ખાતાવહી પર આધારિત સંદર્ભ અહેવાલ (નફો કે વેચાણનો હિસાબ નથી).'
        : 'Generated offline by StitchFlow — Reference data strictly from local workshop ledger (not a sales or profit statement).';

    return '''
<!DOCTYPE html>
<html lang="${isGu ? 'gu' : 'en'}">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>${_e(title)}</title>
<style>
  @font-face {
    font-family: 'NotoSansGujarati';
    src: url('file:///android_asset/flutter_assets/assets/fonts/NotoSansGujarati-Regular.ttf') format('truetype');
    font-weight: 400;
    font-style: normal;
  }
  @font-face {
    font-family: 'NotoSansGujarati';
    src: url('file:///android_asset/flutter_assets/assets/fonts/NotoSansGujarati-Bold.ttf') format('truetype');
    font-weight: 700;
    font-style: normal;
  }
  @page {
    size: A4 portrait;
    margin: 12mm;
  }
  * { box-sizing: border-box; }
  body {
    font-family: 'NotoSansGujarati', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    color: #172B4D;
    background: #FFFFFF;
    margin: 0;
    padding: 0;
    font-size: 11px;
    line-height: 1.45;
  }
  .header {
    border-bottom: 2px solid #172B4D;
    padding-bottom: 10px;
    margin-bottom: 14px;
    display: flex;
    justify-content: space-between;
    align-items: flex-end;
    gap: 12px;
  }
  .brand { font-size: 18px; font-weight: 700; color: #172B4D; margin: 0; }
  .tagline { font-size: 10px; color: #0D9488; font-weight: 700; margin-top: 2px; }
  .meta { text-align: right; font-size: 10px; color: #475569; }
  .report-title { font-size: 14px; font-weight: 700; color: #172B4D; margin: 0 0 8px 0; }
  .kpi-grid {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-bottom: 14px;
  }
  .kpi {
    flex: 1 1 115px;
    border: 1px solid #CBD5E1;
    border-left: 3px solid #0D9488;
    border-radius: 6px;
    padding: 7px 9px;
    background: #F8FAFC;
  }
  .kpi.warn { border-left-color: #F4A340; }
  .kpi-label { font-size: 9.5px; color: #475569; margin-bottom: 2px; }
  .kpi-val { font-size: 13px; font-weight: 700; color: #172B4D; font-variant-numeric: tabular-nums; }
  h3 { font-size: 12px; font-weight: 700; color: #172B4D; margin: 14px 0 6px 0; }
  table {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 12px;
    font-variant-numeric: tabular-nums;
  }
  th, td {
    border: 1px solid #CBD5E1;
    padding: 5px 7px;
    text-align: left;
    vertical-align: top;
  }
  th {
    background: #172B4D;
    color: #FFFFFF;
    font-weight: 700;
    font-size: 10px;
  }
  tr:nth-child(even) td { background: #F8FAFC; }
  .num { text-align: right; white-space: nowrap; }
  .empty { color: #64748B; font-style: italic; padding: 10px 0; }
  .footer {
    margin-top: 18px;
    padding-top: 8px;
    border-top: 1px solid #CBD5E1;
    font-size: 9.5px;
    color: #64748B;
  }
</style>
</head>
<body>
  <div class="header">
    <div>
      <p class="brand">${_e(shopName)}</p>
      <div class="tagline">StitchFlow • ${isGu ? 'કાપડથી તૈયાર વસ્ત્ર સુધી' : 'From Fabric to Finished'}</div>
    </div>
    <div class="meta">
      <div><strong>${_e(title)}</strong></div>
      <div>${_e(periodLabel)}</div>
      <div>${isGu ? 'તૈયાર સમય:' : 'Generated:'} ${_e(generatedAt)}</div>
    </div>
  </div>
  $bodyHtml
  <div class="footer">${_e(disclaimer)}</div>
</body>
</html>
''';
  }

  String _e(String s) => _esc.convert(s);

  String _categoryTitle(ReportCategory c, {required bool isGu}) => switch (c) {
    ReportCategory.dailyWorkshop =>
      isGu ? 'દૈનિક વર્કશોપ રિપોર્ટ' : 'Daily Workshop Report',
    ReportCategory.workerPerformance =>
      isGu ? 'કારીગર કામગીરી રિપોર્ટ' : 'Worker Performance Report',
    ReportCategory.processPerformance =>
      isGu ? 'પ્રક્રિયા કામગીરી રિપોર્ટ' : 'Process Performance Report',
    ReportCategory.inventory =>
      isGu ? 'સ્ટોક / ઇન્વેન્ટરી રિપોર્ટ' : 'Inventory Report',
    ReportCategory.labourFinancial =>
      isGu ? 'મજૂરી અને હિસાબ રિપોર્ટ' : 'Labour & Financial Report',
    ReportCategory.businessInsights =>
      isGu ? 'વ્યવસાયિક વિશ્લેષણ (Insights)' : 'Business Insights Report',
  };

  String _formatPeriod(ReportFilter f, {required bool isGu}) {
    if (f.fromUtcMillis == null && f.toUtcMillis == null) {
      return isGu ? 'સમયગાળો: બધો સમય' : 'Period: All Time';
    }
    final fromStr = f.fromUtcMillis != null
        ? IstDateTimeHelper.toIstBusinessDate(f.fromUtcMillis!)
        : '—';
    final toStr = f.toUtcMillis != null
        ? IstDateTimeHelper.toIstBusinessDate(f.toUtcMillis!)
        : '—';
    return isGu
        ? 'સમયગાળો: $fromStr થી $toStr (IST)'
        : 'Period: $fromStr to $toStr (IST)';
  }

  String _kpi(String label, String value, {bool warn = false}) =>
      '<div class="kpi${warn ? ' warn' : ''}"><div class="kpi-label">${_e(label)}</div><div class="kpi-val">${_e(value)}</div></div>';

  String _buildDailySection(AdvancedReportsBundle b, {required bool isGu}) {
    final buf = StringBuffer()
      ..write('<div class="kpi-grid">')
      ..write(
        _kpi(isGu ? 'કુલ ઇશ્યુ' : 'Total Issued', '${b.dailyTotalIssued}'),
      )
      ..write(
        _kpi(
          isGu ? 'સારા પરત' : 'Good Returned',
          '${b.dailyTotalGoodReturned}',
        ),
      )
      ..write(
        _kpi(
          isGu ? 'નુકસાન / ગુમ' : 'Damaged / Lost',
          '${b.dailyTotalDamaged} / ${b.dailyTotalLostShortage}',
          warn: (b.dailyTotalDamaged + b.dailyTotalLostShortage) > 0,
        ),
      )
      ..write(
        _kpi(
          isGu ? 'મજૂરી ખર્ચ' : 'Labour Cost',
          MoneyFormatter.formatPaise(b.dailyTotalLabourPaise),
        ),
      )
      ..write(
        _kpi(
          isGu ? 'ચુકવણી (નેટ)' : 'Net Payments',
          MoneyFormatter.formatPaise(b.dailyTotalNetPaymentsPaise),
        ),
      )
      ..write(
        _kpi(
          isGu ? 'હાલનું બાકી કામ' : 'Current Pending',
          '${b.currentTotalPendingQty}',
          warn: b.currentTotalPendingQty > 0,
        ),
      )
      ..write(
        _kpi(
          isGu ? 'તપાસ બાકી (QC)' : 'Pending Inspection',
          '${b.currentTotalPendingInspectionQty}',
          warn: b.currentTotalPendingInspectionQty > 0,
        ),
      )
      ..write('</div>');

    if (b.dailyRows.isEmpty) {
      buf.write(
        '<p class="empty">${_e(isGu ? 'આ સમયગાળામાં કોઈ દૈનિક વ્યવહાર નથી.' : 'No daily workshop activity in this period.')}</p>',
      );
      return buf.toString();
    }

    buf.write(
      '<table><thead><tr>'
      '<th>${_e(isGu ? 'તારીખ (IST)' : 'Date (IST)')}</th>'
      '<th class="num">${_e(isGu ? 'ઇશ્યુ' : 'Issued')}</th>'
      '<th class="num">${_e(isGu ? 'સારા પરત' : 'Good Ret.')}</th>'
      '<th class="num">${_e(isGu ? 'નુકસાન' : 'Damaged')}</th>'
      '<th class="num">${_e(isGu ? 'ગુમ/ઘટ' : 'Lost/Short')}</th>'
      '<th class="num">${_e(isGu ? 'મજૂરી' : 'Labour')}</th>'
      '<th class="num">${_e(isGu ? 'ચુકવણી' : 'Payments')}</th>'
      '</tr></thead><tbody>',
    );
    for (final r in b.dailyRows) {
      buf.write(
        '<tr>'
        '<td>${_e(r.istDateIso)}</td>'
        '<td class="num">${r.issuedQty}</td>'
        '<td class="num">${r.goodReturnedQty}</td>'
        '<td class="num">${r.damagedQty}</td>'
        '<td class="num">${r.lostAndShortageQty}</td>'
        '<td class="num">${_e(MoneyFormatter.formatPaise(r.labourEarnedPaise))}</td>'
        '<td class="num">${_e(MoneyFormatter.formatPaise(r.netPaymentsPaise))}</td>'
        '</tr>',
      );
    }
    buf.write('</tbody></table>');
    return buf.toString();
  }

  String _buildWorkerSection(AdvancedReportsBundle b, {required bool isGu}) {
    if (b.workerPerformance.isEmpty) {
      return '<p class="empty">${_e(isGu ? 'કોઈ કારીગર ડેટા મળ્યો નથી.' : 'No worker performance records found.')}</p>';
    }
    final buf = StringBuffer()
      ..write(
        '<table><thead><tr>'
        '<th>${_e(isGu ? 'કારીગર' : 'Worker')}</th>'
        '<th class="num">${_e(isGu ? 'ઇશ્યુ' : 'Issued')}</th>'
        '<th class="num">${_e(isGu ? 'મંજૂર' : 'Accepted')}</th>'
        '<th class="num">${_e(isGu ? 'નુકસાન/ઘટ' : 'Rejected/Defects')}</th>'
        '<th class="num">${_e(isGu ? 'તપાસ બાકી' : 'Pending QC')}</th>'
        '<th class="num">${_e(isGu ? 'હાલનું બાકી' : 'Curr. Pending')}</th>'
        '<th class="num">${_e(isGu ? 'સમય મજૂરી' : 'Period Labour')}</th>'
        '<th class="num">${_e(isGu ? 'ચુકવણી' : 'Paid')}</th>'
        '<th class="num">${_e(isGu ? 'બાકી લેણું' : 'Outstanding')}</th>'
        '</tr></thead><tbody>',
      );
    for (final w in b.workerPerformance) {
      buf.write(
        '<tr>'
        '<td>${_e(w.workerName)}</td>'
        '<td class="num">${w.periodIssuedQty}</td>'
        '<td class="num">${w.periodGoodReturnedQty}</td>'
        '<td class="num">${w.periodDamagedQty + w.periodLostShortageQty}</td>'
        '<td class="num">${w.currentPendingInspectionQty}</td>'
        '<td class="num">${w.currentPendingQty}</td>'
        '<td class="num">${_e(MoneyFormatter.formatPaise(w.periodLabourEarnedPaise))}</td>'
        '<td class="num">${_e(MoneyFormatter.formatPaise(w.periodNetPaymentsPaise))}</td>'
        '<td class="num">${_e(MoneyFormatter.formatPaise(w.currentOutstandingPayablePaise))}</td>'
        '</tr>',
      );
    }
    buf.write('</tbody></table>');
    return buf.toString();
  }

  String _buildProcessSection(AdvancedReportsBundle b, {required bool isGu}) {
    if (b.processPerformance.isEmpty) {
      return '<p class="empty">${_e(isGu ? 'કોઈ પ્રક્રિયા ડેટા મળ્યો નથી.' : 'No process performance records found.')}</p>';
    }
    final buf = StringBuffer()
      ..write(
        '<table><thead><tr>'
        '<th>${_e(isGu ? 'પ્રક્રિયા' : 'Process')}</th>'
        '<th class="num">${_e(isGu ? 'ઇશ્યુ' : 'Issued')}</th>'
        '<th class="num">${_e(isGu ? 'મંજૂર (પૂર્ણ)' : 'Accepted')}</th>'
        '<th class="num">${_e(isGu ? 'તપાસ બાકી' : 'Pending QC')}</th>'
        '<th class="num">${_e(isGu ? 'હાલનું બાકી' : 'Curr. Pending')}</th>'
        '<th class="num">${_e(isGu ? 'સરેરાશ સમય' : 'Avg. Turnaround')}</th>'
        '<th class="num">${_e(isGu ? 'મજૂરી ખર્ચ' : 'Labour Cost')}</th>'
        '</tr></thead><tbody>',
      );
    for (final p in b.processPerformance) {
      final turnStr = p.averageTurnaroundHours == null
          ? '—'
          : '${AppDateTimeFormatter.formatDurationHours(p.averageTurnaroundHours!)} (n=${p.settledIssuesCount})';
      buf.write(
        '<tr>'
        '<td>${_e(p.processName)}</td>'
        '<td class="num">${p.periodIssuedQty}</td>'
        '<td class="num">${p.periodGoodReturnedQty}</td>'
        '<td class="num">${p.currentPendingInspectionQty}</td>'
        '<td class="num">${p.currentPendingQty}</td>'
        '<td class="num">${_e(turnStr)}</td>'
        '<td class="num">${_e(MoneyFormatter.formatPaise(p.periodLabourCostPaise))}</td>'
        '</tr>',
      );
    }
    buf.write('</tbody></table>');
    return buf.toString();
  }

  String _buildInventorySection(
    AdvancedReportsBundle b, {
    required bool isGu,
    int? subTabIndex,
  }) {
    final inv = b.inventory;
    final buf = StringBuffer()
      ..write('<div class="kpi-grid">')
      ..write(
        _kpi(isGu ? 'શરૂઆત સ્ટોક' : 'Initial Stock', '${inv.initialStock}'),
      )
      ..write(
        _kpi(
          isGu ? 'ઉપલબ્ધ સારો સ્ટોક' : 'Available Good',
          '${inv.availableGoodStock}',
        ),
      )
      ..write(
        _kpi(
          isGu ? 'કારીગર પાસે બાકી' : 'Pending w/ Workers',
          '${inv.pendingWithWorkers}',
          warn: inv.pendingWithWorkers > 0,
        ),
      )
      ..write(
        _kpi(
          isGu ? 'તપાસ બાકી (QC)' : 'Pending Inspection',
          '${b.currentTotalPendingInspectionQty}',
          warn: b.currentTotalPendingInspectionQty > 0,
        ),
      )
      ..write(
        _kpi(
          isGu ? 'નુકસાન સ્ટોક' : 'Damaged Bucket',
          '${inv.damagedBucket}',
          warn: inv.damagedBucket > 0,
        ),
      )
      ..write(
        _kpi(
          isGu ? 'અંદાજિત સ્ટોક કિંમત' : 'Reference Stock Value',
          MoneyFormatter.formatPaise(inv.referenceGoodStockValuePaise),
        ),
      )
      ..write('</div>');

    buf.write('<h3>${_e(isGu ? 'લોટ મુજબ સ્ટોક' : 'Lot-Wise Stock')}</h3>');
    if (inv.lotRows.isEmpty) {
      buf.write('<p class="empty">—</p>');
    } else {
      buf.write(
        '<table><thead><tr>'
        '<th>${_e(isGu ? 'લોટ' : 'Lot')}</th>'
        '<th class="num">${_e(isGu ? 'શરૂઆત' : 'Initial')}</th>'
        '<th class="num">${_e(isGu ? 'ઉપલબ્ધ' : 'Available')}</th>'
        '<th class="num">${_e(isGu ? 'બાકી' : 'Pending')}</th>'
        '<th class="num">${_e(isGu ? 'નુકસાન' : 'Damaged')}</th>'
        '<th class="num">${_e(isGu ? 'સંદર્ભ કિંમત' : 'Ref. Value')}</th>'
        '</tr></thead><tbody>',
      );
      for (final r in inv.lotRows) {
        buf.write(
          '<tr>'
          '<td>${_e(r.lotNumber)}${r.title != null ? ' • ${_e(r.title!)}' : ''}</td>'
          '<td class="num">${r.initialQuantity}</td>'
          '<td class="num">${r.availableGoodStock}</td>'
          '<td class="num">${r.pendingWithWorkers}</td>'
          '<td class="num">${r.damagedBucket}</td>'
          '<td class="num">${_e(MoneyFormatter.formatPaise(r.goodStockValuePaise))}</td>'
          '</tr>',
        );
      }
      buf.write('</tbody></table>');
    }

    if (inv.colourBalances.isNotEmpty) {
      buf.write(
        '<h3>${_e(isGu ? 'ડિઝાઇન અને રંગ મુજબ સ્ટોક' : 'Design & Colour Stock')}</h3>'
        '<table><thead><tr>'
        '<th>${_e(isGu ? 'લોટ / ડિઝાઇન / રંગ' : 'Lot / Design / Colour')}</th>'
        '<th class="num">${_e(isGu ? 'ઉપલબ્ધ' : 'Available')}</th>'
        '<th class="num">${_e(isGu ? 'બાકી' : 'Pending')}</th>'
        '<th class="num">${_e(isGu ? 'નુકસાન' : 'Damaged')}</th>'
        '</tr></thead><tbody>',
      );
      for (final c in inv.colourBalances.take(250)) {
        buf.write(
          '<tr>'
          '<td>${_e('${c.lotNumber} • ${c.designName} • ${c.colourName}')}</td>'
          '<td class="num">${c.physicalAvailableInHouse}</td>'
          '<td class="num">${c.totalPendingWithWorkers}</td>'
          '<td class="num">${c.damagedBucket}</td>'
          '</tr>',
        );
      }
      buf.write('</tbody></table>');
    }

    if (b.pendingInspectionReturns.isNotEmpty) {
      buf.write(
        '<h3>${_e(isGu ? 'તપાસ બાકી પરત (QC કતાર)' : 'Pending Inspection Returns (QC Queue)')}</h3>'
        '<table><thead><tr>'
        '<th>${_e(isGu ? 'લોટ / ડિઝાઇન / રંગ' : 'Lot / Design / Colour')}</th>'
        '<th>${_e(isGu ? 'કારીગર' : 'Worker')}</th>'
        '<th>${_e(isGu ? 'પ્રક્રિયા' : 'Process')}</th>'
        '<th class="num">${_e(isGu ? 'પરત' : 'Returned')}</th>'
        '<th class="num">${_e(isGu ? 'તપાસ બાકી' : 'Pending QC')}</th>'
        '<th class="num">${_e(isGu ? 'દર (લોક)' : 'Locked Rate')}</th>'
        '</tr></thead><tbody>',
      );
      for (final r in b.pendingInspectionReturns.take(150)) {
        buf.write(
          '<tr>'
          '<td>${_e('${r.lotNumber} • ${r.designName} • ${r.colourName}')}</td>'
          '<td>${_e(r.workerName)}</td>'
          '<td>${_e(r.processName)}</td>'
          '<td class="num">${r.productionReturn.returnedQuantity}</td>'
          '<td class="num">${r.remainingPendingInspectionQty}</td>'
          '<td class="num">${_e(MoneyFormatter.formatPaise(r.lockedRatePaise))}</td>'
          '</tr>',
        );
      }
      buf.write('</tbody></table>');
    }

    if (b.rejectionRecords.isNotEmpty) {
      buf.write(
        '<h3>${_e(isGu ? 'રિજેક્શન અને રિપેર ટ્રેકિંગ' : 'Rejections & Repair Tracking')}</h3>'
        '<table><thead><tr>'
        '<th>${_e(isGu ? 'લોટ / ડિઝાઇન / રંગ' : 'Lot / Design / Colour')}</th>'
        '<th>${_e(isGu ? 'કારીગર / પ્રક્રિયા' : 'Worker / Process')}</th>'
        '<th class="num">${_e(isGu ? 'રિજેક્ટ' : 'Rejected')}</th>'
        '<th class="num">${_e(isGu ? 'ફરી મંજૂર' : 'Re-Approved')}</th>'
        '<th class="num">${_e(isGu ? 'બાકી' : 'Remaining')}</th>'
        '<th>${_e(isGu ? 'સ્થિતિ' : 'Status')}</th>'
        '</tr></thead><tbody>',
      );
      for (final r in b.rejectionRecords.take(150)) {
        buf.write(
          '<tr>'
          '<td>${_e('${r.lotNumber} • ${r.designName} • ${r.colourName}')}</td>'
          '<td>${_e('${r.workerName} • ${r.processName}')}</td>'
          '<td class="num">${r.record.rejectedQuantity}</td>'
          '<td class="num">${r.totalReapprovedQty}</td>'
          '<td class="num">${r.netRejectedQty}</td>'
          '<td>${_e(r.record.status.dbValue)}</td>'
          '</tr>',
        );
      }
      buf.write('</tbody></table>');
    }
    return buf.toString();
  }

  String _buildFinancialSection(
    AdvancedReportsBundle b, {
    required bool isGu,
    int? subTabIndex,
  }) {
    final fin = b.financial;
    final buf = StringBuffer()
      ..write('<div class="kpi-grid">')
      ..write(
        _kpi(
          isGu ? 'કમાયેલી મજૂરી (સમય)' : 'Earned Labour (Period)',
          MoneyFormatter.formatPaise(fin.periodEarnedLabourPaise),
        ),
      )
      ..write(
        _kpi(
          isGu ? 'નેટ ચુકવણી (સમય)' : 'Net Payments (Period)',
          MoneyFormatter.formatPaise(fin.periodNetPaymentsPaise),
        ),
      )
      ..write(
        _kpi(
          isGu ? 'હાલનું બાકી લેણું' : 'Current Outstanding Payable',
          MoneyFormatter.formatPaise(fin.totalCurrentOutstandingPayablePaise),
          warn: fin.totalCurrentOutstandingPayablePaise > 0,
        ),
      )
      ..write(
        _kpi(
          isGu ? 'એડવાન્સ જમા' : 'Current Advance Credit',
          MoneyFormatter.formatPaise(fin.totalCurrentAdvanceCreditPaise),
        ),
      )
      ..write('</div>');

    buf.write(
      '<h3>${_e(isGu ? 'કારીગર હિસાબ સારાંશ' : 'Worker Financial Summary')}</h3>',
    );
    if (fin.workerSummaries.isEmpty) {
      buf.write('<p class="empty">—</p>');
    } else {
      buf.write(
        '<table><thead><tr>'
        '<th>${_e(isGu ? 'કારીગર' : 'Worker')}</th>'
        '<th class="num">${_e(isGu ? 'કુલ મજૂરી' : 'Earned Labour')}</th>'
        '<th class="num">${_e(isGu ? 'નિયમિત ચુકવણી' : 'Regular Paid')}</th>'
        '<th class="num">${_e(isGu ? 'એડવાન્સ' : 'Advance')}</th>'
        '<th class="num">${_e(isGu ? 'બાકી લેણું' : 'Outstanding')}</th>'
        '</tr></thead><tbody>',
      );
      for (final w in fin.workerSummaries) {
        buf.write(
          '<tr>'
          '<td>${_e(w.workerName)}</td>'
          '<td class="num">${_e(MoneyFormatter.formatPaise(w.earnedLabourPaise))}</td>'
          '<td class="num">${_e(MoneyFormatter.formatPaise(w.regularPaymentsPaise))}</td>'
          '<td class="num">${_e(MoneyFormatter.formatPaise(w.advancePaymentsPaise))}</td>'
          '<td class="num">${_e(MoneyFormatter.formatPaise(w.outstandingPayablePaise))}</td>'
          '</tr>',
        );
      }
      buf.write('</tbody></table>');
    }
    return buf.toString();
  }

  String _buildInsightsSection(AdvancedReportsBundle b, {required bool isGu}) {
    final ins = b.insights;
    final buf = StringBuffer()
      ..write('<div class="kpi-grid">')
      ..write(
        _kpi(
          isGu ? 'કુલ મજૂરી ખર્ચ' : 'Total Labour Cost',
          MoneyFormatter.formatPaise(ins.totalPeriodLabourCostPaise),
        ),
      )
      ..write(
        _kpi(
          isGu ? 'નુકસાન / ઘટ દર' : 'Defect / Loss Rate',
          ins.overallDefectRatePercent == null
              ? '—'
              : '${ins.overallDefectRatePercent!.toStringAsFixed(1)}%',
          warn: (ins.overallDefectRatePercent ?? 0) > 5,
        ),
      )
      ..write(
        _kpi(
          isGu ? 'અવરોધિત પ્રક્રિયાઓ' : 'Process Bottlenecks',
          '${ins.bottlenecks.length}',
          warn: ins.bottlenecks.isNotEmpty,
        ),
      )
      ..write('</div>');

    buf.write(
      '<h3>${_e(isGu ? 'પ્રક્રિયા અવરોધો (Bottlenecks)' : 'Process Bottlenecks')}</h3>',
    );
    if (ins.bottlenecks.isEmpty) {
      buf.write(
        '<p class="empty">${_e(isGu ? 'કોઈ બાકી અવરોધ નથી.' : 'No active process bottlenecks.')}</p>',
      );
    } else {
      buf.write(
        '<table><thead><tr>'
        '<th>${_e(isGu ? 'પ્રક્રિયા' : 'Process')}</th>'
        '<th class="num">${_e(isGu ? 'બાકી નંગ' : 'Pending Pcs')}</th>'
        '<th class="num">${_e(isGu ? 'ખુલ્લા ઇશ્યુ' : 'Open Issues')}</th>'
        '<th class="num">${_e(isGu ? 'સૌથી જૂનું (દિવસ)' : 'Oldest (Days)')}</th>'
        '</tr></thead><tbody>',
      );
      for (final bn in ins.bottlenecks) {
        buf.write(
          '<tr>'
          '<td>${_e(bn.processName)}</td>'
          '<td class="num">${bn.currentPendingQty}</td>'
          '<td class="num">${bn.openIssuesCount}</td>'
          '<td class="num">${bn.oldestOpenIssueAgeDays}</td>'
          '</tr>',
        );
      }
      buf.write('</tbody></table>');
    }

    if (ins.processLabourCostShares.isNotEmpty) {
      buf.write(
        '<h3>${_e(isGu ? 'પ્રક્રિયા મુજબ મજૂરી ખર્ચ' : 'Labour Cost by Process')}</h3>'
        '<table><thead><tr>'
        '<th>${_e(isGu ? 'પ્રક્રિયા' : 'Process')}</th>'
        '<th class="num">${_e(isGu ? 'મજૂરી ખર્ચ' : 'Labour Cost')}</th>'
        '<th class="num">${_e(isGu ? 'હિસ્સો %' : 'Share %')}</th>'
        '</tr></thead><tbody>',
      );
      for (final s in ins.processLabourCostShares) {
        buf.write(
          '<tr>'
          '<td>${_e(s.processName)}</td>'
          '<td class="num">${_e(MoneyFormatter.formatPaise(s.labourCostPaise))}</td>'
          '<td class="num">${s.sharePercent.toStringAsFixed(1)}%</td>'
          '</tr>',
        );
      }
      buf.write('</tbody></table>');
    }

    return buf.toString();
  }
}
