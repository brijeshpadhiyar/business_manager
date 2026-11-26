import 'package:business_manager/features/auth/data/repositories/supabase_team_repository.dart';
import 'package:business_manager/features/auth/domain/entities/auth_entities.dart';
import 'package:business_manager/features/auth/domain/services/rbac_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RbacPolicy 4-role permission matrix', () {
    test('offline guest resolves to Owner with full permissions', () {
      const offline = AuthState(status: AuthStatus.offlineGuest);
      expect(RbacPolicy.effectiveRole(offline), BusinessRole.owner);
      for (final p in AppPermission.values) {
        expect(RbacPolicy.can(BusinessRole.owner, p), isTrue);
      }
    });

    test('Manager has operational & conflict restore rights but no finance write or team admin', () {
      expect(
        RbacPolicy.can(BusinessRole.manager, AppPermission.editLotsAndMasterData),
        isTrue,
      );
      expect(
        RbacPolicy.can(BusinessRole.manager, AppPermission.issueAndRouteStock),
        isTrue,
      );
      expect(
        RbacPolicy.can(BusinessRole.manager, AppPermission.restoreSyncConflicts),
        isTrue,
      );
      expect(
        RbacPolicy.can(
          BusinessRole.manager,
          AppPermission.recordPaymentsAndAdjustments,
        ),
        isFalse,
      );
      expect(
        RbacPolicy.can(BusinessRole.manager, AppPermission.manageTeamAndInvites),
        isFalse,
      );
      expect(
        RbacPolicy.can(BusinessRole.manager, AppPermission.restoreLocalBackup),
        isFalse,
      );
    });

    test('QC Inspector can inspect/view lots but cannot view accounting or issue stock', () {
      expect(
        RbacPolicy.can(BusinessRole.qcInspector, AppPermission.performQcInspection),
        isTrue,
      );
      expect(
        RbacPolicy.can(
          BusinessRole.qcInspector,
          AppPermission.viewLotsAndMasterData,
        ),
        isTrue,
      );
      expect(
        RbacPolicy.can(
          BusinessRole.qcInspector,
          AppPermission.viewAccountingAndKhata,
        ),
        isFalse,
      );
      expect(
        RbacPolicy.can(BusinessRole.qcInspector, AppPermission.issueAndRouteStock),
        isFalse,
      );
    });

    test('Accountant manages payments & khata but cannot mutate stock or QC', () {
      expect(
        RbacPolicy.can(
          BusinessRole.accountant,
          AppPermission.recordPaymentsAndAdjustments,
        ),
        isTrue,
      );
      expect(
        RbacPolicy.can(
          BusinessRole.accountant,
          AppPermission.viewAccountingAndKhata,
        ),
        isTrue,
      );
      expect(
        RbacPolicy.can(BusinessRole.accountant, AppPermission.issueAndRouteStock),
        isFalse,
      );
      expect(
        RbacPolicy.can(BusinessRole.accountant, AppPermission.performQcInspection),
        isFalse,
      );
    });

    test('generated invite codes follow XXXX-XXXX unambiguous format', () {
      final code = SupabaseTeamRepository.generateInviteCode();
      expect(code, matches(RegExp(r'^[A-Z2-9]{4}-[A-Z2-9]{4}$')));
    });
  });
}
