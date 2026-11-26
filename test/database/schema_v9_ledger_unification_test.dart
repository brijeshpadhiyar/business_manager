import 'dart:io';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/database/migrations/database_migration_manager.dart';
import 'package:business_manager/core/database/migrations/schema_v9_ledger_unification.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/data/repositories/accounting_repository_impl.dart';
import 'package:business_manager/features/process_routing/data/repositories/process_routing_repository_impl.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/stock_movements/data/repositories/stock_movement_repository_impl.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

const _ts = 1795411200000;

Future<int> _count(AppDatabase db, String sql) async =>
    (await db.customSelect(sql).getSingle()).read<int>('c');

void main() {
  late Directory tempDir;
  late File file;

  setUpAll(IstDateTimeHelper.initialize);

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sf_v9_mig_');
    file = File('${tempDir.path}/v8.sqlite');
  });

  tearDown(() async {
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  /// Builds a populated database and rolls it back to the v8 shape.
  Future<({String jobProcessId, String issueId})> seedV8() async {
    final db = AppDatabase.forTesting(NativeDatabase(file));
    final tx = DatabaseTransactionRunner(db);
    final ids = IdGenerator();
    final stock = StockMovementRepositoryImpl(db, tx, ids);
    final routing = ProcessRoutingRepositoryImpl(db, tx, stock, ids);

    await db.lotDao.insertLot(
      const LotsCompanion(
        id: Value('lot-1'),
        lotNumber: Value('L-1'),
        transactionAt: Value(_ts),
        recordedAt: Value(_ts),
        createdAt: Value(_ts),
        updatedAt: Value(_ts),
      ),
    );
    await db.lotDao.insertDesign(
      const LotDesignsCompanion(
        id: Value('des-1'),
        lotId: Value('lot-1'),
        designName: Value('D-1'),
        createdAt: Value(_ts),
        updatedAt: Value(_ts),
      ),
    );
    await db.lotDao.insertDesignColour(
      const DesignColoursCompanion(
        id: Value('col-1'),
        lotDesignId: Value('des-1'),
        colourName: Value('Red'),
        initialQuantity: Value(100),
        unitPricePaise: Value(1000),
        createdAt: Value(_ts),
        updatedAt: Value(_ts),
      ),
    );
    await db.processMemberDao.insertProcess(
      ProcessesCompanion.insert(
        id: 'p-1',
        name: 'Stitching',
        defaultRatePaise: const Value(1000),
        createdAt: _ts,
        updatedAt: _ts,
      ),
    );
    await db.processMemberDao.insertMember(
      MembersCompanion.insert(
        id: 'w-1',
        name: 'Ramesh',
        createdAt: _ts,
        updatedAt: _ts,
      ),
    );

    final jp = await routing.addJobProcess(
      lotId: 'lot-1',
      designColourId: 'col-1',
      processId: 'p-1',
      workerId: 'w-1',
      quantity: 40,
      transactionAtUtcMillis: _ts,
    );
    await routing.addAdditionalCharge(
      jobProcessId: jp.id,
      chargeType: ProcessChargeType.extraCharge,
      description: 'Urgent work',
      amountPaise: 5000,
      transactionAtUtcMillis: _ts + 1000,
    );
    await routing.addAdditionalCharge(
      jobProcessId: jp.id,
      chargeType: ProcessChargeType.deduction,
      description: 'Thread wastage',
      amountPaise: 2000,
      transactionAtUtcMillis: _ts + 2000,
    );

    // Roll back to what a v1.3 install holds.
    await db.customStatement('PRAGMA foreign_keys = OFF;');
    await db.customStatement('DELETE FROM worker_ledger_adjustments;');
    await db.customStatement(
      'UPDATE stock_movements SET job_process_id = NULL;',
    );
    await db.customStatement(
      'ALTER TABLE process_additional_charges DROP COLUMN ledger_adjustment_id;',
    );
    await db.customStatement(
      'ALTER TABLE worker_ledger_adjustments DROP COLUMN source_charge_id;',
    );
    await db.customStatement(
      'ALTER TABLE worker_ledger_adjustments DROP COLUMN job_process_id;',
    );
    await db.customStatement('PRAGMA user_version = 8;');
    await db.customStatement('PRAGMA foreign_keys = ON;');
    await db.close();
    return (jobProcessId: jp.id, issueId: jp.linkedIssueMovementId!);
  }

  test('populated v8 database migrates to v9: charges enter the worker ledger', () async {
    final seeded = await seedV8();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    final ver = await db.customSelect('PRAGMA user_version;').getSingle();
    expect(ver.read<int>('user_version'), DatabaseMigrationManager.currentSchemaVersion);
    expect(DatabaseMigrationManager.currentSchemaVersion, 11);

    final adjustments = await db.workerAdjustmentDao.getAdjustmentsForMember('w-1');
    expect(
      adjustments
          .map((a) => (a.adjustmentType, a.amountPaise, a.transactionAt))
          .toSet(),
      {('CREDIT', 5000, _ts + 1000), ('DEBIT', 2000, _ts + 2000)},
    );
    expect(adjustments.every((a) => a.jobProcessId == seeded.jobProcessId), isTrue);
    expect(adjustments.every((a) => a.sourceChargeId != null), isTrue);
    expect(
      await _count(
        db,
        'SELECT COUNT(*) AS c FROM process_additional_charges WHERE ledger_adjustment_id IS NULL',
      ),
      0,
    );

    // Movement backfilled with its operation.
    final issue = await db.stockMovementDao.findById(seeded.issueId);
    expect(issue!.jobProcessId, seeded.jobProcessId);

    // Worker balance now includes +50 - 20.
    final acct = AccountingRepositoryImpl(
      db,
      DatabaseTransactionRunner(db),
      IdGenerator(),
    );
    final summary = (await acct.getAllWorkerSummaries()).single;
    expect(summary.netBalancePaise, 3000);

    // One reconciliation report row explains the change.
    final audit = await db
        .customSelect(
          'SELECT new_value_json FROM audit_logs WHERE entity_type = ?',
          variables: [const Variable<String>(SchemaV9LedgerUnification.auditEntityType)],
        )
        .get();
    expect(audit, hasLength(1));
    expect(audit.single.read<String>('new_value_json'), contains('"balance_change_paise":3000'));

    // Integrity.
    final integrity = await db.customSelect('PRAGMA integrity_check;').getSingle();
    expect(integrity.data.values.first, 'ok');
    expect(await db.customSelect('PRAGMA foreign_key_check;').get(), isEmpty);

    // Idempotent: running the step again changes nothing.
    await SchemaV9LedgerUnification.run(db, nowUtcMillis: _ts + 9999);
    expect(
      await _count(db, 'SELECT COUNT(*) AS c FROM worker_ledger_adjustments'),
      2,
    );
    expect(
      await _count(
        db,
        "SELECT COUNT(*) AS c FROM audit_logs WHERE entity_type = 'DATA_MIGRATION'",
      ),
      1,
    );
    await db.close();
  });
}
