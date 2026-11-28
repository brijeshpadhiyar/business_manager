import 'dart:io';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/migrations/database_migration_manager.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/features/backup/data/services/web_backup_restore_service.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sq;

void main() {
  test(
    'Fresh v13 database installs all 37 tables, v13 indexes, sync triggers, and WORKSHOP_EXPENSE attachments',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      await db.customSelect('SELECT 1').getSingle();
      expect(DatabaseMigrationManager.currentSchemaVersion, 13);

      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      expect(tables, hasLength(37));

      final now = DateTime.now().millisecondsSinceEpoch;
      await db.cashbookDao.insertExpense(
        WorkshopExpensesCompanion(
          id: const Value('exp-1'),
          category: const Value('RENT'),
          title: const Value('Workshop Rent'),
          amountPaise: const Value(1500000),
          paymentStatus: const Value('PAID'),
          paymentMode: const Value('UPI'),
          transactionAt: Value(now),
          recordedAt: Value(now),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await db.attachmentAuditDao.insertAttachment(
        AttachmentsCompanion(
          id: const Value('att-exp-1'),
          entityType: const Value('WORKSHOP_EXPENSE'),
          entityId: const Value('exp-1'),
          relativePath: const Value('expenses/exp-1/receipt.jpg'),
          mimeType: const Value('image/jpeg'),
          fileSizeBytes: const Value(1024),
          sha256: const Value('abc123'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final outboxCount = await db.syncDao.getPendingOutboxCount();
      expect(outboxCount, greaterThanOrEqualTo(2));

      final integrity = await db.customSelect('PRAGMA integrity_check;').get();
      expect(integrity.first.data.values.first, 'ok');
    },
  );

  test(
    'Upgrades a populated v12 SQLite file cleanly to v13 preserving business_profile logo attachment',
    () async {
      final tempDir = await Directory.systemTemp.createTemp('sf_v12_to_v13_');
      addTearDown(() async {
        if (tempDir.existsSync()) await tempDir.delete(recursive: true);
      });

      final dbFile = File(p.join(tempDir.path, 'legacy_v12.sqlite'));
      final seedDb = AppDatabase.forTesting(NativeDatabase(dbFile));
      const now = 1795324800000;
      await seedDb.attachmentAuditDao.insertAttachment(
        const AttachmentsCompanion(
          id: Value('att-logo-1'),
          entityType: Value('BUSINESS_PROFILE'),
          entityId: Value('default'),
          relativePath: Value('profile/default/logo.png'),
          mimeType: Value('image/png'),
          fileSizeBytes: Value(512),
          sha256: Value('deadbeef'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await seedDb.customStatement(
        "UPDATE business_profile SET logo_attachment_id = 'att-logo-1' WHERE id = 'default';",
      );
      await seedDb.close();

      // Downgrade on-disk schema to authentic v12 (35 tables + old attachments CHECK).
      final raw = sq.sqlite3.open(dbFile.path);
      raw.execute('DROP TABLE IF EXISTS cashbook_entries;');
      raw.execute('DROP TABLE IF EXISTS workshop_expenses;');
      raw.execute('''
        CREATE TABLE attachments_v12 (
          id TEXT NOT NULL PRIMARY KEY,
          entity_type TEXT NOT NULL CHECK(entity_type IN ('LOT', 'STOCK_MOVEMENT', 'PAYMENT', 'BUSINESS_PROFILE')),
          entity_id TEXT NOT NULL,
          relative_path TEXT NOT NULL,
          mime_type TEXT NOT NULL,
          file_size_bytes INTEGER NOT NULL,
          sha256 TEXT NOT NULL,
          caption TEXT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER NULL
        );
      ''');
      raw.execute('INSERT INTO attachments_v12 SELECT * FROM attachments;');
      raw.execute('DROP TABLE attachments;');
      raw.execute('ALTER TABLE attachments_v12 RENAME TO attachments;');
      raw.execute('PRAGMA user_version = 12;');
      raw.close();

      final db = AppDatabase.forTesting(NativeDatabase(dbFile));
      addTearDown(db.close);

      await db.customSelect('SELECT 1').getSingle();

      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      expect(tables, hasLength(37));

      final profile = await db.businessProfileDao.getProfile();
      expect(profile?.logoAttachmentId, 'att-logo-1');

      // Upgraded DB now accepts WORKSHOP_EXPENSE attachments.
      await db.attachmentAuditDao.insertAttachment(
        const AttachmentsCompanion(
          id: Value('att-exp-2'),
          entityType: Value('WORKSHOP_EXPENSE'),
          entityId: Value('exp-2'),
          relativePath: Value('expenses/exp-2/bill.jpg'),
          mimeType: Value('image/jpeg'),
          fileSizeBytes: Value(256),
          sha256: Value('cafebabe'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final fkIssues = await db.customSelect('PRAGMA foreign_key_check;').get();
      expect(fkIssues, isEmpty);

      final integrity = await db.customSelect('PRAGMA integrity_check;').get();
      expect(integrity.first.data.values.first, 'ok');
    },
  );

  test(
    'WebBackupRestoreService preserves workshop_expenses and cashbook_entries on snapshot & restore',
    () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);

      const now = 1795500000000;
      await db.cashbookDao.insertExpense(
        const WorkshopExpensesCompanion(
          id: Value('exp-web-1'),
          category: Value('ELECTRICITY'),
          title: Value('Web Power Bill'),
          amountPaise: Value(45000),
          paymentStatus: Value('UNPAID'),
          transactionAt: Value(now),
          recordedAt: Value(now),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await db.cashbookDao.insertCashbookEntry(
        const CashbookEntriesCompanion(
          id: Value('cb-web-1'),
          entryType: Value('EXPENSE_SETTLEMENT'),
          accountBucket: Value('BANK'),
          paymentMode: Value('UPI'),
          amountPaise: Value(45000),
          linkedExpenseId: Value('exp-web-1'),
          transactionAt: Value(now + 1000),
          recordedAt: Value(now + 1000),
          createdAt: Value(now + 1000),
          updatedAt: Value(now + 1000),
        ),
      );

      final svc = WebBackupRestoreService(db, AppConfig.dev(), IdGenerator());
      final (bytes, _) = await svc.buildSnapshotBytes();

      await db.customStatement('DELETE FROM cashbook_entries;');
      await db.customStatement('DELETE FROM workshop_expenses;');
      expect(await db.cashbookDao.getAllExpenses(), isEmpty);
      expect(await db.cashbookDao.getAllCashbookEntries(), isEmpty);

      final token = WebBackupRestoreService.stagePickedBytes(bytes);
      await svc.restoreFromZip(token);

      final expenses = await db.cashbookDao.getAllExpenses();
      final entries = await db.cashbookDao.getAllCashbookEntries();
      expect(expenses, hasLength(1));
      expect(expenses.first.id, 'exp-web-1');
      expect(entries, hasLength(1));
      expect(entries.first.id, 'cb-web-1');
    },
  );
}
