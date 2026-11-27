import 'dart:convert';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/database/mappers/actor_resolver.dart';
import 'package:business_manager/core/database/mappers/ledger_row_mappers.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/features/accounting/domain/calculators/labour_calculator.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/notifications/data/services/notification_refresh_coordinator.dart';
import 'package:business_manager/features/production_history/domain/calculators/production_history_calculator.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/rates/domain/entities/rate_entities.dart';
import 'package:business_manager/features/rates/domain/services/member_process_rate_resolver.dart';
import 'package:business_manager/features/stock_movements/data/repositories/stock_movement_query_delegate.dart';
import 'package:business_manager/features/stock_movements/domain/calculators/stock_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: StockMovementRepository)
final class StockMovementRepositoryImpl implements StockMovementRepository {
  StockMovementRepositoryImpl(this._db, this._txRunner, this._idGenerator)
    : _queryDelegate = StockMovementQueryDelegate(
        _db,
        _stockCalc,
        _prodCalc,
        _rateResolver,
      );

  final AppDatabase _db;
  final DatabaseTransactionRunner _txRunner;
  final IdGenerator _idGenerator;
  final StockMovementQueryDelegate _queryDelegate;

  static const StockCalculator _stockCalc = StockCalculator();
  static const LabourCalculator _labourCalc = LabourCalculator();
  static const ProductionHistoryCalculator _prodCalc =
      ProductionHistoryCalculator();
  static const MemberProcessRateResolver _rateResolver =
      MemberProcessRateResolver();

  @override
  Future<RateResolutionResult> previewRate({
    required String workerId,
    required String processId,
    required int transactionAtUtcMillis,
  }) => _queryDelegate.previewRate(
    workerId: workerId,
    processId: processId,
    transactionAtUtcMillis: transactionAtUtcMillis,
  );

  @override
  Future<List<StockMovementEntity>> getMovementsForColour(
    String designColourId,
  ) => _queryDelegate.getMovementsForColour(designColourId);

  @override
  Future<Map<String, int>> getPendingInspectionByIssue() =>
      _queryDelegate.getPendingInspectionByIssue();

  @override
  Future<List<LabourEntryEntity>> getLabourEntriesForLot(String lotId) =>
      _queryDelegate.getLabourEntriesForLot(lotId);

  @override
  Future<DesignColourStockBalance?> getDesignColourBalance(
    String designColourId,
  ) => _queryDelegate.getDesignColourBalance(designColourId);

  @override
  Future<List<DesignColourStockBalance>> getAllDesignColourBalances({
    String? lotId,
    bool onlyWithDamaged = false,
  }) => _queryDelegate.getAllDesignColourBalances(
    lotId: lotId,
    onlyWithDamaged: onlyWithDamaged,
  );

  @override
  Future<List<OpenIssueSummary>> getOpenIssues({
    String? workerId,
    String? processId,
    String? lotId,
    String? designColourId,
  }) => _queryDelegate.getOpenIssues(
    workerId: workerId,
    processId: processId,
    lotId: lotId,
    designColourId: designColourId,
  );

  @override
  Future<OpenIssueSummary?> getIssueDetail(String issueId) =>
      _queryDelegate.getIssueDetail(issueId);

  @override
  Future<List<StockMovementView>> getMovementHistory({
    StockMovementFilter filter = const StockMovementFilter(),
  }) => _queryDelegate.getMovementHistory(filter: filter);

  @override
  Future<List<WorkerStockSummary>> getWorkerStockSummaries() =>
      _queryDelegate.getWorkerStockSummaries();

  @override
  Future<List<ProcessStockSummary>> getProcessStockSummaries() =>
      _queryDelegate.getProcessStockSummaries();

  @override
  Future<RecentIssueSuggestions> getRecentIssueSuggestions() =>
      _queryDelegate.getRecentIssueSuggestions();

