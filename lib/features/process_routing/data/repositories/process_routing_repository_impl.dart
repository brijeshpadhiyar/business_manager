import 'dart:convert';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/process_routing/domain/calculators/process_pricing_calculator.dart';
import 'package:business_manager/features/process_routing/domain/calculators/process_routing_validator.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/process_routing/domain/repositories/process_routing_repository.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/rates/domain/entities/rate_entities.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

/// Production implementation of [ProcessRoutingRepository] with full Schema v5
/// Dynamic Process Pricing, Configurable Units, Immutable Assignment Rate
/// Snapshots, Additional Charges/Deductions, and existing Ledger Integration.
@LazySingleton(as: ProcessRoutingRepository)
final class ProcessRoutingRepositoryImpl implements ProcessRoutingRepository {
  ProcessRoutingRepositoryImpl(
    this._db,
    this._txRunner,
    this._stockRepo,
    this._idGenerator,
  );

  final AppDatabase _db;
  final DatabaseTransactionRunner _txRunner;
  final StockMovementRepository _stockRepo;
  final IdGenerator _idGenerator;

  static const ProcessRoutingValidator _validator = ProcessRoutingValidator();
  static const ProcessPricingCalculator _pricingCalc =
      ProcessPricingCalculator();

  Never _throwValidation(String code) =>
      throw DomainValidationException(code, code);

  Future<String> _resolveActor() async {
    final profile = await _db.businessProfileDao.getProfile();
    final owner = profile?.ownerName?.trim();
    return (owner != null && owner.isNotEmpty) ? owner : 'local_owner';
  }

