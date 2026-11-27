import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/mappers/ledger_row_mappers.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/production_history/data/repositories/production_history_dataset_loader.dart';
import 'package:business_manager/features/production_history/domain/calculators/production_history_calculator.dart';
import 'package:business_manager/features/rates/domain/entities/rate_entities.dart';
import 'package:business_manager/features/rates/domain/services/member_process_rate_resolver.dart';
import 'package:business_manager/features/reports/domain/calculators/workshop_daily_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/calculators/stock_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';

/// Read-only query, stock balance, open issue, and rate-preview delegate for
/// [StockMovementRepositoryImpl].
final class StockMovementQueryDelegate {
  const StockMovementQueryDelegate(
    this._db,
    this._stockCalc,
    this._prodCalc,
    this._rateResolver,
  );

  final AppDatabase _db;
  final StockCalculator _stockCalc;
  final ProductionHistoryCalculator _prodCalc;
  final MemberProcessRateResolver _rateResolver;

  Future<({Map<String, int> pendingByColour, Map<String, int> pendingByIssue})>
  loadPendingInspectionMaps(List<StockMovementEntity> movements) async {
    final reversedIds = _stockCalc.reversedMovementIds(movements);
    final returns = (await _db.productionTrackingDao.getAllReturns())
        .map(ProductionHistoryDatasetLoader.mapReturn)
        .toList();
    final inspections = (await _db.productionTrackingDao.getAllInspections())
        .map(ProductionHistoryDatasetLoader.mapInspection)
        .toList();
    return (
      pendingByColour: _prodCalc.pendingInspectionByDesignColour(
        returns: returns,
        inspections: inspections,
        reversedMovementIds: reversedIds,
      ),
      pendingByIssue: _prodCalc.pendingInspectionByIssue(
        returns: returns,
        inspections: inspections,
        reversedMovementIds: reversedIds,
      ),
    );
  }

  int? _effectiveProcessDefaultPerPiecePaise({
    required int defaultRatePaise,
    required String pricingUnit,
  }) {
    if (defaultRatePaise <= 0) return null;
    return switch (pricingUnit.trim().toUpperCase()) {
      'PER_PIECE' => defaultRatePaise,
      'PER_DOZEN' => (defaultRatePaise / 12).round(),
      _ => null,
    };
  }

  Future<RateResolutionResult> resolveWithProcessFallback({
    required String workerId,
    required String processId,
    required int transactionAtUtcMillis,
    ProcessRow? processRow,
  }) async {
    final rateRows = await _db.processMemberDao.getActiveRates(
      workerId,
      processId,
    );
    final resolved = _rateResolver.resolve(
      workerId: workerId,
      processId: processId,
      transactionAtUtcMillis: transactionAtUtcMillis,
      rates: rateRows.map(LedgerRowMappers.memberProcessRate).toList(),
    );
    if (resolved is RateResolutionMissing) {
      final proc =
          processRow ?? await _db.processMemberDao.findProcessById(processId);
      if (proc != null && proc.deletedAt == null && proc.defaultRatePaise > 0) {
        final effectivePerPiece = _effectiveProcessDefaultPerPiecePaise(
          defaultRatePaise: proc.defaultRatePaise,
          pricingUnit: proc.defaultPricingUnit,
        );
        if (effectivePerPiece != null) {
          return RateResolutionProcessDefault(
            workerId: workerId,
            processId: processId,
            businessDateIst: resolved.businessDateIst,
            ratePaise: effectivePerPiece,
            rawDefaultRatePaise: proc.defaultRatePaise,
            pricingUnit: proc.defaultPricingUnit,
            processName: proc.name,
          );
        }
      }
    }
    return resolved;
  }

  Future<RateResolutionResult> previewRate({
    required String workerId,
    required String processId,
    required int transactionAtUtcMillis,
  }) => resolveWithProcessFallback(
    workerId: workerId,
    processId: processId,
    transactionAtUtcMillis: transactionAtUtcMillis,
  );

  Future<List<StockMovementEntity>> getMovementsForColour(
    String designColourId,
  ) async => (await _db.stockMovementDao.getMovementsForDesignColour(
    designColourId,
  )).map(LedgerRowMappers.stockMovement).toList();

  Future<Map<String, int>> getPendingInspectionByIssue() async {
    final all = (await _db.stockMovementDao.getAllMovements())
        .map(LedgerRowMappers.stockMovement)
        .toList();
    return (await loadPendingInspectionMaps(all)).pendingByIssue;
  }

