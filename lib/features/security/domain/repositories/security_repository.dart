import 'package:business_manager/features/security/domain/entities/security_entities.dart';

/// Abstraction for local Android Keystore-backed security persistence.
/// Isolated from SQLite and `.zip` backups; 100% mockable in unit/widget tests.
abstract interface class SecurityRepository {
  /// Binds subsequent PIN storage reads/writes to [userId] (or local-only
  /// scope when `null`), seamlessly migrating legacy v1.4 local PIN keys.
  void setActiveAccountScope(String? userId);

  Future<SecuritySettings> loadSettings();

  /// Sets up a brand-new PIN and recovery key hash, enabling App Lock.
  Future<SecuritySettings> setupPin({
    required String pin,
    required String recoveryKey,
    bool enableBiometric = false,
    LockTimeoutOption timeout = LockTimeoutOption.minute1,
    bool screenshotProtectionEnabled = true,
  });

  /// Verifies [pin] against stored salted hash, persisting lockout counters on
  /// failure and clearing them on success.
  Future<PinVerificationResult> verifyPin(
    String pin, {
    required int nowUtcMillis,
  });

  /// Verifies [recoveryKey] (normalized Crockford 8-char) against stored hash
  /// with the same persistent lockout protection as PIN verification.
  Future<PinVerificationResult> verifyRecoveryKey(
    String recoveryKey, {
    required int nowUtcMillis,
  });

  /// Changes the PIN (after caller has verified current PIN) and optionally
  /// rotates the recovery key verifier.
  Future<SecuritySettings> updatePin({
    required String newPin,
    String? newRecoveryKey,
  });

  /// Regenerates only the recovery key verifier (after caller verified PIN).
  Future<SecuritySettings> updateRecoveryKey(String newRecoveryKey);

  /// Disables App Lock and wipes all stored PIN/recovery verifiers & lockout state.
  Future<SecuritySettings> disablePin();

  /// Updates non-secret lock preferences (biometric toggle, timeout, FLAG_SECURE).
  Future<SecuritySettings> updatePreferences({
    bool? biometricEnabled,
    LockTimeoutOption? timeout,
    bool? screenshotProtectionEnabled,
    bool? requireAuthForApprovals,
  });

  /// Records the timestamp when the app entered background (survives process death).
  Future<void> saveLastBackgroundedUtcMillis(int? utcMillis);

  /// Clears failed-attempt counter & lockout timestamp (e.g., after biometric unlock).
  Future<void> resetFailedAttempts();
}

/// Abstraction over platform biometric authentication (`local_auth` v3).
abstract interface class BiometricAuthService {
  Future<BiometricAvailability> checkAvailability();

  Future<BiometricAuthOutcome> authenticate({required String localizedReason});
}

/// Abstraction over native Android `WindowManager.LayoutParams.FLAG_SECURE`.
abstract interface class WindowSecurityService {
  Future<void> setFlagSecure(bool enabled);
}
