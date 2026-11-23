// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'worker_adjustment_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkerAdjustmentDaoMixin on DatabaseAccessor<AppDatabase> {
  $MembersTable get members => attachedDatabase.members;
  $WorkerLedgerAdjustmentsTable get workerLedgerAdjustments =>
      attachedDatabase.workerLedgerAdjustments;
  WorkerAdjustmentDaoManager get managers => WorkerAdjustmentDaoManager(this);
}

class WorkerAdjustmentDaoManager {
  final _$WorkerAdjustmentDaoMixin _db;
  WorkerAdjustmentDaoManager(this._db);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db.attachedDatabase, _db.members);
  $$WorkerLedgerAdjustmentsTableTableManager get workerLedgerAdjustments =>
      $$WorkerLedgerAdjustmentsTableTableManager(
        _db.attachedDatabase,
        _db.workerLedgerAdjustments,
      );
}
