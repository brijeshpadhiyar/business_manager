/// Centralized limits and typed validation error codes used across UI, BLoC,
/// and Repository layers without introducing external dependencies.
abstract final class ValidationLimits {
  /// Short identifiers & names (lot number, design name, colour name, process name, reference no).
  static const int maxShortNameLength = 100;

  /// Person & business names (worker name, owner name, business EN/GU names).
  static const int maxPersonNameLength = 120;

  /// Multi-line addresses (worker address, business address).
  static const int maxAddressLength = 300;

  /// Free-text descriptions, notes, and audit/settlement/reversal reasons.
  static const int maxNotesLength = 500;

  /// Search input limit for filter bars.
  static const int maxSearchLength = 120;

  /// Safe piece quantity ceiling (1 Crore pcs) preventing 64-bit multiplication overflow.
  static const int maxQuantity = 10000000;

  /// Safe monetary ceiling in integer paise (₹99,99,99,999.99 ≈ ₹100 Crore).
  static const int maxAmountPaise = 99999999999;

  /// Earliest supported business transaction epoch (2000-01-01T00:00:00Z).
  static const int minValidEpochMillis = 946684800000;

  /// Latest supported business transaction epoch (2100-01-01T00:00:00Z).
  static const int maxValidEpochMillis = 4102444800000;
}

/// Machine-readable validation error codes mapped to localized English and
/// Gujarati strings by `ValidationLocalizer`.
enum ValidationErrorCode {
  required,
  whitespaceOnly,
  maxLength,
  minLength,
  invalidName,
  mobileRequired,
  mobileInvalidIndian,
  mobileInvalidChars,
  mobileInvalidInternational,
  invalidEmail,
  invalidNumber,
  invalidInteger,
  invalidDecimal,
  tooManyDecimals,
  negativeNotAllowed,
  mustBePositive,
  valueTooLarge,
  valueOutOfRange,
  quantityMustBePositive,
  quantityNonNegative,
  quantityExceedsMax,
  amountMustBePositive,
  amountNonNegative,
  invalidPercentage,
  invalidDate,
  dateRangeOrder,
  duplicateValue,
  invalidHexColor,
  invalidPin,
  recoveryKeyRequired,
  invalidRecoveryKey,
}

/// Pure Dart validation outcome returned by `AppValidators`.
final class ValidationResult {
  const ValidationResult.valid()
    : code = null,
      intParam = null,
      maxDecimals = null;

  const ValidationResult.invalid(
    ValidationErrorCode this.code, {
    this.intParam,
    this.maxDecimals,
  });

  final ValidationErrorCode? code;
  final int? intParam;
  final int? maxDecimals;

  bool get isValid => code == null;
}
