import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    IstDateTimeHelper.initialize();
    await initializeDateFormatting('en');
    await initializeDateFormatting('gu');
  });

  group('MoneyFormatter (Indian Rupee en_IN standard accounting)', () {
    test('formats paise with Indian lakh/crore grouping and 2 decimals', () {
      expect(MoneyFormatter.formatPaise(0), '₹0.00');
      expect(MoneyFormatter.formatPaise(2550), '₹25.50');
      expect(MoneyFormatter.formatPaise(125000), '₹1,250.00');
      expect(MoneyFormatter.formatPaise(12500000), '₹1,25,000.00');
      expect(MoneyFormatter.formatPaise(123456789), '₹12,34,567.89');
      expect(MoneyFormatter.formatPaise(1000000000), '₹1,00,00,000.00');
      expect(MoneyFormatter.formatPaise(-2550), '-₹25.50');
      expect(MoneyFormatter.formatPaise(-12500000), '-₹1,25,000.00');
    });

    test('formats signed paise deltas accurately', () {
      expect(MoneyFormatter.formatSignedPaise(125000), '+₹1,250.00');
      expect(MoneyFormatter.formatSignedPaise(-50000), '-₹500.00');
      expect(MoneyFormatter.formatSignedPaise(0), '₹0.00');
    });

    test('formats plain INR without symbol and clean input strings', () {
      expect(MoneyFormatter.formatPaiseWithoutSymbol(12500000), '1,25,000.00');
      expect(MoneyFormatter.formatPaiseWithoutSymbol(-2550), '-25.50');
      expect(MoneyFormatter.formatPaiseForInput(0), '0.00');
      expect(MoneyFormatter.formatPaiseForInput(2550), '25.50');
      expect(MoneyFormatter.formatPaiseForInput(12500000), '125000.00');
    });

    test('formats labour rates with pricing units and Indian quantities', () {
      expect(MoneyFormatter.formatRatePaise(2550), '₹25.50 / pc');
      expect(
        MoneyFormatter.formatRatePaise(30000, pricingUnit: 'PER_DOZEN'),
        '₹300.00 / doz',
      );
      expect(
        MoneyFormatter.formatRatePaise(500000, pricingUnit: 'PER_LOT'),
        '₹5,000.00 / lot',
      );
      expect(
        MoneyFormatter.formatRatePaise(150000, pricingUnit: 'FIXED_AMOUNT'),
        '₹1,500.00 / fixed',
      );
      expect(MoneyFormatter.formatQuantity(125000), '1,25,000');
    });
  });

  group('AppDateTimeFormatter (centralized IST date & time helper)', () {
    test('formats IST date, date-time, 12h time, and short date cleanly', () {
      final utcMillis = IstDateTimeHelper.istDateTimeToUtcMillis(
        year: 2026,
        month: 11,
        day: 24,
        hour: 16,
        minute: 15,
      );

      expect(AppDateTimeFormatter.formatDate(utcMillis), '24 Nov 2026');
      expect(
        AppDateTimeFormatter.formatDateTime(utcMillis),
        '24 Nov 2026, 04:15 PM',
      );
      expect(AppDateTimeFormatter.formatTime(utcMillis), '04:15 PM');
      expect(
        AppDateTimeFormatter.formatTime(utcMillis, includeIstSuffix: true),
        '04:15 PM IST',
      );
      expect(AppDateTimeFormatter.formatShortDate(utcMillis), '24 Nov');
      expect(
        AppDateTimeFormatter.formatTimeFromHourMinute(
          20,
          0,
          includeIstSuffix: true,
        ),
        '08:00 PM IST',
      );
      expect(
        AppDateTimeFormatter.toIstBusinessDate(utcMillis),
        '2026-11-24',
      );
      // IstDateTimeHelper delegates cleanly to AppDateTimeFormatter
      expect(
        IstDateTimeHelper.formatIstDateTime(utcMillis),
        '24 Nov 2026, 04:15 PM',
      );
    });

    test('formats ISO business dates and effective date ranges', () {
      expect(
        AppDateTimeFormatter.formatIsoBusinessDateForDisplay('2026-11-24'),
        '24 Nov 2026',
      );
      expect(
        AppDateTimeFormatter.formatIsoBusinessDateForDisplay('invalid'),
        'invalid',
      );
      expect(
        AppDateTimeFormatter.formatIsoDateRange(
          fromIso: '2026-01-01',
          toIso: '2026-03-31',
          ongoingLabel: 'Ongoing',
        ),
        '01 Jan 2026 – 31 Mar 2026',
      );
      expect(
        AppDateTimeFormatter.formatIsoDateRange(
          fromIso: '2026-04-01',
          toIso: null,
          ongoingLabel: 'Ongoing',
        ),
        '01 Apr 2026 – Ongoing',
      );
    });

    test('formats deterministic timestamps, durations, and countdowns', () {
      final utcMillis = IstDateTimeHelper.istDateTimeToUtcMillis(
        year: 2026,
        month: 11,
        day: 24,
        hour: 9,
        minute: 5,
        second: 3,
      );
      expect(
        AppDateTimeFormatter.formatIsoDateTimeIst(utcMillis),
        '2026-11-24 09:05:03 IST',
      );
      expect(
        AppDateTimeFormatter.formatFileTimestampIst(utcMillis),
        '20261124_090503',
      );
      expect(AppDateTimeFormatter.formatDurationHours(4.5), '4.5h');
      expect(AppDateTimeFormatter.formatDurationHours(60), '2.5d');
      expect(AppDateTimeFormatter.formatCountdownSeconds(125), '2m 05s');
      expect(AppDateTimeFormatter.formatCountdownSeconds(45), '45s');
    });
  });
}
