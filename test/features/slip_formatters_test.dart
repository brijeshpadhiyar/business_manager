import 'package:business_manager/features/slips/domain/entities/slip_entities.dart';
import 'package:business_manager/features/slips/domain/services/slip_html_builder.dart';
import 'package:business_manager/features/slips/domain/services/slip_text_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('gu');
  });

  const textFormatter = SlipTextFormatter();
  const htmlBuilder = SlipHtmlBuilder();

  const sampleSlip = WorkerSlipData(
    type: SlipDocumentType.paymentReceipt,
    referenceId: 'PAY-1042',
    businessNameEn: 'Shree Krishna Garments',
    businessNameGu: 'શ્રી કૃષ્ણ ગારમેન્ટ્સ',
    businessPhone: '+91 9876543210',
    workerName: 'Rameshbhai Patel',
    workerPhone: '+91 9123456789',
    transactionAtUtcMillis: 1732620000000,
    items: [
      SlipLineItem(
        title: 'Regular Payment',
        subtitle: 'UPI',
        amountPaise: 250000,
      ),
    ],
    primaryAmountPaise: 250000,
    outstandingPayablePaise: 120000,
    notes: 'Weekly settlement',
  );

  group('SlipTextFormatter & SlipHtmlBuilder', () {
    test('formats English and Gujarati WhatsApp text accurately', () {
      final enText = textFormatter.format(sampleSlip, localeCode: 'en');
      expect(enText, contains('Shree Krishna Garments'));
      expect(enText, contains('PAYMENT RECEIPT'));
      expect(enText, contains('PAY-1042'));
      expect(enText, contains('Rameshbhai Patel'));
      expect(enText, contains('Outstanding Payable'));

      final guText = textFormatter.format(sampleSlip, localeCode: 'gu');
      expect(guText, contains('શ્રી કૃષ્ણ ગારમેન્ટ્સ'));
      expect(guText, contains('ચુકવણી રસીદ'));
      expect(guText, contains('બાકી ચૂકવવાપાત્ર'));
    });

    test('renders Indigo Thread HTML with NotoSansGujarati and XSS escaping', () {
      final htmlEn = htmlBuilder.buildHtml(sampleSlip, localeCode: 'en');
      expect(htmlEn, contains('#4F46E5'));
      expect(htmlEn, contains('#059669'));
      expect(htmlEn, contains('NotoSansGujarati'));
      expect(htmlEn, contains('Shree Krishna Garments'));

      const xssSlip = WorkerSlipData(
        type: SlipDocumentType.stockIssueChallan,
        referenceId: '<script>alert(1)</script>',
        businessNameEn: 'Shop & Co',
        businessNameGu: 'શોપ',
        workerName: '<b>Worker</b>',
        transactionAtUtcMillis: 1732620000000,
        items: [
          SlipLineItem(
            title: 'LOT-1',
            quantityText: '50 pcs',
            rateText: '₹25/pc',
            amountPaise: 125000,
          ),
        ],
      );
      final escapedHtml = htmlBuilder.buildHtml(xssSlip, localeCode: 'gu');
      expect(escapedHtml, isNot(contains('<script>')));
      expect(escapedHtml, contains('&lt;script&gt;'));
      expect(escapedHtml, contains('માલ ઇશ્યુ ચલણ'));
    });
  });
}
