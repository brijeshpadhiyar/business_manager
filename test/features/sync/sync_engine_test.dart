import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_logger.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/auth/domain/entities/auth_entities.dart';
import 'package:business_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:business_manager/features/sync/data/services/sync_engine.dart';
import 'package:business_manager/features/sync/domain/repositories/cloud_sync_gateway.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGateway extends Mock implements CloudSyncGateway {}

class _MockMediaStorage extends Mock implements MediaStorageService {}

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late AppDatabase db;
  late _MockGateway gateway;
  late _MockMediaStorage mediaStorage;
  late _MockAuthRepository authRepo;
  late SyncEngine engine;

  const testUser = AuthUser(
    id: 'user-123',
    businessId: 'biz_user123',
    email: 'owner@stitchflow.app',
  );

  setUp(() {
    IstDateTimeHelper.initialize();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    gateway = _MockGateway();
    mediaStorage = _MockMediaStorage();
    authRepo = _MockAuthRepository();

    when(() => gateway.isConfigured).thenReturn(true);
    when(
      () => gateway.upsertRows(
        tableName: any(named: 'tableName'),
        businessId: any(named: 'businessId'),
        ownerId: any(named: 'ownerId'),
        rows: any(named: 'rows'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => gateway.pullDeltaRows(
        tableName: any(named: 'tableName'),
        businessId: any(named: 'businessId'),
        afterServerUpdatedAt: any(named: 'afterServerUpdatedAt'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => const []);
    when(
      () => gateway.publishSyncNotification(
        businessId: any(named: 'businessId'),
        ownerId: any(named: 'ownerId'),
        deviceId: any(named: 'deviceId'),
        lastTable: any(named: 'lastTable'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => authRepo.registerCurrentDevice(
        deviceId: any(named: 'deviceId'),
        businessId: any(named: 'businessId'),
        lastSyncedAtUtcMillis: any(named: 'lastSyncedAtUtcMillis'),
      ),
    ).thenAnswer((_) async {});

    engine = SyncEngine(
      db,
      gateway,
      mediaStorage,
      authRepo,
      IdGenerator(),
      AppLogger(AppConfig.dev()),
    );
  });

  tearDown(() async {
    await db.close();
  });

  test('pushes local offline writes and pulls remote deltas without echo',
      () async {
    await db.syncDao.clearAllOutbox();
    final now = IstDateTimeHelper.nowUtcMillis();

    // 1. Offline local write captured by SQLite trigger.
    await db.into(db.lots).insert(
          LotsCompanion.insert(
            id: 'lot-sync-1',
            lotNumber: 'LOT-SYNC-01',
            transactionAt: now,
            recordedAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
    expect(await db.syncDao.getPendingOutboxCount(), 1);

    // 2. Stub one remote member delta coming from another device.
    when(
      () => gateway.pullDeltaRows(
        tableName: 'members',
        businessId: testUser.businessId,
        afterServerUpdatedAt: null,
        limit: 500,
      ),
    ).thenAnswer(
      (_) async => [
        {
          'id': 'mem-cloud-1',
          'name': 'Kishorbhai',
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
          'server_updated_at': '2026-11-26T08:00:00Z',
        },
      ],
    );

    final summary = await engine.runSyncCycle(testUser);

    expect(summary.pushedCount, 1);
    expect(summary.pulledCount, 1);
    expect(summary.failedCount, 0);
    expect(await db.syncDao.getPendingOutboxCount(), 0);
    expect(await db.syncDao.getCursor('members'), '2026-11-26T08:00:00Z');

    final pulledMember = await db.syncDao.getLocalRowById(
      'members',
      'mem-cloud-1',
    );
    expect(pulledMember?['name'], 'Kishorbhai');
  });

  test('inspectFirstLoginMerge flags prompt when both local and cloud have data',
      () async {
    final now = IstDateTimeHelper.nowUtcMillis();
    await db.into(db.lots).insert(
          LotsCompanion.insert(
            id: 'lot-local-1',
            lotNumber: 'L-1',
            transactionAt: now,
            recordedAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );
    when(
      () => gateway.countCloudBusinessRows(businessId: testUser.businessId),
    ).thenAnswer((_) async => 3);

    final mergeSummary = await engine.inspectFirstLoginMerge(testUser);
    expect(mergeSummary.needsUserPrompt, isTrue);
    expect(mergeSummary.localRowCount, 1);
    expect(mergeSummary.cloudRowCount, 3);
  });
}
