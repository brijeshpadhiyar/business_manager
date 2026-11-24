import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/validation/validation_error.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Translates [ValidationResult] and [DomainValidationException] codes into
/// localized English & Gujarati user-facing error messages with zero hardcoded
/// UI validation strings.
abstract final class ValidationLocalizer {
  /// Converts a [ValidationResult] into a localized message (or `null` if valid).
  static String? localize(AppLocalizations l10n, ValidationResult result) {
    final code = result.code;
    if (code == null) return null;

    return switch (code) {
      ValidationErrorCode.required => l10n.validationRequired,
      ValidationErrorCode.whitespaceOnly => l10n.validationWhitespaceOnly,
      ValidationErrorCode.maxLength => l10n.validationMaxLength(
        result.intParam ?? ValidationLimits.maxNotesLength,
      ),
      ValidationErrorCode.minLength => l10n.validationMinLength(
        result.intParam ?? 1,
      ),
      ValidationErrorCode.invalidName => l10n.validationRequired,
      ValidationErrorCode.mobileRequired => l10n.validationMobileRequired,
      ValidationErrorCode.mobileInvalidIndian =>
        l10n.validationMobileInvalidIndian,
      ValidationErrorCode.mobileInvalidChars =>
        l10n.validationMobileInvalidChars,
      ValidationErrorCode.mobileInvalidInternational =>
        l10n.validationMobileInvalidInternational,
      ValidationErrorCode.invalidEmail => l10n.validationEmailInvalid,
      ValidationErrorCode.invalidNumber => l10n.validationInvalidNumber,
      ValidationErrorCode.invalidInteger => l10n.validationInvalidInteger,
      ValidationErrorCode.invalidDecimal => l10n.validationInvalidDecimal,
      ValidationErrorCode.tooManyDecimals => l10n.validationTooManyDecimals(
        result.maxDecimals ?? 2,
      ),
      ValidationErrorCode.negativeNotAllowed =>
        l10n.validationNegativeNotAllowed,
      ValidationErrorCode.mustBePositive => l10n.validationPositiveNumber,
      ValidationErrorCode.valueTooLarge => l10n.validationValueTooLarge,
      ValidationErrorCode.valueOutOfRange => l10n.validationInvalidNumber,
      ValidationErrorCode.quantityMustBePositive => l10n.validationPositiveInt,
      ValidationErrorCode.quantityNonNegative =>
        l10n.validationNonNegativeInt,
      ValidationErrorCode.quantityExceedsMax =>
        l10n.validationQuantityExceedsMax(result.intParam ?? 0),
      ValidationErrorCode.amountMustBePositive =>
        l10n.validationPositiveAmount,
      ValidationErrorCode.amountNonNegative => l10n.validationValidPrice,
      ValidationErrorCode.invalidPercentage => l10n.validationInvalidPercentage,
      ValidationErrorCode.invalidDate => l10n.validationInvalidDate,
      ValidationErrorCode.dateRangeOrder => l10n.validationDateRangeOrder,
      ValidationErrorCode.duplicateValue => l10n.validationDuplicateValue,
      ValidationErrorCode.invalidHexColor => l10n.validationInvalidHexColor,
      ValidationErrorCode.invalidPin => l10n.validationInvalidPin,
      ValidationErrorCode.recoveryKeyRequired =>
        l10n.validationRecoveryKeyRequired,
      ValidationErrorCode.invalidRecoveryKey =>
        l10n.securityRecoveryKeyInvalidError,
    };
  }

  /// Convenience adapter turning any pure [AppValidators] function into a
  /// Flutter [FormFieldValidator<String>].
  static FormFieldValidator<String> wrap(
    AppLocalizations l10n,
    ValidationResult Function(String? value) validator,
  ) {
    return (value) => localize(l10n, validator(value));
  }

  /// Maps repository/domain [DomainValidationException] to a localized string.
  static String localizeDomainException(
    AppLocalizations l10n,
    DomainValidationException exception,
  ) {
    return localizeDomainCode(
      l10n,
      exception.code,
      fallback: exception.message,
    );
  }