  Future<List<LabourEntryEntity>> getLabourEntriesForLot(String lotId) async =>
      (await _db.labourEntryDao.getEntriesForLots([lotId]))
          .map(LedgerRowMappers.labourEntry)
          .toList();

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
    )).map(LedgerRowMappers.stockMovement).toList();
    final pendingMaps = await loadPendingInspectionMaps(movements);
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
      pendingInspectionQuantity: pendingMaps.pendingByColour[colour.id] ?? 0,
    );
  }

  Future<List<DesignColourStockBalance>> getAllDesignColourBalances({
    String? lotId,
    bool onlyWithDamaged = false,
  }) async {
    final activeLots = await _db.lotDao.getActiveLots();
    final activeDesigns = await _db.lotDao.getAllActiveDesigns();
    final activeColours = await _db.lotDao.getAllActiveDesignColours();
    final allMovements = (await _db.stockMovementDao.getAllMovements())
        .map(LedgerRowMappers.stockMovement)
        .toList();
    final pendingMaps = await loadPendingInspectionMaps(allMovements);
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
        pendingInspectionQuantity: pendingMaps.pendingByColour[c.id] ?? 0,
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
    Map<String, int> pendingInspectionByIssue = const {},
  }) {
    final isReversed = reversedByMap.containsKey(movement.id);
    int good = 0;
    int damaged = 0;
    int lost = 0;
    int shortage = 0;
    int pendingInsp = 0;
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
      pendingInsp = pendingInspectionByIssue[movement.id] ?? 0;
      pending = (totals.pending - pendingInsp).clamp(0, movement.quantity);
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
      pendingInspectionQty: pendingInsp,
      remainingPendingQty: pending,
    );
  }

  Future<List<OpenIssueSummary>> getOpenIssues({
    String? workerId,
    String? processId,
    String? lotId,
    String? designColourId,
  }) async {
    final allMovements = (await _db.stockMovementDao.getAllMovements())
        .map(LedgerRowMappers.stockMovement)
        .toList();
    final pendingMaps = await loadPendingInspectionMaps(allMovements);
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
        pendingInspectionByIssue: pendingMaps.pendingByIssue,
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
              pendingInspectionByIssue: pendingMaps.pendingByIssue,
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

  Future<OpenIssueSummary?> getIssueDetail(String issueId) async {
    final row = await _db.stockMovementDao.findById(issueId);
    if (row == null) return null;
    final issue = LedgerRowMappers.stockMovement(row);
    if (issue.movementType != StockMovementType.issue) return null;

    final colourMovements =
        (await _db.stockMovementDao.getMovementsForDesignColour(
          issue.designColourId,
        )).map(LedgerRowMappers.stockMovement).toList();
    final pendingMaps = await loadPendingInspectionMaps(colourMovements);
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
      pendingInspectionByIssue: pendingMaps.pendingByIssue,
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
            pendingInspectionByIssue: pendingMaps.pendingByIssue,
          ),
        )
        .toList();

    return OpenIssueSummary(issueView: issueView, childSettlements: children);
  }

  Future<List<StockMovementView>> getMovementHistory({
    StockMovementFilter filter = const StockMovementFilter(),
  }) async {
    final allMovements = (await _db.stockMovementDao.getAllMovements())
        .map(LedgerRowMappers.stockMovement)
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

  Future<List<WorkerStockSummary>> getWorkerStockSummaries() async {
    final allMovements = (await _db.stockMovementDao.getAllMovements())
        .map(LedgerRowMappers.stockMovement)
        .toList();
    final workers = await _db.select(_db.members).get();
    final workerNames = {for (final w in workers) w.id: w.name};
    return _stockCalc.calculateWorkerSummaries(
      allMovements: allMovements,
      workerNamesById: workerNames,
    );
  }

  Future<List<ProcessStockSummary>> getProcessStockSummaries() async {
    final allMovements = (await _db.stockMovementDao.getAllMovements())
        .map(LedgerRowMappers.stockMovement)
        .toList();
    final procs = await _db.select(_db.processes).get();
    final procNames = {for (final p in procs) p.id: p.name};
    return _stockCalc.calculateProcessSummaries(
      allMovements: allMovements,
      processNamesById: procNames,
    );
  }

  Future<RecentIssueSuggestions> getRecentIssueSuggestions() async {
    final allMovements = (await _db.stockMovementDao.getAllMovements())
        .map(LedgerRowMappers.stockMovement)
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
}
