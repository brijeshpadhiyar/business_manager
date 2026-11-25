import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';

/// Pure Dart deterministic inventory & reversal validation calculator
/// implementing `docs/09_stock_calculation_rules.md` and
/// `docs/24_FINAL_TECHNICAL_SAFEGUARDS.md`.
///
/// Zero Flutter, Drift, or BLoC dependencies.
final class StockCalculator {
  const StockCalculator();

  /// Returns the set of movement IDs that have been reversed by a `REVERSAL` row.
  Set<String> reversedMovementIds(List<StockMovementEntity> movements) {
    final reversed = <String>{};
    for (final m in movements) {
      if (m.movementType == StockMovementType.reversal &&
          m.reversesMovementId != null) {
        reversed.add(m.reversesMovementId!);
      }
    }
    return reversed;
  }

  /// Filters [movements] to active (non-reversed, non-reversal) ledger rows,
  /// ordered chronologically (`transactionAt ASC, recordedAt ASC, id ASC`).
  List<StockMovementEntity> activeMovements(
    List<StockMovementEntity> movements,
  ) {
    final reversedIds = reversedMovementIds(movements);
    final active = movements
        .where(
          (m) =>
              m.movementType != StockMovementType.reversal &&
              !reversedIds.contains(m.id),
        )
        .toList();
    active.sort(_chronologicalCompare);
    return active;
  }

  static int _chronologicalCompare(
    StockMovementEntity a,
    StockMovementEntity b,
  ) {
    final txCmp = a.transactionAt.compareTo(b.transactionAt);
    if (txCmp != 0) return txCmp;
    final recCmp = a.recordedAt.compareTo(b.recordedAt);
    if (recCmp != 0) return recCmp;
    return a.id.compareTo(b.id);
  }

  /// Computes exact live stock balances for a single `design_colour_id`.
  DesignColourStockBalance calculateDesignColourBalance({
    required String designColourId,
    required String lotId,
    required String lotNumber,
    required String lotDesignId,
    required String designName,
    required String colourName,
    String? colourHex,
    required int unitPricePaise,
    required int initialQuantity,
    required List<StockMovementEntity> allMovementsForColour,
    Map<String, String> processNamesById = const {},
    int pendingInspectionQuantity = 0,
  }) {
    final active = activeMovements(allMovementsForColour);

    var sumIssue = 0;
    var sumReturnGood = 0;
    var sumReturnDamaged = 0;
    var sumLost = 0;
    var sumShortage = 0;
    var sumRepaired = 0;

    final procAccum = <String, _ProcessAccumulator>{};

    for (final m in active) {
      switch (m.movementType) {
        case StockMovementType.issue:
          sumIssue += m.quantity;
          if (m.processId != null) {
            procAccum
                    .putIfAbsent(m.processId!, () => _ProcessAccumulator())
                    .issued +=
                m.quantity;
          }
        case StockMovementType.returnGood:
          sumReturnGood += m.quantity;
          if (m.processId != null) {
            procAccum
                    .putIfAbsent(m.processId!, () => _ProcessAccumulator())
                    .goodReturned +=
                m.quantity;
          }
        case StockMovementType.returnDamaged:
          sumReturnDamaged += m.quantity;
          if (m.processId != null) {
            procAccum
                    .putIfAbsent(m.processId!, () => _ProcessAccumulator())
                    .damaged +=
                m.quantity;
          }
        case StockMovementType.settlementLost:
          sumLost += m.quantity;
          if (m.processId != null) {
            procAccum
                    .putIfAbsent(m.processId!, () => _ProcessAccumulator())
                    .lost +=
                m.quantity;
          }
        case StockMovementType.settlementShortage:
          sumShortage += m.quantity;
          if (m.processId != null) {
            procAccum
                    .putIfAbsent(m.processId!, () => _ProcessAccumulator())
                    .shortage +=
                m.quantity;
          }
        case StockMovementType.adjustmentDamagedToGood:
          sumRepaired += m.quantity;
        case StockMovementType.reversal:
          break;
      }
    }

    final damagedBucket = sumReturnDamaged - sumRepaired;
    final totalGoodPhysicalStock =
        initialQuantity - damagedBucket - sumLost - sumShortage;
    final safePendingInspection = pendingInspectionQuantity < 0
        ? 0
        : pendingInspectionQuantity;
    final unreturnedAndUninspected =
        sumIssue - (sumReturnGood + sumReturnDamaged + sumLost + sumShortage);
    final totalPendingWithWorkers =
        (unreturnedAndUninspected - safePendingInspection) < 0
        ? 0
        : (unreturnedAndUninspected - safePendingInspection);
    final physicalAvailableInHouse =
        totalGoodPhysicalStock - unreturnedAndUninspected;

    final processBreakdown = procAccum.entries.map((entry) {
      final acc = entry.value;
      return ProcessStockSummary(
        processId: entry.key,
        processName: processNamesById[entry.key] ?? entry.key,
        issued: acc.issued,
        goodReturned: acc.goodReturned,
        damaged: acc.damaged,
        lost: acc.lost,
        shortage: acc.shortage,
        pending:
            acc.issued -
            (acc.goodReturned + acc.damaged + acc.lost + acc.shortage),
      );
    }).toList()..sort((a, b) => a.processName.compareTo(b.processName));

    return DesignColourStockBalance(
      designColourId: designColourId,
      lotId: lotId,
      lotNumber: lotNumber,
      lotDesignId: lotDesignId,
      designName: designName,
      colourName: colourName,
      colourHex: colourHex,
      unitPricePaise: unitPricePaise,
      initialQuantity: initialQuantity,
      damagedBucket: damagedBucket,
      totalLost: sumLost,
      totalShortage: sumShortage,
      totalGoodPhysicalStock: totalGoodPhysicalStock,
      totalPendingWithWorkers: totalPendingWithWorkers,
      totalPendingInspection: safePendingInspection,
      physicalAvailableInHouse: physicalAvailableInHouse,
      totalIssued: sumIssue,
      totalGoodReturned: sumReturnGood,
      totalRepairedToGood: sumRepaired,
      processBreakdown: processBreakdown,
    );
  }

