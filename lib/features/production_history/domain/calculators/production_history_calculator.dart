import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/features/accounting/domain/calculators/ledger_calculator.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/stock_movements/domain/calculators/stock_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';

/// Pure Dart reconciliation, timeline, and analytics engine for StitchFlow's
/// Complete Production History, Lot Tracking, Worker Account & Process History.
///
/// Guarantees:
/// - Single Source of Truth: derives all quantities, pending inspection counts,
///   rejection/repair balances, and earned amounts directly from immutable
///   transaction rows (`stock_movements`, `production_returns`,
///   `production_inspections`, `rejection_records`, `rejection_repairs`,
///   `labour_entries`, `payments`, `worker_ledger_adjustments`).
/// - 100% backward compatible with pre-v8 legacy returns (movements without
///   `production_returns` / `production_inspections` rows).
/// - Strict conservation of pieces and exact integer paise reconciliation
///   across Lot, Worker, and Process summaries.
final class ProductionHistoryCalculator {
  const ProductionHistoryCalculator();

  static const StockCalculator _stockCalc = StockCalculator();
  static const LedgerCalculator _ledgerCalc = LedgerCalculator();

  /// Computes remaining uninspected pieces for a single [ProductionReturnEntity].
  int remainingPendingInspectionForReturn({
    required ProductionReturnEntity productionReturn,
    required List<ProductionInspectionEntity> inspections,
  }) {
    var inspected = 0;
    for (final insp in inspections) {
      if (insp.inspectionType == ProductionInspectionType.initial &&
          insp.productionReturnId == productionReturn.id) {
        inspected += insp.acceptedQuantity + insp.rejectedQuantity;
      }
    }
    return (productionReturn.returnedQuantity - inspected)
        .clamp(0, productionReturn.returnedQuantity);
  }

  /// Computes pending inspection quantity grouped by `design_colour_id`.
  Map<String, int> pendingInspectionByDesignColour({
    required List<ProductionReturnEntity> returns,
    required List<ProductionInspectionEntity> inspections,
    required Set<String> reversedMovementIds,
  }) {
    final inspectedByReturn = <String, int>{};
    for (final insp in inspections) {
      if (insp.inspectionType == ProductionInspectionType.initial &&
          insp.productionReturnId != null) {
        inspectedByReturn[insp.productionReturnId!] =
            (inspectedByReturn[insp.productionReturnId!] ?? 0) +
            insp.acceptedQuantity +
            insp.rejectedQuantity;
      }
    }

    final byColour = <String, int>{};
    for (final ret in returns) {
      if (reversedMovementIds.contains(ret.parentIssueId)) continue;
      final inspected = inspectedByReturn[ret.id] ?? 0;
      final pending = (ret.returnedQuantity - inspected)
          .clamp(0, ret.returnedQuantity);
      if (pending > 0) {
        byColour[ret.designColourId] =
            (byColour[ret.designColourId] ?? 0) + pending;
      }
    }
    return byColour;
  }

  /// Computes pending inspection quantity grouped by `parentIssueId`.
  Map<String, int> pendingInspectionByIssue({
    required List<ProductionReturnEntity> returns,
    required List<ProductionInspectionEntity> inspections,
    required Set<String> reversedMovementIds,
  }) {
    final inspectedByReturn = <String, int>{};
    for (final insp in inspections) {
      if (insp.inspectionType == ProductionInspectionType.initial &&
          insp.productionReturnId != null) {
        inspectedByReturn[insp.productionReturnId!] =
            (inspectedByReturn[insp.productionReturnId!] ?? 0) +
            insp.acceptedQuantity +
            insp.rejectedQuantity;
      }
    }

    final byIssue = <String, int>{};
    for (final ret in returns) {
      if (reversedMovementIds.contains(ret.parentIssueId)) continue;
      final inspected = inspectedByReturn[ret.id] ?? 0;
      final pending = (ret.returnedQuantity - inspected)
          .clamp(0, ret.returnedQuantity);
      if (pending > 0) {
        byIssue[ret.parentIssueId] =
            (byIssue[ret.parentIssueId] ?? 0) + pending;
      }
    }
    return byIssue;
  }

