import 'package:business_manager/features/auth/domain/services/rbac_policy.dart';
import 'package:flutter/foundation.dart';

/// Active or revoked member of a StitchFlow business workspace.
@immutable
final class TeamMemberInfo {
  const TeamMemberInfo({
    required this.userId,
    required this.businessId,
    required this.role,
    required this.status,
    this.displayName,
    this.email,
    this.phone,
    required this.updatedAtUtcMillis,
  });

  final String userId;
  final String businessId;
  final BusinessRole role;
  final String status;
  final String? displayName;
  final String? email;
  final String? phone;
  final int updatedAtUtcMillis;

  bool get isActive => status.toUpperCase() == 'ACTIVE';

  String get bestLabel {
    if (displayName != null && displayName!.trim().isNotEmpty) {
      return displayName!.trim();
    }
    if (email != null && email!.trim().isNotEmpty) return email!.trim();
    if (phone != null && phone!.trim().isNotEmpty) return phone!.trim();
    return userId;
  }
}

/// Shareable WhatsApp-friendly team invite code with expiry & optional lock.
@immutable
final class BusinessInviteInfo {
  const BusinessInviteInfo({
    required this.id,
    required this.businessId,
    required this.code,
    required this.role,
    required this.status,
    required this.expiresAtUtcMillis,
    required this.createdAtUtcMillis,
    this.targetPhone,
    this.targetEmail,
  });

  final String id;
  final String businessId;
  final String code;
  final BusinessRole role;
  final String status;
  final int expiresAtUtcMillis;
  final int createdAtUtcMillis;
  final String? targetPhone;
  final String? targetEmail;

  bool get isPending => status.toUpperCase() == 'PENDING';
}

/// Result returned when a staff user redeems an invite code.
@immutable
final class RedeemedInviteResult {
  const RedeemedInviteResult({
    required this.businessId,
    required this.role,
    this.businessNameEn,
    this.businessNameGu,
  });

  final String businessId;
  final BusinessRole role;
  final String? businessNameEn;
  final String? businessNameGu;
}
