import 'dart:math' as math;

import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';

/// Pure Dart worker ledger and financial balance calculator implementing
/// `docs/10_labour_calculation_rules.md` Section 4.
///
/// Guarantees:
/// - Never treats advances as earned labour.
/// - Supports negative net balances (Advance Credit carried forward).
/// - Excludes reversed labour, reversed payments, and reversed adjustments cleanly.
/// - Computes exact chronological running balances in integer paise.
final class LedgerCalculator {
  const LedgerCalculator();

  Set<String> reversedLabourIds(List<LabourEntryEntity> entries) {
    final ids = <String>{};
    for (final e in entries) {
      if (e.basisType == LabourBasisType.reversal &&
          e.reversesLabourEntryId != null) {
        ids.add(e.reversesLabourEntryId!);
      }
    }
    return ids;
  }

  Set<String> reversedPaymentIds(List<PaymentEntity> payments) {
    final ids = <String>{};
    for (final p in payments) {
      if (p.paymentType == PaymentType.reversal &&
          p.reversesPaymentId != null) {
        ids.add(p.reversesPaymentId!);
      }
    }
    return ids;
  }

  Set<String> reversedAdjustmentIds(List<WorkerAdjustmentEntity> adjustments) {
    final ids = <String>{};
    for (final a in adjustments) {
      if (a.adjustmentType == WorkerAdjustmentType.reversal &&
          a.reversesAdjustmentId != null) {
        ids.add(a.reversesAdjustmentId!);
      }
    }
    return ids;
  }

  /// Computes exact financial summary for a worker across all active records.
  WorkerFinancialSummary calculateWorkerSummary({
    required String workerId,
    required String workerName,
    String? workerPhone,
    required bool workerIsActive,
    required List<LabourEntryEntity> labourEntries,
    required List<PaymentEntity> payments,
    required List<WorkerAdjustmentEntity> adjustments,
  }) {
    final revLabour = reversedLabourIds(labourEntries);
    final revPayments = reversedPaymentIds(payments);
    final revAdjustments = reversedAdjustmentIds(adjustments);

    var issuedLabour = 0;
    var receivedLabour = 0;
    var earnedLabour = 0;

    for (final e in labourEntries) {
      if (e.memberId != workerId) continue;
      if (e.basisType == LabourBasisType.reversal || revLabour.contains(e.id)) {
        continue;
      }
      if (e.basisType == LabourBasisType.issued) {
        issuedLabour += e.amountPaise;
      } else if (e.basisType == LabourBasisType.receivedGood ||
          e.basisType == LabourBasisType.receivedDamaged) {
        receivedLabour += e.amountPaise;
      }
      if (e.isPayable) {
        earnedLabour += e.amountPaise;
      }
    }

    var regularPayments = 0;
    var advancePayments = 0;
    var advanceRefunds = 0;

    for (final p in payments) {
      if (p.memberId != workerId) continue;
      if (p.paymentType == PaymentType.reversal || revPayments.contains(p.id)) {
        continue;
      }
      switch (p.paymentType) {
        case PaymentType.regular:
          regularPayments += p.amountPaise;
        case PaymentType.advance:
          advancePayments += p.amountPaise;
        case PaymentType.advanceRefund:
          advanceRefunds += p.amountPaise;
        case PaymentType.reversal:
          break;
      }
    }

    var adjustmentCredits = 0;
    var adjustmentDebits = 0;

    for (final a in adjustments) {
      if (a.memberId != workerId) continue;
      if (a.adjustmentType == WorkerAdjustmentType.reversal ||
          revAdjustments.contains(a.id)) {
        continue;
      }
      switch (a.adjustmentType) {
        case WorkerAdjustmentType.credit:
          adjustmentCredits += a.amountPaise;
        case WorkerAdjustmentType.debit:
          adjustmentDebits += a.amountPaise;
        case WorkerAdjustmentType.reversal:
          break;
      }
    }

    final netPaidToWorker = regularPayments + advancePayments - advanceRefunds;
    final netBalance =
        earnedLabour + adjustmentCredits - adjustmentDebits - netPaidToWorker;
    final outstandingPayable = math.max(0, netBalance);
    final advanceCreditBalance = math.max(0, -netBalance);

    return WorkerFinancialSummary(
      workerId: workerId,
      workerName: workerName,
      workerPhone: workerPhone,
      workerIsActive: workerIsActive,
      totalIssuedLabourPaise: issuedLabour,
      totalReceivedLabourPaise: receivedLabour,
      earnedLabourPaise: earnedLabour,
      adjustmentCreditsPaise: adjustmentCredits,
      adjustmentDebitsPaise: adjustmentDebits,
      regularPaymentsPaise: regularPayments,
      advancePaymentsPaise: advancePayments,
      advanceRefundsPaise: advanceRefunds,
      netPaidToWorkerPaise: netPaidToWorker,
      netBalancePaise: netBalance,
      outstandingPayablePaise: outstandingPayable,
      advanceCreditBalancePaise: advanceCreditBalance,
    );
  }