  /// Validates a new return submission against an `ISSUE` assignment.
  /// Returns `null` if valid, or a machine-readable error code.
  String? validateReturnSubmission({
    required StockMovementEntity parentIssue,
    required int returnedQuantity,
    required int currentOutstandingQty,
    required bool isReversed,
    bool inspectImmediately = false,
    int acceptedQuantity = 0,
    int rejectedQuantity = 0,
    String? rejectionReason,
  }) {
    if (isReversed || parentIssue.movementType != StockMovementType.issue) {
      return 'parent_issue_inactive';
    }
    if (returnedQuantity <= 0) {
      return 'invalid_quantity';
    }
    if (returnedQuantity > currentOutstandingQty) {
      return 'exceeds_pending_quantity';
    }
    if (inspectImmediately) {
      if (acceptedQuantity < 0 || rejectedQuantity < 0) {
        return 'invalid_quantity';
      }
      final inspected = acceptedQuantity + rejectedQuantity;
      if (inspected <= 0) {
        return 'settlement_empty';
      }
      if (inspected > returnedQuantity) {
        return 'exceeds_returned_quantity';
      }
      if (rejectedQuantity > 0 &&
          (rejectionReason == null || rejectionReason.trim().isEmpty)) {
        return 'reason_required';
      }
    }
    return null;
  }

  /// Validates QC inspection on a pending [ProductionReturnEntity].
  String? validateInspectionApproval({
    required int remainingPendingInspectionQty,
    required int acceptedQuantity,
    required int rejectedQuantity,
    String? rejectionReason,
  }) {
    if (acceptedQuantity < 0 || rejectedQuantity < 0) {
      return 'invalid_quantity';
    }
    final total = acceptedQuantity + rejectedQuantity;
    if (total <= 0) {
      return 'settlement_empty';
    }
    if (total > remainingPendingInspectionQty) {
      return 'exceeds_pending_inspection';
    }
    if (rejectedQuantity > 0 &&
        (rejectionReason == null || rejectionReason.trim().isEmpty)) {
      return 'reason_required';
    }
    return null;
  }

  /// Validates submitting a repair operation against a [RejectionRecordEntity].
  String? validateRepairSubmission({
    required int openUnrepairedQty,
    required int repairedQuantity,
  }) {
    if (repairedQuantity <= 0) return 'invalid_quantity';
    if (repairedQuantity > openUnrepairedQty) {
      return 'exceeds_rejected_quantity';
    }
    return null;
  }

  /// Validates reinspection & re-approval of a [RejectionRepairEntity].
  String? validateRepairReinspection({
    required int pendingReinspectionQty,
    required int acceptedQuantity,
    required int rejectedAgainQuantity,
    String? rejectionReason,
  }) {
    if (acceptedQuantity < 0 || rejectedAgainQuantity < 0) {
      return 'invalid_quantity';
    }
    final total = acceptedQuantity + rejectedAgainQuantity;
    if (total <= 0) return 'settlement_empty';
    if (total > pendingReinspectionQty) {
      return 'exceeds_repaired_quantity';
    }
    if (rejectedAgainQuantity > 0 &&
        (rejectionReason == null || rejectionReason.trim().isEmpty)) {
      return 'reason_required';
    }
    return null;
  }

