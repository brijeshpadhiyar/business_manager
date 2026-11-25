import 'dart:convert';

import 'package:drift/drift.dart';

/// Schema v8 -> v9: one production engine, one worker ledger.
///
/// Additive and idempotent (safe to run twice, deletes nothing):
/// 1. Adds `worker_ledger_adjustments.source_charge_id` / `job_process_id` and
///    `process_additional_charges.ledger_adjustment_id`.
/// 2. Backfills `stock_movements.job_process_id` for ISSUE rows that Routing
///    created before the column was always written.
/// 3. Copies every Routing extra charge / deduction into the worker ledger as
///    a CREDIT / DEBIT adjustment with the original timestamps, then marks the
///    charge as migrated.
/// 4. Writes one `audit_logs` row (`DATA_MIGRATION`) listing every worker whose
///    ledger balance changed and why.
abstract final class SchemaV9LedgerUnification {
  static const String auditEntityType = 'DATA_MIGRATION';
  static const String auditEntityId = 'schema_v9_ledger_unification';

  static Future<void> run(
    GeneratedDatabase db, {
    required int nowUtcMillis,
  }) async {
    await _addColumnIfMissing(
      db,
      'worker_ledger_adjustments',
      'source_charge_id',
    );
    await _addColumnIfMissing(
      db,
      'worker_ledger_adjustments',
      'job_process_id',
    );
    await _addColumnIfMissing(
      db,
      'process_additional_charges',
      'ledger_adjustment_id',
    );

    final backfilled = await _backfillMovementJobProcessIds(db);
    final perWorker = await _migrateCharges(db, nowUtcMillis);

    final alreadyLogged = await db
        .customSelect(
          'SELECT COUNT(*) AS c FROM audit_logs WHERE entity_type = ? AND entity_id = ?',
          variables: [
            const Variable<String>(auditEntityType),
            const Variable<String>(auditEntityId),
          ],
        )
        .getSingle();
    if (alreadyLogged.read<int>('c') > 0 &&
        perWorker.isEmpty &&
        backfilled == 0) {
      return;
    }

    await db.customInsert(
      'INSERT INTO audit_logs (id, entity_type, entity_id, action_type, actor, '
      'new_value_json, reason, transaction_at, recorded_at) '
      'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      variables: [
        Variable<String>('mig-v9-$nowUtcMillis'),
        const Variable<String>(auditEntityType),
        const Variable<String>(auditEntityId),
        const Variable<String>('UPDATE'),
        const Variable<String>('system'),
        Variable<String>(
          jsonEncode({
            'from_schema': 8,
            'to_schema': 9,
            'movements_linked_to_job_process': backfilled,
            'workers': [
              for (final e in perWorker.entries)
                {
                  'member_id': e.key,
                  'charges_credited_paise': e.value.credit,
                  'deductions_debited_paise': e.value.debit,
                  'balance_change_paise': e.value.credit - e.value.debit,
                  'charges_migrated': e.value.count,
                  'reason': 'Routing extra charges / deductions now count in the worker ledger.',
                },
            ],
          }),
        ),
        const Variable<String>(
          'Schema v9: Routing charges moved into the worker ledger.',
        ),
        Variable<int>(nowUtcMillis),
        Variable<int>(nowUtcMillis),
      ],
    );
  }

  static Future<void> _addColumnIfMissing(
    GeneratedDatabase db,
    String table,
    String column,
  ) async {
    final cols = await db.customSelect('PRAGMA table_info($table);').get();
    if (cols.any((r) => r.read<String>('name') == column)) return;
    await db.customStatement(
      'ALTER TABLE $table ADD COLUMN $column TEXT NULL;',
    );
  }

  static Future<int> _backfillMovementJobProcessIds(
    GeneratedDatabase db,
  ) async {
    // Via the operation's first linked issue.
    final a = await db.customUpdate(
      'UPDATE stock_movements SET job_process_id = ('
      '  SELECT jp.id FROM job_processes jp'
      '  WHERE jp.linked_issue_movement_id = stock_movements.id LIMIT 1'
      ') '
      "WHERE job_process_id IS NULL AND movement_type = 'ISSUE' AND EXISTS ("
      '  SELECT 1 FROM job_processes jp'
      '  WHERE jp.linked_issue_movement_id = stock_movements.id'
      ')',
      updateKind: UpdateKind.update,
    );
    // Via dispatch / transfer / reassignment handovers (later batches).
    final b = await db.customUpdate(
      'UPDATE stock_movements SET job_process_id = ('
      '  SELECT h.to_job_process_id FROM process_handovers h'
      '  WHERE h.linked_stock_movement_id = stock_movements.id'
      '    AND h.to_job_process_id IS NOT NULL LIMIT 1'
      ') '
      "WHERE job_process_id IS NULL AND movement_type = 'ISSUE' AND EXISTS ("
      '  SELECT 1 FROM process_handovers h'
      '  WHERE h.linked_stock_movement_id = stock_movements.id'
      '    AND h.to_job_process_id IS NOT NULL'
      ')',
      updateKind: UpdateKind.update,
    );
    return a + b;
  }

  static Future<Map<String, ({int credit, int debit, int count})>>
  _migrateCharges(GeneratedDatabase db, int nowUtcMillis) async {
    final rows = await db
        .customSelect(
          'SELECT id, job_process_id, member_id, charge_type, description, '
          'amount_paise, created_by, transaction_at, created_at '
          'FROM process_additional_charges WHERE ledger_adjustment_id IS NULL '
          'ORDER BY transaction_at, created_at, id',
        )
        .get();
    final perWorker = <String, ({int credit, int debit, int count})>{};
    for (final r in rows) {
      final chargeId = r.read<String>('id');
      final memberId = r.read<String>('member_id');
      final isExtra = r.read<String>('charge_type') == 'EXTRA_CHARGE';
      final amount = r.read<int>('amount_paise');
      final adjId = 'adj-pac-$chargeId';
      final reqId = 'pac_$chargeId';

      final existing = await db
          .customSelect(
            'SELECT id FROM worker_ledger_adjustments WHERE client_request_id = ?',
            variables: [Variable<String>(reqId)],
          )
          .getSingleOrNull();
      final linkedId = existing?.read<String>('id') ?? adjId;
      if (existing == null) {
        await db.customInsert(
          'INSERT INTO worker_ledger_adjustments (id, member_id, adjustment_type, '
          'client_request_id, amount_paise, reason, notes, transaction_at, '
          'recorded_at, created_by, updated_by, created_at, updated_at, '
          'source_charge_id, job_process_id) '
          'VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          variables: [
            Variable<String>(adjId),
            Variable<String>(memberId),
            Variable<String>(isExtra ? 'CREDIT' : 'DEBIT'),
            Variable<String>(reqId),
            Variable<int>(amount),
            Variable<String>(r.read<String>('description')),
            const Variable<String>('Migrated from Routing charge (v1.4)'),
            Variable<int>(r.read<int>('transaction_at')),
            Variable<int>(nowUtcMillis),
            Variable<String>(r.readNullable<String>('created_by')),
            const Variable<String>('system'),
            Variable<int>(r.read<int>('created_at')),
            Variable<int>(nowUtcMillis),
            Variable<String>(chargeId),
            Variable<String>(r.read<String>('job_process_id')),
          ],
        );
        final prev = perWorker[memberId] ?? (credit: 0, debit: 0, count: 0);
        perWorker[memberId] = (
          credit: prev.credit + (isExtra ? amount : 0),
          debit: prev.debit + (isExtra ? 0 : amount),
          count: prev.count + 1,
        );
      }
      await db.customUpdate(
        'UPDATE process_additional_charges SET ledger_adjustment_id = ? WHERE id = ?',
        variables: [Variable<String>(linkedId), Variable<String>(chargeId)],
        updateKind: UpdateKind.update,
      );
    }
    return perWorker;
  }
}
