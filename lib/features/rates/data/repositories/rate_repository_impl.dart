import 'dart:convert';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/rates/domain/entities/rate_entities.dart';
import 'package:business_manager/features/rates/domain/repositories/rate_repository.dart';
import 'package:business_manager/features/rates/domain/services/member_process_rate_resolver.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: RateRepository)
final class RateRepositoryImpl implements RateRepository {
  RateRepositoryImpl(this._db, this._txRunner, this._idGenerator);

  final AppDatabase _db;
  final DatabaseTransactionRunner _txRunner;
  final IdGenerator _idGenerator;
  static const MemberProcessRateResolver _resolver =
      MemberProcessRateResolver();

  Future<String?> _currentActor() async {
    final profile = await _db.businessProfileDao.getProfile();
    return profile?.ownerName;
  }

  @override
  Future<List<MemberProcessRateEntity>> getRateHistory({
    required String workerId,
    required String processId,
  }) async {
    final rows = await _db.processMemberDao.getActiveRates(workerId, processId);
    // Return newest effective_from first for UI history display
    final entities = rows.map(_toEntity).toList()
      ..sort((a, b) => b.effectiveFrom.compareTo(a.effectiveFrom));
    return entities;
  }

  @override
  Future<List<MemberProcessRateEntity>> getAllRatesForWorker(
    String workerId,
  ) async {
    final rows = await _db.processMemberDao.getAllActiveRatesForMember(
      workerId,
    );
    return rows.map(_toEntity).toList();
  }

  @override
  Future<MemberProcessRateEntity?> getRateById(String rateId) async {
    final row = await _db.processMemberDao.findRateById(rateId);
    if (row == null || row.deletedAt != null) return null;
    return _toEntity(row);
  }

  @override
  Future<bool> isRateLockedByHistory(String rateId) {
    return _db.stockMovementDao.hasMovementsUsingRate(rateId);
  }

  @override
  Future<MemberProcessRateEntity?> findAutoClosableOpenRate({
    required String workerId,
    required String processId,
    required String newEffectiveFrom,
  }) async {
    final existing = (await _db.processMemberDao.getActiveRates(
      workerId,
      processId,
    )).map(_toEntity).toList();
    return _resolver.findAutoClosableOpenRate(
      newEffectiveFrom: newEffectiveFrom,
      existingRates: existing,
    );
  }

