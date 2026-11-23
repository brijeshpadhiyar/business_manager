import 'dart:convert';
import 'dart:io' show Platform;

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/security/domain/entities/security_entities.dart';
import 'package:business_manager/features/security/domain/repositories/security_repository.dart';
import 'package:business_manager/features/security/domain/services/pin_hasher.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Android Keystore-backed implementation of [SecurityRepository] using
/// `flutter_secure_storage` v11 (`RSA-OAEP-SHA256` key wrapping + `AES-GCM`).
///
/// Key guarantees:
/// - `resetOnError: false` prevents silent PIN erasure on transient KeyStore errors.
/// - Flavor-isolated `storageNamespace` and key prefix (`sf_dev_` / `sf_prod_`).
/// - Security credentials NEVER touch SQLite or `.zip` backups.
/// - Security lifecycle events (enable/change/disable/recovery) are audited in
///   `audit_logs` with `entity_type = 'app_security'`, `action_type = 'UPDATE'`
///   without ever recording any PIN, salt, hash, or recovery key.
@LazySingleton(as: SecurityRepository)
final class SecureStorageSecurityRepository implements SecurityRepository {
  SecureStorageSecurityRepository(
    this._config,
    this._db,
    this._idGenerator, {
    @ignoreParam FlutterSecureStorage? storageOverride,
    @ignoreParam PinHasher? hasherOverride,
    @ignoreParam bool runHashInIsolate = true,
  }) : _storage =
           storageOverride ??
           FlutterSecureStorage(
             aOptions: AndroidOptions(
               resetOnError: false,
               migrateOnAlgorithmChange: true,
               storageNamespace: 'sf_${_config.flavor.name}_security',
             ),
           ),
       _hasher = hasherOverride ?? const PinHasher(),
       _useIsolateForHashing = runHashInIsolate;

  final AppConfig _config;
  final AppDatabase _db;
  final IdGenerator _idGenerator;
  final FlutterSecureStorage _storage;
  final PinHasher _hasher;
  final bool _useIsolateForHashing;
  final Map<String, String>? _testMemoryStore =
      (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST'))
      ? <String, String>{}
      : null;

  Future<String?> _readKey(String key) async {
    final mem = _testMemoryStore;
    if (mem != null) return mem[key];
    return _storage.read(key: key);
  }

  Future<void> _writeKey(String key, String value) async {
    final mem = _testMemoryStore;
    if (mem != null) {
      mem[key] = value;
      return;
    }
    await _storage.write(key: key, value: value);
  }

  Future<void> _deleteKey(String key) async {
    final mem = _testMemoryStore;
    if (mem != null) {
      mem.remove(key);
      return;
    }
    await _storage.delete(key: key);
  }

  String get _prefix => 'sf_${_config.flavor.name}_';
  String get _kPinEnabled => '${_prefix}pin_enabled';
  String get _kPinLength => '${_prefix}pin_length';
  String get _kPinVerifier => '${_prefix}pin_verifier';
  String get _kRecoveryVerifier => '${_prefix}recovery_verifier';
  String get _kBiometricEnabled => '${_prefix}biometric_enabled';
  String get _kTimeoutSec => '${_prefix}lock_timeout_sec';
  String get _kFlagSecure => '${_prefix}flag_secure_enabled';
  String get _kFailedAttempts => '${_prefix}failed_attempts';
  String get _kLockoutUntil => '${_prefix}lockout_until_utc_ms';
  String get _kLastBackgrounded => '${_prefix}last_backgrounded_utc_ms';

  Future<void> _recordSecurityAudit(String event, {String? reason}) async {
    try {
      final now = IstDateTimeHelper.nowUtcMillis();
      final profile = await _db.businessProfileDao.getProfile();
      final actor = profile?.ownerName?.trim().isNotEmpty == true
          ? profile!.ownerName!.trim()
          : 'local_owner';
      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('app_security'),
          entityId: Value(_config.flavor.name),
          actionType: const Value('UPDATE'),
          actor: Value(actor),
          newValueJson: Value(jsonEncode({'event': event})),
          reason: Value(reason ?? event),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );
    } catch (_) {
      // Never block security operations if audit insert fails (e.g. DB not ready).
    }
  }