  /// Computes remaining pending quantity for a specific `ISSUE` movement.
  int calculateIssueRemainingPending({
    required StockMovementEntity issue,
    required List<StockMovementEntity> allMovementsForColour,
  }) {
    final reversedIds = reversedMovementIds(allMovementsForColour);
    if (issue.movementType != StockMovementType.issue ||
        reversedIds.contains(issue.id)) {
      return 0;
    }

    var settled = 0;
    for (final m in allMovementsForColour) {
      if (m.parentIssueId == issue.id &&
          m.movementType.isSettlement &&
          !reversedIds.contains(m.id)) {
        settled += m.quantity;
      }
    }
    return issue.quantity - settled;
  }

  /// Computes exact settlement breakdown for a specific `ISSUE` movement.
  ({int good, int damaged, int lost, int shortage, int pending})
  calculateIssueSettlementTotals({
    required StockMovementEntity issue,
    required List<StockMovementEntity> allMovementsForColour,
  }) {
    final reversedIds = reversedMovementIds(allMovementsForColour);
    if (issue.movementType != StockMovementType.issue ||
        reversedIds.contains(issue.id)) {
      return (good: 0, damaged: 0, lost: 0, shortage: 0, pending: 0);
    }

    var good = 0;
    var damaged = 0;
    var lost = 0;
    var shortage = 0;
    for (final m in allMovementsForColour) {
      if (m.parentIssueId != issue.id || reversedIds.contains(m.id)) continue;
      switch (m.movementType) {
        case StockMovementType.returnGood:
          good += m.quantity;
        case StockMovementType.returnDamaged:
          damaged += m.quantity;
        case StockMovementType.settlementLost:
          lost += m.quantity;
        case StockMovementType.settlementShortage:
          shortage += m.quantity;
        case StockMovementType.issue:
        case StockMovementType.adjustmentDamagedToGood:
        case StockMovementType.reversal:
          break;
      }
    }
    final pending = issue.quantity - (good + damaged + lost + shortage);
    return (
      good: good,
      damaged: damaged,
      lost: lost,
      shortage: shortage,
      pending: pending,
    );
  }

