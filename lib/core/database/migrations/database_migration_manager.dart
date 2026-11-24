import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/migrations/schema_indexes.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:drift/drift.dart';

/// Coordinates initial schema creation, default singleton seeding, and
/// step-by-step schema upgrades (`v1 -> v2 -> v3 -> v4 -> v5 -> v6`).
abstract final class DatabaseMigrationManager {
  static const int currentSchemaVersion = 6;
  static const String defaultBusinessProfileId = 'default';

  static Future<void> handleOnCreate(Migrator m, AppDatabase db) async {
    await m.createAll();
    for (final statement in SchemaIndexes.allIndexStatements) {
      await db.customStatement(statement);
    }
    await seedDefaultBusinessProfile(db);
    await seedDefaultColourMaster(db);
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

    if (from < 4) {
      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS job_processes (
          id TEXT NOT NULL PRIMARY KEY,
          lot_id TEXT NOT NULL REFERENCES lots(id) ON DELETE RESTRICT,
          lot_design_id TEXT NOT NULL REFERENCES lot_designs(id) ON DELETE RESTRICT,
          design_colour_id TEXT NOT NULL REFERENCES design_colours(id) ON DELETE RESTRICT,
          process_id TEXT NOT NULL REFERENCES processes(id) ON DELETE RESTRICT,
          member_id TEXT NULL REFERENCES members(id) ON DELETE RESTRICT,
          sequence_order INTEGER NOT NULL DEFAULT 1,
          planned_quantity INTEGER NOT NULL,
          dispatched_quantity INTEGER NOT NULL DEFAULT 0,
          received_quantity INTEGER NOT NULL DEFAULT 0,
          returned_to_factory_quantity INTEGER NOT NULL DEFAULT 0,
          transferred_out_quantity INTEGER NOT NULL DEFAULT 0,
          damaged_quantity INTEGER NOT NULL DEFAULT 0,
          status TEXT NOT NULL DEFAULT 'DRAFT',
          source_job_process_id TEXT NULL REFERENCES job_processes(id) ON DELETE RESTRICT,
          linked_issue_movement_id TEXT NULL REFERENCES stock_movements(id) ON DELETE RESTRICT,
          notes TEXT NULL,
          transaction_at INTEGER NOT NULL,
          created_by TEXT NULL,
          updated_by TEXT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER NULL,
          CHECK(planned_quantity > 0),
          CHECK(dispatched_quantity >= 0),
          CHECK(received_quantity >= 0),
          CHECK(returned_to_factory_quantity >= 0),
          CHECK(transferred_out_quantity >= 0),
          CHECK(damaged_quantity >= 0),
          CHECK(status IN ('DRAFT', 'PENDING', 'DISPATCHED', 'IN_PROGRESS', 'PARTIALLY_COMPLETED', 'COMPLETED', 'PARTIALLY_RETURNED', 'RETURNED', 'TRANSFERRED', 'CANCELLED'))
        );
      ''');

      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS process_handovers (
          id TEXT NOT NULL PRIMARY KEY,
          transfer_reference TEXT NOT NULL,
          client_request_id TEXT NULL,
          lot_id TEXT NOT NULL REFERENCES lots(id) ON DELETE RESTRICT,
          lot_design_id TEXT NOT NULL REFERENCES lot_designs(id) ON DELETE RESTRICT,
          design_colour_id TEXT NOT NULL REFERENCES design_colours(id) ON DELETE RESTRICT,
          handover_type TEXT NOT NULL,
          from_job_process_id TEXT NULL REFERENCES job_processes(id) ON DELETE RESTRICT,
          to_job_process_id TEXT NULL REFERENCES job_processes(id) ON DELETE RESTRICT,
          from_member_id TEXT NULL REFERENCES members(id) ON DELETE RESTRICT,
          to_member_id TEXT NULL REFERENCES members(id) ON DELETE RESTRICT,
          process_id TEXT NOT NULL REFERENCES processes(id) ON DELETE RESTRICT,
          quantity_dispatched INTEGER NOT NULL,
          quantity_received INTEGER NOT NULL DEFAULT 0,
          status TEXT NOT NULL DEFAULT 'PENDING_RECEIPT',
          linked_stock_movement_id TEXT NULL REFERENCES stock_movements(id) ON DELETE RESTRICT,
          notes TEXT NULL,
          transaction_at INTEGER NOT NULL,
          recorded_at INTEGER NOT NULL,
          created_by TEXT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          CHECK(handover_type IN ('FACTORY_DISPATCH', 'DIRECT_TRANSFER', 'FACTORY_RETURN', 'REASSIGNMENT', 'CANCELLATION')),
          CHECK(quantity_dispatched >= 0),
          CHECK(quantity_received >= 0),
          CHECK(quantity_received <= quantity_dispatched),
          CHECK(status IN ('PENDING_RECEIPT', 'PARTIALLY_RECEIVED', 'RECEIVED', 'CANCELLED'))
        );
      ''');
    }

