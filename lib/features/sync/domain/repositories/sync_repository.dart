import 'package:business_manager/features/auth/domain/entities/auth_entities.dart';
import 'package:business_manager/features/sync/domain/entities/sync_entities.dart';

/// Pure-Dart domain repository contract isolating Drift/SyncEngine internals
/// from `AuthCubit` and `SyncCubit`.
abstract interface class SyncRepository {
  bool get isCloudConfigured;

  bool get isSyncRunning;

  Future<SyncSessionSummary> getSessionState();

  Future<void> updateSessionBinding({
    required String? userId,
    required String? businessId,
  });

  Stream<int> watchPendingOutboxCount();

  Stream<int> watchPendingMediaCount();

  Future<int> getPendingOutboxCount();

  Future<List<SyncFailedItem>> getFailedOutboxItems();

  Future<int> getUnresolvedConflictCount();

  Future<void> resetFailedItems();

  Future<FirstLoginMergeSummary> inspectFirstLoginMerge(AuthUser user);

  Future<SyncRunSummary> executeFirstLoginMerge(
    AuthUser user,
    FirstLoginMergeChoice choice,
  );

  Future<SyncRunSummary> runSyncCycle(AuthUser user);
}
