import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/domain/calculators/ledger_calculator.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/reports/domain/entities/dashboard_report_entities.dart';
import 'package:business_manager/features/stock_movements/domain/calculators/stock_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';

/// Pure Dart daily workshop productivity & IST business-day calculator.
///
/// Guarantees:
/// - All daily metrics strictly filter by `transactionAt` converted to
///   `Asia/Kolkata` (`YYYY-MM-DD`), never `recordedAt`.
/// - Always excludes reversed stock movements, labour entries, and payments via
///   [StockCalculator] and [LedgerCalculator].
/// - Zero Flutter, Drift, or BLoC dependencies.
final class WorkshopDailyCalculator {
  const WorkshopDailyCalculator();

  static const StockCalculator _stockCalc = StockCalculator();
  static const LedgerCalculator _ledgerCalc = LedgerCalculator();

  /// Returns exact UTC `[startUtcMillis, endUtcMillis]` boundaries for the
  /// `Asia/Kolkata` calendar date containing [referenceUtcMillis].
  static ({int startUtcMillis, int endUtcMillis, String istDateIso})
  istDayBounds(int referenceUtcMillis) {
    final ist = IstDateTimeHelper.fromUtcMillisToIst(referenceUtcMillis);
    final start = IstDateTimeHelper.istDateTimeToUtcMillis(
      year: ist.year,
      month: ist.month,
      day: ist.day,
      hour: 0,
      minute: 0,
      second: 0,
    );
    final end =
        IstDateTimeHelper.istDateTimeToUtcMillis(
          year: ist.year,
          month: ist.month,
          day: ist.day,
          hour: 23,
          minute: 59,
          second: 59,
        ) +
        999;
    return (
      startUtcMillis: start,
      endUtcMillis: end,
      istDateIso: IstDateTimeHelper.toIstBusinessDate(referenceUtcMillis),
    );
  }

  /// Calculates whole IST calendar days elapsed between [issueTransactionAtUtc]
  /// and [nowUtcMillis] (clamped at >= 0).
  static int pendingAgeDays(int issueTransactionAtUtc, int nowUtcMillis) {
    final issueIst = IstDateTimeHelper.fromUtcMillisToIst(
      issueTransactionAtUtc,
    );
    final nowIst = IstDateTimeHelper.fromUtcMillisToIst(nowUtcMillis);
    final d1 = DateTime.utc(issueIst.year, issueIst.month, issueIst.day);
    final d2 = DateTime.utc(nowIst.year, nowIst.month, nowIst.day);
    final diff = d2.difference(d1).inDays;
    return diff < 0 ? 0 : diff;
  }

  /// Ranks open pending issues by urgency: oldest `transactionAt` first, then
  /// highest remaining pending quantity descending.
  List<OpenIssueSummary> prioritizeImportantPending(
    List<OpenIssueSummary> openIssues, {
    int limit = 5,
  }) {
    final sorted = List<OpenIssueSummary>.from(openIssues)
      ..sort((a, b) {
        final ageCmp = a.issueView.movement.transactionAt.compareTo(
          b.issueView.movement.transactionAt,
        );
        if (ageCmp != 0) return ageCmp;
        return b.remainingPending.compareTo(a.remainingPending);
      });
    return sorted.take(limit).toList();
  }

