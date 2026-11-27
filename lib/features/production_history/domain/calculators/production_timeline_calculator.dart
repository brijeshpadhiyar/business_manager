import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/features/accounting/domain/calculators/ledger_calculator.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/production_history/domain/calculators/production_inspection_calculator.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/stock_movements/domain/calculators/stock_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';

typedef AssignmentsBuilder =
    List<AssignmentReconciliationSummary> Function(
      ProductionHistoryDataset data, {
      ProductionHistoryFilter? filter,
    });

/// Pure-Dart lot timeline, lot history, worker profile, and process history
/// builders extracted from [ProductionHistoryCalculator].
final class ProductionTimelineCalculator {
  const ProductionTimelineCalculator({
    required StockCalculator stockCalculator,
    required LedgerCalculator ledgerCalculator,
    required ProductionInspectionCalculator inspectionCalculator,
  }) : _stockCalc = stockCalculator,
       _ledgerCalc = ledgerCalculator,
       _inspectionCalc = inspectionCalculator;

  final StockCalculator _stockCalc;
  final LedgerCalculator _ledgerCalc;
  final ProductionInspectionCalculator _inspectionCalc;

  LotCompleteHistory? buildLotCompleteHistory(
    String lotId,
    ProductionHistoryDataset data, {
    required AssignmentsBuilder buildAssignments,
  }) {
    final lotEntry = data.lots[lotId];
    if (lotEntry == null) return null;
    final lot = lotEntry.entity;

    final reversedMovIds = _stockCalc.reversedMovementIds(data.movements);
    final pendingByColour = _inspectionCalc.pendingInspectionByDesignColour(
      returns: data.returns,
      inspections: data.inspections,
      reversedMovementIds: reversedMovIds,
    );

    final lotMovements = data.movements.where((m) => m.lotId == lotId).toList();
    final movementsByColour = <String, List<StockMovementEntity>>{};
    for (final m in lotMovements) {
      movementsByColour.putIfAbsent(m.designColourId, () => []).add(m);
    }

    final lotDesigns = data.designs.values
        .where((d) => d.lotId == lotId)
        .toList();
    final designById = {for (final d in lotDesigns) d.id: d};
    final lotColours = data.colours.values
        .where((c) => designById.containsKey(c.lotDesignId))
        .toList();
    final procNames = {
      for (final e in data.processes.entries) e.key: e.value.name,
    };

    var totalInitial = 0;
    final colourSummaries = <LotColourHistorySummary>[];
    for (final c in lotColours) {
      final design = designById[c.lotDesignId]!;
      totalInitial += c.initialQuantity;
      final bal = _stockCalc.calculateDesignColourBalance(
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
        pendingInspectionQuantity: pendingByColour[c.id] ?? 0,
      );
      colourSummaries.add(
        LotColourHistorySummary(
          designColourId: c.id,
          designName: design.designName,
          colourName: c.colourName,
          colourHex: c.colourHex,
          initialQuantity: c.initialQuantity,
          availableInHouse: bal.physicalAvailableInHouse,
          outstandingWithWorkers: bal.totalPendingWithWorkers,
          pendingInspection: bal.totalPendingInspection,
          damagedBucket: bal.damagedBucket,
          lostQty: bal.totalLost,
          shortageQty: bal.totalShortage,
        ),
      );
    }

    final assignments = buildAssignments(
      data,
      filter: ProductionHistoryFilter(lotId: lotId),
    );
    final rejections = _inspectionCalc.buildRejectionViews(data, lotId: lotId);
    final pendingReturns = _inspectionCalc.buildPendingReturns(
      data,
      lotId: lotId,
    );

    var assignedQty = 0;
    var returnedQty = 0;
    var acceptedQty = 0;
    var rejectedQty = 0;
    var pendingInspQty = 0;
    var pendingReinspQty = 0;
    var outstandingQty = 0;
    var lostShortageQty = 0;
    var totalCostPaise = 0;
    for (final a in assignments) {
      assignedQty += a.assignedQty;
      returnedQty += a.returnedQty;
      acceptedQty += a.totalAcceptedQty;
      rejectedQty += a.netRejectedQty;
      pendingInspQty += a.pendingInspectionQty;
      pendingReinspQty += a.pendingReinspectionQty;
      outstandingQty += a.outstandingQty;
      lostShortageQty += a.lostQty + a.shortageQty;
      totalCostPaise += a.earnedAmountPaise;
    }

    final timeline = buildLotTimeline(lotId, data);

    return LotCompleteHistory(
      lot: lot,
      createdBy: lotEntry.createdBy,
      updatedBy: lotEntry.updatedBy,
      colourSummaries: colourSummaries,
      totalInitialQty: totalInitial,
      totalAssignedQty: assignedQty,
      totalReturnedQty: returnedQty,
      totalAcceptedQty: acceptedQty,
      totalRejectedQty: rejectedQty,
      totalPendingInspectionQty: pendingInspQty,
      totalPendingReinspectionQty: pendingReinspQty,
      totalOutstandingQty: outstandingQty,
      totalLostShortageQty: lostShortageQty,
      totalProductionCostPaise: totalCostPaise,
      assignments: assignments,
      timeline: timeline,
      rejections: rejections,
      pendingReturns: pendingReturns,
    );
  }

