import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/domain/calculators/ledger_calculator.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/cashbook/domain/entities/cashbook_entities.dart';
import 'package:business_manager/features/parties/domain/calculators/lot_profit_loss_calculator.dart';
import 'package:business_manager/features/parties/domain/calculators/party_ledger_calculator.dart';
import 'package:business_manager/features/parties/domain/entities/party_entities.dart';
import 'package:timezone/timezone.dart' as tz;

/// Pure Dart deterministic calculator for StitchFlow's Unified Cash & Bank Book,
/// Workshop Overhead Expenses, and True Workshop Net Profit.
///
/// Zero Flutter, Drift, or IO dependencies; all monetary math uses exact integer
/// paise (`100 paise = ₹1.00`).
final class CashbookCalculator {
  const CashbookCalculator({
    LedgerCalculator ledgerCalculator = const LedgerCalculator(),
    PartyLedgerCalculator partyLedgerCalculator = const PartyLedgerCalculator(),
    LotProfitLossCalculator lotPnlCalculator = const LotProfitLossCalculator(),
  }) : _ledgerCalc = ledgerCalculator,
       _partyCalc = partyLedgerCalculator,
       _lotPnlCalc = lotPnlCalculator;

  final LedgerCalculator _ledgerCalc;
  final PartyLedgerCalculator _partyCalc;
  final LotProfitLossCalculator _lotPnlCalc;

  static CashbookAccountBucket bucketForPaymentMode(PaymentMode mode) {
    return mode == PaymentMode.cash
        ? CashbookAccountBucket.cash
        : CashbookAccountBucket.bank;
  }

  static PaymentMode _fromPartyPaymentMode(PartyPaymentMode mode) {
    return switch (mode) {
      PartyPaymentMode.cash => PaymentMode.cash,
      PartyPaymentMode.upi => PaymentMode.upi,
      PartyPaymentMode.bankTransfer => PaymentMode.bankTransfer,
      PartyPaymentMode.cheque => PaymentMode.cheque,
      PartyPaymentMode.other => PaymentMode.other,
    };
  }

  Set<String> reversedExpenseIds(List<WorkshopExpenseEntity> expenses) {
    final ids = <String>{};
    for (final e in expenses) {
      if (e.reversesExpenseId != null) {
        ids.add(e.reversesExpenseId!);
      }
    }
    return ids;
  }

  Set<String> reversedCashbookEntryIds(List<CashbookEntryEntity> entries) {
    final ids = <String>{};
    for (final e in entries) {
      if (e.reversesEntryId != null) {
        ids.add(e.reversesEntryId!);
      }
    }
    return ids;
  }

