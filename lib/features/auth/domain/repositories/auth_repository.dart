import 'package:business_manager/features/auth/domain/entities/auth_entities.dart';

/// Domain contract for StitchFlow v1.5 authentication (Google + Phone OTP),
/// identity linking, device registry, and offline session persistence.
abstract interface class AuthRepository {
  bool get isCloudConfigured;

  /// Emits updates whenever the authenticated user changes.
  Stream<AuthUser?> watchAuthUser();

  /// Restores the securely cached user for instant offline cold starts.
  Future<AuthUser?> restoreCachedUser();

  /// Signs in with Google (native GoogleSignIn on mobile, OAuth on desktop/web).
  Future<AuthUser> signInWithGoogle();

  /// Sends a 6-digit SMS OTP to [e164Phone] (e.g. `+919876543210`).
  Future<void> sendPhoneOtp(String e164Phone);

  /// Verifies the SMS OTP and returns the signed-in [AuthUser].
  Future<AuthUser> verifyPhoneOtp({
    required String e164Phone,
    required String token,
  });

  /// Links a Google identity to the currently signed-in account.
  Future<AuthUser> linkGoogleIdentity();

  /// Initiates phone number linking on the currently signed-in account.
  Future<void> sendPhoneLinkOtp(String e164Phone);

  /// Completes phone number linking using the SMS OTP.
  Future<AuthUser> verifyPhoneLinkOtp({
    required String e164Phone,
    required String token,
  });

  /// Lists devices registered under the signed-in owner's account.
  Future<List<UserDeviceInfo>> fetchLinkedDevices({
    required String currentDeviceId,
  });

  /// Registers or updates the current device's heartbeat in `user_devices`.
  Future<void> registerCurrentDevice({
    required String deviceId,
    required String businessId,
    int? lastSyncedAtUtcMillis,
  });

  /// Re-authenticates the signed-in user to authorize local App Lock PIN reset.
  Future<bool> reauthenticateViaGoogle();

  /// Re-authenticates the signed-in user via Phone OTP for PIN reset.
  Future<bool> reauthenticateViaPhoneOtp({
    required String e164Phone,
    required String token,
  });

  /// Signs out of Supabase and clears cached auth session (does not wipe SQLite).
  Future<void> signOut();
}
