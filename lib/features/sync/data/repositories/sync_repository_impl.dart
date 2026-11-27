import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/features/auth/domain/entities/auth_entities.dart';
import 'package:business_manager/features/sync/data/services/sync_engine.dart';
import 'package:business_manager/features/sync/domain/entities/sync_entities.dart';
import 'package:business_manager/features/sync/domain/repositories/sync_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: SyncRepository)
final class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl(this._db, this._engine);

  final AppDatabase _db;
  final SyncEngine _engine;

  @override
  bool get isCloudConfigured => _engine.isCloudConfigured;

  @override
  bool get isSyncRunning => _engine.isRunning;

  @override
  Future<SyncSessionSummary> getSessionState() async {
    final row = await _db.syncDao.getSessionState();
    return SyncSessionSummary(
      deviceId: row.deviceId,
      boundUserId: row.boundUserId,
      boundBusinessId: row.boundBusinessId,
      lastFullSyncAt: row.lastFullSyncAt,
    );
  }

  @override
  Future<void> updateSessionBinding({
    required String? userId,
    required String? businessId,
  }) => _db.syncDao.updateSessionBinding(
    userId: userId,
    businessId: businessId,
  );

  @override
  Stream<int> watchPendingOutboxCount() =>
      _db.syncDao.watchPendingOutboxCount();

  @override
  Stream<int> watchPendingMediaCount() => _db.syncDao.watchPendingMediaCount();

  @override
  Future<int> getPendingOutboxCount() => _db.syncDao.getPendingOutboxCount();

  @override
  Future<List<SyncFailedItem>> getFailedOutboxItems() async {
    final rows = await _db.syncDao.getFailedOutboxItems();
    return rows
        .map(
          (r) => SyncFailedItem(
            entryKey: r.entryKey,
            tableName: r.tableNameCol,
            rowId: r.rowId,
            retryCount: r.retryCount,
            lastError: r.lastError ?? 'Unknown sync error',
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> resetFailedItems() async {
    await _db.syncDao.resetFailedOutboxItems();
    await _db.syncDao.resetFailedMediaItems();
  }

  @override
  Future<FirstLoginMergeSummary> inspectFirstLoginMerge(AuthUser user) =>
      _engine.inspectFirstLoginMerge(user);

  @override
  Future<SyncRunSummary> executeFirstLoginMerge(
    AuthUser user,
    FirstLoginMergeChoice choice,
  ) => _engine.executeFirstLoginMerge(user, choice);

  @override
  Future<SyncRunSummary> runSyncCycle(AuthUser user) =>
      _engine.runSyncCycle(user);
}
