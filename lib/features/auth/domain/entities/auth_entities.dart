import 'package:business_manager/features/auth/domain/services/rbac_policy.dart';

/// Supported authentication providers in StitchFlow v1.5.
enum AuthIdentityProvider { google, phone }

/// Represents a linked login method on the user's StitchFlow account.
final class LinkedIdentity {
  const LinkedIdentity({
    required this.provider,
    required this.identifier,
    this.identityId,
  });

  final AuthIdentityProvider provider;
  final String identifier;
  final String? identityId;

  Map<String, Object?> toJson() => {
    'provider': provider.name,
    'identifier': identifier,
    'identityId': identityId,
  };

  factory LinkedIdentity.fromJson(Map<String, Object?> json) {
    final providerName = (json['provider'] as String?) ?? 'google';
    return LinkedIdentity(
      provider: providerName == 'phone'
          ? AuthIdentityProvider.phone
          : AuthIdentityProvider.google,
      identifier: (json['identifier'] as String?) ?? '',
      identityId: json['identityId'] as String?,
    );
  }
}

/// Authenticated StitchFlow account (cached securely for offline cold starts).
final class AuthUser {
  const AuthUser({
    required this.id,
    required this.businessId,
    this.role = BusinessRole.owner,
    this.displayName,
    this.email,
    this.phone,
    this.identities = const [],
  });

  final String id;
  final String businessId;
  final BusinessRole role;
  final String? displayName;
  final String? email;
  final String? phone;
  final List<LinkedIdentity> identities;

  bool get hasGoogleLinked =>
      identities.any((i) => i.provider == AuthIdentityProvider.google) ||
      (email != null && email!.isNotEmpty);

  bool get hasPhoneLinked =>
      identities.any((i) => i.provider == AuthIdentityProvider.phone) ||
      (phone != null && phone!.isNotEmpty);

  String get primaryLabel {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    if (email != null && email!.trim().isNotEmpty) return email!.trim();
    if (phone != null && phone!.trim().isNotEmpty) return phone!.trim();
    return id;
  }

  AuthUser copyWith({
    String? id,
    String? businessId,
    BusinessRole? role,
    String? displayName,
    String? email,
    String? phone,
    List<LinkedIdentity>? identities,
  }) {
    return AuthUser(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      identities: identities ?? this.identities,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'businessId': businessId,
    'role': role.dbValue,
    'displayName': displayName,
    'email': email,
    'phone': phone,
    'identities': identities.map((i) => i.toJson()).toList(),
  };

  factory AuthUser.fromJson(Map<String, Object?> json) {
    final rawIdentities = json['identities'] as List<Object?>? ?? const [];
    return AuthUser(
      id: json['id'] as String,
      businessId: json['businessId'] as String,
      role: BusinessRole.fromDbValue(json['role'] as String?),
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      identities: rawIdentities
          .whereType<Map<String, Object?>>()
          .map(LinkedIdentity.fromJson)
          .toList(),
    );
  }
}

/// Device registered under the signed-in owner's StitchFlow account.
final class UserDeviceInfo {
  const UserDeviceInfo({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.appVersion,
    this.lastSyncedAtUtcMillis,
    this.isCurrentDevice = false,
  });

  final String id;
  final String deviceName;
  final String platform;
  final String appVersion;
  final int? lastSyncedAtUtcMillis;
  final bool isCurrentDevice;
}

/// Choice presented when both local offline data and cloud data exist on first login.
enum FirstLoginMergeChoice { mergeBoth, keepCloudOnly, overwriteCloudWithLocal }

enum AuthStatus { initializing, offlineGuest, authenticated }

final class AuthState {
  const AuthState({
    this.status = AuthStatus.initializing,
    this.user,
    this.isCloudConfigured = false,
    this.isBusy = false,
    this.pendingOtpPhone,
    this.isLinkingPhone = false,
    this.devices = const [],
    this.errorMessage,
  });

  final AuthStatus status;
  final AuthUser? user;
  final bool isCloudConfigured;
  final bool isBusy;
  final String? pendingOtpPhone;
  final bool isLinkingPhone;
  final List<UserDeviceInfo> devices;
  final String? errorMessage;

  bool get isAuthenticated =>
      status == AuthStatus.authenticated && user != null;
  bool get isOfflineGuest => status == AuthStatus.offlineGuest;

  AuthState copyWith({
    AuthStatus? status,
    AuthUser? user,
    bool clearUser = false,
    bool? isCloudConfigured,
    bool? isBusy,
    String? pendingOtpPhone,
    bool clearPendingOtp = false,
    bool? isLinkingPhone,
    List<UserDeviceInfo>? devices,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      isCloudConfigured: isCloudConfigured ?? this.isCloudConfigured,
      isBusy: isBusy ?? this.isBusy,
      pendingOtpPhone: clearPendingOtp
          ? null
          : (pendingOtpPhone ?? this.pendingOtpPhone),
      isLinkingPhone: isLinkingPhone ?? this.isLinkingPhone,
      devices: devices ?? this.devices,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
