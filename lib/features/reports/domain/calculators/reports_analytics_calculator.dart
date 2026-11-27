import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/domain/calculators/ledger_calculator.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/parties/domain/entities/party_entities.dart';
import 'package:business_manager/features/reports/domain/calculators/reports_analytics_accumulators.dart';
import 'package:business_manager/features/reports/domain/calculators/reports_insights_calculator.dart';
import 'package:business_manager/features/reports/domain/calculators/workshop_daily_calculator.dart';
import 'package:business_manager/features/reports/domain/entities/advanced_report_entities.dart';
import 'package:business_manager/features/reports/domain/entities/dashboard_report_entities.dart';
import 'package:business_manager/features/reports/domain/entities/report_filter.dart';
import 'package:business_manager/features/stock_movements/domain/calculators/stock_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';

export 'reports_analytics_accumulators.dart'
    show
        ReportColourInput,
        ReportDesignInput,
        ReportLotInput,
        ReportProcessInput,
        ReportWorkerInput;

/// Single-pass pure Dart analytics & business-insights calculator for StitchFlow V1.2.
final class ReportsAnalyticsCalculator {
  const ReportsAnalyticsCalculator({
    StockCalculator stockCalculator = const StockCalculator(),
    LedgerCalculator ledgerCalculator = const LedgerCalculator(),
    ReportsInsightsCalculator insightsCalculator =
        const ReportsInsightsCalculator(),
  }) : _stockCalc = stockCalculator,
       _ledgerCalc = ledgerCalculator,
       _insightsCalc = insightsCalculator;

  final StockCalculator _stockCalc;
  final LedgerCalculator _ledgerCalc;
  final ReportsInsightsCalculator _insightsCalc;

