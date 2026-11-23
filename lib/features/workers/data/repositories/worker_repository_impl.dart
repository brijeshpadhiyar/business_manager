import 'dart:convert';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/features/rates/domain/entities/rate_entities.dart';
import 'package:business_manager/features/rates/domain/services/member_process_rate_resolver.dart';
import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';
import 'package:business_manager/features/workers/domain/repositories/worker_repository.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: WorkerRepository)
final class WorkerRepositoryImpl implements WorkerRepository {
  WorkerRepositoryImpl(this._db, this._txRunner, this._idGenerator);

  final AppDatabase _db;
  final DatabaseTransactionRunner _txRunner;
  final IdGenerator _idGenerator;
  static const MemberProcessRateResolver _rateResolver =
      MemberProcessRateResolver();

  Future<String?> _currentActor() async {
    final profile = await _db.businessProfileDao.getProfile();
    return profile?.ownerName;
  }

  @override
  Future<List<WorkerEntity>> getWorkers({
    String? searchQuery,
    bool? isActiveFilter,
  }) async {
    final rows = await _db.processMemberDao.getNonDeletedMembers();
    final q = searchQuery?.trim().toLowerCase() ?? '';
    return rows
        .where((row) {
          if (isActiveFilter != null && (row.isActive == 1) != isActiveFilter) {
            return false;
          }
          if (q.isEmpty) return true;
          return row.name.toLowerCase().contains(q) ||
              (row.phone?.toLowerCase().contains(q) ?? false) ||
              (row.address?.toLowerCase().contains(q) ?? false) ||
              (row.notes?.toLowerCase().contains(q) ?? false);
        })
        .map(_workerToEntity)
        .toList();
  }

  @override
  Future<WorkerDetailAggregate?> getWorkerDetail(
    String workerId, {
    int? asOfUtcMillis,
  }) async {
    final workerRow = await _db.processMemberDao.findMemberById(workerId);
    if (workerRow == null || workerRow.deletedAt != null) return null;

    final assignments = await getAssignmentsForWorker(
      workerId,
      activeOnly: true,
    );
    final rateRows = await _db.processMemberDao.getAllActiveRatesForMember(
      workerId,
    );
    final allRates = rateRows.map(_rateToEntity).toList();
    final refTime = asOfUtcMillis ?? IstDateTimeHelper.nowUtcMillis();

    final summaries = assignments.map((assignment) {
      final processRates = allRates
          .where((r) => r.processId == assignment.processId)
          .toList();
      final resolved = _rateResolver.resolve(
        workerId: workerId,
        processId: assignment.processId,
        transactionAtUtcMillis: refTime,
        rates: processRates,
      );
      final currentRate = switch (resolved) {
        RateResolutionFound(:final rate) => rate,
        _ => null,
      };
      return WorkerProcessRateSummary(
        assignment: assignment,
        currentRate: currentRate,
        totalRateHistoryCount: processRates.length,
      );
    }).toList();

    return WorkerDetailAggregate(
      worker: _workerToEntity(workerRow),
      assignedProcesses: summaries,
      allRates: allRates,
    );
  }

