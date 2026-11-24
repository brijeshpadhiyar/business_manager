import 'dart:async';

import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/features/security/domain/entities/security_entities.dart';
import 'package:business_manager/features/security/domain/repositories/security_repository.dart';
import 'package:business_manager/features/security/domain/services/pin_hasher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

typedef ClockProvider = int Function();

final class AppLockState {
  const AppLockState({
    this.status = AppLockStatus.initializing,
    this.settings = const SecuritySettings(),
    this.biometricAvailability = BiometricAvailability.unavailable,
    this.showPrivacyShield = false,
    this.isVerifying = false,
    this.isBiometricInProgress = false,
    this.remainingLockoutSeconds = 0,
    this.errorCode,
    this.pendingDeepLinkRoute,
    this.forceSensitiveScreenFlagSecure = false,
  });

  final AppLockStatus status;
  final SecuritySettings settings;
  final BiometricAvailability biometricAvailability;
  final bool showPrivacyShield;
  final bool isVerifying;
  final bool isBiometricInProgress;
  final int remainingLockoutSeconds;
  final String? errorCode;
  final String? pendingDeepLinkRoute;
  final bool forceSensitiveScreenFlagSecure;

  bool get isLocked => status == AppLockStatus.locked;
  bool get isPinEnabled => settings.pinEnabled;
  bool get isLockedOut => remainingLockoutSeconds > 0;
  bool get canUseBiometrics =>
      settings.pinEnabled &&
      settings.biometricEnabled &&
      biometricAvailability == BiometricAvailability.available &&
      !isLockedOut;

  AppLockState copyWith({
    AppLockStatus? status,
    SecuritySettings? settings,
    BiometricAvailability? biometricAvailability,
    bool? showPrivacyShield,
    bool? isVerifying,
    bool? isBiometricInProgress,
    int? remainingLockoutSeconds,
    String? errorCode,
    bool clearError = false,
    String? pendingDeepLinkRoute,
    bool clearPendingDeepLink = false,
    bool? forceSensitiveScreenFlagSecure,
  }) {
    return AppLockState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      biometricAvailability:
          biometricAvailability ?? this.biometricAvailability,
      showPrivacyShield: showPrivacyShield ?? this.showPrivacyShield,
      isVerifying: isVerifying ?? this.isVerifying,
      isBiometricInProgress:
          isBiometricInProgress ?? this.isBiometricInProgress,
      remainingLockoutSeconds:
          remainingLockoutSeconds ?? this.remainingLockoutSeconds,
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      pendingDeepLinkRoute: clearPendingDeepLink
          ? null
          : (pendingDeepLinkRoute ?? this.pendingDeepLinkRoute),
      forceSensitiveScreenFlagSecure:
          forceSensitiveScreenFlagSecure ?? this.forceSensitiveScreenFlagSecure,
    );
  }
}

/// Root-level local security & app-lock controller (`@lazySingleton`).
///
/// Manages:
/// - Cold-start lock before any business frame renders.
/// - Background auto-lock with configurable timeout & anti-clock-tamper check.
/// - Foreground inactivity auto-lock.
/// - Privacy shield on `inactive`/`hidden`/`paused`.
/// - Dynamic Android `FLAG_SECURE` synchronization.
/// - Biometric unlock with PIN fallback and safe exception handling.
/// - Persistent brute-force exponential lockout across process restarts.
/// - System-picker auto-lock suspension (file picker, image picker, share sheet).
/// - Lock-safe pending deep-link queue for notification taps.
@lazySingleton
final class AppLockCubit extends Cubit<AppLockState> {
  AppLockCubit(
    this._repository,
    this._biometricService,
    this._windowSecurityService, {
    @ignoreParam ClockProvider? clockProvider,
  }) : _nowUtcMillis = clockProvider ?? IstDateTimeHelper.nowUtcMillis,
       super(const AppLockState());

  final SecurityRepository _repository;
  final BiometricAuthService _biometricService;
  final WindowSecurityService _windowSecurityService;
  final ClockProvider _nowUtcMillis;

  Timer? _inactivityTimer;
  Timer? _lockoutTicker;
  int _systemPickerDepth = 0;
  int? _systemPickerSuspendedAtUtcMs;