  List<LotTimelineEvent> buildLotTimeline(
    String lotId,
    ProductionHistoryDataset data,
  ) {
    final lotEntry = data.lots[lotId];
    if (lotEntry == null) return const [];
    final lot = lotEntry.entity;
    final events = <LotTimelineEvent>[];

    final lotDesigns = data.designs.values.where((d) => d.lotId == lotId);
    final designIds = {for (final d in lotDesigns) d.id};
    final totalInitial = data.colours.values
        .where((c) => designIds.contains(c.lotDesignId))
        .fold<int>(0, (s, c) => s + c.initialQuantity);

    events.add(
      LotTimelineEvent(
        id: 'lot_created_${lot.id}',
        kind: LotTimelineEventKind.lotCreated,
        timestampUtcMillis: lot.transactionAt,
        recordedAtUtcMillis: lot.recordedAt,
        title: 'Lot ${lot.lotNumber} created',
        subtitle: lot.title != null
            ? '${lot.title} • $totalInitial pcs'
            : '$totalInitial pcs initial quantity',
        quantity: totalInitial,
        lotId: lot.id,
        lotNumber: lot.lotNumber,
        actor: lotEntry.createdBy,
        notes: lot.notes,
        transactionKind: ProductionTransactionKind.stockMovement,
        transactionId: lot.id,
      ),
    );

    final linkedMovIdsFromInsp = <String>{};
    for (final insp in data.inspections) {
      if (insp.lotId != lotId) continue;
      if (insp.linkedGoodMovementId != null) {
        linkedMovIdsFromInsp.add(insp.linkedGoodMovementId!);
      }
      if (insp.linkedDamagedMovementId != null) {
        linkedMovIdsFromInsp.add(insp.linkedDamagedMovementId!);
      }
    }

    for (final m in data.movements) {
      if (m.lotId != lotId) continue;
      final design = data.designs[m.lotDesignId]?.designName;
      final colour = data.colours[m.designColourId]?.colourName;
      final procName = m.processId != null
          ? data.processes[m.processId!]?.name
          : null;
      final workerName = m.memberId != null
          ? data.workers[m.memberId!]?.name
          : null;

      switch (m.movementType) {
        case StockMovementType.issue:
          events.add(
            LotTimelineEvent(
              id: 'mov_${m.id}',
              kind: LotTimelineEventKind.stockIssued,
              timestampUtcMillis: m.transactionAt,
              recordedAtUtcMillis: m.recordedAt,
              title:
                  '${procName ?? 'Process'} assigned & ${m.quantity} pcs issued to ${workerName ?? 'Worker'}',
              subtitle:
                  '${design ?? ''} ${colour ?? ''} • Rate ${MoneyFormatter.formatPaise(m.appliedRatePaise)}/pc',
              quantity: m.quantity,
              ratePaise: m.appliedRatePaise,
              lotId: lot.id,
              lotNumber: lot.lotNumber,
              designName: design,
              colourName: colour,
              processId: m.processId,
              processName: procName,
              workerId: m.memberId,
              workerName: workerName,
              actor: m.createdBy,
              notes: m.notes,
              transactionKind: ProductionTransactionKind.stockMovement,
              transactionId: m.id,
            ),
          );
        case StockMovementType.returnGood:
          if (!linkedMovIdsFromInsp.contains(m.id)) {
            events.add(
              LotTimelineEvent(
                id: 'mov_${m.id}',
                kind: LotTimelineEventKind.inspectionApproved,
                timestampUtcMillis: m.transactionAt,
                recordedAtUtcMillis: m.recordedAt,
                title:
                    '${m.quantity} pcs returned & accepted (${procName ?? ''})',
                subtitle:
                    '${workerName ?? ''} • Earned ${MoneyFormatter.formatPaise(m.quantity * m.appliedRatePaise)}',
                quantity: m.quantity,
                ratePaise: m.appliedRatePaise,
                amountPaise: m.quantity * m.appliedRatePaise,
                lotId: lot.id,
                lotNumber: lot.lotNumber,
                designName: design,
                colourName: colour,
                processId: m.processId,
                processName: procName,
                workerId: m.memberId,
                workerName: workerName,
                actor: m.createdBy,
                notes: m.notes,
                transactionKind: ProductionTransactionKind.stockMovement,
                transactionId: m.id,
              ),
            );
          }
        case StockMovementType.returnDamaged:
          if (!linkedMovIdsFromInsp.contains(m.id)) {
            events.add(
              LotTimelineEvent(
                id: 'mov_${m.id}',
                kind: LotTimelineEventKind.inspectionRejected,
                timestampUtcMillis: m.transactionAt,
                recordedAtUtcMillis: m.recordedAt,
                title: '${m.quantity} pcs recorded as damaged/rejected',
                subtitle: '${workerName ?? ''} • ${procName ?? ''}',
                quantity: m.quantity,
                lotId: lot.id,
                lotNumber: lot.lotNumber,
                designName: design,
                colourName: colour,
                processId: m.processId,
                processName: procName,
                workerId: m.memberId,
                workerName: workerName,
                actor: m.createdBy,
                reason: m.reason,
                notes: m.notes,
                transactionKind: ProductionTransactionKind.stockMovement,
                transactionId: m.id,
              ),
            );
          }
        case StockMovementType.settlementLost:
          events.add(
            LotTimelineEvent(
              id: 'mov_${m.id}',
              kind: LotTimelineEventKind.settlementLost,
              timestampUtcMillis: m.transactionAt,
              recordedAtUtcMillis: m.recordedAt,
              title: '${m.quantity} pcs settled as Lost',
              subtitle: '${workerName ?? ''} • ${procName ?? ''}',
              quantity: m.quantity,
              lotId: lot.id,
              lotNumber: lot.lotNumber,
              designName: design,
              colourName: colour,
              processId: m.processId,
              processName: procName,
              workerId: m.memberId,
              workerName: workerName,
              actor: m.createdBy,
              reason: m.reason,
              notes: m.notes,
              transactionKind: ProductionTransactionKind.stockMovement,
              transactionId: m.id,
            ),
          );
        case StockMovementType.settlementShortage:
          events.add(
            LotTimelineEvent(
              id: 'mov_${m.id}',
              kind: LotTimelineEventKind.settlementShortage,
              timestampUtcMillis: m.transactionAt,
              recordedAtUtcMillis: m.recordedAt,
              title: '${m.quantity} pcs settled as Shortage',
              subtitle: '${workerName ?? ''} • ${procName ?? ''}',
              quantity: m.quantity,
              lotId: lot.id,
              lotNumber: lot.lotNumber,
              designName: design,
              colourName: colour,
              processId: m.processId,
              processName: procName,
              workerId: m.memberId,
              workerName: workerName,
              actor: m.createdBy,
              reason: m.reason,
              notes: m.notes,
              transactionKind: ProductionTransactionKind.stockMovement,
              transactionId: m.id,
            ),
          );
        case StockMovementType.reversal:
          events.add(
            LotTimelineEvent(
              id: 'mov_${m.id}',
              kind: LotTimelineEventKind.movementReversed,
              timestampUtcMillis: m.transactionAt,
              recordedAtUtcMillis: m.recordedAt,
              title: 'Movement reversed (${m.quantity} pcs)',
              subtitle: m.reason ?? '',
              quantity: m.quantity,
              lotId: lot.id,
              lotNumber: lot.lotNumber,
              designName: design,
              colourName: colour,
              processId: m.processId,
              processName: procName,
              workerId: m.memberId,
              workerName: workerName,
              actor: m.createdBy,
              reason: m.reason,
              notes: m.notes,
              transactionKind: ProductionTransactionKind.stockMovement,
              transactionId: m.id,
            ),
          );
        case StockMovementType.adjustmentDamagedToGood:
          if (!linkedMovIdsFromInsp.contains(m.id)) {
            events.add(
              LotTimelineEvent(
                id: 'mov_${m.id}',
                kind: LotTimelineEventKind.repairReapproved,
                timestampUtcMillis: m.transactionAt,
                recordedAtUtcMillis: m.recordedAt,
                title: '${m.quantity} damaged pcs repaired to Good stock',
                subtitle: '${design ?? ''} ${colour ?? ''}',
                quantity: m.quantity,
                lotId: lot.id,
                lotNumber: lot.lotNumber,
                designName: design,
                colourName: colour,
                processId: m.processId,
                processName: procName,
                workerId: m.memberId,
                workerName: workerName,
                actor: m.createdBy,
                reason: m.reason,
                notes: m.notes,
                transactionKind: ProductionTransactionKind.stockMovement,
                transactionId: m.id,
              ),
            );
          }
      }
    }

    for (final ret in data.returns) {
      if (ret.lotId != lotId) continue;
      final design = data.designs[ret.lotDesignId]?.designName;
      final colour = data.colours[ret.designColourId]?.colourName;
      final procName = data.processes[ret.processId]?.name;
      final workerName = data.workers[ret.memberId]?.name;
      events.add(
        LotTimelineEvent(
          id: 'ret_${ret.id}',
          kind: LotTimelineEventKind.stockReturned,
          timestampUtcMillis: ret.transactionAt,
          recordedAtUtcMillis: ret.recordedAt,
          title:
              '${ret.returnedQuantity} pcs returned by ${workerName ?? 'Worker'} (${procName ?? ''})',
          subtitle: ret.returnMode == ProductionReturnMode.pendingInspection
              ? 'Logged as Pending QC Inspection'
              : 'Returned with Immediate Inspection',
          quantity: ret.returnedQuantity,
          lotId: lot.id,
          lotNumber: lot.lotNumber,
          designName: design,
          colourName: colour,
          processId: ret.processId,
          processName: procName,
          workerId: ret.memberId,
          workerName: workerName,
          actor: ret.createdBy,
          notes: ret.notes,
          transactionKind: ProductionTransactionKind.productionReturn,
          transactionId: ret.id,
        ),
      );
    }

    for (final insp in data.inspections) {
      if (insp.lotId != lotId) continue;
      final design = data.designs[insp.lotDesignId]?.designName;
      final colour = data.colours[insp.designColourId]?.colourName;
      final procName = data.processes[insp.processId]?.name;
      final workerName = data.workers[insp.memberId]?.name;
      final isReinsp =
          insp.inspectionType == ProductionInspectionType.reinspection;

      if (insp.acceptedQuantity > 0) {
        events.add(
          LotTimelineEvent(
            id: 'insp_acc_${insp.id}',
            kind: isReinsp
                ? LotTimelineEventKind.repairReapproved
                : LotTimelineEventKind.inspectionApproved,
            timestampUtcMillis: insp.transactionAt,
            recordedAtUtcMillis: insp.recordedAt,
            title: isReinsp
                ? '${insp.acceptedQuantity} repaired pcs re-approved (${procName ?? ''})'
                : '${insp.acceptedQuantity} pcs approved (${procName ?? ''})',
            subtitle: insp.creditWorkerEarnings
                ? '${workerName ?? ''} • Earned ${MoneyFormatter.formatPaise(insp.earnedAmountPaise)} @ ${MoneyFormatter.formatPaise(insp.lockedRatePaise)}/pc'
                : 'In-house repair • No worker earning credited',
            quantity: insp.acceptedQuantity,
            ratePaise: insp.lockedRatePaise,
            amountPaise: insp.earnedAmountPaise,
            lotId: lot.id,
            lotNumber: lot.lotNumber,
            designName: design,
            colourName: colour,
            processId: insp.processId,
            processName: procName,
            workerId: insp.memberId,
            workerName: workerName,
            actor: insp.approvedBy ?? insp.inspectedBy,
            notes: insp.notes,
            transactionKind: ProductionTransactionKind.inspection,
            transactionId: insp.id,
          ),
        );
      }

      if (insp.rejectedQuantity > 0) {
        events.add(
          LotTimelineEvent(
            id: 'insp_rej_${insp.id}',
            kind: LotTimelineEventKind.inspectionRejected,
            timestampUtcMillis: insp.transactionAt,
            recordedAtUtcMillis: insp.recordedAt + 1,
            title: isReinsp
                ? '${insp.rejectedQuantity} repaired pcs failed reinspection'
                : '${insp.rejectedQuantity} pcs rejected/damaged (${procName ?? ''})',
            subtitle:
                '${workerName ?? ''} • ₹0 payable${insp.rejectionReason != null ? ' • ${insp.rejectionReason}' : ''}',
            quantity: insp.rejectedQuantity,
            lotId: lot.id,
            lotNumber: lot.lotNumber,
            designName: design,
            colourName: colour,
            processId: insp.processId,
            processName: procName,
            workerId: insp.memberId,
            workerName: workerName,
            actor: insp.inspectedBy ?? insp.approvedBy,
            reason: insp.rejectionReason,
            notes: insp.notes,
            transactionKind: ProductionTransactionKind.inspection,
            transactionId: insp.id,
          ),
        );
      }
    }

    for (final rep in data.repairs) {
      if (rep.lotId != lotId) continue;
      final procName = data.processes[rep.processId]?.name;
      final workerName = data.workers[rep.memberId]?.name;
      events.add(
        LotTimelineEvent(
          id: 'rep_${rep.id}',
          kind: LotTimelineEventKind.rejectionRepaired,
          timestampUtcMillis: rep.transactionAt,
          recordedAtUtcMillis: rep.recordedAt,
          title:
              '${rep.repairedQuantity} rejected pcs repaired (${rep.repairSource == RepairSource.originalWorker ? workerName ?? 'Worker' : 'In-House'})',
          subtitle: 'Submitted for QC Reinspection • ${procName ?? ''}',
          quantity: rep.repairedQuantity,
          lotId: lot.id,
          lotNumber: lot.lotNumber,
          processId: rep.processId,
          processName: procName,
          workerId: rep.memberId,
          workerName: workerName,
          actor: rep.repairedBy,
          notes: rep.notes,
          transactionKind: ProductionTransactionKind.repair,
          transactionId: rep.id,
        ),
      );
    }

    for (final h in data.handovers) {
      if (h.lotId != lotId) continue;
      if (h.handoverType != ProcessHandoverType.directTransfer) continue;
      events.add(
        LotTimelineEvent(
          id: 'ho_${h.id}',
          kind: LotTimelineEventKind.handoverTransfer,
          timestampUtcMillis: h.transactionAt,
          recordedAtUtcMillis: h.recordedAt,
          title:
              'Direct transfer ${h.quantityDispatched} pcs: ${h.fromMemberName ?? 'Worker'} → ${h.toMemberName ?? 'Worker'}',
          subtitle: '${h.processName} • Ref ${h.transferReference}',
          quantity: h.quantityDispatched,
          lotId: lot.id,
          lotNumber: lot.lotNumber,
          designName: h.designName,
          colourName: h.colourName,
          processId: h.processId,
          processName: h.processName,
          workerId: h.toMemberId,
          workerName: h.toMemberName,
          notes: h.notes,
          transactionKind: ProductionTransactionKind.handover,
          transactionId: h.id,
        ),
      );
    }

    if (lot.status == LotStatus.completed) {
      events.add(
        LotTimelineEvent(
          id: 'lot_completed_${lot.id}',
          kind: LotTimelineEventKind.lotCompleted,
          timestampUtcMillis: lot.updatedAt,
          recordedAtUtcMillis: lot.updatedAt,
          title: 'Lot ${lot.lotNumber} completed',
          subtitle: 'Production finished and reconciled',
          lotId: lot.id,
          lotNumber: lot.lotNumber,
          actor: lotEntry.updatedBy,
          transactionKind: ProductionTransactionKind.stockMovement,
          transactionId: lot.id,
        ),
      );
    }

    events.sort((a, b) {
      if (a.kind == LotTimelineEventKind.lotCreated &&
          b.kind != LotTimelineEventKind.lotCreated) {
        return -1;
      }
      if (b.kind == LotTimelineEventKind.lotCreated &&
          a.kind != LotTimelineEventKind.lotCreated) {
        return 1;
      }
      if (a.kind == LotTimelineEventKind.lotCompleted &&
          b.kind != LotTimelineEventKind.lotCompleted) {
        return 1;
      }
      if (b.kind == LotTimelineEventKind.lotCompleted &&
          a.kind != LotTimelineEventKind.lotCompleted) {
        return -1;
      }
      final tsCmp = a.timestampUtcMillis.compareTo(b.timestampUtcMillis);
      if (tsCmp != 0) return tsCmp;
      final recCmp = a.recordedAtUtcMillis.compareTo(b.recordedAtUtcMillis);
      if (recCmp != 0) return recCmp;
      return a.id.compareTo(b.id);
    });
    return events;
  }