  @override
  Future<SecuritySettings> loadSettings() async {
    try {
      final pinEnabledStr = await _readKey(_kPinEnabled);
      final pinVerifier = await _readKey(_kPinVerifier);
      final pinEnabled =
          pinEnabledStr == 'true' &&
          pinVerifier != null &&
          pinVerifier.isNotEmpty;

      final pinLength = int.tryParse((await _readKey(_kPinLength)) ?? '');
      final recoveryVerifier = await _readKey(_kRecoveryVerifier);
      final biometricEnabled = (await _readKey(_kBiometricEnabled)) == 'true';
      final timeoutSec = int.tryParse((await _readKey(_kTimeoutSec)) ?? '');
      final flagSecureStr = await _readKey(_kFlagSecure);
      final failedAttempts =
          int.tryParse((await _readKey(_kFailedAttempts)) ?? '') ?? 0;
      final lockoutUntil = int.tryParse((await _readKey(_kLockoutUntil)) ?? '');
      final lastBg = int.tryParse((await _readKey(_kLastBackgrounded)) ?? '');

      return SecuritySettings(
        pinEnabled: pinEnabled,
        pinLength: (pinLength == 6) ? 6 : 4,
        biometricEnabled: biometricEnabled,
        timeout: LockTimeoutOption.fromSeconds(timeoutSec),
        screenshotProtectionEnabled: flagSecureStr != 'false',
        failedAttempts: failedAttempts,
        lockoutUntilUtcMillis: lockoutUntil,
        lastBackgroundedUtcMillis: lastBg,
        hasRecoveryKey: recoveryVerifier != null && recoveryVerifier.isNotEmpty,
      );
    } catch (_) {
      // Fail closed with storageError if KeyStore read fails; never crash boot.
      return const SecuritySettings(storageError: true);
    }
  }

  @override
  Future<SecuritySettings> setupPin({
    required String pin,
    required String recoveryKey,
    bool enableBiometric = false,
    LockTimeoutOption timeout = LockTimeoutOption.minute1,
    bool screenshotProtectionEnabled = true,
  }) async {
    if (!PinHasher.isValidPinFormat(pin)) {
      throw ArgumentError('PIN must be 4 or 6 numeric digits.');
    }
    final normalizedRecovery = PinHasher.normalizeRecoveryKey(recoveryKey);
    if (!PinHasher.isValidRecoveryKeyFormat(normalizedRecovery)) {
      throw ArgumentError('Invalid recovery key format.');
    }

    final pinVerifier = await _hasher.hashSecret(
      pin,
      runInIsolate: _useIsolateForHashing,
    );
    final recoveryVerifier = await _hasher.hashSecret(
      normalizedRecovery,
      runInIsolate: _useIsolateForHashing,
    );

    await _writeKey(_kPinVerifier, pinVerifier);
    await _writeKey(_kRecoveryVerifier, recoveryVerifier);
    await _writeKey(_kPinLength, '${pin.length}');
    await _writeKey(_kPinEnabled, 'true');
    await _writeKey(_kBiometricEnabled, enableBiometric ? 'true' : 'false');
    await _writeKey(_kTimeoutSec, '${timeout.seconds}');
    await _writeKey(
      _kFlagSecure,
      screenshotProtectionEnabled ? 'true' : 'false',
    );
    await _deleteKey(_kFailedAttempts);
    await _deleteKey(_kLockoutUntil);

    await _recordSecurityAudit(
      'pin_enabled',
      reason: 'Local app PIN enabled by owner',
    );
    return loadSettings();
  }

  @override
  Future<PinVerificationResult> verifyPin(
    String pin, {
    required int nowUtcMillis,
  }) async {
    return _verifyAgainstKey(
      secret: pin,
      verifierKey: _kPinVerifier,
      nowUtcMillis: nowUtcMillis,
      mismatchCode: 'invalid_pin',
    );
  }

  @override
  Future<PinVerificationResult> verifyRecoveryKey(
    String recoveryKey, {
    required int nowUtcMillis,
  }) async {
    final normalized = PinHasher.normalizeRecoveryKey(recoveryKey);
    return _verifyAgainstKey(
      secret: normalized,
      verifierKey: _kRecoveryVerifier,
      nowUtcMillis: nowUtcMillis,
      mismatchCode: 'invalid_recovery_key',
    );
  }