  /// Reconciles every non-reversed `ISSUE` assignment across the dataset.
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
        childMovementsByIssue
            .putIfAbsent(m.parentIssueId!, () => [])
            .add(m);
      }
    }

    // Map active payable labour by stockMovementId for exact earning reconciliation.
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

      // Include legacy pre-v8 settlements that were recorded directly in
      // stock_movements before production_returns/production_inspections existed.
      var legacyGood = 0;
      var legacyDamaged = 0;
      var lost = 0;
      var shortage = 0;
      var earnedPaise = payableLabourByMovement[issue.id] ?? 0;

      for (final child in issueChildren) {
        if (child.transactionAt > lastEventAt) lastEventAt = child.transactionAt;
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
          (returnedViaV8 - (acceptedInitial + rejectedInitial))
              .clamp(0, returnedViaV8);
      final outstanding =
          (issue.quantity - totalReturned - lost - shortage)
              .clamp(0, issue.quantity);

      // Pending reinspection across all repairs linked to this issue's rejections.
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

  /// Builds enriched pending return views awaiting QC inspection.
  List<PendingReturnView> buildPendingReturns(
    ProductionHistoryDataset data, {
    String? lotId,
    String? workerId,
    String? processId,
  }) {
    final reversedMovIds = _stockCalc.reversedMovementIds(data.movements);
    final issueById = {for (final m in data.movements) m.id: m};
    final inspectionsByReturn = <String, List<ProductionInspectionEntity>>{};
    for (final insp in data.inspections) {
      if (insp.inspectionType == ProductionInspectionType.initial &&
          insp.productionReturnId != null) {
        inspectionsByReturn
            .putIfAbsent(insp.productionReturnId!, () => [])
            .add(insp);
      }
    }

    final views = <PendingReturnView>[];
    for (final ret in data.returns) {
      if (reversedMovIds.contains(ret.parentIssueId)) continue;
      if (lotId != null && ret.lotId != lotId) continue;
      if (workerId != null && ret.memberId != workerId) continue;
      if (processId != null && ret.processId != processId) continue;

      final insps = inspectionsByReturn[ret.id] ?? const [];
      var accepted = 0;
      var rejected = 0;
      for (final i in insps) {
        accepted += i.acceptedQuantity;
        rejected += i.rejectedQuantity;
      }
      final pending =
          (ret.returnedQuantity - accepted - rejected).clamp(0, ret.returnedQuantity);
      if (pending <= 0) continue;

      final issue = issueById[ret.parentIssueId];
      final lot = data.lots[ret.lotId];
      final design = data.designs[ret.lotDesignId];
      final colour = data.colours[ret.designColourId];
      final proc = data.processes[ret.processId];
      final worker = data.workers[ret.memberId];

      views.add(
        PendingReturnView(
          productionReturn: ret,
          lotNumber: lot?.entity.lotNumber ?? ret.lotId,
          designName: design?.designName ?? '-',
          colourName: colour?.colourName ?? '-',
          colourHex: colour?.colourHex,
          processName: proc?.name ?? ret.processId,
          workerName: worker?.name ?? ret.memberId,
          lockedRatePaise: issue?.appliedRatePaise ?? 0,
          inspectedAcceptedQty: accepted,
          inspectedRejectedQty: rejected,
          remainingPendingInspectionQty: pending,
        ),
      );
    }

    views.sort(
      (a, b) => b.productionReturn.transactionAt
          .compareTo(a.productionReturn.transactionAt),
    );
    return views;
  }

  /// Builds enriched rejection record views with repair & reinspection balances.
  List<RejectionRecordView> buildRejectionViews(
    ProductionHistoryDataset data, {
    String? lotId,
    String? workerId,
    String? processId,
    bool onlyOpen = false,
  }) {
    final issueById = {for (final m in data.movements) m.id: m};
    final repairsByRejection = <String, List<RejectionRepairEntity>>{};
    for (final r in data.repairs) {
      repairsByRejection.putIfAbsent(r.rejectionRecordId, () => []).add(r);
    }
    final reinspectionsByRepair = <String, List<ProductionInspectionEntity>>{};
    for (final i in data.inspections) {
      if (i.inspectionType == ProductionInspectionType.reinspection &&
          i.rejectionRepairId != null) {
        reinspectionsByRepair
            .putIfAbsent(i.rejectionRepairId!, () => [])
            .add(i);
      }
    }

    final views = <RejectionRecordView>[];
    for (final rej in data.rejections) {
      if (lotId != null && rej.lotId != lotId) continue;
      if (workerId != null && rej.memberId != workerId) continue;
      if (processId != null && rej.processId != processId) continue;

      final repairs = repairsByRejection[rej.id] ?? const [];
      var totalSubmitted = 0;
      var totalReapproved = 0;
      var totalRejectedAgain = 0;
      var pendingReinspection = 0;
      final repairViews = <RejectionRepairView>[];

      for (final rep in repairs) {
        totalSubmitted += rep.repairedQuantity;
        final insps = reinspectionsByRepair[rep.id] ?? const [];
        var repAcc = 0;
        var repRej = 0;
        for (final ins in insps) {
          repAcc += ins.acceptedQuantity;
          repRej += ins.rejectedQuantity;
        }
        final repPending = (rep.repairedQuantity - repAcc - repRej)
            .clamp(0, rep.repairedQuantity);
        totalReapproved += repAcc;
        totalRejectedAgain += repRej;
        pendingReinspection += repPending;
        repairViews.add(
          RejectionRepairView(
            repair: rep,
            reapprovedQty: repAcc,
            rejectedAgainQty: repRej,
            pendingReinspectionQty: repPending,
          ),
        );
      }

      // Failed reinspections return pieces to the open pool (still defective),
      // so openUnrepaired = rejectedQty - totalReapproved - pendingReinspection.
      final openUnrepaired = (rej.rejectedQuantity -
              totalReapproved -
              pendingReinspection)
          .clamp(0, rej.rejectedQuantity);
      // Guard against over-submission while keeping exact remaining open count.
      final _ = totalRejectedAgain;

      if (onlyOpen && openUnrepaired == 0 && pendingReinspection == 0) {
        continue;
      }

      final issue = issueById[rej.parentIssueId];
      final lot = data.lots[rej.lotId];
      final design = data.designs[rej.lotDesignId];
      final colour = data.colours[rej.designColourId];
      final proc = data.processes[rej.processId];
      final worker = data.workers[rej.memberId];

      views.add(
        RejectionRecordView(
          record: rej,
          lotNumber: lot?.entity.lotNumber ?? rej.lotId,
          designName: design?.designName ?? '-',
          colourName: colour?.colourName ?? '-',
          colourHex: colour?.colourHex,
          processName: proc?.name ?? rej.processId,
          workerName: worker?.name ?? rej.memberId,
          lockedRatePaise: issue?.appliedRatePaise ?? 0,
          totalRepairedSubmittedQty: totalSubmitted,
          totalReapprovedQty: totalReapproved,
          pendingReinspectionQty: pendingReinspection,
          openUnrepairedQty: openUnrepaired,
          repairs: repairViews,
        ),
      );
    }

    views.sort(
      (a, b) => b.record.inspectedAt.compareTo(a.record.inspectedAt),
    );
    return views;
  }

  /// Builds Complete Lot History & Chronological Timeline for a single Lot.
  LotCompleteHistory? buildLotCompleteHistory(
    String lotId,
    ProductionHistoryDataset data,
  ) {
    final lotEntry = data.lots[lotId];
    if (lotEntry == null) return null;
    final lot = lotEntry.entity;

    final reversedMovIds = _stockCalc.reversedMovementIds(data.movements);
    final pendingByColour = pendingInspectionByDesignColour(
      returns: data.returns,
      inspections: data.inspections,
      reversedMovementIds: reversedMovIds,
    );

    final lotMovements =
        data.movements.where((m) => m.lotId == lotId).toList();
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
    final rejections = buildRejectionViews(data, lotId: lotId);
    final pendingReturns = buildPendingReturns(data, lotId: lotId);

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

  /// Builds chronological exact-timestamp event timeline for a single Lot.
  List<LotTimelineEvent> buildLotTimeline(
    String lotId,
    ProductionHistoryDataset data,
  ) {
    final lotEntry = data.lots[lotId];
    if (lotEntry == null) return const [];
    final lot = lotEntry.entity;
    final events = <LotTimelineEvent>[];

    // 1. Lot created
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

    // 2. Stock movements (Issues, legacy returns, lost/shortage, reversals)
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

    // 3. Schema v8 Production Returns
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

    // 4. Schema v8 Inspections & Reinspections
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

    // 5. Rejection Repairs
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

    // 6. Direct Worker-to-Worker Handovers
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

    // 7. Lot Completed marker
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
      final tsCmp = a.timestampUtcMillis.compareTo(b.timestampUtcMillis);
      if (tsCmp != 0) return tsCmp;
      final recCmp = a.recordedAtUtcMillis.compareTo(b.recordedAtUtcMillis);
      if (recCmp != 0) return recCmp;
      return a.id.compareTo(b.id);
    });
    return events;
  }

  /// Builds Complete Worker Account Profile (Phase 3) with exact ledger &
  /// process-wise grouping reconciliation.
  WorkerCompleteProfile? buildWorkerCompleteProfile(
    String workerId,
    ProductionHistoryDataset data, {
    ProductionHistoryFilter? filter,
  }) {
    final w = data.workers[workerId];
    if (w == null) return null;

    final assignments = buildAssignments(
      data,
      filter: (filter ?? const ProductionHistoryFilter())
          .copyWith(workerId: workerId),
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
    final rejections = buildRejectionViews(data, workerId: workerId);
    final pendingReturns = buildPendingReturns(data, workerId: workerId);

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

    // Proportional outstanding attribution per process (reconciles cleanly with
    // worker's overall outstandingPayablePaise while showing exact process earnings).
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

  /// Builds Complete Process-wise History (Phase 4) across all processes or
  /// for a single process, preserving deactivated processes with history.
  List<ProcessCompleteHistory> buildAllProcessHistories(
    ProductionHistoryDataset data, {
    ProductionHistoryFilter? filter,
  }) {
    final allAssignments = buildAssignments(data, filter: filter);
    final byProc = <String, List<AssignmentReconciliationSummary>>{};
    for (final a in allAssignments) {
      byProc.putIfAbsent(a.processId, () => []).add(a);
    }

    // Precompute worker outstanding ratio for fair non-fabricated payment estimates.
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
            (fin.earnedLabourPaise - fin.outstandingPayablePaise)
                .clamp(0, fin.earnedLabourPaise) /
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
        estPaidPaise +=
            (a.earnedAmountPaise * (workerRatio[a.workerId] ?? 0.0)).round();

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
      }).toList()
        ..sort((a, b) => b.assignedQty.compareTo(a.assignedQty));

      final workerRows = byWorker.entries.map((e) {
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
          earnedAmountPaise: items.fold(0, (s, x) => s + x.earnedAmountPaise),
        );
      }).toList()
        ..sort((a, b) => b.earnedAmountPaise.compareTo(a.earnedAmountPaise));

      final dateRows = byDate.entries
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

      final rejections = buildRejectionViews(data, processId: procId);

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

  /// Builds paginated Production History Dashboard data with reconciled KPIs.
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

    // Reconcile paid & outstanding across filtered workers
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

    // Build unified chronological feed across issues, returns, inspections, repairs
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
      final proc = m.processId != null ? data.processes[m.processId!]?.name : null;
      final worker = m.memberId != null ? data.workers[m.memberId!]?.name : null;
      final hay = '$lotNum $design $colour ${proc ?? ''} ${worker ?? ''} ${m.notes ?? ''}';
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
      final hay = '$lotNum $design $colour ${proc ?? ''} ${worker ?? ''} ${ret.notes ?? ''}';
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

final class _DateBucket {
  int assigned = 0;
  int returned = 0;
  int accepted = 0;
  int rejected = 0;
  int earned = 0;
}