  /// Builds the full chronological worker ledger with exact running balances.
  ///
  /// When [fromUtcMillis] / [toUtcMillis] are supplied, [openingBalancePaise]
  /// captures the exact cumulative balance prior to [fromUtcMillis], and the
  /// returned [lines] contain entries in the window with true running balances.
  ({int openingBalancePaise, List<WorkerLedgerLine> lines}) buildLedgerLines({
    required String workerId,
    required List<LabourEntryEntity> labourEntries,
    required List<PaymentEntity> payments,
    required List<WorkerAdjustmentEntity> adjustments,
    Map<String, String> processNamesById = const {},
    Map<String, String> lotNumbersById = const {},
    int? fromUtcMillis,
    int? toUtcMillis,
    bool newestFirst = true,
  }) {
    final revLabour = reversedLabourIds(labourEntries);
    final revPayments = reversedPaymentIds(payments);
    final revAdjustments = reversedAdjustmentIds(adjustments);

    final rawItems = <_RawLedgerItem>[];

    // 1. Labour entries (both payable and informational; reversals offset payable)
    for (final e in labourEntries) {
      if (e.memberId != workerId) continue;
      final processName = processNamesById[e.processId] ?? e.processId;
      final lotNum = lotNumbersById[e.lotId] ?? e.lotId;
      final isReversed = revLabour.contains(e.id);

      final WorkerLedgerEntryKind kind;
      final int delta;
      final bool isInfo;
      if (e.basisType == LabourBasisType.reversal) {
        kind = WorkerLedgerEntryKind.labourReversal;
        delta = e.isPayable ? e.amountPaise : 0; // already negative
        isInfo = !e.isPayable;
      } else if (e.isPayable) {
        kind = WorkerLedgerEntryKind.labourPayable;
        delta = e.amountPaise;
        isInfo = false;
      } else {
        kind = WorkerLedgerEntryKind.labourInformational;
        delta = 0;
        isInfo = true;
      }

      rawItems.add(
        _RawLedgerItem(
          id: 'lab_${e.id}',
          sourceEntityId: e.id,
          kind: kind,
          title: '$processName • Lot $lotNum',
          subtitle:
              '${e.quantity.abs()} pcs × ₹${(e.ratePaise / 100).toStringAsFixed(2)}',
          transactionAt: e.transactionAt,
          recordedAt: e.recordedAt,
          amountPaise: e.amountPaise.abs(),
          balanceDeltaPaise: delta,
          isInformational: isInfo,
          isReversed: isReversed,
        ),
      );
    }

    // 2. Payments, Advances, Refunds & Reversals
    final paymentById = {for (final p in payments) p.id: p};
    for (final p in payments) {
      if (p.memberId != workerId) continue;
      final isReversed = revPayments.contains(p.id);

      final WorkerLedgerEntryKind kind;
      final int delta;
      switch (p.paymentType) {
        case PaymentType.regular:
          kind = WorkerLedgerEntryKind.regularPayment;
          delta = -p.amountPaise;
        case PaymentType.advance:
          kind = WorkerLedgerEntryKind.advancePayment;
          delta = -p.amountPaise;
        case PaymentType.advanceRefund:
          kind = WorkerLedgerEntryKind.advanceRefund;
          delta = p.amountPaise;
        case PaymentType.reversal:
          kind = WorkerLedgerEntryKind.paymentReversal;
          final original = paymentById[p.reversesPaymentId];
          delta = switch (original?.paymentType) {
            PaymentType.advanceRefund => -p.amountPaise,
            _ => p.amountPaise,
          };
      }

      rawItems.add(
        _RawLedgerItem(
          id: 'pay_${p.id}',
          sourceEntityId: p.id,
          kind: kind,
          title: p.paymentType.dbValue,
          subtitle: p.referenceNo ?? p.notes,
          transactionAt: p.transactionAt,
          recordedAt: p.recordedAt,
          amountPaise: p.amountPaise,
          balanceDeltaPaise: delta,
          isInformational: false,
          isReversed: isReversed,
          paymentMode: p.paymentMode,
          referenceNo: p.referenceNo,
          reason: p.reason,
          notes: p.notes,
        ),
      );
    }

    // 3. Worker Ledger Adjustments & Reversals
    final adjById = {for (final a in adjustments) a.id: a};
    for (final a in adjustments) {
      if (a.memberId != workerId) continue;
      final isReversed = revAdjustments.contains(a.id);

      final WorkerLedgerEntryKind kind;
      final int delta;
      switch (a.adjustmentType) {
        case WorkerAdjustmentType.credit:
          kind = WorkerLedgerEntryKind.adjustmentCredit;
          delta = a.amountPaise;
        case WorkerAdjustmentType.debit:
          kind = WorkerLedgerEntryKind.adjustmentDebit;
          delta = -a.amountPaise;
        case WorkerAdjustmentType.reversal:
          kind = WorkerLedgerEntryKind.adjustmentReversal;
          final original = adjById[a.reversesAdjustmentId];
          delta = switch (original?.adjustmentType) {
            WorkerAdjustmentType.debit => a.amountPaise,
            _ => -a.amountPaise,
          };
      }

      rawItems.add(
        _RawLedgerItem(
          id: 'adj_${a.id}',
          sourceEntityId: a.id,
          kind: kind,
          title: a.reason,
          subtitle: a.notes,
          transactionAt: a.transactionAt,
          recordedAt: a.recordedAt,
          amountPaise: a.amountPaise,
          balanceDeltaPaise: delta,
          isInformational: false,
          isReversed: isReversed,
          reason: a.reason,
          notes: a.notes,
        ),
      );
    }

    // Sort strictly chronologically to compute accurate running balance
    rawItems.sort((a, b) {
      final txCmp = a.transactionAt.compareTo(b.transactionAt);
      if (txCmp != 0) return txCmp;
      final recCmp = a.recordedAt.compareTo(b.recordedAt);
      if (recCmp != 0) return recCmp;
      return a.id.compareTo(b.id);
    });

    var runningBalance = 0;
    var openingBalance = 0;
    final filteredLines = <WorkerLedgerLine>[];

    for (final item in rawItems) {
      runningBalance += item.balanceDeltaPaise;

      if (fromUtcMillis != null && item.transactionAt < fromUtcMillis) {
        openingBalance = runningBalance;
        continue;
      }
      if (toUtcMillis != null && item.transactionAt > toUtcMillis) {
        continue;
      }

      filteredLines.add(
        WorkerLedgerLine(
          id: item.id,
          sourceEntityId: item.sourceEntityId,
          kind: item.kind,
          title: item.title,
          subtitle: item.subtitle,
          transactionAt: item.transactionAt,
          recordedAt: item.recordedAt,
          amountPaise: item.amountPaise,
          balanceDeltaPaise: item.balanceDeltaPaise,
          runningBalancePaise: runningBalance,
          isInformational: item.isInformational,
          isReversed: item.isReversed,
          paymentMode: item.paymentMode,
          referenceNo: item.referenceNo,
          reason: item.reason,
          notes: item.notes,
        ),
      );
    }

    if (newestFirst) {
      return (
        openingBalancePaise: openingBalance,
        lines: filteredLines.reversed.toList(),
      );
    }
    return (openingBalancePaise: openingBalance, lines: filteredLines);
  }
}

final class _RawLedgerItem {
  const _RawLedgerItem({
    required this.id,
    required this.sourceEntityId,
    required this.kind,
    required this.title,
    this.subtitle,
    required this.transactionAt,
    required this.recordedAt,
    required this.amountPaise,
    required this.balanceDeltaPaise,
    required this.isInformational,
    required this.isReversed,
    this.paymentMode,
    this.referenceNo,
    this.reason,
    this.notes,
  });

  final String id;
  final String sourceEntityId;
  final WorkerLedgerEntryKind kind;
  final String title;
  final String? subtitle;
  final int transactionAt;
  final int recordedAt;
  final int amountPaise;
  final int balanceDeltaPaise;
  final bool isInformational;
  final bool isReversed;
  final PaymentMode? paymentMode;
  final String? referenceNo;
  final String? reason;
  final String? notes;
}