  static const int _maxSystemPickerSuspendMs = 120 * 1000;
  static const int _backwardClockToleranceMs = 60 * 1000;

  /// Short-lived handoff flag allowing `AppSessionController.reloadSession()`
  /// after an already-authenticated backup restore to stay unlocked seamlessly.
  static bool _preserveUnlockOnNextInit = false;

  static void markPreserveUnlockAcrossSessionReload() {
    _preserveUnlockOnNextInit = true;
  }

  Future<void> initialize() async {
    final preserveUnlocked = _preserveUnlockOnNextInit;
    _preserveUnlockOnNextInit = false;

    final settings = await _repository.loadSettings();
    final bioAvail = await _biometricService.checkAvailability();
    final now = _nowUtcMillis();
    final remLockout = _computeRemainingLockoutSeconds(
      settings.lockoutUntilUtcMillis,
      now,
    );

    final initialStatus = !settings.pinEnabled
        ? AppLockStatus.disabled
        : (preserveUnlocked ? AppLockStatus.unlocked : AppLockStatus.locked);

    emit(
      state.copyWith(
        status: initialStatus,
        settings: settings,
        biometricAvailability: bioAvail,
        remainingLockoutSeconds: remLockout,
        showPrivacyShield: false,
        clearError: true,
      ),
    );

    _startLockoutTickerIfNeeded();
    if (initialStatus == AppLockStatus.unlocked) {
      _resetForegroundInactivityTimer();
    }
    await _syncWindowFlagSecure();
  }

  /// Refreshes device biometric capability (e.g., when returning from OS Settings).
  Future<void> refreshBiometricAvailability() async {
    final bioAvail = await _biometricService.checkAvailability();
    if (!isClosed) {
      emit(state.copyWith(biometricAvailability: bioAvail));
    }
  }

  /// Sets or clears forced `FLAG_SECURE` while viewing sensitive security screens
  /// (PIN setup, PIN change, Recovery Key display).
  Future<void> setSensitiveScreenActive(bool active) async {
    if (isClosed) return;
    emit(state.copyWith(forceSensitiveScreenFlagSecure: active));
    await _syncWindowFlagSecure();
  }

  /// Suspends auto-lock briefly while launching a native system picker/share
  /// sheet (`file_picker`, `image_picker`, `share_plus`, `PrintManager`) so
  /// returning from the picker does not interrupt an active workshop task.
  Future<T> runWithSystemPicker<T>(Future<T> Function() action) async {
    _systemPickerDepth++;
    _systemPickerSuspendedAtUtcMs = _nowUtcMillis();
    _inactivityTimer?.cancel();
    try {
      return await action();
    } finally {
      _systemPickerDepth = (_systemPickerDepth - 1).clamp(0, 100);
      if (_systemPickerDepth == 0) {
        _systemPickerSuspendedAtUtcMs = null;
        if (state.status == AppLockStatus.unlocked) {
          _resetForegroundInactivityTimer();
        }
      }
    }
  }

  /// Records pointer interaction while unlocked to reset the foreground timer.
  void recordUserActivity() {
    if (state.status != AppLockStatus.unlocked) return;
    if (!state.settings.pinEnabled) return;
    if (state.settings.timeout == LockTimeoutOption.immediate) return;
    _resetForegroundInactivityTimer();
  }

  /// Immediately locks the application (if PIN security is enabled).
  Future<void> lockNow() async {
    if (!state.settings.pinEnabled) return;
    _inactivityTimer?.cancel();
    emit(
      state.copyWith(
        status: AppLockStatus.locked,
        showPrivacyShield: false,
        clearError: true,
      ),
    );
    await _syncWindowFlagSecure();
  }

  /// Called by [AppLockGate] when app becomes `inactive` or `hidden`.
  void onAppInactiveOrHidden() {
    if (!state.settings.pinEnabled) return;
    if (state.isBiometricInProgress || _isSystemPickerActive()) return;
    if (!state.showPrivacyShield) {
      emit(state.copyWith(showPrivacyShield: true));
    }
  }

