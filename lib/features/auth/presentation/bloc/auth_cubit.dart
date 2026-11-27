import 'dart:async';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/features/auth/domain/entities/auth_entities.dart';
import 'package:business_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

/// Root authentication Cubit managing offline-first optional sign-in,
/// Google + Phone OTP login, identity linking, and safe sign-out.
@lazySingleton
final class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._authRepository, this._db)
    : super(AuthState(isCloudConfigured: _authRepository.isCloudConfigured));

  final AuthRepository _authRepository;
  final AppDatabase _db;
  StreamSubscription<AuthUser?>? _sub;

  Future<void> initialize() async {
    final cached = await _authRepository.restoreCachedUser();
    if (cached != null) {
      await _db.syncDao.updateSessionBinding(
        userId: cached.id,
        businessId: cached.businessId,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: cached,
          isCloudConfigured: _authRepository.isCloudConfigured,
          clearError: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          status: AuthStatus.offlineGuest,
          clearUser: true,
          isCloudConfigured: _authRepository.isCloudConfigured,
          clearError: true,
        ),
      );
    }

    _sub ??= _authRepository.watchAuthUser().listen((user) async {
      if (user == null) {
        await _db.syncDao.updateSessionBinding(userId: null, businessId: null);
        emit(
          state.copyWith(
            status: AuthStatus.offlineGuest,
            clearUser: true,
            devices: const [],
          ),
        );
      } else {
        await _db.syncDao.updateSessionBinding(
          userId: user.id,
          businessId: user.businessId,
        );
        emit(
          state.copyWith(
            status: AuthStatus.authenticated,
            user: user,
            clearError: true,
          ),
        );
      }
    });
  }

  /// Explicit offline guest mode — lets user bypass login with zero friction.
  void continueOffline() {
    emit(
      state.copyWith(
        status: AuthStatus.offlineGuest,
        clearUser: true,
        clearPendingOtp: true,
        clearError: true,
      ),
    );
  }

  Future<bool> signInWithGoogle() async {
    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      final user = await _authRepository.signInWithGoogle();
      await _db.syncDao.updateSessionBinding(
        userId: user.id,
        businessId: user.businessId,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isBusy: false,
          clearPendingOtp: true,
          clearError: true,
        ),
      );
      return true;
    } catch (e) {
      emit(state.copyWith(isBusy: false, errorMessage: _cleanError(e)));
      return false;
    }
  }

  Future<bool> sendPhoneOtp(String rawPhone, {bool isLinking = false}) async {
    final e164 = normalizeIndianPhone(rawPhone);
    if (e164 == null) {
      emit(state.copyWith(errorMessage: 'invalid_phone'));
      return false;
    }
    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      if (isLinking) {
        await _authRepository.sendPhoneLinkOtp(e164);
      } else {
        await _authRepository.sendPhoneOtp(e164);
      }
      emit(
        state.copyWith(
          isBusy: false,
          pendingOtpPhone: e164,
          isLinkingPhone: isLinking,
          clearError: true,
        ),
      );
      return true;
    } catch (e) {
      emit(state.copyWith(isBusy: false, errorMessage: _cleanError(e)));
      return false;
    }
  }

  Future<bool> verifyPhoneOtp(String token) async {
    final phone = state.pendingOtpPhone;
    if (phone == null || phone.isEmpty) return false;
    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      final user = state.isLinkingPhone
          ? await _authRepository.verifyPhoneLinkOtp(
              e164Phone: phone,
              token: token.trim(),
            )
          : await _authRepository.verifyPhoneOtp(
              e164Phone: phone,
              token: token.trim(),
            );
      await _db.syncDao.updateSessionBinding(
        userId: user.id,
        businessId: user.businessId,
      );
      emit(
        state.copyWith(
          status: AuthStatus.authenticated,
          user: user,
          isBusy: false,
          clearPendingOtp: true,
          isLinkingPhone: false,
          clearError: true,
        ),
      );
      return true;
    } catch (e) {
      emit(state.copyWith(isBusy: false, errorMessage: _cleanError(e)));
      return false;
    }
  }

  void cancelPendingOtp() {
    emit(
      state.copyWith(
        clearPendingOtp: true,
        isLinkingPhone: false,
        clearError: true,
      ),
    );
  }

  Future<bool> linkGoogleIdentity() async {
    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      final user = await _authRepository.linkGoogleIdentity();
      emit(state.copyWith(user: user, isBusy: false, clearError: true));
      return true;
    } catch (e) {
      emit(state.copyWith(isBusy: false, errorMessage: _cleanError(e)));
      return false;
    }
  }

  Future<void> refreshDevices() async {
    if (!state.isAuthenticated) return;
    try {
      final session = await _db.syncDao.getSessionState();
      final devices = await _authRepository.fetchLinkedDevices(
        currentDeviceId: session.deviceId,
      );
      emit(state.copyWith(devices: devices));
    } catch (_) {
      // Offline: keep last known device list quietly.
    }
  }

  Future<int> getUnsyncedChangesCount() => _db.syncDao.getPendingOutboxCount();

  Future<bool> reauthenticateViaGoogle() =>
      _authRepository.reauthenticateViaGoogle();

  Future<bool> reauthenticateViaPhoneOtp({
    required String rawPhone,
    required String token,
  }) async {
    final e164 = normalizeIndianPhone(rawPhone);
    if (e164 == null) return false;
    return _authRepository.reauthenticateViaPhoneOtp(
      e164Phone: e164,
      token: token.trim(),
    );
  }

  Future<void> signOut() async {
    emit(state.copyWith(isBusy: true, clearError: true));
    try {
      await _authRepository.signOut();
      await _db.syncDao.updateSessionBinding(userId: null, businessId: null);
      emit(
        state.copyWith(
          status: AuthStatus.offlineGuest,
          clearUser: true,
          isBusy: false,
          devices: const [],
          clearPendingOtp: true,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isBusy: false, errorMessage: _cleanError(e)));
    }
  }

  /// Normalizes a 10-digit Indian mobile number (`9876543210`) or full E.164
  /// number (`+919876543210`) into strict E.164 format. Returns `null` if invalid.
  static String? normalizeIndianPhone(String input) {
    final cleaned = input.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.isEmpty) return null;
    if (cleaned.startsWith('+')) {
      final digits = cleaned.substring(1);
      if (RegExp(r'^\d{10,15}$').hasMatch(digits)) return '+$digits';
      return null;
    }
    if (RegExp(r'^\d{10}$').hasMatch(cleaned)) {
      return '+91$cleaned';
    }
    if (RegExp(r'^91\d{10}$').hasMatch(cleaned)) {
      return '+$cleaned';
    }
    return null;
  }

  static String _cleanError(Object error) {
    final text = error.toString();
    return text.replaceFirst(RegExp(r'^(StateError|Exception):\s*'), '');
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
