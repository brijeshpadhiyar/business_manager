import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/stock_movements/domain/calculators/stock_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';

/// Live progress of one Routing operation (`job_processes` row), derived only
/// from the Stock ledger. Routing never stores its own quantities or money.
final class JobProcessProgress {
  const JobProcessProgress({
    required this.issueIds,
    required this.openIssueIds,
    required this.withWorkerByIssue,
    required this.dispatchedQuantity,
    required this.goodReturnedQuantity,
    required this.returnedToFactoryQuantity,
    required this.transferredOutQuantity,
    required this.damagedQuantity,
    required this.lostShortageQuantity,
    required this.pendingInspectionQuantity,
    required this.withWorkerQuantity,
    required this.payableAmountPaise,
  });

  static const empty = JobProcessProgress(
    issueIds: [],
    openIssueIds: [],
    withWorkerByIssue: {},
    dispatchedQuantity: 0,
    goodReturnedQuantity: 0,
    returnedToFactoryQuantity: 0,
    transferredOutQuantity: 0,
    damagedQuantity: 0,
    lostShortageQuantity: 0,
    pendingInspectionQuantity: 0,
    withWorkerQuantity: 0,
    payableAmountPaise: 0,
  );

  /// Every active (non-reversed) ISSUE of this operation, oldest first.
  final List<String> issueIds;

  /// Issues that still have pieces with the worker, oldest first (FIFO).
  final List<String> openIssueIds;

  /// Pieces still with the worker per open ISSUE.
  final Map<String, int> withWorkerByIssue;
  final int dispatchedQuantity;
  final int goodReturnedQuantity;
  final int returnedToFactoryQuantity;
  final int transferredOutQuantity;
  final int damagedQuantity;
  final int lostShortageQuantity;
  final int pendingInspectionQuantity;
  final int withWorkerQuantity;

  /// Net payable labour (accepted qty x locked per-piece rate, minus reversals).
  final int payableAmountPaise;
}

/// Pure Dart; no Drift or Flutter imports.
final class JobProcessProgressCalculator {
  const JobProcessProgressCalculator();

  static const StockCalculator _stockCalc = StockCalculator();

  /// [movementsForColour] are ALL movements of the operation's colour.
  /// [legacyLinkedIssueId] covers rows created before `job_process_id` was
  /// written on every ISSUE. [directTransferOutQty] is the total moved to the
  /// next worker through Routing's direct transfer (recorded in Stock as a
  /// good return followed by a new issue).
  JobProcessProgress calculate({
    required String jobProcessId,
    required List<StockMovementEntity> movementsForColour,
    required Map<String, int> pendingInspectionByIssue,
    required List<LabourEntryEntity> labourEntries,
    String? legacyLinkedIssueId,
    int directTransferOutQty = 0,
  }) {
    final reversed = _stockCalc.reversedMovementIds(movementsForColour);
    final issues =
        movementsForColour
            .where(
              (m) =>
                  m.movementType == StockMovementType.issue &&
                  !reversed.contains(m.id) &&
                  (m.jobProcessId == jobProcessId ||
                      (legacyLinkedIssueId != null &&
                          m.id == legacyLinkedIssueId)),
            )
            .toList()
          ..sort((a, b) {
            final c = a.transactionAt.compareTo(b.transactionAt);
            if (c != 0) return c;
            final r = a.recordedAt.compareTo(b.recordedAt);
            return r != 0 ? r : a.id.compareTo(b.id);
          });
    if (issues.isEmpty) return JobProcessProgress.empty;

    final issueIds = {for (final i in issues) i.id};
    var dispatched = 0;
    for (final i in issues) {
      dispatched += i.quantity;
    }

    var good = 0;
    var damaged = 0;
    var lostShortage = 0;
    final settledByIssue = <String, int>{};
    final ownMovementIds = <String>{...issueIds};
    for (final m in movementsForColour) {
      if (m.parentIssueId == null || !issueIds.contains(m.parentIssueId)) {
        continue;
      }
      ownMovementIds.add(m.id);
      if (reversed.contains(m.id) || !m.movementType.isSettlement) continue;
      settledByIssue[m.parentIssueId!] =
          (settledByIssue[m.parentIssueId!] ?? 0) + m.quantity;
      switch (m.movementType) {
        case StockMovementType.returnGood:
          good += m.quantity;
        case StockMovementType.returnDamaged:
          damaged += m.quantity;
        case StockMovementType.settlementLost:
        case StockMovementType.settlementShortage:
          lostShortage += m.quantity;
        case StockMovementType.issue:
        case StockMovementType.adjustmentDamagedToGood:
        case StockMovementType.reversal:
          break;
      }
    }

    var pendingInspection = 0;
    final openIssueIds = <String>[];
    final withWorkerByIssue = <String, int>{};
    for (final i in issues) {
      final inQc = pendingInspectionByIssue[i.id] ?? 0;
      pendingInspection += inQc;
      final withWorker = i.quantity - (settledByIssue[i.id] ?? 0) - inQc;
      if (withWorker > 0) {
        openIssueIds.add(i.id);
        withWorkerByIssue[i.id] = withWorker;
      }
    }

    final transferredOut = directTransferOutQty.clamp(0, good);
    final withWorker =
        dispatched - good - damaged - lostShortage - pendingInspection;

    var payable = 0;
    for (final l in labourEntries) {
      if (l.isPayable && ownMovementIds.contains(l.stockMovementId)) {
        payable += l.amountPaise;
      }
    }

    return JobProcessProgress(
      issueIds: [for (final i in issues) i.id],
      openIssueIds: openIssueIds,
      withWorkerByIssue: withWorkerByIssue,
      dispatchedQuantity: dispatched,
      goodReturnedQuantity: good,
      returnedToFactoryQuantity: good - transferredOut,
      transferredOutQuantity: transferredOut,
      damagedQuantity: damaged,
      lostShortageQuantity: lostShortage,
      pendingInspectionQuantity: pendingInspection,
      withWorkerQuantity: withWorker < 0 ? 0 : withWorker,
      payableAmountPaise: payable < 0 ? 0 : payable,
    );
  }

  /// Splits [quantity] across [openIssueIds] (FIFO) using each issue's
  /// remaining with-worker quantity, so returns and transfers work no matter
  /// how many dispatch batches the operation had.
  List<({String issueId, int quantity})> allocateFifo({
    required int quantity,
    required List<String> openIssueIds,
    required Map<String, int> withWorkerByIssue,
  }) {
    var left = quantity;
    final out = <({String issueId, int quantity})>[];
    for (final id in openIssueIds) {
      if (left <= 0) break;
      final avail = withWorkerByIssue[id] ?? 0;
      if (avail <= 0) continue;
      final take = avail < left ? avail : left;
      out.add((issueId: id, quantity: take));
      left -= take;
    }
    return out;
  }
}