  /// Called by [AppLockGate] when app enters `paused` (background).
  Future<void> onAppPaused() async {
    if (!state.settings.pinEnabled) return;
    if (state.isBiometricInProgress || _isSystemPickerActive()) return;

    _inactivityTimer?.cancel();
    final now = _nowUtcMillis();
    await _repository.saveLastBackgroundedUtcMillis(now);

    final updatedSettings = state.settings.copyWith(
      lastBackgroundedUtcMillis: now,
    );

    if (state.settings.timeout == LockTimeoutOption.immediate) {
      emit(
        state.copyWith(
          status: AppLockStatus.locked,
          settings: updatedSettings,
          showPrivacyShield: true,
          clearError: true,
        ),
      );
      await _syncWindowFlagSecure();
    } else {
      emit(state.copyWith(settings: updatedSettings, showPrivacyShield: true));
    }
  }

  /// Called by [AppLockGate] when app returns to `resumed` (foreground).
  Future<void> onAppResumed() async {
    if (!state.settings.pinEnabled) {
      if (state.showPrivacyShield) {
        emit(state.copyWith(showPrivacyShield: false));
      }
      return;
    }

    if (state.isBiometricInProgress || _isSystemPickerActive()) {
      if (state.showPrivacyShield) {
        emit(state.copyWith(showPrivacyShield: false));
      }
      return;
    }

    final now = _nowUtcMillis();
    final remLockout = _computeRemainingLockoutSeconds(
      state.settings.lockoutUntilUtcMillis,
      now,
    );

    if (state.status == AppLockStatus.locked) {
      emit(
        state.copyWith(
          showPrivacyShield: false,
          remainingLockoutSeconds: remLockout,
        ),
      );
      _startLockoutTickerIfNeeded();
      await _syncWindowFlagSecure();
      return;
    }

    final bgAt = state.settings.lastBackgroundedUtcMillis;
    var shouldLock = false;
    if (bgAt != null) {
      final elapsed = now - bgAt;
      // Lock if timeout elapsed OR if device clock jumped backwards significantly.
      if (elapsed >= state.settings.timeout.milliseconds ||
          elapsed < -_backwardClockToleranceMs) {
        shouldLock = true;
      }
    }

    await _repository.saveLastBackgroundedUtcMillis(null);
    final clearedSettings = state.settings.copyWith(
      clearLastBackgrounded: true,
    );

    if (shouldLock) {
      emit(
        state.copyWith(
          status: AppLockStatus.locked,
          settings: clearedSettings,
          showPrivacyShield: false,
          remainingLockoutSeconds: remLockout,
          clearError: true,
        ),
      );
      _startLockoutTickerIfNeeded();
      await _syncWindowFlagSecure();
    } else {
      emit(
        state.copyWith(
          settings: clearedSettings,
          showPrivacyShield: false,
          remainingLockoutSeconds: remLockout,
        ),
      );
      _resetForegroundInactivityTimer();
      await _syncWindowFlagSecure();
    }
  }

  /// Attempts to unlock the app using a numeric PIN.
  Future<bool> unlockWithPin(String pin) async {
    if (state.isVerifying) return false;
    final now = _nowUtcMillis();
    final activeLockout = _computeRemainingLockoutSeconds(
      state.settings.lockoutUntilUtcMillis,
      now,
    );
    if (activeLockout > 0) {
      emit(
        state.copyWith(
          remainingLockoutSeconds: activeLockout,
          errorCode: 'locked_out',
        ),
      );
      _startLockoutTickerIfNeeded();
      return false;
    }

    emit(state.copyWith(isVerifying: true, clearError: true));
    final result = await _repository.verifyPin(pin, nowUtcMillis: now);

    if (result.success) {
      final refreshed = state.settings.copyWith(
        failedAttempts: 0,
        clearLockout: true,
        clearLastBackgrounded: true,
      );
      await _repository.saveLastBackgroundedUtcMillis(null);
      _lockoutTicker?.cancel();
      emit(
        state.copyWith(
          status: AppLockStatus.unlocked,
          settings: refreshed,
          isVerifying: false,
          remainingLockoutSeconds: 0,
          showPrivacyShield: false,
          clearError: true,
        ),
      );
      _resetForegroundInactivityTimer();
      await _syncWindowFlagSecure();
      return true;
    }

    final updatedSettings = state.settings.copyWith(
      failedAttempts: result.failedAttempts,
      lockoutUntilUtcMillis: result.lockoutUntilUtcMillis,
      clearLockout: result.lockoutUntilUtcMillis == null,
    );
    final remSec = result.remainingLockoutSecondsAt(now);
    emit(
      state.copyWith(
        settings: updatedSettings,
        isVerifying: false,
        remainingLockoutSeconds: remSec,
        errorCode: result.errorCode ?? 'invalid_pin',
      ),
    );
    _startLockoutTickerIfNeeded();
    return false;
  }

