import 'package:business_manager/core/validation/validation_error.dart';
import 'package:business_manager/features/security/domain/services/pin_hasher.dart';

/// Pure Dart, UI-independent centralized validation suite for StitchFlow V1.3.
///
/// Designed for consistent enforcement across:
/// - Flutter `Form` / `TextFormField` widgets
/// - BLoC / Cubit business rules
/// - Repository / data-layer invariants
///
/// Never mutates or silently truncates user input.
abstract final class AppValidators {
  static final RegExp _mobileAllowedChars = RegExp(r'^[0-9+\-\s()]+$');
  static final RegExp _indianTenDigits = RegExp(r'^[6-9]\d{9}$');
  static final RegExp _e164Digits = RegExp(r'^[1-9]\d{6,14}$');
  static final RegExp _emailPattern = RegExp(
    r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+@[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?(?:\.[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?)+$",
  );
  static final RegExp _integerPattern = RegExp(r'^[+-]?\d+$');
  static final RegExp _decimalPattern = RegExp(r'^[+-]?(?:\d+\.?\d*|\.\d+)$');
  static final RegExp _isoDatePattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final RegExp _hexColorPattern = RegExp(
    r'^#?(?:[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})$',
  );

  /// Rejects `null`, empty, or whitespace-only text.
  static ValidationResult requiredValidator(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationResult.invalid(ValidationErrorCode.required);
    }
    if (value.trim().isEmpty) {
      return const ValidationResult.invalid(ValidationErrorCode.whitespaceOnly);
    }
    return const ValidationResult.valid();
  }

  /// Rejects non-empty strings that consist exclusively of whitespace.
  /// Allows `null` or empty `""` for optional fields.
  static ValidationResult whitespaceValidator(String? value) {
    if (value == null || value.isEmpty) {
      return const ValidationResult.valid();
    }
    if (value.trim().isEmpty) {
      return const ValidationResult.invalid(ValidationErrorCode.whitespaceOnly);
    }
    return const ValidationResult.valid();
  }

  /// Enforces a minimum character bound on trimmed text (when non-empty).
  static ValidationResult minLengthValidator(
    String? value, {
    required int minLength,
    bool isRequired = false,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return isRequired
          ? const ValidationResult.invalid(ValidationErrorCode.required)
          : const ValidationResult.valid();
    }
    if (trimmed.length < minLength) {
      return ValidationResult.invalid(
        ValidationErrorCode.minLength,
        intParam: minLength,
      );
    }
    return const ValidationResult.valid();
  }

  /// Enforces an exact character count on trimmed text.
  static ValidationResult exactLengthValidator(
    String? value, {
    required int length,
    bool isRequired = true,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return isRequired
          ? const ValidationResult.invalid(ValidationErrorCode.required)
          : const ValidationResult.valid();
    }
    if (trimmed.length < length) {
      return ValidationResult.invalid(
        ValidationErrorCode.minLength,
        intParam: length,
      );
    }
    if (trimmed.length > length) {
      return ValidationResult.invalid(
        ValidationErrorCode.maxLength,
        intParam: length,
      );
    }
    return const ValidationResult.valid();
  }

  /// Enforces an upper character bound on trimmed text.
  static ValidationResult maxLengthValidator(
    String? value, {
    required int maxLength,
  }) {
    if (value == null) return const ValidationResult.valid();
    if (value.trim().length > maxLength) {
      return ValidationResult.invalid(
        ValidationErrorCode.maxLength,
        intParam: maxLength,
      );
    }
    return const ValidationResult.valid();
  }

  /// Validates a person, business, lot, design, colour, or process name.
  /// Supports English, Gujarati Unicode, digits, punctuation, and spaces.
  static ValidationResult nameValidator(
    String? value, {
    bool isRequired = true,
    int maxLength = ValidationLimits.maxPersonNameLength,
  }) {
    if (isRequired) {
      final req = requiredValidator(value);
      if (!req.isValid) return req;
    } else if (value == null || value.trim().isEmpty) {
      return const ValidationResult.valid();
    }

    final trimmed = value!.trim();
    if (trimmed.length > maxLength) {
      return ValidationResult.invalid(
        ValidationErrorCode.maxLength,
        intParam: maxLength,
      );
    }
    return const ValidationResult.valid();
  }

  /// Normalizes formatting characters (` `, `-`, `(`, `)`) for validation
  /// inspection only; callers should preserve the user's trimmed text.
  static String normalizeMobileForValidation(String raw) {
    return raw.trim().replaceAll(RegExp(r'[\s\-()]'), '');
  }

  /// Validates Indian mobile numbers (10 digits starting with 6–9, with or
  /// without explicit `+91`) and optional country-code-aware international
  /// E.164 numbers (`+<country><subscriber>`, 7–15 digits).
  ///
  /// - Does NOT silently truncate or prepend `+91`.
  /// - Does NOT claim OTP or ownership verification (offline-first).
  static ValidationResult mobileNumberValidator(
    String? value, {
    bool isRequired = false,
    bool allowInternational = true,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      if (isRequired) {
        return const ValidationResult.invalid(
          ValidationErrorCode.mobileRequired,
        );
      }
      return const ValidationResult.valid();
    }

    // Reject letters, symbols, or unsupported punctuation immediately.
    if (!_mobileAllowedChars.hasMatch(trimmed)) {
      return const ValidationResult.invalid(
        ValidationErrorCode.mobileInvalidChars,
      );
    }

    final normalized = normalizeMobileForValidation(trimmed);
    if (normalized.isEmpty) {
      return isRequired
          ? const ValidationResult.invalid(ValidationErrorCode.mobileRequired)
          : const ValidationResult.valid();
    }

    // '+' is only valid as a single leading character.
    final plusCount = '+'.allMatches(normalized).length;
    if (plusCount > 1 || (plusCount == 1 && !normalized.startsWith('+'))) {
      return const ValidationResult.invalid(
        ValidationErrorCode.mobileInvalidChars,
      );
    }

    if (normalized.startsWith('+')) {
      final digits = normalized.substring(1);
      if (digits.isEmpty || !RegExp(r'^\d+$').hasMatch(digits)) {
        return const ValidationResult.invalid(
          ValidationErrorCode.mobileInvalidChars,
        );
      }

      // Explicit Indian country code +91 -> enforce strict 10-digit Indian mobile rule
      if (digits.startsWith('91')) {
        final subscriber = digits.substring(2);
        if (!_indianTenDigits.hasMatch(subscriber)) {
          return const ValidationResult.invalid(
            ValidationErrorCode.mobileInvalidIndian,
          );
        }
        return const ValidationResult.valid();
      }

      if (!allowInternational) {
        return const ValidationResult.invalid(
          ValidationErrorCode.mobileInvalidIndian,
        );
      }

      // Country-code-aware international E.164 validation (7–15 digits, non-zero CC)
      if (!_e164Digits.hasMatch(digits)) {
        return const ValidationResult.invalid(
          ValidationErrorCode.mobileInvalidInternational,
        );
      }
      return const ValidationResult.valid();
    }

    // Local Indian number (no country code prefix): strictly 10 digits starting with 6–9
    if (!_indianTenDigits.hasMatch(normalized)) {
      return const ValidationResult.invalid(
        ValidationErrorCode.mobileInvalidIndian,
      );
    }
    return const ValidationResult.valid();
  }

  /// Validates an email address (optional by default).
  static ValidationResult emailValidator(
    String? value, {
    bool isRequired = false,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return isRequired
          ? const ValidationResult.invalid(ValidationErrorCode.required)
          : const ValidationResult.valid();
    }
    if (trimmed.length > 254 ||
        trimmed.contains('..') ||
        !_emailPattern.hasMatch(trimmed)) {
      return const ValidationResult.invalid(ValidationErrorCode.invalidEmail);
    }
    return const ValidationResult.valid();
  }

  /// Generic finite numeric validation (rejects NaN, Infinity, scientific notation).
  static ValidationResult numericValidator(
    String? value, {
    bool isRequired = true,
    bool allowNegative = true,
    bool allowDecimal = true,
    int? maxDecimalPlaces,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return isRequired
          ? const ValidationResult.invalid(ValidationErrorCode.required)
          : const ValidationResult.valid();
    }

    if (trimmed.toLowerCase() == 'nan' ||
        trimmed.toLowerCase().contains('infinity') ||
        trimmed.toLowerCase().contains('e')) {
      return const ValidationResult.invalid(ValidationErrorCode.invalidNumber);
    }

    final pattern = allowDecimal ? _decimalPattern : _integerPattern;
    if (!pattern.hasMatch(trimmed)) {
      return ValidationResult.invalid(
        allowDecimal
            ? ValidationErrorCode.invalidDecimal
            : ValidationErrorCode.invalidInteger,
      );
    }

    if (!allowNegative && trimmed.startsWith('-')) {
      return const ValidationResult.invalid(
        ValidationErrorCode.negativeNotAllowed,
      );
    }

    if (allowDecimal && maxDecimalPlaces != null && trimmed.contains('.')) {
      final frac = trimmed.split('.')[1];
      if (frac.length > maxDecimalPlaces) {
        return ValidationResult.invalid(
          ValidationErrorCode.tooManyDecimals,
          maxDecimals: maxDecimalPlaces,
        );
      }
    }

    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed.isNaN || parsed.isInfinite) {
      return const ValidationResult.invalid(ValidationErrorCode.invalidNumber);
    }

    return const ValidationResult.valid();
  }

