import 'dart:convert';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: ProcessRepository)
final class ProcessRepositoryImpl implements ProcessRepository {
  ProcessRepositoryImpl(this._db, this._txRunner, this._idGenerator);

  final AppDatabase _db;
  final DatabaseTransactionRunner _txRunner;
  final IdGenerator _idGenerator;

  Future<String?> _currentActor() async {
    final profile = await _db.businessProfileDao.getProfile();
    return profile?.ownerName;
  }

  @override
  Future<List<ProcessEntity>> getProcesses({
    String? searchQuery,
    bool? isActiveFilter,
  }) async {
    final rows = await _db.processMemberDao.getNonDeletedProcesses();
    final q = searchQuery?.trim().toLowerCase() ?? '';
    return rows
        .where((row) {
          if (isActiveFilter != null && (row.isActive == 1) != isActiveFilter) {
            return false;
          }
          if (q.isEmpty) return true;
          return row.name.toLowerCase().contains(q) ||
              (row.description?.toLowerCase().contains(q) ?? false);
        })
        .map(_toEntity)
        .toList();
  }

  @override
  Future<ProcessDetailAggregate?> getProcessDetail(String processId) async {
    final row = await _db.processMemberDao.findProcessById(processId);
    if (row == null || row.deletedAt != null) return null;

    final assignments = await _db.processMemberDao.getAssignmentsForProcess(
      processId,
      activeOnly: true,
    );
    final assignedWorkers = <ProcessAssignedWorkerSummary>[];
    for (final link in assignments) {
      final member = await _db.processMemberDao.findMemberById(link.memberId);
      if (member == null || member.deletedAt != null) continue;
      assignedWorkers.add(
        ProcessAssignedWorkerSummary(
          workerId: member.id,
          workerName: member.name,
          workerPhone: member.phone,
          workerIsActive: member.isActive == 1,
          assignedAt: link.updatedAt,
        ),
      );
    }

    final auditRows = await _db.attachmentAuditDao.getAuditLogsForEntity(
      'processes',
      processId,
    );

    return ProcessDetailAggregate(
      process: _toEntity(row),
      assignedWorkers: assignedWorkers,
      auditHistory: auditRows
          .map(
            (a) => ProcessAuditEntry(
              id: a.id,
              actionType: a.actionType,
              actor: a.actor,
              previousValueJson: a.previousValueJson,
              newValueJson: a.newValueJson,
              recordedAt: a.recordedAt,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<ProcessEntity> createProcess({
    required String name,
    String? description,
    ProcessBillingModeOverride? billingModeOverride,
    bool includeDamagedInLabour = false,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const DomainValidationException(
        'process_name_required',
        'Process name cannot be empty.',
      );
    }

    return _txRunner.runInTransaction(() async {
      final duplicate = await _db.processMemberDao
          .findNonDeletedProcessByLowerName(cleanName.toLowerCase());
      if (duplicate != null) {
        throw const DomainValidationException(
          'duplicate_process_name',
          'A process with this name already exists.',
        );
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final id = _idGenerator.nextEntityId();
      final actor = await _currentActor();
      final cleanDesc = _nullIfBlank(description);

      await _db.processMemberDao.insertProcess(
        ProcessesCompanion(
          id: Value(id),
          name: Value(cleanName),
          description: Value(cleanDesc),
          isActive: const Value(1),
          billingModeOverride: Value(billingModeOverride?.dbValue),
          includeDamagedInLabour: Value(includeDamagedInLabour ? 1 : 0),
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('processes'),
          entityId: Value(id),
          actionType: const Value('CREATE'),
          actor: Value(actor),
          newValueJson: Value(
            jsonEncode({
              'name': cleanName,
              'description': cleanDesc,
              'is_active': true,
              'billing_mode_override': billingModeOverride?.dbValue,
              'include_damaged_in_labour': includeDamagedInLabour,
            }),
          ),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );

      final created = await _db.processMemberDao.findProcessById(id);
      return _toEntity(created!);
    });
  }

  @override
  Future<ProcessEntity> updateProcess({
    required String processId,
    required String name,
    String? description,
    ProcessBillingModeOverride? billingModeOverride,
    required bool includeDamagedInLabour,
  }) async {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const DomainValidationException(
        'process_name_required',
        'Process name cannot be empty.',
      );
    }

    return _txRunner.runInTransaction(() async {
      final existing = await _db.processMemberDao.findProcessById(processId);
      if (existing == null || existing.deletedAt != null) {
        throw const LocalStorageException('Process not found.');
      }

      final duplicate = await _db.processMemberDao
          .findNonDeletedProcessByLowerName(cleanName.toLowerCase());
      if (duplicate != null && duplicate.id != processId) {
        throw const DomainValidationException(
          'duplicate_process_name',
          'A process with this name already exists.',
        );
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await _currentActor();
      final cleanDesc = _nullIfBlank(description);

      await _db.processMemberDao.updateProcessById(
        processId,
        ProcessesCompanion(
          name: Value(cleanName),
          description: Value(cleanDesc),
          billingModeOverride: Value(billingModeOverride?.dbValue),
          includeDamagedInLabour: Value(includeDamagedInLabour ? 1 : 0),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('processes'),
          entityId: Value(processId),
          actionType: const Value('UPDATE'),
          actor: Value(actor),
          previousValueJson: Value(
            jsonEncode({
              'name': existing.name,
              'description': existing.description,
              'billing_mode_override': existing.billingModeOverride,
              'include_damaged_in_labour': existing.includeDamagedInLabour == 1,
            }),
          ),
          newValueJson: Value(
            jsonEncode({
              'name': cleanName,
              'description': cleanDesc,
              'billing_mode_override': billingModeOverride?.dbValue,
              'include_damaged_in_labour': includeDamagedInLabour,
            }),
          ),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );

      final updated = await _db.processMemberDao.findProcessById(processId);
      return _toEntity(updated!);
    });
  }

  @override
  Future<ProcessEntity> setProcessActive({
    required String processId,
    required bool isActive,
  }) async {
    return _txRunner.runInTransaction(() async {
      final existing = await _db.processMemberDao.findProcessById(processId);
      if (existing == null || existing.deletedAt != null) {
        throw const LocalStorageException('Process not found.');
      }
      if ((existing.isActive == 1) == isActive) {
        return _toEntity(existing);
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await _currentActor();

      await _db.processMemberDao.updateProcessById(
        processId,
        ProcessesCompanion(
          isActive: Value(isActive ? 1 : 0),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('processes'),
          entityId: Value(processId),
          actionType: Value(isActive ? 'REACTIVATE' : 'DEACTIVATE'),
          actor: Value(actor),
          previousValueJson: Value(
            jsonEncode({'is_active': existing.isActive == 1}),
          ),
          newValueJson: Value(jsonEncode({'is_active': isActive})),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );

      final updated = await _db.processMemberDao.findProcessById(processId);
      return _toEntity(updated!);
    });
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  ProcessEntity _toEntity(ProcessRow row) => ProcessEntity(
    id: row.id,
    name: row.name,
    description: row.description,
    isActive: row.isActive == 1,
    billingModeOverride: ProcessBillingModeOverride.fromDbValue(
      row.billingModeOverride,
    ),
    includeDamagedInLabour: row.includeDamagedInLabour == 1,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );
}
