import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/migrations/schema_indexes.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:drift/drift.dart';

/// Coordinates initial schema creation, default singleton seeding, and
/// step-by-step schema upgrades (`v1 -> v2 -> ...`).
abstract final class DatabaseMigrationManager {
  static const int currentSchemaVersion = 2;
  static const String defaultBusinessProfileId = 'default';

  static Future<void> handleOnCreate(Migrator m, AppDatabase db) async {
    await m.createAll();
    for (final statement in SchemaIndexes.allIndexStatements) {
      await db.customStatement(statement);
    }
    await seedDefaultBusinessProfile(db);
  }

  /// Step-by-step upgrade entrypoint. Preserves 100% of existing user data
  /// via additive, idempotent DDL statements.
  static Future<void> handleOnUpgrade(
    Migrator m,
    AppDatabase db,
    int from,
    int to,
  ) async {
    if (from < 2) {
      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS worker_ledger_adjustments (
          id TEXT NOT NULL PRIMARY KEY,
          member_id TEXT NOT NULL REFERENCES members(id) ON DELETE RESTRICT,
          adjustment_type TEXT NOT NULL,
          reverses_adjustment_id TEXT NULL REFERENCES worker_ledger_adjustments(id) ON DELETE RESTRICT,
          client_request_id TEXT NULL,
          amount_paise INTEGER NOT NULL,
          reason TEXT NOT NULL,
          notes TEXT NULL,
          transaction_at INTEGER NOT NULL,
          recorded_at INTEGER NOT NULL,
          created_by TEXT NULL,
          updated_by TEXT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER NULL,
          CHECK(adjustment_type IN ('CREDIT', 'DEBIT', 'REVERSAL')),
          CHECK(amount_paise > 0),
          CHECK(length(trim(reason)) > 0)
        );
      ''');
    }

    // Ensure all idempotent indexes exist after any upgrade.
    for (final statement in SchemaIndexes.allIndexStatements) {
      await db.customStatement(statement);
    }
  }

  static Future<void> seedDefaultBusinessProfile(GeneratedDatabase db) async {
    final now = IstDateTimeHelper.nowUtcMillis();
    await db.customInsert(
      'INSERT OR IGNORE INTO business_profile '
      '(id, name_en, name_gu, default_billing_mode, created_at, updated_at) '
      'VALUES (?, ?, ?, ?, ?, ?)',
      variables: [
        const Variable<String>(defaultBusinessProfileId),
        const Variable<String>('Business Manager'),
        const Variable<String>('બિઝનેસ મેનેજર'),
        const Variable<String>('RECEIVED_QTY'),
        Variable<int>(now),
        Variable<int>(now),
      ],
    );
  }
}
