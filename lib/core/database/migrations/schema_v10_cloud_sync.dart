import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:drift/drift.dart';

/// Additive Schema v9 -> v10 migration for StitchFlow v1.5 Cloud Sync.
///
/// Creates 4 local-only sync tables (`sync_session_state`, `sync_outbox`,
/// `sync_cursors`, `sync_media_queue`), seeds the singleton session state with
/// a stable device UUID, and installs guarded SQLite `AFTER INSERT` /
/// `AFTER UPDATE` triggers on all 23 domain tables.
abstract final class SchemaV10CloudSync {
  /// All 23 synced domain tables in strict Foreign-Key topological push order.
  static const List<String> syncedTablesInPushOrder = [
    'attachments',
    'business_profile',
    'colour_master',
    'processes',
    'members',
    'member_processes',
    'member_process_rates',
    'lots',
    'lot_designs',
    'design_colours',
    'stock_movements',
    'job_processes',
    'process_handovers',
    'process_additional_charges',
    'process_rate_history',
    'labour_entries',
    'payments',
    'worker_ledger_adjustments',
    'production_returns',
    'production_inspections',
    'rejection_records',
    'rejection_repairs',
    'audit_logs',
  ];

  static Future<void> run(
    GeneratedDatabase db, {
    required int nowUtcMillis,
  }) async {
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS sync_session_state (
        id INTEGER NOT NULL PRIMARY KEY DEFAULT 1,
        is_applying_remote INTEGER NOT NULL DEFAULT 0,
        device_id TEXT NOT NULL,
        bound_user_id TEXT NULL,
        bound_business_id TEXT NULL,
        last_full_sync_at INTEGER NULL,
        updated_at INTEGER NOT NULL,
        CHECK(id = 1),
        CHECK(is_applying_remote IN (0, 1))
      );
    ''');

    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS sync_outbox (
        entry_key TEXT NOT NULL PRIMARY KEY,
        table_name TEXT NOT NULL,
        row_id TEXT NOT NULL,
        operation TEXT NOT NULL DEFAULT 'UPSERT',
        enqueued_at INTEGER NOT NULL,
        status TEXT NOT NULL DEFAULT 'PENDING',
        retry_count INTEGER NOT NULL DEFAULT 0,
        next_retry_at INTEGER NULL,
        last_error TEXT NULL,
        CHECK(operation IN ('UPSERT', 'DELETE')),
        CHECK(status IN ('PENDING', 'FAILED')),
        CHECK(retry_count >= 0)
      );
    ''');

    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS sync_cursors (
        table_name TEXT NOT NULL PRIMARY KEY,
        last_server_updated_at TEXT NOT NULL,
        last_pulled_at INTEGER NOT NULL
      );
    ''');

    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS sync_media_queue (
        attachment_id TEXT NOT NULL PRIMARY KEY,
        direction TEXT NOT NULL,
        sha256 TEXT NOT NULL,
        relative_path TEXT NOT NULL,
        remote_path TEXT NULL,
        status TEXT NOT NULL DEFAULT 'PENDING',
        retry_count INTEGER NOT NULL DEFAULT 0,
        next_retry_at INTEGER NULL,
        last_error TEXT NULL,
        updated_at INTEGER NOT NULL,
        CHECK(direction IN ('UPLOAD', 'DOWNLOAD')),
        CHECK(status IN ('PENDING', 'DONE', 'FAILED')),
        CHECK(retry_count >= 0)
      );
    ''');

    await seedSessionState(db, nowUtcMillis: nowUtcMillis);
    await installTriggers(db);
  }

  static Future<void> seedSessionState(
    GeneratedDatabase db, {
    required int nowUtcMillis,
  }) async {
    final deviceId = IdGenerator().nextEntityId();
    await db.customInsert(
      'INSERT OR IGNORE INTO sync_session_state '
      '(id, is_applying_remote, device_id, updated_at) '
      'VALUES (1, 0, ?, ?)',
      variables: [Variable<String>(deviceId), Variable<int>(nowUtcMillis)],
    );
  }

  /// Installs idempotent SQLite change-capture triggers on all 23 synced tables
  /// plus automatic media upload enqueue on local `attachments` inserts.
  static Future<void> installTriggers(GeneratedDatabase db) async {
    for (final table in syncedTablesInPushOrder) {
      await db.customStatement(
        'DROP TRIGGER IF EXISTS trg_sync_ins_$table;',
      );
      await db.customStatement('''
        CREATE TRIGGER trg_sync_ins_$table
        AFTER INSERT ON $table
        WHEN COALESCE((SELECT is_applying_remote FROM sync_session_state WHERE id = 1), 0) = 0
        BEGIN
          INSERT INTO sync_outbox (entry_key, table_name, row_id, operation, enqueued_at, status, retry_count, next_retry_at, last_error)
          VALUES ('$table:' || NEW.id, '$table', NEW.id, 'UPSERT', CAST(strftime('%s','now') AS INTEGER) * 1000, 'PENDING', 0, NULL, NULL)
          ON CONFLICT(entry_key) DO UPDATE SET
            operation = 'UPSERT',
            enqueued_at = excluded.enqueued_at,
            status = 'PENDING',
            retry_count = 0,
            next_retry_at = NULL,
            last_error = NULL;
        END;
      ''');

      await db.customStatement(
        'DROP TRIGGER IF EXISTS trg_sync_upd_$table;',
      );
      await db.customStatement('''
        CREATE TRIGGER trg_sync_upd_$table
        AFTER UPDATE ON $table
        WHEN COALESCE((SELECT is_applying_remote FROM sync_session_state WHERE id = 1), 0) = 0
        BEGIN
          INSERT INTO sync_outbox (entry_key, table_name, row_id, operation, enqueued_at, status, retry_count, next_retry_at, last_error)
          VALUES ('$table:' || NEW.id, '$table', NEW.id, 'UPSERT', CAST(strftime('%s','now') AS INTEGER) * 1000, 'PENDING', 0, NULL, NULL)
          ON CONFLICT(entry_key) DO UPDATE SET
            operation = 'UPSERT',
            enqueued_at = excluded.enqueued_at,
            status = 'PENDING',
            retry_count = 0,
            next_retry_at = NULL,
            last_error = NULL;
        END;
      ''');
    }

    // Automatically enqueue local attachments for cloud Storage upload.
    await db.customStatement(
      'DROP TRIGGER IF EXISTS trg_sync_media_ins_attachments;',
    );
    await db.customStatement('''
      CREATE TRIGGER trg_sync_media_ins_attachments
      AFTER INSERT ON attachments
      WHEN COALESCE((SELECT is_applying_remote FROM sync_session_state WHERE id = 1), 0) = 0
        AND NEW.deleted_at IS NULL
      BEGIN
        INSERT INTO sync_media_queue (attachment_id, direction, sha256, relative_path, status, retry_count, updated_at)
        VALUES (NEW.id, 'UPLOAD', NEW.sha256, NEW.relative_path, 'PENDING', 0, CAST(strftime('%s','now') AS INTEGER) * 1000)
        ON CONFLICT(attachment_id) DO UPDATE SET
          direction = 'UPLOAD',
          sha256 = excluded.sha256,
          relative_path = excluded.relative_path,
          status = 'PENDING',
          retry_count = 0,
          next_retry_at = NULL,
          last_error = NULL,
          updated_at = excluded.updated_at;
      END;
    ''');
  }
}

/// Extension hook so [AppDatabase] can install v10 triggers cleanly on create.
extension AppDatabaseV10Ext on AppDatabase {
  Future<void> installV10SyncTriggers() =>
      SchemaV10CloudSync.installTriggers(this);
}