  /// Computes a complete IST daily workshop production & financial summary for
  /// the business day containing [targetDayUtcMillis].
  DailyWorkshopSummary calculateDailySummary({
    required int targetDayUtcMillis,
    required List<StockMovementEntity> allMovements,
    required List<LabourEntryEntity> allLabourEntries,
    required List<PaymentEntity> allPayments,
    required Map<String, String> processNamesById,
    required Map<String, String> workerNamesById,
    required int currentTotalPendingQty,
    required int currentTotalDamagedQty,
    required int currentTotalOutstandingPayablePaise,
  }) {
    final bounds = istDayBounds(targetDayUtcMillis);
    final activeMoves = _stockCalc.activeMovements(allMovements);
    final revLabour = _ledgerCalc.reversedLabourIds(allLabourEntries);
    final revPayments = _ledgerCalc.reversedPaymentIds(allPayments);

    var issued = 0;
    var goodReturned = 0;
    var damaged = 0;
    var lost = 0;
    var shortage = 0;
    var repaired = 0;

    final procAccum = <String, _DailyProcAcc>{};
    final workerAccum = <String, _DailyWorkerAcc>{};

    for (final m in activeMoves) {
      if (m.transactionAt < bounds.startUtcMillis ||
          m.transactionAt > bounds.endUtcMillis) {
        continue;
      }

      _DailyProcAcc? pAcc;
      if (m.processId != null) {
        pAcc = procAccum.putIfAbsent(m.processId!, () => _DailyProcAcc());
      }
      _DailyWorkerAcc? wAcc;
      if (m.memberId != null) {
        wAcc = workerAccum.putIfAbsent(m.memberId!, () => _DailyWorkerAcc());
      }

      switch (m.movementType) {
        case StockMovementType.issue:
          issued += m.quantity;
          pAcc?.issued += m.quantity;
          wAcc?.issued += m.quantity;
        case StockMovementType.returnGood:
          goodReturned += m.quantity;
          pAcc?.goodReturned += m.quantity;
          wAcc?.goodReturned += m.quantity;
        case StockMovementType.returnDamaged:
          damaged += m.quantity;
          pAcc?.damaged += m.quantity;
          wAcc?.damaged += m.quantity;
        case StockMovementType.settlementLost:
          lost += m.quantity;
          pAcc?.lostShortage += m.quantity;
          wAcc?.lostShortage += m.quantity;
        case StockMovementType.settlementShortage:
          shortage += m.quantity;
          pAcc?.lostShortage += m.quantity;
          wAcc?.lostShortage += m.quantity;
        case StockMovementType.adjustmentDamagedToGood:
          repaired += m.quantity;
        case StockMovementType.reversal:
          break;
      }
    }

    var labourEarnedPaise = 0;
    for (final l in allLabourEntries) {
      if (l.transactionAt < bounds.startUtcMillis ||
          l.transactionAt > bounds.endUtcMillis) {
        continue;
      }
      if (!l.isPayable ||
          l.basisType == LabourBasisType.reversal ||
          revLabour.contains(l.id)) {
        continue;
      }
      labourEarnedPaise += l.amountPaise;
      workerAccum
              .putIfAbsent(l.memberId, () => _DailyWorkerAcc())
              .labourEarnedPaise +=
          l.amountPaise;
    }

    var regularPaidPaise = 0;
    var advancePaidPaise = 0;
    var advanceRefundPaise = 0;
    for (final p in allPayments) {
      if (p.transactionAt < bounds.startUtcMillis ||
          p.transactionAt > bounds.endUtcMillis) {
        continue;
      }
      if (p.paymentType == PaymentType.reversal || revPayments.contains(p.id)) {
        continue;
      }
      final wAcc = workerAccum.putIfAbsent(p.memberId, () => _DailyWorkerAcc());
      switch (p.paymentType) {
        case PaymentType.regular:
          regularPaidPaise += p.amountPaise;
          wAcc.paymentsPaidPaise += p.amountPaise;
        case PaymentType.advance:
          advancePaidPaise += p.amountPaise;
          wAcc.paymentsPaidPaise += p.amountPaise;
        case PaymentType.advanceRefund:
          advanceRefundPaise += p.amountPaise;
          wAcc.paymentsPaidPaise -= p.amountPaise;
        case PaymentType.reversal:
          break;
      }
    }

    final processActivities =
        procAccum.entries
            .map(
              (e) => DailyProcessActivity(
                processId: e.key,
                processName: processNamesById[e.key] ?? e.key,
                issuedQty: e.value.issued,
                goodReturnedQty: e.value.goodReturned,
                damagedQty: e.value.damaged,
                lostShortageQty: e.value.lostShortage,
              ),
            )
            .toList()
          ..sort(
            (a, b) => (b.issuedQty + b.goodReturnedQty).compareTo(
              a.issuedQty + a.goodReturnedQty,
            ),
          );

    final workerActivities =
        workerAccum.entries
            .map(
              (e) => DailyWorkerActivity(
                workerId: e.key,
                workerName: workerNamesById[e.key] ?? e.key,
                issuedQty: e.value.issued,
                goodReturnedQty: e.value.goodReturned,
                damagedQty: e.value.damaged,
                lostShortageQty: e.value.lostShortage,
                labourEarnedPaise: e.value.labourEarnedPaise,
                paymentsPaidPaise: e.value.paymentsPaidPaise,
              ),
            )
            .toList()
          ..sort(
            (a, b) =>
                (b.issuedQty +
                        b.goodReturnedQty +
                        (b.paymentsPaidPaise > 0 ? 1 : 0))
                    .compareTo(
                      a.issuedQty +
                          a.goodReturnedQty +
                          (a.paymentsPaidPaise > 0 ? 1 : 0),
                    ),
          );

    return DailyWorkshopSummary(
      istDateIso: bounds.istDateIso,
      dayStartUtcMillis: bounds.startUtcMillis,
      dayEndUtcMillis: bounds.endUtcMillis,
      issuedQty: issued,
      goodReturnedQty: goodReturned,
      damagedQty: damaged,
      lostQty: lost,
      shortageQty: shortage,
      repairedQty: repaired,
      labourEarnedPaise: labourEarnedPaise,
      regularPaymentsPaise: regularPaidPaise,
      advancePaymentsPaise: advancePaidPaise,
      advanceRefundsPaise: advanceRefundPaise,
      netPaymentsPaise:
          regularPaidPaise + advancePaidPaise - advanceRefundPaise,
      currentTotalPendingQty: currentTotalPendingQty,
      currentTotalDamagedQty: currentTotalDamagedQty,
      currentTotalOutstandingPayablePaise: currentTotalOutstandingPayablePaise,
      processActivities: processActivities,
      workerActivities: workerActivities,
    );
  }

