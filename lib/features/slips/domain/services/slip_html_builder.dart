import 'dart:convert';

import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/features/slips/domain/entities/slip_entities.dart';
import 'package:business_manager/features/slips/domain/services/slip_text_formatter.dart';

/// Pure-Dart bilingual EN/GU HTML generator for printable/PDF Karigar slips
/// using StitchFlow's Indigo Thread palette and bundled `NotoSansGujarati`.
final class SlipHtmlBuilder {
  const SlipHtmlBuilder();

  static const HtmlEscape _esc = HtmlEscape();
  static const SlipTextFormatter _textFormatter = SlipTextFormatter();

  String _e(String value) => _esc.convert(value);

  String buildHtml(WorkerSlipData slip, {required String localeCode}) {
    final isGu = localeCode == 'gu';
    final shop = slip.shopNameForLocale(localeCode);
    final title = _textFormatter.titleFor(slip.type, isGu: isGu);
    final dateStr = IstDateTimeHelper.formatIstDateTime(
      slip.transactionAtUtcMillis,
      locale: localeCode,
    );
    final period = slip.periodForLocale(localeCode);

    final rowsHtml = StringBuffer();
    for (final item in slip.items) {
      rowsHtml.writeln('<tr>');
      rowsHtml.writeln(
        '<td><strong>${_e(item.title)}</strong>'
        '${item.subtitle != null && item.subtitle!.isNotEmpty ? '<div class="sub">${_e(item.subtitle!)}</div>' : ''}'
        '</td>',
      );
      rowsHtml.writeln(
        '<td class="num">${_e(item.quantityText ?? '—')}</td>',
      );
      rowsHtml.writeln(
        '<td class="num">${_e(item.rateText ?? '—')}</td>',
      );
      rowsHtml.writeln(
        '<td class="num">${item.amountPaise != null ? _e(MoneyFormatter.formatPaise(item.amountPaise!)) : '—'}</td>',
      );
      rowsHtml.writeln('</tr>');
    }

    final balanceLabel = slip.outstandingPayablePaise > 0
        ? (isGu ? 'બાકી ચૂકવવાપાત્ર' : 'Outstanding Payable')
        : slip.advanceCreditPaise > 0
        ? (isGu ? 'એડવાન્સ જમા બાકી' : 'Advance Credit Balance')
        : (isGu ? 'ખાતાની બાકી' : 'Account Balance');
    final balanceValue = slip.outstandingPayablePaise > 0
        ? MoneyFormatter.formatPaise(slip.outstandingPayablePaise)
        : slip.advanceCreditPaise > 0
        ? MoneyFormatter.formatPaise(slip.advanceCreditPaise)
        : MoneyFormatter.formatPaise(0);

    return '''
<!DOCTYPE html>
<html lang="${isGu ? 'gu' : 'en'}">
<head>
<meta charset="UTF-8" />
<meta name="viewport" content="width=device-width, initial-scale=1.0" />
<title>${_e(title)} - ${_e(slip.referenceId)}</title>
<style>
  @font-face {
    font-family: 'NotoSansGujarati';
    src: url('assets/assets/fonts/NotoSansGujarati-Regular.ttf') format('truetype'),
         url('file:///android_asset/flutter_assets/assets/fonts/NotoSansGujarati-Regular.ttf') format('truetype');
    font-weight: 400;
  }
  @font-face {
    font-family: 'NotoSansGujarati';
    src: url('assets/assets/fonts/NotoSansGujarati-Bold.ttf') format('truetype'),
         url('file:///android_asset/flutter_assets/assets/fonts/NotoSansGujarati-Bold.ttf') format('truetype');
    font-weight: 700;
  }
  @page { size: A5 portrait; margin: 10mm; }
  * { box-sizing: border-box; }
  body {
    font-family: 'NotoSansGujarati', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    color: #0F172A;
    margin: 0;
    padding: 0;
    font-size: 11px;
    line-height: 1.45;
  }
  .slip {
    border: 1.5px solid #4F46E5;
    border-radius: 10px;
    overflow: hidden;
  }
  .banner {
    background: #4F46E5;
    color: #FFFFFF;
    padding: 12px 14px;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  .shop { font-size: 16px; font-weight: 700; margin: 0; }
  .shop-meta { font-size: 9.5px; opacity: 0.9; margin-top: 2px; }
  .badge {
    background: #059669;
    color: #FFFFFF;
    padding: 4px 10px;
    border-radius: 999px;
    font-weight: 700;
    font-size: 10px;
  }
  .body { padding: 12px 14px; }
  .meta-grid {
    display: flex;
    justify-content: space-between;
    gap: 12px;
    margin-bottom: 10px;
    padding-bottom: 8px;
    border-bottom: 1px dashed #CBD5E1;
  }
  .meta-label { color: #64748B; font-size: 9.5px; }
  .meta-val { font-weight: 700; color: #0F172A; }
  table {
    width: 100%;
    border-collapse: collapse;
    margin: 8px 0 12px 0;
    font-variant-numeric: tabular-nums;
  }
  th {
    background: #EEF2FF;
    color: #312E81;
    border-bottom: 1.5px solid #4F46E5;
    padding: 6px;
    text-align: left;
    font-size: 10px;
  }
  td {
    border-bottom: 1px solid #E2E8F0;
    padding: 6px;
    vertical-align: top;
  }
  .sub { font-size: 9.5px; color: #64748B; margin-top: 2px; }
  .num { text-align: right; white-space: nowrap; }
  .summary {
    background: #F8FAFC;
    border: 1px solid #CBD5E1;
    border-left: 4px solid #059669;
    border-radius: 6px;
    padding: 8px 10px;
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-top: 8px;
  }
  .summary.primary {
    border-left-color: #4F46E5;
    margin-bottom: 6px;
  }
  .notes {
    margin-top: 8px;
    font-size: 10px;
    color: #475569;
  }
  .footer {
    margin-top: 12px;
    padding-top: 8px;
    border-top: 1px solid #E2E8F0;
    display: flex;
    justify-content: space-between;
    font-size: 9.5px;
    color: #64748B;
  }
</style>
</head>
<body>
  <div class="slip">
    <div class="banner">
      <div>
        <p class="shop">${_e(shop)}</p>
        ${slip.businessPhone != null && slip.businessPhone!.isNotEmpty ? '<div class="shop-meta">${_e(slip.businessPhone!)}</div>' : ''}
      </div>
      <div class="badge">${_e(title)}</div>
    </div>
    <div class="body">
      <div class="meta-grid">
        <div>
          <div class="meta-label">${isGu ? 'કારીગર' : 'Worker'}</div>
          <div class="meta-val">${_e(slip.workerName)}</div>
          ${slip.workerPhone != null && slip.workerPhone!.isNotEmpty ? '<div class="sub">${_e(slip.workerPhone!)}</div>' : ''}
        </div>
        <div style="text-align:right">
          <div class="meta-label">${isGu ? 'સંદર્ભ / તારીખ' : 'Ref / Date (IST)'}</div>
          <div class="meta-val">${_e(slip.referenceId)}</div>
          <div class="sub">${_e(dateStr)}${period != null && period.isNotEmpty ? ' • ${_e(period)}' : ''}</div>
        </div>
      </div>
      <table>
        <thead>
          <tr>
            <th>${isGu ? 'વિગત' : 'Description'}</th>
            <th class="num">${isGu ? 'જથ્થો' : 'Qty'}</th>
            <th class="num">${isGu ? 'દર' : 'Rate'}</th>
            <th class="num">${isGu ? 'રકમ' : 'Amount'}</th>
          </tr>
        </thead>
        <tbody>
          $rowsHtml
        </tbody>
      </table>
      ${slip.primaryAmountPaise != null ? '''
      <div class="summary primary">
        <span>${isGu ? 'કુલ રકમ' : 'Slip Total'}</span>
        <strong>${_e(MoneyFormatter.formatPaise(slip.primaryAmountPaise!))}</strong>
      </div>''' : ''}
      <div class="summary">
        <span>${_e(balanceLabel)}</span>
        <strong>${_e(balanceValue)}</strong>
      </div>
      ${slip.notes != null && slip.notes!.trim().isNotEmpty ? '<div class="notes"><strong>${isGu ? 'નોંધ' : 'Notes'}:</strong> ${_e(slip.notes!.trim())}</div>' : ''}
      <div class="footer">
        <span>StitchFlow • ${isGu ? 'ઓફલાઇન રસીદ' : 'Offline Slip'}</span>
        <span>${isGu ? 'સહી: ______________' : 'Signature: ______________'}</span>
      </div>
    </div>
  </div>
</body>
</html>
''';
  }
}
