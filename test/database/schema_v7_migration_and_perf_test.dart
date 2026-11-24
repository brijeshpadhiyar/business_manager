import 'dart:io';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/connection/database_connection_native.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/database/migrations/database_migration_manager.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/features/lots/data/repositories/lot_repository_impl.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const now = 1795324800000;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sf_v7_mig_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> verifyIntegrityAndSchemaV7(AppDatabase db) async {
    final userVer = await db.customSelect('PRAGMA user_version;').getSingle();
    expect(userVer.read<int>('user_version'), 7);

    final integrity = await db
        .customSelect('PRAGMA integrity_check;')
        .getSingle();
    expect(integrity.data.values.first.toString().toLowerCase(), 'ok');

    final fkViolations = await db
        .customSelect('PRAGMA foreign_key_check;')
        .get();
    expect(fkViolations, isEmpty);

    final tables = await db
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name NOT LIKE 'sqlite_%';",
        )
        .get();
    expect(tables.length, 19);

    final indexes = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'index';")
        .get();
    final idxNames = {for (final r in indexes) r.read<String>('name')};
    expect(
      idxNames,
      containsAll(const [
        'idx_sm_lot_tx',
        'idx_sm_source_rate',
        'idx_lots_active_tx',
        'idx_jp_lot_seq',
        'idx_colour_master_name',
      ]),
    );
  }

  group('Schema v7 Complete Migration Matrix (v1..v6 -> v7 & Fresh v7)', () {
    test(
      'Fresh v7 database passes integrity_check & foreign_key_check',
      () async {
        final file = await resolvePrivateDatabaseFile(
          AppConfig.dev(),
          baseDirectoryOverride: tempDir,
        );
        final db = AppDatabase.forTesting(NativeDatabase(file));
        await db.verifyPragmas();
        await verifyIntegrityAndSchemaV7(db);
        await db.close();
      },
    );

    for (final fromVersion in const [1, 2, 3, 4, 5, 6]) {
      test(
        'Populated file-backed DB migrates cleanly from v$fromVersion -> v7',
        () async {
          final subDir = await Directory('${tempDir.path}/from_v$fromVersion')
              .create(recursive: true);
          final file = await resolvePrivateDatabaseFile(
            AppConfig.prod(),
            baseDirectoryOverride: subDir,
          );

          // Seed realistic records then simulate schema version `fromVersion`
          final seedDb = AppDatabase.forTesting(NativeDatabase(file));
          await seedDb.verifyPragmas();
          await seedDb.lotDao.insertLot(
            LotsCompanion(
              id: Value('lot-v$fromVersion'),
              lotNumber: Value('LOT-V$fromVersion'),
              transactionAt: const Value(now),
              recordedAt: const Value(now),
              createdAt: const Value(now),
              updatedAt: const Value(now),
            ),
          );
          await seedDb.processMemberDao.insertMember(
            MembersCompanion(
              id: Value('mem-v$fromVersion'),
              name: Value('Worker V$fromVersion'),
              createdAt: const Value(now),
              updatedAt: const Value(now),
            ),
          );

          // Drop v7 indexes (and higher-version tables matching `fromVersion`)
          for (final idx in const [
            'idx_sm_lot_tx',
            'idx_sm_source_rate',
            'idx_lots_active_tx',
          ]) {
            await seedDb.customStatement('DROP INDEX IF EXISTS $idx;');
          }
          if (fromVersion < 6) {
            await seedDb.customStatement('DROP TABLE IF EXISTS colour_master;');
          }
          if (fromVersion < 5) {
            await seedDb.customStatement(
              'DROP TABLE IF EXISTS process_additional_charges;',
            );
            await seedDb.customStatement(
              'DROP TABLE IF EXISTS process_rate_history;',
            );
          }
          if (fromVersion < 4) {
            await seedDb.customStatement(
              'DROP TABLE IF EXISTS process_handovers;',
            );
            await seedDb.customStatement('DROP TABLE IF EXISTS job_processes;');
          }
          if (fromVersion < 2) {
            await seedDb.customStatement(
              'DROP TABLE IF EXISTS worker_ledger_adjustments;',
            );
          }
          await seedDb.customStatement('PRAGMA user_version = $fromVersion;');
          await seedDb.close();

          // Reopen with current AppDatabase (v7) -> runs real migration
          final upgraded = AppDatabase.forTesting(NativeDatabase(file));
          final pragmas = await upgraded.verifyPragmas();
          expect(pragmas.foreignKeysEnabled, isTrue);
          expect(pragmas.isWalMode, isTrue);
          expect(pragmas.isSynchronousFull, isTrue);

          await verifyIntegrityAndSchemaV7(upgraded);

          // Verify pre-existing data survived migration intact
          final lot = await upgraded.lotDao.findLotById('lot-v$fromVersion');
          expect(lot?.lotNumber, 'LOT-V$fromVersion');
          final member = await upgraded.processMemberDao.findMemberById(
            'mem-v$fromVersion',
          );
          expect(member?.name, 'Worker V$fromVersion');
          await upgraded.close();
        },
      );
    }
  });

  group('EXPLAIN QUERY PLAN Index Verification & Performance Benchmarks', () {
    test('Verifies SQLite uses v7/v4 indexes and benchmarks optimized queries', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.verifyPragmas();
      final txRunner = DatabaseTransactionRunner(db);
      final idGen = IdGenerator();
      final lotRepo = LotRepositoryImpl(
        db,
        txRunner,
        idGen,
        NativeMediaStorageService(config: AppConfig.dev(), idGenerator: idGen),
      );

      // Seed realistic dataset: 100 lots, target lot with 25 designs x 4 colours (100 SKUs),
      // 1,000 stock movements, 100 job processes
      await db.processMemberDao.insertProcess(
        const ProcessesCompanion(
          id: Value('p-1'),
          name: Value('Cutting'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await db.processMemberDao.insertMember(
        const MembersCompanion(
          id: Value('m-1'),
          name: Value('Dharmesh'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await db.processMemberDao.insertMemberProcessRate(
        const MemberProcessRatesCompanion(
          id: Value('rate-1'),
          memberId: Value('m-1'),
          processId: Value('p-1'),
          ratePaise: Value(500),
          effectiveFrom: Value('2026-01-01'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await db.batch((b) {
        for (var i = 0; i < 100; i++) {
          b.insert(
            db.lots,
            LotsCompanion(
              id: Value('lot-$i'),
              lotNumber: Value('L-$i'),
              transactionAt: Value(now + i * 1000),
              recordedAt: Value(now + i * 1000),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
        }
        for (var d = 0; d < 25; d++) {
          b.insert(
            db.lotDesigns,
            LotDesignsCompanion(
              id: Value('des-$d'),
              lotId: const Value('lot-0'),
              designName: Value('D-${100 + d}'),
              createdAt: const Value(now),
              updatedAt: const Value(now),
            ),
          );
          for (var c = 0; c < 4; c++) {
            b.insert(
              db.designColours,
              DesignColoursCompanion(
                id: Value('col-$d-$c'),
                lotDesignId: Value('des-$d'),
                colourName: Value('Colour-$c'),
                initialQuantity: const Value(100),
                unitPricePaise: const Value(5000),
                createdAt: const Value(now),
                updatedAt: const Value(now),
              ),
            );
          }
        }
        for (var s = 0; s < 1000; s++) {
          final isTarget = s < 100;
          b.insert(
            db.stockMovements,
            StockMovementsCompanion(
              id: Value('sm-$s'),
              lotId: Value(isTarget ? 'lot-0' : 'lot-${(s % 99) + 1}'),
              lotDesignId: const Value('des-0'),
              designColourId: const Value('col-0-0'),
              processId: const Value('p-1'),
              memberId: const Value('m-1'),
              sourceRateId: Value(s == 50 ? 'rate-1' : null),
              movementType: const Value('ISSUE'),
              quantity: const Value(5),
              appliedRatePaise: const Value(500),
              transactionAt: Value(now + s * 100),
              recordedAt: Value(now + s * 100),
              createdAt: const Value(now),
              updatedAt: const Value(now),
            ),
          );
        }
        for (var jp = 0; jp < 100; jp++) {
          b.insert(
            db.jobProcesses,
            JobProcessesCompanion(
              id: Value('jp-$jp'),
              lotId: const Value('lot-0'),
              lotDesignId: const Value('des-0'),
              designColourId: const Value('col-0-0'),
              processId: const Value('p-1'),
              memberId: const Value('m-1'),
              sequenceOrder: Value(jp + 1),
              plannedQuantity: const Value(10),
              transactionAt: const Value(now),
              createdAt: const Value(now),
              updatedAt: const Value(now),
            ),
          );
        }
      });

      Future<String> explain(String sql, List<Variable<Object>> vars) async {
        final rows = await db
            .customSelect('EXPLAIN QUERY PLAN $sql', variables: vars)
            .get();
        return rows.map((r) => r.data.values.join(' ')).join(' | ');
      }

      // 1. EXPLAIN QUERY PLAN assertions (verify index usage)
      final smLotPlan = await explain(
        'SELECT * FROM stock_movements WHERE lot_id = ? '
        'ORDER BY transaction_at ASC, recorded_at ASC, id ASC',
        [const Variable<String>('lot-0')],
      );
      expect(smLotPlan, contains('idx_sm_lot_tx'));

      final smRatePlan = await explain(
        'SELECT * FROM stock_movements WHERE source_rate_id = ? LIMIT 1',
        [const Variable<String>('rate-1')],
      );
      expect(smRatePlan, contains('idx_sm_source_rate'));

      final activeLotsPlan = await explain(
        'SELECT * FROM lots WHERE deleted_at IS NULL '
        'ORDER BY transaction_at DESC',
        const [],
      );
      expect(activeLotsPlan, contains('idx_lots_active_tx'));

      final jpLotPlan = await explain(
        'SELECT * FROM job_processes WHERE lot_id = ? AND deleted_at IS NULL '
        'ORDER BY sequence_order ASC',
        [const Variable<String>('lot-0')],
      );
      expect(jpLotPlan, contains('idx_jp_lot_seq'));

      // 2. Measure real execution times for optimized queries
      final swLotDetail = Stopwatch()..start();
      final detail = (await lotRepo.getLotDetail('lot-0'))!;
      swLotDetail.stop();
      expect(detail.designs.length, 25);
      expect(detail.designs.fold<int>(0, (s, d) => s + d.colours.length), 100);

      final swMovements = Stopwatch()..start();
      final movs = await db.stockMovementDao.getMovementsForLot('lot-0');
      swMovements.stop();
      expect(movs.length, 100);

      final swRateLock = Stopwatch()..start();
      final used = await db.stockMovementDao.hasMovementsUsingRate('rate-1');
      swRateLock.stop();
      expect(used, isTrue);

      final swActiveLots = Stopwatch()..start();
      final activeLots = await db.lotDao.getActiveLots();
      swActiveLots.stop();
      expect(activeLots.length, 100);

      final swNextSeq = Stopwatch()..start();
      final nextSeq = await db.jobProcessDao.getNextSequenceOrderForLot(
        'lot-0',
      );
      swNextSeq.stop();
      expect(nextSeq, 101);

      // Print measured benchmark timings for Phase 4 report
      // ignore: avoid_print
      print(
        'BENCHMARK_V7: '
        'getLotDetail(25d/100c)=${swLotDetail.elapsedMicroseconds}us, '
        'getMovementsForLot(1000_rows)=${swMovements.elapsedMicroseconds}us, '
        'hasMovementsUsingRate(1000_rows)=${swRateLock.elapsedMicroseconds}us, '
        'getActiveLots(100_rows)=${swActiveLots.elapsedMicroseconds}us, '
        'getNextSequenceOrderForLot(100_rows)=${swNextSeq.elapsedMicroseconds}us',
      );

      expect(DatabaseMigrationManager.currentSchemaVersion, 7);
      await db.close();
    });
  });
}
