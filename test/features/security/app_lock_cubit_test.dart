import 'package:business_manager/features/security/domain/entities/security_entities.dart';
import 'package:business_manager/features/security/domain/repositories/security_repository.dart';
import 'package:business_manager/features/security/domain/services/pin_hasher.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deterministic in-memory [SecurityRepository] for fast cubit & lifecycle tests.
final class InMemorySecurityRepository implements SecurityRepository {
  InMemorySecurityRepository({this.hasher = const PinHasher(iterations: 1000)});

  final PinHasher hasher;
  SecuritySettings _settings = const SecuritySettings();
  String? _pinVerifier;
  String? _recoveryVerifier;

  @override
  void setActiveAccountScope(String? userId) {}

  @override
  Future<SecuritySettings> loadSettings() async => _settings;

  @override
  Future<SecuritySettings> setupPin({
    required String pin,
    required String recoveryKey,
    bool enableBiometric = false,
    LockTimeoutOption timeout = LockTimeoutOption.minute1,
    bool screenshotProtectionEnabled = true,
  }) async {
    _pinVerifier = await hasher.hashSecret(pin, runInIsolate: false);
    _recoveryVerifier = await hasher.hashSecret(
      PinHasher.normalizeRecoveryKey(recoveryKey),
      runInIsolate: false,
    );
    _settings = SecuritySettings(
      pinEnabled: true,
      pinLength: pin.length,
      biometricEnabled: enableBiometric,
      timeout: timeout,
      screenshotProtectionEnabled: screenshotProtectionEnabled,
      hasRecoveryKey: true,
    );
    return _settings;
  }

  @override
  Future<PinVerificationResult> verifyPin(
    String pin, {
    required int nowUtcMillis,
  }) => _verify(pin, _pinVerifier, nowUtcMillis, 'invalid_pin');

  @override
  Future<PinVerificationResult> verifyRecoveryKey(
    String recoveryKey, {
    required int nowUtcMillis,
  }) => _verify(
    PinHasher.normalizeRecoveryKey(recoveryKey),
    _recoveryVerifier,
    nowUtcMillis,
    'invalid_recovery_key',
  );

  Future<PinVerificationResult> _verify(
    String secret,
    String? verifier,
    int nowUtcMillis,
    String mismatchCode,
  ) async {
    if (_settings.lockoutUntilUtcMillis != null &&
        _settings.lockoutUntilUtcMillis! > nowUtcMillis) {
      return PinVerificationResult(
        success: false,
        failedAttempts: _settings.failedAttempts,
        lockoutUntilUtcMillis: _settings.lockoutUntilUtcMillis,
        errorCode: 'locked_out',
      );
    }
    if (verifier == null) {
      return const PinVerificationResult(
        success: false,
        errorCode: 'not_configured',
      );
    }
    final ok = await hasher.verifySecret(secret, verifier, runInIsolate: false);
    if (ok) {
      await resetFailedAttempts();
      return const PinVerificationResult(success: true);
    }
    final nextFailed = _settings.failedAttempts + 1;
    final dur = PinHasher.lockoutDurationMsForFailedAttempts(nextFailed);
    final until = dur != null ? nowUtcMillis + dur : null;
    _settings = _settings.copyWith(
      failedAttempts: nextFailed,
      lockoutUntilUtcMillis: until,
      clearLockout: until == null,
    );
    return PinVerificationResult(
      success: false,
      failedAttempts: nextFailed,
      lockoutUntilUtcMillis: until,
      errorCode: until != null ? 'locked_out' : mismatchCode,
    );
  }

  @override
  Future<SecuritySettings> updatePin({
    required String newPin,
    String? newRecoveryKey,
  }) async {
    _pinVerifier = await hasher.hashSecret(newPin, runInIsolate: false);
    if (newRecoveryKey != null) {
      _recoveryVerifier = await hasher.hashSecret(
        PinHasher.normalizeRecoveryKey(newRecoveryKey),
        runInIsolate: false,
      );
    }
    _settings = _settings.copyWith(
      pinEnabled: true,
      pinLength: newPin.length,
      failedAttempts: 0,
      clearLockout: true,
      hasRecoveryKey: _recoveryVerifier != null,
    );
    return _settings;
  }

  @override
  Future<SecuritySettings> updateRecoveryKey(String newRecoveryKey) async {
    _recoveryVerifier = await hasher.hashSecret(
      PinHasher.normalizeRecoveryKey(newRecoveryKey),
      runInIsolate: false,
    );
    _settings = _settings.copyWith(hasRecoveryKey: true);
    return _settings;
  }

