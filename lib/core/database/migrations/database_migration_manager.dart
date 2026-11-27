import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/migrations/schema_indexes.dart';
import 'package:business_manager/core/database/migrations/sync_schema.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:drift/drift.dart';

/// Creates the final local schema and seeds its required singleton rows.
///
/// Go-live baseline is schema v11. Older development databases (v1-v10) are
/// not upgraded: opening one fails with [UnsupportedSchemaException], and the
/// app must be reinstalled or restored from a current backup.
abstract final class DatabaseMigrationManager {
  static const int currentSchemaVersion = 11;

  /// Oldest schema this build can open or restore from a backup.
  static const int minimumSupportedSchemaVersion = 11;
  static const String defaultBusinessProfileId = 'default';

  static Future<void> handleOnCreate(Migrator m, AppDatabase db) async {
    await m.createAll();
    for (final statement in SchemaIndexes.allIndexStatements) {
      await db.customStatement(statement);
    }
    final now = IstDateTimeHelper.nowUtcMillis();
    await SyncSchema.seedSessionState(db, nowUtcMillis: now);
    await seedDefaultBusinessProfile(db);
    await seedDefaultColourMaster(db);
    await SyncSchema.installTriggers(db);
  }

  /// Future schema changes (v12+) add additive, idempotent steps here.
  static Future<void> handleOnUpgrade(
    Migrator m,
    AppDatabase db,
    int from,
    int to,
  ) async {
    if (from < minimumSupportedSchemaVersion) {
      throw UnsupportedSchemaException(
        foundVersion: from,
        minimumVersion: minimumSupportedSchemaVersion,
      );
    }

    // Keep idempotent indexes, seeds and sync triggers current.
    for (final statement in SchemaIndexes.allIndexStatements) {
      await db.customStatement(statement);
    }
    await seedDefaultColourMaster(db);
    await SyncSchema.installTriggers(db);
  }

  static Future<void> seedDefaultColourMaster(GeneratedDatabase db) async {
    final now = IstDateTimeHelper.nowUtcMillis();
    const defaults = <(String, String, String)>[
      ('cm-red', 'Red', '#DC2626'),
      ('cm-maroon', 'Maroon', '#7F1D1D'),
      ('cm-navy', 'Navy Blue', '#1E3A8A'),
      ('cm-blue', 'Blue', '#2563EB'),
      ('cm-sky', 'Sky Blue', '#38BDF8'),
      ('cm-teal', 'Teal', '#0D9488'),
      ('cm-green', 'Green', '#16A34A'),
      ('cm-bottle', 'Bottle Green', '#14532D'),
      ('cm-mustard', 'Mustard', '#CA8A04'),
      ('cm-yellow', 'Yellow', '#FACC15'),
      ('cm-orange', 'Orange', '#EA580C'),
      ('cm-peach', 'Peach', '#FDBA74'),
      ('cm-pink', 'Pink', '#EC4899'),
      ('cm-magenta', 'Magenta', '#BE185D'),
      ('cm-purple', 'Purple', '#7C3AED'),
      ('cm-white', 'White', '#FFFFFF'),
      ('cm-ivory', 'Ivory', '#FFFFF0'),
      ('cm-cream', 'Cream', '#FEF3C7'),
      ('cm-beige', 'Beige', '#D6C7AE'),
      ('cm-grey', 'Grey', '#6B7280'),
      ('cm-black', 'Black', '#111827'),
    ];
    for (final (id, name, hex) in defaults) {
      await db.customInsert(
        'INSERT OR IGNORE INTO colour_master '
        '(id, name, hex_code, is_custom, created_at, updated_at) '
        'VALUES (?, ?, ?, 0, ?, ?)',
        variables: [
          Variable<String>(id),
          Variable<String>(name),
          Variable<String>(hex),
          Variable<int>(now),
          Variable<int>(now),
        ],
      );
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