  /// Attempts to unlock using Android BiometricPrompt (only when enabled & not locked out).
  Future<BiometricAuthOutcome> unlockWithBiometrics({
    required String localizedReason,
  }) async {
    if (!state.canUseBiometrics || state.isBiometricInProgress) {
      return BiometricAuthOutcome.failed;
    }

    emit(state.copyWith(isBiometricInProgress: true, clearError: true));
    final outcome = await _biometricService.authenticate(
      localizedReason: localizedReason,
    );

    if (isClosed) return outcome;

    if (outcome == BiometricAuthOutcome.success) {
      await _repository.resetFailedAttempts();
      await _repository.saveLastBackgroundedUtcMillis(null);
      final refreshed = state.settings.copyWith(
        failedAttempts: 0,
        clearLockout: true,
        clearLastBackgrounded: true,
      );
      _lockoutTicker?.cancel();
      emit(
        state.copyWith(
          status: AppLockStatus.unlocked,
          settings: refreshed,
          isBiometricInProgress: false,
          remainingLockoutSeconds: 0,
          showPrivacyShield: false,
          clearError: true,
        ),
      );
      _resetForegroundInactivityTimer();
      await _syncWindowFlagSecure();
      return outcome;
    }

    final errCode = switch (outcome) {
      BiometricAuthOutcome.canceled => null, // Quiet fallback to PIN pad
      BiometricAuthOutcome.temporaryLockout => 'biometric_temp_lockout',
      BiometricAuthOutcome.permanentLockout => 'biometric_perm_lockout',
      BiometricAuthOutcome.notEnrolled => 'biometric_not_enrolled',
      BiometricAuthOutcome.noHardware => 'biometric_no_hardware',
      BiometricAuthOutcome.failed => 'biometric_failed',
      BiometricAuthOutcome.success => null,
    };

    emit(
      state.copyWith(
        isBiometricInProgress: false,
        errorCode: errCode,
        clearError: errCode == null,
      ),
    );
    return outcome;
  }

  /// Verifies current PIN for sensitive operations without changing lock state.
  Future<PinVerificationResult> verifyPinForSensitiveAction(String pin) async {
    final now = _nowUtcMillis();
    final result = await _repository.verifyPin(pin, nowUtcMillis: now);
    final updatedSettings = state.settings.copyWith(
      failedAttempts: result.success ? 0 : result.failedAttempts,
      lockoutUntilUtcMillis: result.lockoutUntilUtcMillis,
      clearLockout: result.success || result.lockoutUntilUtcMillis == null,
    );
    emit(
      state.copyWith(
        settings: updatedSettings,
        remainingLockoutSeconds: result.remainingLockoutSecondsAt(now),
      ),
    );
    _startLockoutTickerIfNeeded();
    return result;
  }

  /// Verifies biometrics for a sensitive operation (e.g., Backup Restore / Raw SQLite).
  Future<BiometricAuthOutcome> verifyBiometricForSensitiveAction({
    required String localizedReason,
  }) async {
    if (!state.canUseBiometrics) return BiometricAuthOutcome.failed;
    emit(state.copyWith(isBiometricInProgress: true));
    try {
      return await _biometricService.authenticate(
        localizedReason: localizedReason,
      );
    } finally {
      if (!isClosed) {
        emit(state.copyWith(isBiometricInProgress: false));
      }
    }
  }

