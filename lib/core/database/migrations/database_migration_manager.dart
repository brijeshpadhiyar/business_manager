import 'package:business_manager/core/database/migrations/schema_indexes.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:drift/drift.dart';

/// Coordinates initial schema creation, default singleton seeding, and future
/// step-by-step schema upgrades (`v1 -> v2 -> ...`).
abstract final class DatabaseMigrationManager {
  static const int currentSchemaVersion = 1;
  static const String defaultBusinessProfileId = 'default';

  static Future<void> handleOnCreate(Migrator m, GeneratedDatabase db) async {
    await m.createAll();
    for (final statement in SchemaIndexes.v1IndexStatements) {
      await db.customStatement(statement);
    }
    await seedDefaultBusinessProfile(db);
  }

  /// Step-by-step upgrade entrypoint. Future schema changes must increment
  /// [currentSchemaVersion] and add an explicit `if (from < N)` migration block
  /// with matching automated migration tests.
  static Future<void> handleOnUpgrade(
    Migrator m,
    GeneratedDatabase db,
    int from,
    int to,
  ) async {
    // Example template for future schema version 2:
    // if (from < 2) { ... }
    // Always ensure idempotent indexes exist after any upgrade.
    for (final statement in SchemaIndexes.v1IndexStatements) {
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
