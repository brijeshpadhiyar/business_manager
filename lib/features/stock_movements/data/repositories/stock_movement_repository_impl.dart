import 'dart:convert';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/domain/calculators/labour_calculator.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/notifications/data/services/notification_refresh_coordinator.dart';
import 'package:business_manager/features/rates/domain/entities/rate_entities.dart';
import 'package:business_manager/features/rates/domain/services/member_process_rate_resolver.dart';
import 'package:business_manager/features/reports/domain/calculators/workshop_daily_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/calculators/stock_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: StockMovementRepository)
final class StockMovementRepositoryImpl implements StockMovementRepository {
  StockMovementRepositoryImpl(this._db, this._txRunner, this._idGenerator);

  final AppDatabase _db;
  final DatabaseTransactionRunner _txRunner;
  final IdGenerator _idGenerator;

  static const StockCalculator _stockCalc = StockCalculator();
  static const LabourCalculator _labourCalc = LabourCalculator();
  static const MemberProcessRateResolver _rateResolver =
      MemberProcessRateResolver();

  StockMovementEntity _mapRow(StockMovementRow row) {
    return StockMovementEntity(
      id: row.id,
      lotId: row.lotId,
      lotDesignId: row.lotDesignId,
      designColourId: row.designColourId,
      processId: row.processId,
      memberId: row.memberId,
      parentIssueId: row.parentIssueId,
      reversesMovementId: row.reversesMovementId,
      clientRequestId: row.clientRequestId,
      movementType: StockMovementType.fromDbValue(row.movementType),
      quantity: row.quantity,
      sourceRateId: row.sourceRateId,
      appliedRatePaise: row.appliedRatePaise,
      isRateOverridden: row.isRateOverridden == 1,
      overrideReason: row.overrideReason,
      lockedBillingMode: row.lockedBillingMode != null
          ? BillingMode.fromDbValue(row.lockedBillingMode!)
          : null,
      lockedIncludeDamaged: row.lockedIncludeDamaged == 1,
      reason: row.reason,
      notes: row.notes,
      transactionAt: row.transactionAt,
      recordedAt: row.recordedAt,
      createdBy: row.createdBy,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  MemberProcessRateEntity _mapRateRow(MemberProcessRateRow r) {
    return MemberProcessRateEntity(
      id: r.id,
      memberId: r.memberId,
      processId: r.processId,
      ratePaise: r.ratePaise,
      effectiveFrom: r.effectiveFrom,
      effectiveTo: r.effectiveTo,
      notes: r.notes,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }

  LabourEntryEntity _mapLabourRow(LabourEntryRow r) {
    return LabourEntryEntity(
      id: r.id,
      stockMovementId: r.stockMovementId,
      reversesLabourEntryId: r.reversesLabourEntryId,
      memberId: r.memberId,
      processId: r.processId,
      lotId: r.lotId,
      basisType: LabourBasisType.fromDbValue(r.basisType),
      quantity: r.quantity,
      ratePaise: r.ratePaise,
      amountPaise: r.amountPaise,
      isPayable: r.isPayable == 1,
      transactionAt: r.transactionAt,
      recordedAt: r.recordedAt,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    );
  }

  Future<String?> _resolveActor() async {
    final profile = await _db.businessProfileDao.getProfile();
    final owner = profile?.ownerName?.trim();
    return (owner != null && owner.isNotEmpty) ? owner : 'local_owner';
  }

  @override
  Future<RateResolutionResult> previewRate({
    required String workerId,
    required String processId,
    required int transactionAtUtcMillis,
  }) async {
    final rateRows = await _db.processMemberDao.getActiveRates(
      workerId,
      processId,
    );
    return _rateResolver.resolve(
      workerId: workerId,
      processId: processId,
      transactionAtUtcMillis: transactionAtUtcMillis,
      rates: rateRows.map(_mapRateRow).toList(),
    );
  }

  @override
  Future<DesignColourStockBalance?> getDesignColourBalance(
    String designColourId,
  ) async {
    final colour = await _db.lotDao.findDesignColourById(designColourId);
    if (colour == null || colour.deletedAt != null) return null;
    final design = await _db.lotDao.findDesignById(colour.lotDesignId);
    if (design == null || design.deletedAt != null) return null;
    final lot = await _db.lotDao.findLotById(design.lotId);
    if (lot == null || lot.deletedAt != null) return null;

    final movements = (await _db.stockMovementDao.getMovementsForDesignColour(
      designColourId,
    )).map(_mapRow).toList();
    final procs = await _db.processMemberDao.getNonDeletedProcesses();
    final procNames = {for (final p in procs) p.id: p.name};

    return _stockCalc.calculateDesignColourBalance(
      designColourId: colour.id,
      lotId: lot.id,
      lotNumber: lot.lotNumber,
      lotDesignId: design.id,
      designName: design.designName,
      colourName: colour.colourName,
      colourHex: colour.colourHex,
      unitPricePaise: colour.unitPricePaise,
      initialQuantity: colour.initialQuantity,
      allMovementsForColour: movements,
      processNamesById: procNames,
    );
  }

  @override
  Future<List<DesignColourStockBalance>> getAllDesignColourBalances({
    String? lotId,
    bool onlyWithDamaged = false,
  }) async {
    final activeLots = await _db.lotDao.getActiveLots();
    final activeDesigns = await _db.lotDao.getAllActiveDesigns();
    final activeColours = await _db.lotDao.getAllActiveDesignColours();
    final allMovements = (await _db.stockMovementDao.getAllMovements())
        .map(_mapRow)
        .toList();
    final procs = await _db.processMemberDao.getNonDeletedProcesses();

    final lotById = {for (final l in activeLots) l.id: l};
    final designById = {
      for (final d in activeDesigns)
        if (lotById.containsKey(d.lotId)) d.id: d,
    };
    final procNames = {for (final p in procs) p.id: p.name};

    final movementsByColour = <String, List<StockMovementEntity>>{};
    for (final m in allMovements) {
      movementsByColour.putIfAbsent(m.designColourId, () => []).add(m);
    }

    final result = <DesignColourStockBalance>[];
    for (final c in activeColours) {
      final design = designById[c.lotDesignId];
      if (design == null) continue;
      final lot = lotById[design.lotId];
      if (lot == null) continue;
      if (lotId != null && lot.id != lotId) continue;

      final balance = _stockCalc.calculateDesignColourBalance(
        designColourId: c.id,
        lotId: lot.id,
        lotNumber: lot.lotNumber,
        lotDesignId: design.id,
        designName: design.designName,
        colourName: c.colourName,
        colourHex: c.colourHex,
        unitPricePaise: c.unitPricePaise,
        initialQuantity: c.initialQuantity,
        allMovementsForColour: movementsByColour[c.id] ?? const [],
        processNamesById: procNames,
      );
      if (onlyWithDamaged && balance.damagedBucket <= 0) continue;
      result.add(balance);
    }

    result.sort((a, b) {
      final lotCmp = a.lotNumber.compareTo(b.lotNumber);
      if (lotCmp != 0) return lotCmp;
      final dCmp = a.designName.compareTo(b.designName);
      if (dCmp != 0) return dCmp;
      return a.colourName.compareTo(b.colourName);
    });
    return result;
  }

  Future<
    ({
      Map<String, LotRow> lots,
      Map<String, LotDesignRow> designs,
      Map<String, DesignColourRow> colours,
      Map<String, ProcessRow> processes,
      Map<String, MemberRow> workers,
    })
  >
  _loadLookupMaps() async {
    final allLots = await _db.select(_db.lots).get();
    final allDesigns = await _db.select(_db.lotDesigns).get();
    final allColours = await _db.select(_db.designColours).get();
    final allProcs = await _db.select(_db.processes).get();
    final allWorkers = await _db.select(_db.members).get();

    return (
      lots: {for (final l in allLots) l.id: l},
      designs: {for (final d in allDesigns) d.id: d},
      colours: {for (final c in allColours) c.id: c},
      processes: {for (final p in allProcs) p.id: p},
      workers: {for (final w in allWorkers) w.id: w},
    );
  }

  StockMovementView _buildView({
    required StockMovementEntity movement,
    required Map<String, LotRow> lots,
    required Map<String, LotDesignRow> designs,
    required Map<String, DesignColourRow> colours,
    required Map<String, ProcessRow> processes,
    required Map<String, MemberRow> workers,
    required Map<String, String> reversedByMap,
    required List<StockMovementEntity> colourMovements,
  }) {
    final isReversed = reversedByMap.containsKey(movement.id);
    int good = 0;
    int damaged = 0;
    int lost = 0;
    int shortage = 0;
    int pending = 0;
    if (movement.movementType == StockMovementType.issue && !isReversed) {
      final totals = _stockCalc.calculateIssueSettlementTotals(
        issue: movement,
        allMovementsForColour: colourMovements,
      );
      good = totals.good;
      damaged = totals.damaged;
      lost = totals.lost;
      shortage = totals.shortage;
      pending = totals.pending;
    }

    final lot = lots[movement.lotId];
    final design = designs[movement.lotDesignId];
    final colour = colours[movement.designColourId];
    final proc = movement.processId != null
        ? processes[movement.processId!]
        : null;
    final worker = movement.memberId != null
        ? workers[movement.memberId!]
        : null;

    return StockMovementView(
      movement: movement,
      lotNumber: lot?.lotNumber ?? movement.lotId,
      designName: design?.designName ?? movement.lotDesignId,
      colourName: colour?.colourName ?? movement.designColourId,
      colourHex: colour?.colourHex,
      processName: proc?.name,
      workerName: worker?.name,
      isReversed: isReversed,
      reversedByMovementId: reversedByMap[movement.id],
      returnedGoodQty: good,
      returnedDamagedQty: damaged,
      lostQty: lost,
      shortageQty: shortage,
      remainingPendingQty: pending,
    );
  }

  @override
  Future<List<OpenIssueSummary>> getOpenIssues({
    String? workerId,
    String? processId,
    String? lotId,
    String? designColourId,
  }) async {
    final allMovements = (await _db.stockMovementDao.getAllMovements())
        .map(_mapRow)
        .toList();
    final lookups = await _loadLookupMaps();

    final reversedByMap = <String, String>{};
    final movementsByColour = <String, List<StockMovementEntity>>{};
    final childrenByIssue = <String, List<StockMovementEntity>>{};

    for (final m in allMovements) {
      if (m.movementType == StockMovementType.reversal &&
          m.reversesMovementId != null) {
        reversedByMap[m.reversesMovementId!] = m.id;
      }
      movementsByColour.putIfAbsent(m.designColourId, () => []).add(m);
      if (m.parentIssueId != null) {
        childrenByIssue.putIfAbsent(m.parentIssueId!, () => []).add(m);
      }
    }

    final openIssues = <OpenIssueSummary>[];
    for (final m in allMovements) {
      if (m.movementType != StockMovementType.issue) continue;
      if (reversedByMap.containsKey(m.id)) continue;
      if (workerId != null && m.memberId != workerId) continue;
      if (processId != null && m.processId != processId) continue;
      if (lotId != null && m.lotId != lotId) continue;
      if (designColourId != null && m.designColourId != designColourId) {
        continue;
      }

      final colourList = movementsByColour[m.designColourId] ?? const [];
      final issueView = _buildView(
        movement: m,
        lots: lookups.lots,
        designs: lookups.designs,
        colours: lookups.colours,
        processes: lookups.processes,
        workers: lookups.workers,
        reversedByMap: reversedByMap,
        colourMovements: colourList,
      );
      if (issueView.remainingPendingQty <= 0) continue;

      final children = (childrenByIssue[m.id] ?? const [])
          .map(
            (child) => _buildView(
              movement: child,
              lots: lookups.lots,
              designs: lookups.designs,
              colours: lookups.colours,
              processes: lookups.processes,
              workers: lookups.workers,
              reversedByMap: reversedByMap,
              colourMovements: colourList,
            ),
          )
          .toList();

      openIssues.add(
        OpenIssueSummary(issueView: issueView, childSettlements: children),
      );
    }

    openIssues.sort(
      (a, b) => b.issueView.movement.transactionAt.compareTo(
        a.issueView.movement.transactionAt,
      ),
    );
    return openIssues;
  }

  @override
  Future<OpenIssueSummary?> getIssueDetail(String issueId) async {
    final row = await _db.stockMovementDao.findById(issueId);
    if (row == null) return null;
    final issue = _mapRow(row);
    if (issue.movementType != StockMovementType.issue) return null;

    final colourMovements =
        (await _db.stockMovementDao.getMovementsForDesignColour(
          issue.designColourId,
        )).map(_mapRow).toList();
    final lookups = await _loadLookupMaps();

    final reversedByMap = <String, String>{};
    for (final m in colourMovements) {
      if (m.movementType == StockMovementType.reversal &&
          m.reversesMovementId != null) {
        reversedByMap[m.reversesMovementId!] = m.id;
      }
    }

    final issueView = _buildView(
      movement: issue,
      lots: lookups.lots,
      designs: lookups.designs,
      colours: lookups.colours,
      processes: lookups.processes,
      workers: lookups.workers,
      reversedByMap: reversedByMap,
      colourMovements: colourMovements,
    );

    final children = colourMovements
        .where((m) => m.parentIssueId == issue.id)
        .map(
          (child) => _buildView(
            movement: child,
            lots: lookups.lots,
            designs: lookups.designs,
            colours: lookups.colours,
            processes: lookups.processes,
            workers: lookups.workers,
            reversedByMap: reversedByMap,
            colourMovements: colourMovements,
          ),
        )
        .toList();

    return OpenIssueSummary(issueView: issueView, childSettlements: children);
  }

  @override
  Future<List<StockMovementView>> getMovementHistory({
    StockMovementFilter filter = const StockMovementFilter(),
  }) async {
    final allMovements = (await _db.stockMovementDao.getAllMovements())
        .map(_mapRow)
        .toList();
    final lookups = await _loadLookupMaps();

    final reversedByMap = <String, String>{};
    final movementsByColour = <String, List<StockMovementEntity>>{};
    for (final m in allMovements) {
      if (m.movementType == StockMovementType.reversal &&
          m.reversesMovementId != null) {
        reversedByMap[m.reversesMovementId!] = m.id;
      }
      movementsByColour.putIfAbsent(m.designColourId, () => []).add(m);
    }

    final query = filter.searchQuery?.trim().toLowerCase();
    final views = <StockMovementView>[];

    for (final m in allMovements) {
      if (filter.lotId != null && m.lotId != filter.lotId) continue;
      if (filter.designId != null && m.lotDesignId != filter.designId) continue;
      if (filter.designColourId != null &&
          m.designColourId != filter.designColourId) {
        continue;
      }
      if (filter.memberId != null && m.memberId != filter.memberId) continue;
      if (filter.processId != null && m.processId != filter.processId) continue;
      if (filter.movementType != null &&
          m.movementType != filter.movementType) {
        continue;
      }
      if (filter.fromUtcMillis != null &&
          m.transactionAt < filter.fromUtcMillis!) {
        continue;
      }
      if (filter.toUtcMillis != null && m.transactionAt > filter.toUtcMillis!) {
        continue;
      }
      if (!filter.includeReversed &&
          (reversedByMap.containsKey(m.id) ||
              m.movementType == StockMovementType.reversal)) {
        continue;
      }

      final view = _buildView(
        movement: m,
        lots: lookups.lots,
        designs: lookups.designs,
        colours: lookups.colours,
        processes: lookups.processes,
        workers: lookups.workers,
        reversedByMap: reversedByMap,
        colourMovements: movementsByColour[m.designColourId] ?? const [],
      );

      if (query != null && query.isNotEmpty) {
        final haystack = [
          view.lotNumber,
          view.designName,
          view.colourName,
          view.processName ?? '',
          view.workerName ?? '',
          m.reason ?? '',
          m.notes ?? '',
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) continue;
      }

      views.add(view);
    }

    views.sort((a, b) {
      final txCmp = b.movement.transactionAt.compareTo(
        a.movement.transactionAt,
      );
      if (txCmp != 0) return txCmp;
      return b.movement.recordedAt.compareTo(a.movement.recordedAt);
    });
    return views;
  }

  @override
  Future<List<WorkerStockSummary>> getWorkerStockSummaries() async {
    final allMovements = (await _db.stockMovementDao.getAllMovements())
        .map(_mapRow)
        .toList();
    final workers = await _db.select(_db.members).get();
    final workerNames = {for (final w in workers) w.id: w.name};
    return _stockCalc.calculateWorkerSummaries(
      allMovements: allMovements,
      workerNamesById: workerNames,
    );
  }

  @override
  Future<List<ProcessStockSummary>> getProcessStockSummaries() async {
    final allMovements = (await _db.stockMovementDao.getAllMovements())
        .map(_mapRow)
        .toList();
    final procs = await _db.select(_db.processes).get();
    final procNames = {for (final p in procs) p.id: p.name};
    return _stockCalc.calculateProcessSummaries(
      allMovements: allMovements,
      processNamesById: procNames,
    );
  }

  @override
  Future<RecentIssueSuggestions> getRecentIssueSuggestions() async {
    final allMovements = (await _db.stockMovementDao.getAllMovements())
        .map(_mapRow)
        .toList();
    final procs = await _db.processMemberDao.getNonDeletedProcesses();
    final workers = await _db.processMemberDao.getNonDeletedMembers();
    final links = await _db.select(_db.memberProcesses).get();
    final balances = await getAllDesignColourBalances();

    final activeProcessIds = {
      for (final p in procs)
        if (p.isActive == 1) p.id,
    };
    final activeWorkerIds = {
      for (final w in workers)
        if (w.isActive == 1) w.id,
    };
    final activeLinks = {
      for (final l in links)
        if (l.isActive == 1) '${l.memberId}::${l.processId}',
    };
    final procNames = {for (final p in procs) p.id: p.name};
    final workerNames = {for (final w in workers) w.id: w.name};
    final inStockIds = {
      for (final b in balances)
        if (b.physicalAvailableInHouse > 0) b.designColourId,
    };

    return const WorkshopDailyCalculator().deriveRecentIssueSuggestions(
      allMovements: allMovements,
      activeProcessIds: activeProcessIds,
      activeWorkerIds: activeWorkerIds,
      activeAssignmentKeys: activeLinks,
      processNamesById: procNames,
      workerNamesById: workerNames,
      inStockColourIds: inStockIds,
    );
  }

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
    String? clientRequestId,
  }) async {
    final reqId = clientRequestId?.trim().isEmpty ?? true
        ? _idGenerator.nextRequestId()
        : clientRequestId!.trim();

    return _txRunner
        .runInTransaction(() async {
          // Idempotency guard: return already committed issue on duplicate tap/retry
          final existingByReq = await _db.stockMovementDao
              .findByClientRequestId(reqId);
          if (existingByReq != null) {
            return _mapRow(existingByReq);
          }

          if (quantity <= 0) {
            throw const DomainValidationException(
              'invalid_quantity',
              'Issue quantity must be greater than zero.',
            );
          }

          // Verify design colour -> design -> lot hierarchy
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

          // Atomic 5-point worker-process pre-issue validation
          // 1. Worker exists, non-deleted, active
          final worker = await _db.processMemberDao.findMemberById(workerId);
          if (worker == null ||
              worker.deletedAt != null ||
              worker.isActive != 1) {
            throw const DomainValidationException(
              'worker_inactive',
              'Selected worker is inactive or unavailable.',
            );
          }

          // 2. Process exists, non-deleted, active
          final process = await _db.processMemberDao.findProcessById(processId);
          if (process == null ||
              process.deletedAt != null ||
              process.isActive != 1) {
            throw const DomainValidationException(
              'process_inactive',
              'Selected process is inactive or unavailable.',
            );
          }

          // 3. Active worker-process assignment link exists
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

          // 4. Resolve historical rate by transactionAt (IST date) or validate override
          final rateRows = await _db.processMemberDao.getActiveRates(
            workerId,
            processId,
          );
          final resolution = _rateResolver.resolve(
            workerId: workerId,
            processId: processId,
            transactionAtUtcMillis: transactionAtUtcMillis,
            rates: rateRows.map(_mapRateRow).toList(),
          );

          String? sourceRateId;
          int appliedRatePaise;
          bool isOverridden = false;
          String? cleanedOverrideReason;

          if (allowRateOverride && overrideRatePaise != null) {
            if (overrideRatePaise < 0) {
              throw const DomainValidationException(
                'invalid_rate',
                'Rate cannot be negative.',
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
              case RateResolutionMissing():
                throw const DomainValidationException(
                  'rate_missing',
                  'No effective historical rate configured for this worker and process on the transaction date.',
                );
              case RateResolutionConflict():
                throw const DomainValidationException(
                  'rate_conflict',
                  'Conflicting overlapping rates exist for this worker and process on the transaction date.',
                );
            }
          }

          // 5. Physical available in-house good stock validation
          final existingMovements =
              (await _db.stockMovementDao.getMovementsForDesignColour(
                designColourId,
              )).map(_mapRow).toList();
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

          // Lock effective billing configuration onto ISSUE row (anti-double-counting)
          final profile = await _db.businessProfileDao.getProfile();
          final globalMode = profile != null
              ? BillingMode.fromDbValue(profile.defaultBillingMode)
              : BillingMode.receivedQty;
          final processOverride = process.billingModeOverride != null
              ? BillingMode.fromDbValue(process.billingModeOverride!)
              : null;
          final lockedBillingMode = _labourCalc.resolveEffectiveBillingMode(
            globalDefault: globalMode,
            processOverride: processOverride,
          );
          final lockedIncludeDamaged = process.includeDamagedInLabour == 1;

          final now = IstDateTimeHelper.nowUtcMillis();
          final actor = await _resolveActor();
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
              clientRequestId: Value(reqId),
              movementType: Value(StockMovementType.issue.dbValue),
              quantity: Value(quantity),
              sourceRateId: Value(sourceRateId),
              appliedRatePaise: Value(appliedRatePaise),
              isRateOverridden: Value(isOverridden ? 1 : 0),
              overrideReason: Value(cleanedOverrideReason),
              lockedBillingMode: Value(lockedBillingMode.dbValue),
              lockedIncludeDamaged: Value(lockedIncludeDamaged ? 1 : 0),
              notes: Value(cleanedNotes),
              transactionAt: Value(transactionAtUtcMillis),
              recordedAt: Value(now),
              createdBy: Value(actor),
              updatedBy: Value(actor),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

          // Plan & insert labour entry atomically
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

          // Write audit log
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
          return _mapRow(inserted!);
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
          final parentIssue = _mapRow(parentRow);
          final existingMovements =
              (await _db.stockMovementDao.getMovementsForDesignColour(
                parentIssue.designColourId,
              )).map(_mapRow).toList();

          // Check idempotency across deterministic child request IDs
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
                alreadyCommitted.add(_mapRow(existing));
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

          // Validate batch against remaining pending & reason requirement
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

          final now = IstDateTimeHelper.nowUtcMillis();
          final actor = await _resolveActor();
          final cleanedReason = reason?.trim().isEmpty ?? true
              ? null
              : reason!.trim();
          final cleanedNotes = notes?.trim().isEmpty ?? true
              ? null
              : notes!.trim();
          final lockedMode =
              parentIssue.lockedBillingMode ?? BillingMode.receivedQty;
          final lockedIncludeDamaged = parentIssue.lockedIncludeDamaged;

          final created = <StockMovementEntity>[];
          for (final (type, qty, reqId) in componentSpecs) {
            final movId = _idGenerator.nextEntityId();
            await _db.stockMovementDao.insertMovement(
              StockMovementsCompanion(
                id: Value(movId),
                lotId: Value(parentIssue.lotId),
                lotDesignId: Value(parentIssue.lotDesignId),
                designColourId: Value(parentIssue.designColourId),
                processId: Value(parentIssue.processId),
                memberId: Value(parentIssue.memberId),
                parentIssueId: Value(parentIssue.id),
                clientRequestId: Value(reqId),
                movementType: Value(type.dbValue),
                quantity: Value(qty),
                sourceRateId: Value(parentIssue.sourceRateId),
                appliedRatePaise: Value(parentIssue.appliedRatePaise),
                isRateOverridden: Value(parentIssue.isRateOverridden ? 1 : 0),
                overrideReason: Value(parentIssue.overrideReason),
                lockedBillingMode: Value(lockedMode.dbValue),
                lockedIncludeDamaged: Value(lockedIncludeDamaged ? 1 : 0),
                reason: Value(
                  type.requiresReason ? cleanedReason : cleanedReason,
                ),
                notes: Value(cleanedNotes),
                transactionAt: Value(transactionAtUtcMillis),
                recordedAt: Value(now),
                createdBy: Value(actor),
                updatedBy: Value(actor),
                createdAt: Value(now),
                updatedAt: Value(now),
              ),
            );

            // Plan & insert labour entry inheriting parent locked rate & billing config
            final plannedLabour = _labourCalc.planForSettlement(
              movementType: type,
              quantity: qty,
              lockedRatePaise: parentIssue.appliedRatePaise,
              lockedBillingMode: lockedMode,
              lockedIncludeDamaged: lockedIncludeDamaged,
            );
            if (plannedLabour != null &&
                parentIssue.memberId != null &&
                parentIssue.processId != null) {
              await _db.labourEntryDao.insertEntry(
                LabourEntriesCompanion(
                  id: Value(_idGenerator.nextEntityId()),
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
                  }),
                ),
                reason: Value(cleanedReason),
                transactionAt: Value(transactionAtUtcMillis),
                recordedAt: Value(now),
              ),
            );

            final insertedRow = await _db.stockMovementDao.findById(movId);
            created.add(_mapRow(insertedRow!));
          }

          final updatedMovements =
              (await _db.stockMovementDao.getMovementsForDesignColour(
                parentIssue.designColourId,
              )).map(_mapRow).toList();
          final remaining = _stockCalc.calculateIssueRemainingPending(
            issue: parentIssue,
            allMovementsForColour: updatedMovements,
          );

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
            return _mapRow(existingByReq);
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
              )).map(_mapRow).toList();
          final validationErr = _stockCalc.validateDamagedToGoodAdjustment(
            initialQuantity: colour.initialQuantity,
            existingMovementsForColour: existingMovements,
            quantity: quantity,
            reason: reason,
          );
          if (validationErr != null) {
            throw DomainValidationException(
              validationErr,
              'Invalid damaged-to-good repair adjustment ($validationErr).',
            );
          }

          final now = IstDateTimeHelper.nowUtcMillis();
          final actor = await _resolveActor();
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
          return _mapRow(inserted!);
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
          )).map(_mapRow).toList();

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
      final actor = await _resolveActor();
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

      // Reverse any associated labour entries atomically
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
          _mapLabourRow(labRow),
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
      return _mapRow(inserted!);
    });
  }
}
