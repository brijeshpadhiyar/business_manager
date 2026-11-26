import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    IstDateTimeHelper.initialize();
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('Schema v10 seeds sync_session_state and captures local writes in outbox',
      () async {
    final session = await db.syncDao.getSessionState();
    expect(session.id, 1);
    expect(session.isApplyingRemote, 0);
    expect(session.deviceId, isNotEmpty);

    // Clear any seeded rows from outbox to isolate our write test.
    await db.syncDao.clearAllOutbox();
    expect(await db.syncDao.getPendingOutboxCount(), 0);

    final now = IstDateTimeHelper.nowUtcMillis();
    await db.into(db.lots).insert(
          LotsCompanion.insert(
            id: 'lot-test-1',
            lotNumber: 'LOT-101',
            transactionAt: now,
            recordedAt: now,
            createdAt: now,
            updatedAt: now,
          ),
        );

    expect(await db.syncDao.getPendingOutboxCount(), 1);
    expect(await db.syncDao.hasPendingOutboxEntry('lots', 'lot-test-1'), isTrue);

    // Updating the same lot coalesces cleanly into the same outbox entry_key.
    await (db.update(db.lots)..where((t) => t.id.equals('lot-test-1'))).write(
      LotsCompanion(
        title: const Value('Updated Cotton Lot'),
        updatedAt: Value(now + 1000),
      ),
    );
    expect(await db.syncDao.getPendingOutboxCount(), 1);
  });

  test('runAsRemoteApply suppresses SQLite triggers so remote pulls never echo',
      () async {
    await db.syncDao.clearAllOutbox();
    final now = IstDateTimeHelper.nowUtcMillis();

    await db.syncDao.runAsRemoteApply(() async {
      await db.syncDao.upsertLocalRowFromRemote('members', {
        'id': 'mem-remote-1',
        'name': 'Rameshbhai',
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
        'business_id': 'biz_ignored_locally',
        'server_updated_at': '2026-11-26T00:00:00Z',
      });
    });

    final member = await db.syncDao.getLocalRowById('members', 'mem-remote-1');
    expect(member, isNotNull);
    expect(member!['name'], 'Rameshbhai');
    expect(await db.syncDao.getPendingOutboxCount(), 0);
  });

  test('enqueueAllLocalRowsForInitialSync queues existing offline rows',
      () async {
    await db.syncDao.clearAllOutbox();
    final now = IstDateTimeHelper.nowUtcMillis();
    await db.syncDao.runAsRemoteApply(() async {
      await db.into(db.lots).insert(
            LotsCompanion.insert(
              id: 'lot-offline-1',
              lotNumber: 'LOT-202',
              transactionAt: now,
              recordedAt: now,
              createdAt: now,
              updatedAt: now,
            ),
          );
    });
    expect(await db.syncDao.getPendingOutboxCount(), 0);

    final enqueued = await db.syncDao.enqueueAllLocalRowsForInitialSync();
    expect(enqueued, greaterThan(0));
    expect(
      await db.syncDao.hasPendingOutboxEntry('lots', 'lot-offline-1'),
      isTrue,
    );
    expect(await db.syncDao.countLocalUserBusinessRows(), greaterThanOrEqualTo(1));
  });
}
