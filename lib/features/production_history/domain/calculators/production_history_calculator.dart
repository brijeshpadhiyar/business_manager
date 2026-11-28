import 'package:business_manager/features/accounting/domain/calculators/ledger_calculator.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/production_history/domain/calculators/production_inspection_calculator.dart';
import 'package:business_manager/features/production_history/domain/calculators/production_timeline_calculator.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/stock_movements/domain/calculators/stock_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';

/// Pure Dart reconciliation, timeline, and analytics engine for StitchFlow's
/// Complete Production History, Lot Tracking, Worker Account & Process History.
final class ProductionHistoryCalculator {
  const ProductionHistoryCalculator();

  static const StockCalculator _stockCalc = StockCalculator();
  static const LedgerCalculator _ledgerCalc = LedgerCalculator();
  static const ProductionInspectionCalculator _inspectionCalc =
      ProductionInspectionCalculator();
  static const ProductionTimelineCalculator _timelineCalc =
      ProductionTimelineCalculator(
        stockCalculator: _stockCalc,
        ledgerCalculator: _ledgerCalc,
        inspectionCalculator: _inspectionCalc,
      );

  int remainingPendingInspectionForReturn({
    required ProductionReturnEntity productionReturn,
    required List<ProductionInspectionEntity> inspections,
  }) => _inspectionCalc.remainingPendingInspectionForReturn(
    productionReturn: productionReturn,
    inspections: inspections,
  );

  Map<String, int> pendingInspectionByDesignColour({
    required List<ProductionReturnEntity> returns,
    required List<ProductionInspectionEntity> inspections,
    required Set<String> reversedMovementIds,
  }) => _inspectionCalc.pendingInspectionByDesignColour(
    returns: returns,
    inspections: inspections,
    reversedMovementIds: reversedMovementIds,
  );

  Map<String, int> pendingInspectionByIssue({
    required List<ProductionReturnEntity> returns,
    required List<ProductionInspectionEntity> inspections,
    required Set<String> reversedMovementIds,
  }) => _inspectionCalc.pendingInspectionByIssue(
    returns: returns,
    inspections: inspections,
    reversedMovementIds: reversedMovementIds,
  );

  String? validateReturnSubmission({
    required StockMovementEntity parentIssue,
    required int returnedQuantity,
    required int currentOutstandingQty,
    required bool isReversed,
    bool inspectImmediately = false,
    int acceptedQuantity = 0,
    int rejectedQuantity = 0,
    String? rejectionReason,
  }) => _inspectionCalc.validateReturnSubmission(
    parentIssue: parentIssue,
    returnedQuantity: returnedQuantity,
    currentOutstandingQty: currentOutstandingQty,
    isReversed: isReversed,
    inspectImmediately: inspectImmediately,
    acceptedQuantity: acceptedQuantity,
    rejectedQuantity: rejectedQuantity,
    rejectionReason: rejectionReason,
  );

  String? validateInspectionApproval({
    required int remainingPendingInspectionQty,
    required int acceptedQuantity,
    required int rejectedQuantity,
    String? rejectionReason,
  }) => _inspectionCalc.validateInspectionApproval(
    remainingPendingInspectionQty: remainingPendingInspectionQty,
    acceptedQuantity: acceptedQuantity,
    rejectedQuantity: rejectedQuantity,
    rejectionReason: rejectionReason,
  );

  String? validateRepairSubmission({
    required int openUnrepairedQty,
    required int repairedQuantity,
  }) => _inspectionCalc.validateRepairSubmission(
    openUnrepairedQty: openUnrepairedQty,
    repairedQuantity: repairedQuantity,
  );

  String? validateRepairReinspection({
    required int pendingReinspectionQty,
    required int acceptedQuantity,
    required int rejectedAgainQuantity,
    String? rejectionReason,
  }) => _inspectionCalc.validateRepairReinspection(
    pendingReinspectionQty: pendingReinspectionQty,
    acceptedQuantity: acceptedQuantity,
    rejectedAgainQuantity: rejectedAgainQuantity,
    rejectionReason: rejectionReason,
  );

