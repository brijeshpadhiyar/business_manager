import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:drift/drift.dart';

/// Cloud-sync support for the local schema: the synced table order, the
/// singleton session-state seed (stable device id), and the guarded SQLite
/// `AFTER INSERT` / `AFTER UPDATE` change-capture triggers on all 23 synced
/// domain tables.
abstract final class SyncSchema {
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
      await db.customStatement('DROP TRIGGER IF EXISTS trg_sync_ins_$table;');
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

      await db.customStatement('DROP TRIGGER IF EXISTS trg_sync_upd_$table;');
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
  Future<void> installV10SyncTriggers() => SyncSchema.installTriggers(this);
}
