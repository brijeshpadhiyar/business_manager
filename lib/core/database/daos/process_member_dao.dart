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

  // ---------------------------------------------------------------------------
  // Processes
  // ---------------------------------------------------------------------------

  Future<void> insertProcess(ProcessesCompanion entry) =>
      into(processes).insert(entry);

  Future<ProcessRow?> findProcessById(String id) =>
      (select(processes)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<ProcessRow>> getNonDeletedProcesses() {
    return (select(processes)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<ProcessRow?> findNonDeletedProcessByLowerName(String lowerName) {
    return (select(processes)..where(
          (t) => t.deletedAt.isNull() & t.name.lower().equals(lowerName),
        ))
        .getSingleOrNull();
  }

  Future<int> updateProcessById(String id, ProcessesCompanion entry) {
    return (update(processes)..where((t) => t.id.equals(id))).write(entry);
  }

  // ---------------------------------------------------------------------------
  // Members (Workers)
  // ---------------------------------------------------------------------------

  Future<void> insertMember(MembersCompanion entry) =>
      into(members).insert(entry);

  Future<MemberRow?> findMemberById(String id) =>
      (select(members)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<MemberRow>> getNonDeletedMembers() {
    return (select(members)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<int> updateMemberById(String id, MembersCompanion entry) {
    return (update(members)..where((t) => t.id.equals(id))).write(entry);
  }

  // ---------------------------------------------------------------------------
  // Member <-> Process Assignments
  // ---------------------------------------------------------------------------

  Future<void> insertMemberProcess(MemberProcessesCompanion entry) =>
      into(memberProcesses).insert(entry);

  Future<MemberProcessRow?> findMemberProcessLink(
    String memberId,
    String processId,
  ) {
    return (select(memberProcesses)..where(
          (t) => t.memberId.equals(memberId) & t.processId.equals(processId),
        ))
        .getSingleOrNull();
  }

  Future<int> updateMemberProcessById(
    String id,
    MemberProcessesCompanion entry,
  ) {
    return (update(
      memberProcesses,
    )..where((t) => t.id.equals(id))).write(entry);
  }

  Future<List<MemberProcessRow>> getAssignmentsForMember(
    String memberId, {
    bool activeOnly = true,
  }) {
    return (select(memberProcesses)
          ..where(
            (t) => activeOnly
                ? (t.memberId.equals(memberId) & t.isActive.equals(1))
                : t.memberId.equals(memberId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Future<List<MemberProcessRow>> getAssignmentsForProcess(
    String processId, {
    bool activeOnly = true,
  }) {
    return (select(memberProcesses)
          ..where(
            (t) => activeOnly
                ? (t.processId.equals(processId) & t.isActive.equals(1))
                : t.processId.equals(processId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  // ---------------------------------------------------------------------------
  // Historical Member Process Rates
  // ---------------------------------------------------------------------------

  Future<void> insertMemberProcessRate(MemberProcessRatesCompanion entry) =>
      into(memberProcessRates).insert(entry);

  Future<MemberProcessRateRow?> findRateById(String id) => (select(
    memberProcessRates,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> updateRateById(String id, MemberProcessRatesCompanion entry) {
    return (update(
      memberProcessRates,
    )..where((t) => t.id.equals(id))).write(entry);
  }

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

  Future<List<MemberProcessRateRow>> getAllActiveRatesForMember(
    String memberId,
  ) {
    return (select(memberProcessRates)
          ..where((t) => t.memberId.equals(memberId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.effectiveFrom)]))
        .get();
  }
}
