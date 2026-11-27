import 'dart:async';
import 'dart:convert';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_identity.dart';
import 'package:business_manager/core/config/app_logger.dart';
import 'package:business_manager/core/platform/platform_env.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/auth/domain/entities/auth_entities.dart';
import 'package:business_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// Supabase-backed implementation of [AuthRepository] supporting:
/// - Native Google Sign-In (`google_sign_in` v7) on Android/iOS + OAuth fallback
/// - Phone Number SMS OTP (`signInWithOtp` + `verifyOTP`)
/// - Account & Identity Linking (Google + Phone on the same StitchFlow user)
/// - Offline-first session caching in `flutter_secure_storage`
@LazySingleton(as: AuthRepository)
final class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(
    this._config,
    this._logger, {
    @ignoreParam FlutterSecureStorage? storageOverride,
  }) : _storage =
           storageOverride ??
           FlutterSecureStorage(
             aOptions: AndroidOptions(
               resetOnError: false,
               migrateOnAlgorithmChange: true,
               storageNamespace: 'sf_${_config.flavor.name}_auth',
             ),
           );

  final AppConfig _config;
  final AppLogger _logger;
  final FlutterSecureStorage _storage;
  final StreamController<AuthUser?> _authController =
      StreamController<AuthUser?>.broadcast();
  StreamSubscription<supa.AuthState>? _supaSub;
  bool _googleInitialized = false;

  final Map<String, String>? _testMemoryStore = isFlutterTestEnv
      ? <String, String>{}
      : null;

  static const String _oauthRedirectUrl =
      '${AppIdentity.urlScheme}://login-callback';

  String get _cachedUserKey => 'sf_${_config.flavor.name}_cached_auth_user';

  @override
  bool get isCloudConfigured => _config.isCloudConfigured;

  supa.SupabaseClient get _client {
    if (!isCloudConfigured) {
      throw StateError(
        'Cloud sync is not configured for this build. '
        'Supply SUPABASE_URL and SUPABASE_ANON_KEY in config/${_config.flavor.name}.local.json.',
      );
    }
    return supa.Supabase.instance.client;
  }

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

  @override
  Stream<AuthUser?> watchAuthUser() {
    _ensureSupabaseListener();
    return _authController.stream;
  }

  void _ensureSupabaseListener() {
    if (_supaSub != null || !isCloudConfigured || isFlutterTestEnv) return;
    try {
      _supaSub = _client.auth.onAuthStateChange.listen((event) async {
        final sessionUser = event.session?.user;
        if (sessionUser == null) {
          if (event.event == supa.AuthChangeEvent.signedOut) {
            await _deleteKey(_cachedUserKey);
            _authController.add(null);
          }
          return;
        }
        final mapped = _mapSupabaseUser(sessionUser);
        await _persistCachedUser(mapped);
        _authController.add(mapped);
      });
    } catch (e) {
      _logger.warning('Supabase auth listener unavailable offline: $e');
    }
  }

  @override
  Future<AuthUser?> restoreCachedUser() async {
    _ensureSupabaseListener();
    // 1. Prefer live Supabase session if initialized and present.
    if (isCloudConfigured && !isFlutterTestEnv) {
      try {
        final liveUser = _client.auth.currentUser;
        if (liveUser != null) {
          final mapped = _mapSupabaseUser(liveUser);
          await _persistCachedUser(mapped);
          return mapped;
        }
      } catch (e) {
        _logger.warning('Falling back to cached offline auth session: $e');
      }
    }
    // 2. Fallback to securely cached offline session.
    final raw = await _readKey(_cachedUserKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw) as Map<String, Object?>;
      return AuthUser.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      clientId: _config.googleIosClientId.isNotEmpty
          ? _config.googleIosClientId
          : null,
      serverClientId: _config.googleWebClientId.isNotEmpty
          ? _config.googleWebClientId
          : null,
    );
    _googleInitialized = true;
  }

  @override
  Future<AuthUser> signInWithGoogle() async {
    final client = _client;
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      await _ensureGoogleInitialized();
      final googleAccount = await GoogleSignIn.instance.authenticate();
      final idToken = googleAccount.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError(
          'Google Sign-In did not return an ID token. Check GOOGLE_WEB_CLIENT_ID configuration.',
        );
      }
      final response = await client.auth.signInWithIdToken(
        provider: supa.OAuthProvider.google,
        idToken: idToken,
      );
      final user = response.user;
      if (user == null) {
        throw StateError('Supabase returned empty user after Google sign-in.');
      }
      final mapped = _mapSupabaseUser(user);
      await _persistCachedUser(mapped);
      _authController.add(mapped);
      return mapped;
    }

    // Desktop / Web OAuth flow via browser redirect (`stitchflow://login-callback`).
    await client.auth.signInWithOAuth(
      supa.OAuthProvider.google,
      redirectTo: kIsWeb ? null : _oauthRedirectUrl,
    );
    final current = client.auth.currentUser;
    if (current == null) {
      throw StateError(
        'Complete Google Sign-In in your browser to finish signing in.',
      );
    }
    final mapped = _mapSupabaseUser(current);
    await _persistCachedUser(mapped);
    _authController.add(mapped);
    return mapped;
  }

  @override
  Future<void> sendPhoneOtp(String e164Phone) async {
    await _client.auth.signInWithOtp(phone: e164Phone);
  }

  @override
  Future<AuthUser> verifyPhoneOtp({
    required String e164Phone,
    required String token,
  }) async {
    final response = await _client.auth.verifyOTP(
      type: supa.OtpType.sms,
      phone: e164Phone,
      token: token,
    );
    final user = response.user;
    if (user == null) {
      throw StateError('Invalid or expired verification code.');
    }
    final mapped = _mapSupabaseUser(user);
    await _persistCachedUser(mapped);
    _authController.add(mapped);
    return mapped;
  }

  @override
  Future<AuthUser> linkGoogleIdentity() async {
    final client = _client;
    await client.auth.linkIdentity(
      supa.OAuthProvider.google,
      redirectTo: kIsWeb ? null : _oauthRedirectUrl,
    );
    final refreshed = await client.auth.getUser();
    final user = refreshed.user ?? client.auth.currentUser;
    if (user == null) {
      throw StateError('Unable to refresh user after linking Google account.');
    }
    final mapped = _mapSupabaseUser(user);
    await _persistCachedUser(mapped);
    _authController.add(mapped);
    return mapped;
  }

  @override
  Future<void> sendPhoneLinkOtp(String e164Phone) async {
    await _client.auth.updateUser(supa.UserAttributes(phone: e164Phone));
  }

  @override
  Future<AuthUser> verifyPhoneLinkOtp({
    required String e164Phone,
    required String token,
  }) async {
    final response = await _client.auth.verifyOTP(
      type: supa.OtpType.phoneChange,
      phone: e164Phone,
      token: token,
    );
    final user = response.user ?? _client.auth.currentUser;
    if (user == null) {
      throw StateError('Unable to verify phone number change.');
    }
    final mapped = _mapSupabaseUser(user);
    await _persistCachedUser(mapped);
    _authController.add(mapped);
    return mapped;
  }

  @override
  Future<List<UserDeviceInfo>> fetchLinkedDevices({
    required String currentDeviceId,
  }) async {
    if (!isCloudConfigured) return const [];
    final client = _client;
    final user = client.auth.currentUser;
    if (user == null) return const [];

    final rows = await client
        .from('user_devices')
        .select()
        .eq('user_id', user.id)
        .order('updated_at', ascending: false);

    return (rows as List<dynamic>).map((item) {
      final map = item as Map<String, dynamic>;
      final id = map['id'] as String;
      return UserDeviceInfo(
        id: id,
        deviceName: (map['device_name'] as String?) ?? 'Device',
        platform: (map['platform'] as String?) ?? 'unknown',
        appVersion: (map['app_version'] as String?) ?? AppIdentity.appVersion,
        lastSyncedAtUtcMillis: (map['last_synced_at'] as num?)?.toInt(),
        isCurrentDevice: id == currentDeviceId,
      );
    }).toList();
  }

  @override
  Future<void> registerCurrentDevice({
    required String deviceId,
    required String businessId,
    int? lastSyncedAtUtcMillis,
  }) async {
    if (!isCloudConfigured) return;
    final client = _client;
    final user = client.auth.currentUser;
    if (user == null) return;

    final deviceName = await _resolveDeviceName();
    final now = IstDateTimeHelper.nowUtcMillis();
    await client.from('user_devices').upsert({
      'id': deviceId,
      'user_id': user.id,
      'business_id': businessId,
      'device_name': deviceName,
      'platform': kIsWeb ? 'web' : defaultTargetPlatform.name,
      'app_version': '${AppIdentity.appVersion}+${AppIdentity.appBuildNumber}',
      'last_synced_at': lastSyncedAtUtcMillis,
      'updated_at': now,
    }, onConflict: 'id');
  }

  @override
  Future<bool> reauthenticateViaGoogle() async {
    final current = await restoreCachedUser();
    if (current == null) return false;
    final reauthed = await signInWithGoogle();
    return reauthed.id == current.id;
  }

  @override
  Future<bool> reauthenticateViaPhoneOtp({
    required String e164Phone,
    required String token,
  }) async {
    final current = await restoreCachedUser();
    if (current == null) return false;
    final reauthed = await verifyPhoneOtp(e164Phone: e164Phone, token: token);
    return reauthed.id == current.id;
  }

  @override
  Future<void> signOut() async {
    await _deleteKey(_cachedUserKey);
    if (isCloudConfigured && !isFlutterTestEnv) {
      try {
        await _client.auth.signOut();
      } catch (e) {
        _logger.warning('Remote signOut failed while offline: $e');
      }
      if (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS)) {
        try {
          if (_googleInitialized) {
            await GoogleSignIn.instance.signOut();
          }
        } catch (_) {}
      }
    }
    _authController.add(null);
  }

  Future<void> _persistCachedUser(AuthUser user) async {
    await _writeKey(_cachedUserKey, jsonEncode(user.toJson()));
  }

  AuthUser _mapSupabaseUser(supa.User user) {
    final businessId = 'biz_${user.id.replaceAll('-', '')}';
    final identities = <LinkedIdentity>[];
    for (final identity in user.identities ?? const <supa.UserIdentity>[]) {
      if (identity.provider == 'google') {
        identities.add(
          LinkedIdentity(
            provider: AuthIdentityProvider.google,
            identifier:
                (identity.identityData?['email'] as String?) ??
                user.email ??
                'Google',
            identityId: identity.identityId,
          ),
        );
      } else if (identity.provider == 'phone') {
        identities.add(
          LinkedIdentity(
            provider: AuthIdentityProvider.phone,
            identifier:
                (identity.identityData?['phone'] as String?) ??
                user.phone ??
                'Phone',
            identityId: identity.identityId,
          ),
        );
      }
    }

    final meta = user.userMetadata;
    final displayName =
        (meta?['full_name'] as String?) ?? (meta?['name'] as String?);

    return AuthUser(
      id: user.id,
      businessId: businessId,
      displayName: displayName,
      email: user.email,
      phone: user.phone,
      identities: identities,
    );
  }

  Future<String> _resolveDeviceName() async {
    if (isFlutterTestEnv) return 'Test Device';
    try {
      final plugin = DeviceInfoPlugin();
      if (kIsWeb) {
        final web = await plugin.webBrowserInfo;
        return web.browserName.name;
      }
      return switch (defaultTargetPlatform) {
        TargetPlatform.android => (await plugin.androidInfo).model,
        TargetPlatform.iOS => (await plugin.iosInfo).utsname.machine,
        TargetPlatform.windows => (await plugin.windowsInfo).computerName,
        TargetPlatform.macOS => (await plugin.macOsInfo).computerName,
        TargetPlatform.linux => (await plugin.linuxInfo).prettyName,
        TargetPlatform.fuchsia => 'Fuchsia',
      };
    } catch (_) {
      return 'StitchFlow Device';
    }
  }
}
