import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/tables/job_process_tables.dart';
import 'package:drift/drift.dart';

part 'job_process_dao.g.dart';

/// DAO for multi-process job operations (`job_processes`), the chronological
/// handover/transfer ledger (`process_handovers`), additional charges
/// (`process_additional_charges`), and rate change history (`process_rate_history`).
@DriftAccessor(
  tables: [
    JobProcesses,
    ProcessHandovers,
    ProcessAdditionalCharges,
    ProcessRateHistories,
  ],
)
class JobProcessDao extends DatabaseAccessor<AppDatabase>
    with _$JobProcessDaoMixin {
  JobProcessDao(super.db);

  // --- JobProcesses ---

  Future<void> insertJobProcess(JobProcessesCompanion entry) =>
      into(jobProcesses).insert(entry);

  Future<JobProcessRow?> findJobProcessById(String id) =>
      (select(jobProcesses)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<JobProcessRow>> getJobProcessesForLot(String lotId) {
    return (select(jobProcesses)
          ..where((t) => t.lotId.equals(lotId) & t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.asc(t.sequenceOrder),
            (t) => OrderingTerm.asc(t.createdAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Future<List<JobProcessRow>> getJobProcessesForDesignColour(
    String designColourId,
  ) {
    return (select(jobProcesses)
          ..where(
            (t) =>
                t.designColourId.equals(designColourId) & t.deletedAt.isNull(),
          )
          ..orderBy([
            (t) => OrderingTerm.asc(t.sequenceOrder),
            (t) => OrderingTerm.asc(t.createdAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Future<int> getNextSequenceOrderForLot(String lotId) async {
    final row = await customSelect(
      'SELECT COALESCE(MAX(sequence_order), 0) + 1 AS next_seq '
      'FROM job_processes '
      'WHERE lot_id = ? AND deleted_at IS NULL;',
      variables: [Variable<String>(lotId)],
      readsFrom: {jobProcesses},
    ).getSingle();
    return row.read<int>('next_seq');
  }

  Future<int> updateJobProcess(String id, JobProcessesCompanion patch) {
    return (update(jobProcesses)..where((t) => t.id.equals(id))).write(patch);
  }

  // --- ProcessHandovers ---

  Future<void> insertHandover(ProcessHandoversCompanion entry) =>
      into(processHandovers).insert(entry);

  Future<ProcessHandoverRow?> findHandoverById(String id) => (select(
    processHandovers,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<ProcessHandoverRow?> findHandoverByClientRequestId(
    String clientRequestId,
  ) => (select(
    processHandovers,
  )..where((t) => t.clientRequestId.equals(clientRequestId))).getSingleOrNull();

  Future<ProcessHandoverRow?> findHandoverByReference(String reference) =>
      (select(
        processHandovers,
      )..where((t) => t.transferReference.equals(reference))).getSingleOrNull();

  Future<List<ProcessHandoverRow>> getHandoversForLot(String lotId) {
    return (select(processHandovers)
          ..where((t) => t.lotId.equals(lotId))
          ..orderBy([
            (t) => OrderingTerm.asc(t.transactionAt),
            (t) => OrderingTerm.asc(t.recordedAt),
            (t) => OrderingTerm.asc(t.id),
          ]))
        .get();
  }

  Future<List<ProcessHandoverRow>> getHandoversForMember(String memberId) {
    return (select(processHandovers)
          ..where(
            (t) =>
                t.fromMemberId.equals(memberId) | t.toMemberId.equals(memberId),
          )
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactionAt),
            (t) => OrderingTerm.desc(t.recordedAt),
          ]))
        .get();
  }

  Future<int> updateHandoverReceipt(
    String id, {
    required int quantityReceived,
    required String status,
    required int updatedAt,
  }) {
    return (update(processHandovers)..where((t) => t.id.equals(id))).write(
      ProcessHandoversCompanion(
        quantityReceived: Value(quantityReceived),
        status: Value(status),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  // --- ProcessAdditionalCharges (v5) ---

  Future<void> insertAdditionalCharge(
    ProcessAdditionalChargesCompanion entry,
  ) => into(processAdditionalCharges).insert(entry);

  Future<ProcessAdditionalChargeRow?> findChargeByClientRequestId(
    String clientRequestId,
  ) => (select(
    processAdditionalCharges,
  )..where((t) => t.clientRequestId.equals(clientRequestId))).getSingleOrNull();

  Future<List<ProcessAdditionalChargeRow>> getChargesForLot(String lotId) {
    return (select(processAdditionalCharges)
          ..where((t) => t.lotId.equals(lotId))
          ..orderBy([(t) => OrderingTerm.asc(t.transactionAt)]))
        .get();
  }

  Future<List<ProcessAdditionalChargeRow>> getChargesForJobProcess(
    String jobProcessId,
  ) {
    return (select(processAdditionalCharges)
          ..where((t) => t.jobProcessId.equals(jobProcessId))
          ..orderBy([(t) => OrderingTerm.asc(t.transactionAt)]))
        .get();
  }

  // --- ProcessRateHistories (v5) ---

  Future<void> insertRateHistory(ProcessRateHistoriesCompanion entry) =>
      into(processRateHistories).insert(entry);

  Future<List<ProcessRateHistoryRow>> getRateHistoryForProcess(
    String processId,
  ) {
    return (select(processRateHistories)
          ..where((t) => t.processId.equals(processId))
          ..orderBy([(t) => OrderingTerm.desc(t.changedAt)]))
        .get();
  }

  Future<List<ProcessRateHistoryRow>> getRateHistoryForJobProcess(
    String jobProcessId,
  ) {
    return (select(processRateHistories)
          ..where((t) => t.jobProcessId.equals(jobProcessId))
          ..orderBy([(t) => OrderingTerm.desc(t.changedAt)]))
        .get();
  }
}