  /// Computes the live Cash & Bank balances, period inflows/outflows,
  /// pending unpaid bills, expense category breakdowns, and unified timeline.
  CashbookSummary calculateSummary({
    required List<WorkshopExpenseEntity> expenses,
    required List<CashbookEntryEntity> cashbookEntries,
    required List<PaymentEntity> workerPayments,
    required List<PartyPaymentEntity> partyPayments,
    Map<String, String> workerNames = const {},
    Map<String, String> partyNames = const {},
    Set<String> expenseIdsWithReceipt = const {},
    int? fromUtcMillis,
    int? toUtcMillis,
    int? referenceNowUtcMillis,
  }) {
    final revExpenses = reversedExpenseIds(expenses);
    final revEntries = reversedCashbookEntryIds(cashbookEntries);
    final revWorkerPayments = _ledgerCalc.reversedPaymentIds(workerPayments);
    final revPartyPayments = _partyCalc.reversedPartyPaymentIds(partyPayments);

    // Aggregate active settlements per unpaid expense.
    final settledByExpense = <String, int>{};
    for (final entry in cashbookEntries) {
      if (entry.isReversal || revEntries.contains(entry.id)) continue;
      if (entry.entryType == CashbookEntryType.expenseSettlement &&
          entry.linkedExpenseId != null) {
        settledByExpense.update(
          entry.linkedExpenseId!,
          (v) => v + entry.amountPaise,
          ifAbsent: () => entry.amountPaise,
        );
      }
    }

    final expenseById = {for (final e in expenses) e.id: e};
    final entryById = {for (final e in cashbookEntries) e.id: e};

    // Build WorkshopExpenseView list (excluding reversal rows from main list
    // only? Keep all non-reversal rows with isReversed flag for audit clarity).
    final expenseViews = <WorkshopExpenseView>[];
    final pendingBills = <WorkshopExpenseView>[];

    for (final e in expenses) {
      if (e.isReversal) continue;
      final isRev = revExpenses.contains(e.id);
      final settled = isRev ? 0 : (settledByExpense[e.id] ?? 0);
      final view = WorkshopExpenseView(
        expense: e,
        isReversed: isRev,
        settledPaise: settled,
        hasReceiptAttachment: expenseIdsWithReceipt.contains(e.id),
      );
      if (_inRange(e.transactionAt, fromUtcMillis, toUtcMillis)) {
        expenseViews.add(view);
      }
      if (!isRev && view.remainingUnpaidPaise > 0) {
        pendingBills.add(view);
      }
    }

    final viewById = {for (final v in expenseViews) v.expense.id: v};

    // Today IST bounds for "Today's Expenses" KPI.
    final nowUtc = referenceNowUtcMillis ?? IstDateTimeHelper.nowUtcMillis();
    final istNow = IstDateTimeHelper.fromUtcMillisToIst(nowUtc);
    final todayStart = tz.TZDateTime(
      IstDateTimeHelper.istLocation,
      istNow.year,
      istNow.month,
      istNow.day,
    ).millisecondsSinceEpoch;
    final todayEnd = tz.TZDateTime(
      IstDateTimeHelper.istLocation,
      istNow.year,
      istNow.month,
      istNow.day,
      23,
      59,
      59,
      999,
    ).millisecondsSinceEpoch;

    var openingCash = 0;
    var openingBank = 0;
    var liveCash = 0;
    var liveBank = 0;
    var periodCashIn = 0;
    var periodCashOut = 0;
    var periodBankIn = 0;
    var periodBankOut = 0;

    var totalExpensesPaid = 0;
    var totalExpensesUnpaid = 0;
    var todayExpenses = 0;

    final categoryTotals = <ExpenseCategory, _CatAccum>{};
    final timeline = <CashbookTimelineItem>[];

    // 1. Worker Payments
    for (final p in workerPayments) {
      final isRev = revWorkerPayments.contains(p.id);
      final isReversal =
          p.reversesPaymentId != null || p.paymentType == PaymentType.reversal;
      final bucket = bucketForPaymentMode(p.paymentMode);
      final isInflow = p.paymentType == PaymentType.advanceRefund;
      final signed = isInflow ? p.amountPaise : -p.amountPaise;

      if (!isRev && !isReversal) {
        if (bucket == CashbookAccountBucket.cash) {
          liveCash += signed;
          if (_inRange(p.transactionAt, fromUtcMillis, toUtcMillis)) {
            if (isInflow) {
              periodCashIn += p.amountPaise;
            } else {
              periodCashOut += p.amountPaise;
            }
          }
        } else {
          liveBank += signed;
          if (_inRange(p.transactionAt, fromUtcMillis, toUtcMillis)) {
            if (isInflow) {
              periodBankIn += p.amountPaise;
            } else {
              periodBankOut += p.amountPaise;
            }
          }
        }
      }

      if (_inRange(p.transactionAt, fromUtcMillis, toUtcMillis)) {
        final cashDelta = bucket == CashbookAccountBucket.cash
            ? (isReversal ? -signed : signed)
            : 0;
        final bankDelta = bucket == CashbookAccountBucket.bank
            ? (isReversal ? -signed : signed)
            : 0;
        timeline.add(
          CashbookTimelineItem(
            id: p.id,
            source: CashbookTimelineSource.workerPayment,
            accountBucket: bucket,
            paymentMode: p.paymentMode,
            title: workerNames[p.memberId] ?? p.memberId,
            subtitle: p.notes ?? p.referenceNo,
            cashDeltaPaise: cashDelta,
            bankDeltaPaise: bankDelta,
            grossAmountPaise: p.amountPaise,
            transactionAt: p.transactionAt,
            recordedAt: p.recordedAt,
            isReversed: isRev,
            isReversal: isReversal,
            subTypeCode: p.paymentType.dbValue,
          ),
        );
      }
    }

    // 2. Party Payments (Receipts, Advances, Refunds)
    for (final pp in partyPayments) {
      final isRev = revPartyPayments.contains(pp.id);
      final isReversal =
          pp.reversesPaymentId != null ||
          pp.paymentType == PartyPaymentType.reversal;
      final mappedMode = _fromPartyPaymentMode(pp.paymentMode);
      final bucket = bucketForPaymentMode(mappedMode);
      final isOutflow = pp.paymentType == PartyPaymentType.refund;
      final signed = isOutflow ? -pp.amountPaise : pp.amountPaise;

      if (!isRev && !isReversal) {
        if (bucket == CashbookAccountBucket.cash) {
          liveCash += signed;
          if (_inRange(pp.transactionAt, fromUtcMillis, toUtcMillis)) {
            if (isOutflow) {
              periodCashOut += pp.amountPaise;
            } else {
              periodCashIn += pp.amountPaise;
            }
          }
        } else {
          liveBank += signed;
          if (_inRange(pp.transactionAt, fromUtcMillis, toUtcMillis)) {
            if (isOutflow) {
              periodBankOut += pp.amountPaise;
            } else {
              periodBankIn += pp.amountPaise;
            }
          }
        }
      }

      if (_inRange(pp.transactionAt, fromUtcMillis, toUtcMillis)) {
        final cashDelta = bucket == CashbookAccountBucket.cash
            ? (isReversal ? -signed : signed)
            : 0;
        final bankDelta = bucket == CashbookAccountBucket.bank
            ? (isReversal ? -signed : signed)
            : 0;
        timeline.add(
          CashbookTimelineItem(
            id: pp.id,
            source: CashbookTimelineSource.partyPayment,
            accountBucket: bucket,
            paymentMode: mappedMode,
            title: partyNames[pp.partyId] ?? pp.partyId,
            subtitle: pp.notes ?? pp.referenceNo,
            cashDeltaPaise: cashDelta,
            bankDeltaPaise: bankDelta,
            grossAmountPaise: pp.amountPaise,
            transactionAt: pp.transactionAt,
            recordedAt: pp.recordedAt,
            isReversed: isRev,
            isReversal: isReversal,
            subTypeCode: pp.paymentType.dbValue,
          ),
        );
      }
    }

    // 3. Workshop Expenses
    for (final e in expenses) {
      final isRev = revExpenses.contains(e.id);
      final isReversal = e.isReversal;

      if (!isRev && !isReversal) {
        if (e.transactionAt >= todayStart && e.transactionAt <= todayEnd) {
          todayExpenses += e.amountPaise;
        }

        final settled = settledByExpense[e.id] ?? 0;
        final isImmediatePaid = e.paymentStatus == ExpensePaymentStatus.paid;

        if (_inRange(e.transactionAt, fromUtcMillis, toUtcMillis)) {
          final paidForRow = isImmediatePaid
              ? e.amountPaise
              : settled.clamp(0, e.amountPaise);
          final unpaidForRow = isImmediatePaid
              ? 0
              : (e.amountPaise - paidForRow).clamp(0, e.amountPaise);

          totalExpensesPaid += paidForRow;
          totalExpensesUnpaid += unpaidForRow;

          final acc = categoryTotals.putIfAbsent(e.category, () => _CatAccum());
          acc.total += e.amountPaise;
          acc.paid += paidForRow;
          acc.unpaid += unpaidForRow;
          acc.count += 1;
        }

        if (isImmediatePaid && e.paymentMode != null) {
          final bucket = bucketForPaymentMode(e.paymentMode!);
          if (bucket == CashbookAccountBucket.cash) {
            liveCash -= e.amountPaise;
            if (_inRange(e.transactionAt, fromUtcMillis, toUtcMillis)) {
              periodCashOut += e.amountPaise;
            }
          } else {
            liveBank -= e.amountPaise;
            if (_inRange(e.transactionAt, fromUtcMillis, toUtcMillis)) {
              periodBankOut += e.amountPaise;
            }
          }
        }
      }

      if (e.paymentStatus == ExpensePaymentStatus.paid &&
          e.paymentMode != null &&
          _inRange(e.transactionAt, fromUtcMillis, toUtcMillis)) {
        final bucket = bucketForPaymentMode(e.paymentMode!);
        final signed = isReversal ? e.amountPaise : -e.amountPaise;
        timeline.add(
          CashbookTimelineItem(
            id: e.id,
            source: CashbookTimelineSource.workshopExpense,
            accountBucket: bucket,
            paymentMode: e.paymentMode!,
            title: e.title,
            subtitle: e.payeeName ?? e.notes,
            cashDeltaPaise: bucket == CashbookAccountBucket.cash ? signed : 0,
            bankDeltaPaise: bucket == CashbookAccountBucket.bank ? signed : 0,
            grossAmountPaise: e.amountPaise,
            transactionAt: e.transactionAt,
            recordedAt: e.recordedAt,
            isReversed: isRev,
            isReversal: isReversal,
            expenseView: viewById[e.id],
            subTypeCode: e.category.dbValue,
          ),
        );
      }
    }

    // 4. Cashbook Entries (Opening, Contra Transfers, Capital, Drawings, Settlements)
    for (final entry in cashbookEntries) {
      final isRev = revEntries.contains(entry.id);
      final isReversal = entry.isReversal;

      final (cashDelta, bankDelta) = _deltasForEntry(entry);

      if (!isRev && !isReversal) {
        if (entry.entryType == CashbookEntryType.openingCash) {
          openingCash += entry.amountPaise;
        } else if (entry.entryType == CashbookEntryType.openingBank) {
          openingBank += entry.amountPaise;
        }
        liveCash += cashDelta;
        liveBank += bankDelta;

        if (_inRange(entry.transactionAt, fromUtcMillis, toUtcMillis) &&
            entry.entryType != CashbookEntryType.openingCash &&
            entry.entryType != CashbookEntryType.openingBank) {
          if (cashDelta > 0) periodCashIn += cashDelta;
          if (cashDelta < 0) periodCashOut += -cashDelta;
          if (bankDelta > 0) periodBankIn += bankDelta;
          if (bankDelta < 0) periodBankOut += -bankDelta;
        }
      }

      if (_inRange(entry.transactionAt, fromUtcMillis, toUtcMillis)) {
        final linkedExp = entry.linkedExpenseId != null
            ? expenseById[entry.linkedExpenseId!]
            : null;
        final (displayCash, displayBank) =
            isReversal &&
                entry.reversesEntryId != null &&
                entryById.containsKey(entry.reversesEntryId!)
            ? _negatedDeltas(entryById[entry.reversesEntryId!]!)
            : (isReversal ? (-cashDelta, -bankDelta) : (cashDelta, bankDelta));
        final cleanNotes = _cleanOrNull(entry.notes);
        final cleanRef = _cleanOrNull(entry.referenceNo);
        final cleanReason = _cleanOrNull(entry.reason);
        final itemTitle =
            linkedExp?.title ?? cleanNotes ?? entry.entryType.dbValue;
        final subtitleParts = <String>[
          if (linkedExp?.payeeName != null &&
              linkedExp!.payeeName!.trim().isNotEmpty)
            linkedExp.payeeName!.trim(),
          ?cleanRef,
          ?cleanReason,
          if (cleanNotes != null && cleanNotes != itemTitle) cleanNotes,
        ];
        timeline.add(
          CashbookTimelineItem(
            id: entry.id,
            source: CashbookTimelineSource.cashbookEntry,
            accountBucket: entry.accountBucket,
            paymentMode: entry.paymentMode,
            title: itemTitle,
            subtitle: subtitleParts.isEmpty ? null : subtitleParts.join(' • '),
            cashDeltaPaise: displayCash,
            bankDeltaPaise: displayBank,
            grossAmountPaise: entry.amountPaise,
            transactionAt: entry.transactionAt,
            recordedAt: entry.recordedAt,
            isReversed: isRev,
            isReversal: isReversal,
            cashbookEntry: entry,
            subTypeCode: entry.entryType.dbValue,
          ),
        );
      }
    }

    timeline.sort((a, b) {
      final txCmp = b.transactionAt.compareTo(a.transactionAt);
      if (txCmp != 0) return txCmp;
      return b.recordedAt.compareTo(a.recordedAt);
    });

    final breakdowns = [
      for (final entry in categoryTotals.entries)
        ExpenseCategoryBreakdown(
          category: entry.key,
          totalPaise: entry.value.total,
          paidPaise: entry.value.paid,
          unpaidPaise: entry.value.unpaid,
          entryCount: entry.value.count,
        ),
    ]..sort((a, b) => b.totalPaise.compareTo(a.totalPaise));

    pendingBills.sort(
      (a, b) => a.expense.transactionAt.compareTo(b.expense.transactionAt),
    );

    return CashbookSummary(
      openingCashPaise: openingCash,
      openingBankPaise: openingBank,
      cashInflowPaise: periodCashIn,
      cashOutflowPaise: periodCashOut,
      currentCashBalancePaise: liveCash,
      bankInflowPaise: periodBankIn,
      bankOutflowPaise: periodBankOut,
      currentBankBalancePaise: liveBank,
      totalExpensesPaidPaise: totalExpensesPaid,
      totalExpensesUnpaidPaise: totalExpensesUnpaid,
      todayExpensesPaise: todayExpenses,
      expenses: expenseViews,
      pendingBills: pendingBills,
      categoryBreakdowns: breakdowns,
      timeline: timeline,
    );
  }

