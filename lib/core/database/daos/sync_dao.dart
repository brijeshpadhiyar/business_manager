import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/migrations/schema_v10_cloud_sync.dart';
import 'package:business_manager/core/database/tables/sync_tables.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:drift/drift.dart';

part 'sync_dao.g.dart';

/// Persistence-only DAO for StitchFlow v1.5 offline-first cloud sync metadata,
/// durable outbox, per-table delta cursors, and cloud media queue.
@DriftAccessor(
  tables: [SyncSessionStates, SyncOutboxes, SyncCursors, SyncMediaQueues],
)
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  static final Set<String> _allowedTables =
      SchemaV10CloudSync.syncedTablesInPushOrder.toSet();

  // ── Session State & Remote-Apply Guard ──────────────────────────────────

  Future<SyncSessionStateRow> getSessionState() async {
    final row = await (select(syncSessionStates)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (row != null) return row;
    final now = IstDateTimeHelper.nowUtcMillis();
    await SchemaV10CloudSync.seedSessionState(attachedDatabase, nowUtcMillis: now);
    return (select(syncSessionStates)..where((t) => t.id.equals(1))).getSingle();
  }

  Stream<SyncSessionStateRow?> watchSessionState() {
    return (select(syncSessionStates)..where((t) => t.id.equals(1)))
        .watchSingleOrNull();
  }

  Future<void> updateSessionBinding({
    required String? userId,
    required String? businessId,
  }) async {
    await getSessionState();
    await (update(syncSessionStates)..where((t) => t.id.equals(1))).write(
      SyncSessionStatesCompanion(
        boundUserId: Value(userId),
        boundBusinessId: Value(businessId),
        updatedAt: Value(IstDateTimeHelper.nowUtcMillis()),
      ),
    );
  }

  Future<void> markLastFullSyncAt(int utcMillis) async {
    await getSessionState();
    await (update(syncSessionStates)..where((t) => t.id.equals(1))).write(
      SyncSessionStatesCompanion(
        lastFullSyncAt: Value(utcMillis),
        updatedAt: Value(utcMillis),
      ),
    );
  }

  /// Runs [action] inside a Drift transaction with `is_applying_remote = 1`
  /// so SQLite triggers do not echo remote rows back into `sync_outbox`.
  Future<T> runAsRemoteApply<T>(Future<T> Function() action) async {
    await getSessionState();
    return transaction(() async {
      await customUpdate(
        'UPDATE sync_session_state SET is_applying_remote = 1 WHERE id = 1',
      );
      try {
        return await action();
      } finally {
        await customUpdate(
          'UPDATE sync_session_state SET is_applying_remote = 0 WHERE id = 1',
        );
      }
    });
  }

  // ── Outbox Operations ───────────────────────────────────────────────────

  Stream<int> watchPendingOutboxCount() {
    final countExp = syncOutboxes.entryKey.count();
    final query = selectOnly(syncOutboxes)..addColumns([countExp]);
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<int> getPendingOutboxCount() async {
    final countExp = syncOutboxes.entryKey.count();
    final query = selectOnly(syncOutboxes)..addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  Future<List<SyncOutboxRow>> getDueOutboxItems({
    required int nowUtcMillis,
    int limit = 200,
  }) {
    return (select(syncOutboxes)
          ..where(
            (t) =>
                t.nextRetryAt.isNull() |
                t.nextRetryAt.isSmallerOrEqualValue(nowUtcMillis),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.enqueuedAt)])
          ..limit(limit))
        .get();
  }

  Future<List<SyncOutboxRow>> getFailedOutboxItems() {
    return (select(syncOutboxes)
          ..where((t) => t.status.equals('FAILED'))
          ..orderBy([(t) => OrderingTerm.desc(t.enqueuedAt)]))
        .get();
  }

  Future<bool> hasPendingOutboxEntry(String tableName, String rowId) async {
    final key = '$tableName:$rowId';
    final row = await (select(syncOutboxes)
          ..where((t) => t.entryKey.equals(key)))
        .getSingleOrNull();
    return row != null;
  }

  Future<void> removeOutboxEntries(List<String> entryKeys) async {
    if (entryKeys.isEmpty) return;
    await (delete(syncOutboxes)..where((t) => t.entryKey.isIn(entryKeys))).go();
  }

  Future<void> markOutboxFailed(
    String entryKey, {
    required String error,
    required int retryCount,
    required int nextRetryAt,
  }) async {
    await (update(syncOutboxes)..where((t) => t.entryKey.equals(entryKey)))
        .write(
          SyncOutboxesCompanion(
            status: const Value('FAILED'),
            retryCount: Value(retryCount),
            nextRetryAt: Value(nextRetryAt),
            lastError: Value(error),
          ),
        );
  }

  Future<void> resetFailedOutboxItems() async {
    await (update(syncOutboxes)..where((t) => t.status.equals('FAILED'))).write(
      const SyncOutboxesCompanion(
        status: Value('PENDING'),
        nextRetryAt: Value(null),
        lastError: Value(null),
      ),
    );
  }

  Future<void> clearAllOutbox() async {
    await delete(syncOutboxes).go();
  }

  /// Enqueues every existing local row across all 23 synced tables so a user
  /// signing in for the first time uploads their full offline history.
  Future<int> enqueueAllLocalRowsForInitialSync() async {
    final now = IstDateTimeHelper.nowUtcMillis();
    var total = 0;
    await transaction(() async {
      for (final table in SchemaV10CloudSync.syncedTablesInPushOrder) {
        final rows = await customSelect('SELECT id FROM $table').get();
        for (final row in rows) {
          final id = row.read<String>('id');
          await customInsert(
            'INSERT INTO sync_outbox '
            '(entry_key, table_name, row_id, operation, enqueued_at, status, retry_count) '
            "VALUES (?, ?, ?, 'UPSERT', ?, 'PENDING', 0) "
            'ON CONFLICT(entry_key) DO NOTHING',
            variables: [
              Variable<String>('$table:$id'),
              Variable<String>(table),
              Variable<String>(id),
              Variable<int>(now),
            ],
          );
          total++;
        }
      }
      // Enqueue existing non-deleted attachments for media upload.
      final attachments = await customSelect(
        'SELECT id, sha256, relative_path FROM attachments WHERE deleted_at IS NULL',
      ).get();
      for (final att in attachments) {
        await customInsert(
          'INSERT INTO sync_media_queue '
          '(attachment_id, direction, sha256, relative_path, status, retry_count, updated_at) '
          "VALUES (?, 'UPLOAD', ?, ?, 'PENDING', 0, ?) "
          'ON CONFLICT(attachment_id) DO NOTHING',
          variables: [
            Variable<String>(att.read<String>('id')),
            Variable<String>(att.read<String>('sha256')),
            Variable<String>(att.read<String>('relative_path')),
            Variable<int>(now),
          ],
        );
      }
    });
    return total;
  }

  /// Counts total user-created rows across key business tables (excluding
  /// default singleton `business_profile` and built-in `colour_master` seeds).
  Future<int> countLocalUserBusinessRows() async {
    const userTables = [
      'lots',
      'members',
      'processes',
      'stock_movements',
      'payments',
      'labour_entries',
    ];
    var total = 0;
    for (final table in userTables) {
      final row = await customSelect('SELECT COUNT(*) AS c FROM $table').getSingle();
      total += row.read<int>('c');
    }
    return total;
  }

  // ── Delta Cursors ───────────────────────────────────────────────────────

  Future<String?> getCursor(String tableName) async {
    final row = await (select(syncCursors)
          ..where((t) => t.tableNameCol.equals(tableName)))
        .getSingleOrNull();
    return row?.lastServerUpdatedAt;
  }

  Future<void> upsertCursor(
    String tableName, {
    required String serverUpdatedAt,
    required int pulledAtMillis,
  }) async {
    await into(syncCursors).insertOnConflictUpdate(
      SyncCursorsCompanion(
        tableNameCol: Value(tableName),
        lastServerUpdatedAt: Value(serverUpdatedAt),
        lastPulledAt: Value(pulledAtMillis),
      ),
    );
  }

  Future<void> clearAllCursors() async {
    await delete(syncCursors).go();
  }

  // ── Media Queue ─────────────────────────────────────────────────────────

  Stream<int> watchPendingMediaCount() {
    final countExp = syncMediaQueues.attachmentId.count();
    final query = selectOnly(syncMediaQueues)
      ..addColumns([countExp])
      ..where(syncMediaQueues.status.isNotValue('DONE'));
    return query.watchSingle().map((row) => row.read(countExp) ?? 0);
  }

  Future<List<SyncMediaQueueRow>> getDueMediaItems({
    required int nowUtcMillis,
    int limit = 20,
  }) {
    return (select(syncMediaQueues)
          ..where(
            (t) =>
                t.status.isNotValue('DONE') &
                (t.nextRetryAt.isNull() |
                    t.nextRetryAt.isSmallerOrEqualValue(nowUtcMillis)),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.updatedAt)])
          ..limit(limit))
        .get();
  }

  Future<void> enqueueMediaDownload({
    required String attachmentId,
    required String sha256,
    required String relativePath,
    required String remotePath,
  }) async {
    final now = IstDateTimeHelper.nowUtcMillis();
    await into(syncMediaQueues).insertOnConflictUpdate(
      SyncMediaQueuesCompanion(
        attachmentId: Value(attachmentId),
        direction: const Value('DOWNLOAD'),
        sha256: Value(sha256),
        relativePath: Value(relativePath),
        remotePath: Value(remotePath),
        status: const Value('PENDING'),
        retryCount: const Value(0),
        nextRetryAt: const Value(null),
        lastError: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  Future<void> markMediaDone(String attachmentId, {String? remotePath}) async {
    await (update(syncMediaQueues)
          ..where((t) => t.attachmentId.equals(attachmentId)))
        .write(
          SyncMediaQueuesCompanion(
            status: const Value('DONE'),
            remotePath: remotePath != null ? Value(remotePath) : const Value.absent(),
            lastError: const Value(null),
            nextRetryAt: const Value(null),
            updatedAt: Value(IstDateTimeHelper.nowUtcMillis()),
          ),
        );
  }

  Future<void> markMediaFailed(
    String attachmentId, {
    required String error,
    required int retryCount,
    required int nextRetryAt,
  }) async {
    await (update(syncMediaQueues)
          ..where((t) => t.attachmentId.equals(attachmentId)))
        .write(
          SyncMediaQueuesCompanion(
            status: const Value('FAILED'),
            retryCount: Value(retryCount),
            nextRetryAt: Value(nextRetryAt),
            lastError: Value(error),
            updatedAt: Value(IstDateTimeHelper.nowUtcMillis()),
          ),
        );
  }

  Future<void> resetFailedMediaItems() async {
    await (update(syncMediaQueues)..where((t) => t.status.equals('FAILED')))
        .write(
          SyncMediaQueuesCompanion(
            status: const Value('PENDING'),
            nextRetryAt: const Value(null),
            lastError: const Value(null),
            updatedAt: Value(IstDateTimeHelper.nowUtcMillis()),
          ),
        );
  }

  // ── Generic Row Read / Upsert for Sync Engine (Allowlist-Guarded) ───────

  void _assertAllowedTable(String tableName) {
    if (!_allowedTables.contains(tableName)) {
      throw ArgumentError.value(tableName, 'tableName', 'Not a synced table');
    }
  }

  Future<Map<String, Object?>?> getLocalRowById(
    String tableName,
    String rowId,
  ) async {
    _assertAllowedTable(tableName);
    final row = await customSelect(
      'SELECT * FROM $tableName WHERE id = ? LIMIT 1',
      variables: [Variable<String>(rowId)],
    ).getSingleOrNull();
    return row?.data;
  }

  Future<Set<String>> getTableColumns(String tableName) async {
    _assertAllowedTable(tableName);
    final rows = await customSelect('PRAGMA table_info($tableName)').get();
    return rows.map((r) => r.read<String>('name')).toSet();
  }

  /// Upserts a remote row into local SQLite. Caller MUST invoke this inside
  /// [runAsRemoteApply] so change-capture triggers do not re-enqueue it.
  Future<void> upsertLocalRowFromRemote(
    String tableName,
    Map<String, Object?> remoteRow, {
    Set<String>? cachedColumns,
  }) async {
    _assertAllowedTable(tableName);
    final validColumns = cachedColumns ?? await getTableColumns(tableName);

    final cols = <String>[];
    final vars = <Variable<Object>>[];
    for (final entry in remoteRow.entries) {
      if (!validColumns.contains(entry.key)) continue;
      cols.add(entry.key);
      vars.add(_toVariable(entry.value));
    }
    if (cols.isEmpty) return;

    final colList = cols.join(', ');
    final placeholders = List.filled(cols.length, '?').join(', ');
    final updateAssignments = cols
        .where((c) => c != 'id')
        .map((c) => '$c = excluded.$c')
        .join(', ');

    final sql = updateAssignments.isEmpty
        ? 'INSERT OR IGNORE INTO $tableName ($colList) VALUES ($placeholders)'
        : 'INSERT INTO $tableName ($colList) VALUES ($placeholders) '
              'ON CONFLICT(id) DO UPDATE SET $updateAssignments';

    await customInsert(sql, variables: vars);
  }

  /// Clears all 23 domain tables in reverse FK order (used ONLY when user
  /// explicitly chooses "Keep Cloud Only" during first-login merge).
  Future<void> wipeLocalDomainDataForCloudReplace() async {
    await runAsRemoteApply(() async {
      for (final table in SchemaV10CloudSync.syncedTablesInPushOrder.reversed) {
        await customStatement('DELETE FROM $table;');
      }
    });
    await clearAllOutbox();
    await clearAllCursors();
    await delete(syncMediaQueues).go();
  }

  static Variable<Object> _toVariable(Object? value) {
    if (value == null) return const Variable<Object>(null);
    if (value is int) return Variable<int>(value);
    if (value is double) return Variable<double>(value);
    if (value is bool) return Variable<int>(value ? 1 : 0);
    if (value is String) return Variable<String>(value);
    return Variable<String>(value.toString());
  }
}