  /// Maps machine-readable repository & BLoC error codes to localized strings.
  static String localizeDomainCode(
    AppLocalizations l10n,
    String code, {
    String? fallback,
  }) {
    return switch (code) {
      // Workers & Business Profile
      'worker_name_required' ||
      'business_name_required' ||
      'process_name_required' => l10n.validationRequired,
      'mobile_invalid_indian' => l10n.validationMobileInvalidIndian,
      'mobile_invalid_chars' => l10n.validationMobileInvalidChars,
      'mobile_invalid_international' =>
        l10n.validationMobileInvalidInternational,
      'text_too_long' => l10n.validationTextTooLong,
      'worker_not_found' => l10n.validationWorkerNotFound,
      'worker_inactive' ||
      'inactive_worker' => l10n.assignmentsInactiveWorkerError,
      'process_inactive' ||
      'inactive_process' => l10n.assignmentsInactiveProcessError,
      'worker_not_assigned' => l10n.validationWorkerNotAssigned,
      'duplicate_assignment' => l10n.assignmentsDuplicateError,
      'duplicate_process_name' => l10n.processDuplicateNameError,

      // Lots / Designs / Colours
      'duplicate_lot_number' => l10n.lotDuplicateError,
      'duplicate_design_name' => l10n.designDuplicateError,
      'duplicate_colour_name' => l10n.colourDuplicateError,
      'quantity_below_committed_stock' =>
        l10n.validationQuantityBelowCommittedStock,
      'invalid_hex_color' => l10n.validationInvalidHexColor,
      'colour_not_found' ||
      'design_not_found' ||
      'lot_not_found' => l10n.validationRecordNotFound,

      // Rates
      'rate_overlap' => l10n.ratesOverlapError,
      'rate_multiple_open_ended' => l10n.ratesMultipleOpenEndedError,
      'rate_to_before_from' => l10n.ratesToBeforeFromError,
      'rate_locked_by_history' => l10n.ratesLockedByHistoryError,
      'rate_negative' || 'invalid_rate' => l10n.validationValidPrice,
      'rate_invalid_from_date' ||
      'rate_invalid_to_date' ||
      'invalid_date' => l10n.validationInvalidDate,
      'rate_too_large' ||
      'amount_too_large' ||
      'quantity_too_large' => l10n.validationValueTooLarge,
      'rate_missing' => l10n.stockRateMissingWarning,
      'rate_conflict' => l10n.stockRateConflictWarning,
      'override_reason_required' ||
      'rate_override_reason_required' => l10n.validationOverrideReasonRequired,

      // Process Routing & Handovers (V1.3)
      'exceeds_dispatched_quantity' => l10n.validationExceedsDispatched,
      'exceeds_held_quantity' => l10n.validationExceedsHeld,
      'unaccounted_quantity_remaining' => l10n.validationUnaccountedRemaining,
      'overpayment_not_allowed' => l10n.validationOverpaymentNotAllowed,
      'duplicate_colour_master' => l10n.colourDuplicateError,
      'invalid_charge_amount' => l10n.validationPositiveAmount,

      // Stock Movements & Reversals
      'insufficient_good_stock' => l10n.stockInsufficientGoodError,
      'invalid_quantity' => l10n.stockInvalidQtyError,
      'exceeds_pending_quantity' => l10n.stockSettlementTotalExceedsError,
      'settlement_empty' => l10n.stockSettlementEmptyError,
      'reason_required' => l10n.stockSettlementReasonRequiredError,
      'exceeds_damaged_stock' => l10n.stockRepairExceedsDamagedError,
      'parent_issue_inactive' => l10n.validationParentIssueInactive,
      'downstream_stock_dependency' ||
      'downstream_damaged_dependency' ||
      'downstream_parent_dependency' => l10n.stockReverseBlockedDownstream,
      'issue_has_active_settlements' => l10n.stockReverseBlockedChildren,
      'already_reversed' => l10n.validationAlreadyReversed,
      'cannot_reverse_reversal' => l10n.validationCannotReverseReversal,

      // Payments & Ledger Adjustments
      'invalid_amount' => l10n.validationPositiveAmount,
      'invalid_payment_type' ||
      'invalid_adjustment_type' => l10n.errorUnexpected,
      'payment_not_found' ||
      'adjustment_not_found' ||
      'movement_not_found' => l10n.validationRecordNotFound,

      // Date Ranges & Security
      'invalid_date_range' => l10n.validationDateRangeOrder,
      'invalid_pin' => l10n.validationInvalidPin,
      'invalid_recovery_key' => l10n.securityRecoveryKeyInvalidError,

      _ => fallback ?? l10n.errorUnexpected,
    };
  }
}