  WorkerCompleteProfile? buildWorkerCompleteProfile(
    String workerId,
    ProductionHistoryDataset data, {
    ProductionHistoryFilter? filter,
    required AssignmentsBuilder buildAssignments,
  }) {
    final w = data.workers[workerId];
    if (w == null) return null;

    final assignments = buildAssignments(
      data,
      filter: (filter ?? const ProductionHistoryFilter()).copyWith(
        workerId: workerId,
      ),
    );
    final financialSummary = _ledgerCalc.calculateWorkerSummary(
      workerId: workerId,
      workerName: w.name,
      workerPhone: w.phone,
      workerIsActive: w.isActive,
      labourEntries: data.labourEntries,
      payments: data.payments,
      adjustments: data.adjustments,
    );
    final rejections = _inspectionCalc.buildRejectionViews(
      data,
      workerId: workerId,
    );
    final pendingReturns = _inspectionCalc.buildPendingReturns(
      data,
      workerId: workerId,
    );

    final distinctLotIds = <String>{};
    var completedAssignments = 0;
    var assignedQty = 0;
    var returnedQty = 0;
    var acceptedQty = 0;
    var pendingInspectionQty = 0;
    var outstandingQty = 0;
    var rejectedQty = 0;

    final byProc = <String, List<AssignmentReconciliationSummary>>{};
    for (final a in assignments) {
      distinctLotIds.add(a.lotId);
      if (a.isCompleted) completedAssignments++;
      assignedQty += a.assignedQty;
      returnedQty += a.returnedQty;
      acceptedQty += a.totalAcceptedQty;
      pendingInspectionQty += a.pendingInspectionQty;
      outstandingQty += a.outstandingQty;
      rejectedQty += a.netRejectedQty;
      byProc.putIfAbsent(a.processId, () => []).add(a);
    }

    final totalEarnedAcrossProcs = assignments.fold<int>(
      0,
      (s, a) => s + a.earnedAmountPaise,
    );
    final processHistory = <WorkerProcessProductionSummary>[];
    for (final entry in byProc.entries) {
      final list = entry.value;
      final procLots = <String>{};
      var pCompleted = 0;
      var pAssigned = 0;
      var pReturned = 0;
      var pAccepted = 0;
      var pPendingInsp = 0;
      var pOutstanding = 0;
      var pRejected = 0;
      var pEarned = 0;
      for (final a in list) {
        procLots.add(a.lotId);
        if (a.isCompleted) pCompleted++;
        pAssigned += a.assignedQty;
        pReturned += a.returnedQty;
        pAccepted += a.totalAcceptedQty;
        pPendingInsp += a.pendingInspectionQty;
        pOutstanding += a.outstandingQty;
        pRejected += a.netRejectedQty;
        pEarned += a.earnedAmountPaise;
      }
      final estPendingPayable =
          (totalEarnedAcrossProcs > 0 &&
              financialSummary.outstandingPayablePaise > 0)
          ? ((financialSummary.outstandingPayablePaise * pEarned) /
                    totalEarnedAcrossProcs)
                .round()
          : 0;
      processHistory.add(
        WorkerProcessProductionSummary(
          processId: entry.key,
          processName: list.first.processName,
          processIsActive: list.first.processIsActive,
          totalLots: procLots.length,
          totalAssignments: list.length,
          completedAssignments: pCompleted,
          assignedQty: pAssigned,
          returnedQty: pReturned,
          acceptedQty: pAccepted,
          pendingInspectionQty: pPendingInsp,
          outstandingQty: pOutstanding,
          rejectedQty: pRejected,
          earnedAmountPaise: pEarned,
          estimatedPendingPayablePaise: estPendingPayable,
        ),
      );
    }
    processHistory.sort(
      (a, b) => b.earnedAmountPaise.compareTo(a.earnedAmountPaise),
    );

    return WorkerCompleteProfile(
      workerId: workerId,
      workerName: w.name,
      phone: w.phone,
      address: w.address,
      notes: w.notes,
      isActive: w.isActive,
      createdAt: w.createdAt,
      totalLotsAssigned: distinctLotIds.length,
      totalProcessesCompleted: completedAssignments,
      assignedQty: assignedQty,
      returnedQty: returnedQty,
      acceptedQty: acceptedQty,
      pendingInspectionQty: pendingInspectionQty,
      outstandingQty: outstandingQty,
      rejectedQty: rejectedQty,
      financialSummary: financialSummary,
      lotHistory: assignments,
      processHistory: processHistory,
      rejections: rejections,
      pendingReturns: pendingReturns,
    );
  }

