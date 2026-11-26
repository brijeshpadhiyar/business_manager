import 'dart:convert';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/sync/domain/services/sync_table_registry.dart';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

enum SyncConflictStatus { unresolved, acknowledged, restored }

@immutable
final class ConflictFieldDiff {
  const ConflictFieldDiff({
    required this.fieldName,
    required this.localValue,
    required this.cloudValue,
  });

  final String fieldName;
  final String localValue;
  final String cloudValue;
}

@immutable
final class SyncConflictRecord {
  const SyncConflictRecord({
    required this.auditLogId,
    required this.tableName,
    required this.entityId,
    required this.occurredAtUtcMillis,
    required this.status,
    required this.fieldDiffs,
    required this.supersededLocalRow,
    required this.appliedCloudRow,
  });

  final String auditLogId;
  final String tableName;
  final String entityId;
  final int occurredAtUtcMillis;
  final SyncConflictStatus status;
  final List<ConflictFieldDiff> fieldDiffs;
  final Map<String, Object?> supersededLocalRow;
  final Map<String, Object?> appliedCloudRow;

  bool get isUnresolved => status == SyncConflictStatus.unresolved;
}

/// Inspects `audit_logs` for LWW sync conflicts (`reason = 'sync_conflict_lww'`),
/// computes field-by-field diffs, and executes audited Acknowledge or
/// One-Tap Restore actions without ever mutating historical `audit_logs` rows.
@lazySingleton
final class SyncConflictService {
  SyncConflictService(this._db, this._idGenerator);

  final AppDatabase _db;
  final IdGenerator _idGenerator;

  static const Set<String> _ignoredDiffKeys = {
    'business_id',
    'owner_id',
    'server_updated_at',
    'updated_at',
    'created_at',
  };