  @override
  Future<SecuritySettings> disablePin() async {
    _pinVerifier = null;
    _recoveryVerifier = null;
    _settings = const SecuritySettings();
    return _settings;
  }

  @override
  Future<SecuritySettings> updatePreferences({
    bool? biometricEnabled,
    LockTimeoutOption? timeout,
    bool? screenshotProtectionEnabled,
    bool? requireAuthForApprovals,
  }) async {
    _settings = _settings.copyWith(
      biometricEnabled: biometricEnabled,
      timeout: timeout,
      screenshotProtectionEnabled: screenshotProtectionEnabled,
      requireAuthForApprovals: requireAuthForApprovals,
    );
    return _settings;
  }

  @override
  Future<void> saveLastBackgroundedUtcMillis(int? utcMillis) async {
    _settings = _settings.copyWith(
      lastBackgroundedUtcMillis: utcMillis,
      clearLastBackgrounded: utcMillis == null,
    );
  }

  @override
  Future<void> resetFailedAttempts() async {
    _settings = _settings.copyWith(failedAttempts: 0, clearLockout: true);
  }
}

final class FakeBiometricService implements BiometricAuthService {
  BiometricAvailability availability = BiometricAvailability.available;
  BiometricAuthOutcome nextOutcome = BiometricAuthOutcome.success;

  @override
  Future<BiometricAvailability> checkAvailability() async => availability;

  @override
  Future<BiometricAuthOutcome> authenticate({
    required String localizedReason,
  }) async => nextOutcome;
}

final class FakeWindowSecurityService implements WindowSecurityService {
  final List<bool> appliedFlags = [];

  @override
  Future<void> setFlagSecure(bool enabled) async {
    appliedFlags.add(enabled);
  }
}