  /// Aggregates worker-wise issued/returned/pending totals across all movements.
  List<WorkerStockSummary> calculateWorkerSummaries({
    required List<StockMovementEntity> allMovements,
    required Map<String, String> workerNamesById,
  }) {
    final active = activeMovements(allMovements);
    final issueRemaining = <String, int>{};
    final accum = <String, _ProcessAccumulator>{};

    for (final m in active) {
      if (m.memberId == null) continue;
      final acc = accum.putIfAbsent(m.memberId!, () => _ProcessAccumulator());
      switch (m.movementType) {
        case StockMovementType.issue:
          acc.issued += m.quantity;
          issueRemaining[m.id] = m.quantity;
        case StockMovementType.returnGood:
          acc.goodReturned += m.quantity;
          if (m.parentIssueId != null &&
              issueRemaining.containsKey(m.parentIssueId)) {
            issueRemaining[m.parentIssueId!] =
                issueRemaining[m.parentIssueId!]! - m.quantity;
          }
        case StockMovementType.returnDamaged:
          acc.damaged += m.quantity;
          if (m.parentIssueId != null &&
              issueRemaining.containsKey(m.parentIssueId)) {
            issueRemaining[m.parentIssueId!] =
                issueRemaining[m.parentIssueId!]! - m.quantity;
          }
        case StockMovementType.settlementLost:
          acc.lost += m.quantity;
          if (m.parentIssueId != null &&
              issueRemaining.containsKey(m.parentIssueId)) {
            issueRemaining[m.parentIssueId!] =
                issueRemaining[m.parentIssueId!]! - m.quantity;
          }
        case StockMovementType.settlementShortage:
          acc.shortage += m.quantity;
          if (m.parentIssueId != null &&
              issueRemaining.containsKey(m.parentIssueId)) {
            issueRemaining[m.parentIssueId!] =
                issueRemaining[m.parentIssueId!]! - m.quantity;
          }
        case StockMovementType.adjustmentDamagedToGood:
        case StockMovementType.reversal:
          break;
      }
    }

    final openIssueCountsByWorker = <String, int>{};
    for (final m in active) {
      if (m.movementType == StockMovementType.issue &&
          m.memberId != null &&
          (issueRemaining[m.id] ?? 0) > 0) {
        openIssueCountsByWorker[m.memberId!] =
            (openIssueCountsByWorker[m.memberId!] ?? 0) + 1;
      }
    }

    return accum.entries.map((e) {
      final a = e.value;
      return WorkerStockSummary(
        workerId: e.key,
        workerName: workerNamesById[e.key] ?? e.key,
        issued: a.issued,
        goodReturned: a.goodReturned,
        damaged: a.damaged,
        lost: a.lost,
        shortage: a.shortage,
        pending: a.issued - (a.goodReturned + a.damaged + a.lost + a.shortage),
        openIssuesCount: openIssueCountsByWorker[e.key] ?? 0,
      );
    }).toList()..sort((a, b) => b.pending.compareTo(a.pending));
  }

  /// Aggregates process-wise issued/returned/pending totals across all movements.
  List<ProcessStockSummary> calculateProcessSummaries({
    required List<StockMovementEntity> allMovements,
    required Map<String, String> processNamesById,
  }) {
    final active = activeMovements(allMovements);
    final accum = <String, _ProcessAccumulator>{};

    for (final m in active) {
      if (m.processId == null) continue;
      final acc = accum.putIfAbsent(m.processId!, () => _ProcessAccumulator());
      switch (m.movementType) {
        case StockMovementType.issue:
          acc.issued += m.quantity;
        case StockMovementType.returnGood:
          acc.goodReturned += m.quantity;
        case StockMovementType.returnDamaged:
          acc.damaged += m.quantity;
        case StockMovementType.settlementLost:
          acc.lost += m.quantity;
        case StockMovementType.settlementShortage:
          acc.shortage += m.quantity;
        case StockMovementType.adjustmentDamagedToGood:
        case StockMovementType.reversal:
          break;
      }
    }

    return accum.entries.map((e) {
      final a = e.value;
      return ProcessStockSummary(
        processId: e.key,
        processName: processNamesById[e.key] ?? e.key,
        issued: a.issued,
        goodReturned: a.goodReturned,
        damaged: a.damaged,
        lost: a.lost,
        shortage: a.shortage,
        pending: a.issued - (a.goodReturned + a.damaged + a.lost + a.shortage),
      );
    }).toList()..sort((a, b) => b.pending.compareTo(a.pending));
  }