  /// Strict integer validator with optional bounds.
  static ValidationResult integerValidator(
    String? value, {
    bool isRequired = true,
    int? min,
    int? max,
  }) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return isRequired
          ? const ValidationResult.invalid(ValidationErrorCode.required)
          : const ValidationResult.valid();
    }

    if (!_integerPattern.hasMatch(trimmed)) {
      return const ValidationResult.invalid(ValidationErrorCode.invalidInteger);
    }

    final big = BigInt.tryParse(trimmed);
    if (big == null) {
      return const ValidationResult.invalid(ValidationErrorCode.invalidInteger);
    }
    if (big < BigInt.zero && (min != null && min >= 0)) {
      return const ValidationResult.invalid(
        ValidationErrorCode.negativeNotAllowed,
      );
    }
    if (min != null && big < BigInt.from(min)) {
      return min == 1
          ? const ValidationResult.invalid(ValidationErrorCode.mustBePositive)
          : const ValidationResult.invalid(ValidationErrorCode.valueOutOfRange);
    }
    if (max != null && big > BigInt.from(max)) {
      return ValidationResult.invalid(
        ValidationErrorCode.valueTooLarge,
        intParam: max,
      );
    }
    if (!big.isValidInt) {
      return const ValidationResult.invalid(ValidationErrorCode.valueTooLarge);
    }
    return const ValidationResult.valid();
  }

  /// Decimal validator with exact decimal-place enforcement (no silent rounding).
  static ValidationResult decimalValidator(
    String? value, {
    bool isRequired = true,
    bool allowNegative = false,
    int maxDecimalPlaces = 2,
  }) {
    return numericValidator(
      value,
      isRequired: isRequired,
      allowNegative: allowNegative,
      allowDecimal: true,
      maxDecimalPlaces: maxDecimalPlaces,
    );
  }

  /// Validates strictly positive numbers (`> 0`).
  static ValidationResult positiveNumberValidator(
    String? value, {
    bool isRequired = true,
    int maxDecimalPlaces = 2,
  }) {
    final base = decimalValidator(
      value,
      isRequired: isRequired,
      allowNegative: false,
      maxDecimalPlaces: maxDecimalPlaces,
    );
    if (!base.isValid) return base;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return const ValidationResult.valid();
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed <= 0) {
      return const ValidationResult.invalid(ValidationErrorCode.mustBePositive);
    }
    return const ValidationResult.valid();
  }

  /// Exact integer parser + validator for garment piece quantities.
  ///
  /// Uses `BigInt` before narrowing to `int` so pasting 20+ digits never
  /// silently becomes `0` or throws `FormatException`.
  static ({int? value, ValidationResult validation}) parseQuantityExact(
    String? raw, {
    bool isRequired = true,
    bool allowZero = false,
    int max = ValidationLimits.maxQuantity,
  }) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) {
      if (!isRequired) {
        return (
          value: allowZero ? 0 : null,
          validation: const ValidationResult.valid(),
        );
      }
      return (
        value: null,
        validation: const ValidationResult.invalid(
          ValidationErrorCode.required,
        ),
      );
    }

    if (trimmed.startsWith('-')) {
      return (
        value: null,
        validation: const ValidationResult.invalid(
          ValidationErrorCode.negativeNotAllowed,
        ),
      );
    }

    if (!_integerPattern.hasMatch(trimmed)) {
      return (
        value: null,
        validation: const ValidationResult.invalid(
          ValidationErrorCode.invalidInteger,
        ),
      );
    }

    final big = BigInt.tryParse(trimmed);
    if (big == null) {
      return (
        value: null,
        validation: const ValidationResult.invalid(
          ValidationErrorCode.invalidInteger,
        ),
      );
    }

    if (allowZero) {
      if (big < BigInt.zero) {
        return (
          value: null,
          validation: const ValidationResult.invalid(
            ValidationErrorCode.quantityNonNegative,
          ),
        );
      }
    } else if (big <= BigInt.zero) {
      return (
        value: null,
        validation: const ValidationResult.invalid(
          ValidationErrorCode.quantityMustBePositive,
        ),
      );
    }

    if (big > BigInt.from(max)) {
      return (
        value: null,
        validation: ValidationResult.invalid(
          max < ValidationLimits.maxQuantity
              ? ValidationErrorCode.quantityExceedsMax
              : ValidationErrorCode.valueTooLarge,
          intParam: max,
        ),
      );
    }

    return (value: big.toInt(), validation: const ValidationResult.valid());
  }

  /// Strictly positive piece quantity validator (`1..max`).
  static ValidationResult quantityValidator(
    String? value, {
    bool isRequired = true,
    int max = ValidationLimits.maxQuantity,
  }) {
    return parseQuantityExact(
      value,
      isRequired: isRequired,
      allowZero: false,
      max: max,
    ).validation;
  }

  /// Non-negative piece quantity validator (`0..max`) for settlement breakdown fields.
  static ValidationResult nonNegativeQuantityValidator(
    String? value, {
    bool isRequired = false,
    int max = ValidationLimits.maxQuantity,
  }) {
    return parseQuantityExact(
      value,
      isRequired: isRequired,
      allowZero: true,
      max: max,
    ).validation;
  }

  /// Exact string-to-paise parser with ZERO floating-point arithmetic.
  ///
  /// - Rejects `NaN`, `Infinity`, scientific notation (`1e5`), negative values.
  /// - Rejects more than 2 decimal places (never silently rounds `10.999`).
  /// - Enforces `ValidationLimits.maxAmountPaise` via `BigInt` (zero overflow).
  static ({int? paise, ValidationResult validation}) parseRupeesToPaiseExact(
    String? raw, {
    bool isRequired = true,
    bool allowZero = false,
    int maxPaise = ValidationLimits.maxAmountPaise,
  }) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) {
      if (!isRequired) {
        return (
          paise: allowZero ? 0 : null,
          validation: const ValidationResult.valid(),
        );
      }
      return (
        paise: null,
        validation: const ValidationResult.invalid(
          ValidationErrorCode.required,
        ),
      );
    }

    if (trimmed.startsWith('-')) {
      return (
        paise: null,
        validation: const ValidationResult.invalid(
          ValidationErrorCode.negativeNotAllowed,
        ),
      );
    }

    // Strict decimal syntax: no scientific notation, letters, commas, or extra dots
    final match = RegExp(r'^\+?(\d+)?(?:\.(\d*))?$').firstMatch(trimmed);
    if (match == null) {
      return (
        paise: null,
        validation: const ValidationResult.invalid(
          ValidationErrorCode.invalidDecimal,
        ),
      );
    }

    final wholePart = match.group(1) ?? '';
    final fracPart = match.group(2);
    if (wholePart.isEmpty && (fracPart == null || fracPart.isEmpty)) {
      return (
        paise: null,
        validation: const ValidationResult.invalid(
          ValidationErrorCode.invalidDecimal,
        ),
      );
    }

    if (fracPart != null && fracPart.length > 2) {
      return (
        paise: null,
        validation: const ValidationResult.invalid(
          ValidationErrorCode.tooManyDecimals,
          maxDecimals: 2,
        ),
      );
    }

    final wholeBig = wholePart.isEmpty ? BigInt.zero : BigInt.parse(wholePart);
    final fracPadded = (fracPart ?? '').padRight(2, '0');
    final fracBig = BigInt.parse(fracPadded);
    final totalPaise = wholeBig * BigInt.from(100) + fracBig;

    if (!allowZero && totalPaise <= BigInt.zero) {
      return (
        paise: null,
        validation: const ValidationResult.invalid(
          ValidationErrorCode.amountMustBePositive,
        ),
      );
    }

    if (totalPaise > BigInt.from(maxPaise)) {
      return (
        paise: null,
        validation: const ValidationResult.invalid(
          ValidationErrorCode.valueTooLarge,
        ),
      );
    }

    return (
      paise: totalPaise.toInt(),
      validation: const ValidationResult.valid(),
    );
  }

  /// Validates strictly positive monetary amounts (`> 0`, <= 2 decimals) such as
  /// worker payments and ledger adjustments.
  static ValidationResult amountValidator(
    String? value, {
    bool isRequired = true,
    int maxPaise = ValidationLimits.maxAmountPaise,
  }) {
    return parseRupeesToPaiseExact(
      value,
      isRequired: isRequired,
      allowZero: false,
      maxPaise: maxPaise,
    ).validation;
  }

  /// Validates non-negative monetary values (`>= 0`, <= 2 decimals) such as
  /// colour unit prices and worker per-piece rates.
  static ValidationResult nonNegativeAmountValidator(
    String? value, {
    bool isRequired = true,
    int maxPaise = ValidationLimits.maxAmountPaise,
  }) {
    return parseRupeesToPaiseExact(
      value,
      isRequired: isRequired,
      allowZero: true,
      maxPaise: maxPaise,
    ).validation;
  }

  /// Validates percentages in `[0, 100]` with configurable decimal precision.
  static ValidationResult percentageValidator(
    String? value, {
    bool isRequired = true,
    int maxDecimalPlaces = 2,
  }) {
    final base = decimalValidator(
      value,
      isRequired: isRequired,
      allowNegative: false,
      maxDecimalPlaces: maxDecimalPlaces,
    );
    if (!base.isValid) return base;
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return const ValidationResult.valid();
    final parsed = double.tryParse(trimmed);
    if (parsed == null || parsed < 0 || parsed > 100) {
      return const ValidationResult.invalid(
        ValidationErrorCode.invalidPercentage,
      );
    }
    return const ValidationResult.valid();
  }

  /// Validates UTC epoch milliseconds fall within StitchFlow's supported range (2000–2100).
  static ValidationResult dateValidator(
    int? epochUtcMillis, {
    bool isRequired = true,
  }) {
    if (epochUtcMillis == null) {
      return isRequired
          ? const ValidationResult.invalid(ValidationErrorCode.invalidDate)
          : const ValidationResult.valid();
    }
    if (epochUtcMillis < ValidationLimits.minValidEpochMillis ||
        epochUtcMillis > ValidationLimits.maxValidEpochMillis) {
      return const ValidationResult.invalid(ValidationErrorCode.invalidDate);
    }
    return const ValidationResult.valid();
  }

  /// Validates that an ordered date range satisfies `endUtcMillis >= startUtcMillis`.
  static ValidationResult dateRangeValidator({
    int? startUtcMillis,
    int? endUtcMillis,
  }) {
    if (startUtcMillis != null) {
      final startRes = dateValidator(startUtcMillis);
      if (!startRes.isValid) return startRes;
    }
    if (endUtcMillis != null) {
      final endRes = dateValidator(endUtcMillis);
      if (!endRes.isValid) return endRes;
    }
    if (startUtcMillis != null &&
        endUtcMillis != null &&
        endUtcMillis < startUtcMillis) {
      return const ValidationResult.invalid(ValidationErrorCode.dateRangeOrder);
    }
    return const ValidationResult.valid();
  }

  /// Validates `YYYY-MM-DD` ISO business date ordering (`endIso >= startIso`).
  static ValidationResult isoDateRangeValidator({
    required String startIso,
    String? endIso,
  }) {
    if (!_isValidIsoCalendarDate(startIso)) {
      return const ValidationResult.invalid(ValidationErrorCode.invalidDate);
    }
    if (endIso != null && endIso.trim().isNotEmpty) {
      final cleanEnd = endIso.trim();
      if (!_isValidIsoCalendarDate(cleanEnd)) {
        return const ValidationResult.invalid(ValidationErrorCode.invalidDate);
      }
      if (cleanEnd.compareTo(startIso.trim()) < 0) {
        return const ValidationResult.invalid(
          ValidationErrorCode.dateRangeOrder,
        );
      }
    }
    return const ValidationResult.valid();
  }

  /// Case-insensitive trimmed duplicate detector against an existing value list.
  static ValidationResult duplicateValidator(
    String? value, {
    required Iterable<String> existingValues,
    String? excludeValue,
  }) {
    final normalized = value?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty) return const ValidationResult.valid();
    final excluded = excludeValue?.trim().toLowerCase();
    for (final item in existingValues) {
      final normItem = item.trim().toLowerCase();
      if (excluded != null && normItem == excluded) continue;
      if (normItem == normalized) {
        return const ValidationResult.invalid(
          ValidationErrorCode.duplicateValue,
        );
      }
    }
    return const ValidationResult.valid();
  }

  /// Optional CSS hex colour validator (`#RRGGBB` or `#AARRGGBB`).
  static ValidationResult hexColorValidator(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return const ValidationResult.valid();
    if (!_hexColorPattern.hasMatch(trimmed)) {
      return const ValidationResult.invalid(
        ValidationErrorCode.invalidHexColor,
      );
    }
    return const ValidationResult.valid();
  }

  /// Validates 4- or 6-digit numeric App PIN format.
  static ValidationResult pinValidator(String? pin, {int? expectedLength}) {
    if (pin == null ||
        !PinHasher.isValidPinFormat(pin, expectedLength: expectedLength)) {
      return const ValidationResult.invalid(ValidationErrorCode.invalidPin);
    }
    return const ValidationResult.valid();
  }

  /// Validates 8-character Crockford offline Recovery Key format.
  static ValidationResult recoveryKeyValidator(String? input) {
    final trimmed = input?.trim() ?? '';
    if (trimmed.isEmpty) {
      return const ValidationResult.invalid(
        ValidationErrorCode.recoveryKeyRequired,
      );
    }
    if (!PinHasher.isValidRecoveryKeyFormat(trimmed)) {
      return const ValidationResult.invalid(
        ValidationErrorCode.invalidRecoveryKey,
      );
    }
    return const ValidationResult.valid();
  }

  static bool _isValidIsoCalendarDate(String raw) {
    final clean = raw.trim();
    if (!_isoDatePattern.hasMatch(clean)) return false;
    final parts = clean.split('-');
    final y = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final d = int.parse(parts[2]);
    if (m < 1 || m > 12 || d < 1 || d > 31) return false;
    final dt = DateTime.utc(y, m, d);
    return dt.year == y && dt.month == m && dt.day == d;
  }
}
