import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/features/slips/domain/entities/slip_entities.dart';

/// Pure Dart formatter generating clean, WhatsApp/SMS-ready bilingual (EN/GU)
/// text summaries for all 4 Karigar slip types.
final class SlipTextFormatter {
  const SlipTextFormatter();

  String titleFor(SlipDocumentType type, {required bool isGu}) => switch (type) {
    SlipDocumentType.stockIssueChallan =>
      isGu ? 'માલ ઇશ્યુ ચલણ' : 'STOCK ISSUE CHALLAN',
    SlipDocumentType.returnQcSlip =>
      isGu ? 'માલ પરત / QC સ્લિપ' : 'RETURN / QC SLIP',
    SlipDocumentType.paymentReceipt =>
      isGu ? 'ચુકવણી રસીદ' : 'PAYMENT RECEIPT',
    SlipDocumentType.workerKhataStatement =>
      isGu ? 'કારીગર ખાતાવહી સ્ટેટમેન્ટ' : 'WORKER KHATA STATEMENT',
  };

  String format(WorkerSlipData slip, {required String localeCode}) {
    final isGu = localeCode == 'gu';
    final shop = slip.shopNameForLocale(localeCode);
    final title = titleFor(slip.type, isGu: isGu);
    final dateStr = IstDateTimeHelper.formatIstDateTime(
      slip.transactionAtUtcMillis,
      locale: localeCode,
    );
    final period = slip.periodForLocale(localeCode);

    final buf = StringBuffer()
      ..writeln('*$shop*')
      ..writeln('━━━━━━━━━━━━━━━━━━━━')
      ..writeln('*$title*')
      ..writeln('${isGu ? 'સંદર્ભ' : 'Ref'}: ${slip.referenceId}')
      ..writeln('${isGu ? 'તારીખ' : 'Date'}: $dateStr (IST)');

    if (period != null && period.isNotEmpty) {
      buf.writeln('${isGu ? 'સમયગાળો' : 'Period'}: $period');
    }

    buf
      ..writeln('${isGu ? 'કારીગર' : 'Worker'}: ${slip.workerName}')
      ..writeln('────────────────────');

    for (final item in slip.items) {
      buf.write('• ${item.title}');
      if (item.quantityText != null && item.quantityText!.isNotEmpty) {
        buf.write('  [${item.quantityText}]');
      }
      if (item.rateText != null && item.rateText!.isNotEmpty) {
        buf.write(' @ ${item.rateText}');
      }
      if (item.amountPaise != null) {
        buf.write(' = ${MoneyFormatter.formatPaise(item.amountPaise!)}');
      }
      buf.writeln();
      if (item.subtitle != null && item.subtitle!.isNotEmpty) {
        buf.writeln('  ${item.subtitle}');
      }
    }

    buf.writeln('────────────────────');

    if (slip.primaryAmountPaise != null) {
      final amtLabel = switch (slip.type) {
        SlipDocumentType.paymentReceipt =>
          isGu ? 'ચૂકવેલ રકમ' : 'Amount Paid',
        SlipDocumentType.returnQcSlip =>
          isGu ? 'મજૂરી કમાણી' : 'Labour Earned',
        _ => isGu ? 'કુલ રકમ' : 'Total Amount',
      };
      buf.writeln(
        '*$amtLabel: ${MoneyFormatter.formatPaise(slip.primaryAmountPaise!)}*',
      );
    }

    if (slip.outstandingPayablePaise > 0) {
      buf.writeln(
        '${isGu ? 'બાકી ચૂકવવાપાત્ર' : 'Outstanding Payable'}: '
        '${MoneyFormatter.formatPaise(slip.outstandingPayablePaise)}',
      );
    } else if (slip.advanceCreditPaise > 0) {
      buf.writeln(
        '${isGu ? 'એડવાન્સ જમા બાકી' : 'Advance Credit Balance'}: '
        '${MoneyFormatter.formatPaise(slip.advanceCreditPaise)}',
      );
    } else {
      buf.writeln(
        '${isGu ? 'ખાતાની સ્થિતિ' : 'Account Balance'}: '
        '${MoneyFormatter.formatPaise(0)} (${isGu ? 'હિસાબ ચોખ્ખો' : 'Settled'})',
      );
    }

    if (slip.notes != null && slip.notes!.trim().isNotEmpty) {
      buf.writeln('${isGu ? 'નોંધ' : 'Note'}: ${slip.notes!.trim()}');
    }

    buf
      ..writeln('━━━━━━━━━━━━━━━━━━━━')
      ..writeln(
        isGu
            ? 'StitchFlow ઓફલાઇન દ્વારા તૈયાર'
            : 'Generated offline via StitchFlow',
      );

    return buf.toString().trimRight();
  }
}