  Future<List<SyncConflictRecord>> loadConflicts({int limit = 100}) async {
    final conflictRows = await _db.customSelect(
      'SELECT * FROM audit_logs '
      "WHERE reason = 'sync_conflict_lww' "
      'ORDER BY recorded_at DESC LIMIT ?',
      variables: [Variable<int>(limit)],
    ).get();

    if (conflictRows.isEmpty) return const [];

    final resolutionRows = await _db.customSelect(
      'SELECT previous_value_json, reason FROM audit_logs '
      "WHERE reason IN ('sync_conflict_acknowledged', 'sync_conflict_restored') "
      'ORDER BY recorded_at DESC',
    ).get();

    final statusByConflictId = <String, SyncConflictStatus>{};
    for (final r in resolutionRows) {
      final raw = r.readNullable<String>('previous_value_json');
      final reason = r.readNullable<String>('reason');
      if (raw == null) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map && decoded['conflict_audit_id'] != null) {
          final cid = decoded['conflict_audit_id'].toString();
          statusByConflictId.putIfAbsent(
            cid,
            () => reason == 'sync_conflict_restored'
                ? SyncConflictStatus.restored
                : SyncConflictStatus.acknowledged,
          );
        }
      } catch (_) {}
    }

    final results = <SyncConflictRecord>[];
    for (final row in conflictRows) {
      final id = row.read<String>('id');
      final table = row.read<String>('entity_type');
      final entityId = row.read<String>('entity_id');
      final recordedAt = row.read<int>('recorded_at');
      final prevMap = _decodeJsonMap(
        row.readNullable<String>('previous_value_json'),
      );
      final newMap = _decodeJsonMap(
        row.readNullable<String>('new_value_json'),
      );

      final diffs = computeFieldDiffs(prevMap, newMap);
      results.add(
        SyncConflictRecord(
          auditLogId: id,
          tableName: table,
          entityId: entityId,
          occurredAtUtcMillis: recordedAt,
          status: statusByConflictId[id] ?? SyncConflictStatus.unresolved,
          fieldDiffs: diffs,
          supersededLocalRow: prevMap,
          appliedCloudRow: newMap,
        ),
      );
    }
    return results;
  }

  /// Pure diff helper exposed for unit testing.
  static List<ConflictFieldDiff> computeFieldDiffs(
    Map<String, Object?> localRow,
    Map<String, Object?> cloudRow,
  ) {
    final keys = {...localRow.keys, ...cloudRow.keys}.toList()..sort();
    final diffs = <ConflictFieldDiff>[];
    for (final key in keys) {
      if (_ignoredDiffKeys.contains(key)) continue;
      final lv = localRow[key];
      final cv = cloudRow[key];
      if (lv != cv) {
        diffs.add(
          ConflictFieldDiff(
            fieldName: key,
            localValue: lv?.toString() ?? '—',
            cloudValue: cv?.toString() ?? '—',
          ),
        );
      }
    }
    return diffs;
  }

  /// Marks a conflict acknowledged by appending a new immutable audit row.
  Future<void> acknowledgeConflict(
    SyncConflictRecord record, {
    String? actor,
  }) async {
    final now = IstDateTimeHelper.nowUtcMillis();
    await _db.attachmentAuditDao.insertAuditLog(
      AuditLogsCompanion.insert(
        id: _idGenerator.nextEntityId(),
        entityType: record.tableName,
        entityId: record.entityId,
        actionType: 'UPDATE',
        actor: Value(actor),
        previousValueJson: Value(
          jsonEncode({'conflict_audit_id': record.auditLogId}),
        ),
        newValueJson: Value(jsonEncode({'resolution': 'kept_cloud'})),
        reason: const Value('sync_conflict_acknowledged'),
        transactionAt: now,
        recordedAt: now,
      ),
    );
  }

  /// Restores the superseded local version as a fresh audited local update
  /// (with new `updated_at`), triggering normal SQLite outbox capture so it
  /// pushes cleanly to Supabase on the next sync cycle.
  Future<void> restoreSupersededVersion(
    SyncConflictRecord record, {
    String? actor,
  }) async {
    if (SyncTableRegistry.isAppendOnly(record.tableName)) {
      throw StateError(
        'Append-only table ${record.tableName} cannot be overwritten.',
      );
    }

    final validCols = await _db.syncDao.getTableColumns(record.tableName);
    if (validCols.isEmpty) {
      throw StateError('Unknown table ${record.tableName}.');
    }

    final now = IstDateTimeHelper.nowUtcMillis();
    final restoredRow = Map<String, Object?>.from(record.supersededLocalRow);
    restoredRow['id'] = record.entityId;
    if (validCols.contains('updated_at')) {
      restoredRow['updated_at'] = now;
    }

    final cols = restoredRow.keys
        .where((k) => validCols.contains(k) && k != 'id')
        .toList();
    if (cols.isEmpty) return;

    await _db.transaction(() async {
      final setClause = cols.map((c) => '$c = ?').join(', ');
      final vars = <Variable<Object>>[
        ...cols.map(_toVariable(restoredRow)),
        Variable<String>(record.entityId),
      ];

      await _db.customUpdate(
        'UPDATE ${record.tableName} SET $setClause WHERE id = ?',
        variables: vars,
      );

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion.insert(
          id: _idGenerator.nextEntityId(),
          entityType: record.tableName,
          entityId: record.entityId,
          actionType: 'UPDATE',
          actor: Value(actor),
          previousValueJson: Value(
            jsonEncode({
              'conflict_audit_id': record.auditLogId,
              'cloud_row': record.appliedCloudRow,
            }),
          ),
          newValueJson: Value(jsonEncode(restoredRow)),
          reason: const Value('sync_conflict_restored'),
          transactionAt: now,
          recordedAt: now,
        ),
      );
    });
  }

  Variable<Object> Function(String) _toVariable(Map<String, Object?> row) {
    return (String col) {
      final value = row[col];
      if (value == null) return const Variable<Object>(null);
      if (value is int) return Variable<int>(value);
      if (value is num) return Variable<double>(value.toDouble());
      if (value is bool) return Variable<int>(value ? 1 : 0);
      return Variable<String>(value.toString());
    };
  }

  Map<String, Object?> _decodeJsonMap(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return decoded.map((k, v) => MapEntry(k.toString(), v));
      }
    } catch (_) {}
    return const {};
  }
}
