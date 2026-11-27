import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/stock_movements/domain/calculators/stock_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';

/// Pure-Dart QC pending counts, submission validators, and rejection/repair
/// view builders extracted from [ProductionHistoryCalculator].
final class ProductionInspectionCalculator {
  const ProductionInspectionCalculator({
    StockCalculator stockCalculator = const StockCalculator(),
  }) : _stockCalc = stockCalculator;

  final StockCalculator _stockCalc;

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
    return (productionReturn.returnedQuantity - inspected).clamp(
      0,
      productionReturn.returnedQuantity,
    );
  }

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
      final pending = (ret.returnedQuantity - inspected).clamp(
        0,
        ret.returnedQuantity,
      );
      if (pending > 0) {
        byColour[ret.designColourId] =
            (byColour[ret.designColourId] ?? 0) + pending;
      }
    }
    return byColour;
  }

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
      final pending = (ret.returnedQuantity - inspected).clamp(
        0,
        ret.returnedQuantity,
      );
      if (pending > 0) {
        byIssue[ret.parentIssueId] =
            (byIssue[ret.parentIssueId] ?? 0) + pending;
      }
    }
    return byIssue;
  }

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
      final pending = (ret.returnedQuantity - accepted - rejected).clamp(
        0,
        ret.returnedQuantity,
      );
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
      (a, b) => b.productionReturn.transactionAt.compareTo(
        a.productionReturn.transactionAt,
      ),
    );
    return views;
  }

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
        final repPending = (rep.repairedQuantity - repAcc - repRej).clamp(
          0,
          rep.repairedQuantity,
        );
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

      final openUnrepaired =
          (rej.rejectedQuantity - totalReapproved - pendingReinspection).clamp(
            0,
            rej.rejectedQuantity,
          );
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

    views.sort((a, b) => b.record.inspectedAt.compareTo(a.record.inspectedAt));
    return views;
  }
}