  List<AssignmentReconciliationSummary> buildAssignments(
    ProductionHistoryDataset data, {
    ProductionHistoryFilter? filter,
  }) {
    final reversedMovIds = _stockCalc.reversedMovementIds(data.movements);
    final revLabourIds = _ledgerCalc.reversedLabourIds(data.labourEntries);

    final linkedMovementIdsFromInspections = <String>{};
    final inspectionsByIssue = <String, List<ProductionInspectionEntity>>{};
    for (final insp in data.inspections) {
      inspectionsByIssue.putIfAbsent(insp.parentIssueId, () => []).add(insp);
      if (insp.linkedGoodMovementId != null) {
        linkedMovementIdsFromInspections.add(insp.linkedGoodMovementId!);
      }
      if (insp.linkedDamagedMovementId != null) {
        linkedMovementIdsFromInspections.add(insp.linkedDamagedMovementId!);
      }
    }

    final returnsByIssue = <String, List<ProductionReturnEntity>>{};
    for (final r in data.returns) {
      returnsByIssue.putIfAbsent(r.parentIssueId, () => []).add(r);
    }

    final repairsByRejection = <String, List<RejectionRepairEntity>>{};
    for (final rep in data.repairs) {
      repairsByRejection.putIfAbsent(rep.rejectionRecordId, () => []).add(rep);
    }

    final rejectionsByIssue = <String, List<RejectionRecordEntity>>{};
    for (final rej in data.rejections) {
      rejectionsByIssue.putIfAbsent(rej.parentIssueId, () => []).add(rej);
    }

    final childMovementsByIssue = <String, List<StockMovementEntity>>{};
    for (final m in data.movements) {
      if (m.movementType == StockMovementType.reversal ||
          reversedMovIds.contains(m.id)) {
        continue;
      }
      if (m.parentIssueId != null) {
        childMovementsByIssue.putIfAbsent(m.parentIssueId!, () => []).add(m);
      }
    }

    final payableLabourByMovement = <String, int>{};
    for (final l in data.labourEntries) {
      if (l.basisType == LabourBasisType.reversal ||
          revLabourIds.contains(l.id)) {
        continue;
      }
      if (l.isPayable) {
        payableLabourByMovement[l.stockMovementId] =
            (payableLabourByMovement[l.stockMovementId] ?? 0) + l.amountPaise;
      }
    }

    final results = <AssignmentReconciliationSummary>[];
    final q = filter?.searchQuery?.trim().toLowerCase();

    for (final issue in data.movements) {
      if (issue.movementType != StockMovementType.issue) continue;
      if (reversedMovIds.contains(issue.id)) continue;
      if (issue.memberId == null || issue.processId == null) continue;

      if (filter != null) {
        if (filter.lotId != null && issue.lotId != filter.lotId) continue;
        if (filter.workerId != null && issue.memberId != filter.workerId) {
          continue;
        }
        if (filter.processId != null && issue.processId != filter.processId) {
          continue;
        }
        if (filter.fromUtcMillis != null &&
            issue.transactionAt < filter.fromUtcMillis!) {
          continue;
        }
        if (filter.toUtcMillis != null &&
            issue.transactionAt > filter.toUtcMillis!) {
          continue;
        }
      }

      final lotMeta = data.lots[issue.lotId];
      final design = data.designs[issue.lotDesignId];
      final colour = data.colours[issue.designColourId];
      final proc = data.processes[issue.processId!];
      final worker = data.workers[issue.memberId!];

      final lotNumber = lotMeta?.entity.lotNumber ?? issue.lotId;
      final designName = design?.designName ?? '-';
      final colourName = colour?.colourName ?? '-';
      final procName = proc?.name ?? issue.processId!;
      final workerName = worker?.name ?? issue.memberId!;

      if (filter != null) {
        if (filter.designName != null &&
            designName.toLowerCase() != filter.designName!.toLowerCase()) {
          continue;
        }
        if (filter.colourName != null &&
            colourName.toLowerCase() != filter.colourName!.toLowerCase()) {
          continue;
        }
        if (q != null && q.isNotEmpty) {
          final hay =
              '$lotNumber $designName $colourName $procName $workerName ${issue.notes ?? ''}'
                  .toLowerCase();
          if (!hay.contains(q)) continue;
        }
      }

      final issueReturns = returnsByIssue[issue.id] ?? const [];
      final issueInspections = inspectionsByIssue[issue.id] ?? const [];
      final issueChildren = childMovementsByIssue[issue.id] ?? const [];
      final issueRejections = rejectionsByIssue[issue.id] ?? const [];

      var returnedViaV8 = 0;
      for (final r in issueReturns) {
        returnedViaV8 += r.returnedQuantity;
      }

      var acceptedInitial = 0;
      var rejectedInitial = 0;
      var reapproved = 0;
      var lastEventAt = issue.transactionAt;

      for (final insp in issueInspections) {
        if (insp.transactionAt > lastEventAt) lastEventAt = insp.transactionAt;
        if (insp.inspectionType == ProductionInspectionType.initial) {
          acceptedInitial += insp.acceptedQuantity;
          rejectedInitial += insp.rejectedQuantity;
        } else {
          reapproved += insp.acceptedQuantity;
        }
      }

      var legacyGood = 0;
      var legacyDamaged = 0;
      var lost = 0;
      var shortage = 0;
      var earnedPaise = payableLabourByMovement[issue.id] ?? 0;

      for (final child in issueChildren) {
        if (child.transactionAt > lastEventAt) {
          lastEventAt = child.transactionAt;
        }
        earnedPaise += payableLabourByMovement[child.id] ?? 0;

        switch (child.movementType) {
          case StockMovementType.returnGood:
            if (!linkedMovementIdsFromInspections.contains(child.id)) {
              legacyGood += child.quantity;
            }
          case StockMovementType.returnDamaged:
            if (!linkedMovementIdsFromInspections.contains(child.id)) {
              legacyDamaged += child.quantity;
            }
          case StockMovementType.settlementLost:
            lost += child.quantity;
          case StockMovementType.settlementShortage:
            shortage += child.quantity;
          case StockMovementType.adjustmentDamagedToGood:
          case StockMovementType.issue:
          case StockMovementType.reversal:
            break;
        }
      }

      final totalReturned = returnedViaV8 + legacyGood + legacyDamaged;
      final totalAcceptedInitial = acceptedInitial + legacyGood;
      final totalRejectedInitial = rejectedInitial + legacyDamaged;
      final pendingInspection =
          (returnedViaV8 - (acceptedInitial + rejectedInitial)).clamp(
            0,
            returnedViaV8,
          );
      final outstanding = (issue.quantity - totalReturned - lost - shortage)
          .clamp(0, issue.quantity);

      var pendingReinspection = 0;
      for (final rej in issueRejections) {
        final repairs =
            repairsByRejection[rej.id] ?? const <RejectionRepairEntity>[];
        for (final rep in repairs) {
          var reinspected = 0;
          for (final insp in issueInspections) {
            if (insp.inspectionType == ProductionInspectionType.reinspection &&
                insp.rejectionRepairId == rep.id) {
              reinspected += insp.acceptedQuantity + insp.rejectedQuantity;
            }
          }
          final diff = rep.repairedQuantity - reinspected;
          if (diff > 0) {
            pendingReinspection += diff;
          }
        }
      }

      final completed =
          outstanding == 0 &&
          pendingInspection == 0 &&
          pendingReinspection == 0;

      if (filter != null && filter.onlyPending && completed) {
        continue;
      }

      results.add(
        AssignmentReconciliationSummary(
          issueMovementId: issue.id,
          jobProcessId: issue.jobProcessId,
          lotId: issue.lotId,
          lotNumber: lotNumber,
          lotDesignId: issue.lotDesignId,
          designName: designName,
          designColourId: issue.designColourId,
          colourName: colourName,
          colourHex: colour?.colourHex,
          processId: issue.processId!,
          processName: procName,
          processIsActive: proc?.isActive ?? false,
          workerId: issue.memberId!,
          workerName: workerName,
          workerIsActive: worker?.isActive ?? false,
          assignedAt: issue.transactionAt,
          completedAt: completed ? lastEventAt : null,
          assignedQty: issue.quantity,
          returnedQty: totalReturned,
          acceptedInitialQty: totalAcceptedInitial,
          reapprovedQty: reapproved,
          rejectedInitialQty: totalRejectedInitial,
          pendingInspectionQty: pendingInspection,
          pendingReinspectionQty: pendingReinspection,
          lostQty: lost,
          shortageQty: shortage,
          outstandingQty: outstanding,
          lockedRatePaise: issue.appliedRatePaise,
          earnedAmountPaise: earnedPaise,
          isRateOverridden: issue.isRateOverridden,
          overrideReason: issue.overrideReason,
          notes: issue.notes,
          createdBy: issue.createdBy,
        ),
      );
    }

    results.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
    return results;
  }

