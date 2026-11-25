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

  test('v1 to v3 file-backed migration adds worker_ledger_adjustments, v3 indexes, and preserves v1 data', () async {
    final targetFile = await resolvePrivateDatabaseFile(
      AppConfig.dev(),
      baseDirectoryOverride: tempDir,
    );

    // Simulate a real v1 database on disk (without worker_ledger_adjustments or v3 indexes)
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
    for (final idx in const [
      'idx_sm_tx_type',
      'idx_labour_tx_payable',
      'idx_payments_tx',
      'idx_wla_tx',
      'idx_audit_action_rec',
    ]) {
      await v1Db.customStatement('DROP INDEX IF EXISTS $idx;');
    }
    await v1Db.customStatement('PRAGMA user_version = 1;');
    await v1Db.close();

    // Reopen with current AppDatabase (schemaVersion = 3) -> triggers v1 -> v3 migration
    final v3Db = AppDatabase.forTesting(NativeDatabase(targetFile));
    final pragmas = await v3Db.verifyPragmas();
    expect(pragmas.foreignKeysEnabled, isTrue);

    final userVer = await v3Db.customSelect('PRAGMA user_version;').getSingle();
    expect(
      userVer.read<int>('user_version'),
      DatabaseMigrationManager.currentSchemaVersion,
    );

    // Existing v1 data intact
    final preservedLot = await v3Db.lotDao.findLotById('lot-v1-keep');
    expect(preservedLot?.lotNumber, 'V1-1001');
    final preservedMember = await v3Db.processMemberDao.findMemberById(
      'mem-v1-keep',
    );
    expect(preservedMember?.name, 'Ramesh Bhai');

    // New v2 table & constraints active
    await v3Db.workerAdjustmentDao.insertAdjustment(
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
    final adjList = await v3Db.workerAdjustmentDao.getAdjustmentsForMember(
      'mem-v1-keep',
    );
    expect(adjList.length, 1);
    expect(adjList.first.amountPaise, 50000);

    // All 5 Schema v3 reporting indexes exist in sqlite_master
    final indexRows = await v3Db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index';")
        .get();
    final indexNames = {for (final r in indexRows) r.read<String>('name')};
    expect(
      indexNames,
      containsAll(const [
        'idx_sm_tx_type',
        'idx_labour_tx_payable',
        'idx_payments_tx',
        'idx_wla_tx',
        'idx_audit_action_rec',
      ]),
    );

    await v3Db.close();
  });

  test('v2 to v3 file-backed migration preserves v2 data and creates all 5 v3 reporting indexes', () async {
    final targetFile = await resolvePrivateDatabaseFile(
      AppConfig.prod(),
      baseDirectoryOverride: tempDir,
    );

    // Simulate a real v2 database on disk (has adjustments, lacks v3 indexes)
    final v2Db = AppDatabase.forTesting(NativeDatabase(targetFile));
    await v2Db.verifyPragmas();
    await v2Db.processMemberDao.insertMember(
      const MembersCompanion(
        id: Value('mem-v2-keep'),
        name: Value('Suresh Bhai'),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await v2Db.workerAdjustmentDao.insertAdjustment(
      const WorkerLedgerAdjustmentsCompanion(
        id: Value('adj-v2-keep'),
        memberId: Value('mem-v2-keep'),
        adjustmentType: Value('CREDIT'),
        amountPaise: Value(25000),
        reason: Value('Carried forward'),
        transactionAt: Value(now),
        recordedAt: Value(now),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    for (final idx in const [
      'idx_sm_tx_type',
      'idx_labour_tx_payable',
      'idx_payments_tx',
      'idx_wla_tx',
      'idx_audit_action_rec',
    ]) {
      await v2Db.customStatement('DROP INDEX IF EXISTS $idx;');
    }
    await v2Db.customStatement('PRAGMA user_version = 2;');
    await v2Db.close();

    // Reopen with current AppDatabase (schemaVersion = 3) -> triggers v2 -> v3 migration
    final v3Db = AppDatabase.forTesting(NativeDatabase(targetFile));
    await v3Db.verifyPragmas();

    final userVer = await v3Db.customSelect('PRAGMA user_version;').getSingle();
    expect(
      userVer.read<int>('user_version'),
      DatabaseMigrationManager.currentSchemaVersion,
    );

    // Existing v2 data intact
    final preservedAdj = await v3Db.workerAdjustmentDao.getAdjustmentsForMember(
      'mem-v2-keep',
    );
    expect(preservedAdj.length, 1);
    expect(preservedAdj.first.amountPaise, 25000);

    // All 5 v3 indexes created
    final indexRows = await v3Db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index';")
        .get();
    final indexNames = {for (final r in indexRows) r.read<String>('name')};
    expect(
      indexNames,
      containsAll(const [
        'idx_sm_tx_type',
        'idx_labour_tx_payable',
        'idx_payments_tx',
        'idx_wla_tx',
        'idx_audit_action_rec',
      ]),
    );

    // Verify bounded range DAOs work cleanly
    final rangedAdj = await v3Db.workerAdjustmentDao.getAdjustmentsInRange(
      fromUtcMillis: now - 1000,
      toUtcMillis: now + 1000,
    );
    expect(rangedAdj.length, 1);

    await v3Db.close();
  });
}
