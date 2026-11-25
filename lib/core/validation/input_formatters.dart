import 'package:flutter/services.dart';

/// Shared input formatters for StitchFlow forms.
///
/// NOTE: Input formatters improve typing ergonomics ONLY — they never replace
/// `AppValidators` or domain/repository validation.
abstract final class AppInputFormatters {
  /// Allows only ASCII digits `0-9` (for garment piece quantities & PINs).
  static final TextInputFormatter digitsOnly =
      FilteringTextInputFormatter.digitsOnly;

  /// Allows non-negative decimal numbers with at most 2 fractional digits
  /// (for ₹ monetary amounts & process rates).
  static final TextInputFormatter currencyDecimal =
      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$'));

  /// Allows characters valid in Indian & E.164 international phone numbers.
  static final TextInputFormatter phoneChars =
      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]'));

  /// Allows `#` and hexadecimal digits for colour HEX codes (`#RRGGBB`).
  static final TextInputFormatter hexColor = FilteringTextInputFormatter.allow(
    RegExp(r'[#0-9a-fA-F]'),
  );
}