  List<PendingReturnView> buildPendingReturns(
    ProductionHistoryDataset data, {
    String? lotId,
    String? workerId,
    String? processId,
  }) => _inspectionCalc.buildPendingReturns(
    data,
    lotId: lotId,
    workerId: workerId,
    processId: processId,
  );

  List<RejectionRecordView> buildRejectionViews(
    ProductionHistoryDataset data, {
    String? lotId,
    String? workerId,
    String? processId,
    bool onlyOpen = false,
  }) => _inspectionCalc.buildRejectionViews(
    data,
    lotId: lotId,
    workerId: workerId,
    processId: processId,
    onlyOpen: onlyOpen,
  );

  LotCompleteHistory? buildLotCompleteHistory(
    String lotId,
    ProductionHistoryDataset data,
  ) => _timelineCalc.buildLotCompleteHistory(
    lotId,
    data,
    buildAssignments: buildAssignments,
  );

  List<LotTimelineEvent> buildLotTimeline(
    String lotId,
    ProductionHistoryDataset data,
  ) => _timelineCalc.buildLotTimeline(lotId, data);

  WorkerCompleteProfile? buildWorkerCompleteProfile(
    String workerId,
    ProductionHistoryDataset data, {
    ProductionHistoryFilter? filter,
  }) => _timelineCalc.buildWorkerCompleteProfile(
    workerId,
    data,
    filter: filter,
    buildAssignments: buildAssignments,
  );