  List<ProcessCompleteHistory> buildAllProcessHistories(
    ProductionHistoryDataset data, {
    ProductionHistoryFilter? filter,
    required AssignmentsBuilder buildAssignments,
  }) {
    final allAssignments = buildAssignments(data, filter: filter);
    final byProc = <String, List<AssignmentReconciliationSummary>>{};
    for (final a in allAssignments) {
      byProc.putIfAbsent(a.processId, () => []).add(a);
    }

    final workerRatio = <String, double>{};
    for (final wId in data.workers.keys) {
      final fin = _ledgerCalc.calculateWorkerSummary(
        workerId: wId,
        workerName: data.workers[wId]!.name,
        workerIsActive: data.workers[wId]!.isActive,
        labourEntries: data.labourEntries,
        payments: data.payments,
        adjustments: data.adjustments,
      );
      if (fin.earnedLabourPaise > 0) {
        final paidRatio =
            (fin.earnedLabourPaise - fin.outstandingPayablePaise).clamp(
              0,
              fin.earnedLabourPaise,
            ) /
            fin.earnedLabourPaise;
        workerRatio[wId] = paidRatio;
      } else {
        workerRatio[wId] = 0.0;
      }
    }

    final targetProcessIds = <String>{
      if (filter?.processId != null)
        filter!.processId!
      else ...{
        ...data.processes.keys,
        ...byProc.keys,
      },
    };

    final list = <ProcessCompleteHistory>[];
    for (final procId in targetProcessIds) {
      final procInfo = data.processes[procId];
      final procAssignments = byProc[procId] ?? const [];
      if (procInfo == null && procAssignments.isEmpty) continue;

      final lotIds = <String>{};
      final workerIds = <String>{};
      var assigned = 0;
      var returned = 0;
      var accepted = 0;
      var pendingInsp = 0;
      var outstanding = 0;
      var rejected = 0;
      var completedQty = 0;
      var costPaise = 0;
      var estPaidPaise = 0;

      final byLot = <String, List<AssignmentReconciliationSummary>>{};
      final byWorker = <String, List<AssignmentReconciliationSummary>>{};
      final byDate = <String, _DateBucket>{};
      final pendingAssignments = <AssignmentReconciliationSummary>[];

      for (final a in procAssignments) {
        lotIds.add(a.lotId);
        workerIds.add(a.workerId);
        assigned += a.assignedQty;
        returned += a.returnedQty;
        accepted += a.totalAcceptedQty;
        pendingInsp += a.pendingInspectionQty;
        outstanding += a.outstandingQty;
        rejected += a.netRejectedQty;
        if (a.isCompleted) completedQty += a.totalAcceptedQty;
        costPaise += a.earnedAmountPaise;
        estPaidPaise += (a.earnedAmountPaise * (workerRatio[a.workerId] ?? 0.0))
            .round();

        byLot.putIfAbsent(a.lotId, () => []).add(a);
        byWorker.putIfAbsent(a.workerId, () => []).add(a);
        final iso = IstDateTimeHelper.toIstBusinessDate(a.assignedAt);
        final db = byDate.putIfAbsent(iso, () => _DateBucket());
        db.assigned += a.assignedQty;
        db.returned += a.returnedQty;
        db.accepted += a.totalAcceptedQty;
        db.rejected += a.netRejectedQty;
        db.earned += a.earnedAmountPaise;

        if (!a.isCompleted) {
          pendingAssignments.add(a);
        }
      }

      final lotRows = byLot.entries.map((e) {
        final items = e.value;
        return ProcessLotSummaryRow(
          lotId: e.key,
          lotNumber: items.first.lotNumber,
          assignedQty: items.fold(0, (s, x) => s + x.assignedQty),
          returnedQty: items.fold(0, (s, x) => s + x.returnedQty),
          acceptedQty: items.fold(0, (s, x) => s + x.totalAcceptedQty),
          pendingInspectionQty: items.fold(
            0,
            (s, x) => s + x.pendingInspectionQty,
          ),
          outstandingQty: items.fold(0, (s, x) => s + x.outstandingQty),
          rejectedQty: items.fold(0, (s, x) => s + x.netRejectedQty),
          earnedAmountPaise: items.fold(0, (s, x) => s + x.earnedAmountPaise),
        );
      }).toList()..sort((a, b) => b.assignedQty.compareTo(a.assignedQty));

      final workerRows =
          byWorker.entries.map((e) {
            final items = e.value;
            final wLots = {for (final x in items) x.lotId};
            return ProcessWorkerSummaryRow(
              workerId: e.key,
              workerName: items.first.workerName,
              workerIsActive: items.first.workerIsActive,
              totalLots: wLots.length,
              assignedQty: items.fold(0, (s, x) => s + x.assignedQty),
              returnedQty: items.fold(0, (s, x) => s + x.returnedQty),
              acceptedQty: items.fold(0, (s, x) => s + x.totalAcceptedQty),
              pendingInspectionQty: items.fold(
                0,
                (s, x) => s + x.pendingInspectionQty,
              ),
              outstandingQty: items.fold(0, (s, x) => s + x.outstandingQty),
              rejectedQty: items.fold(0, (s, x) => s + x.netRejectedQty),
              earnedAmountPaise: items.fold(
                0,
                (s, x) => s + x.earnedAmountPaise,
              ),
            );
          }).toList()..sort(
            (a, b) => b.earnedAmountPaise.compareTo(a.earnedAmountPaise),
          );

      final dateRows =
          byDate.entries
              .map(
                (e) => ProcessDateHistoryRow(
                  istDateIso: e.key,
                  assignedQty: e.value.assigned,
                  returnedQty: e.value.returned,
                  acceptedQty: e.value.accepted,
                  rejectedQty: e.value.rejected,
                  earnedPaise: e.value.earned,
                ),
              )
              .toList()
            ..sort((a, b) => b.istDateIso.compareTo(a.istDateIso));

      final rejections = _inspectionCalc.buildRejectionViews(
        data,
        processId: procId,
      );

      list.add(
        ProcessCompleteHistory(
          processId: procId,
          processName: procInfo?.name ?? procId,
          isActive: procInfo?.isActive ?? false,
          totalLots: lotIds.length,
          totalWorkersInvolved: workerIds.length,
          assignedQty: assigned,
          returnedQty: returned,
          acceptedQty: accepted,
          pendingInspectionQty: pendingInsp,
          outstandingQty: outstanding,
          rejectedQty: rejected,
          completedQty: completedQty,
          totalProductionCostPaise: costPaise,
          estimatedPaidPaise: estPaidPaise,
          estimatedOutstandingPaise: (costPaise - estPaidPaise).clamp(
            0,
            costPaise,
          ),
          lotHistory: lotRows,
          workerHistory: workerRows,
          dateHistory: dateRows,
          pendingAssignments: pendingAssignments,
          allAssignments: procAssignments,
          rejections: rejections,
        ),
      );
    }

    list.sort((a, b) => b.assignedQty.compareTo(a.assignedQty));
    return list;
  }
}

final class _DateBucket {
  int assigned = 0;
  int returned = 0;
  int accepted = 0;
  int rejected = 0;
  int earned = 0;
}
