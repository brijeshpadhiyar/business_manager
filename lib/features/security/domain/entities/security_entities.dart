/// Supported automatic app-lock timeout durations when backgrounded or idle.
enum LockTimeoutOption {
  immediate(0),
  seconds30(30),
  minute1(60),
  minutes5(300),
  minutes15(900);

  const LockTimeoutOption(this.seconds);

  final int seconds;

  int get milliseconds => seconds * 1000;

  static LockTimeoutOption fromSeconds(int? value) {
    if (value == null) return LockTimeoutOption.minute1;
    for (final option in LockTimeoutOption.values) {
      if (option.seconds == value) return option;
    }
    return LockTimeoutOption.minute1;
  }
}

/// High-level state of the local application lock gate.
enum AppLockStatus {
  /// Loading secure storage configuration during app bootstrap.
  initializing,

  /// Local PIN security is turned OFF (default on upgrade from V1.1).
  disabled,

  /// Local PIN security is ON and the user must unlock before seeing app UI.
  locked,

  /// Local PIN security is ON and the user has unlocked the active session.
  unlocked,
}

/// Biometric hardware & enrollment capability on the current device.
enum BiometricAvailability { available, notEnrolled, noHardware, unavailable }

/// Outcome of a biometric prompt attempt.
enum BiometricAuthOutcome {
  success,
  canceled,
  notEnrolled,
  noHardware,
  temporaryLockout,
  permanentLockout,
  failed,
}

/// Result of attempting to verify a PIN or Recovery Key.
final class PinVerificationResult {
  const PinVerificationResult({
    required this.success,
    this.failedAttempts = 0,
    this.lockoutUntilUtcMillis,
    this.errorCode,
  });

  final bool success;
  final int failedAttempts;
  final int? lockoutUntilUtcMillis;
  final String? errorCode;

  bool isLockedOutAt(int nowUtcMillis) =>
      lockoutUntilUtcMillis != null && lockoutUntilUtcMillis! > nowUtcMillis;

  int remainingLockoutSecondsAt(int nowUtcMillis) {
    if (!isLockedOutAt(nowUtcMillis)) return 0;
    return ((lockoutUntilUtcMillis! - nowUtcMillis) / 1000).ceil();
  }
}

/// Persisted local security settings loaded from Android Keystore-backed
/// secure storage (never stored in SQLite or exported in `.zip` backups).
final class SecuritySettings {
  const SecuritySettings({
    this.pinEnabled = false,
    this.pinLength = 4,
    this.biometricEnabled = false,
    this.timeout = LockTimeoutOption.minute1,
    this.screenshotProtectionEnabled = true,
    this.failedAttempts = 0,
    this.lockoutUntilUtcMillis,
    this.lastBackgroundedUtcMillis,
    this.hasRecoveryKey = false,
    this.storageError = false,
  });

  final bool pinEnabled;
  final int pinLength;
  final bool biometricEnabled;
  final LockTimeoutOption timeout;
  final bool screenshotProtectionEnabled;
  final int failedAttempts;
  final int? lockoutUntilUtcMillis;
  final int? lastBackgroundedUtcMillis;
  final bool hasRecoveryKey;
  final bool storageError;

  SecuritySettings copyWith({
    bool? pinEnabled,
    int? pinLength,
    bool? biometricEnabled,
    LockTimeoutOption? timeout,
    bool? screenshotProtectionEnabled,
    int? failedAttempts,
    int? lockoutUntilUtcMillis,
    bool clearLockout = false,
    int? lastBackgroundedUtcMillis,
    bool clearLastBackgrounded = false,
    bool? hasRecoveryKey,
    bool? storageError,
  }) {
    return SecuritySettings(
      pinEnabled: pinEnabled ?? this.pinEnabled,
      pinLength: pinLength ?? this.pinLength,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      timeout: timeout ?? this.timeout,
      screenshotProtectionEnabled:
          screenshotProtectionEnabled ?? this.screenshotProtectionEnabled,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutUntilUtcMillis: clearLockout
          ? null
          : (lockoutUntilUtcMillis ?? this.lockoutUntilUtcMillis),
      lastBackgroundedUtcMillis: clearLastBackgrounded
          ? null
          : (lastBackgroundedUtcMillis ?? this.lastBackgroundedUtcMillis),
      hasRecoveryKey: hasRecoveryKey ?? this.hasRecoveryKey,
      storageError: storageError ?? this.storageError,
    );
  }
}