  /// Verifies an offline Recovery Key during the Forgot PIN flow.
  Future<PinVerificationResult> verifyRecoveryKey(String recoveryKey) async {
    final now = _nowUtcMillis();
    final result = await _repository.verifyRecoveryKey(
      recoveryKey,
      nowUtcMillis: now,
    );
    final updatedSettings = state.settings.copyWith(
      failedAttempts: result.success ? 0 : result.failedAttempts,
      lockoutUntilUtcMillis: result.lockoutUntilUtcMillis,
      clearLockout: result.success || result.lockoutUntilUtcMillis == null,
    );
    emit(
      state.copyWith(
        settings: updatedSettings,
        remainingLockoutSeconds: result.remainingLockoutSecondsAt(now),
      ),
    );
    _startLockoutTickerIfNeeded();
    return result;
  }

  /// Enables PIN lock with a brand-new PIN and confirmed offline Recovery Key.
  Future<void> enablePin({
    required String pin,
    required String recoveryKey,
    bool enableBiometric = false,
    LockTimeoutOption timeout = LockTimeoutOption.minute1,
    bool screenshotProtectionEnabled = true,
  }) async {
    if (!AppValidators.pinValidator(pin).isValid) {
      throw const DomainValidationException(
        'invalid_pin',
        'PIN must be 4 or 6 numeric digits.',
      );
    }
    if (!AppValidators.recoveryKeyValidator(recoveryKey).isValid) {
      throw const DomainValidationException(
        'invalid_recovery_key',
        'Invalid recovery key format.',
      );
    }
    final bioEnabled =
        enableBiometric &&
        state.biometricAvailability == BiometricAvailability.available;
    final updated = await _repository.setupPin(
      pin: pin,
      recoveryKey: recoveryKey,
      enableBiometric: bioEnabled,
      timeout: timeout,
      screenshotProtectionEnabled: screenshotProtectionEnabled,
    );
    emit(
      state.copyWith(
        status: AppLockStatus.unlocked,
        settings: updated,
        remainingLockoutSeconds: 0,
        clearError: true,
      ),
    );
    _resetForegroundInactivityTimer();
    await _syncWindowFlagSecure();
  }

  /// Changes PIN (or completes Recovery Key PIN reset with a fresh Recovery Key).
  Future<void> changePin({
    required String newPin,
    String? newRecoveryKey,
  }) async {
    if (!AppValidators.pinValidator(newPin).isValid) {
      throw const DomainValidationException(
        'invalid_pin',
        'PIN must be 4 or 6 numeric digits.',
      );
    }
    if (newRecoveryKey != null &&
        !AppValidators.recoveryKeyValidator(newRecoveryKey).isValid) {
      throw const DomainValidationException(
        'invalid_recovery_key',
        'Invalid recovery key format.',
      );
    }
    final updated = await _repository.updatePin(
      newPin: newPin,
      newRecoveryKey: newRecoveryKey,
    );
    _lockoutTicker?.cancel();
    emit(
      state.copyWith(
        status: AppLockStatus.unlocked,
        settings: updated,
        remainingLockoutSeconds: 0,
        showPrivacyShield: false,
        clearError: true,
      ),
    );
    _resetForegroundInactivityTimer();
    await _syncWindowFlagSecure();
  }

  /// Regenerates and saves a fresh Recovery Key verifier.
  Future<String> regenerateRecoveryKey() async {
    final freshKey = PinHasher.generateRecoveryKey();
    final updated = await _repository.updateRecoveryKey(freshKey);
    emit(state.copyWith(settings: updated));
    return freshKey;
  }

  /// Disables PIN lock completely (caller must have verified current PIN first).
  Future<void> disablePin() async {
    _inactivityTimer?.cancel();
    _lockoutTicker?.cancel();
    final updated = await _repository.disablePin();
    emit(
      state.copyWith(
        status: AppLockStatus.disabled,
        settings: updated,
        remainingLockoutSeconds: 0,
        showPrivacyShield: false,
        clearError: true,
      ),
    );
    await _syncWindowFlagSecure();
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    final effective =
        enabled &&
        state.biometricAvailability == BiometricAvailability.available;
    final updated = await _repository.updatePreferences(
      biometricEnabled: effective,
    );
    emit(state.copyWith(settings: updated));
  }

