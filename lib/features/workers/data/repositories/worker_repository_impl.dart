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
    final allProcesses = await _db.processMemberDao.getNonDeletedProcesses();
    final processById = {for (final p in allProcesses) p.id: p};
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
      final procRow = processById[assignment.processId];
      return WorkerProcessRateSummary(
        assignment: assignment,
        currentRate: currentRate,
        processDefaultRatePaise: procRow?.defaultRatePaise ?? 0,
        processDefaultPricingUnit: procRow?.defaultPricingUnit ?? 'PER_PIECE',
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

  void _validateProcessConfigs(List<WorkerProcessConfigInput> configs) {
    final seenProcessIds = <String>{};
    for (final cfg in configs) {
      final procId = cfg.processId.trim();
      if (procId.isEmpty) {
        throw const DomainValidationException(
          'process_not_found',
          'Selected process is invalid.',
        );
      }
      if (!seenProcessIds.add(procId)) {
        throw const DomainValidationException(
          'duplicate_assignment',
          'Duplicate process selected for worker.',
        );
      }
      final rate = cfg.customRatePaise;
      if (rate != null) {
        if (rate < 0) {
          throw const DomainValidationException(
            'rate_negative',
            'Rate per piece cannot be negative.',
          );
        }
        if (rate > ValidationLimits.maxAmountPaise) {
          throw const DomainValidationException(
            'rate_too_large',
            'Rate exceeds maximum allowed limit.',
          );
        }
      }
      if ((cfg.notes?.trim().length ?? 0) > ValidationLimits.maxNotesLength) {
        throw const DomainValidationException(
          'text_too_long',
          'Notes exceed maximum allowed length.',
        );
      }
    }
  }

  /// Safely inserts or updates a worker-specific custom rate inside an active
  /// transaction without ever mutating historical rates referenced by stock
  /// movements.
  Future<void> _upsertWorkerProcessRateInTx({
    required String workerId,
    required String processId,
    required int ratePaise,
    required String effectiveFromIso,
    String? notes,
    required String? actor,
    required int now,
  }) async {
    final existingRows = await _db.processMemberDao.getActiveRates(
      workerId,
      processId,
    );
    final existingEntities = existingRows.map(_rateToEntity).toList();

    final resolvedNow = _rateResolver.resolveForBusinessDate(
      workerId: workerId,
      processId: processId,
      businessDateIst: effectiveFromIso,
      rates: existingEntities,
    );
    if (resolvedNow is RateResolutionFound &&
        resolvedNow.rate.ratePaise == ratePaise) {
      return;
    }

    // If an unreferenced rate already starts on the exact same effective date,
    // update it in place rather than triggering an overlap error.
    for (final existing in existingEntities) {
      if (existing.effectiveFrom == effectiveFromIso &&
          existing.effectiveTo == null) {
        final isLocked = await _db.stockMovementDao.hasMovementsUsingRate(
          existing.id,
        );
        if (!isLocked) {
          await _db.processMemberDao.updateRateById(
            existing.id,
            MemberProcessRatesCompanion(
              ratePaise: Value(ratePaise),
              notes: Value(_nullIfBlank(notes) ?? existing.notes),
              updatedBy: Value(actor),
              updatedAt: Value(now),
            ),
          );
          await _db.attachmentAuditDao.insertAuditLog(
            AuditLogsCompanion(
              id: Value(_idGenerator.nextEntityId()),
              entityType: const Value('member_process_rates'),
              entityId: Value(existing.id),
              actionType: const Value('UPDATE'),
              actor: Value(actor),
              previousValueJson: Value(
                jsonEncode({'rate_paise': existing.ratePaise}),
              ),
              newValueJson: Value(jsonEncode({'rate_paise': ratePaise})),
              transactionAt: Value(now),
              recordedAt: Value(now),
            ),
          );
          return;
        }
      }
    }

    final autoClosable = _rateResolver.findAutoClosableOpenRate(
      newEffectiveFrom: effectiveFromIso,
      existingRates: existingEntities,
    );

    final validation = _rateResolver.validateCandidateRate(
      ratePaise: ratePaise,
      effectiveFrom: effectiveFromIso,
      effectiveTo: null,
      existingRates: existingEntities,
      autoCloseRateId: autoClosable?.id,
    );
    if (!validation.isValid) {
      throw DomainValidationException(
        'rate_overlap',
        'A conflicting worker rate already exists for this process on $effectiveFromIso. Update it in Rate History.',
      );
    }

    if (autoClosable != null) {
      final closedTo = _rateResolver.previousDayIso(effectiveFromIso);
      await _db.processMemberDao.updateRateById(
        autoClosable.id,
        MemberProcessRatesCompanion(
          effectiveTo: Value(closedTo),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );
      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('member_process_rates'),
          entityId: Value(autoClosable.id),
          actionType: const Value('UPDATE'),
          actor: Value(actor),
          previousValueJson: Value(
            jsonEncode({
              'effective_from': autoClosable.effectiveFrom,
              'effective_to': autoClosable.effectiveTo,
              'rate_paise': autoClosable.ratePaise,
            }),
          ),
          newValueJson: Value(
            jsonEncode({
              'effective_from': autoClosable.effectiveFrom,
              'effective_to': closedTo,
              'rate_paise': autoClosable.ratePaise,
            }),
          ),
          reason: Value(
            'Auto-closed open-ended rate before new rate effective $effectiveFromIso',
          ),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );
    }

    final rateId = _idGenerator.nextEntityId();
    final cleanNotes = _nullIfBlank(notes);
    await _db.processMemberDao.insertMemberProcessRate(
      MemberProcessRatesCompanion(
        id: Value(rateId),
        memberId: Value(workerId),
        processId: Value(processId),
        ratePaise: Value(ratePaise),
        effectiveFrom: Value(effectiveFromIso),
        effectiveTo: const Value(null),
        notes: Value(cleanNotes),
        createdBy: Value(actor),
        updatedBy: Value(actor),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    await _db.attachmentAuditDao.insertAuditLog(
      AuditLogsCompanion(
        id: Value(_idGenerator.nextEntityId()),
        entityType: const Value('member_process_rates'),
        entityId: Value(rateId),
        actionType: const Value('CREATE'),
        actor: Value(actor),
        newValueJson: Value(
          jsonEncode({
            'member_id': workerId,
            'process_id': processId,
            'rate_paise': ratePaise,
            'effective_from': effectiveFromIso,
            'notes': cleanNotes,
          }),
        ),
        transactionAt: Value(now),
        recordedAt: Value(now),
      ),
    );
  }

  @override
  Future<WorkerEntity> createWorkerWithProcesses({
    required String name,
    String? phone,
    String? address,
    String? notes,
    bool isActive = true,
    required List<WorkerProcessConfigInput> processConfigs,
  }) async {
    _validateWorkerInputs(
      name: name,
      phone: phone,
      address: address,
      notes: notes,
    );
    _validateProcessConfigs(processConfigs);
    final cleanName = name.trim();

    return _txRunner.runInTransaction(() async {
      // Verify all selected processes exist & are active before writing.
      for (final cfg in processConfigs) {
        final proc = await _db.processMemberDao.findProcessById(cfg.processId);
        if (proc == null || proc.deletedAt != null || proc.isActive != 1) {
          throw const DomainValidationException(
            'inactive_process',
            'Cannot assign an inactive or unavailable process to a worker.',
          );
        }
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final todayIso = IstDateTimeHelper.toIstBusinessDate(now);
      final workerId = _idGenerator.nextEntityId();
      final actor = await _currentActor();
      final cleanPhone = _nullIfBlank(phone);
      final cleanAddress = _nullIfBlank(address);
      final cleanNotes = _nullIfBlank(notes);

      await _db.processMemberDao.insertMember(
        MembersCompanion(
          id: Value(workerId),
          name: Value(cleanName),
          phone: Value(cleanPhone),
          address: Value(cleanAddress),
          notes: Value(cleanNotes),
          isActive: Value(isActive ? 1 : 0),
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
          entityId: Value(workerId),
          actionType: const Value('CREATE'),
          actor: Value(actor),
          newValueJson: Value(
            jsonEncode({
              'name': cleanName,
              'phone': cleanPhone,
              'address': cleanAddress,
              'notes': cleanNotes,
              'is_active': isActive,
              'assigned_processes_count': processConfigs.length,
            }),
          ),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );

      for (final cfg in processConfigs) {
        final linkId = _idGenerator.nextEntityId();
        await _db.processMemberDao.insertMemberProcess(
          MemberProcessesCompanion(
            id: Value(linkId),
            memberId: Value(workerId),
            processId: Value(cfg.processId),
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
                'process_id': cfg.processId,
                'is_active': true,
              }),
            ),
            transactionAt: Value(now),
            recordedAt: Value(now),
          ),
        );

        if (cfg.customRatePaise != null) {
          final effFrom =
              (cfg.effectiveFrom != null &&
                  cfg.effectiveFrom!.trim().isNotEmpty)
              ? cfg.effectiveFrom!.trim()
              : todayIso;
          await _upsertWorkerProcessRateInTx(
            workerId: workerId,
            processId: cfg.processId,
            ratePaise: cfg.customRatePaise!,
            effectiveFromIso: effFrom,
            notes: cfg.notes,
            actor: actor,
            now: now,
          );
        }
      }

      final created = await _db.processMemberDao.findMemberById(workerId);
      return _workerToEntity(created!);
    });
  }

  @override
  Future<WorkerEntity> updateWorkerWithProcesses({
    required String workerId,
    required String name,
    String? phone,
    String? address,
    String? notes,
    required bool isActive,
    required List<WorkerProcessConfigInput> processConfigs,
  }) async {
    _validateWorkerInputs(
      name: name,
      phone: phone,
      address: address,
      notes: notes,
    );
    _validateProcessConfigs(processConfigs);
    final cleanName = name.trim();

    return _txRunner.runInTransaction(() async {
      final existing = await _db.processMemberDao.findMemberById(workerId);
      if (existing == null || existing.deletedAt != null) {
        throw const LocalStorageException('Worker not found.');
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final todayIso = IstDateTimeHelper.toIstBusinessDate(now);
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
          actionType: const Value('UPDATE'),
          actor: Value(actor),
          previousValueJson: Value(
            jsonEncode({
              'name': existing.name,
              'phone': existing.phone,
              'address': existing.address,
              'notes': existing.notes,
              'is_active': existing.isActive == 1,
            }),
          ),
          newValueJson: Value(
            jsonEncode({
              'name': cleanName,
              'phone': cleanPhone,
              'address': cleanAddress,
              'notes': cleanNotes,
              'is_active': isActive,
              'assigned_processes_count': processConfigs.length,
            }),
          ),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );

      // Reconcile process assignments (soft-deactivate removed links to
      // preserve all historical movements, ledger entries, and rate records).
      final existingLinks = await _db.processMemberDao.getAssignmentsForMember(
        workerId,
        activeOnly: false,
      );
      final linkByProcessId = {for (final l in existingLinks) l.processId: l};
      final desiredProcessIds = {
        for (final cfg in processConfigs) cfg.processId,
      };

      for (final link in existingLinks) {
        if (link.isActive == 1 && !desiredProcessIds.contains(link.processId)) {
          await _db.processMemberDao.updateMemberProcessById(
            link.id,
            MemberProcessesCompanion(
              isActive: const Value(0),
              updatedAt: Value(now),
            ),
          );
          await _db.attachmentAuditDao.insertAuditLog(
            AuditLogsCompanion(
              id: Value(_idGenerator.nextEntityId()),
              entityType: const Value('member_processes'),
              entityId: Value(link.id),
              actionType: const Value('DEACTIVATE'),
              actor: Value(actor),
              previousValueJson: Value(
                jsonEncode({
                  'member_id': workerId,
                  'process_id': link.processId,
                  'is_active': true,
                }),
              ),
              newValueJson: Value(
                jsonEncode({
                  'member_id': workerId,
                  'process_id': link.processId,
                  'is_active': false,
                }),
              ),
              transactionAt: Value(now),
              recordedAt: Value(now),
            ),
          );
        }
      }

      for (final cfg in processConfigs) {
        final existingLink = linkByProcessId[cfg.processId];
        if (existingLink == null) {
          final proc = await _db.processMemberDao.findProcessById(
            cfg.processId,
          );
          if (proc == null || proc.deletedAt != null || proc.isActive != 1) {
            throw const DomainValidationException(
              'inactive_process',
              'Cannot assign an inactive process to a worker.',
            );
          }
          final linkId = _idGenerator.nextEntityId();
          await _db.processMemberDao.insertMemberProcess(
            MemberProcessesCompanion(
              id: Value(linkId),
              memberId: Value(workerId),
              processId: Value(cfg.processId),
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
                  'process_id': cfg.processId,
                  'is_active': true,
                }),
              ),
              transactionAt: Value(now),
              recordedAt: Value(now),
            ),
          );
        } else if (existingLink.isActive == 0) {
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
                  'process_id': cfg.processId,
                  'is_active': false,
                }),
              ),
              newValueJson: Value(
                jsonEncode({
                  'member_id': workerId,
                  'process_id': cfg.processId,
                  'is_active': true,
                }),
              ),
              transactionAt: Value(now),
              recordedAt: Value(now),
            ),
          );
        }

        if (cfg.customRatePaise != null) {
          final effFrom =
              (cfg.effectiveFrom != null &&
                  cfg.effectiveFrom!.trim().isNotEmpty)
              ? cfg.effectiveFrom!.trim()
              : todayIso;
          await _upsertWorkerProcessRateInTx(
            workerId: workerId,
            processId: cfg.processId,
            ratePaise: cfg.customRatePaise!,
            effectiveFromIso: effFrom,
            notes: cfg.notes,
            actor: actor,
            now: now,
          );
        }
      }

      final updated = await _db.processMemberDao.findMemberById(workerId);
      return _workerToEntity(updated!);
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
  Future<WorkerProcessAssignmentEntity> assignProcessWithOptionalRate({
    required String workerId,
    required String processId,
    int? customRatePaise,
    String? notes,
  }) async {
    if (customRatePaise != null) {
      if (customRatePaise < 0) {
        throw const DomainValidationException(
          'rate_negative',
          'Rate per piece cannot be negative.',
        );
      }
      if (customRatePaise > ValidationLimits.maxAmountPaise) {
        throw const DomainValidationException(
          'rate_too_large',
          'Rate exceeds maximum allowed limit.',
        );
      }
    }

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
      final todayIso = IstDateTimeHelper.toIstBusinessDate(now);
      final actor = await _currentActor();

      late final String finalLinkId;
      late final int createdAt;

      if (existingLink != null) {
        if (existingLink.isActive == 1) {
          throw const DomainValidationException(
            'duplicate_assignment',
            'This process is already assigned to the worker.',
          );
        }
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
        finalLinkId = existingLink.id;
        createdAt = existingLink.createdAt;
      } else {
        finalLinkId = _idGenerator.nextEntityId();
        createdAt = now;
        await _db.processMemberDao.insertMemberProcess(
          MemberProcessesCompanion(
            id: Value(finalLinkId),
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
            entityId: Value(finalLinkId),
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
      }

      if (customRatePaise != null) {
        await _upsertWorkerProcessRateInTx(
          workerId: workerId,
          processId: processId,
          ratePaise: customRatePaise,
          effectiveFromIso: todayIso,
          notes: notes,
          actor: actor,
          now: now,
        );
      }

      return WorkerProcessAssignmentEntity(
        id: finalLinkId,
        workerId: workerId,
        processId: processId,
        processName: process.name,
        processIsActive: process.isActive == 1,
        isActive: true,
        createdAt: createdAt,
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
