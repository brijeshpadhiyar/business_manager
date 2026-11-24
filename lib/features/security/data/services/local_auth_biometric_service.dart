import 'package:business_manager/core/platform/platform_env.dart';
import 'package:business_manager/features/security/domain/entities/security_entities.dart';
import 'package:business_manager/features/security/domain/repositories/security_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

/// Production adapter wrapping `local_auth` v3.x with flat `authenticate()`
/// parameters and typed [LocalAuthException] handling.
///
/// Fails closed on any unsupported platform, cancellation, or error.
@LazySingleton(as: BiometricAuthService)
final class LocalAuthBiometricService implements BiometricAuthService {
  LocalAuthBiometricService() : _auth = LocalAuthentication();

  final LocalAuthentication _auth;

  bool get _isTestEnv => isFlutterTestEnv;

  @override
  Future<BiometricAvailability> checkAvailability() async {
    if (kIsWeb || _isTestEnv) return BiometricAvailability.noHardware;
    try {
      final isSupported = await _auth.isDeviceSupported();
      final canCheck = await _auth.canCheckBiometrics;
      if (!isSupported && !canCheck) {
        return BiometricAvailability.noHardware;
      }
      final enrolled = await _auth.getAvailableBiometrics();
      if (enrolled.isEmpty) {
        return BiometricAvailability.notEnrolled;
      }
      return BiometricAvailability.available;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.noBiometricHardware =>
          BiometricAvailability.noHardware,
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noCredentialsSet =>
          BiometricAvailability.notEnrolled,
        _ => BiometricAvailability.unavailable,
      };
    } catch (_) {
      return BiometricAvailability.unavailable;
    }
  }

  @override
  Future<BiometricAuthOutcome> authenticate({
    required String localizedReason,
  }) async {
    if (kIsWeb) return BiometricAuthOutcome.noHardware;
    try {
      final ok = await _auth.authenticate(
        localizedReason: localizedReason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      return ok ? BiometricAuthOutcome.success : BiometricAuthOutcome.failed;
    } on LocalAuthException catch (e) {
      return switch (e.code) {
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.userRequestedFallback =>
          BiometricAuthOutcome.canceled,
        LocalAuthExceptionCode.noBiometricsEnrolled ||
        LocalAuthExceptionCode.noCredentialsSet =>
          BiometricAuthOutcome.notEnrolled,
        LocalAuthExceptionCode.noBiometricHardware =>
          BiometricAuthOutcome.noHardware,
        LocalAuthExceptionCode.temporaryLockout =>
          BiometricAuthOutcome.temporaryLockout,
        LocalAuthExceptionCode.biometricLockout =>
          BiometricAuthOutcome.permanentLockout,
        _ => BiometricAuthOutcome.failed,
      };
    } catch (_) {
      return BiometricAuthOutcome.failed;
    }
  }
}
