// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_dao.dart';

// ignore_for_file: type=lint
mixin _$SyncDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncSessionStatesTable get syncSessionStates =>
      attachedDatabase.syncSessionStates;
  $SyncOutboxesTable get syncOutboxes => attachedDatabase.syncOutboxes;
  $SyncCursorsTable get syncCursors => attachedDatabase.syncCursors;
  $SyncMediaQueuesTable get syncMediaQueues => attachedDatabase.syncMediaQueues;
  SyncDaoManager get managers => SyncDaoManager(this);
}

class SyncDaoManager {
  final _$SyncDaoMixin _db;
  SyncDaoManager(this._db);
  $$SyncSessionStatesTableTableManager get syncSessionStates =>
      $$SyncSessionStatesTableTableManager(
        _db.attachedDatabase,
        _db.syncSessionStates,
      );
  $$SyncOutboxesTableTableManager get syncOutboxes =>
      $$SyncOutboxesTableTableManager(_db.attachedDatabase, _db.syncOutboxes);
  $$SyncCursorsTableTableManager get syncCursors =>
      $$SyncCursorsTableTableManager(_db.attachedDatabase, _db.syncCursors);
  $$SyncMediaQueuesTableTableManager get syncMediaQueues =>
      $$SyncMediaQueuesTableTableManager(
        _db.attachedDatabase,
        _db.syncMediaQueues,
      );
}