  Future<void> setTimeout(LockTimeoutOption timeout) async {
    final updated = await _repository.updatePreferences(timeout: timeout);
    emit(state.copyWith(settings: updated));
    if (state.status == AppLockStatus.unlocked) {
      _resetForegroundInactivityTimer();
    }
  }

  Future<void> setScreenshotProtectionEnabled(bool enabled) async {
    final updated = await _repository.updatePreferences(
      screenshotProtectionEnabled: enabled,
    );
    emit(state.copyWith(settings: updated));
    await _syncWindowFlagSecure();
  }

  Future<void> setRequireAuthForApprovals(bool enabled) async {
    final updated = await _repository.updatePreferences(
      requireAuthForApprovals: enabled,
    );
    emit(state.copyWith(settings: updated));
  }

  /// Queues a validated deep-link route (e.g., from a tapped local notification).
  /// If locked, the route is held until unlock; if unlocked, consumers navigate immediately.
  void queueDeepLinkRoute(String routePath) {
    emit(state.copyWith(pendingDeepLinkRoute: routePath));
  }

  String? consumePendingDeepLinkRoute() {
    final route = state.pendingDeepLinkRoute;
    if (route != null) {
      emit(state.copyWith(clearPendingDeepLink: true));
    }
    return route;
  }

  void clearError() {
    if (state.errorCode != null) {
      emit(state.copyWith(clearError: true));
    }
  }

  /// Cancels in-memory foreground & countdown timers when the root UI unmounts.
  void pauseTimersOnUnmount() {
    _inactivityTimer?.cancel();
    _lockoutTicker?.cancel();
  }

  bool _isSystemPickerActive() {
    if (_systemPickerDepth <= 0) return false;
    final started = _systemPickerSuspendedAtUtcMs;
    if (started == null) return false;
    final elapsed = _nowUtcMillis() - started;
    if (elapsed > _maxSystemPickerSuspendMs || elapsed < 0) {
      _systemPickerDepth = 0;
      _systemPickerSuspendedAtUtcMs = null;
      return false;
    }
    return true;
  }

  int _computeRemainingLockoutSeconds(int? lockoutUntilUtcMillis, int now) {
    if (lockoutUntilUtcMillis == null || lockoutUntilUtcMillis <= now) return 0;
    return ((lockoutUntilUtcMillis - now) / 1000).ceil();
  }

  void _resetForegroundInactivityTimer() {
    _inactivityTimer?.cancel();
    if (!state.settings.pinEnabled || state.status != AppLockStatus.unlocked) {
      return;
    }
    final timeout = state.settings.timeout;
    if (timeout == LockTimeoutOption.immediate) return;
    _inactivityTimer = Timer(Duration(seconds: timeout.seconds), () {
      if (!isClosed &&
          state.status == AppLockStatus.unlocked &&
          !_isSystemPickerActive() &&
          !state.isBiometricInProgress) {
        lockNow();
      }
    });
  }

  void _startLockoutTickerIfNeeded() {
    _lockoutTicker?.cancel();
    final until = state.settings.lockoutUntilUtcMillis;
    if (until == null) return;
    final rem = _computeRemainingLockoutSeconds(until, _nowUtcMillis());
    if (rem <= 0) return;

    _lockoutTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed) {
        timer.cancel();
        return;
      }
      final nextRem = _computeRemainingLockoutSeconds(until, _nowUtcMillis());
      if (nextRem <= 0) {
        timer.cancel();
        emit(
          state.copyWith(
            remainingLockoutSeconds: 0,
            clearError: state.errorCode == 'locked_out',
          ),
        );
      } else if (nextRem != state.remainingLockoutSeconds) {
        emit(state.copyWith(remainingLockoutSeconds: nextRem));
      }
    });
  }

  Future<void> _syncWindowFlagSecure() async {
    final shouldSecure =
        state.forceSensitiveScreenFlagSecure ||
        state.status == AppLockStatus.locked ||
        (state.settings.pinEnabled &&
            state.settings.screenshotProtectionEnabled);
    await _windowSecurityService.setFlagSecure(shouldSecure);
  }

  @override
  Future<void> close() {
    _inactivityTimer?.cancel();
    _lockoutTicker?.cancel();
    return super.close();
  }
}