    if (from < 5) {
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
        'processes',
        'default_rate_paise',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await addColumnIfMissing(
        'processes',
        'default_pricing_unit',
        "TEXT NOT NULL DEFAULT 'PER_PIECE'",
      );

      await addColumnIfMissing(
        'job_processes',
        'default_rate_paise',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await addColumnIfMissing(
        'job_processes',
        'agreed_rate_paise',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await addColumnIfMissing(
        'job_processes',
        'pricing_unit',
        "TEXT NOT NULL DEFAULT 'PER_PIECE'",
      );
      await addColumnIfMissing(
        'job_processes',
        'rate_override_reason',
        'TEXT NULL',
      );
      await addColumnIfMissing(
        'job_processes',
        'payable_amount_paise',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await addColumnIfMissing(
        'job_processes',
        'paid_amount_paise',
        'INTEGER NOT NULL DEFAULT 0',
      );
      await addColumnIfMissing(
        'job_processes',
        'payment_status',
        "TEXT NOT NULL DEFAULT 'PENDING'",
      );

      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS process_additional_charges (
          id TEXT NOT NULL PRIMARY KEY,
          job_process_id TEXT NOT NULL REFERENCES job_processes(id) ON DELETE RESTRICT,
          lot_id TEXT NOT NULL REFERENCES lots(id) ON DELETE RESTRICT,
          design_colour_id TEXT NOT NULL REFERENCES design_colours(id) ON DELETE RESTRICT,
          member_id TEXT NOT NULL REFERENCES members(id) ON DELETE RESTRICT,
          charge_type TEXT NOT NULL,
          description TEXT NOT NULL,
          amount_paise INTEGER NOT NULL,
          client_request_id TEXT NULL,
          created_by TEXT NULL,
          transaction_at INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          CHECK(charge_type IN ('EXTRA_CHARGE', 'DEDUCTION')),
          CHECK(amount_paise > 0),
          CHECK(length(trim(description)) > 0)
        );
      ''');

      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS process_rate_history (
          id TEXT NOT NULL PRIMARY KEY,
          scope TEXT NOT NULL,
          process_id TEXT NOT NULL REFERENCES processes(id) ON DELETE RESTRICT,
          job_process_id TEXT NULL REFERENCES job_processes(id) ON DELETE RESTRICT,
          member_id TEXT NULL REFERENCES members(id) ON DELETE RESTRICT,
          design_colour_id TEXT NULL REFERENCES design_colours(id) ON DELETE RESTRICT,
          previous_rate_paise INTEGER NOT NULL,
          new_rate_paise INTEGER NOT NULL,
          pricing_unit TEXT NOT NULL,
          reason TEXT NOT NULL,
          changed_by TEXT NULL,
          changed_at INTEGER NOT NULL,
          CHECK(scope IN ('PROCESS_DEFAULT', 'JOB_ASSIGNMENT')),
          CHECK(previous_rate_paise >= 0),
          CHECK(new_rate_paise >= 0),
          CHECK(length(trim(reason)) > 0)
        );
      ''');
    }

    if (from < 6) {
      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS colour_master (
          id TEXT NOT NULL PRIMARY KEY,
          name TEXT NOT NULL,
          hex_code TEXT NOT NULL,
          is_custom INTEGER NOT NULL DEFAULT 0,
          last_used_at INTEGER NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER NULL,
          CHECK(length(trim(name)) > 0),
          CHECK(length(trim(hex_code)) = 7),
          CHECK(is_custom IN (0, 1))
        );
      ''');
    }

    // Ensure all idempotent indexes exist after any upgrade.
    for (final statement in SchemaIndexes.allIndexStatements) {
      await db.customStatement(statement);
    }
    await seedDefaultColourMaster(db);
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
