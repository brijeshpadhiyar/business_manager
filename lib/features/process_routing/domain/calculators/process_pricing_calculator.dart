import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';

/// Pure Dart exact integer-paise pricing & cost breakdown engine for
/// Multi-Process assignments, configurable pricing units, additional charges,
/// deductions, and payment status reconciliation.
final class ProcessPricingCalculator {
  const ProcessPricingCalculator();

  static const String unitPerPiece = 'PER_PIECE';
  static const String unitPerDozen = 'PER_DOZEN';
  static const String unitPerLot = 'PER_LOT';
  static const String unitFixedAmount = 'FIXED_AMOUNT';

  static const List<String> standardUnits = [
    unitPerPiece,
    unitPerDozen,
    unitPerLot,
    unitFixedAmount,
  ];

  static String unitLabel(String unit) => switch (unit.toUpperCase()) {
    unitPerPiece => 'Per Piece',
    unitPerDozen => 'Per Dozen',
    unitPerLot => 'Per Lot',
    unitFixedAmount => 'Fixed Amount',
    _ => unit,
  };

  /// Computes exact base payable amount in integer paise without floating-point
  /// rounding drift. For `PER_DOZEN`, uses half-up integer division.
  int calculateBaseAmountPaise({
    required int quantity,
    required int ratePaise,
    required String pricingUnit,
  }) {
    if (quantity <= 0 || ratePaise <= 0) return 0;
    return switch (pricingUnit.toUpperCase()) {
      unitPerPiece => quantity * ratePaise,
      unitPerDozen => (quantity * ratePaise + 6) ~/ 12,
      unitPerLot || unitFixedAmount => ratePaise,
      _ => quantity * ratePaise,
    };
  }

  /// Derives the equivalent per-piece integer paise rate for synchronizing
  /// `stock_movements.applied_rate_paise` cleanly.
  int effectivePerPieceRatePaise({
    required int quantity,
    required int ratePaise,
    required String pricingUnit,
  }) {
    if (quantity <= 0 || ratePaise <= 0) return 0;
    final total = calculateBaseAmountPaise(
      quantity: quantity,
      ratePaise: ratePaise,
      pricingUnit: pricingUnit,
    );
    return (total + (quantity ~/ 2)) ~/ quantity;
  }

  /// Resolves `PENDING` / `PARTIALLY_PAID` / `PAID` payment status.
  ProcessPaymentStatus resolvePaymentStatus({
    required int netPayablePaise,
    required int paidPaise,
  }) {
    if (netPayablePaise <= 0) return ProcessPaymentStatus.paid;
    if (paidPaise <= 0) return ProcessPaymentStatus.pending;
    if (paidPaise >= netPayablePaise) return ProcessPaymentStatus.paid;
    return ProcessPaymentStatus.partiallyPaid;
  }