  AdvancedReportsBundle compute({
    required ReportFilter filter,
    required String businessNameEn,
    required String businessNameGu,
    required List<ReportLotInput> lots,
    required List<ReportDesignInput> designs,
    required List<ReportColourInput> colours,
    required List<ReportProcessInput> processes,
    required List<ReportWorkerInput> workers,
    required List<StockMovementEntity> allMovements,
    required List<LabourEntryEntity> allLabourEntries,
    required List<PaymentEntity> allPayments,
    required List<WorkerAdjustmentEntity> allAdjustments,
    Map<String, int> pendingInspectionByIssue = const {},
    Map<String, PartyDispatchStockDelta> dispatchDeltasByColour = const {},
    int? nowUtcMillis,
  }) {
    final nowUtc = nowUtcMillis ?? IstDateTimeHelper.nowUtcMillis();
    final query = filter.searchQuery.trim().toLowerCase();

    final lotById = {for (final l in lots) l.id: l};
    final designById = {for (final d in designs) d.id: d};
    final colourById = {for (final c in colours) c.id: c};
    final processById = {for (final p in processes) p.id: p};
    final workerById = {for (final w in workers) w.id: w};
    final processNamesById = {for (final p in processes) p.id: p.name};

    final filterOptions = ReportFilterOptions(
      workers:
          workers
              .map(
                (w) => ReportFilterOption(
                  id: w.id,
                  label: w.name,
                  isActive: w.isActive,
                ),
              )
              .toList()
            ..sort((a, b) => a.label.compareTo(b.label)),
      processes:
          processes
              .map(
                (p) => ReportFilterOption(
                  id: p.id,
                  label: p.name,
                  isActive: p.isActive,
                ),
              )
              .toList()
            ..sort((a, b) => a.label.compareTo(b.label)),
      lots:
          lots
              .map(
                (l) => ReportFilterOption(
                  id: l.id,
                  label: l.title != null && l.title!.isNotEmpty
                      ? '${l.lotNumber} • ${l.title}'
                      : l.lotNumber,
                ),
              )
              .toList()
            ..sort((a, b) => a.label.compareTo(b.label)),
      designs:
          designs
              .map(
                (d) => ReportFilterOption(
                  id: d.id,
                  label: d.designName,
                  parentId: d.lotId,
                ),
              )
              .toList()
            ..sort((a, b) => a.label.compareTo(b.label)),
      colours:
          colours
              .map(
                (c) => ReportFilterOption(
                  id: c.id,
                  label: c.colourName,
                  parentId: c.lotDesignId,
                ),
              )
              .toList()
            ..sort((a, b) => a.label.compareTo(b.label)),
    );

    final revMovementIds = _stockCalc.reversedMovementIds(allMovements);
    final revLabourIds = _ledgerCalc.reversedLabourIds(allLabourEntries);
    final revPaymentIds = _ledgerCalc.reversedPaymentIds(allPayments);

    final movementsByColour = <String, List<StockMovementEntity>>{};
    final issueSettlementMap = <String, IssueSettlementAcc>{};
    final activeMovements = <StockMovementEntity>[];

    for (final m in allMovements) {
      movementsByColour.putIfAbsent(m.designColourId, () => []).add(m);
      if (m.movementType == StockMovementType.reversal ||
          revMovementIds.contains(m.id)) {
        continue;
      }
      activeMovements.add(m);
      if (m.parentIssueId != null && m.movementType.isSettlement) {
        final acc = issueSettlementMap.putIfAbsent(
          m.parentIssueId!,
          () => IssueSettlementAcc(),
        );
        switch (m.movementType) {
          case StockMovementType.returnGood:
            acc.good += m.quantity;
          case StockMovementType.returnDamaged:
            acc.damaged += m.quantity;
          case StockMovementType.settlementLost:
            acc.lost += m.quantity;
          case StockMovementType.settlementShortage:
            acc.shortage += m.quantity;
          case StockMovementType.issue:
          case StockMovementType.adjustmentDamagedToGood:
          case StockMovementType.reversal:
            break;
        }
        if (m.transactionAt > acc.maxSettlementTxAt) {
          acc.maxSettlementTxAt = m.transactionAt;
        }
      }
    }

    bool matchesStockDimensions(StockMovementEntity m) {
      if (filter.workerId != null && m.memberId != filter.workerId) {
        return false;
      }
      if (filter.processId != null && m.processId != filter.processId) {
        return false;
      }
      if (filter.lotId != null && m.lotId != filter.lotId) return false;
      if (filter.lotDesignId != null && m.lotDesignId != filter.lotDesignId) {
        return false;
      }
      if (filter.designColourId != null &&
          m.designColourId != filter.designColourId) {
        return false;
      }
      if (query.isNotEmpty) {
        final lotNum = lotById[m.lotId]?.lotNumber.toLowerCase() ?? '';
        final designName =
            designById[m.lotDesignId]?.designName.toLowerCase() ?? '';
        final colourName =
            colourById[m.designColourId]?.colourName.toLowerCase() ?? '';
        final workerName =
            (m.memberId != null ? workerById[m.memberId!]?.name : null)
                ?.toLowerCase() ??
            '';
        final procName =
            (m.processId != null ? processById[m.processId!]?.name : null)
                ?.toLowerCase() ??
            '';
        final reason = m.reason?.toLowerCase() ?? '';
        if (!lotNum.contains(query) &&
            !designName.contains(query) &&
            !colourName.contains(query) &&
            !workerName.contains(query) &&
            !procName.contains(query) &&
            !reason.contains(query)) {
          return false;
        }
      }
      return true;
    }

    bool matchesLabourDimensions(LabourEntryEntity e) {
      if (filter.workerId != null && e.memberId != filter.workerId) {
        return false;
      }
      if (filter.processId != null && e.processId != filter.processId) {
        return false;
      }
      if (filter.lotId != null && e.lotId != filter.lotId) return false;
      if (query.isNotEmpty) {
        final lotNum = lotById[e.lotId]?.lotNumber.toLowerCase() ?? '';
        final workerName = workerById[e.memberId]?.name.toLowerCase() ?? '';
        final procName = processById[e.processId]?.name.toLowerCase() ?? '';
        if (!lotNum.contains(query) &&
            !workerName.contains(query) &&
            !procName.contains(query)) {
          return false;
        }
      }
      return true;
    }

    bool matchesPaymentDimensions(PaymentEntity p) {
      if (filter.workerId != null && p.memberId != filter.workerId) {
        return false;
      }
      if (filter.paymentMode != null && p.paymentMode != filter.paymentMode) {
        return false;
      }
      if (filter.paymentType != null && p.paymentType != filter.paymentType) {
        return false;
      }
      if (query.isNotEmpty) {
        final workerName = workerById[p.memberId]?.name.toLowerCase() ?? '';
        final ref = p.referenceNo?.toLowerCase() ?? '';
        final notes = p.notes?.toLowerCase() ?? '';
        if (!workerName.contains(query) &&
            !ref.contains(query) &&
            !notes.contains(query)) {
          return false;
        }
      }
      return true;
    }

    final pendingInspectionByColour = <String, int>{};
    for (final m in allMovements) {
      if (m.movementType != StockMovementType.issue) continue;
      final q = pendingInspectionByIssue[m.id] ?? 0;
      if (q <= 0 || revMovementIds.contains(m.id)) continue;
      pendingInspectionByColour[m.designColourId] =
          (pendingInspectionByColour[m.designColourId] ?? 0) + q;
    }

    final colourBalances = <DesignColourStockBalance>[];
    for (final c in colours) {
      if (!lotById.containsKey(c.lotId)) continue;
      if (filter.lotId != null && c.lotId != filter.lotId) continue;
      if (filter.lotDesignId != null && c.lotDesignId != filter.lotDesignId) {
        continue;
      }
      if (filter.designColourId != null && c.id != filter.designColourId) {
        continue;
      }
      final lot = lotById[c.lotId]!;
      final design = designById[c.lotDesignId];
      if (query.isNotEmpty) {
        final matchesText =
            lot.lotNumber.toLowerCase().contains(query) ||
            (lot.title?.toLowerCase().contains(query) ?? false) ||
            (design?.designName.toLowerCase().contains(query) ?? false) ||
            c.colourName.toLowerCase().contains(query);
        if (!matchesText) continue;
      }

      final delta = dispatchDeltasByColour[c.id];
      colourBalances.add(
        _stockCalc.calculateDesignColourBalance(
          designColourId: c.id,
          lotId: c.lotId,
          lotNumber: lot.lotNumber,
          lotDesignId: c.lotDesignId,
          designName: design?.designName ?? c.lotDesignId,
          colourName: c.colourName,
          colourHex: c.colourHex,
          unitPricePaise: c.unitPricePaise,
          initialQuantity: c.initialQuantity,
          allMovementsForColour: movementsByColour[c.id] ?? const [],
          processNamesById: processNamesById,
          pendingInspectionQuantity: pendingInspectionByColour[c.id] ?? 0,
          dispatchedOutQty: delta?.dispatchedOutQty ?? 0,
          buyerReturnedGoodQty: delta?.buyerReturnedGoodQty ?? 0,
          buyerReturnedDamagedQty: delta?.buyerReturnedDamagedQty ?? 0,
        ),
      );
    }

    final coloursByLot = <String, List<DesignColourStockBalance>>{};
    var totalInitialStock = 0;
    var totalAvailableGood = 0;
    var totalPendingWithWorkers = 0;
    var totalPendingInspection = 0;
    var totalDamagedBucket = 0;
    var totalLostStock = 0;
    var totalShortageStock = 0;
    var totalReferenceValuePaise = 0;

    for (final b in colourBalances) {
      coloursByLot.putIfAbsent(b.lotId, () => []).add(b);
      totalInitialStock += b.initialQuantity;
      totalAvailableGood += b.physicalAvailableInHouse;
      totalPendingWithWorkers += b.totalPendingWithWorkers;
      totalPendingInspection += b.totalPendingInspection;
      totalDamagedBucket += b.damagedBucket;
      totalLostStock += b.totalLost;
      totalShortageStock += b.totalShortage;
      totalReferenceValuePaise += b.totalGoodPhysicalStock * b.unitPricePaise;
    }

    final lotRows = <LotStockReportRow>[];
    for (final lot in lots) {
      if (filter.lotId != null && lot.id != filter.lotId) continue;
      final cols = coloursByLot[lot.id] ?? const [];
      if (query.isNotEmpty &&
          !lot.lotNumber.toLowerCase().contains(query) &&
          !(lot.title?.toLowerCase().contains(query) ?? false) &&
          cols.isEmpty) {
        continue;
      }
      if ((filter.lotDesignId != null || filter.designColourId != null) &&
          cols.isEmpty) {
        continue;
      }
      final designIds = {for (final c in cols) c.lotDesignId};
      var initQ = 0;
      var avail = 0;
      var pend = 0;
      var pendInsp = 0;
      var dmg = 0;
      var lost = 0;
      var shrt = 0;
      var refVal = 0;
      for (final c in cols) {
        initQ += c.initialQuantity;
        avail += c.physicalAvailableInHouse;
        pend += c.totalPendingWithWorkers;
        pendInsp += c.totalPendingInspection;
        dmg += c.damagedBucket;
        lost += c.totalLost;
        shrt += c.totalShortage;
        refVal += c.totalGoodPhysicalStock * c.unitPricePaise;
      }
      lotRows.add(
        LotStockReportRow(
          lotId: lot.id,
          lotNumber: lot.lotNumber,
          title: lot.title,
          status: lot.status,
          designCount: designIds.length,
          colourCount: cols.length,
          initialQuantity: initQ,
          availableGoodStock: avail,
          pendingWithWorkers: pend,
          damagedBucket: dmg,
          lostQuantity: lost,
          shortageQuantity: shrt,
          goodStockValuePaise: refVal,
          pendingInspection: pendInsp,
        ),
      );
    }

    final openIssues = <OpenIssueSummary>[];
    final currentPendingByWorker = <String, int>{};
    final currentOpenCountByWorker = <String, int>{};
    final currentPendingByProcess = <String, int>{};
    final currentOpenCountByProcess = <String, int>{};
    final oldestOpenAgeByProcess = <String, int>{};
    final turnaroundHoursByProcess = <String, List<double>>{};

    StockMovementView toMovementView(
      StockMovementEntity m, {
      int remainingPendingQty = 0,
    }) {
      final lot = lotById[m.lotId];
      final design = designById[m.lotDesignId];
      final colour = colourById[m.designColourId];
      return StockMovementView(
        movement: m,
        lotNumber: lot?.lotNumber ?? m.lotId,
        designName: design?.designName ?? m.lotDesignId,
        colourName: colour?.colourName ?? m.designColourId,
        processName: m.processId != null
            ? processById[m.processId!]?.name
            : null,
        workerName: m.memberId != null ? workerById[m.memberId!]?.name : null,
        isReversed: revMovementIds.contains(m.id),
        remainingPendingQty: remainingPendingQty,
      );
    }

    for (final m in activeMovements) {
      if (m.movementType != StockMovementType.issue) continue;
      if (!matchesStockDimensions(m)) continue;

      final acc = issueSettlementMap[m.id];
      final good = acc?.good ?? 0;
      final damaged = acc?.damaged ?? 0;
      final lost = acc?.lost ?? 0;
      final shortage = acc?.shortage ?? 0;
      final remaining = m.quantity - (good + damaged + lost + shortage);
      final withWorker = (remaining - (pendingInspectionByIssue[m.id] ?? 0))
          .clamp(0, remaining);

      if (withWorker > 0) {
        final ageDays = WorkshopDailyCalculator.pendingAgeDays(
          m.transactionAt,
          nowUtc,
        );
        openIssues.add(
          OpenIssueSummary(
            issueView: toMovementView(m, remainingPendingQty: withWorker),
            childSettlements: const [],
          ),
        );
        if (m.memberId != null) {
          currentPendingByWorker[m.memberId!] =
              (currentPendingByWorker[m.memberId!] ?? 0) + withWorker;
          currentOpenCountByWorker[m.memberId!] =
              (currentOpenCountByWorker[m.memberId!] ?? 0) + 1;
        }
        if (m.processId != null) {
          currentPendingByProcess[m.processId!] =
              (currentPendingByProcess[m.processId!] ?? 0) + withWorker;
          currentOpenCountByProcess[m.processId!] =
              (currentOpenCountByProcess[m.processId!] ?? 0) + 1;
          final prevOldest = oldestOpenAgeByProcess[m.processId!];
          if (prevOldest == null || ageDays > prevOldest) {
            oldestOpenAgeByProcess[m.processId!] = ageDays;
          }
        }
      } else if (remaining == 0 && acc != null && acc.maxSettlementTxAt > 0) {
        if (m.processId != null &&
            filter.matchesTimestamp(acc.maxSettlementTxAt) &&
            acc.maxSettlementTxAt >= m.transactionAt) {
          final hours = (acc.maxSettlementTxAt - m.transactionAt) / 3600000.0;
          turnaroundHoursByProcess
              .putIfAbsent(m.processId!, () => [])
              .add(hours);
        }
      }
    }

    openIssues.sort(
      (a, b) => a.issueView.movement.transactionAt.compareTo(
        b.issueView.movement.transactionAt,
      ),
    );

    final labourByWorker = <String, List<LabourEntryEntity>>{};
    final paymentsByWorker = <String, List<PaymentEntity>>{};
    final adjustmentsByWorker = <String, List<WorkerAdjustmentEntity>>{};
    for (final e in allLabourEntries) {
      labourByWorker.putIfAbsent(e.memberId, () => []).add(e);
    }
    for (final p in allPayments) {
      paymentsByWorker.putIfAbsent(p.memberId, () => []).add(p);
    }
    for (final a in allAdjustments) {
      adjustmentsByWorker.putIfAbsent(a.memberId, () => []).add(a);
    }

    final workerFinancialById = <String, WorkerFinancialSummary>{};
    final filteredWorkerFinancials = <WorkerFinancialSummary>[];
    for (final w in workers) {
      final summary = _ledgerCalc.calculateWorkerSummary(
        workerId: w.id,
        workerName: w.name,
        workerPhone: w.phone,
        workerIsActive: w.isActive,
        labourEntries: labourByWorker[w.id] ?? const [],
        payments: paymentsByWorker[w.id] ?? const [],
        adjustments: adjustmentsByWorker[w.id] ?? const [],
      );
      workerFinancialById[w.id] = summary;
      if (filter.workerId != null && w.id != filter.workerId) continue;
      if (query.isNotEmpty && !w.name.toLowerCase().contains(query)) continue;
      filteredWorkerFinancials.add(summary);
    }
    filteredWorkerFinancials.sort(
      (a, b) => b.outstandingPayablePaise.compareTo(a.outstandingPayablePaise),
    );

    final dailyAcc = <String, DailyAcc>{};
    final workerPeriodAcc = <String, WorkerPeriodAcc>{};
    final processPeriodAcc = <String, ProcessPeriodAcc>{};
    final defectReasonAcc = <String, ReasonAcc>{};
    final movementHistory = <StockMovementView>[];
    final damagedLostMovements = <StockMovementView>[];

    var totalPeriodGood = 0;
    var totalPeriodDamaged = 0;
    var totalPeriodLostShortage = 0;

    for (final m in allMovements) {
      if (!filter.matchesTimestamp(m.transactionAt)) continue;
      if (!matchesStockDimensions(m)) continue;
      final isReversedOrReversal =
          m.movementType == StockMovementType.reversal ||
          revMovementIds.contains(m.id);
      if (filter.includeReversedInHistory || !isReversedOrReversal) {
        final view = toMovementView(m);
        movementHistory.add(view);
        if (!isReversedOrReversal &&
            (m.movementType == StockMovementType.returnDamaged ||
                m.movementType == StockMovementType.settlementLost ||
                m.movementType == StockMovementType.settlementShortage ||
                m.movementType == StockMovementType.adjustmentDamagedToGood)) {
          damagedLostMovements.add(view);
        }
      }
    }
    movementHistory.sort((a, b) {
      final tx = b.movement.transactionAt.compareTo(a.movement.transactionAt);
      if (tx != 0) return tx;
      return b.movement.recordedAt.compareTo(a.movement.recordedAt);
    });
    damagedLostMovements.sort((a, b) {
      final tx = b.movement.transactionAt.compareTo(a.movement.transactionAt);
      if (tx != 0) return tx;
      return b.movement.recordedAt.compareTo(a.movement.recordedAt);
    });

    for (final m in activeMovements) {
      if (!filter.matchesTimestamp(m.transactionAt)) continue;
      if (!matchesStockDimensions(m)) continue;

      final dayIso = IstDateTimeHelper.toIstBusinessDate(m.transactionAt);
      final dayStart = IstDateRangePresets.startOfIstDay(m.transactionAt);
      final dAcc = dailyAcc.putIfAbsent(dayIso, () => DailyAcc(dayStart));

      final wAcc = m.memberId != null
          ? workerPeriodAcc.putIfAbsent(m.memberId!, () => WorkerPeriodAcc())
          : null;
      final wpAcc = (wAcc != null && m.processId != null)
          ? wAcc.byProcess.putIfAbsent(m.processId!, () => WorkerProcessAcc())
          : null;
      final pAcc = m.processId != null
          ? processPeriodAcc.putIfAbsent(
              m.processId!,
              () => ProcessPeriodAcc(),
            )
          : null;
      final pwAcc = (pAcc != null && m.memberId != null)
          ? pAcc.byWorker.putIfAbsent(m.memberId!, () => ProcessWorkerAcc())
          : null;

      switch (m.movementType) {
        case StockMovementType.issue:
          dAcc.issued += m.quantity;
          if (wAcc != null) wAcc.issued += m.quantity;
          if (wpAcc != null) wpAcc.issued += m.quantity;
          if (pAcc != null) pAcc.issued += m.quantity;
          if (pwAcc != null) pwAcc.issued += m.quantity;
        case StockMovementType.returnGood:
          dAcc.good += m.quantity;
          totalPeriodGood += m.quantity;
          if (wAcc != null) wAcc.good += m.quantity;
          if (wpAcc != null) wpAcc.good += m.quantity;
          if (pAcc != null) pAcc.good += m.quantity;
          if (pwAcc != null) pwAcc.good += m.quantity;
        case StockMovementType.returnDamaged:
          dAcc.damaged += m.quantity;
          totalPeriodDamaged += m.quantity;
          if (wAcc != null) wAcc.damaged += m.quantity;
          if (wpAcc != null) wpAcc.damaged += m.quantity;
          if (pAcc != null) pAcc.damaged += m.quantity;
          _recordReason(defectReasonAcc, m.reason, m.quantity);
        case StockMovementType.settlementLost:
          dAcc.lost += m.quantity;
          totalPeriodLostShortage += m.quantity;
          if (wAcc != null) wAcc.lostShortage += m.quantity;
          if (wpAcc != null) wpAcc.lostShortage += m.quantity;
          if (pAcc != null) pAcc.lostShortage += m.quantity;
          _recordReason(defectReasonAcc, m.reason, m.quantity);
        case StockMovementType.settlementShortage:
          dAcc.shortage += m.quantity;
          totalPeriodLostShortage += m.quantity;
          if (wAcc != null) wAcc.lostShortage += m.quantity;
          if (wpAcc != null) wpAcc.lostShortage += m.quantity;
          if (pAcc != null) pAcc.lostShortage += m.quantity;
          _recordReason(defectReasonAcc, m.reason, m.quantity);
        case StockMovementType.adjustmentDamagedToGood:
          dAcc.repaired += m.quantity;
        case StockMovementType.reversal:
          break;
      }
    }

    final periodLabourViews = <LabourEntryView>[];
    var periodTotalLabourPaise = 0;
    for (final e in allLabourEntries) {
      if (e.basisType == LabourBasisType.reversal ||
          revLabourIds.contains(e.id)) {
        continue;
      }
      if (!e.isPayable) continue;
      if (!filter.matchesTimestamp(e.transactionAt)) continue;
      if (!matchesLabourDimensions(e)) continue;

      periodTotalLabourPaise += e.amountPaise;

      final dayIso = IstDateTimeHelper.toIstBusinessDate(e.transactionAt);
      final dayStart = IstDateRangePresets.startOfIstDay(e.transactionAt);
      dailyAcc.putIfAbsent(dayIso, () => DailyAcc(dayStart)).labourPaise +=
          e.amountPaise;

      final wAcc = workerPeriodAcc.putIfAbsent(
        e.memberId,
        () => WorkerPeriodAcc(),
      );
      wAcc.labourPaise += e.amountPaise;
      wAcc.byProcess
              .putIfAbsent(e.processId, () => WorkerProcessAcc())
              .labourPaise +=
          e.amountPaise;

      processPeriodAcc
              .putIfAbsent(e.processId, () => ProcessPeriodAcc())
              .labourPaise +=
          e.amountPaise;

      periodLabourViews.add(
        LabourEntryView(
          entry: e,
          workerName: workerById[e.memberId]?.name ?? e.memberId,
          processName: processById[e.processId]?.name ?? e.processId,
          lotNumber: lotById[e.lotId]?.lotNumber ?? e.lotId,
          isReversed: false,
        ),
      );
    }
    periodLabourViews.sort((a, b) {
      final tx = b.entry.transactionAt.compareTo(a.entry.transactionAt);
      if (tx != 0) return tx;
      return b.entry.recordedAt.compareTo(a.entry.recordedAt);
    });

    final periodPaymentViews = <PaymentView>[];
    var periodRegularPayPaise = 0;
    var periodAdvancePayPaise = 0;
    var periodAdvanceRefPaise = 0;
    for (final p in allPayments) {
      if (p.paymentType == PaymentType.reversal ||
          revPaymentIds.contains(p.id)) {
        continue;
      }
      if (!filter.matchesTimestamp(p.transactionAt)) continue;
      if (!matchesPaymentDimensions(p)) continue;

      final dayIso = IstDateTimeHelper.toIstBusinessDate(p.transactionAt);
      final dayStart = IstDateRangePresets.startOfIstDay(p.transactionAt);
      final dAcc = dailyAcc.putIfAbsent(dayIso, () => DailyAcc(dayStart));
      final wAcc = workerPeriodAcc.putIfAbsent(
        p.memberId,
        () => WorkerPeriodAcc(),
      );

      switch (p.paymentType) {
        case PaymentType.regular:
          periodRegularPayPaise += p.amountPaise;
          dAcc.regularPayPaise += p.amountPaise;
          wAcc.regularPayPaise += p.amountPaise;
        case PaymentType.advance:
          periodAdvancePayPaise += p.amountPaise;
          dAcc.advancePayPaise += p.amountPaise;
          wAcc.advancePayPaise += p.amountPaise;
        case PaymentType.advanceRefund:
          periodAdvanceRefPaise += p.amountPaise;
          dAcc.advanceRefPaise += p.amountPaise;
          wAcc.advanceRefPaise += p.amountPaise;
        case PaymentType.reversal:
          break;
      }

      periodPaymentViews.add(
        PaymentView(
          payment: p,
          workerName: workerById[p.memberId]?.name ?? p.memberId,
          isReversed: false,
        ),
      );
    }
    periodPaymentViews.sort((a, b) {
      final tx = b.payment.transactionAt.compareTo(a.payment.transactionAt);
      if (tx != 0) return tx;
      return b.payment.recordedAt.compareTo(a.payment.recordedAt);
    });
    final periodNetPaymentsPaise =
        periodRegularPayPaise + periodAdvancePayPaise - periodAdvanceRefPaise;

    final dailyRows = dailyAcc.entries.map((entry) {
      final a = entry.value;
      return DailyReportRow(
        istDateIso: entry.key,
        dayStartUtcMillis: a.dayStartUtcMillis,
        issuedQty: a.issued,
        goodReturnedQty: a.good,
        damagedQty: a.damaged,
        lostQty: a.lost,
        shortageQty: a.shortage,
        repairedQty: a.repaired,
        labourEarnedPaise: a.labourPaise,
        regularPaymentsPaise: a.regularPayPaise,
        advancePaymentsPaise: a.advancePayPaise,
        advanceRefundsPaise: a.advanceRefPaise,
        netPaymentsPaise:
            a.regularPayPaise + a.advancePayPaise - a.advanceRefPaise,
      );
    }).toList()..sort((a, b) => b.istDateIso.compareTo(a.istDateIso));

    final dailyTotalIssued = dailyRows.fold<int>(0, (s, r) => s + r.issuedQty);
    final dailyTotalGood = dailyRows.fold<int>(
      0,
      (s, r) => s + r.goodReturnedQty,
    );
    final dailyTotalDamaged = dailyRows.fold<int>(
      0,
      (s, r) => s + r.damagedQty,
    );
    final dailyTotalLostShortage = dailyRows.fold<int>(
      0,
      (s, r) => s + r.lostAndShortageQty,
    );

    final workerIdsToInclude = <String>{
      ...workerPeriodAcc.keys,
      ...currentPendingByWorker.keys,
      for (final wf in filteredWorkerFinancials)
        if (wf.outstandingPayablePaise > 0 ||
            wf.advanceCreditBalancePaise > 0 ||
            wf.workerIsActive)
          wf.workerId,
    };

    final workerPerfRows = <WorkerPerformanceRow>[];
    for (final wId in workerIdsToInclude) {
      if (filter.workerId != null && wId != filter.workerId) continue;
      final w = workerById[wId];
      final wName = w?.name ?? wId;
      if (query.isNotEmpty && !wName.toLowerCase().contains(query)) continue;

      final pAcc = workerPeriodAcc[wId];
      final fin = workerFinancialById[wId];
      final pendingQty = currentPendingByWorker[wId] ?? 0;
      final openCount = currentOpenCountByWorker[wId] ?? 0;

      final issued = pAcc?.issued ?? 0;
      final good = pAcc?.good ?? 0;
      final damaged = pAcc?.damaged ?? 0;
      final lostShortage = pAcc?.lostShortage ?? 0;
      final labour = pAcc?.labourPaise ?? 0;
      final regPay = pAcc?.regularPayPaise ?? 0;
      final advPay = pAcc?.advancePayPaise ?? 0;
      final advRef = pAcc?.advanceRefPaise ?? 0;
      final netPay = regPay + advPay - advRef;
      final outstanding = fin?.outstandingPayablePaise ?? 0;
      final advCredit = fin?.advanceCreditBalancePaise ?? 0;

      if (issued == 0 &&
          good == 0 &&
          damaged == 0 &&
          lostShortage == 0 &&
          labour == 0 &&
          regPay == 0 &&
          advPay == 0 &&
          advRef == 0 &&
          pendingQty == 0 &&
          outstanding == 0 &&
          advCredit == 0) {
        continue;
      }

      final breakdowns = <WorkerProcessBreakdownItem>[];
      if (pAcc != null) {
        for (final pe in pAcc.byProcess.entries) {
          final pa = pe.value;
          breakdowns.add(
            WorkerProcessBreakdownItem(
              processId: pe.key,
              processName: processNamesById[pe.key] ?? pe.key,
              issuedQty: pa.issued,
              goodReturnedQty: pa.good,
              damagedQty: pa.damaged,
              lostShortageQty: pa.lostShortage,
              labourEarnedPaise: pa.labourPaise,
              defectRatePercent: computeReportDefectRate(
                good: pa.good,
                damaged: pa.damaged,
                lostShortage: pa.lostShortage,
              ),
            ),
          );
        }
        breakdowns.sort(
          (a, b) => b.goodReturnedQty.compareTo(a.goodReturnedQty),
        );
      }

      workerPerfRows.add(
        WorkerPerformanceRow(
          workerId: wId,
          workerName: wName,
          workerIsActive: w?.isActive ?? true,
          periodIssuedQty: issued,
          periodGoodReturnedQty: good,
          periodDamagedQty: damaged,
          periodLostShortageQty: lostShortage,
          periodLabourEarnedPaise: labour,
          periodRegularPaymentsPaise: regPay,
          periodAdvancePaymentsPaise: advPay,
          periodAdvanceRefundsPaise: advRef,
          periodNetPaymentsPaise: netPay,
          currentPendingQty: pendingQty,
          currentOpenIssuesCount: openCount,
          currentOutstandingPayablePaise: outstanding,
          currentAdvanceCreditPaise: advCredit,
          defectRatePercent: computeReportDefectRate(
            good: good,
            damaged: damaged,
            lostShortage: lostShortage,
          ),
          processBreakdown: breakdowns,
        ),
      );
    }
    workerPerfRows.sort((a, b) {
      final goodCmp = b.periodGoodReturnedQty.compareTo(
        a.periodGoodReturnedQty,
      );
      if (goodCmp != 0) return goodCmp;
      final pendCmp = b.currentPendingQty.compareTo(a.currentPendingQty);
      if (pendCmp != 0) return pendCmp;
      return b.currentOutstandingPayablePaise.compareTo(
        a.currentOutstandingPayablePaise,
      );
    });

    final processIdsToInclude = <String>{
      ...processPeriodAcc.keys,
      ...currentPendingByProcess.keys,
      ...turnaroundHoursByProcess.keys,
      for (final p in processes)
        if (p.isActive) p.id,
    };

    final processPerfRows = <ProcessPerformanceRow>[];
    for (final pId in processIdsToInclude) {
      if (filter.processId != null && pId != filter.processId) continue;
      final pName = processNamesById[pId] ?? pId;
      if (query.isNotEmpty && !pName.toLowerCase().contains(query)) continue;

      final pAcc = processPeriodAcc[pId];
      final pendingQty = currentPendingByProcess[pId] ?? 0;
      final openCount = currentOpenCountByProcess[pId] ?? 0;
      final oldestAge = oldestOpenAgeByProcess[pId];
      final turnSamples = turnaroundHoursByProcess[pId] ?? const <double>[];
      final avgTurnaround = turnSamples.isEmpty
          ? null
          : turnSamples.reduce((a, b) => a + b) / turnSamples.length;

      final issued = pAcc?.issued ?? 0;
      final good = pAcc?.good ?? 0;
      final damaged = pAcc?.damaged ?? 0;
      final lostShortage = pAcc?.lostShortage ?? 0;
      final labourCost = pAcc?.labourPaise ?? 0;

      if (issued == 0 &&
          good == 0 &&
          damaged == 0 &&
          lostShortage == 0 &&
          labourCost == 0 &&
          pendingQty == 0 &&
          turnSamples.isEmpty) {
        continue;
      }

      final contributions = <ProcessWorkerContribution>[];
      if (pAcc != null) {
        final denom = good > 0 ? good : issued;
        for (final we in pAcc.byWorker.entries) {
          final wa = we.value;
          final numVal = good > 0 ? wa.good : wa.issued;
          contributions.add(
            ProcessWorkerContribution(
              workerId: we.key,
              workerName: workerById[we.key]?.name ?? we.key,
              issuedQty: wa.issued,
              goodReturnedQty: wa.good,
              sharePercent: denom > 0 ? (numVal * 100.0) / denom : null,
            ),
          );
        }
        contributions.sort(
          (a, b) => b.goodReturnedQty.compareTo(a.goodReturnedQty),
        );
      }

      processPerfRows.add(
        ProcessPerformanceRow(
          processId: pId,
          processName: pName,
          periodIssuedQty: issued,
          periodGoodReturnedQty: good,
          periodDamagedQty: damaged,
          periodLostShortageQty: lostShortage,
          periodLabourCostPaise: labourCost,
          currentPendingQty: pendingQty,
          currentOpenIssuesCount: openCount,
          oldestOpenIssueAgeDays: oldestAge,
          averageTurnaroundHours: avgTurnaround,
          settledIssuesCount: turnSamples.length,
          defectRatePercent: computeReportDefectRate(
            good: good,
            damaged: damaged,
            lostShortage: lostShortage,
          ),
          workerContributions: contributions,
        ),
      );
    }
    processPerfRows.sort((a, b) {
      final pendCmp = b.currentPendingQty.compareTo(a.currentPendingQty);
      if (pendCmp != 0) return pendCmp;
      return b.periodGoodReturnedQty.compareTo(a.periodGoodReturnedQty);
    });

    final inventorySection = InventoryReportSection(
      initialStock: totalInitialStock,
      availableGoodStock: totalAvailableGood,
      pendingWithWorkers: totalPendingWithWorkers,
      damagedBucket: totalDamagedBucket,
      lostStock: totalLostStock,
      shortageStock: totalShortageStock,
      referenceGoodStockValuePaise: totalReferenceValuePaise,
      lotRows: lotRows,
      colourBalances: colourBalances,
      openIssues: openIssues,
      pendingInspection: totalPendingInspection,
      movementHistory: movementHistory,
      damagedLostShortageMovements: damagedLostMovements,
    );

    final totalOutstandingPayable = filteredWorkerFinancials.fold<int>(
      0,
      (s, w) => s + w.outstandingPayablePaise,
    );
    final totalAdvanceCredit = filteredWorkerFinancials.fold<int>(
      0,
      (s, w) => s + w.advanceCreditBalancePaise,
    );

    final financialSection = FinancialReportSection(
      periodEarnedLabourPaise: periodTotalLabourPaise,
      periodRegularPaymentsPaise: periodRegularPayPaise,
      periodAdvancePaymentsPaise: periodAdvancePayPaise,
      periodAdvanceRefundsPaise: periodAdvanceRefPaise,
      periodNetPaymentsPaise: periodNetPaymentsPaise,
      totalCurrentOutstandingPayablePaise: totalOutstandingPayable,
      totalCurrentAdvanceCreditPaise: totalAdvanceCredit,
      labourEntries: periodLabourViews,
      workerSummaries: filteredWorkerFinancials,
      payments: periodPaymentViews,
    );

    final insights = _insightsCalc.buildInsights(
      filter: filter,
      dailyRows: dailyRows,
      workerPerfRows: workerPerfRows,
      processPerfRows: processPerfRows,
      activeMovements: activeMovements,
      allLabourEntries: allLabourEntries,
      revLabourIds: revLabourIds,
      defectReasonAcc: defectReasonAcc,
      totalPeriodGood: totalPeriodGood,
      totalPeriodDamaged: totalPeriodDamaged,
      totalPeriodLostShortage: totalPeriodLostShortage,
      dailyTotalIssued: dailyTotalIssued,
      dailyTotalGood: dailyTotalGood,
      periodTotalLabourPaise: periodTotalLabourPaise,
      matchesStockDimensions: matchesStockDimensions,
      matchesLabourDimensions: matchesLabourDimensions,
    );

    return AdvancedReportsBundle(
      filter: filter,
      filterOptions: filterOptions,
      businessNameEn: businessNameEn,
      businessNameGu: businessNameGu,
      generatedAtUtcMillis: nowUtc,
      dailyRows: dailyRows,
      dailyTotalIssued: dailyTotalIssued,
      dailyTotalGoodReturned: dailyTotalGood,
      dailyTotalDamaged: dailyTotalDamaged,
      dailyTotalLostShortage: dailyTotalLostShortage,
      dailyTotalLabourPaise: periodTotalLabourPaise,
      dailyTotalNetPaymentsPaise: periodNetPaymentsPaise,
      currentTotalPendingQty: totalPendingWithWorkers,
      workerPerformance: workerPerfRows,
      processPerformance: processPerfRows,
      inventory: inventorySection,
      financial: financialSection,
      insights: insights,
    );
  }

  static void _recordReason(
    Map<String, ReasonAcc> map,
    String? rawReason,
    int qty,
  ) {
    final cleaned = rawReason?.trim();
    if (cleaned == null || cleaned.isEmpty) return;
    final acc = map.putIfAbsent(cleaned, () => ReasonAcc());
    acc.quantity += qty;
    acc.occurrences += 1;
  }
}
