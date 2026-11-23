import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/l10n/generated/app_localizations_en.dart';
import 'package:business_manager/l10n/generated/app_localizations_gu.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l10nEn = AppLocalizationsEn();
  final l10nGu = AppLocalizationsGu();

  group('Required, Whitespace & Name Validators', () {
    test('rejects null, empty, and whitespace-only values', () {
      expect(
        AppValidators.requiredValidator(null).code,
        ValidationErrorCode.required,
      );
      expect(
        AppValidators.requiredValidator('').code,
        ValidationErrorCode.required,
      );
      expect(
        AppValidators.requiredValidator('   \t\n ').code,
        ValidationErrorCode.whitespaceOnly,
      );
      expect(AppValidators.requiredValidator('Cutting').isValid, isTrue);
      expect(AppValidators.requiredValidator('કટિંગ').isValid, isTrue);
    });

    test('whitespaceValidator allows empty optional values but rejects spaces-only', () {
      expect(AppValidators.whitespaceValidator(null).isValid, isTrue);
      expect(AppValidators.whitespaceValidator('').isValid, isTrue);
      expect(
        AppValidators.whitespaceValidator('   ').code,
        ValidationErrorCode.whitespaceOnly,
      );
      expect(AppValidators.whitespaceValidator(' valid ').isValid, isTrue);
    });

    test('nameValidator enforces required and maxLength cleanly', () {
      expect(
        AppValidators.nameValidator('   ').code,
        ValidationErrorCode.whitespaceOnly,
      );
      expect(
        AppValidators.nameValidator('a' * 121, maxLength: 120).code,
        ValidationErrorCode.maxLength,
      );
      expect(
        AppValidators.nameValidator('Hasmukh Bhai / હસમુખ ભાઈ').isValid,
        isTrue,
      );
      expect(
        AppValidators.nameValidator('', isRequired: false).isValid,
        isTrue,
      );
    });
  });

  group('Indian & International Mobile Number Validation', () {
    test('accepts valid 10-digit Indian mobile numbers and formatting', () {
      for (final valid in const [
        '9876543210',
        '6000000001',
        '7123456789',
        '8989898989',
        ' 98765 43210 ',
        '98765-43210',
        '(98765) 43210',
        '+91 98765 43210',
        '+919876543210',
        '+91-98765-43210',
      ]) {
        expect(
          AppValidators.mobileNumberValidator(valid).isValid,
          isTrue,
          reason: 'Expected "$valid" to be valid',
        );
      }
    });

    test('accepts valid country-code-aware international E.164 numbers', () {
      for (final valid in const [
        '+1 415 555 2671',
        '+44 20 7946 0958',
        '+971 50 123 4567',
      ]) {
        expect(
          AppValidators.mobileNumberValidator(valid).isValid,
          isTrue,
          reason: 'Expected international "$valid" to be valid',
        );
      }
    });

    test('rejects incomplete, invalid-prefix, letters, and unsupported chars', () {
      expect(
        AppValidators.mobileNumberValidator('', isRequired: true).code,
        ValidationErrorCode.mobileRequired,
      );
      expect(
        AppValidators.mobileNumberValidator('', isRequired: false).isValid,
        isTrue,
      );

      // Invalid characters / letters
      for (final badChars in const [
        '98765abcde',
        '98765@4321',
        '98765*4321',
        '987+6543210',
        '++919876543210',
      ]) {
        expect(
          AppValidators.mobileNumberValidator(badChars).code,
          ValidationErrorCode.mobileInvalidChars,
          reason: 'Expected "$badChars" to fail invalid chars',
        );
      }

      // Invalid Indian 10-digit numbers
      for (final badIndian in const [
        '987654321', // 9 digits
        '98765432101', // 11 digits
        '09876543210', // leading 0
        '1234567890', // starts with 1
        '5555555555', // starts with 5
        '+91 5123456789', // +91 with invalid starting digit
        '+91 98765', // +91 incomplete
      ]) {
        expect(
          AppValidators.mobileNumberValidator(badIndian).code,
          ValidationErrorCode.mobileInvalidIndian,
          reason: 'Expected "$badIndian" to fail Indian mobile validation',
        );
      }

      // Invalid international E.164
      expect(
        AppValidators.mobileNumberValidator('+1 123').code,
        ValidationErrorCode.mobileInvalidInternational,
      );
      expect(
        AppValidators.mobileNumberValidator('+0123456789').code,
        ValidationErrorCode.mobileInvalidInternational,
      );
      expect(
        AppValidators.mobileNumberValidator('+1234567890123456').code,
        ValidationErrorCode.mobileInvalidInternational,
      );
    });
  });

  group('Email & Percentage Validators', () {
    test('validates email addresses accurately', () {
      expect(AppValidators.emailValidator('').isValid, isTrue);
      expect(
        AppValidators.emailValidator('', isRequired: true).code,
        ValidationErrorCode.required,
      );
      expect(AppValidators.emailValidator('owner@stitchflow.in').isValid, isTrue);
      expect(
        AppValidators.emailValidator('invalid-email').code,
        ValidationErrorCode.invalidEmail,
      );
      expect(
        AppValidators.emailValidator('a..b@domain.com').code,
        ValidationErrorCode.invalidEmail,
      );
      expect(
        AppValidators.emailValidator('user@localhost').code,
        ValidationErrorCode.invalidEmail,
      );
    });

    test('validates percentages between 0 and 100', () {
      expect(AppValidators.percentageValidator('0').isValid, isTrue);
      expect(AppValidators.percentageValidator('100').isValid, isTrue);
      expect(AppValidators.percentageValidator('12.5').isValid, isTrue);
      expect(
        AppValidators.percentageValidator('-1').code,
        ValidationErrorCode.negativeNotAllowed,
      );
      expect(
        AppValidators.percentageValidator('100.01').code,
        ValidationErrorCode.invalidPercentage,
      );
      expect(
        AppValidators.percentageValidator('12.345').code,
        ValidationErrorCode.tooManyDecimals,
      );
    });
  });

  group('Exact Numeric, Quantity & Financial Validation', () {
    test('quantityValidator rejects zero, negative, decimals, letters, and huge overflow', () {
      expect(AppValidators.quantityValidator('1').isValid, isTrue);
      expect(AppValidators.quantityValidator('1000').isValid, isTrue);
      expect(
        AppValidators.quantityValidator('').code,
        ValidationErrorCode.required,
      );
      expect(
        AppValidators.quantityValidator('0').code,
        ValidationErrorCode.quantityMustBePositive,
      );
      expect(
        AppValidators.quantityValidator('-5').code,
        ValidationErrorCode.negativeNotAllowed,
      );
      expect(
        AppValidators.quantityValidator('10.5').code,
        ValidationErrorCode.invalidInteger,
      );
      expect(
        AppValidators.quantityValidator('1e5').code,
        ValidationErrorCode.invalidInteger,
      );
      expect(
        AppValidators.quantityValidator('999999999999999999999999').code,
        ValidationErrorCode.valueTooLarge,
      );
      expect(
        AppValidators.quantityValidator('150', max: 100).code,
        ValidationErrorCode.quantityExceedsMax,
      );
    });

    test('parseRupeesToPaiseExact avoids float drift, rejects >2 decimals & overflow', () {
      // Exact conversion without binary float error (e.g. 19.99 * 100 = 1999)
      final p1 = AppValidators.parseRupeesToPaiseExact('19.99');
      expect(p1.validation.isValid, isTrue);
      expect(p1.paise, 1999);

      final p2 = AppValidators.parseRupeesToPaiseExact('250.5');
      expect(p2.validation.isValid, isTrue);
      expect(p2.paise, 25050);

      final p3 = AppValidators.parseRupeesToPaiseExact('.50');
      expect(p3.validation.isValid, isTrue);
      expect(p3.paise, 50);

      // Zero disallowed for positive amount, allowed for rate/price
      expect(
        AppValidators.amountValidator('0').code,
        ValidationErrorCode.amountMustBePositive,
      );
      expect(
        AppValidators.amountValidator('0.00').code,
        ValidationErrorCode.amountMustBePositive,
      );
      expect(AppValidators.nonNegativeAmountValidator('0').isValid, isTrue);

      // Negative rejected
      expect(
        AppValidators.amountValidator('-10').code,
        ValidationErrorCode.negativeNotAllowed,
      );
      expect(
        AppValidators.nonNegativeAmountValidator('-0.01').code,
        ValidationErrorCode.negativeNotAllowed,
      );

      // >2 decimals rejected (NEVER silently rounded!)
      expect(
        AppValidators.amountValidator('10.999').code,
        ValidationErrorCode.tooManyDecimals,
      );
      expect(
        AppValidators.nonNegativeAmountValidator('25.125').code,
        ValidationErrorCode.tooManyDecimals,
      );

      // NaN, Infinity, scientific notation, letters rejected
      for (final bad in const ['NaN', 'Infinity', '1e5', '1E2', '₹100', 'abc']) {
        expect(
          AppValidators.amountValidator(bad).isValid,
          isFalse,
          reason: 'Expected "$bad" to be rejected',
        );
      }

      // Huge numeric input rejected safely without FormatException
      expect(
        AppValidators.amountValidator('999999999999999999999999').code,
        ValidationErrorCode.valueTooLarge,
      );
    });
  });

  group('Date, Date Range, Duplicate & Security Validators', () {
    test('validates epoch dates and ordered date ranges', () {
      final jan1 = DateTime.utc(2026, 1, 1).millisecondsSinceEpoch;
      final jan10 = DateTime.utc(2026, 1, 10).millisecondsSinceEpoch;
      expect(
        AppValidators.dateRangeValidator(
          startUtcMillis: jan1,
          endUtcMillis: jan10,
        ).isValid,
        isTrue,
      );
      expect(
        AppValidators.dateRangeValidator(
          startUtcMillis: jan10,
          endUtcMillis: jan1,
        ).code,
        ValidationErrorCode.dateRangeOrder,
      );
      expect(
        AppValidators.isoDateRangeValidator(
          startIso: '2026-05-10',
          endIso: '2026-05-01',
        ).code,
        ValidationErrorCode.dateRangeOrder,
      );
      expect(
        AppValidators.isoDateRangeValidator(
          startIso: '2026-02-30',
        ).code,
        ValidationErrorCode.invalidDate,
      );
    });

    test('duplicateValidator checks case-insensitively with exclude support', () {
      expect(
        AppValidators.duplicateValidator(
          ' cutting ',
          existingValues: const ['Cutting', 'Stitching'],
        ).code,
        ValidationErrorCode.duplicateValue,
      );
      expect(
        AppValidators.duplicateValidator(
          'Cutting',
          existingValues: const ['Cutting', 'Stitching'],
          excludeValue: 'cutting',
        ).isValid,
        isTrue,
      );
    });

    test('pinValidator and recoveryKeyValidator enforce strict formats', () {
      expect(AppValidators.pinValidator('1234').isValid, isTrue);
      expect(AppValidators.pinValidator('123456').isValid, isTrue);
      expect(AppValidators.pinValidator('123').code, ValidationErrorCode.invalidPin);
      expect(AppValidators.pinValidator('12ab').code, ValidationErrorCode.invalidPin);
      expect(
        AppValidators.recoveryKeyValidator('   ').code,
        ValidationErrorCode.recoveryKeyRequired,
      );
      expect(
        AppValidators.recoveryKeyValidator('INVALID!').code,
        ValidationErrorCode.invalidRecoveryKey,
      );
      expect(
        AppValidators.recoveryKeyValidator('WXYZ-2345').isValid,
        isTrue,
      );
    });
  });

  group('Bilingual Localization Coverage (EN & GU)', () {
    test('every ValidationErrorCode produces non-empty distinct EN & GU messages', () {
      for (final code in ValidationErrorCode.values) {
        final res = ValidationResult.invalid(code, intParam: 100, maxDecimals: 2);
        final en = ValidationLocalizer.localize(l10nEn, res);
        final gu = ValidationLocalizer.localize(l10nGu, res);
        expect(en, isNotNull, reason: 'EN missing for $code');
        expect(gu, isNotNull, reason: 'GU missing for $code');
        expect(en!.trim(), isNotEmpty, reason: 'EN empty for $code');
        expect(gu!.trim(), isNotEmpty, reason: 'GU empty for $code');
      }
    });

    test('mobile error messages match required English & Gujarati phrasing', () {
      expect(
        ValidationLocalizer.localize(
          l10nEn,
          const ValidationResult.invalid(ValidationErrorCode.mobileRequired),
        ),
        'Enter mobile number.',
      );
      expect(
        ValidationLocalizer.localize(
          l10nEn,
          const ValidationResult.invalid(ValidationErrorCode.mobileInvalidIndian),
        ),
        'Enter a valid 10-digit mobile number.',
      );
      expect(
        ValidationLocalizer.localize(
          l10nEn,
          const ValidationResult.invalid(ValidationErrorCode.mobileInvalidChars),
        ),
        'Mobile number contains invalid characters.',
      );

      expect(
        ValidationLocalizer.localize(
          l10nGu,
          const ValidationResult.invalid(ValidationErrorCode.mobileRequired),
        ),
        'મોબાઇલ નંબર દાખલ કરો.',
      );
      expect(
        ValidationLocalizer.localize(
          l10nGu,
          const ValidationResult.invalid(ValidationErrorCode.mobileInvalidIndian),
        ),
        'માન્ય 10 અંકનો મોબાઇલ નંબર દાખલ કરો.',
      );
      expect(
        ValidationLocalizer.localize(
          l10nGu,
          const ValidationResult.invalid(ValidationErrorCode.mobileInvalidChars),
        ),
        'મોબાઇલ નંબરમાં અમાન્ય અક્ષરો છે.',
      );
    });

    test('DomainValidationException codes localize cleanly in EN & GU', () {
      const codes = [
        'worker_name_required',
        'mobile_invalid_indian',
        'mobile_invalid_chars',
        'mobile_invalid_international',
        'quantity_below_committed_stock',
        'insufficient_good_stock',
        'exceeds_pending_quantity',
        'exceeds_damaged_stock',
        'invalid_amount',
        'amount_too_large',
        'rate_locked_by_history',
        'invalid_date_range',
      ];
      for (final c in codes) {
        final ex = DomainValidationException(c, 'fallback');
        final en = ValidationLocalizer.localizeDomainException(l10nEn, ex);
        final gu = ValidationLocalizer.localizeDomainException(l10nGu, ex);
        expect(en, isNot('fallback'), reason: 'EN should map $c');
        expect(gu, isNot('fallback'), reason: 'GU should map $c');
      }
    });
  });
}
