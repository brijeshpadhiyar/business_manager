import 'package:business_manager/features/security/domain/services/pin_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PinHasher', () {
    test('validates 4-digit and 6-digit numeric PIN formats strictly', () {
      expect(PinHasher.isValidPinFormat('1234'), isTrue);
      expect(PinHasher.isValidPinFormat('098765'), isTrue);
      expect(PinHasher.isValidPinFormat('123'), isFalse);
      expect(PinHasher.isValidPinFormat('12345'), isFalse);
      expect(PinHasher.isValidPinFormat('1234567'), isFalse);
      expect(PinHasher.isValidPinFormat('12a4'), isFalse);
      expect(PinHasher.isValidPinFormat('1234', expectedLength: 6), isFalse);
      expect(PinHasher.isValidPinFormat('123456', expectedLength: 6), isTrue);
    });

    test('generates unambiguous Crockford XXXX-XXXX recovery keys', () {
      final seen = <String>{};
      for (var i = 0; i < 25; i++) {
        final key = PinHasher.generateRecoveryKey();
        expect(key.length, 9);
        expect(key[4], '-');
        expect(PinHasher.isValidRecoveryKeyFormat(key), isTrue);
        // Must never contain ambiguous characters 0, O, 1, I, L
        expect(key, isNot(contains('0')));
        expect(key, isNot(contains('O')));
        expect(key, isNot(contains('1')));
        expect(key, isNot(contains('I')));
        expect(key, isNot(contains('L')));
        seen.add(key);
      }
      expect(seen.length, greaterThan(20));

      expect(PinHasher.normalizeRecoveryKey(' abcd - ef23 '), 'ABCDEF23');
      expect(PinHasher.isValidRecoveryKeyFormat('ab23-cd45'), isTrue);
      expect(PinHasher.isValidRecoveryKeyFormat('0O1I-L234'), isFalse);
    });

    test('hashes with unique salt, never contains plaintext, and verifies in constant time', () async {
      const hasher = PinHasher(iterations: 2000);
      final h1 = await hasher.hashSecret('4829', runInIsolate: false);
      final h2 = await hasher.hashSecret('4829', runInIsolate: false);

      expect(h1, startsWith('pbkdf2_hmac_sha256\$v1\$2000\$'));
      expect(h1, isNot(equals(h2))); // Unique salt per hash
      expect(h1, isNot(contains('4829')));

      expect(
        await hasher.verifySecret('4829', h1, runInIsolate: false),
        isTrue,
      );
      expect(
        await hasher.verifySecret('4829', h2, runInIsolate: false),
        isTrue,
      );
      expect(
        await hasher.verifySecret('4828', h1, runInIsolate: false),
        isFalse,
      );
      expect(
        await hasher.verifySecret(
          '4829',
          'tampered\$v1\$2000\$a\$b',
          runInIsolate: false,
        ),
        isFalse,
      );
    });

    test(
      'production 210,000-iteration PBKDF2 executes in Isolate accurately',
      () async {
        const hasher = PinHasher();
        final sw = Stopwatch()..start();
        final encoded = await hasher.hashSecret('2580', runInIsolate: true);
        final ok = await hasher.verifySecret(
          '2580',
          encoded,
          runInIsolate: true,
        );
        final wrong = await hasher.verifySecret(
          '0000',
          encoded,
          runInIsolate: true,
        );
        sw.stop();

        expect(ok, isTrue);
        expect(wrong, isFalse);
        expect(encoded, startsWith('pbkdf2_hmac_sha256\$v1\$210000\$'));
        // Sanity check: 3 operations completed cleanly within reasonable budget
        expect(sw.elapsedMilliseconds, lessThan(15000));
      },
    );

    test('lockout durations obey 5th=30s, 8th=2m, 10th+=5m schedule', () {
      expect(PinHasher.lockoutDurationMsForFailedAttempts(1), isNull);
      expect(PinHasher.lockoutDurationMsForFailedAttempts(4), isNull);
      expect(PinHasher.lockoutDurationMsForFailedAttempts(5), 30 * 1000);
      expect(PinHasher.lockoutDurationMsForFailedAttempts(7), 30 * 1000);
      expect(PinHasher.lockoutDurationMsForFailedAttempts(8), 2 * 60 * 1000);
      expect(PinHasher.lockoutDurationMsForFailedAttempts(9), 2 * 60 * 1000);
      expect(PinHasher.lockoutDurationMsForFailedAttempts(10), 5 * 60 * 1000);
      expect(PinHasher.lockoutDurationMsForFailedAttempts(15), 5 * 60 * 1000);
    });
  });
}