  /// Derives up to [maxPairs] recent active `(process, worker)` pairs and up to
  /// [maxColours] recent in-stock `designColourId`s from non-reversed `ISSUE`
  /// movements. Never suggests inactive workers, inactive processes, unassigned
  /// links, or out-of-stock colours.
  RecentIssueSuggestions deriveRecentIssueSuggestions({
    required List<StockMovementEntity> allMovements,
    required Set<String> activeProcessIds,
    required Set<String> activeWorkerIds,
    required Set<String> activeAssignmentKeys, // '$workerId::$processId'
    required Map<String, String> processNamesById,
    required Map<String, String> workerNamesById,
    required Set<String> inStockColourIds,
    int maxPairs = 3,
    int maxColours = 3,
  }) {
    final active = _stockCalc.activeMovements(allMovements).reversed;
    final seenPairs = <String>{};
    final pairs = <RecentWorkPairSuggestion>[];
    final seenColours = <String>{};
    final colours = <String>[];

    for (final m in active) {
      if (m.movementType != StockMovementType.issue) continue;

      if (pairs.length < maxPairs &&
          m.processId != null &&
          m.memberId != null &&
          activeProcessIds.contains(m.processId) &&
          activeWorkerIds.contains(m.memberId)) {
        final pairKey = '${m.memberId!}::${m.processId!}';
        if (activeAssignmentKeys.contains(pairKey) && seenPairs.add(pairKey)) {
          pairs.add(
            RecentWorkPairSuggestion(
              processId: m.processId!,
              processName: processNamesById[m.processId!] ?? m.processId!,
              workerId: m.memberId!,
              workerName: workerNamesById[m.memberId!] ?? m.memberId!,
            ),
          );
        }
      }

      if (colours.length < maxColours &&
          inStockColourIds.contains(m.designColourId) &&
          seenColours.add(m.designColourId)) {
        colours.add(m.designColourId);
      }

      if (pairs.length >= maxPairs && colours.length >= maxColours) {
        break;
      }
    }

    return RecentIssueSuggestions(
      workPairs: pairs,
      inStockDesignColourIds: colours,
    );
  }
}

final class _DailyProcAcc {
  int issued = 0;
  int goodReturned = 0;
  int damaged = 0;
  int lostShortage = 0;
}

final class _DailyWorkerAcc {
  int issued = 0;
  int goodReturned = 0;
  int damaged = 0;
  int lostShortage = 0;
  int labourEarnedPaise = 0;
  int paymentsPaidPaise = 0;
}