  Future<void> _ensureMemberProcessLink({
    required String memberId,
    required String processId,
    required int now,
  }) async {
    final existing = await _db.processMemberDao.findMemberProcessLink(
      memberId,
      processId,
    );
    if (existing == null) {
      await _db.processMemberDao.insertMemberProcess(
        MemberProcessesCompanion.insert(
          id: _idGenerator.nextEntityId(),
          memberId: memberId,
          processId: processId,
          isActive: const Value(1),
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else if (existing.isActive == 0) {
      await _db.processMemberDao.updateMemberProcessById(
        existing.id,
        MemberProcessesCompanion(
          isActive: const Value(1),
          updatedAt: Value(now),
        ),
      );
    }
  }

  /// Resolves default rate using strict precedence:
  /// Worker-specific historical rate -> Process default rate -> 0.
  /// Validates override reason whenever agreed rate != resolved default rate,
  /// and computes exact base payable amount in integer paise.
  Future<
    ({
      int defaultRatePaise,
      int agreedRatePaise,
      String pricingUnit,
      int payableAmountPaise,
      int perPieceRatePaise,
      bool isOverridden,
      String? overrideReason,
    })
  >
  _resolveAssignmentPricing({
    required String processId,
    required String workerId,
    required int quantity,
    required int transactionAtUtcMillis,
    int? requestedAgreedRatePaise,
    String? requestedPricingUnit,
    String? requestedOverrideReason,
  }) async {
    final procRow = await _db.processMemberDao.findProcessById(processId);
    if (procRow == null) _throwValidation('process_not_found');

    // Strict precedence: Worker-specific historical rate -> Process default rate -> 0
    var defaultRate = procRow.defaultRatePaise;
    var defaultUnit = procRow.defaultPricingUnit;

    final histRate = await _stockRepo.previewRate(
      workerId: workerId,
      processId: processId,
      transactionAtUtcMillis: transactionAtUtcMillis,
    );
    if (histRate is RateResolutionFound) {
      defaultRate = histRate.rate.ratePaise;
      defaultUnit = 'PER_PIECE';
    }

    final agreedRate = requestedAgreedRatePaise ?? defaultRate;
    if (agreedRate < 0) _throwValidation('invalid_rate');

    final unit =
        (requestedPricingUnit != null && requestedPricingUnit.trim().isNotEmpty)
        ? requestedPricingUnit.trim().toUpperCase()
        : defaultUnit;

    final isOverridden = agreedRate != defaultRate;
    final trimmedReason = requestedOverrideReason?.trim();
    if (isOverridden && (trimmedReason == null || trimmedReason.isEmpty)) {
      _throwValidation('rate_override_reason_required');
    }

    final payable = _pricingCalc.calculateBaseAmountPaise(
      quantity: quantity,
      ratePaise: agreedRate,
      pricingUnit: unit,
    );
    final perPiece = _pricingCalc.effectivePerPieceRatePaise(
      quantity: quantity,
      ratePaise: agreedRate,
      pricingUnit: unit,
    );

    return (
      defaultRatePaise: defaultRate,
      agreedRatePaise: agreedRate,
      pricingUnit: unit,
      payableAmountPaise: payable,
      perPieceRatePaise: perPiece,
      isOverridden: isOverridden,
      overrideReason: isOverridden ? trimmedReason : null,
    );
  }

  Future<StockMovementEntity> _issueStockWithResolvedRate({
    required String designColourId,
    required String processId,
    required String workerId,
    required int quantity,
    required int transactionAtUtcMillis,
    required int effectivePerPieceRatePaise,
    required String? overrideReason,
    required String? notes,
    required String? clientRequestId,
  }) async {
    final now = IstDateTimeHelper.nowUtcMillis();
    await _ensureMemberProcessLink(
      memberId: workerId,
      processId: processId,
      now: now,
    );

    final rateResult = await _stockRepo.previewRate(
      workerId: workerId,
      processId: processId,
      transactionAtUtcMillis: transactionAtUtcMillis,
    );
    final matchesResolved = switch (rateResult) {
      RateResolutionFound(:final rate) =>
        rate.ratePaise == effectivePerPieceRatePaise,
      RateResolutionProcessDefault(:final ratePaise) =>
        ratePaise == effectivePerPieceRatePaise,
      _ => false,
    };

    return _stockRepo.issueStock(
      designColourId: designColourId,
      processId: processId,
      workerId: workerId,
      quantity: quantity,
      transactionAtUtcMillis: transactionAtUtcMillis,
      notes: notes,
      allowRateOverride: !matchesResolved,
      overrideRatePaise: matchesResolved ? null : effectivePerPieceRatePaise,
      overrideReason: matchesResolved
          ? null
          : (overrideReason ?? 'Dynamic assignment rate'),
      clientRequestId: clientRequestId,
    );
  }

  Future<void> _writeAudit({
    required String entityType,
    required String entityId,
    required String actionType,
    required String actor,
    required Map<String, Object?> payload,
    required int transactionAt,
    required int now,
    String? reason,
  }) {
    return _db.attachmentAuditDao.insertAuditLog(
      AuditLogsCompanion.insert(
        id: _idGenerator.nextEntityId(),
        entityType: entityType,
        entityId: entityId,
        actionType: actionType,
        actor: Value(actor),
        newValueJson: Value(jsonEncode(payload)),
        reason: Value(reason),
        transactionAt: transactionAt,
        recordedAt: now,
      ),
    );
  }

  Future<JobProcessEntity> _hydrateJobProcess(JobProcessRow row) async {
    final design = await _db.lotDao.findDesignById(row.lotDesignId);
    final colour = await _db.lotDao.findDesignColourById(row.designColourId);
    final proc = await _db.processMemberDao.findProcessById(row.processId);
    final member = row.memberId != null
        ? await _db.processMemberDao.findMemberById(row.memberId!)
        : null;

    return JobProcessEntity(
      id: row.id,
      lotId: row.lotId,
      lotDesignId: row.lotDesignId,
      designColourId: row.designColourId,
      designName: design?.designName ?? '-',
      colourName: colour?.colourName ?? '-',
      processId: row.processId,
      processName: proc?.name ?? '-',
      memberId: row.memberId,
      workerName: member?.name,
      sequenceOrder: row.sequenceOrder,
      plannedQuantity: row.plannedQuantity,
      dispatchedQuantity: row.dispatchedQuantity,
      receivedQuantity: row.receivedQuantity,
      returnedToFactoryQuantity: row.returnedToFactoryQuantity,
      transferredOutQuantity: row.transferredOutQuantity,
      damagedQuantity: row.damagedQuantity,
      status: JobProcessStatus.fromDbValue(row.status),
      sourceJobProcessId: row.sourceJobProcessId,
      linkedIssueMovementId: row.linkedIssueMovementId,
      defaultRatePaise: row.defaultRatePaise,
      agreedRatePaise: row.agreedRatePaise,
      pricingUnit: row.pricingUnit,
      rateOverrideReason: row.rateOverrideReason,
      payableAmountPaise: row.payableAmountPaise,
      paidAmountPaise: row.paidAmountPaise,
      paymentStatus: ProcessPaymentStatus.fromDbValue(row.paymentStatus),
      notes: row.notes,
      transactionAt: row.transactionAt,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<ProcessHandoverEntity> _hydrateHandover(ProcessHandoverRow row) async {
    final design = await _db.lotDao.findDesignById(row.lotDesignId);
    final colour = await _db.lotDao.findDesignColourById(row.designColourId);
    final proc = await _db.processMemberDao.findProcessById(row.processId);
    final fromMember = row.fromMemberId != null
        ? await _db.processMemberDao.findMemberById(row.fromMemberId!)
        : null;
    final toMember = row.toMemberId != null
        ? await _db.processMemberDao.findMemberById(row.toMemberId!)
        : null;

    return ProcessHandoverEntity(
      id: row.id,
      transferReference: row.transferReference,
      clientRequestId: row.clientRequestId,
      lotId: row.lotId,
      lotDesignId: row.lotDesignId,
      designColourId: row.designColourId,
      designName: design?.designName ?? '-',
      colourName: colour?.colourName ?? '-',
      handoverType: ProcessHandoverType.fromDbValue(row.handoverType),
      fromJobProcessId: row.fromJobProcessId,
      toJobProcessId: row.toJobProcessId,
      fromMemberId: row.fromMemberId,
      fromMemberName: fromMember?.name,
      toMemberId: row.toMemberId,
      toMemberName: toMember?.name,
      processId: row.processId,
      processName: proc?.name ?? '-',
      quantityDispatched: row.quantityDispatched,
      quantityReceived: row.quantityReceived,
      status: ProcessHandoverStatus.fromDbValue(row.status),
      linkedStockMovementId: row.linkedStockMovementId,
      notes: row.notes,
      transactionAt: row.transactionAt,
      recordedAt: row.recordedAt,
    );
  }

  ProcessAdditionalChargeEntity _mapCharge(ProcessAdditionalChargeRow r) {
    return ProcessAdditionalChargeEntity(
      id: r.id,
      jobProcessId: r.jobProcessId,
      lotId: r.lotId,
      designColourId: r.designColourId,
      memberId: r.memberId,
      chargeType: ProcessChargeType.fromDbValue(r.chargeType),
      description: r.description,
      amountPaise: r.amountPaise,
      transactionAt: r.transactionAt,
      createdAt: r.createdAt,
    );
  }

  @override
  Future<JobRoutingOverview?> getJobRoutingOverview(String lotId) async {
    final lotRow = await _db.lotDao.findLotById(lotId);
    if (lotRow == null || lotRow.deletedAt != null) return null;

    final lot = LotEntity(
      id: lotRow.id,
      lotNumber: lotRow.lotNumber,
      title: lotRow.title,
      notes: lotRow.notes,
      status: LotStatus.fromDbValue(lotRow.status),
      transactionAt: lotRow.transactionAt,
      recordedAt: lotRow.recordedAt,
      createdAt: lotRow.createdAt,
      updatedAt: lotRow.updatedAt,
    );

    final skuBalances = await _stockRepo.getAllDesignColourBalances(
      lotId: lotId,
    );
    final processRows = await _db.jobProcessDao.getJobProcessesForLot(lotId);
    final handoverRows = await _db.jobProcessDao.getHandoversForLot(lotId);
    final chargeRows = await _db.jobProcessDao.getChargesForLot(lotId);

    final nonDeletedProcs = await _db.processMemberDao.getNonDeletedProcesses();
    final nonDeletedMembers = await _db.processMemberDao.getNonDeletedMembers();
    final activeProcesses = nonDeletedProcs
        .where((p) => p.isActive == 1)
        .toList();
    final activeMembers = nonDeletedMembers
        .where((m) => m.isActive == 1)
        .toList();

    final designs = await _db.lotDao.getDesignsForLot(lotId);
    final designById = {for (final d in designs) d.id: d.designName};
    final colourById = {for (final b in skuBalances) b.designColourId: b};
    final procById = {for (final p in nonDeletedProcs) p.id: p.name};
    final memberById = {for (final m in nonDeletedMembers) m.id: m.name};
    final defaultPricingByProcessId = {
      for (final p in nonDeletedProcs)
        p.id: ProcessDefaultPricing(
          processId: p.id,
          defaultRatePaise: p.defaultRatePaise,
          defaultPricingUnit: p.defaultPricingUnit,
        ),
    };

    final jobProcesses = processRows.map((row) {
      final sku = colourById[row.designColourId];
      return JobProcessEntity(
        id: row.id,
        lotId: row.lotId,
        lotDesignId: row.lotDesignId,
        designColourId: row.designColourId,
        designName: sku?.designName ?? designById[row.lotDesignId] ?? '-',
        colourName: sku?.colourName ?? '-',
        processId: row.processId,
        processName: procById[row.processId] ?? '-',
        memberId: row.memberId,
        workerName: row.memberId != null ? memberById[row.memberId!] : null,
        sequenceOrder: row.sequenceOrder,
        plannedQuantity: row.plannedQuantity,
        dispatchedQuantity: row.dispatchedQuantity,
        receivedQuantity: row.receivedQuantity,
        returnedToFactoryQuantity: row.returnedToFactoryQuantity,
        transferredOutQuantity: row.transferredOutQuantity,
        damagedQuantity: row.damagedQuantity,
        status: JobProcessStatus.fromDbValue(row.status),
        sourceJobProcessId: row.sourceJobProcessId,
        linkedIssueMovementId: row.linkedIssueMovementId,
        defaultRatePaise: row.defaultRatePaise,
        agreedRatePaise: row.agreedRatePaise,
        pricingUnit: row.pricingUnit,
        rateOverrideReason: row.rateOverrideReason,
        payableAmountPaise: row.payableAmountPaise,
        paidAmountPaise: row.paidAmountPaise,
        paymentStatus: ProcessPaymentStatus.fromDbValue(row.paymentStatus),
        notes: row.notes,
        transactionAt: row.transactionAt,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
    }).toList();

    final handovers = handoverRows.map((row) {
      final sku = colourById[row.designColourId];
      return ProcessHandoverEntity(
        id: row.id,
        transferReference: row.transferReference,
        clientRequestId: row.clientRequestId,
        lotId: row.lotId,
        lotDesignId: row.lotDesignId,
        designColourId: row.designColourId,
        designName: sku?.designName ?? designById[row.lotDesignId] ?? '-',
        colourName: sku?.colourName ?? '-',
        handoverType: ProcessHandoverType.fromDbValue(row.handoverType),
        fromJobProcessId: row.fromJobProcessId,
        toJobProcessId: row.toJobProcessId,
        fromMemberId: row.fromMemberId,
        fromMemberName: row.fromMemberId != null
            ? memberById[row.fromMemberId!]
            : null,
        toMemberId: row.toMemberId,
        toMemberName: row.toMemberId != null
            ? memberById[row.toMemberId!]
            : null,
        processId: row.processId,
        processName: procById[row.processId] ?? '-',
        quantityDispatched: row.quantityDispatched,
        quantityReceived: row.quantityReceived,
        status: ProcessHandoverStatus.fromDbValue(row.status),
        linkedStockMovementId: row.linkedStockMovementId,
        notes: row.notes,
        transactionAt: row.transactionAt,
        recordedAt: row.recordedAt,
      );
    }).toList();

    final additionalCharges = chargeRows.map(_mapCharge).toList();
    final costSummary = _pricingCalc.calculateJobCostSummary(
      jobProcesses: jobProcesses,
      charges: additionalCharges,
    );

    final locations = <GoodsLocationBucket>[];
    final factoryTotal = skuBalances.fold(
      0,
      (sum, b) => sum + b.physicalAvailableInHouse,
    );
    if (factoryTotal > 0) {
      locations.add(
        GoodsLocationBucket(
          locationLabel: 'Factory',
          operationLabel: 'In-House Ready',
          quantity: factoryTotal,
          isFactory: true,
        ),
      );
    }
    for (final jp in jobProcesses) {
      if (!jp.status.isTerminal && jp.pendingQuantity > 0) {
        locations.add(
          GoodsLocationBucket(
            locationLabel: jp.workerName ?? 'Unassigned',
            operationLabel: '${jp.processName} • ${jp.variantLabel}',
            quantity: jp.pendingQuantity,
            isFactory: false,
          ),
        );
      }
    }

    return JobRoutingOverview(
      lot: lot,
      skuBalances: skuBalances,
      jobProcesses: jobProcesses,
      handovers: handovers,
      currentLocations: locations,
      availableProcesses: activeProcesses
          .map(
            (p) => ProcessEntity(
              id: p.id,
              name: p.name,
              description: p.description,
              isActive: p.isActive == 1,
              includeDamagedInLabour: p.includeDamagedInLabour == 1,
              createdAt: p.createdAt,
              updatedAt: p.updatedAt,
            ),
          )
          .toList(),
      availableWorkers: activeMembers
          .map(
            (m) => WorkerEntity(
              id: m.id,
              name: m.name,
              phone: m.phone,
              address: m.address,
              notes: m.notes,
              isActive: m.isActive == 1,
              createdAt: m.createdAt,
              updatedAt: m.updatedAt,
            ),
          )
          .toList(),
      defaultPricingByProcessId: defaultPricingByProcessId,
      additionalCharges: additionalCharges,
      costSummary: costSummary,
    );
  }

  @override
  Future<ProcessDefaultPricing> updateProcessDefaultRate({
    required String processId,
    required int defaultRatePaise,
    required String defaultPricingUnit,
    required String reason,
  }) async {
    if (defaultRatePaise < 0) _throwValidation('invalid_rate');
    final cleanUnit = defaultPricingUnit.trim().toUpperCase();
    if (cleanUnit.isEmpty) _throwValidation('pricing_unit_required');
    final cleanReason = reason.trim();
    if (cleanReason.isEmpty) _throwValidation('reason_required');

    final proc = await _db.processMemberDao.findProcessById(processId);
    if (proc == null || proc.deletedAt != null) {
      _throwValidation('process_not_found');
    }

    final actor = await _resolveActor();
    final now = IstDateTimeHelper.nowUtcMillis();

    await _txRunner.runInTransaction(() async {
      await _db.processMemberDao.updateProcessById(
        processId,
        ProcessesCompanion(
          defaultRatePaise: Value(defaultRatePaise),
          defaultPricingUnit: Value(cleanUnit),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );

      await _db.jobProcessDao.insertRateHistory(
        ProcessRateHistoriesCompanion.insert(
          id: _idGenerator.nextEntityId(),
          scope: 'PROCESS_DEFAULT',
          processId: processId,
          previousRatePaise: proc.defaultRatePaise,
          newRatePaise: defaultRatePaise,
          pricingUnit: cleanUnit,
          reason: cleanReason,
          changedBy: Value(actor),
          changedAt: now,
        ),
      );

      await _writeAudit(
        entityType: 'PROCESS',
        entityId: processId,
        actionType: 'UPDATE',
        actor: actor,
        payload: {
          'previousDefaultRatePaise': proc.defaultRatePaise,
          'newDefaultRatePaise': defaultRatePaise,
          'defaultPricingUnit': cleanUnit,
        },
        transactionAt: now,
        now: now,
        reason: cleanReason,
      );
    });

    return ProcessDefaultPricing(
      processId: processId,
      defaultRatePaise: defaultRatePaise,
      defaultPricingUnit: cleanUnit,
    );
  }

  @override
  Future<List<ProcessRateHistoryEntity>> getProcessRateHistory(
    String processId,
  ) async {
    final rows = await _db.jobProcessDao.getRateHistoryForProcess(processId);
    return rows
        .map(
          (r) => ProcessRateHistoryEntity(
            id: r.id,
            scope: r.scope,
            processId: r.processId,
            jobProcessId: r.jobProcessId,
            memberId: r.memberId,
            designColourId: r.designColourId,
            previousRatePaise: r.previousRatePaise,
            newRatePaise: r.newRatePaise,
            pricingUnit: r.pricingUnit,
            reason: r.reason,
            changedBy: r.changedBy,
            changedAt: r.changedAt,
          ),
        )
        .toList();
  }

  @override
  Future<JobProcessEntity> addJobProcess({
    required String lotId,
    required String designColourId,
    required String processId,
    required String workerId,
    required int quantity,
    required int transactionAtUtcMillis,
    bool dispatchImmediately = true,
    int? agreedRatePaise,
    String? pricingUnit,
    String? rateOverrideReason,
    String? notes,
    String? clientRequestId,
  }) async {
    final trimmedReqId = clientRequestId?.trim();
    if (trimmedReqId != null && trimmedReqId.isNotEmpty) {
      final existingHandover = await _db.jobProcessDao
          .findHandoverByClientRequestId(trimmedReqId);
      if (existingHandover != null && existingHandover.toJobProcessId != null) {
        final existingJp = await _db.jobProcessDao.findJobProcessById(
          existingHandover.toJobProcessId!,
        );
        if (existingJp != null) return _hydrateJobProcess(existingJp);
      }
    }

    final balance = await _stockRepo.getDesignColourBalance(designColourId);
    if (balance == null || balance.lotId != lotId) {
      _throwValidation('sku_not_found');
    }

    if (dispatchImmediately) {
      final err = _validator.validateFactoryDispatch(
        designColourId: designColourId,
        processId: processId,
        workerId: workerId,
        quantity: quantity,
        availableInHouse: balance.physicalAvailableInHouse,
      );
      if (err != null) _throwValidation(err);
    } else {
      if (quantity <= 0) _throwValidation('invalid_quantity');
      if (processId.trim().isEmpty) _throwValidation('process_required');
      if (workerId.trim().isEmpty) _throwValidation('worker_required');
    }

    final pricing = await _resolveAssignmentPricing(
      processId: processId,
      workerId: workerId,
      quantity: quantity,
      transactionAtUtcMillis: transactionAtUtcMillis,
      requestedAgreedRatePaise: agreedRatePaise,
      requestedPricingUnit: pricingUnit,
      requestedOverrideReason: rateOverrideReason,
    );

    final actor = await _resolveActor();
    final now = IstDateTimeHelper.nowUtcMillis();
    final jpId = _idGenerator.nextEntityId();

    await _txRunner.runInTransaction(() async {
      final nextSeq = await _db.jobProcessDao.getNextSequenceOrderForLot(lotId);
      String? linkedIssueId;

      if (dispatchImmediately) {
        final issue = await _issueStockWithResolvedRate(
          designColourId: designColourId,
          processId: processId,
          workerId: workerId,
          quantity: quantity,
          transactionAtUtcMillis: transactionAtUtcMillis,
          effectivePerPieceRatePaise: pricing.perPieceRatePaise,
          overrideReason: pricing.overrideReason,
          notes: notes,
          clientRequestId: trimmedReqId != null && trimmedReqId.isNotEmpty
              ? 'jp_iss_$trimmedReqId'
              : null,
        );
        linkedIssueId = issue.id;
      }

      final initialStatus = dispatchImmediately
          ? JobProcessStatus.dispatched
          : JobProcessStatus.pending;

      await _db.jobProcessDao.insertJobProcess(
        JobProcessesCompanion.insert(
          id: jpId,
          lotId: lotId,
          lotDesignId: balance.lotDesignId,
          designColourId: designColourId,
          processId: processId,
          memberId: Value(workerId),
          sequenceOrder: Value(nextSeq),
          plannedQuantity: quantity,
          dispatchedQuantity: Value(dispatchImmediately ? quantity : 0),
          receivedQuantity: const Value(0),
          status: Value(initialStatus.dbValue),
          linkedIssueMovementId: Value(linkedIssueId),
          defaultRatePaise: Value(pricing.defaultRatePaise),
          agreedRatePaise: Value(pricing.agreedRatePaise),
          pricingUnit: Value(pricing.pricingUnit),
          rateOverrideReason: Value(pricing.overrideReason),
          payableAmountPaise: Value(pricing.payableAmountPaise),
          paidAmountPaise: const Value(0),
          paymentStatus: Value(
            _pricingCalc
                .resolvePaymentStatus(
                  netPayablePaise: pricing.payableAmountPaise,
                  paidPaise: 0,
                )
                .dbValue,
          ),
          notes: Value(notes?.trim()),
          transactionAt: transactionAtUtcMillis,
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: now,
          updatedAt: now,
        ),
      );

      if (pricing.isOverridden) {
        await _db.jobProcessDao.insertRateHistory(
          ProcessRateHistoriesCompanion.insert(
            id: _idGenerator.nextEntityId(),
            scope: 'JOB_ASSIGNMENT',
            processId: processId,
            jobProcessId: Value(jpId),
            memberId: Value(workerId),
            designColourId: Value(designColourId),
            previousRatePaise: pricing.defaultRatePaise,
            newRatePaise: pricing.agreedRatePaise,
            pricingUnit: pricing.pricingUnit,
            reason: pricing.overrideReason!,
            changedBy: Value(actor),
            changedAt: now,
          ),
        );
      }

      if (dispatchImmediately) {
        final handoverId = _idGenerator.nextEntityId();
        final ref = _validator.generateReference(
          type: ProcessHandoverType.factoryDispatch,
          transactionAtUtcMillis: transactionAtUtcMillis,
          uniqueId: handoverId,
        );
        await _db.jobProcessDao.insertHandover(
          ProcessHandoversCompanion.insert(
            id: handoverId,
            transferReference: ref,
            clientRequestId: Value(
              trimmedReqId != null && trimmedReqId.isNotEmpty
                  ? trimmedReqId
                  : null,
            ),
            lotId: lotId,
            lotDesignId: balance.lotDesignId,
            designColourId: designColourId,
            handoverType: ProcessHandoverType.factoryDispatch.dbValue,
            toJobProcessId: Value(jpId),
            toMemberId: Value(workerId),
            processId: processId,
            quantityDispatched: quantity,
            quantityReceived: const Value(0),
            status: Value(ProcessHandoverStatus.pendingReceipt.dbValue),
            linkedStockMovementId: Value(linkedIssueId),
            notes: Value(notes?.trim()),
            transactionAt: transactionAtUtcMillis,
            recordedAt: now,
            createdBy: Value(actor),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      await _writeAudit(
        entityType: 'JOB_PROCESS',
        entityId: jpId,
        actionType: 'CREATE',
        actor: actor,
        payload: {
          'lotId': lotId,
          'designColourId': designColourId,
          'processId': processId,
          'workerId': workerId,
          'quantity': quantity,
          'defaultRatePaise': pricing.defaultRatePaise,
          'agreedRatePaise': pricing.agreedRatePaise,
          'pricingUnit': pricing.pricingUnit,
          'payableAmountPaise': pricing.payableAmountPaise,
          'dispatched': dispatchImmediately,
        },
        transactionAt: transactionAtUtcMillis,
        now: now,
        reason: pricing.overrideReason,
      );
    });

    final created = await _db.jobProcessDao.findJobProcessById(jpId);
    return _hydrateJobProcess(created!);
  }

  @override
  Future<JobProcessEntity> editJobProcess({
    required String jobProcessId,
    String? workerId,
    int? plannedQuantity,
    String? notes,
  }) async {
    final row = await _db.jobProcessDao.findJobProcessById(jobProcessId);
    if (row == null || row.deletedAt != null) {
      _throwValidation('process_not_found');
    }
    final currentStatus = JobProcessStatus.fromDbValue(row.status);
    if (currentStatus.isTerminal) {
      _throwValidation('process_already_closed');
    }
    if (plannedQuantity != null && plannedQuantity < row.dispatchedQuantity) {
      _throwValidation('invalid_quantity');
    }
    if (plannedQuantity != null && plannedQuantity <= 0) {
      _throwValidation('invalid_quantity');
    }

    final actor = await _resolveActor();
    final now = IstDateTimeHelper.nowUtcMillis();
    final newPlanned = plannedQuantity ?? row.plannedQuantity;
    final recomputedPayable = _pricingCalc.calculateBaseAmountPaise(
      quantity: newPlanned,
      ratePaise: row.agreedRatePaise,
      pricingUnit: row.pricingUnit,
    );

    await _txRunner.runInTransaction(() async {
      await _db.jobProcessDao.updateJobProcess(
        jobProcessId,
        JobProcessesCompanion(
          memberId: workerId != null && row.dispatchedQuantity == 0
              ? Value(workerId)
              : const Value.absent(),
          plannedQuantity: plannedQuantity != null
              ? Value(plannedQuantity)
              : const Value.absent(),
          payableAmountPaise: Value(recomputedPayable),
          notes: notes != null ? Value(notes.trim()) : const Value.absent(),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );
      await _writeAudit(
        entityType: 'JOB_PROCESS',
        entityId: jobProcessId,
        actionType: 'UPDATE',
        actor: actor,
        payload: {
          'workerId': workerId,
          'plannedQuantity': plannedQuantity,
          'notes': notes,
        },
        transactionAt: row.transactionAt,
        now: now,
      );
    });

    final updated = await _db.jobProcessDao.findJobProcessById(jobProcessId);
    return _hydrateJobProcess(updated!);
  }

  @override
  Future<ProcessHandoverEntity> dispatchJobProcess({
    required String jobProcessId,
    required int quantity,
    required int transactionAtUtcMillis,
    String? notes,
    String? clientRequestId,
  }) async {
    final trimmedReqId = clientRequestId?.trim();
    if (trimmedReqId != null && trimmedReqId.isNotEmpty) {
      final existing = await _db.jobProcessDao.findHandoverByClientRequestId(
        trimmedReqId,
      );
      if (existing != null) return _hydrateHandover(existing);
    }

    final row = await _db.jobProcessDao.findJobProcessById(jobProcessId);
    if (row == null || row.deletedAt != null) {
      _throwValidation('process_not_found');
    }
    final status = JobProcessStatus.fromDbValue(row.status);
    if (status.isTerminal) {
      _throwValidation('process_already_closed');
    }
    final balance = await _stockRepo.getDesignColourBalance(row.designColourId);
    if (balance == null) _throwValidation('sku_not_found');

    final err = _validator.validateFactoryDispatch(
      designColourId: row.designColourId,
      processId: row.processId,
      workerId: row.memberId,
      quantity: quantity,
      availableInHouse: balance.physicalAvailableInHouse,
    );
    if (err != null) _throwValidation(err);

    final actor = await _resolveActor();
    final now = IstDateTimeHelper.nowUtcMillis();
    final handoverId = _idGenerator.nextEntityId();
    final perPiece = _pricingCalc.effectivePerPieceRatePaise(
      quantity: quantity,
      ratePaise: row.agreedRatePaise,
      pricingUnit: row.pricingUnit,
    );

    await _txRunner.runInTransaction(() async {
      final issue = await _issueStockWithResolvedRate(
        designColourId: row.designColourId,
        processId: row.processId,
        workerId: row.memberId!,
        quantity: quantity,
        transactionAtUtcMillis: transactionAtUtcMillis,
        effectivePerPieceRatePaise: perPiece,
        overrideReason: row.rateOverrideReason,
        notes: notes ?? row.notes,
        clientRequestId: trimmedReqId != null && trimmedReqId.isNotEmpty
            ? 'jp_dsp_$trimmedReqId'
            : null,
      );

      final newDispatched = row.dispatchedQuantity + quantity;
      final newPlanned = newDispatched > row.plannedQuantity
          ? newDispatched
          : row.plannedQuantity;
      final newPayable = _pricingCalc.calculateBaseAmountPaise(
        quantity: newPlanned,
        ratePaise: row.agreedRatePaise,
        pricingUnit: row.pricingUnit,
      );
      final nextStatus = _validator.resolveStatus(
        dispatchedQty: newDispatched,
        receivedQty: row.receivedQuantity,
        returnedQty: row.returnedToFactoryQuantity,
        transferredOutQty: row.transferredOutQuantity,
        damagedQty: row.damagedQuantity,
        isCancelled: false,
      );

      await _db.jobProcessDao.updateJobProcess(
        row.id,
        JobProcessesCompanion(
          plannedQuantity: Value(newPlanned),
          dispatchedQuantity: Value(newDispatched),
          payableAmountPaise: Value(newPayable),
          status: Value(nextStatus.dbValue),
          linkedIssueMovementId: Value(row.linkedIssueMovementId ?? issue.id),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );

      final ref = _validator.generateReference(
        type: ProcessHandoverType.factoryDispatch,
        transactionAtUtcMillis: transactionAtUtcMillis,
        uniqueId: handoverId,
      );
      await _db.jobProcessDao.insertHandover(
        ProcessHandoversCompanion.insert(
          id: handoverId,
          transferReference: ref,
          clientRequestId: Value(
            trimmedReqId != null && trimmedReqId.isNotEmpty
                ? trimmedReqId
                : null,
          ),
          lotId: row.lotId,
          lotDesignId: row.lotDesignId,
          designColourId: row.designColourId,
          handoverType: ProcessHandoverType.factoryDispatch.dbValue,
          toJobProcessId: Value(row.id),
          toMemberId: Value(row.memberId),
          processId: row.processId,
          quantityDispatched: quantity,
          quantityReceived: const Value(0),
          status: Value(ProcessHandoverStatus.pendingReceipt.dbValue),
          linkedStockMovementId: Value(issue.id),
          notes: Value(notes?.trim()),
          transactionAt: transactionAtUtcMillis,
          recordedAt: now,
          createdBy: Value(actor),
          createdAt: now,
          updatedAt: now,
        ),
      );
    });

    final created = await _db.jobProcessDao.findHandoverById(handoverId);
    return _hydrateHandover(created!);
  }

  @override
  Future<ProcessHandoverEntity> confirmHandoverReceipt({
    required String handoverId,
    required int receivedQuantity,
    required int transactionAtUtcMillis,
  }) async {
    final row = await _db.jobProcessDao.findHandoverById(handoverId);
    if (row == null) _throwValidation('handover_not_found');

    final currentStatus = ProcessHandoverStatus.fromDbValue(row.status);
    final err = _validator.validateReceiptConfirmation(
      quantityDispatched: row.quantityDispatched,
      alreadyReceived: row.quantityReceived,
      receiveNow: receivedQuantity,
      currentStatus: currentStatus,
    );
    if (err != null) _throwValidation(err);

    final actor = await _resolveActor();
    final now = IstDateTimeHelper.nowUtcMillis();
    final newReceived = row.quantityReceived + receivedQuantity;
    final nextHandoverStatus = newReceived >= row.quantityDispatched
        ? ProcessHandoverStatus.received
        : ProcessHandoverStatus.partiallyReceived;

    await _txRunner.runInTransaction(() async {
      await _db.jobProcessDao.updateHandoverReceipt(
        handoverId,
        quantityReceived: newReceived,
        status: nextHandoverStatus.dbValue,
        updatedAt: now,
      );

      if (row.toJobProcessId != null) {
        final targetJp = await _db.jobProcessDao.findJobProcessById(
          row.toJobProcessId!,
        );
        if (targetJp != null) {
          final updatedReceived = targetJp.receivedQuantity + receivedQuantity;
          final nextJpStatus = _validator.resolveStatus(
            dispatchedQty: targetJp.dispatchedQuantity,
            receivedQty: updatedReceived,
            returnedQty: targetJp.returnedToFactoryQuantity,
            transferredOutQty: targetJp.transferredOutQuantity,
            damagedQty: targetJp.damagedQuantity,
            isCancelled:
                JobProcessStatus.fromDbValue(targetJp.status) ==
                JobProcessStatus.cancelled,
          );
          await _db.jobProcessDao.updateJobProcess(
            targetJp.id,
            JobProcessesCompanion(
              receivedQuantity: Value(updatedReceived),
              status: Value(nextJpStatus.dbValue),
              updatedBy: Value(actor),
              updatedAt: Value(now),
            ),
          );
        }
      }

      await _writeAudit(
        entityType: 'PROCESS_HANDOVER',
        entityId: handoverId,
        actionType: 'UPDATE',
        actor: actor,
        payload: {
          'event': 'RECEIPT_CONFIRMED',
          'transferReference': row.transferReference,
          'receivedNow': receivedQuantity,
          'totalReceived': newReceived,
          'status': nextHandoverStatus.dbValue,
        },
        transactionAt: transactionAtUtcMillis,
        now: now,
      );
    });

    final updated = await _db.jobProcessDao.findHandoverById(handoverId);
    return _hydrateHandover(updated!);
  }

  @override
  Future<ProcessHandoverEntity> directTransfer({
    required String sourceJobProcessId,
    required String destinationProcessId,
    required String destinationWorkerId,
    required int quantity,
    required int transactionAtUtcMillis,
    bool autoConfirmReceipt = false,
    int? agreedRatePaise,
    String? pricingUnit,
    String? rateOverrideReason,
    String? notes,
    String? clientRequestId,
  }) async {
    final trimmedReqId = clientRequestId?.trim();
    if (trimmedReqId != null && trimmedReqId.isNotEmpty) {
      final existing = await _db.jobProcessDao.findHandoverByClientRequestId(
        trimmedReqId,
      );
      if (existing != null) return _hydrateHandover(existing);
    }

    final srcRow = await _db.jobProcessDao.findJobProcessById(
      sourceJobProcessId,
    );
    if (srcRow == null || srcRow.deletedAt != null) {
      _throwValidation('process_not_found');
    }
    final srcEntity = await _hydrateJobProcess(srcRow);

    final err = _validator.validateDirectTransfer(
      sourceProcess: srcEntity,
      destinationWorkerId: destinationWorkerId,
      destinationProcessId: destinationProcessId,
      transferQuantity: quantity,
    );
    if (err != null) _throwValidation(err);

    final destPricing = await _resolveAssignmentPricing(
      processId: destinationProcessId,
      workerId: destinationWorkerId,
      quantity: quantity,
      transactionAtUtcMillis: transactionAtUtcMillis,
      requestedAgreedRatePaise: agreedRatePaise,
      requestedPricingUnit: pricingUnit,
      requestedOverrideReason: rateOverrideReason,
    );

    final actor = await _resolveActor();
    final now = IstDateTimeHelper.nowUtcMillis();
    final handoverId = _idGenerator.nextEntityId();
    final destJpId = _idGenerator.nextEntityId();
    final ref = _validator.generateReference(
      type: ProcessHandoverType.directTransfer,
      transactionAtUtcMillis: transactionAtUtcMillis,
      uniqueId: handoverId,
    );

    await _txRunner.runInTransaction(() async {
      if (srcRow.linkedIssueMovementId != null) {
        await _stockRepo.recordSettlement(
          parentIssueId: srcRow.linkedIssueMovementId!,
          goodQuantity: quantity,
          damagedQuantity: 0,
          lostQuantity: 0,
          shortageQuantity: 0,
          transactionAtUtcMillis: transactionAtUtcMillis,
          notes:
              'Direct transfer $ref${notes != null && notes.trim().isNotEmpty ? ' • ${notes.trim()}' : ''}',
          clientRequestId: trimmedReqId != null && trimmedReqId.isNotEmpty
              ? 'dt_ret_$trimmedReqId'
              : null,
        );
      }

      final destIssue = await _issueStockWithResolvedRate(
        designColourId: srcRow.designColourId,
        processId: destinationProcessId,
        workerId: destinationWorkerId,
        quantity: quantity,
        transactionAtUtcMillis: transactionAtUtcMillis,
        effectivePerPieceRatePaise: destPricing.perPieceRatePaise,
        overrideReason: destPricing.overrideReason,
        notes:
            'Received via direct transfer $ref${notes != null && notes.trim().isNotEmpty ? ' • ${notes.trim()}' : ''}',
        clientRequestId: trimmedReqId != null && trimmedReqId.isNotEmpty
            ? 'dt_iss_$trimmedReqId'
            : null,
      );

      final newTransferredOut = srcRow.transferredOutQuantity + quantity;
      final srcNextStatus = _validator.resolveStatus(
        dispatchedQty: srcRow.dispatchedQuantity,
        receivedQty: srcRow.receivedQuantity,
        returnedQty: srcRow.returnedToFactoryQuantity,
        transferredOutQty: newTransferredOut,
        damagedQty: srcRow.damagedQuantity,
        isCancelled: false,
      );
      await _db.jobProcessDao.updateJobProcess(
        srcRow.id,
        JobProcessesCompanion(
          transferredOutQuantity: Value(newTransferredOut),
          status: Value(srcNextStatus.dbValue),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );

      final nextSeq = await _db.jobProcessDao.getNextSequenceOrderForLot(
        srcRow.lotId,
      );
      final destStatus = autoConfirmReceipt
          ? JobProcessStatus.inProgress
          : JobProcessStatus.dispatched;

      await _db.jobProcessDao.insertJobProcess(
        JobProcessesCompanion.insert(
          id: destJpId,
          lotId: srcRow.lotId,
          lotDesignId: srcRow.lotDesignId,
          designColourId: srcRow.designColourId,
          processId: destinationProcessId,
          memberId: Value(destinationWorkerId),
          sequenceOrder: Value(nextSeq),
          plannedQuantity: quantity,
          dispatchedQuantity: Value(quantity),
          receivedQuantity: Value(autoConfirmReceipt ? quantity : 0),
          status: Value(destStatus.dbValue),
          sourceJobProcessId: Value(srcRow.id),
          linkedIssueMovementId: Value(destIssue.id),
          defaultRatePaise: Value(destPricing.defaultRatePaise),
          agreedRatePaise: Value(destPricing.agreedRatePaise),
          pricingUnit: Value(destPricing.pricingUnit),
          rateOverrideReason: Value(destPricing.overrideReason),
          payableAmountPaise: Value(destPricing.payableAmountPaise),
          paidAmountPaise: const Value(0),
          paymentStatus: Value(
            _pricingCalc
                .resolvePaymentStatus(
                  netPayablePaise: destPricing.payableAmountPaise,
                  paidPaise: 0,
                )
                .dbValue,
          ),
          notes: Value(notes?.trim()),
          transactionAt: transactionAtUtcMillis,
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: now,
          updatedAt: now,
        ),
      );

      if (destPricing.isOverridden) {
        await _db.jobProcessDao.insertRateHistory(
          ProcessRateHistoriesCompanion.insert(
            id: _idGenerator.nextEntityId(),
            scope: 'JOB_ASSIGNMENT',
            processId: destinationProcessId,
            jobProcessId: Value(destJpId),
            memberId: Value(destinationWorkerId),
            designColourId: Value(srcRow.designColourId),
            previousRatePaise: destPricing.defaultRatePaise,
            newRatePaise: destPricing.agreedRatePaise,
            pricingUnit: destPricing.pricingUnit,
            reason: destPricing.overrideReason!,
            changedBy: Value(actor),
            changedAt: now,
          ),
        );
      }

      await _db.jobProcessDao.insertHandover(
        ProcessHandoversCompanion.insert(
          id: handoverId,
          transferReference: ref,
          clientRequestId: Value(
            trimmedReqId != null && trimmedReqId.isNotEmpty
                ? trimmedReqId
                : null,
          ),
          lotId: srcRow.lotId,
          lotDesignId: srcRow.lotDesignId,
          designColourId: srcRow.designColourId,
          handoverType: ProcessHandoverType.directTransfer.dbValue,
          fromJobProcessId: Value(srcRow.id),
          toJobProcessId: Value(destJpId),
          fromMemberId: Value(srcRow.memberId),
          toMemberId: Value(destinationWorkerId),
          processId: destinationProcessId,
          quantityDispatched: quantity,
          quantityReceived: Value(autoConfirmReceipt ? quantity : 0),
          status: Value(
            autoConfirmReceipt
                ? ProcessHandoverStatus.received.dbValue
                : ProcessHandoverStatus.pendingReceipt.dbValue,
          ),
          linkedStockMovementId: Value(destIssue.id),
          notes: Value(notes?.trim()),
          transactionAt: transactionAtUtcMillis,
          recordedAt: now,
          createdBy: Value(actor),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await _writeAudit(
        entityType: 'PROCESS_HANDOVER',
        entityId: handoverId,
        actionType: 'CREATE',
        actor: actor,
        payload: {
          'event': 'DIRECT_TRANSFER',
          'transferReference': ref,
          'fromJobProcessId': srcRow.id,
          'toJobProcessId': destJpId,
          'fromMemberId': srcRow.memberId,
          'toMemberId': destinationWorkerId,
          'destinationProcessId': destinationProcessId,
          'designColourId': srcRow.designColourId,
          'quantity': quantity,
          'agreedRatePaise': destPricing.agreedRatePaise,
        },
        transactionAt: transactionAtUtcMillis,
        now: now,
        reason: destPricing.overrideReason,
      );
    });

    final created = await _db.jobProcessDao.findHandoverById(handoverId);
    return _hydrateHandover(created!);
  }

  @override
  Future<ProcessHandoverEntity> returnToFactory({
    required String sourceJobProcessId,
    required int goodQuantity,
    int damagedQuantity = 0,
    required int transactionAtUtcMillis,
    String? reason,
    String? notes,
    String? clientRequestId,
  }) async {
    final trimmedReqId = clientRequestId?.trim();
    if (trimmedReqId != null && trimmedReqId.isNotEmpty) {
      final existing = await _db.jobProcessDao.findHandoverByClientRequestId(
        trimmedReqId,
      );
      if (existing != null) return _hydrateHandover(existing);
    }

    final srcRow = await _db.jobProcessDao.findJobProcessById(
      sourceJobProcessId,
    );
    if (srcRow == null || srcRow.deletedAt != null) {
      _throwValidation('process_not_found');
    }
    final srcEntity = await _hydrateJobProcess(srcRow);

    final err = _validator.validateFactoryReturn(
      sourceProcess: srcEntity,
      goodQuantity: goodQuantity,
      damagedQuantity: damagedQuantity,
      reason: reason,
    );
    if (err != null) _throwValidation(err);

    final totalReturned = goodQuantity + damagedQuantity;
    final actor = await _resolveActor();
    final now = IstDateTimeHelper.nowUtcMillis();
    final handoverId = _idGenerator.nextEntityId();
    final ref = _validator.generateReference(
      type: ProcessHandoverType.factoryReturn,
      transactionAtUtcMillis: transactionAtUtcMillis,
      uniqueId: handoverId,
    );

    await _txRunner.runInTransaction(() async {
      String? linkedMovementId;
      if (srcRow.linkedIssueMovementId != null) {
        final batch = await _stockRepo.recordSettlement(
          parentIssueId: srcRow.linkedIssueMovementId!,
          goodQuantity: goodQuantity,
          damagedQuantity: damagedQuantity,
          lostQuantity: 0,
          shortageQuantity: 0,
          transactionAtUtcMillis: transactionAtUtcMillis,
          reason: reason,
          notes:
              'Factory return $ref${notes != null && notes.trim().isNotEmpty ? ' • ${notes.trim()}' : ''}',
          clientRequestId: trimmedReqId != null && trimmedReqId.isNotEmpty
              ? 'fr_ret_$trimmedReqId'
              : null,
        );
        if (batch.createdMovements.isNotEmpty) {
          linkedMovementId = batch.createdMovements.first.id;
        }
      }

      final newReturned = srcRow.returnedToFactoryQuantity + goodQuantity;
      final newDamaged = srcRow.damagedQuantity + damagedQuantity;
      final nextStatus = _validator.resolveStatus(
        dispatchedQty: srcRow.dispatchedQuantity,
        receivedQty: srcRow.receivedQuantity,
        returnedQty: newReturned,
        transferredOutQty: srcRow.transferredOutQuantity,
        damagedQty: newDamaged,
        isCancelled: false,
      );

      await _db.jobProcessDao.updateJobProcess(
        srcRow.id,
        JobProcessesCompanion(
          returnedToFactoryQuantity: Value(newReturned),
          damagedQuantity: Value(newDamaged),
          status: Value(nextStatus.dbValue),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );

      await _db.jobProcessDao.insertHandover(
        ProcessHandoversCompanion.insert(
          id: handoverId,
          transferReference: ref,
          clientRequestId: Value(
            trimmedReqId != null && trimmedReqId.isNotEmpty
                ? trimmedReqId
                : null,
          ),
          lotId: srcRow.lotId,
          lotDesignId: srcRow.lotDesignId,
          designColourId: srcRow.designColourId,
          handoverType: ProcessHandoverType.factoryReturn.dbValue,
          fromJobProcessId: Value(srcRow.id),
          fromMemberId: Value(srcRow.memberId),
          processId: srcRow.processId,
          quantityDispatched: totalReturned,
          quantityReceived: Value(totalReturned),
          status: Value(ProcessHandoverStatus.received.dbValue),
          linkedStockMovementId: Value(linkedMovementId),
          notes: Value(notes?.trim()),
          transactionAt: transactionAtUtcMillis,
          recordedAt: now,
          createdBy: Value(actor),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await _writeAudit(
        entityType: 'PROCESS_HANDOVER',
        entityId: handoverId,
        actionType: 'CREATE',
        actor: actor,
        payload: {
          'event': 'FACTORY_RETURN',
          'transferReference': ref,
          'fromJobProcessId': srcRow.id,
          'designColourId': srcRow.designColourId,
          'goodQuantity': goodQuantity,
          'damagedQuantity': damagedQuantity,
        },
        transactionAt: transactionAtUtcMillis,
        now: now,
        reason: reason,
      );
    });

    final created = await _db.jobProcessDao.findHandoverById(handoverId);
    return _hydrateHandover(created!);
  }

  @override
  Future<ProcessHandoverEntity> reassignFromFactory({
    required String lotId,
    required String designColourId,
    required String targetProcessId,
    required String targetWorkerId,
    required int quantity,
    required int transactionAtUtcMillis,
    int? agreedRatePaise,
    String? pricingUnit,
    String? rateOverrideReason,
    String? notes,
    String? clientRequestId,
  }) async {
    final trimmedReqId = clientRequestId?.trim();
    if (trimmedReqId != null && trimmedReqId.isNotEmpty) {
      final existing = await _db.jobProcessDao.findHandoverByClientRequestId(
        trimmedReqId,
      );
      if (existing != null) return _hydrateHandover(existing);
    }

    final balance = await _stockRepo.getDesignColourBalance(designColourId);
    if (balance == null || balance.lotId != lotId) {
      _throwValidation('sku_not_found');
    }

    final err = _validator.validateReassignment(
      designColourId: designColourId,
      targetProcessId: targetProcessId,
      targetWorkerId: targetWorkerId,
      quantity: quantity,
      availableInHouse: balance.physicalAvailableInHouse,
    );
    if (err != null) _throwValidation(err);

    final pricing = await _resolveAssignmentPricing(
      processId: targetProcessId,
      workerId: targetWorkerId,
      quantity: quantity,
      transactionAtUtcMillis: transactionAtUtcMillis,
      requestedAgreedRatePaise: agreedRatePaise,
      requestedPricingUnit: pricingUnit,
      requestedOverrideReason: rateOverrideReason,
    );

    final actor = await _resolveActor();
    final now = IstDateTimeHelper.nowUtcMillis();
    final handoverId = _idGenerator.nextEntityId();
    final newJpId = _idGenerator.nextEntityId();
    final ref = _validator.generateReference(
      type: ProcessHandoverType.reassignment,
      transactionAtUtcMillis: transactionAtUtcMillis,
      uniqueId: handoverId,
    );

    await _txRunner.runInTransaction(() async {
      final issue = await _issueStockWithResolvedRate(
        designColourId: designColourId,
        processId: targetProcessId,
        workerId: targetWorkerId,
        quantity: quantity,
        transactionAtUtcMillis: transactionAtUtcMillis,
        effectivePerPieceRatePaise: pricing.perPieceRatePaise,
        overrideReason: pricing.overrideReason,
        notes:
            'Factory reassignment $ref${notes != null && notes.trim().isNotEmpty ? ' • ${notes.trim()}' : ''}',
        clientRequestId: trimmedReqId != null && trimmedReqId.isNotEmpty
            ? 'ras_iss_$trimmedReqId'
            : null,
      );

      final nextSeq = await _db.jobProcessDao.getNextSequenceOrderForLot(lotId);
      await _db.jobProcessDao.insertJobProcess(
        JobProcessesCompanion.insert(
          id: newJpId,
          lotId: lotId,
          lotDesignId: balance.lotDesignId,
          designColourId: designColourId,
          processId: targetProcessId,
          memberId: Value(targetWorkerId),
          sequenceOrder: Value(nextSeq),
          plannedQuantity: quantity,
          dispatchedQuantity: Value(quantity),
          receivedQuantity: const Value(0),
          status: Value(JobProcessStatus.dispatched.dbValue),
          linkedIssueMovementId: Value(issue.id),
          defaultRatePaise: Value(pricing.defaultRatePaise),
          agreedRatePaise: Value(pricing.agreedRatePaise),
          pricingUnit: Value(pricing.pricingUnit),
          rateOverrideReason: Value(pricing.overrideReason),
          payableAmountPaise: Value(pricing.payableAmountPaise),
          paidAmountPaise: const Value(0),
          paymentStatus: Value(
            _pricingCalc
                .resolvePaymentStatus(
                  netPayablePaise: pricing.payableAmountPaise,
                  paidPaise: 0,
                )
                .dbValue,
          ),
          notes: Value(notes?.trim()),
          transactionAt: transactionAtUtcMillis,
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: now,
          updatedAt: now,
        ),
      );

      if (pricing.isOverridden) {
        await _db.jobProcessDao.insertRateHistory(
          ProcessRateHistoriesCompanion.insert(
            id: _idGenerator.nextEntityId(),
            scope: 'JOB_ASSIGNMENT',
            processId: targetProcessId,
            jobProcessId: Value(newJpId),
            memberId: Value(targetWorkerId),
            designColourId: Value(designColourId),
            previousRatePaise: pricing.defaultRatePaise,
            newRatePaise: pricing.agreedRatePaise,
            pricingUnit: pricing.pricingUnit,
            reason: pricing.overrideReason!,
            changedBy: Value(actor),
            changedAt: now,
          ),
        );
      }

      await _db.jobProcessDao.insertHandover(
        ProcessHandoversCompanion.insert(
          id: handoverId,
          transferReference: ref,
          clientRequestId: Value(
            trimmedReqId != null && trimmedReqId.isNotEmpty
                ? trimmedReqId
                : null,
          ),
          lotId: lotId,
          lotDesignId: balance.lotDesignId,
          designColourId: designColourId,
          handoverType: ProcessHandoverType.reassignment.dbValue,
          toJobProcessId: Value(newJpId),
          toMemberId: Value(targetWorkerId),
          processId: targetProcessId,
          quantityDispatched: quantity,
          quantityReceived: const Value(0),
          status: Value(ProcessHandoverStatus.pendingReceipt.dbValue),
          linkedStockMovementId: Value(issue.id),
          notes: Value(notes?.trim()),
          transactionAt: transactionAtUtcMillis,
          recordedAt: now,
          createdBy: Value(actor),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await _writeAudit(
        entityType: 'PROCESS_HANDOVER',
        entityId: handoverId,
        actionType: 'CREATE',
        actor: actor,
        payload: {
          'event': 'REASSIGNMENT',
          'transferReference': ref,
          'toJobProcessId': newJpId,
          'targetProcessId': targetProcessId,
          'targetWorkerId': targetWorkerId,
          'quantity': quantity,
          'agreedRatePaise': pricing.agreedRatePaise,
        },
        transactionAt: transactionAtUtcMillis,
        now: now,
        reason: pricing.overrideReason,
      );
    });

    final created = await _db.jobProcessDao.findHandoverById(handoverId);
    return _hydrateHandover(created!);
  }

  @override
  Future<ProcessAdditionalChargeEntity> addAdditionalCharge({
    required String jobProcessId,
    required ProcessChargeType chargeType,
    required String description,
    required int amountPaise,
    required int transactionAtUtcMillis,
    String? clientRequestId,
  }) async {
    final trimmedReqId = clientRequestId?.trim();
    if (trimmedReqId != null && trimmedReqId.isNotEmpty) {
      final existing = await _db.jobProcessDao.findChargeByClientRequestId(
        trimmedReqId,
      );
      if (existing != null) return _mapCharge(existing);
    }

    if (amountPaise <= 0) _throwValidation('invalid_amount');
    final cleanDesc = description.trim();
    if (cleanDesc.isEmpty) _throwValidation('description_required');

    final jp = await _db.jobProcessDao.findJobProcessById(jobProcessId);
    if (jp == null || jp.deletedAt != null || jp.memberId == null) {
      _throwValidation('process_not_found');
    }

    final actor = await _resolveActor();
    final now = IstDateTimeHelper.nowUtcMillis();
    final chargeId = _idGenerator.nextEntityId();

    await _txRunner.runInTransaction(() async {
      await _db.jobProcessDao.insertAdditionalCharge(
        ProcessAdditionalChargesCompanion.insert(
          id: chargeId,
          jobProcessId: jp.id,
          lotId: jp.lotId,
          designColourId: jp.designColourId,
          memberId: jp.memberId!,
          chargeType: chargeType.dbValue,
          description: cleanDesc,
          amountPaise: amountPaise,
          clientRequestId: Value(
            trimmedReqId != null && trimmedReqId.isNotEmpty
                ? trimmedReqId
                : null,
          ),
          createdBy: Value(actor),
          transactionAt: transactionAtUtcMillis,
          createdAt: now,
        ),
      );

      // Recompute payment status for this operation against updated net payable
      final allOpCharges = await _db.jobProcessDao.getChargesForJobProcess(
        jp.id,
      );
      var extra = 0;
      var deduct = 0;
      for (final c in allOpCharges) {
        if (c.chargeType == ProcessChargeType.extraCharge.dbValue) {
          extra += c.amountPaise;
        } else {
          deduct += c.amountPaise;
        }
      }
      final netPayable = (jp.payableAmountPaise + extra - deduct).clamp(
        0,
        1 << 62,
      );
      final payStatus = _pricingCalc.resolvePaymentStatus(
        netPayablePaise: netPayable,
        paidPaise: jp.paidAmountPaise,
      );

      await _db.jobProcessDao.updateJobProcess(
        jp.id,
        JobProcessesCompanion(
          paymentStatus: Value(payStatus.dbValue),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );

      await _writeAudit(
        entityType: 'PROCESS_CHARGE',
        entityId: chargeId,
        actionType: 'CREATE',
        actor: actor,
        payload: {
          'jobProcessId': jp.id,
          'chargeType': chargeType.dbValue,
          'description': cleanDesc,
          'amountPaise': amountPaise,
        },
        transactionAt: transactionAtUtcMillis,
        now: now,
      );
    });

    final rows = await _db.jobProcessDao.getChargesForJobProcess(jp.id);
    return _mapCharge(rows.firstWhere((r) => r.id == chargeId));
  }

  @override
  Future<JobProcessEntity> recordProcessPayment({
    required String jobProcessId,
    required int amountPaise,
    required String paymentMode,
    required int transactionAtUtcMillis,
    String? referenceNo,
    String? notes,
    String? clientRequestId,
  }) async {
    if (amountPaise <= 0) _throwValidation('invalid_amount');
    final jp = await _db.jobProcessDao.findJobProcessById(jobProcessId);
    if (jp == null || jp.deletedAt != null || jp.memberId == null) {
      _throwValidation('process_not_found');
    }

    final trimmedReqId = clientRequestId?.trim();
    if (trimmedReqId != null && trimmedReqId.isNotEmpty) {
      final existingPay = await _db.paymentDao.findByClientRequestId(
        trimmedReqId,
      );
      if (existingPay != null) return _hydrateJobProcess(jp);
    }

    final allOpCharges = await _db.jobProcessDao.getChargesForJobProcess(jp.id);
    var extra = 0;
    var deduct = 0;
    for (final c in allOpCharges) {
      if (c.chargeType == ProcessChargeType.extraCharge.dbValue) {
        extra += c.amountPaise;
      } else {
        deduct += c.amountPaise;
      }
    }
    final netPayable = (jp.payableAmountPaise + extra - deduct).clamp(
      0,
      1 << 62,
    );
    final remaining = netPayable - jp.paidAmountPaise;
    if (amountPaise > remaining) {
      _throwValidation('exceeds_outstanding_payable');
    }

    final actor = await _resolveActor();
    final now = IstDateTimeHelper.nowUtcMillis();
    final paymentId = _idGenerator.nextEntityId();
    final newPaid = jp.paidAmountPaise + amountPaise;
    final payStatus = _pricingCalc.resolvePaymentStatus(
      netPayablePaise: netPayable,
      paidPaise: newPaid,
    );

    await _txRunner.runInTransaction(() async {
      // Single unified payments ledger (zero duplicate payment system!)
      await _db.paymentDao.insertPayment(
        PaymentsCompanion.insert(
          id: paymentId,
          memberId: jp.memberId!,
          paymentType: 'REGULAR',
          clientRequestId: Value(
            trimmedReqId != null && trimmedReqId.isNotEmpty
                ? trimmedReqId
                : null,
          ),
          amountPaise: amountPaise,
          paymentMode: paymentMode,
          referenceNo: Value(referenceNo?.trim()),
          notes: Value(
            notes?.trim().isNotEmpty == true
                ? notes!.trim()
                : 'Process payment (${jp.id})',
          ),
          transactionAt: transactionAtUtcMillis,
          recordedAt: now,
          createdBy: Value(actor),
          updatedBy: Value(actor),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await _db.jobProcessDao.updateJobProcess(
        jp.id,
        JobProcessesCompanion(
          paidAmountPaise: Value(newPaid),
          paymentStatus: Value(payStatus.dbValue),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );

      await _writeAudit(
        entityType: 'JOB_PROCESS_PAYMENT',
        entityId: paymentId,
        actionType: 'CREATE',
        actor: actor,
        payload: {
          'jobProcessId': jp.id,
          'memberId': jp.memberId,
          'amountPaise': amountPaise,
          'totalPaidPaise': newPaid,
          'paymentStatus': payStatus.dbValue,
        },
        transactionAt: transactionAtUtcMillis,
        now: now,
      );
    });

    final updated = await _db.jobProcessDao.findJobProcessById(jp.id);
    return _hydrateJobProcess(updated!);
  }

  @override
  Future<JobProcessEntity> markProcessCompleted({
    required String jobProcessId,
    required int transactionAtUtcMillis,
  }) async {
    final row = await _db.jobProcessDao.findJobProcessById(jobProcessId);
    if (row == null || row.deletedAt != null) {
      _throwValidation('process_not_found');
    }
    final entity = await _hydrateJobProcess(row);
    final err = _validator.validateCompletion(entity);
    if (err != null) _throwValidation(err);

    final actor = await _resolveActor();
    final now = IstDateTimeHelper.nowUtcMillis();

    await _txRunner.runInTransaction(() async {
      await _db.jobProcessDao.updateJobProcess(
        jobProcessId,
        JobProcessesCompanion(
          status: Value(JobProcessStatus.completed.dbValue),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );
      await _writeAudit(
        entityType: 'JOB_PROCESS',
        entityId: jobProcessId,
        actionType: 'UPDATE',
        actor: actor,
        payload: {'status': JobProcessStatus.completed.dbValue},
        transactionAt: transactionAtUtcMillis,
        now: now,
      );
    });

    final updated = await _db.jobProcessDao.findJobProcessById(jobProcessId);
    return _hydrateJobProcess(updated!);
  }

  @override
  Future<JobProcessEntity> cancelJobProcess({
    required String jobProcessId,
    required String reason,
    required int transactionAtUtcMillis,
  }) async {
    if (reason.trim().isEmpty) _throwValidation('reason_required');
    final row = await _db.jobProcessDao.findJobProcessById(jobProcessId);
    if (row == null || row.deletedAt != null) {
      _throwValidation('process_not_found');
    }
    final entity = await _hydrateJobProcess(row);
    final err = _validator.validateCancellation(entity);
    if (err != null) _throwValidation(err);

    final actor = await _resolveActor();
    final now = IstDateTimeHelper.nowUtcMillis();
    final handoverId = _idGenerator.nextEntityId();
    final ref = _validator.generateReference(
      type: ProcessHandoverType.cancellation,
      transactionAtUtcMillis: transactionAtUtcMillis,
      uniqueId: handoverId,
    );

    await _txRunner.runInTransaction(() async {
      await _db.jobProcessDao.updateJobProcess(
        jobProcessId,
        JobProcessesCompanion(
          status: Value(JobProcessStatus.cancelled.dbValue),
          notes: Value(reason.trim()),
          updatedBy: Value(actor),
          updatedAt: Value(now),
        ),
      );

      await _db.jobProcessDao.insertHandover(
        ProcessHandoversCompanion.insert(
          id: handoverId,
          transferReference: ref,
          lotId: row.lotId,
          lotDesignId: row.lotDesignId,
          designColourId: row.designColourId,
          handoverType: ProcessHandoverType.cancellation.dbValue,
          fromJobProcessId: Value(row.id),
          fromMemberId: Value(row.memberId),
          processId: row.processId,
          quantityDispatched: 0,
          quantityReceived: const Value(0),
          status: Value(ProcessHandoverStatus.cancelled.dbValue),
          notes: Value(reason.trim()),
          transactionAt: transactionAtUtcMillis,
          recordedAt: now,
          createdBy: Value(actor),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await _writeAudit(
        entityType: 'JOB_PROCESS',
        entityId: jobProcessId,
        actionType: 'UPDATE',
        actor: actor,
        payload: {
          'event': 'CANCELLED',
          'reason': reason.trim(),
          'reference': ref,
        },
        transactionAt: transactionAtUtcMillis,
        now: now,
        reason: reason.trim(),
      );
    });

    final updated = await _db.jobProcessDao.findJobProcessById(jobProcessId);
    return _hydrateJobProcess(updated!);
  }
}
