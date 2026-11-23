import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Pure Dart PBKDF2-HMAC-SHA256 PIN & Recovery Key hasher with CSPRNG salts,
/// Isolate offloading, and constant-time digest comparison.
///
/// Stored format (self-describing):
/// `pbkdf2_hmac_sha256$v1$<iterations>$<base64_salt>$<base64_dk>`
///
/// Never logs or persists plaintext PINs or recovery keys.
final class PinHasher {
  const PinHasher({
    this.iterations = defaultIterations,
    this.saltLengthBytes = 16,
    this.derivedKeyLengthBytes = 32,
  });

  /// Production PBKDF2-HMAC-SHA256 iteration count.
  /// Benchmarked in automated tests and offloaded to a background [Isolate].
  static const int defaultIterations = 210000;

  static const String algorithmId = 'pbkdf2_hmac_sha256';
  static const String formatVersion = 'v1';

  /// Unambiguous Crockford-style alphabet (omits 0, O, 1, I, L) so the workshop
  /// owner can reliably write down and re-enter the 8-character Recovery Key.
  static const String recoveryAlphabet = '23456789ABCDEFGHJKMNPQRSTUVWXYZ';

  final int iterations;
  final int saltLengthBytes;
  final int derivedKeyLengthBytes;

  /// Validates that [pin] is strictly numeric and 4 or 6 digits long.
  static bool isValidPinFormat(String pin, {int? expectedLength}) {
    if (expectedLength != null && pin.length != expectedLength) return false;
    if (pin.length != 4 && pin.length != 6) return false;
    for (var i = 0; i < pin.length; i++) {
      final code = pin.codeUnitAt(i);
      if (code < 0x30 || code > 0x39) return false;
    }
    return true;
  }

  /// Generates an 8-character random offline recovery key formatted as `XXXX-XXXX`.
  static String generateRecoveryKey({Random? random}) {
    final rng = random ?? Random.secure();
    final chars = List<String>.generate(
      8,
      (_) => recoveryAlphabet[rng.nextInt(recoveryAlphabet.length)],
    );
    return '${chars.sublist(0, 4).join()}-${chars.sublist(4, 8).join()}';
  }

  /// Normalizes user-entered recovery key input (strips spaces/hyphens, uppercases).
  static String normalizeRecoveryKey(String input) {
    return input.trim().toUpperCase().replaceAll('-', '').replaceAll(' ', '');
  }

  /// Checks whether normalized recovery key contains 8 valid Crockford chars.
  static bool isValidRecoveryKeyFormat(String input) {
    final norm = normalizeRecoveryKey(input);
    if (norm.length != 8) return false;
    for (var i = 0; i < norm.length; i++) {
      if (!recoveryAlphabet.contains(norm[i])) return false;
    }
    return true;
  }

  /// Hashes a secret (PIN or normalized recovery key) in a background [Isolate]
  /// with a fresh CSPRNG salt.
  Future<String> hashSecret(String secret, {bool runInIsolate = true}) async {
    final rng = Random.secure();
    final salt = Uint8List.fromList(
      List<int>.generate(saltLengthBytes, (_) => rng.nextInt(256)),
    );
    final secretBytes = Uint8List.fromList(utf8.encode(secret));
    final iters = iterations;
    final dkLen = derivedKeyLengthBytes;

    final dk = runInIsolate
        ? await Isolate.run(
            () => derivePbkdf2HmacSha256(
              passwordBytes: secretBytes,
              salt: salt,
              iterations: iters,
              keyLength: dkLen,
            ),
          )
        : derivePbkdf2HmacSha256(
            passwordBytes: secretBytes,
            salt: salt,
            iterations: iters,
            keyLength: dkLen,
          );

    return '$algorithmId\$$formatVersion\$$iters\$${base64Encode(salt)}\$${base64Encode(dk)}';
  }

  /// Verifies [candidateSecret] against a stored [encodedVerifier] using
  /// constant-time byte comparison in a background [Isolate].
  Future<bool> verifySecret(
    String candidateSecret,
    String encodedVerifier, {
    bool runInIsolate = true,
  }) async {
    final parts = encodedVerifier.split('\$');
    if (parts.length != 5) return false;
    if (parts[0] != algorithmId || parts[1] != formatVersion) return false;

    final parsedIters = int.tryParse(parts[2]);
    if (parsedIters == null || parsedIters < 1000) return false;

    Uint8List salt;
    Uint8List expectedDk;
    try {
      salt = base64Decode(parts[3]);
      expectedDk = base64Decode(parts[4]);
    } catch (_) {
      return false;
    }
    if (salt.isEmpty || expectedDk.isEmpty) return false;

    final secretBytes = Uint8List.fromList(utf8.encode(candidateSecret));
    final dkLen = expectedDk.length;

    final actualDk = runInIsolate
        ? await Isolate.run(
            () => derivePbkdf2HmacSha256(
              passwordBytes: secretBytes,
              salt: salt,
              iterations: parsedIters,
              keyLength: dkLen,
            ),
          )
        : derivePbkdf2HmacSha256(
            passwordBytes: secretBytes,
            salt: salt,
            iterations: parsedIters,
            keyLength: dkLen,
          );

    return constantTimeEquals(actualDk, expectedDk);
  }

  /// RFC 2898 PBKDF2-HMAC-SHA256 implementation using `package:crypto`.
  static Uint8List derivePbkdf2HmacSha256({
    required Uint8List passwordBytes,
    required Uint8List salt,
    required int iterations,
    required int keyLength,
  }) {
    const hashLen = 32; // SHA-256 digest length in bytes
    final hmac = Hmac(sha256, passwordBytes);
    final blockCount = (keyLength + hashLen - 1) ~/ hashLen;
    final output = Uint8List(blockCount * hashLen);

    final saltWithIndex = Uint8List(salt.length + 4);
    saltWithIndex.setRange(0, salt.length, salt);

    for (var block = 1; block <= blockCount; block++) {
      saltWithIndex[salt.length] = (block >> 24) & 0xff;
      saltWithIndex[salt.length + 1] = (block >> 16) & 0xff;
      saltWithIndex[salt.length + 2] = (block >> 8) & 0xff;
      saltWithIndex[salt.length + 3] = block & 0xff;

      var u = hmac.convert(saltWithIndex).bytes;
      final t = Uint8List.fromList(u);

      for (var iter = 1; iter < iterations; iter++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < hashLen; j++) {
          t[j] ^= u[j];
        }
      }

      output.setRange((block - 1) * hashLen, block * hashLen, t);
    }

    return Uint8List.sublistView(output, 0, keyLength);
  }

  /// Constant-time comparison preventing timing side-channel leaks.
  static bool constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }

  /// Calculates lockout duration (in milliseconds) for consecutive failed
  /// attempts:
  /// - 5th..7th failure -> 30 seconds
  /// - 8th..9th failure -> 2 minutes
  /// - 10th+ failure -> 5 minutes
  static int? lockoutDurationMsForFailedAttempts(int failedAttempts) {
    if (failedAttempts >= 10) return 5 * 60 * 1000;
    if (failedAttempts >= 8) return 2 * 60 * 1000;
    if (failedAttempts >= 5) return 30 * 1000;
    return null;
  }
}