  void _validateWorkerInputs({
    required String name,
    String? phone,
    String? address,
    String? notes,
  }) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      throw const DomainValidationException(
        'worker_name_required',
        'Worker name cannot be empty.',
      );
    }
    if (cleanName.length > ValidationLimits.maxPersonNameLength) {
      throw const DomainValidationException(
        'text_too_long',
        'Worker name exceeds maximum allowed length.',
      );
    }
    final phoneRes = AppValidators.mobileNumberValidator(phone);
    if (!phoneRes.isValid) {
      final code = switch (phoneRes.code) {
        ValidationErrorCode.mobileInvalidChars => 'mobile_invalid_chars',
        ValidationErrorCode.mobileInvalidInternational =>
          'mobile_invalid_international',
        _ => 'mobile_invalid_indian',
      };
      throw DomainValidationException(code, 'Invalid mobile number.');
    }
    if ((address?.trim().length ?? 0) > ValidationLimits.maxAddressLength) {
      throw const DomainValidationException(
        'text_too_long',
        'Address exceeds maximum allowed length.',
      );
    }
    if ((notes?.trim().length ?? 0) > ValidationLimits.maxNotesLength) {
      throw const DomainValidationException(
        'text_too_long',
        'Notes exceed maximum allowed length.',
      );
    }
  }

  @override
  Future<WorkerEntity> createWorker({
    required String name,
    String? phone,
    String? address,
    String? notes,
  }) async {
    _validateWorkerInputs(
      name: name,
      phone: phone,
      address: address,
      notes: notes,
    );
    final cleanName = name.trim();

    return _txRunner.runInTransaction(() async {
      final now = IstDateTimeHelper.nowUtcMillis();
      final id = _idGenerator.nextEntityId();
      final actor = await _currentActor();
      final cleanPhone = _nullIfBlank(phone);
      final cleanAddress = _nullIfBlank(address);
      final cleanNotes = _nullIfBlank(notes);

      await _db.processMemberDao.insertMember(
        MembersCompanion(
          id: Value(id),
          name: Value(cleanName),
          phone: Value(cleanPhone),
          address: Value(cleanAddress),
          notes: Value(cleanNotes),
          isActive: const Value(1),
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('members'),
          entityId: Value(id),
          actionType: const Value('CREATE'),
          actor: Value(actor),
          newValueJson: Value(
            jsonEncode({
              'name': cleanName,
              'phone': cleanPhone,
              'address': cleanAddress,
              'notes': cleanNotes,
              'is_active': true,
            }),
          ),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );

      final created = await _db.processMemberDao.findMemberById(id);
      return _workerToEntity(created!);
    });
  }

  @override
  Future<WorkerEntity> updateWorker({
    required String workerId,
    required String name,
    String? phone,
    String? address,
    String? notes,
  }) async {
    _validateWorkerInputs(
      name: name,
      phone: phone,
      address: address,
      notes: notes,
    );
    final cleanName = name.trim();

    return _txRunner.runInTransaction(() async {
      final existing = await _db.processMemberDao.findMemberById(workerId);
      if (existing == null || existing.deletedAt != null) {
        throw const LocalStorageException('Worker not found.');
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await _currentActor();
      final cleanPhone = _nullIfBlank(phone);
      final cleanAddress = _nullIfBlank(address);
      final cleanNotes = _nullIfBlank(notes);

      await _db.processMemberDao.updateMemberById(
        workerId,
        MembersCompanion(
          name: Value(cleanName),
          phone: Value(cleanPhone),
          address: Value(cleanAddress),
          notes: Value(cleanNotes),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('members'),
          entityId: Value(workerId),
          actionType: const Value('UPDATE'),
          actor: Value(actor),
          previousValueJson: Value(
            jsonEncode({
              'name': existing.name,
              'phone': existing.phone,
              'address': existing.address,
              'notes': existing.notes,
            }),
          ),
          newValueJson: Value(
            jsonEncode({
              'name': cleanName,
              'phone': cleanPhone,
              'address': cleanAddress,
              'notes': cleanNotes,
            }),
          ),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );

      final updated = await _db.processMemberDao.findMemberById(workerId);
      return _workerToEntity(updated!);
    });
  }

  @override
  Future<WorkerEntity> setWorkerActive({
    required String workerId,
    required bool isActive,
  }) async {
    return _txRunner.runInTransaction(() async {
      final existing = await _db.processMemberDao.findMemberById(workerId);
      if (existing == null || existing.deletedAt != null) {
        throw const LocalStorageException('Worker not found.');
      }
      if ((existing.isActive == 1) == isActive) {
        return _workerToEntity(existing);
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await _currentActor();

      await _db.processMemberDao.updateMemberById(
        workerId,
        MembersCompanion(
          isActive: Value(isActive ? 1 : 0),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('members'),
          entityId: Value(workerId),
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

      final updated = await _db.processMemberDao.findMemberById(workerId);
      return _workerToEntity(updated!);
    });
  }

  @override
  Future<List<WorkerProcessAssignmentEntity>> getAssignmentsForWorker(
    String workerId, {
    bool activeOnly = true,
  }) async {
    final rows = await _db.processMemberDao.getAssignmentsForMember(
      workerId,
      activeOnly: activeOnly,
    );
    final result = <WorkerProcessAssignmentEntity>[];
    for (final link in rows) {
      final process = await _db.processMemberDao.findProcessById(
        link.processId,
      );
      if (process == null || process.deletedAt != null) continue;
      result.add(
        WorkerProcessAssignmentEntity(
          id: link.id,
          workerId: link.memberId,
          processId: link.processId,
          processName: process.name,
          processIsActive: process.isActive == 1,
          isActive: link.isActive == 1,
          createdAt: link.createdAt,
          updatedAt: link.updatedAt,
        ),
      );
    }
    return result;
  }

  @override
  Future<WorkerProcessAssignmentEntity> assignProcessToWorker({
    required String workerId,
    required String processId,
  }) async {
    return _txRunner.runInTransaction(() async {
      final worker = await _db.processMemberDao.findMemberById(workerId);
      if (worker == null || worker.deletedAt != null || worker.isActive != 1) {
        throw const DomainValidationException(
          'inactive_worker',
          'Cannot assign processes to an inactive worker.',
        );
      }

      final process = await _db.processMemberDao.findProcessById(processId);
      if (process == null ||
          process.deletedAt != null ||
          process.isActive != 1) {
        throw const DomainValidationException(
          'inactive_process',
          'Cannot assign an inactive process to a worker.',
        );
      }

      final existingLink = await _db.processMemberDao.findMemberProcessLink(
        workerId,
        processId,
      );
      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await _currentActor();

      if (existingLink != null) {
        if (existingLink.isActive == 1) {
          throw const DomainValidationException(
            'duplicate_assignment',
            'This process is already assigned to the worker.',
          );
        }

        // Reactivate existing link (preserves unique pair constraint & history)
        await _db.processMemberDao.updateMemberProcessById(
          existingLink.id,
          MemberProcessesCompanion(
            isActive: const Value(1),
            updatedAt: Value(now),
          ),
        );

        await _db.attachmentAuditDao.insertAuditLog(
          AuditLogsCompanion(
            id: Value(_idGenerator.nextEntityId()),
            entityType: const Value('member_processes'),
            entityId: Value(existingLink.id),
            actionType: const Value('REACTIVATE'),
            actor: Value(actor),
            previousValueJson: Value(
              jsonEncode({
                'member_id': workerId,
                'process_id': processId,
                'is_active': false,
              }),
            ),
            newValueJson: Value(
              jsonEncode({
                'member_id': workerId,
                'process_id': processId,
                'is_active': true,
              }),
            ),
            transactionAt: Value(now),
            recordedAt: Value(now),
          ),
        );

        return WorkerProcessAssignmentEntity(
          id: existingLink.id,
          workerId: workerId,
          processId: processId,
          processName: process.name,
          processIsActive: process.isActive == 1,
          isActive: true,
          createdAt: existingLink.createdAt,
          updatedAt: now,
        );
      }

      final linkId = _idGenerator.nextEntityId();
      await _db.processMemberDao.insertMemberProcess(
        MemberProcessesCompanion(
          id: Value(linkId),
          memberId: Value(workerId),
          processId: Value(processId),
          isActive: const Value(1),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('member_processes'),
          entityId: Value(linkId),
          actionType: const Value('CREATE'),
          actor: Value(actor),
          newValueJson: Value(
            jsonEncode({
              'member_id': workerId,
              'process_id': processId,
              'is_active': true,
            }),
          ),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );

      return WorkerProcessAssignmentEntity(
        id: linkId,
        workerId: workerId,
        processId: processId,
        processName: process.name,
        processIsActive: process.isActive == 1,
        isActive: true,
        createdAt: now,
        updatedAt: now,
      );
    });
  }

  @override
  Future<void> deactivateAssignment({
    required String workerId,
    required String processId,
  }) async {
    await _txRunner.runInTransaction(() async {
      final existingLink = await _db.processMemberDao.findMemberProcessLink(
        workerId,
        processId,
      );
      if (existingLink == null || existingLink.isActive == 0) return;

      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await _currentActor();

      await _db.processMemberDao.updateMemberProcessById(
        existingLink.id,
        MemberProcessesCompanion(
          isActive: const Value(0),
          updatedAt: Value(now),
        ),
      );

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('member_processes'),
          entityId: Value(existingLink.id),
          actionType: const Value('DEACTIVATE'),
          actor: Value(actor),
          previousValueJson: Value(
            jsonEncode({
              'member_id': workerId,
              'process_id': processId,
              'is_active': true,
            }),
          ),
          newValueJson: Value(
            jsonEncode({
              'member_id': workerId,
              'process_id': processId,
              'is_active': false,
            }),
          ),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );
    });
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  WorkerEntity _workerToEntity(MemberRow row) => WorkerEntity(
    id: row.id,
    name: row.name,
    phone: row.phone,
    address: row.address,
    notes: row.notes,
    isActive: row.isActive == 1,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  MemberProcessRateEntity _rateToEntity(MemberProcessRateRow row) =>
      MemberProcessRateEntity(
        id: row.id,
        memberId: row.memberId,
        processId: row.processId,
        ratePaise: row.ratePaise,
        effectiveFrom: row.effectiveFrom,
        effectiveTo: row.effectiveTo,
        notes: row.notes,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
}
