import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/tables/process_member_tables.dart';
import 'package:drift/drift.dart';

part 'process_member_dao.g.dart';

@DriftAccessor(
  tables: [Processes, Members, MemberProcesses, MemberProcessRates],
)
class ProcessMemberDao extends DatabaseAccessor<AppDatabase>
    with _$ProcessMemberDaoMixin {
  ProcessMemberDao(super.db);

  Future<void> insertProcess(ProcessesCompanion entry) =>
      into(processes).insert(entry);

  Future<ProcessRow?> findProcessById(String id) =>
      (select(processes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertMember(MembersCompanion entry) =>
      into(members).insert(entry);

  Future<MemberRow?> findMemberById(String id) =>
      (select(members)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> insertMemberProcess(MemberProcessesCompanion entry) =>
      into(memberProcesses).insert(entry);

  Future<MemberProcessRow?> findMemberProcessLink(
    String memberId,
    String processId,
  ) {
    return (select(memberProcesses)
          ..where(
            (t) =>
                t.memberId.equals(memberId) & t.processId.equals(processId),
          ))
        .getSingleOrNull();
  }

  Future<void> insertMemberProcessRate(MemberProcessRatesCompanion entry) =>
      into(memberProcessRates).insert(entry);

  Future<List<MemberProcessRateRow>> getActiveRates(
    String memberId,
    String processId,
  ) {
    return (select(memberProcessRates)
          ..where(
            (t) =>
                t.memberId.equals(memberId) &
                t.processId.equals(processId) &
                t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.effectiveFrom)]))
        .get();
  }
}
