import 'dart:convert';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/migrations/database_migration_manager.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/features/sync/data/services/sync_conflict_service.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SyncConflictService conflictService;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    conflictService = SyncConflictService(db, IdGenerator());
    await db.customSelect('SELECT 1').getSingle();
  });

  tearDown(() async {
    await db.close();
  });

  test(
    'Fresh database is the v13 schema with all tables, seeds and indexes',
    () async {
      expect(DatabaseMigrationManager.currentSchemaVersion, 13);
      expect(DatabaseMigrationManager.minimumSupportedSchemaVersion, 11);

      final tables = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'table' "
            "AND name NOT LIKE 'sqlite_%'",
          )
          .get();
      expect(tables, hasLength(37));

      final session = await db.syncDao.getSessionState();
      expect(session.activeRole, 'OWNER');

      final profile = await db.businessProfileDao.getProfile();
      expect(profile?.id, DatabaseMigrationManager.defaultBusinessProfileId);

      final colours = await db
          .customSelect('SELECT COUNT(*) AS c FROM colour_master')
          .getSingle();
      expect(colours.read<int>('c'), 21);

      final reasonIndex = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name = 'idx_audit_logs_reason_rec'",
          )
          .get();
      expect(reasonIndex, hasLength(1));

      final integrity = await db.customSelect('PRAGMA integrity_check;').get();
      expect(integrity.first.data.values.first, 'ok');

      final fkViolations = await db
          .customSelect('PRAGMA foreign_key_check;')
          .get();
      expect(fkViolations, isEmpty);
    },
  );

  test('SyncConflictService surfaces LWW diffs and performs one-tap audited restore', () async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // Seed a Lot with the "applied cloud" title
    await db.lotDao.insertLot(
      LotsCompanion.insert(
        id: 'lot-conflict-1',
        lotNumber: 'LOT-900',
        title: const Value('Cloud Title'),
        status: const Value('ACTIVE'),
        transactionAt: now,
        recordedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.syncDao.clearAllOutbox();

    // Insert a simulated LWW sync conflict audit row
    await db.attachmentAuditDao.insertAuditLog(
      AuditLogsCompanion.insert(
        id: 'audit-conf-1',
        entityType: 'lots',
        entityId: 'lot-conflict-1',
        actionType: 'UPDATE',
        previousValueJson: Value(
          jsonEncode({
            'id': 'lot-conflict-1',
            'lot_number': 'LOT-900',
            'title': 'Local Workshop Title',
            'updated_at': now - 5000,
          }),
        ),
        newValueJson: Value(
          jsonEncode({
            'id': 'lot-conflict-1',
            'lot_number': 'LOT-900',
            'title': 'Cloud Title',
            'updated_at': now,
          }),
        ),
        reason: const Value('sync_conflict_lww'),
        transactionAt: now,
        recordedAt: now,
      ),
    );

    final conflicts = await conflictService.loadConflicts();
    expect(conflicts, hasLength(1));
    expect(conflicts.first.status, SyncConflictStatus.unresolved);
    expect(conflicts.first.fieldDiffs.map((d) => d.fieldName), ['title']);
    expect(conflicts.first.fieldDiffs.first.localValue, 'Local Workshop Title');
    expect(conflicts.first.fieldDiffs.first.cloudValue, 'Cloud Title');

    // One-tap audited restore
    await conflictService.restoreSupersededVersion(
      conflicts.first,
      actor: 'owner-1',
    );

    // Local DB row updated back to superseded value AND enqueued into sync_outbox
    final restoredLot = await db.lotDao.findLotById('lot-conflict-1');
    expect(restoredLot?.title, 'Local Workshop Title');
    final hasOutbox = await db.syncDao.hasPendingOutboxEntry(
      'lots',
      'lot-conflict-1',
    );
    expect(hasOutbox, isTrue);

    // Conflict status now reads as RESTORED (via append-only audit row)
    final reloaded = await conflictService.loadConflicts();
    expect(reloaded.first.status, SyncConflictStatus.restored);
  });
}
