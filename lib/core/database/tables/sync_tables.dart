import 'package:drift/drift.dart';

/// 2.24 `sync_session_state` — Singleton local-only sync metadata & trigger guard.
///
/// When [isApplyingRemote] is `1`, SQLite change-capture triggers skip enqueueing
/// into `sync_outbox` so remote rows pulled from Supabase never echo back.
@DataClassName('SyncSessionStateRow')
class SyncSessionStates extends Table {
  @override
  String get tableName => 'sync_session_state';

  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get isApplyingRemote => integer().withDefault(const Constant(0))();
  TextColumn get deviceId => text()();
  TextColumn get boundUserId => text().nullable()();
  TextColumn get boundBusinessId => text().nullable()();
  IntColumn get lastFullSyncAt => integer().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK(id = 1)',
    'CHECK(is_applying_remote IN (0, 1))',
  ];
}

/// 2.25 `sync_outbox` — Local-only durable queue of offline/online mutations
/// waiting to be pushed to Supabase. Coalesces repeated edits to the same row
/// via [entryKey] (`<table_name>:<row_id>`).
@DataClassName('SyncOutboxRow')
class SyncOutboxes extends Table {
  @override
  String get tableName => 'sync_outbox';

  TextColumn get entryKey => text()();
  TextColumn get tableNameCol => text().named('table_name')();
  TextColumn get rowId => text()();
  TextColumn get operation => text().withDefault(const Constant('UPSERT'))();
  IntColumn get enqueuedAt => integer()();
  TextColumn get status => text().withDefault(const Constant('PENDING'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  IntColumn get nextRetryAt => integer().nullable()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {entryKey};

  @override
  List<String> get customConstraints => const [
    "CHECK(operation IN ('UPSERT', 'DELETE'))",
    "CHECK(status IN ('PENDING', 'FAILED'))",
    'CHECK(retry_count >= 0)',
  ];
}

/// 2.26 `sync_cursors` — Per-table high-watermark (`server_updated_at` ISO-8601
/// UTC from Supabase Postgres) for incremental delta pulls.
@DataClassName('SyncCursorRow')
class SyncCursors extends Table {
  @override
  String get tableName => 'sync_cursors';

  TextColumn get tableNameCol => text().named('table_name')();
  TextColumn get lastServerUpdatedAt => text()();
  IntColumn get lastPulledAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {tableNameCol};
}

/// 2.27 `sync_media_queue` — Durable queue for uploading local attachments to
/// Supabase Storage (`stitchflow-media`) and lazily downloading remote photos.
@DataClassName('SyncMediaQueueRow')
class SyncMediaQueues extends Table {
  @override
  String get tableName => 'sync_media_queue';

  TextColumn get attachmentId => text()();
  TextColumn get direction => text()();
  TextColumn get sha256 => text()();
  TextColumn get relativePath => text()();
  TextColumn get remotePath => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('PENDING'))();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  IntColumn get nextRetryAt => integer().nullable()();
  TextColumn get lastError => text().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {attachmentId};

  @override
  List<String> get customConstraints => const [
    "CHECK(direction IN ('UPLOAD', 'DOWNLOAD'))",
    "CHECK(status IN ('PENDING', 'DONE', 'FAILED'))",
    'CHECK(retry_count >= 0)',
  ];
}