  /// Computes true business-wide Net Profit combining Dispatched Sales,
  /// Buyer Returns, Worker Labour & Adjustments, Lot Direct Costs, and
  /// Workshop Overhead Expenses.
  TrueWorkshopNetProfitSummary calculateTrueNetProfit({
    required List<DispatchChallanEntity> challans,
    required List<BuyerReturnEntity> buyerReturns,
    required List<LabourEntryEntity> labourEntries,
    required List<WorkerAdjustmentEntity> workerAdjustments,
    required List<LotDirectCostEntity> lotDirectCosts,
    required List<WorkshopExpenseEntity> workshopExpenses,
    required List<CashbookEntryEntity> cashbookEntries,
    int? fromUtcMillis,
    int? toUtcMillis,
  }) {
    final revChallans = _partyCalc.reversedChallanIds(challans);
    final revReturns = _partyCalc.reversedBuyerReturnIds(buyerReturns);
    final revLabour = _ledgerCalc.reversedLabourIds(labourEntries);
    final revAdj = _ledgerCalc.reversedAdjustmentIds(workerAdjustments);
    final revCosts = _lotPnlCalc.reversedDirectCostIds(lotDirectCosts);
    final revExpenses = reversedExpenseIds(workshopExpenses);
    final revEntries = reversedCashbookEntryIds(cashbookEntries);

    var dispatchedSales = 0;
    for (final c in challans) {
      if (c.isReversal || revChallans.contains(c.id)) continue;
      if (_inRange(c.transactionAt, fromUtcMillis, toUtcMillis)) {
        dispatchedSales += c.netAmountPaise;
      }
    }

    var returnCredits = 0;
    for (final r in buyerReturns) {
      if (r.isReversal || revReturns.contains(r.id)) continue;
      if (_inRange(r.transactionAt, fromUtcMillis, toUtcMillis)) {
        returnCredits += r.creditAmountPaise;
      }
    }

    var workerLabour = 0;
    for (final l in labourEntries) {
      if (!l.isPayable ||
          l.basisType == LabourBasisType.reversal ||
          revLabour.contains(l.id)) {
        continue;
      }
      if (_inRange(l.transactionAt, fromUtcMillis, toUtcMillis)) {
        workerLabour += l.amountPaise;
      }
    }
    for (final a in workerAdjustments) {
      final isAdjReversal =
          a.reversesAdjustmentId != null ||
          a.adjustmentType == WorkerAdjustmentType.reversal;
      if (isAdjReversal || revAdj.contains(a.id)) continue;
      if (_inRange(a.transactionAt, fromUtcMillis, toUtcMillis)) {
        if (a.adjustmentType == WorkerAdjustmentType.credit) {
          workerLabour += a.amountPaise;
        } else if (a.adjustmentType == WorkerAdjustmentType.debit) {
          workerLabour -= a.amountPaise;
        }
      }
    }

    var directCosts = 0;
    for (final dc in lotDirectCosts) {
      if (dc.isReversal || revCosts.contains(dc.id)) continue;
      if (_inRange(dc.transactionAt, fromUtcMillis, toUtcMillis)) {
        directCosts += dc.amountPaise;
      }
    }

    final settledByExpense = <String, int>{};
    for (final entry in cashbookEntries) {
      if (entry.isReversal || revEntries.contains(entry.id)) continue;
      if (entry.entryType == CashbookEntryType.expenseSettlement &&
          entry.linkedExpenseId != null) {
        settledByExpense.update(
          entry.linkedExpenseId!,
          (v) => v + entry.amountPaise,
          ifAbsent: () => entry.amountPaise,
        );
      }
    }

    var overheadTotal = 0;
    var overheadPaid = 0;
    var overheadUnpaid = 0;
    for (final e in workshopExpenses) {
      if (e.isReversal || revExpenses.contains(e.id)) continue;
      if (!_inRange(e.transactionAt, fromUtcMillis, toUtcMillis)) continue;
      overheadTotal += e.amountPaise;
      if (e.paymentStatus == ExpensePaymentStatus.paid) {
        overheadPaid += e.amountPaise;
      } else {
        final paid = (settledByExpense[e.id] ?? 0).clamp(0, e.amountPaise);
        overheadPaid += paid;
        overheadUnpaid += e.amountPaise - paid;
      }
    }

    final netSales = dispatchedSales - returnCredits;
    final netProfit = netSales - workerLabour - directCosts - overheadTotal;
    final margin = netSales > 0 ? (netProfit / netSales) * 100.0 : 0.0;

    return TrueWorkshopNetProfitSummary(
      netDispatchedSalesPaise: netSales,
      workerLabourPaise: workerLabour,
      lotDirectCostsPaise: directCosts,
      workshopOverheadExpensesPaise: overheadTotal,
      workshopExpensesPaidPaise: overheadPaid,
      workshopExpensesUnpaidPaise: overheadUnpaid,
      trueNetProfitPaise: netProfit,
      netMarginPercent: margin,
    );
  }