  List<ProcessCompleteHistory> buildAllProcessHistories(
    ProductionHistoryDataset data, {
    ProductionHistoryFilter? filter,
  }) => _timelineCalc.buildAllProcessHistories(
    data,
    filter: filter,
    buildAssignments: buildAssignments,
  );

  ProductionHistoryDashboardData buildDashboard(
    ProductionHistoryDataset data, {
    ProductionHistoryFilter filter = const ProductionHistoryFilter(),
  }) {
    final assignments = buildAssignments(data, filter: filter);
    final pendingReturns = buildPendingReturns(
      data,
      lotId: filter.lotId,
      workerId: filter.workerId,
      processId: filter.processId,
    );
    final openRejections = buildRejectionViews(
      data,
      lotId: filter.lotId,
      workerId: filter.workerId,
      processId: filter.processId,
      onlyOpen: true,
    );

    final lotIds = <String>{};
    var assigned = 0;
    var returned = 0;
    var accepted = 0;
    var rejected = 0;
    var pendingInsp = 0;
    var outstanding = 0;
    var earned = 0;
    for (final a in assignments) {
      lotIds.add(a.lotId);
      assigned += a.assignedQty;
      returned += a.returnedQty;
      accepted += a.totalAcceptedQty;
      rejected += a.netRejectedQty;
      pendingInsp += a.pendingInspectionQty;
      outstanding += a.outstandingQty;
      earned += a.earnedAmountPaise;
    }

    var paid = 0;
    var outstandingPayable = 0;
    final targetWorkerIds = filter.workerId != null
        ? {filter.workerId!}
        : data.workers.keys.toSet();
    for (final wId in targetWorkerIds) {
      final w = data.workers[wId];
      if (w == null) continue;
      final fin = _ledgerCalc.calculateWorkerSummary(
        workerId: wId,
        workerName: w.name,
        workerIsActive: w.isActive,
        labourEntries: data.labourEntries,
        payments: data.payments,
        adjustments: data.adjustments,
      );
      paid += fin.netPaidToWorkerPaise;
      outstandingPayable += fin.outstandingPayablePaise;
    }

    final feed = <ProductionHistoryFeedItem>[];
    final q = filter.searchQuery?.trim().toLowerCase();
    final reversedMovIds = _stockCalc.reversedMovementIds(data.movements);

    bool matchesDims({
      required String? lotId,
      required String? workerId,
      required String? processId,
      required int timestamp,
      required String haystack,
    }) {
      if (filter.lotId != null && lotId != filter.lotId) return false;
      if (filter.workerId != null && workerId != filter.workerId) return false;
      if (filter.processId != null && processId != filter.processId) {
        return false;
      }
      if (filter.fromUtcMillis != null && timestamp < filter.fromUtcMillis!) {
        return false;
      }
      if (filter.toUtcMillis != null && timestamp > filter.toUtcMillis!) {
        return false;
      }
      if (q != null && q.isNotEmpty && !haystack.toLowerCase().contains(q)) {
        return false;
      }
      return true;
    }

    for (final m in data.movements) {
      if (reversedMovIds.contains(m.id)) continue;
      if (m.movementType != StockMovementType.issue &&
          m.movementType != StockMovementType.settlementLost &&
          m.movementType != StockMovementType.settlementShortage) {
        continue;
      }
      final lotNum = data.lots[m.lotId]?.entity.lotNumber ?? m.lotId;
      final design = data.designs[m.lotDesignId]?.designName ?? '-';
      final colour = data.colours[m.designColourId]?.colourName ?? '-';
      final proc = m.processId != null
          ? data.processes[m.processId!]?.name
          : null;
      final worker = m.memberId != null
          ? data.workers[m.memberId!]?.name
          : null;
      final hay =
          '$lotNum $design $colour ${proc ?? ''} ${worker ?? ''} ${m.notes ?? ''}';
      if (!matchesDims(
        lotId: m.lotId,
        workerId: m.memberId,
        processId: m.processId,
        timestamp: m.transactionAt,
        haystack: hay,
      )) {
        continue;
      }
      feed.add(
        ProductionHistoryFeedItem(
          id: 'sm_${m.id}',
          transactionKind: ProductionTransactionKind.stockMovement,
          transactionId: m.id,
          title: m.movementType == StockMovementType.issue
              ? '${proc ?? 'Process'} Issued • $lotNum'
              : '${m.movementType.dbValue} • $lotNum',
          subtitle: '${worker ?? '-'} • $design / $colour',
          badgeLabel: m.movementType == StockMovementType.issue
              ? 'ISSUED'
              : m.movementType.dbValue,
          traceCode: m.movementType == StockMovementType.issue
              ? 'feed_issue'
              : 'feed_movement',
          badgeCode: m.movementType == StockMovementType.issue
              ? 'issued'
              : 'movement',
          traceArgs: {'movementType': m.movementType},
          isWarning: m.movementType != StockMovementType.issue,
          isPositive: false,
          timestampUtcMillis: m.transactionAt,
          quantity: m.quantity,
          ratePaise: m.appliedRatePaise,
          lotId: m.lotId,
          lotNumber: lotNum,
          designName: design,
          colourName: colour,
          processId: m.processId,
          processName: proc,
          workerId: m.memberId,
          workerName: worker,
          actor: m.createdBy,
          notes: m.notes,
        ),
      );
    }

    for (final ret in data.returns) {
      final lotNum = data.lots[ret.lotId]?.entity.lotNumber ?? ret.lotId;
      final design = data.designs[ret.lotDesignId]?.designName ?? '-';
      final colour = data.colours[ret.designColourId]?.colourName ?? '-';
      final proc = data.processes[ret.processId]?.name;
      final worker = data.workers[ret.memberId]?.name;
      final hay =
          '$lotNum $design $colour ${proc ?? ''} ${worker ?? ''} ${ret.notes ?? ''}';
      if (!matchesDims(
        lotId: ret.lotId,
        workerId: ret.memberId,
        processId: ret.processId,
        timestamp: ret.transactionAt,
        haystack: hay,
      )) {
        continue;
      }
      feed.add(
        ProductionHistoryFeedItem(
          id: 'pr_${ret.id}',
          transactionKind: ProductionTransactionKind.productionReturn,
          transactionId: ret.id,
          title: '${proc ?? 'Process'} Return • $lotNum',
          subtitle: '${worker ?? '-'} • $design / $colour',
          badgeLabel: ret.returnMode == ProductionReturnMode.pendingInspection
              ? 'PENDING QC'
              : 'RETURNED',
          traceCode: 'feed_return',
          badgeCode: ret.returnMode == ProductionReturnMode.pendingInspection
              ? 'pending_qc'
              : 'returned',
          isWarning: ret.returnMode == ProductionReturnMode.pendingInspection,
          isPositive: false,
          timestampUtcMillis: ret.transactionAt,
          quantity: ret.returnedQuantity,
          lotId: ret.lotId,
          lotNumber: lotNum,
          designName: design,
          colourName: colour,
          processId: ret.processId,
          processName: proc,
          workerId: ret.memberId,
          workerName: worker,
          actor: ret.createdBy,
          notes: ret.notes,
        ),
      );
    }

    for (final insp in data.inspections) {
      final lotNum = data.lots[insp.lotId]?.entity.lotNumber ?? insp.lotId;
      final design = data.designs[insp.lotDesignId]?.designName ?? '-';
      final colour = data.colours[insp.designColourId]?.colourName ?? '-';
      final proc = data.processes[insp.processId]?.name;
      final worker = data.workers[insp.memberId]?.name;
      final hay =
          '$lotNum $design $colour ${proc ?? ''} ${worker ?? ''} ${insp.rejectionReason ?? ''} ${insp.notes ?? ''}';
      if (!matchesDims(
        lotId: insp.lotId,
        workerId: insp.memberId,
        processId: insp.processId,
        timestamp: insp.transactionAt,
        haystack: hay,
      )) {
        continue;
      }
      final isRe = insp.inspectionType == ProductionInspectionType.reinspection;
      feed.add(
        ProductionHistoryFeedItem(
          id: 'pi_${insp.id}',
          transactionKind: ProductionTransactionKind.inspection,
          transactionId: insp.id,
          title: isRe
              ? 'Re-Inspection • $lotNum (${proc ?? ''})'
              : 'QC Inspection • $lotNum (${proc ?? ''})',
          subtitle:
              '${worker ?? '-'} • Acc: ${insp.acceptedQuantity}, Rej: ${insp.rejectedQuantity}',
          badgeLabel: isRe ? 'RE-APPROVED' : 'INSPECTED',
          traceCode: isRe ? 'feed_reinspection' : 'feed_inspection',
          badgeCode: isRe ? 'reapproved' : 'inspected',
          traceArgs: {
            'acc': insp.acceptedQuantity,
            'rej': insp.rejectedQuantity,
          },
          isWarning: insp.rejectedQuantity > 0 && insp.acceptedQuantity == 0,
          isPositive: insp.acceptedQuantity > 0,
          timestampUtcMillis: insp.transactionAt,
          quantity: insp.totalInspectedQuantity,
          ratePaise: insp.lockedRatePaise,
          amountPaise: insp.earnedAmountPaise,
          lotId: insp.lotId,
          lotNumber: lotNum,
          designName: design,
          colourName: colour,
          processId: insp.processId,
          processName: proc,
          workerId: insp.memberId,
          workerName: worker,
          actor: insp.approvedBy ?? insp.inspectedBy,
          notes: insp.rejectionReason ?? insp.notes,
        ),
      );
    }

    feed.sort((a, b) => b.timestampUtcMillis.compareTo(a.timestampUtcMillis));

    final safePage = filter.page < 0 ? 0 : filter.page;
    final safePageSize = filter.pageSize <= 0 ? 30 : filter.pageSize;
    final start = safePage * safePageSize;
    final paged = start >= feed.length
        ? const <ProductionHistoryFeedItem>[]
        : feed.skip(start).take(safePageSize).toList(growable: false);

    return ProductionHistoryDashboardData(
      totalLots: lotIds.length,
      totalAssignedQty: assigned,
      totalReturnedQty: returned,
      totalAcceptedQty: accepted,
      totalRejectedQty: rejected,
      totalPendingInspectionQty: pendingInsp,
      totalOutstandingQty: outstanding,
      totalEarnedPaise: earned,
      totalPaidPaise: paid,
      totalOutstandingPayablePaise: outstandingPayable,
      pendingReturnsCount: pendingReturns.length,
      openRejectionsCount: openRejections.length,
      items: paged,
      totalItemsCount: feed.length,
      page: safePage,
      pageSize: safePageSize,
      hasMore: start + paged.length < feed.length,
      assignments: assignments,
    );
  }
}
