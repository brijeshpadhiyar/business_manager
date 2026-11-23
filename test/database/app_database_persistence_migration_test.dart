import 'dart:io';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/connection/database_connection_native.dart';
import 'package:business_manager/core/database/migrations/database_migration_manager.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  const now = 1795324800000;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bm_db_test_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('resolves separate private DB files for dev and prod flavors', () async {
    final devFile = await resolvePrivateDatabaseFile(
      AppConfig.dev(),
      baseDirectoryOverride: tempDir,
    );
    final prodFile = await resolvePrivateDatabaseFile(
      AppConfig.prod(),
      baseDirectoryOverride: tempDir,
    );

    expect(devFile.path, isNot(equals(prodFile.path)));
    expect(devFile.path, endsWith('business_manager_dev.sqlite'));
    expect(prodFile.path, endsWith('business_manager_prod.sqlite'));
  });

  test(
    'file-backed DB enforces WAL + synchronous=FULL and persists across reopen',
    () async {
      final dbFile = await resolvePrivateDatabaseFile(
        AppConfig.dev(),
        baseDirectoryOverride: tempDir,
      );

      final db1 = AppDatabase.forTesting(NativeDatabase(dbFile));
      final pragmas = await db1.verifyPragmas();
      expect(pragmas.foreignKeysEnabled, isTrue);
      expect(pragmas.isWalMode, isTrue);
      expect(pragmas.isSynchronousFull, isTrue);
      expect(pragmas.busyTimeoutMs, 5000);

      await db1.lotDao.insertLot(
        const LotsCompanion(
          id: Value('lot-persist-1'),
          lotNumber: Value('2001'),
          transactionAt: Value(now),
          recordedAt: Value(now),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await db1.close();

      // Reopen same file and verify data survived close/reopen
      final db2 = AppDatabase.forTesting(NativeDatabase(dbFile));
      final reopenedLot = await db2.lotDao.findLotById('lot-persist-1');
      expect(reopenedLot, isNotNull);
      expect(reopenedLot!.lotNumber, '2001');
      await db2.close();
    },
  );

  test(
    'migration upgrade handler is idempotent and preserves existing data',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.verifyPragmas();

      await db.lotDao.insertLot(
        const LotsCompanion(
          id: Value('lot-mig-1'),
          lotNumber: Value('3001'),
          transactionAt: Value(now),
          recordedAt: Value(now),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      // Invoke upgrade handler directly to verify idempotent index recreation
      await DatabaseMigrationManager.handleOnUpgrade(
        db.createMigrator(),
        db,
        1,
        2,
      );

      final lot = await db.lotDao.findLotById('lot-mig-1');
      expect(lot, isNotNull);
      expect(lot!.lotNumber, '3001');
      await db.close();
    },
  );

  test('v1 to v2 file-backed migration adds worker_ledger_adjustments and preserves v1 data', () async {
    final dbFile = resolvePrivateDatabaseFile(
      AppConfig.dev(),
      baseDirectoryOverride: tempDir,
    );
    final targetFile = await dbFile;

    // Simulate a real v1 database on disk (without worker_ledger_adjustments)
    final v1Db = AppDatabase.forTesting(NativeDatabase(targetFile));
    await v1Db.verifyPragmas();
    await v1Db.lotDao.insertLot(
      const LotsCompanion(
        id: Value('lot-v1-keep'),
        lotNumber: Value('V1-1001'),
        transactionAt: Value(now),
        recordedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await v1Db.processMemberDao.insertMember(
      const MembersCompanion(
        id: Value('mem-v1-keep'),
        name: Value('Ramesh Bhai'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await v1Db.customStatement('DROP TABLE worker_ledger_adjustments;');
    await v1Db.customStatement('PRAGMA user_version = 1;');
    await v1Db.close();

    // Reopen with current AppDatabase (schemaVersion = 2) -> triggers v1 -> v2 migration
    final v2Db = AppDatabase.forTesting(NativeDatabase(targetFile));
    final pragmas = await v2Db.verifyPragmas();
    expect(pragmas.foreignKeysEnabled, isTrue);

    // Existing v1 data intact
    final preservedLot = await v2Db.lotDao.findLotById('lot-v1-keep');
    expect(preservedLot?.lotNumber, 'V1-1001');
    final preservedMember = await v2Db.processMemberDao.findMemberById(
      'mem-v1-keep',
    );
    expect(preservedMember?.name, 'Ramesh Bhai');

    // New v2 table & constraints active
    await v2Db.workerAdjustmentDao.insertAdjustment(
      const WorkerLedgerAdjustmentsCompanion(
        id: Value('adj-v2-1'),
        memberId: Value('mem-v1-keep'),
        adjustmentType: Value('CREDIT'),
        amountPaise: Value(50000),
        reason: Value('Festival bonus'),
        transactionAt: Value(now),
        recordedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    final adjList = await v2Db.workerAdjustmentDao.getAdjustmentsForMember(
      'mem-v1-keep',
    );
    expect(adjList.length, 1);
    expect(adjList.first.amountPaise, 50000);
    await v2Db.close();
  });

  test(
    'v1 to v2 file-backed migration adds worker_ledger_adjustments and preserves v1 data',
    () async {
      final dbFile = resolvePrivateDatabaseFile(
        AppConfig.dev(),
        baseDirectoryOverride: tempDir,
      );
      final targetFile = await dbFile;

      // Simulate a real v1 database on disk (without worker_ledger_adjustments)
      final v1Db = AppDatabase.forTesting(NativeDatabase(targetFile));
      await v1Db.verifyPragmas();
      await v1Db.lotDao.insertLot(
        const LotsCompanion(
          id: Value('lot-v1-keep'),
          lotNumber: Value('V1-1001'),
          transactionAt: Value(now),
          recordedAt: Value(now),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await v1Db.processMemberDao.insertMember(
        const MembersCompanion(
          id: Value('mem-v1-keep'),
          name: Value('Ramesh Bhai'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await v1Db.customStatement('DROP TABLE worker_ledger_adjustments;');
      await v1Db.customStatement('PRAGMA user_version = 1;');
      await v1Db.close();

      // Reopen with current AppDatabase (schemaVersion = 2) -> triggers v1 -> v2 migration
      final v2Db = AppDatabase.forTesting(NativeDatabase(targetFile));
      final pragmas = await v2Db.verifyPragmas();
      expect(pragmas.foreignKeysEnabled, isTrue);

      // Existing v1 data intact
      final preservedLot = await v2Db.lotDao.findLotById('lot-v1-keep');
      expect(preservedLot?.lotNumber, 'V1-1001');
      final preservedMember = await v2Db.processMemberDao.findMemberById(
        'mem-v1-keep',
      );
      expect(preservedMember?.name, 'Ramesh Bhai');

      // New v2 table & constraints active
      await v2Db.workerAdjustmentDao.insertAdjustment(
        const WorkerLedgerAdjustmentsCompanion(
          id: Value('adj-v2-1'),
          memberId: Value('mem-v1-keep'),
          adjustmentType: Value('CREDIT'),
          amountPaise: Value(50000),
          reason: Value('Festival bonus'),
          transactionAt: Value(now),
          recordedAt: Value(now),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      final adjList = await v2Db.workerAdjustmentDao.getAdjustmentsForMember(
        'mem-v1-keep',
      );
      expect(adjList.length, 1);
      expect(adjList.first.amountPaise, 50000);
      await v2Db.close();
    },
  );
}
