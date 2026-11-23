import 'package:intl/intl.dart';

/// Formats integer paise values (`₹20.50` = `2050`) into Indian currency strings
/// without floating-point drift.
abstract final class MoneyFormatter {
  static final NumberFormat _inrFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Formats [paise] using Indian numbering system (e.g., `12500000` -> `₹1,25,000.00`).
  static String formatPaise(int paise) {
    final isNegative = paise < 0;
    final absPaise = paise.abs();
    final rupees = absPaise ~/ 100;
    final remainderPaise = absPaise % 100;
    final exactDecimal = rupees + (remainderPaise / 100);
    final formatted = _inrFormat.format(exactDecimal);
    return isNegative ? '-$formatted' : formatted;
  }
}
