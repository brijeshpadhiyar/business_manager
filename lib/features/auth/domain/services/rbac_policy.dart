import 'package:business_manager/features/auth/domain/entities/auth_entities.dart';

/// Four granular StitchFlow workshop roles enforced in both Supabase RLS
/// (`business_members`) and cached offline UI/navigation guards.
///
/// Offline-only guest users always resolve to [BusinessRole.owner].
enum BusinessRole {
  owner('OWNER'),
  manager('MANAGER'),
  qcInspector('QC_INSPECTOR'),
  accountant('ACCOUNTANT');

  const BusinessRole(this.dbValue);

  final String dbValue;

  static BusinessRole fromDbValue(String? raw) {
    return switch (raw?.toUpperCase().trim()) {
      'MANAGER' => BusinessRole.manager,
      'QC_INSPECTOR' => BusinessRole.qcInspector,
      'ACCOUNTANT' => BusinessRole.accountant,
      _ => BusinessRole.owner,
    };
  }
}

/// Fine-grained capabilities guarded across StitchFlow screens and actions.
enum AppPermission {
  viewLotsAndMasterData,
  editLotsAndMasterData,
  viewWorkerRates,
  editWorkerRates,
  issueAndRouteStock,
  performQcInspection,
  viewAccountingAndKhata,
  recordPaymentsAndAdjustments,
  restoreSyncConflicts,
  manageBusinessProfile,
  manageTeamAndInvites,
  restoreLocalBackup,
}

/// Pure Dart RBAC permission engine (zero Flutter/Drift dependencies).
abstract final class RbacPolicy {
  /// Offline-only local users have full Owner control (`AGENT_RULES.md` #4).
  static BusinessRole effectiveRole(AuthState authState) {
    if (!authState.isAuthenticated) return BusinessRole.owner;
    return authState.user?.role ?? BusinessRole.owner;
  }

  static bool can(BusinessRole role, AppPermission permission) {
    if (role == BusinessRole.owner) return true;
    return switch (role) {
      BusinessRole.owner => true,
      BusinessRole.manager => switch (permission) {
        AppPermission.viewLotsAndMasterData ||
        AppPermission.editLotsAndMasterData ||
        AppPermission.viewWorkerRates ||
        AppPermission.editWorkerRates ||
        AppPermission.issueAndRouteStock ||
        AppPermission.performQcInspection ||
        AppPermission.viewAccountingAndKhata ||
        AppPermission.restoreSyncConflicts => true,
        AppPermission.recordPaymentsAndAdjustments ||
        AppPermission.manageBusinessProfile ||
        AppPermission.manageTeamAndInvites ||
        AppPermission.restoreLocalBackup => false,
      },
      BusinessRole.qcInspector => switch (permission) {
        AppPermission.viewLotsAndMasterData ||
        AppPermission.performQcInspection => true,
        AppPermission.editLotsAndMasterData ||
        AppPermission.viewWorkerRates ||
        AppPermission.editWorkerRates ||
        AppPermission.issueAndRouteStock ||
        AppPermission.viewAccountingAndKhata ||
        AppPermission.recordPaymentsAndAdjustments ||
        AppPermission.restoreSyncConflicts ||
        AppPermission.manageBusinessProfile ||
        AppPermission.manageTeamAndInvites ||
        AppPermission.restoreLocalBackup => false,
      },
      BusinessRole.accountant => switch (permission) {
        AppPermission.viewLotsAndMasterData ||
        AppPermission.viewWorkerRates ||
        AppPermission.viewAccountingAndKhata ||
        AppPermission.recordPaymentsAndAdjustments => true,
        AppPermission.editLotsAndMasterData ||
        AppPermission.editWorkerRates ||
        AppPermission.issueAndRouteStock ||
        AppPermission.performQcInspection ||
        AppPermission.restoreSyncConflicts ||
        AppPermission.manageBusinessProfile ||
        AppPermission.manageTeamAndInvites ||
        AppPermission.restoreLocalBackup => false,
      },
    };
  }
}
