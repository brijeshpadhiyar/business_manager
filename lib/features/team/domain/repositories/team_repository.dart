import 'package:business_manager/features/auth/domain/services/rbac_policy.dart';
import 'package:business_manager/features/team/domain/entities/team_entities.dart';

/// Domain contract for managing StitchFlow multi-user workshop members,
/// shareable invite codes, and offline cached role state.
abstract interface class TeamRepository {
  bool get isCloudConfigured;

  /// Loads cached local team members first, then refreshes from Supabase when online.
  Future<List<TeamMemberInfo>> loadMembers(String businessId);

  /// Fetches pending & recent invites for [businessId] (Owner only).
  Future<List<BusinessInviteInfo>> loadInvites(String businessId);

  /// Generates a WhatsApp-friendly 8-character expiring join code (`XXXX-XXXX`).
  Future<BusinessInviteInfo> createInvite({
    required String businessId,
    required BusinessRole role,
    String? targetPhone,
    String? targetEmail,
    int validDays = 7,
  });

  /// Revokes a pending invite code.
  Future<void> revokeInvite(String inviteId);

  /// Updates an existing team member's role (`MANAGER`, `QC_INSPECTOR`, `ACCOUNTANT`).
  Future<void> updateMemberRole({
    required String businessId,
    required String userId,
    required BusinessRole role,
  });

  /// Revokes a team member's access to [businessId].
  Future<void> revokeMember({
    required String businessId,
    required String userId,
  });

  /// Redeems an invite code via Supabase RPC `stitchflow_redeem_invite` and
  /// caches the joined workspace role locally.
  Future<RedeemedInviteResult> redeemInviteCode(String code);

  /// Persists the active user's role locally in `sync_session_state`.
  Future<void> cacheActiveRole(BusinessRole role, {String? businessName});
}
