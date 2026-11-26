import 'package:drift/drift.dart';

/// Additive Schema v10 -> v11 migration for StitchFlow v1.7 Team RBAC,
/// Conflict Inspector indexing, and pre-sync metadata hardening.
///
/// 100% idempotent and non-destructive: preserves every existing local row
/// while adding offline RBAC role caching (`sync_session_state.active_role`,
/// `sync_session_state.active_business_name`, `cached_team_members`) and an
/// index on `audit_logs(reason, recorded_at DESC)` for instant conflict queries.
abstract final class SchemaV11RbacAndHardening {
  static Future<void> run(
    GeneratedDatabase db, {
    required int nowUtcMillis,
  }) async {
    Future<void> addColumnIfMissing(
      String table,
      String column,
      String definition,
    ) async {
      final cols = await db.customSelect('PRAGMA table_info($table);').get();
      final exists = cols.any((r) => r.read<String>('name') == column);
      if (!exists) {
        await db.customStatement(
          'ALTER TABLE $table ADD COLUMN $column $definition;',
        );
      }
    }

    await addColumnIfMissing(
      'sync_session_state',
      'active_role',
      "TEXT NOT NULL DEFAULT 'OWNER'",
    );
    await addColumnIfMissing(
      'sync_session_state',
      'active_business_name',
      'TEXT NULL',
    );

    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS cached_team_members (
        user_id TEXT NOT NULL,
        business_id TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'OWNER',
        status TEXT NOT NULL DEFAULT 'ACTIVE',
        display_name TEXT NULL,
        email TEXT NULL,
        phone TEXT NULL,
        updated_at INTEGER NOT NULL,
        PRIMARY KEY (business_id, user_id),
        CHECK(role IN ('OWNER', 'MANAGER', 'QC_INSPECTOR', 'ACCOUNTANT')),
        CHECK(status IN ('ACTIVE', 'REVOKED'))
      );
    ''');

    await db.customStatement(
      'CREATE INDEX IF NOT EXISTS idx_audit_logs_reason_rec '
      'ON audit_logs(reason, recorded_at DESC);',
    );
  }
}
