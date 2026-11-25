import 'package:intl/intl.dart';

/// System-wide Indian Rupee (`en_IN`) currency and numeric formatter powered by
/// `package:intl`.
///
/// All monetary values are stored in integer paise (`₹20.50` = `2050`) and
/// formatted using standard Indian accounting notation (lakh/crore grouping
/// with 2 decimal places, e.g., `₹1,25,000.00`).
abstract final class MoneyFormatter {
  static final NumberFormat _inrCurrencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final NumberFormat _inrPlainFormat = NumberFormat(
    '#,##,##0.00',
    'en_IN',
  );

  static final NumberFormat _inrIntegerFormat = NumberFormat.decimalPattern(
    'en_IN',
  );

  static double _paiseToExactDouble(int absPaise) {
    final rupees = absPaise ~/ 100;
    final remainderPaise = absPaise % 100;
    return rupees + (remainderPaise / 100);
  }

  /// Formats [paise] using Indian numbering system with ₹ symbol and 2 decimal
  /// places (e.g., `12500000` -> `₹1,25,000.00`, `-2550` -> `-₹25.50`).
  static String formatPaise(int paise) {
    final isNegative = paise < 0;
    final formatted = _inrCurrencyFormat.format(
      _paiseToExactDouble(paise.abs()),
    );
    return isNegative ? '-$formatted' : formatted;
  }

  /// Formats [paise] with explicit sign prefix for ledger deltas/adjustments
  /// (e.g., `125000` -> `+₹1,250.00`, `-50000` -> `-₹500.00`, `0` -> `₹0.00`).
  static String formatSignedPaise(int paise) {
    if (paise > 0) return '+${formatPaise(paise)}';
    return formatPaise(paise);
  }

  /// Formats [paise] in Indian numbering system WITHOUT the `₹` symbol
  /// (e.g., `12500000` -> `1,25,000.00`). Useful when a table header already
  /// specifies `(₹)`.
  static String formatPaiseWithoutSymbol(int paise) {
    final isNegative = paise < 0;
    final formatted = _inrPlainFormat.format(_paiseToExactDouble(paise.abs()));
    return isNegative ? '-$formatted' : formatted;
  }

  /// Formats [paise] as a plain editable decimal string without currency symbol
  /// or thousands commas (e.g., `2550` -> `25.50`, `0` -> `0.00`) for
  /// `TextEditingController` prefill without floating-point drift.
  static String formatPaiseForInput(int paise) {
    final isNegative = paise < 0;
    final absPaise = paise.abs();
    final rupees = absPaise ~/ 100;
    final rem = absPaise % 100;
    final raw = '$rupees.${rem.toString().padLeft(2, '0')}';
    return isNegative ? '-$raw' : raw;
  }

  /// Formats a labour or unit rate in INR along with its pricing unit suffix
  /// (e.g., `₹25.50 / pc`, `₹300.00 / doz`).
  static String formatRatePaise(
    int paise, {
    String pricingUnit = 'PER_PIECE',
    String? unitLabel,
  }) {
    final suffix = unitLabel ?? shortUnitSuffix(pricingUnit);
    return '${formatPaise(paise)} / $suffix';
  }

  /// Standard short unit suffix for a database pricing unit code.
  static String shortUnitSuffix(String pricingUnit) {
    return switch (pricingUnit.trim().toUpperCase()) {
      'PER_DOZEN' => 'doz',
      'PER_LOT' => 'lot',
      'FIXED_AMOUNT' => 'fixed',
      _ => 'pc',
    };
  }

  /// Formats an integer quantity using Indian digit grouping
  /// (e.g., `125000` -> `1,25,000`).
  static String formatQuantity(int quantity) {
    return _inrIntegerFormat.format(quantity);
  }
}
