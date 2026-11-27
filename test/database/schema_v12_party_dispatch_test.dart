import 'dart:io';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/migrations/database_migration_manager.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sq;

void main() {
  test(
    'Fresh v12 database installs all 35 tables, v12 indexes and sync triggers',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await db.customSelect('SELECT 1').getSingle();
      expect(DatabaseMigrationManager.currentSchemaVersion, 12);

      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      expect(tables, hasLength(35));

      final now = DateTime.now().millisecondsSinceEpoch;
      await db.partyDispatchDao.insertParty(
        PartiesCompanion(
          id: const Value('party-1'),
          name: const Value('Patel Garments'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final outboxCount = await db.syncDao.getPendingOutboxCount();
      expect(outboxCount, greaterThanOrEqualTo(1));

      final integrity = await db.customSelect('PRAGMA integrity_check;').get();
      expect(integrity.first.data.values.first, 'ok');
    },
  );

  test(
    'Upgrades a populated v11 SQLite file cleanly to v12 without data loss',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('sf_v11_to_v12_');
      addTearDown(() async {
        if (tempDir.existsSync()) await tempDir.delete(recursive: true);
      });

      final dbFile = File(p.join(tempDir.path, 'legacy_v11.sqlite'));

      // 1. Seed a real database with a sample lot row, then roll back schema
      // metadata to genuine v11 (28 tables, user_version = 11).
      final seedDb = AppDatabase.forTesting(NativeDatabase(dbFile));
      await seedDb.lotDao.insertLot(
        const LotsCompanion(
          id: Value('lot-legacy-1'),
          lotNumber: Value('L-900'),
          transactionAt: Value(1795324800000),
          recordedAt: Value(1795324800000),
          createdAt: Value(1795324800000),
          updatedAt: Value(1795324800000),
        ),
      );
      await seedDb.close();

      final raw = sq.sqlite3.open(dbFile.path);
      for (final tbl in const [
        'lot_direct_costs',
        'party_payments',
        'buyer_return_items',
        'buyer_returns',
        'dispatch_items',
        'dispatch_challans',
        'parties',
      ]) {
        raw.execute('DROP TABLE IF EXISTS $tbl;');
      }
      raw.execute('PRAGMA user_version = 11;');
      raw.close();

      // 2. Re-open with Drift -> triggers v11 -> v12 upgrade
      final db = AppDatabase.forTesting(NativeDatabase(dbFile));
      addTearDown(db.close);

      final lot = await db.lotDao.findLotById('lot-legacy-1');
      expect(lot?.lotNumber, 'L-900');

      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      expect(tables, hasLength(35));

      final fk = await db.customSelect('PRAGMA foreign_key_check;').get();
      expect(fk, isEmpty);

      final integrity = await db.customSelect('PRAGMA integrity_check;').get();
      expect(integrity.first.data.values.first, 'ok');
    },
  );
}