  @override
  Future<MemberProcessRateEntity> addRate({
    required String workerId,
    required String processId,
    required int ratePaise,
    required String effectiveFrom,
    String? effectiveTo,
    String? notes,
    bool autoClosePreviousOpenRate = false,
  }) async {
    final cleanFrom = effectiveFrom.trim();
    final cleanTo = _nullIfBlank(effectiveTo);
    final cleanNotes = _nullIfBlank(notes);

    return _txRunner.runInTransaction(() async {
      final worker = await _db.processMemberDao.findMemberById(workerId);
      if (worker == null || worker.deletedAt != null) {
        throw const LocalStorageException('Worker not found.');
      }
      final process = await _db.processMemberDao.findProcessById(processId);
      if (process == null || process.deletedAt != null) {
        throw const LocalStorageException('Process not found.');
      }

      final existing = (await _db.processMemberDao.getActiveRates(
        workerId,
        processId,
      )).map(_toEntity).toList();

      final autoClosable = autoClosePreviousOpenRate
          ? _resolver.findAutoClosableOpenRate(
              newEffectiveFrom: cleanFrom,
              existingRates: existing,
            )
          : null;

      final validation = _resolver.validateCandidateRate(
        ratePaise: ratePaise,
        effectiveFrom: cleanFrom,
        effectiveTo: cleanTo,
        existingRates: existing,
        autoCloseRateId: autoClosable?.id,
      );
      if (!validation.isValid) {
        throw _mapValidationError(validation.errorCode!);
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await _currentActor();

      // Auto-close previous open-ended rate atomically when confirmed
      if (autoClosable != null) {
        final closedTo = _resolver.previousDayIso(cleanFrom);
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
              'Auto-closed open-ended rate before new rate effective $cleanFrom',
            ),
            transactionAt: Value(now),
            recordedAt: Value(now),
          ),
        );
      }

      final rateId = _idGenerator.nextEntityId();
      await _db.processMemberDao.insertMemberProcessRate(
        MemberProcessRatesCompanion(
          id: Value(rateId),
          memberId: Value(workerId),
          processId: Value(processId),
          ratePaise: Value(ratePaise),
          effectiveFrom: Value(cleanFrom),
          effectiveTo: Value(cleanTo),
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
              'effective_from': cleanFrom,
              'effective_to': cleanTo,
              'notes': cleanNotes,
            }),
          ),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );

      final created = await _db.processMemberDao.findRateById(rateId);
      return _toEntity(created!);
    });
  }

  @override
  Future<MemberProcessRateEntity> updateRate({
    required String rateId,
    required int ratePaise,
    required String effectiveFrom,
    String? effectiveTo,
    String? notes,
  }) async {
    final cleanFrom = effectiveFrom.trim();
    final cleanTo = _nullIfBlank(effectiveTo);
    final cleanNotes = _nullIfBlank(notes);

    return _txRunner.runInTransaction(() async {
      final existingRow = await _db.processMemberDao.findRateById(rateId);
      if (existingRow == null || existingRow.deletedAt != null) {
        throw const LocalStorageException('Rate record not found.');
      }

      // Historical safety: never overwrite a rate already referenced by stock movements
      final isUsedByHistory = await _db.stockMovementDao.hasMovementsUsingRate(
        rateId,
      );
      if (isUsedByHistory) {
        throw const DomainValidationException(
          'rate_locked_by_history',
          'Cannot edit a rate that is already used by historical stock movements.',
        );
      }

      final allRates = (await _db.processMemberDao.getActiveRates(
        existingRow.memberId,
        existingRow.processId,
      )).map(_toEntity).toList();

      final validation = _resolver.validateCandidateRate(
        ratePaise: ratePaise,
        effectiveFrom: cleanFrom,
        effectiveTo: cleanTo,
        existingRates: allRates,
        excludeRateId: rateId,
      );
      if (!validation.isValid) {
        throw _mapValidationError(validation.errorCode!);
      }

      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await _currentActor();

      await _db.processMemberDao.updateRateById(
        rateId,
        MemberProcessRatesCompanion(
          ratePaise: Value(ratePaise),
          effectiveFrom: Value(cleanFrom),
          effectiveTo: Value(cleanTo),
          notes: Value(cleanNotes),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('member_process_rates'),
          entityId: Value(rateId),
          actionType: const Value('UPDATE'),
          actor: Value(actor),
          previousValueJson: Value(
            jsonEncode({
              'rate_paise': existingRow.ratePaise,
              'effective_from': existingRow.effectiveFrom,
              'effective_to': existingRow.effectiveTo,
              'notes': existingRow.notes,
            }),
          ),
          newValueJson: Value(
            jsonEncode({
              'rate_paise': ratePaise,
              'effective_from': cleanFrom,
              'effective_to': cleanTo,
              'notes': cleanNotes,
            }),
          ),
          transactionAt: Value(now),
          recordedAt: Value(now),
        ),
      );

      final updated = await _db.processMemberDao.findRateById(rateId);
      return _toEntity(updated!);
    });
  }

  @override
  Future<RateResolutionResult> resolveRate({
    required String workerId,
    required String processId,
    required int transactionAtUtcMillis,
  }) async {
    final rows = await _db.processMemberDao.getActiveRates(workerId, processId);
    final entities = rows.map(_toEntity).toList();
    return _resolver.resolve(
      workerId: workerId,
      processId: processId,
      transactionAtUtcMillis: transactionAtUtcMillis,
      rates: entities,
    );
  }

  DomainValidationException _mapValidationError(RateValidationErrorCode code) {
    return switch (code) {
      RateValidationErrorCode.negativeRate => const DomainValidationException(
        'rate_negative',
        'Rate per piece cannot be negative.',
      ),
      RateValidationErrorCode.invalidEffectiveFrom =>
        const DomainValidationException(
          'rate_invalid_from_date',
          'Effective from date must be a valid YYYY-MM-DD date.',
        ),
      RateValidationErrorCode.invalidEffectiveTo =>
        const DomainValidationException(
          'rate_invalid_to_date',
          'Effective to date must be a valid YYYY-MM-DD date.',
        ),
      RateValidationErrorCode.effectiveToBeforeFrom =>
        const DomainValidationException(
          'rate_to_before_from',
          'Effective to date cannot be earlier than effective from date.',
        ),
      RateValidationErrorCode.overlappingPeriod =>
        const DomainValidationException(
          'rate_overlap',
          'Effective date range overlaps with an existing rate.',
        ),
      RateValidationErrorCode.multipleOpenEndedRates =>
        const DomainValidationException(
          'rate_multiple_open_ended',
          'Another ongoing rate already exists for this worker and process.',
        ),
    };
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  MemberProcessRateEntity _toEntity(MemberProcessRateRow row) =>
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