  static (int cashDelta, int bankDelta) _deltasForEntry(
    CashbookEntryEntity entry,
  ) {
    return switch (entry.entryType) {
      CashbookEntryType.openingCash => (entry.amountPaise, 0),
      CashbookEntryType.openingBank => (0, entry.amountPaise),
      CashbookEntryType.cashToBank => (-entry.amountPaise, entry.amountPaise),
      CashbookEntryType.bankToCash => (entry.amountPaise, -entry.amountPaise),
      CashbookEntryType.capitalIn =>
        entry.accountBucket == CashbookAccountBucket.cash
            ? (entry.amountPaise, 0)
            : (0, entry.amountPaise),
      CashbookEntryType.ownerDrawing =>
        entry.accountBucket == CashbookAccountBucket.cash
            ? (-entry.amountPaise, 0)
            : (0, -entry.amountPaise),
      CashbookEntryType.expenseSettlement =>
        entry.accountBucket == CashbookAccountBucket.cash
            ? (-entry.amountPaise, 0)
            : (0, -entry.amountPaise),
      CashbookEntryType.reversal => (0, 0),
    };
  }

  static (int cashDelta, int bankDelta) _negatedDeltas(
    CashbookEntryEntity original,
  ) {
    final (c, b) = _deltasForEntry(original);
    return (-c, -b);
  }

  static String? _cleanOrNull(String? raw) {
    final trimmed = raw?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static bool _inRange(int ts, int? fromUtcMillis, int? toUtcMillis) {
    if (fromUtcMillis != null && ts < fromUtcMillis) return false;
    if (toUtcMillis != null && ts > toUtcMillis) return false;
    return true;
  }
}

final class _CatAccum {
  int total = 0;
  int paid = 0;
  int unpaid = 0;
  int count = 0;
}