  /// Validates an `ISSUE` quantity against available in-house good stock.
  /// Returns `null` if valid, or a machine-readable error code.
  String? validateIssueQuantity({
    required int initialQuantity,
    required List<StockMovementEntity> existingMovementsForColour,
    required int issueQuantity,
  }) {
    if (issueQuantity <= 0) return 'invalid_quantity';
    final available = _computeAvailableInHouse(
      initialQuantity: initialQuantity,
      activeMovementsList: activeMovements(existingMovementsForColour),
    );
    if (issueQuantity > available) {
      return 'insufficient_good_stock';
    }
    return null;
  }

  /// Validates a combined partial/complete settlement submission against a parent issue.
  /// Returns `null` if valid, or a machine-readable error code.
  String? validateSettlementBatch({
    required StockMovementEntity parentIssue,
    required List<StockMovementEntity> existingMovementsForColour,
    required int goodQty,
    required int damagedQty,
    required int lostQty,
    required int shortageQty,
    required String? reason,
  }) {
    if (goodQty < 0 || damagedQty < 0 || lostQty < 0 || shortageQty < 0) {
      return 'invalid_quantity';
    }
    final total = goodQty + damagedQty + lostQty + shortageQty;
    if (total <= 0) {
      return 'settlement_empty';
    }
    final hasNonGood = damagedQty > 0 || lostQty > 0 || shortageQty > 0;
    if (hasNonGood && (reason == null || reason.trim().isEmpty)) {
      return 'reason_required';
    }
    final reversedIds = reversedMovementIds(existingMovementsForColour);
    if (parentIssue.movementType != StockMovementType.issue ||
        reversedIds.contains(parentIssue.id)) {
      return 'parent_issue_inactive';
    }
    final remaining = calculateIssueRemainingPending(
      issue: parentIssue,
      allMovementsForColour: existingMovementsForColour,
    );
    if (total > remaining) {
      return 'exceeds_pending_quantity';
    }
    return null;
  }

  /// Validates a damaged-to-good repair adjustment against current damaged bucket.
  String? validateDamagedToGoodAdjustment({
    required int initialQuantity,
    required List<StockMovementEntity> existingMovementsForColour,
    required int quantity,
    required String? reason,
    int reservedForOpenRepairsQty = 0,
  }) {
    if (quantity <= 0) return 'invalid_quantity';
    if (reason == null || reason.trim().isEmpty) return 'reason_required';

    final active = activeMovements(existingMovementsForColour);
    var damaged = 0;
    for (final m in active) {
      if (m.movementType == StockMovementType.returnDamaged) {
        damaged += m.quantity;
      } else if (m.movementType == StockMovementType.adjustmentDamagedToGood) {
        damaged -= m.quantity;
      }
    }
    // Pieces already sent for repair through a rejection record stay in the
    // Damaged bucket until re-inspected; they cannot be repaired twice.
    final reserved = reservedForOpenRepairsQty < 0
        ? 0
        : reservedForOpenRepairsQty;
    if (quantity > damaged - reserved) {
      return 'exceeds_damaged_stock';
    }
    return null;
  }

