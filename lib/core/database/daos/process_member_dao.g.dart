// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'process_member_dao.dart';

// ignore_for_file: type=lint
mixin _$ProcessMemberDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProcessesTable get processes => attachedDatabase.processes;
  $MembersTable get members => attachedDatabase.members;
  $MemberProcessesTable get memberProcesses => attachedDatabase.memberProcesses;
  $MemberProcessRatesTable get memberProcessRates =>
      attachedDatabase.memberProcessRates;
  ProcessMemberDaoManager get managers => ProcessMemberDaoManager(this);
}

class ProcessMemberDaoManager {
  final _$ProcessMemberDaoMixin _db;
  ProcessMemberDaoManager(this._db);
  $$ProcessesTableTableManager get processes =>
      $$ProcessesTableTableManager(_db.attachedDatabase, _db.processes);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db.attachedDatabase, _db.members);
  $$MemberProcessesTableTableManager get memberProcesses =>
      $$MemberProcessesTableTableManager(
        _db.attachedDatabase,
        _db.memberProcesses,
      );
  $$MemberProcessRatesTableTableManager get memberProcessRates =>
      $$MemberProcessRatesTableTableManager(
        _db.attachedDatabase,
        _db.memberProcessRates,
      );
}