  /// Computes complete worker-wise, process-wise, design-wise, colour-wise,
  /// and lot-wise cost & payment summaries.
  JobCostSummary calculateJobCostSummary({
    required List<JobProcessEntity> jobProcesses,
    required List<ProcessAdditionalChargeEntity> charges,
  }) {
    final activeOps = jobProcesses
        .where((p) => p.status != JobProcessStatus.cancelled)
        .toList();

    final chargesByJp = <String, List<ProcessAdditionalChargeEntity>>{};
    for (final c in charges) {
      chargesByJp.putIfAbsent(c.jobProcessId, () => []).add(c);
    }

    final workerAccum = <String, _WorkerCostAccum>{};
    final processAccum = <String, _BucketCostAccum>{};
    final designAccum = <String, _BucketCostAccum>{};
    final colourAccum = <String, _BucketCostAccum>{};

    var totalBase = 0;
    var totalExtra = 0;
    var totalDeductions = 0;
    var totalPaid = 0;

    for (final op in activeOps) {
      final opCharges = chargesByJp[op.id] ?? const [];
      var opExtra = 0;
      var opDeduct = 0;
      for (final c in opCharges) {
        if (c.chargeType == ProcessChargeType.extraCharge) {
          opExtra += c.amountPaise;
        } else {
          opDeduct += c.amountPaise;
        }
      }

      final opBase = op.payableAmountPaise;
      final opNet = (opBase + opExtra - opDeduct).clamp(0, 1 << 62);
      final qty = op.dispatchedQuantity > 0
          ? op.dispatchedQuantity
          : op.plannedQuantity;

      totalBase += opBase;
      totalExtra += opExtra;
      totalDeductions += opDeduct;
      totalPaid += op.paidAmountPaise;

      if (op.memberId != null) {
        final w = workerAccum.putIfAbsent(
          op.memberId!,
          () => _WorkerCostAccum(op.memberId!, op.workerName ?? op.memberId!),
        );
        w.quantity += qty;
        w.basePaise += opBase;
        w.extraPaise += opExtra;
        w.deductionPaise += opDeduct;
        w.paidPaise += op.paidAmountPaise;
      }

      final p = processAccum.putIfAbsent(
        op.processId,
        () => _BucketCostAccum(op.processId, op.processName),
      );
      p.quantity += qty;
      p.costPaise += opNet;

      final designLabel = op.isColourOnly ? 'Colour-Only' : op.designName;
      final d = designAccum.putIfAbsent(
        op.lotDesignId,
        () => _BucketCostAccum(op.lotDesignId, designLabel),
      );
      d.quantity += qty;
      d.costPaise += opNet;

      final col = colourAccum.putIfAbsent(
        op.designColourId,
        () => _BucketCostAccum(op.designColourId, op.variantLabel),
      );
      col.quantity += qty;
      col.costPaise += opNet;
    }

    final workerPayables = workerAccum.values.map((w) {
      final net = (w.basePaise + w.extraPaise - w.deductionPaise).clamp(
        0,
        1 << 62,
      );
      final outstanding = (net - w.paidPaise).clamp(0, 1 << 62);
      return WorkerCostBreakdown(
        workerId: w.id,
        workerName: w.name,
        totalQuantity: w.quantity,
        basePayablePaise: w.basePaise,
        additionalChargesPaise: w.extraPaise,
        deductionsPaise: w.deductionPaise,
        netPayablePaise: net,
        paidPaise: w.paidPaise,
        outstandingPaise: outstanding,
        paymentStatus: resolvePaymentStatus(
          netPayablePaise: net,
          paidPaise: w.paidPaise,
        ),
      );
    }).toList()..sort((a, b) => b.netPayablePaise.compareTo(a.netPayablePaise));

    List<CostBucketSummary> toList(Map<String, _BucketCostAccum> m) =>
        m.values
            .map(
              (b) => CostBucketSummary(
                id: b.id,
                label: b.label,
                quantity: b.quantity,
                totalCostPaise: b.costPaise,
              ),
            )
            .toList()
          ..sort((a, b) => b.totalCostPaise.compareTo(a.totalCostPaise));

    final netTotal = (totalBase + totalExtra - totalDeductions).clamp(
      0,
      1 << 62,
    );
    final outstandingTotal = (netTotal - totalPaid).clamp(0, 1 << 62);

    return JobCostSummary(
      totalBasePaise: totalBase,
      totalAdditionalChargesPaise: totalExtra,
      totalDeductionsPaise: totalDeductions,
      totalNetCostPaise: netTotal,
      totalPaidPaise: totalPaid,
      totalOutstandingPaise: outstandingTotal,
      workerPayables: workerPayables,
      processExpenses: toList(processAccum),
      designCosts: toList(designAccum),
      colourCosts: toList(colourAccum),
    );
  }
}

final class _WorkerCostAccum {
  _WorkerCostAccum(this.id, this.name);
  final String id;
  final String name;
  int quantity = 0;
  int basePaise = 0;
  int extraPaise = 0;
  int deductionPaise = 0;
  int paidPaise = 0;
}

final class _BucketCostAccum {
  _BucketCostAccum(this.id, this.label);
  final String id;
  final String label;
  int quantity = 0;
  int costPaise = 0;
}