  /// Chronological Prefix Replay Reversal Guard (`docs/09_stock_calculation_rules.md` Rule 6).
  ///
  /// Simulates removing [targetMovementId] and replays all remaining active
  /// movements in chronological order. Blocks if:
  /// - reason is missing
  /// - target is missing, is itself a REVERSAL, or is already reversed
  /// - target is an ISSUE with active child settlements
  /// - ANY chronological prefix or final state yields negative
  ///   `PhysicalAvailableInHouse`, `DamagedBucket`, or `ParentRemainingPending`.
  StockReversalValidationResult validateReversal({
    required int initialQuantity,
    required List<StockMovementEntity> allMovementsForColour,
    required String targetMovementId,
    required String? reason,
  }) {
    if (reason == null || reason.trim().isEmpty) {
      return const StockReversalBlocked(
        code: 'reason_required',
        message: 'A reason is required to reverse a stock movement.',
      );
    }

    StockMovementEntity? target;
    for (final m in allMovementsForColour) {
      if (m.id == targetMovementId) {
        target = m;
        break;
      }
    }
    if (target == null) {
      return const StockReversalBlocked(
        code: 'movement_not_found',
        message: 'Target stock movement was not found.',
      );
    }
    if (target.movementType == StockMovementType.reversal) {
      return const StockReversalBlocked(
        code: 'cannot_reverse_reversal',
        message: 'A reversal movement cannot itself be reversed.',
      );
    }

    final reversedIds = reversedMovementIds(allMovementsForColour);
    if (reversedIds.contains(target.id)) {
      return const StockReversalBlocked(
        code: 'already_reversed',
        message: 'This stock movement has already been reversed.',
      );
    }

    final remainingActive =
        allMovementsForColour
            .where(
              (m) =>
                  m.id != target!.id &&
                  m.movementType != StockMovementType.reversal &&
                  !reversedIds.contains(m.id),
            )
            .toList()
          ..sort(_chronologicalCompare);

    // Parent issue reversal guard: block if any active child settlement exists
    if (target.movementType == StockMovementType.issue) {
      for (final m in remainingActive) {
        if (m.parentIssueId == target.id) {
          return StockReversalBlocked(
            code: 'issue_has_active_settlements',
            message: 'Reverse all child returns/settlements before reversing this issue.',
            blockingMovementId: m.id,
          );
        }
      }
    }

    // Chronological prefix replay across remaining active movements
    var availableInHouse = initialQuantity;
    var damagedBucket = 0;
    final parentRemaining = <String, int>{};

    for (final m in remainingActive) {
      switch (m.movementType) {
        case StockMovementType.issue:
          availableInHouse -= m.quantity;
          parentRemaining[m.id] = m.quantity;
        case StockMovementType.returnGood:
          availableInHouse += m.quantity;
          if (m.parentIssueId != null) {
            parentRemaining[m.parentIssueId!] =
                (parentRemaining[m.parentIssueId!] ?? 0) - m.quantity;
          }
        case StockMovementType.returnDamaged:
          damagedBucket += m.quantity;
          if (m.parentIssueId != null) {
            parentRemaining[m.parentIssueId!] =
                (parentRemaining[m.parentIssueId!] ?? 0) - m.quantity;
          }
        case StockMovementType.settlementLost:
        case StockMovementType.settlementShortage:
          if (m.parentIssueId != null) {
            parentRemaining[m.parentIssueId!] =
                (parentRemaining[m.parentIssueId!] ?? 0) - m.quantity;
          }
        case StockMovementType.adjustmentDamagedToGood:
          damagedBucket -= m.quantity;
          availableInHouse += m.quantity;
        case StockMovementType.reversal:
          break;
      }

      if (availableInHouse < 0) {
        return StockReversalBlocked(
          code: 'downstream_stock_dependency',
          message:
              'Cannot reverse movement because downstream issue (${m.id}) depends on those good pieces.',
          blockingMovementId: m.id,
        );
      }
      if (damagedBucket < 0) {
        return StockReversalBlocked(
          code: 'downstream_damaged_dependency',
          message:
              'Cannot reverse movement because downstream repair adjustment (${m.id}) depends on those damaged pieces.',
          blockingMovementId: m.id,
        );
      }
      if (m.parentIssueId != null &&
          (parentRemaining[m.parentIssueId!] ?? 0) < 0) {
        return StockReversalBlocked(
          code: 'downstream_parent_dependency',
          message:
              'Cannot reverse movement because downstream settlement (${m.id}) exceeds parent issue quantity.',
          blockingMovementId: m.id,
        );
      }
    }

    return StockReversalAllowed(targetMovement: target);
  }

  int _computeAvailableInHouse({
    required int initialQuantity,
    required List<StockMovementEntity> activeMovementsList,
  }) {
    var available = initialQuantity;
    for (final m in activeMovementsList) {
      switch (m.movementType) {
        case StockMovementType.issue:
          available -= m.quantity;
        case StockMovementType.returnGood:
        case StockMovementType.adjustmentDamagedToGood:
          available += m.quantity;
        case StockMovementType.returnDamaged:
        case StockMovementType.settlementLost:
        case StockMovementType.settlementShortage:
        case StockMovementType.reversal:
          break;
      }
    }
    return available;
  }
}

final class _ProcessAccumulator {
  int issued = 0;
  int goodReturned = 0;
  int damaged = 0;
  int lost = 0;
  int shortage = 0;
}