  Future<PinVerificationResult> _verifyAgainstKey({
    required String secret,
    required String verifierKey,
    required int nowUtcMillis,
    required String mismatchCode,
  }) async {
    final settings = await loadSettings();
    if (settings.lockoutUntilUtcMillis != null &&
        settings.lockoutUntilUtcMillis! > nowUtcMillis) {
      return PinVerificationResult(
        success: false,
        failedAttempts: settings.failedAttempts,
        lockoutUntilUtcMillis: settings.lockoutUntilUtcMillis,
        errorCode: 'locked_out',
      );
    }

    final storedVerifier = await _readKey(verifierKey);
    if (storedVerifier == null || storedVerifier.isEmpty) {
      return const PinVerificationResult(
        success: false,
        errorCode: 'not_configured',
      );
    }

    final matched = await _hasher.verifySecret(
      secret,
      storedVerifier,
      runInIsolate: _useIsolateForHashing,
    );

    if (matched) {
      await resetFailedAttempts();
      return const PinVerificationResult(success: true);
    }

    final nextFailed = settings.failedAttempts + 1;
    final lockoutDurationMs = PinHasher.lockoutDurationMsForFailedAttempts(
      nextFailed,
    );
    final lockoutUntil = lockoutDurationMs != null
        ? nowUtcMillis + lockoutDurationMs
        : null;

    await _writeKey(_kFailedAttempts, '$nextFailed');
    if (lockoutUntil != null) {
      await _writeKey(_kLockoutUntil, '$lockoutUntil');
    } else {
      await _deleteKey(_kLockoutUntil);
    }

    return PinVerificationResult(
      success: false,
      failedAttempts: nextFailed,
      lockoutUntilUtcMillis: lockoutUntil,
      errorCode: lockoutUntil != null ? 'locked_out' : mismatchCode,
    );
  }

  @override
  Future<SecuritySettings> updatePin({
    required String newPin,
    String? newRecoveryKey,
  }) async {
    if (!PinHasher.isValidPinFormat(newPin)) {
      throw ArgumentError('PIN must be 4 or 6 numeric digits.');
    }
    final pinVerifier = await _hasher.hashSecret(
      newPin,
      runInIsolate: _useIsolateForHashing,
    );
    await _writeKey(_kPinVerifier, pinVerifier);
    await _writeKey(_kPinLength, '${newPin.length}');
    await _writeKey(_kPinEnabled, 'true');

    if (newRecoveryKey != null) {
      final normalized = PinHasher.normalizeRecoveryKey(newRecoveryKey);
      if (!PinHasher.isValidRecoveryKeyFormat(normalized)) {
        throw ArgumentError('Invalid recovery key format.');
      }
      final recoveryVerifier = await _hasher.hashSecret(
        normalized,
        runInIsolate: _useIsolateForHashing,
      );
      await _writeKey(_kRecoveryVerifier, recoveryVerifier);
    }

    await resetFailedAttempts();
    await _recordSecurityAudit(
      newRecoveryKey != null ? 'pin_recovered_or_rotated' : 'pin_changed',
      reason: newRecoveryKey != null
          ? 'Local app PIN reset with fresh recovery key'
          : 'Local app PIN changed by owner',
    );
    return loadSettings();
  }

  @override
  Future<SecuritySettings> updateRecoveryKey(String newRecoveryKey) async {
    final normalized = PinHasher.normalizeRecoveryKey(newRecoveryKey);
    if (!PinHasher.isValidRecoveryKeyFormat(normalized)) {
      throw ArgumentError('Invalid recovery key format.');
    }
    final recoveryVerifier = await _hasher.hashSecret(
      normalized,
      runInIsolate: _useIsolateForHashing,
    );
    await _writeKey(_kRecoveryVerifier, recoveryVerifier);
    await _recordSecurityAudit(
      'recovery_key_regenerated',
      reason: 'Offline recovery key regenerated by owner',
    );
    return loadSettings();
  }

  @override
  Future<SecuritySettings> disablePin() async {
    for (final key in [
      _kPinEnabled,
      _kPinLength,
      _kPinVerifier,
      _kRecoveryVerifier,
      _kBiometricEnabled,
      _kFailedAttempts,
      _kLockoutUntil,
      _kLastBackgrounded,
    ]) {
      await _deleteKey(key);
    }
    await _recordSecurityAudit(
      'pin_disabled',
      reason: 'Local app PIN disabled by owner',
    );
    return loadSettings();
  }

  @override
  Future<SecuritySettings> updatePreferences({
    bool? biometricEnabled,
    LockTimeoutOption? timeout,
    bool? screenshotProtectionEnabled,
  }) async {
    if (biometricEnabled != null) {
      await _writeKey(_kBiometricEnabled, biometricEnabled ? 'true' : 'false');
    }
    if (timeout != null) {
      await _writeKey(_kTimeoutSec, '${timeout.seconds}');
    }
    if (screenshotProtectionEnabled != null) {
      await _writeKey(
        _kFlagSecure,
        screenshotProtectionEnabled ? 'true' : 'false',
      );
    }
    return loadSettings();
  }

  @override
  Future<void> saveLastBackgroundedUtcMillis(int? utcMillis) async {
    if (utcMillis == null) {
      await _deleteKey(_kLastBackgrounded);
    } else {
      await _writeKey(_kLastBackgrounded, '$utcMillis');
    }
  }

  @override
  Future<void> resetFailedAttempts() async {
    await _deleteKey(_kFailedAttempts);
    await _deleteKey(_kLockoutUntil);
  }
}
