import 'dart:io';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/connection/database_connection_native.dart';
import 'package:business_manager/core/database/migrations/database_migration_manager.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const now = 1795324800000;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sf_v8_mig_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Schema v8 Production History Migration & Query Plan Verification', () {
    test(
      'Populated v7 database migrates cleanly to v8 preserving 100% legacy data & FKs',
      () async {
        final file = await resolvePrivateDatabaseFile(
          AppConfig.prod(),
          baseDirectoryOverride: tempDir,
        );

        // Seed realistic legacy v7 records
        final seedDb = AppDatabase.forTesting(NativeDatabase(file));
        await seedDb.verifyPragmas();

        await seedDb.lotDao.insertLot(
          LotsCompanion(
            id: const Value('lot-legacy-1'),
            lotNumber: const Value('LOT-LEGACY-01'),
            title: const Value('Pre-v8 Cotton Kurti'),
            transactionAt: const Value(now),
            recordedAt: const Value(now),
            createdAt: const Value(now),
            updatedAt: const Value(now),
          ),
        );
        await seedDb.lotDao.insertDesign(
          LotDesignsCompanion(
            id: const Value('des-legacy-1'),
            lotId: const Value('lot-legacy-1'),
            designName: const Value('Floral Kurti'),
            createdAt: const Value(now),
            updatedAt: const Value(now),
          ),
        );
        await seedDb.lotDao.insertDesignColour(
          DesignColoursCompanion(
            id: const Value('col-legacy-1'),
            lotDesignId: const Value('des-legacy-1'),
            colourName: const Value('Red'),
            initialQuantity: const Value(100),
            unitPricePaise: const Value(50000),
            createdAt: const Value(now),
            updatedAt: const Value(now),
          ),
        );
        await seedDb.processMemberDao.insertProcess(
          ProcessesCompanion(
            id: const Value('proc-legacy-1'),
            name: const Value('Stitching'),
            createdAt: const Value(now),
            updatedAt: const Value(now),
          ),
        );
        await seedDb.processMemberDao.insertMember(
          MembersCompanion(
            id: const Value('mem-legacy-1'),
            name: const Value('Rameshbhai'),
            createdAt: const Value(now),
            updatedAt: const Value(now),
          ),
        );

        // Downgrade DB to simulate an authentic v7 database on disk
        await seedDb.customStatement('PRAGMA foreign_keys = OFF;');
        for (final table in const [
          'rejection_repairs',
          'rejection_records',
          'production_inspections',
          'production_returns',
        ]) {
          await seedDb.customStatement('DROP TABLE IF EXISTS $table;');
        }
        await seedDb.customStatement('DROP INDEX IF EXISTS idx_sm_job_process;');
        await seedDb.customStatement('PRAGMA user_version = 7;');
        await seedDb.customStatement('PRAGMA foreign_keys = ON;');
        await seedDb.close();

        // Re-open with AppDatabase -> triggers v7 -> v8 migration
        final migratedDb = AppDatabase.forTesting(NativeDatabase(file));
        await migratedDb.verifyPragmas();

        final ver = await migratedDb
            .customSelect('PRAGMA user_version;')
            .getSingle();
        expect(
          ver.read<int>('user_version'),
          DatabaseMigrationManager.currentSchemaVersion,
        );

        final integrity = await migratedDb
            .customSelect('PRAGMA integrity_check;')
            .getSingle();
        expect(integrity.data.values.first.toString().toLowerCase(), 'ok');

        final fkViolations = await migratedDb
            .customSelect('PRAGMA foreign_key_check;')
            .get();
        expect(fkViolations, isEmpty);

        // Verify all 4 v8 tables & key v8 indexes exist
        final tables = await migratedDb
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%';",
            )
            .get();
        final tableNames = {for (final r in tables) r.read<String>('name')};
        expect(
          tableNames,
          containsAll(const [
            'production_returns',
            'production_inspections',
            'rejection_records',
            'rejection_repairs',
          ]),
        );

        final indexes = await migratedDb
            .customSelect("SELECT name FROM sqlite_master WHERE type = 'index';")
            .get();
        final idxNames = {for (final r in indexes) r.read<String>('name')};
        expect(
          idxNames,
          containsAll(const [
            'idx_sm_job_process',
            'idx_pr_issue',
            'idx_pr_lot_tx',
            'idx_pi_return',
            'idx_pi_issue',
            'idx_rr_lot_status',
            'idx_rep_rejection',
          ]),
        );

        // Verify 100% legacy data survived intact
        final lot = await migratedDb.lotDao.findLotById('lot-legacy-1');
        expect(lot, isNotNull);
        expect(lot!.lotNumber, 'LOT-LEGACY-01');
        final member = await migratedDb.processMemberDao.findMemberById(
          'mem-legacy-1',
        );
        expect(member?.name, 'Rameshbhai');

        // Verify EXPLAIN QUERY PLAN uses indexes on hot queries (no full table scan)
        final planSm = await migratedDb
            .customSelect(
              "EXPLAIN QUERY PLAN SELECT * FROM stock_movements WHERE lot_id = 'lot-legacy-1' ORDER BY transaction_at ASC;",
            )
            .get();
        final planSmText = planSm.map((r) => r.data.values.join(' ')).join('\n');
        expect(planSmText.toUpperCase(), contains('INDEX'));

        final planPr = await migratedDb
            .customSelect(
              "EXPLAIN QUERY PLAN SELECT * FROM production_returns WHERE parent_issue_id = 'iss-1';",
            )
            .get();
        final planPrText = planPr.map((r) => r.data.values.join(' ')).join('\n');
        expect(planPrText.toUpperCase(), contains('INDEX'));

        await migratedDb.close();
      },
    );
  });
}