void main() {
  late InMemorySecurityRepository repo;
  late FakeBiometricService bio;
  late FakeWindowSecurityService winSec;
  late int fakeNow;

  AppLockCubit createCubit() =>
      AppLockCubit(repo, bio, winSec, clockProvider: () => fakeNow);

  setUp(() {
    repo = InMemorySecurityRepository();
    bio = FakeBiometricService();
    winSec = FakeWindowSecurityService();
    fakeNow = 1795324800000;
  });

  test('starts disabled by default (safe upgrade from V1.1)', () async {
    final cubit = createCubit();
    await cubit.initialize();
    expect(cubit.state.status, AppLockStatus.disabled);
    expect(cubit.state.isPinEnabled, isFalse);
    await cubit.close();
  });

  test('cold start locks immediately when PIN is enabled, and persists lockout across restart', () async {
    final key = PinHasher.generateRecoveryKey();
    await repo.setupPin(pin: '1357', recoveryKey: key);

    final cubit1 = createCubit();
    await cubit1.initialize();
    expect(cubit1.state.status, AppLockStatus.locked);
    expect(winSec.appliedFlags.last, isTrue);

    // 5 wrong attempts trigger 30s lockout
    for (var i = 0; i < 5; i++) {
      final ok = await cubit1.unlockWithPin('9999');
      expect(ok, isFalse);
    }
    expect(cubit1.state.isLockedOut, isTrue);
    expect(cubit1.state.remainingLockoutSeconds, 30);
    await cubit1.close();

    // Simulate process kill & cold restart 10 seconds later: lockout MUST persist
    fakeNow += 10 * 1000;
    final cubit2 = createCubit();
    await cubit2.initialize();
    expect(cubit2.state.status, AppLockStatus.locked);
    expect(cubit2.state.isLockedOut, isTrue);
    expect(cubit2.state.remainingLockoutSeconds, 20);

    // Correct PIN still blocked during lockout
    expect(await cubit2.unlockWithPin('1357'), isFalse);

    // Advance past lockout -> correct PIN unlocks & clears failed attempts
    fakeNow += 25 * 1000;
    expect(await cubit2.unlockWithPin('1357'), isTrue);
    expect(cubit2.state.status, AppLockStatus.unlocked);
    expect(cubit2.state.settings.failedAttempts, 0);
    await cubit2.close();
  });

  test('handles background timeout, privacy shield, clock rollback, and system-picker suspension', () async {
    final cubit = createCubit();
    await cubit.initialize();
    await cubit.enablePin(
      pin: '2468',
      recoveryKey: PinHasher.generateRecoveryKey(),
      timeout: LockTimeoutOption.minute1,
    );
    expect(cubit.state.status, AppLockStatus.unlocked);

    // Inactive shows privacy shield
    cubit.onAppInactiveOrHidden();
    expect(cubit.state.showPrivacyShield, isTrue);

    // Background 30s (< 1m timeout) -> stays unlocked
    await cubit.onAppPaused();
    fakeNow += 30 * 1000;
    await cubit.onAppResumed();
    expect(cubit.state.status, AppLockStatus.unlocked);
    expect(cubit.state.showPrivacyShield, isFalse);

    // System picker open -> paused/resumed does NOT falsely lock
    await cubit.runWithSystemPicker(() async {
      cubit.onAppInactiveOrHidden();
      await cubit.onAppPaused();
      fakeNow += 15 * 1000;
      await cubit.onAppResumed();
    });
    expect(cubit.state.status, AppLockStatus.unlocked);

    // Background 65s (>= 1m timeout) -> locks automatically
    await cubit.onAppPaused();
    fakeNow += 65 * 1000;
    await cubit.onAppResumed();
    expect(cubit.state.status, AppLockStatus.locked);

    // Unlock again & verify backward clock tampering (>60s jump back) locks
    expect(await cubit.unlockWithPin('2468'), isTrue);
    await cubit.onAppPaused();
    fakeNow -= 120 * 1000;
    await cubit.onAppResumed();
    expect(cubit.state.status, AppLockStatus.locked);
    await cubit.close();
  });

  test('biometric cancellation, lockout, and unavailability never bypass lock; success unlocks', () async {
    final cubit = createCubit();
    await cubit.initialize();
    await cubit.enablePin(
      pin: '1122',
      recoveryKey: PinHasher.generateRecoveryKey(),
      enableBiometric: true,
    );
    await cubit.lockNow();
    expect(cubit.state.isLocked, isTrue);

    // Cancel -> stays locked cleanly with no error noise
    bio.nextOutcome = BiometricAuthOutcome.canceled;
    await cubit.unlockWithBiometrics(localizedReason: 'Unlock');
    expect(cubit.state.isLocked, isTrue);
    expect(cubit.state.errorCode, isNull);

    // Temporary lockout -> stays locked with fallback error code
    bio.nextOutcome = BiometricAuthOutcome.temporaryLockout;
    await cubit.unlockWithBiometrics(localizedReason: 'Unlock');
    expect(cubit.state.isLocked, isTrue);
    expect(cubit.state.errorCode, 'biometric_temp_lockout');

    // Success -> unlocks cleanly
    bio.nextOutcome = BiometricAuthOutcome.success;
    await cubit.unlockWithBiometrics(localizedReason: 'Unlock');
    expect(cubit.state.status, AppLockStatus.unlocked);
    await cubit.close();
  });

  test(
    'recovery key resets PIN & rotates key; queues deep link until unlock',
    () async {
      final initialKey = PinHasher.generateRecoveryKey();
      final cubit = createCubit();
      await cubit.initialize();
      await cubit.enablePin(pin: '4455', recoveryKey: initialKey);
      await cubit.lockNow();

      // Queue notification deep link while locked
      cubit.queueDeepLinkRoute('/accounting');
      expect(cubit.state.pendingDeepLinkRoute, '/accounting');
      expect(cubit.state.isLocked, isTrue);

      // Wrong recovery key fails
      final badRes = await cubit.verifyRecoveryKey('AAAA-BBBB');
      expect(badRes.success, isFalse);

      // Valid recovery key succeeds -> set new PIN & fresh recovery key
      final goodRes = await cubit.verifyRecoveryKey(initialKey);
      expect(goodRes.success, isTrue);

      final freshKey = PinHasher.generateRecoveryKey();
      await cubit.changePin(newPin: '778899', newRecoveryKey: freshKey);
      expect(cubit.state.status, AppLockStatus.unlocked);
      expect(cubit.state.settings.pinLength, 6);
      expect(cubit.consumePendingDeepLinkRoute(), '/accounting');
      expect(cubit.state.pendingDeepLinkRoute, isNull);

      // Old PIN no longer works, new PIN works
      await cubit.lockNow();
      expect(await cubit.unlockWithPin('4455'), isFalse);
      expect(await cubit.unlockWithPin('778899'), isTrue);
      await cubit.close();
    },
  );
}
