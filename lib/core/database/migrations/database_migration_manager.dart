import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/migrations/schema_indexes.dart';
import 'package:business_manager/core/database/migrations/schema_v10_cloud_sync.dart';
import 'package:business_manager/core/database/migrations/schema_v11_rbac_and_hardening.dart';
import 'package:business_manager/core/database/migrations/schema_v9_ledger_unification.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:drift/drift.dart';

/// Coordinates initial schema creation, default singleton seeding, and
/// step-by-step schema upgrades (`v1 -> ... -> v10 -> v11`).
abstract final class DatabaseMigrationManager {
  static const int currentSchemaVersion = 11;
  static const String defaultBusinessProfileId = 'default';

  static Future<void> handleOnCreate(Migrator m, AppDatabase db) async {
    await m.createAll();
    for (final statement in SchemaIndexes.allIndexStatements) {
      await db.customStatement(statement);
    }
    final now = IstDateTimeHelper.nowUtcMillis();
    await SchemaV10CloudSync.seedSessionState(db, nowUtcMillis: now);
    await seedDefaultBusinessProfile(db);
    await seedDefaultColourMaster(db);
    await SchemaV10CloudSync.installTriggers(db);
    await SchemaV11RbacAndHardening.run(db, nowUtcMillis: now);
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

    if (from < 8) {
      final smCols = await db
          .customSelect('PRAGMA table_info(stock_movements);')
          .get();
      final hasJobProcessId = smCols.any(
        (r) => r.read<String>('name') == 'job_process_id',
      );
      if (!hasJobProcessId) {
        await db.customStatement(
          'ALTER TABLE stock_movements ADD COLUMN job_process_id TEXT NULL;',
        );
      }

      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS production_returns (
          id TEXT NOT NULL PRIMARY KEY,
          client_request_id TEXT NULL,
          parent_issue_id TEXT NOT NULL REFERENCES stock_movements(id) ON DELETE RESTRICT,
          job_process_id TEXT NULL REFERENCES job_processes(id) ON DELETE RESTRICT,
          lot_id TEXT NOT NULL REFERENCES lots(id) ON DELETE RESTRICT,
          lot_design_id TEXT NOT NULL REFERENCES lot_designs(id) ON DELETE RESTRICT,
          design_colour_id TEXT NOT NULL REFERENCES design_colours(id) ON DELETE RESTRICT,
          process_id TEXT NOT NULL REFERENCES processes(id) ON DELETE RESTRICT,
          member_id TEXT NOT NULL REFERENCES members(id) ON DELETE RESTRICT,
          returned_quantity INTEGER NOT NULL,
          return_mode TEXT NOT NULL DEFAULT 'PENDING_INSPECTION',
          notes TEXT NULL,
          transaction_at INTEGER NOT NULL,
          recorded_at INTEGER NOT NULL,
          created_by TEXT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          deleted_at INTEGER NULL,
          CHECK(returned_quantity > 0),
          CHECK(return_mode IN ('PENDING_INSPECTION', 'IMMEDIATE_INSPECTION'))
        );
      ''');

      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS production_inspections (
          id TEXT NOT NULL PRIMARY KEY,
          client_request_id TEXT NULL,
          inspection_type TEXT NOT NULL DEFAULT 'INITIAL',
          production_return_id TEXT NULL REFERENCES production_returns(id) ON DELETE RESTRICT,
          rejection_record_id TEXT NULL,
          rejection_repair_id TEXT NULL,
          parent_issue_id TEXT NOT NULL REFERENCES stock_movements(id) ON DELETE RESTRICT,
          job_process_id TEXT NULL REFERENCES job_processes(id) ON DELETE RESTRICT,
          lot_id TEXT NOT NULL REFERENCES lots(id) ON DELETE RESTRICT,
          lot_design_id TEXT NOT NULL REFERENCES lot_designs(id) ON DELETE RESTRICT,
          design_colour_id TEXT NOT NULL REFERENCES design_colours(id) ON DELETE RESTRICT,
          process_id TEXT NOT NULL REFERENCES processes(id) ON DELETE RESTRICT,
          member_id TEXT NOT NULL REFERENCES members(id) ON DELETE RESTRICT,
          accepted_quantity INTEGER NOT NULL DEFAULT 0,
          rejected_quantity INTEGER NOT NULL DEFAULT 0,
          locked_rate_paise INTEGER NOT NULL DEFAULT 0,
          earned_amount_paise INTEGER NOT NULL DEFAULT 0,
          credit_worker_earnings INTEGER NOT NULL DEFAULT 1,
          linked_good_movement_id TEXT NULL REFERENCES stock_movements(id) ON DELETE RESTRICT,
          linked_damaged_movement_id TEXT NULL REFERENCES stock_movements(id) ON DELETE RESTRICT,
          linked_labour_entry_id TEXT NULL REFERENCES labour_entries(id) ON DELETE RESTRICT,
          rejection_reason TEXT NULL,
          notes TEXT NULL,
          inspected_by TEXT NULL,
          approved_by TEXT NULL,
          authorized_via_pin INTEGER NOT NULL DEFAULT 0,
          transaction_at INTEGER NOT NULL,
          recorded_at INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          CHECK(inspection_type IN ('INITIAL', 'REINSPECTION')),
          CHECK(accepted_quantity >= 0),
          CHECK(rejected_quantity >= 0),
          CHECK(accepted_quantity + rejected_quantity > 0),
          CHECK(locked_rate_paise >= 0),
          CHECK(earned_amount_paise >= 0),
          CHECK(credit_worker_earnings IN (0, 1)),
          CHECK(authorized_via_pin IN (0, 1))
        );
      ''');

      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS rejection_records (
          id TEXT NOT NULL PRIMARY KEY,
          lot_id TEXT NOT NULL REFERENCES lots(id) ON DELETE RESTRICT,
          lot_design_id TEXT NOT NULL REFERENCES lot_designs(id) ON DELETE RESTRICT,
          design_colour_id TEXT NOT NULL REFERENCES design_colours(id) ON DELETE RESTRICT,
          process_id TEXT NOT NULL REFERENCES processes(id) ON DELETE RESTRICT,
          member_id TEXT NOT NULL REFERENCES members(id) ON DELETE RESTRICT,
          parent_issue_id TEXT NOT NULL REFERENCES stock_movements(id) ON DELETE RESTRICT,
          job_process_id TEXT NULL REFERENCES job_processes(id) ON DELETE RESTRICT,
          production_return_id TEXT NULL REFERENCES production_returns(id) ON DELETE RESTRICT,
          inspection_id TEXT NOT NULL REFERENCES production_inspections(id) ON DELETE RESTRICT,
          stock_movement_id TEXT NOT NULL REFERENCES stock_movements(id) ON DELETE RESTRICT,
          rejected_quantity INTEGER NOT NULL,
          rejection_reason TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'OPEN',
          inspected_at INTEGER NOT NULL,
          recorded_by TEXT NULL,
          notes TEXT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          CHECK(rejected_quantity > 0),
          CHECK(length(trim(rejection_reason)) > 0),
          CHECK(status IN ('OPEN', 'PARTIALLY_REPAIRED', 'REPAIRED_PENDING_INSPECTION', 'PARTIALLY_REAPPROVED', 'REAPPROVED', 'SCRAPPED'))
        );
      ''');

      await db.customStatement('''
        CREATE TABLE IF NOT EXISTS rejection_repairs (
          id TEXT NOT NULL PRIMARY KEY,
          client_request_id TEXT NULL,
          rejection_record_id TEXT NOT NULL REFERENCES rejection_records(id) ON DELETE RESTRICT,
          lot_id TEXT NOT NULL REFERENCES lots(id) ON DELETE RESTRICT,
          design_colour_id TEXT NOT NULL REFERENCES design_colours(id) ON DELETE RESTRICT,
          process_id TEXT NOT NULL REFERENCES processes(id) ON DELETE RESTRICT,
          member_id TEXT NOT NULL REFERENCES members(id) ON DELETE RESTRICT,
          repaired_quantity INTEGER NOT NULL,
          repair_source TEXT NOT NULL DEFAULT 'ORIGINAL_WORKER',
          status TEXT NOT NULL DEFAULT 'PENDING_REINSPECTION',
          repaired_by TEXT NULL,
          notes TEXT NULL,
          transaction_at INTEGER NOT NULL,
          recorded_at INTEGER NOT NULL,
          created_at INTEGER NOT NULL,
          updated_at INTEGER NOT NULL,
          CHECK(repaired_quantity > 0),
          CHECK(repair_source IN ('ORIGINAL_WORKER', 'IN_HOUSE')),
          CHECK(status IN ('PENDING_REINSPECTION', 'PARTIALLY_REINSPECTED', 'COMPLETED'))
        );
      ''');
    }

    if (from < 9) {
      await SchemaV9LedgerUnification.run(
        db,
        nowUtcMillis: IstDateTimeHelper.nowUtcMillis(),
      );
    }

    if (from < 10) {
      await SchemaV10CloudSync.run(
        db,
        nowUtcMillis: IstDateTimeHelper.nowUtcMillis(),
      );
    }

    if (from < 11) {
      await SchemaV11RbacAndHardening.run(
        db,
        nowUtcMillis: IstDateTimeHelper.nowUtcMillis(),
      );
    }

    // Ensure all idempotent indexes exist after any upgrade.
    for (final statement in SchemaIndexes.allIndexStatements) {
      await db.customStatement(statement);
    }
    await seedDefaultColourMaster(db);
    await SchemaV10CloudSync.installTriggers(db);
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