  @override
  Future<StockMovementEntity> issueStock({
    required String designColourId,
    required String processId,
    required String workerId,
    required int quantity,
    required int transactionAtUtcMillis,
    String? notes,
    bool allowRateOverride = false,
    int? overrideRatePaise,
    String? overrideReason,
    String? jobProcessId,
    String? clientRequestId,
  }) async {
    final reqId = clientRequestId?.trim().isEmpty ?? true
        ? _idGenerator.nextRequestId()
        : clientRequestId!.trim();

    return _txRunner
        .runInTransaction(() async {
          final existingByReq = await _db.stockMovementDao
              .findByClientRequestId(reqId);
          if (existingByReq != null) {
            return LedgerRowMappers.stockMovement(existingByReq);
          }

          if (quantity <= 0) {
            throw const DomainValidationException(
              'invalid_quantity',
              'Issue quantity must be greater than zero.',
            );
          }
          if (quantity > ValidationLimits.maxQuantity) {
            throw const DomainValidationException(
              'quantity_too_large',
              'Issue quantity exceeds maximum allowed limit.',
            );
          }
          if (!AppValidators.dateValidator(transactionAtUtcMillis).isValid) {
            throw const DomainValidationException(
              'invalid_date',
              'Transaction date is invalid.',
            );
          }
          if ((notes?.trim().length ?? 0) > ValidationLimits.maxNotesLength ||
              (overrideReason?.trim().length ?? 0) >
                  ValidationLimits.maxNotesLength) {
            throw const DomainValidationException(
              'text_too_long',
              'Notes or override reason exceeds maximum allowed length.',
            );
          }

          final colour = await _db.lotDao.findDesignColourById(designColourId);
          if (colour == null || colour.deletedAt != null) {
            throw const DomainValidationException(
              'colour_not_found',
              'Selected colour was not found.',
            );
          }
          final design = await _db.lotDao.findDesignById(colour.lotDesignId);
          if (design == null || design.deletedAt != null) {
            throw const DomainValidationException(
              'design_not_found',
              'Selected design was not found.',
            );
          }
          final lot = await _db.lotDao.findLotById(design.lotId);
          if (lot == null || lot.deletedAt != null) {
            throw const DomainValidationException(
              'lot_not_found',
              'Selected lot was not found.',
            );
          }

          final worker = await _db.processMemberDao.findMemberById(workerId);
          if (worker == null ||
              worker.deletedAt != null ||
              worker.isActive != 1) {
            throw const DomainValidationException(
              'worker_inactive',
              'Selected worker is inactive or unavailable.',
            );
          }

          final process = await _db.processMemberDao.findProcessById(processId);
          if (process == null ||
              process.deletedAt != null ||
              process.isActive != 1) {
            throw const DomainValidationException(
              'process_inactive',
              'Selected process is inactive or unavailable.',
            );
          }

          final link = await _db.processMemberDao.findMemberProcessLink(
            workerId,
            processId,
          );
          if (link == null || link.isActive != 1) {
            throw const DomainValidationException(
              'worker_not_assigned',
              'Selected worker is not actively assigned to this process.',
            );
          }

          final resolution = await _queryDelegate.resolveWithProcessFallback(
            workerId: workerId,
            processId: processId,
            transactionAtUtcMillis: transactionAtUtcMillis,
            processRow: process,
          );

          String? sourceRateId;
          int appliedRatePaise;
          bool isOverridden = false;
          String? cleanedOverrideReason;

          if (allowRateOverride) {
            if (overrideRatePaise == null || overrideRatePaise < 0) {
              throw const DomainValidationException(
                'invalid_rate',
                'Rate cannot be negative.',
              );
            }
            if (overrideRatePaise > ValidationLimits.maxAmountPaise) {
              throw const DomainValidationException(
                'rate_too_large',
                'Override rate exceeds maximum allowed limit.',
              );
            }
            if (overrideReason == null || overrideReason.trim().isEmpty) {
              throw const DomainValidationException(
                'override_reason_required',
                'A reason is required for manual rate override.',
              );
            }
            isOverridden = true;
            appliedRatePaise = overrideRatePaise;
            cleanedOverrideReason = overrideReason.trim();
            if (resolution is RateResolutionFound) {
              sourceRateId = resolution.rate.id;
            }
          } else {
            switch (resolution) {
              case RateResolutionFound(:final rate):
                sourceRateId = rate.id;
                appliedRatePaise = rate.ratePaise;
              case RateResolutionProcessDefault(:final ratePaise):
                sourceRateId = null;
                appliedRatePaise = ratePaise;
              case RateResolutionMissing():
                throw const DomainValidationException(
                  'rate_missing',
                  'No effective historical rate or process default rate configured for this worker and process on the transaction date.',
                );
              case RateResolutionConflict():
                throw const DomainValidationException(
                  'rate_conflict',
                  'Conflicting overlapping rates exist for this worker and process on the transaction date.',
                );
            }
          }

          final existingMovements =
              (await _db.stockMovementDao.getMovementsForDesignColour(
                designColourId,
              )).map(LedgerRowMappers.stockMovement).toList();
          final qtyError = _stockCalc.validateIssueQuantity(
            initialQuantity: colour.initialQuantity,
            existingMovementsForColour: existingMovements,
            issueQuantity: quantity,
          );
          if (qtyError != null) {
            throw DomainValidationException(
              qtyError,
              'Cannot issue $quantity pieces: exceeds available in-house good stock.',
            );
          }

          const lockedBillingMode = BillingMode.receivedQty;
          const lockedIncludeDamaged = false;

          final now = IstDateTimeHelper.nowUtcMillis();
          final actor = await ActorResolver.resolveRequired(_db);
          final movementId = _idGenerator.nextEntityId();
          final cleanedNotes = notes?.trim().isEmpty ?? true
              ? null
              : notes!.trim();

          await _db.stockMovementDao.insertMovement(
            StockMovementsCompanion(
              id: Value(movementId),
              lotId: Value(lot.id),
              lotDesignId: Value(design.id),
              designColourId: Value(colour.id),
              processId: Value(process.id),
              memberId: Value(worker.id),
              jobProcessId: Value(jobProcessId),
              clientRequestId: Value(reqId),
              movementType: Value(StockMovementType.issue.dbValue),
              quantity: Value(quantity),
              sourceRateId: Value(sourceRateId),
              appliedRatePaise: Value(appliedRatePaise),
              isRateOverridden: Value(isOverridden ? 1 : 0),
              overrideReason: Value(cleanedOverrideReason),
              lockedBillingMode: Value(lockedBillingMode.dbValue),
              lockedIncludeDamaged: const Value(0),
              notes: Value(cleanedNotes),
              transactionAt: Value(transactionAtUtcMillis),
              recordedAt: Value(now),
              createdBy: Value(actor),
              updatedBy: Value(actor),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

          final plannedLabour = _labourCalc.planForIssue(
            quantity: quantity,
            appliedRatePaise: appliedRatePaise,
            lockedBillingMode: lockedBillingMode,
          );
          await _db.labourEntryDao.insertEntry(
            LabourEntriesCompanion(
              id: Value(_idGenerator.nextEntityId()),
              stockMovementId: Value(movementId),
              memberId: Value(worker.id),
              processId: Value(process.id),
              lotId: Value(lot.id),
              basisType: Value(plannedLabour.basisType.dbValue),
              quantity: Value(plannedLabour.quantity),
              ratePaise: Value(plannedLabour.ratePaise),
              amountPaise: Value(plannedLabour.amountPaise),
              isPayable: Value(plannedLabour.isPayable ? 1 : 0),
              transactionAt: Value(transactionAtUtcMillis),
              recordedAt: Value(now),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

          await _db.attachmentAuditDao.insertAuditLog(
            AuditLogsCompanion(
              id: Value(_idGenerator.nextEntityId()),
              entityType: const Value('stock_movements'),
              entityId: Value(movementId),
              actionType: Value(isOverridden ? 'RATE_OVERRIDE' : 'CREATE'),
              actor: Value(actor),
              newValueJson: Value(
                jsonEncode({
                  'movement_type': StockMovementType.issue.dbValue,
                  'lot_number': lot.lotNumber,
                  'design': design.designName,
                  'colour': colour.colourName,
                  'process': process.name,
                  'worker': worker.name,
                  'quantity': quantity,
                  'applied_rate_paise': appliedRatePaise,
                  'source_rate_id': sourceRateId,
                  'locked_billing_mode': lockedBillingMode.dbValue,
                  'locked_include_damaged': lockedIncludeDamaged,
                }),
              ),
              reason: Value(cleanedOverrideReason),
              transactionAt: Value(transactionAtUtcMillis),
              recordedAt: Value(now),
            ),
          );

          final inserted = await _db.stockMovementDao.findById(movementId);
          return LedgerRowMappers.stockMovement(inserted!);
        })
        .then((result) {
          NotificationRefreshCoordinator.requestBackgroundRefreshIfRegistered();
          return result;
        });
  }

  @override
  Future<SettlementBatchResult> recordSettlement({
    required String parentIssueId,
    required int goodQuantity,
    required int damagedQuantity,
    required int lostQuantity,
    required int shortageQuantity,
    required int transactionAtUtcMillis,
    String? reason,
    String? notes,
    String? approvedBy,
    bool authorizedViaPin = false,
    String? clientRequestId,
  }) async {
    final baseReqId = clientRequestId?.trim().isEmpty ?? true
        ? _idGenerator.nextRequestId()
        : clientRequestId!.trim();

    return _txRunner
        .runInTransaction(() async {
          final parentRow = await _db.stockMovementDao.findById(parentIssueId);
          if (parentRow == null) {
            throw const DomainValidationException(
              'parent_issue_inactive',
              'Original stock issue was not found.',
            );
          }
          final parentIssue = LedgerRowMappers.stockMovement(parentRow);
          final existingMovements =
              (await _db.stockMovementDao.getMovementsForDesignColour(
                parentIssue.designColourId,
              )).map(LedgerRowMappers.stockMovement).toList();

          final componentSpecs = <(StockMovementType, int, String)>[
            if (goodQuantity > 0)
              (StockMovementType.returnGood, goodQuantity, '$baseReqId:GOOD'),
            if (damagedQuantity > 0)
              (
                StockMovementType.returnDamaged,
                damagedQuantity,
                '$baseReqId:DAMAGED',
              ),
            if (lostQuantity > 0)
              (
                StockMovementType.settlementLost,
                lostQuantity,
                '$baseReqId:LOST',
              ),
            if (shortageQuantity > 0)
              (
                StockMovementType.settlementShortage,
                shortageQuantity,
                '$baseReqId:SHORTAGE',
              ),
          ];

          if (componentSpecs.isNotEmpty) {
            final alreadyCommitted = <StockMovementEntity>[];
            for (final spec in componentSpecs) {
              final existing = await _db.stockMovementDao.findByClientRequestId(
                spec.$3,
              );
              if (existing != null) {
                alreadyCommitted.add(LedgerRowMappers.stockMovement(existing));
              }
            }
            if (alreadyCommitted.isNotEmpty) {
              final remaining = _stockCalc.calculateIssueRemainingPending(
                issue: parentIssue,
                allMovementsForColour: existingMovements,
              );
              return SettlementBatchResult(
                createdMovements: alreadyCommitted,
                remainingPending: remaining,
                wasIdempotentReplay: true,
              );
            }
          }

          if (!AppValidators.dateValidator(transactionAtUtcMillis).isValid) {
            throw const DomainValidationException(
              'invalid_date',
              'Transaction date is invalid.',
            );
          }
          if (goodQuantity > ValidationLimits.maxQuantity ||
              damagedQuantity > ValidationLimits.maxQuantity ||
              lostQuantity > ValidationLimits.maxQuantity ||
              shortageQuantity > ValidationLimits.maxQuantity) {
            throw const DomainValidationException(
              'quantity_too_large',
              'Settlement quantity exceeds maximum allowed limit.',
            );
          }
          if ((reason?.trim().length ?? 0) > ValidationLimits.maxNotesLength ||
              (notes?.trim().length ?? 0) > ValidationLimits.maxNotesLength) {
            throw const DomainValidationException(
              'text_too_long',
              'Reason or notes exceed maximum allowed length.',
            );
          }

          final validationErr = _stockCalc.validateSettlementBatch(
            parentIssue: parentIssue,
            existingMovementsForColour: existingMovements,
            goodQty: goodQuantity,
            damagedQty: damagedQuantity,
            lostQty: lostQuantity,
            shortageQty: shortageQuantity,
            reason: reason,
          );
          if (validationErr != null) {
            throw DomainValidationException(
              validationErr,
              'Invalid settlement submission ($validationErr).',
            );
          }

          final pendingMaps = await _queryDelegate.loadPendingInspectionMaps(
            existingMovements,
          );
          final pendingInsp = pendingMaps.pendingByIssue[parentIssue.id] ?? 0;
          final rawRemaining = _stockCalc.calculateIssueRemainingPending(
            issue: parentIssue,
            allMovementsForColour: existingMovements,
          );
          final trueOutstanding = (rawRemaining - pendingInsp).clamp(
            0,
            parentIssue.quantity,
          );
          if (goodQuantity + damagedQuantity + lostQuantity + shortageQuantity >
              trueOutstanding) {
            throw const DomainValidationException(
              'exceeds_pending_quantity',
              'Settlement quantity exceeds outstanding pieces with worker (excluding pending inspection).',
            );
          }

          final now = IstDateTimeHelper.nowUtcMillis();
          final actor = await ActorResolver.resolveRequired(
            _db,
            explicit: approvedBy,
          );
          final cleanedReason = reason?.trim().isEmpty ?? true
              ? null
              : reason!.trim();
          final cleanedNotes = notes?.trim().isEmpty ?? true
              ? null
              : notes!.trim();
          const lockedMode = BillingMode.receivedQty;
          const lockedIncludeDamaged = false;

          final issueLabourAlreadyPaid = await _db.labourEntryDao
              .issueHasPayableLabour(parentIssue.id);

          final created = <StockMovementEntity>[];
          String? goodMovId;
          String? dmgMovId;
          String? createdLabourId;
          var earnedPaise = 0;

          for (final (type, qty, reqId) in componentSpecs) {
            final movId = _idGenerator.nextEntityId();
            if (type == StockMovementType.returnGood) goodMovId = movId;
            if (type == StockMovementType.returnDamaged) dmgMovId = movId;

            await _db.stockMovementDao.insertMovement(
              StockMovementsCompanion(
                id: Value(movId),
                lotId: Value(parentIssue.lotId),
                lotDesignId: Value(parentIssue.lotDesignId),
                designColourId: Value(parentIssue.designColourId),
                processId: Value(parentIssue.processId),
                memberId: Value(parentIssue.memberId),
                parentIssueId: Value(parentIssue.id),
                jobProcessId: Value(parentIssue.jobProcessId),
                clientRequestId: Value(reqId),
                movementType: Value(type.dbValue),
                quantity: Value(qty),
                sourceRateId: Value(parentIssue.sourceRateId),
                appliedRatePaise: Value(parentIssue.appliedRatePaise),
                isRateOverridden: Value(parentIssue.isRateOverridden ? 1 : 0),
                overrideReason: Value(parentIssue.overrideReason),
                lockedBillingMode: Value(lockedMode.dbValue),
                lockedIncludeDamaged: const Value(0),
                reason: Value(cleanedReason),
                notes: Value(cleanedNotes),
                transactionAt: Value(transactionAtUtcMillis),
                recordedAt: Value(now),
                createdBy: Value(actor),
                updatedBy: Value(actor),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );

            final plannedLabour = _labourCalc.planForSettlement(
              movementType: type,
              quantity: qty,
              lockedRatePaise: parentIssue.appliedRatePaise,
              lockedBillingMode: lockedMode,
              lockedIncludeDamaged: lockedIncludeDamaged,
              issueLabourAlreadyPaid: issueLabourAlreadyPaid,
            );
            if (plannedLabour != null &&
                parentIssue.memberId != null &&
                parentIssue.processId != null) {
              final labId = _idGenerator.nextEntityId();
              createdLabourId = labId;
              earnedPaise += plannedLabour.amountPaise;
              await _db.labourEntryDao.insertEntry(
                LabourEntriesCompanion(
                  id: Value(labId),
                  stockMovementId: Value(movId),
                  memberId: Value(parentIssue.memberId!),
                  processId: Value(parentIssue.processId!),
                  lotId: Value(parentIssue.lotId),
                  basisType: Value(plannedLabour.basisType.dbValue),
                  quantity: Value(plannedLabour.quantity),
                  ratePaise: Value(plannedLabour.ratePaise),
                  amountPaise: Value(plannedLabour.amountPaise),
                  isPayable: Value(plannedLabour.isPayable ? 1 : 0),
                  transactionAt: Value(transactionAtUtcMillis),
                  recordedAt: Value(now),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
              );
            }

            await _db.attachmentAuditDao.insertAuditLog(
              AuditLogsCompanion(
                id: Value(_idGenerator.nextEntityId()),
                entityType: const Value('stock_movements'),
                entityId: Value(movId),
                actionType: const Value('CREATE'),
                actor: Value(actor),
                newValueJson: Value(
                  jsonEncode({
                    'movement_type': type.dbValue,
                    'parent_issue_id': parentIssue.id,
                    'quantity': qty,
                    'inherited_rate_paise': parentIssue.appliedRatePaise,
                    'locked_billing_mode': lockedMode.dbValue,
                    'authorized_via_pin': authorizedViaPin,
                  }),
                ),
                reason: Value(cleanedReason),
                transactionAt: Value(transactionAtUtcMillis),
                recordedAt: Value(now),
              ),
            );

            final insertedRow = await _db.stockMovementDao.findById(movId);
            created.add(LedgerRowMappers.stockMovement(insertedRow!));
          }

          final returnedQty = goodQuantity + damagedQuantity;
          if (returnedQty > 0 &&
              parentIssue.processId != null &&
              parentIssue.memberId != null) {
            final retId = _idGenerator.nextEntityId();
            await _db.productionTrackingDao.insertReturn(
              ProductionReturnsCompanion(
                id: Value(retId),
                clientRequestId: Value('$baseReqId:RET'),
                parentIssueId: Value(parentIssue.id),
                jobProcessId: Value(parentIssue.jobProcessId),
                lotId: Value(parentIssue.lotId),
                lotDesignId: Value(parentIssue.lotDesignId),
                designColourId: Value(parentIssue.designColourId),
                processId: Value(parentIssue.processId!),
                memberId: Value(parentIssue.memberId!),
                returnedQuantity: Value(returnedQty),
                returnMode: Value(
                  ProductionReturnMode.immediateInspection.dbValue,
                ),
                notes: Value(cleanedNotes),
                transactionAt: Value(transactionAtUtcMillis),
                recordedAt: Value(now),
                createdBy: Value(actor),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );

            final inspId = _idGenerator.nextEntityId();
            await _db.productionTrackingDao.insertInspection(
              ProductionInspectionsCompanion(
                id: Value(inspId),
                clientRequestId: Value('$baseReqId:INSP'),
                inspectionType: Value(ProductionInspectionType.initial.dbValue),
                productionReturnId: Value(retId),
                parentIssueId: Value(parentIssue.id),
                jobProcessId: Value(parentIssue.jobProcessId),
                lotId: Value(parentIssue.lotId),
                lotDesignId: Value(parentIssue.lotDesignId),
                designColourId: Value(parentIssue.designColourId),
                processId: Value(parentIssue.processId!),
                memberId: Value(parentIssue.memberId!),
                acceptedQuantity: Value(goodQuantity),
                rejectedQuantity: Value(damagedQuantity),
                lockedRatePaise: Value(parentIssue.appliedRatePaise),
                earnedAmountPaise: Value(earnedPaise),
                creditWorkerEarnings: const Value(1),
                linkedGoodMovementId: Value(goodMovId),
                linkedDamagedMovementId: Value(dmgMovId),
                linkedLabourEntryId: Value(createdLabourId),
                rejectionReason: Value(cleanedReason),
                notes: Value(cleanedNotes),
                inspectedBy: Value(actor),
                approvedBy: Value(actor),
                authorizedViaPin: Value(authorizedViaPin ? 1 : 0),
                transactionAt: Value(transactionAtUtcMillis),
                recordedAt: Value(now),
                createdAt: Value(now),
              ),
            );

            if (damagedQuantity > 0 && dmgMovId != null) {
              await _db.productionTrackingDao.insertRejectionRecord(
                RejectionRecordsCompanion(
                  id: Value(_idGenerator.nextEntityId()),
                  lotId: Value(parentIssue.lotId),
                  lotDesignId: Value(parentIssue.lotDesignId),
                  designColourId: Value(parentIssue.designColourId),
                  processId: Value(parentIssue.processId!),
                  memberId: Value(parentIssue.memberId!),
                  parentIssueId: Value(parentIssue.id),
                  jobProcessId: Value(parentIssue.jobProcessId),
                  productionReturnId: Value(retId),
                  inspectionId: Value(inspId),
                  stockMovementId: Value(dmgMovId),
                  rejectedQuantity: Value(damagedQuantity),
                  rejectionReason: Value(cleanedReason ?? 'Damaged return'),
                  status: Value(RejectionStatus.open.dbValue),
                  inspectedAt: Value(transactionAtUtcMillis),
                  recordedBy: Value(actor),
                  notes: Value(cleanedNotes),
                  createdAt: Value(now),
                  updatedAt: Value(now),
                ),
              );
            }
          }

          final updatedMovements =
              (await _db.stockMovementDao.getMovementsForDesignColour(
                parentIssue.designColourId,
              )).map(LedgerRowMappers.stockMovement).toList();
          final updatedPending = await _queryDelegate.loadPendingInspectionMaps(
            updatedMovements,
          );
          final remaining =
              (_stockCalc.calculateIssueRemainingPending(
                        issue: parentIssue,
                        allMovementsForColour: updatedMovements,
                      ) -
                      (updatedPending.pendingByIssue[parentIssue.id] ?? 0))
                  .clamp(0, parentIssue.quantity);

          return SettlementBatchResult(
            createdMovements: created,
            remainingPending: remaining,
            wasIdempotentReplay: false,
          );
        })
        .then((result) {
          NotificationRefreshCoordinator.requestBackgroundRefreshIfRegistered();
          return result;
        });
  }

  @override
  Future<StockMovementEntity> recordDamagedToGoodAdjustment({
    required String designColourId,
    required int quantity,
    required String reason,
    required int transactionAtUtcMillis,
    String? notes,
    String? clientRequestId,
  }) async {
    final reqId = clientRequestId?.trim().isEmpty ?? true
        ? _idGenerator.nextRequestId()
        : clientRequestId!.trim();

    return _txRunner
        .runInTransaction(() async {
          final existingByReq = await _db.stockMovementDao
              .findByClientRequestId(reqId);
          if (existingByReq != null) {
            return LedgerRowMappers.stockMovement(existingByReq);
          }

          if (!AppValidators.dateValidator(transactionAtUtcMillis).isValid) {
            throw const DomainValidationException(
              'invalid_date',
              'Transaction date is invalid.',
            );
          }
          if (quantity > ValidationLimits.maxQuantity) {
            throw const DomainValidationException(
              'quantity_too_large',
              'Repair quantity exceeds maximum allowed limit.',
            );
          }
          if (reason.trim().length > ValidationLimits.maxNotesLength ||
              (notes?.trim().length ?? 0) > ValidationLimits.maxNotesLength) {
            throw const DomainValidationException(
              'text_too_long',
              'Reason or notes exceed maximum allowed length.',
            );
          }

          final colour = await _db.lotDao.findDesignColourById(designColourId);
          if (colour == null || colour.deletedAt != null) {
            throw const DomainValidationException(
              'colour_not_found',
              'Selected colour was not found.',
            );
          }
          final design = await _db.lotDao.findDesignById(colour.lotDesignId);
          if (design == null || design.deletedAt != null) {
            throw const DomainValidationException(
              'design_not_found',
              'Selected design was not found.',
            );
          }

          final existingMovements =
              (await _db.stockMovementDao.getMovementsForDesignColour(
                designColourId,
              )).map(LedgerRowMappers.stockMovement).toList();
          final validationErr = _stockCalc.validateDamagedToGoodAdjustment(
            initialQuantity: colour.initialQuantity,
            existingMovementsForColour: existingMovements,
            quantity: quantity,
            reason: reason,
            reservedForOpenRepairsQty: await _db.productionTrackingDao
                .pendingReinspectionQtyForColour(designColourId),
          );
          if (validationErr != null) {
            throw DomainValidationException(
              validationErr,
              'Invalid damaged-to-good repair adjustment ($validationErr).',
            );
          }

          final now = IstDateTimeHelper.nowUtcMillis();
          final actor = await ActorResolver.resolveRequired(_db);
          final movId = _idGenerator.nextEntityId();
          final cleanedReason = reason.trim();
          final cleanedNotes = notes?.trim().isEmpty ?? true
              ? null
              : notes!.trim();

          await _db.stockMovementDao.insertMovement(
            StockMovementsCompanion(
              id: Value(movId),
              lotId: Value(design.lotId),
              lotDesignId: Value(design.id),
              designColourId: Value(colour.id),
              clientRequestId: Value(reqId),
              movementType: Value(
                StockMovementType.adjustmentDamagedToGood.dbValue,
              ),
              quantity: Value(quantity),
              appliedRatePaise: const Value(0),
              reason: Value(cleanedReason),
              notes: Value(cleanedNotes),
              transactionAt: Value(transactionAtUtcMillis),
              recordedAt: Value(now),
              createdBy: Value(actor),
              updatedBy: Value(actor),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

          await _db.attachmentAuditDao.insertAuditLog(
            AuditLogsCompanion(
              id: Value(_idGenerator.nextEntityId()),
              entityType: const Value('stock_movements'),
              entityId: Value(movId),
              actionType: const Value('DAMAGED_TO_GOOD_ADJUSTMENT'),
              actor: Value(actor),
              newValueJson: Value(
                jsonEncode({
                  'design_colour_id': colour.id,
                  'quantity': quantity,
                  'reason': cleanedReason,
                }),
              ),
              reason: Value(cleanedReason),
              transactionAt: Value(transactionAtUtcMillis),
              recordedAt: Value(now),
            ),
          );

          final inserted = await _db.stockMovementDao.findById(movId);
          return LedgerRowMappers.stockMovement(inserted!);
        })
        .then((result) {
          NotificationRefreshCoordinator.requestBackgroundRefreshIfRegistered();
          return result;
        });
  }

  @override
  Future<StockMovementEntity> reverseMovement({
    required String movementId,
    required String reason,
    required int transactionAtUtcMillis,
    String? notes,
  }) async {
    return _txRunner.runInTransaction(() async {
      final targetRow = await _db.stockMovementDao.findById(movementId);
      if (targetRow == null) {
        throw const DomainValidationException(
          'movement_not_found',
          'Stock movement was not found.',
        );
      }

      final colour = await _db.lotDao.findDesignColourById(
        targetRow.designColourId,
      );
      if (colour == null) {
        throw const DomainValidationException(
          'colour_not_found',
          'Design colour not found.',
        );
      }

      final allColourMovements =
          (await _db.stockMovementDao.getMovementsForDesignColour(
            targetRow.designColourId,
          )).map(LedgerRowMappers.stockMovement).toList();

      if (targetRow.movementType == StockMovementType.issue.dbValue) {
        final pendingMaps = await _queryDelegate.loadPendingInspectionMaps(
          allColourMovements,
        );
        if ((pendingMaps.pendingByIssue[targetRow.id] ?? 0) > 0) {
          throw const DomainValidationException(
            'pending_inspection_exists',
            'This issue has returned pieces waiting for QC. Inspect them first.',
          );
        }
      }

      final validation = _stockCalc.validateReversal(
        initialQuantity: colour.initialQuantity,
        allMovementsForColour: allColourMovements,
        targetMovementId: movementId,
        reason: reason,
      );

      if (validation is StockReversalBlocked) {
        throw DomainValidationException(validation.code, validation.message);
      }

      final target = (validation as StockReversalAllowed).targetMovement;
      final now = IstDateTimeHelper.nowUtcMillis();
      final actor = await ActorResolver.resolveRequired(_db);
      final reversalId = _idGenerator.nextEntityId();
      final cleanedReason = reason.trim();
      final cleanedNotes = notes?.trim().isEmpty ?? true ? null : notes!.trim();

      await _db.stockMovementDao.insertMovement(
        StockMovementsCompanion(
          id: Value(reversalId),
          lotId: Value(target.lotId),
          lotDesignId: Value(target.lotDesignId),
          designColourId: Value(target.designColourId),
          processId: Value(target.processId),
          memberId: Value(target.memberId),
          parentIssueId: Value(target.parentIssueId),
          reversesMovementId: Value(target.id),
          movementType: Value(StockMovementType.reversal.dbValue),
          quantity: Value(target.quantity),
          sourceRateId: Value(target.sourceRateId),
          appliedRatePaise: Value(target.appliedRatePaise),
          lockedBillingMode: Value(target.lockedBillingMode?.dbValue),
          lockedIncludeDamaged: Value(target.lockedIncludeDamaged ? 1 : 0),
          reason: Value(cleanedReason),
          notes: Value(cleanedNotes),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final linkedLabourRows = await _db.labourEntryDao.getEntriesForMovement(
        target.id,
      );
      for (final labRow in linkedLabourRows) {
        if (labRow.basisType == LabourBasisType.reversal.dbValue) continue;
        final existingLabRev = await _db.labourEntryDao.findReversalForEntry(
          labRow.id,
        );
        if (existingLabRev != null) continue;

        final plannedRev = _labourCalc.planReversalForEntry(
          LedgerRowMappers.labourEntry(labRow),
        );
        await _db.labourEntryDao.insertEntry(
          LabourEntriesCompanion(
            id: Value(_idGenerator.nextEntityId()),
            stockMovementId: Value(reversalId),
            reversesLabourEntryId: Value(labRow.id),
            memberId: Value(labRow.memberId),
            processId: Value(labRow.processId),
            lotId: Value(labRow.lotId),
            basisType: Value(plannedRev.basisType.dbValue),
            quantity: Value(plannedRev.quantity),
            ratePaise: Value(plannedRev.ratePaise),
            amountPaise: Value(plannedRev.amountPaise),
            isPayable: Value(plannedRev.isPayable ? 1 : 0),
            transactionAt: Value(transactionAtUtcMillis),
            recordedAt: Value(now),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
      }

      await _db.attachmentAuditDao.insertAuditLog(
        AuditLogsCompanion(
          id: Value(_idGenerator.nextEntityId()),
          entityType: const Value('stock_movements'),
          entityId: Value(reversalId),
          actionType: const Value('REVERSAL'),
          actor: Value(actor),
          previousValueJson: Value(
            jsonEncode({
              'reversed_movement_id': target.id,
              'movement_type': target.movementType.dbValue,
              'quantity': target.quantity,
            }),
          ),
          newValueJson: Value(
            jsonEncode({'reversal_id': reversalId, 'reason': cleanedReason}),
          ),
          reason: Value(cleanedReason),
          transactionAt: Value(transactionAtUtcMillis),
          recordedAt: Value(now),
        ),
      );

      final inserted = await _db.stockMovementDao.findById(reversalId);
      return LedgerRowMappers.stockMovement(inserted!);
    });
  }
}
