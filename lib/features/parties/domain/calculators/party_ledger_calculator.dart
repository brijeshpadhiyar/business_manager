import 'package:business_manager/features/parties/domain/entities/party_entities.dart';

/// Pure Dart party receivable, advance credit, and chronological running-balance
/// calculator.
///
/// Zero Flutter, Drift, or BLoC dependencies.
final class PartyLedgerCalculator {
  const PartyLedgerCalculator();

  Set<String> reversedChallanIds(List<DispatchChallanEntity> challans) {
    final ids = <String>{};
    for (final c in challans) {
      if (c.reversesChallanId != null) {
        ids.add(c.reversesChallanId!);
      }
    }
    return ids;
  }

  Set<String> reversedBuyerReturnIds(List<BuyerReturnEntity> returns) {
    final ids = <String>{};
    for (final r in returns) {
      if (r.reversesReturnId != null) {
        ids.add(r.reversesReturnId!);
      }
    }
    return ids;
  }

  Set<String> reversedPartyPaymentIds(List<PartyPaymentEntity> payments) {
    final ids = <String>{};
    for (final p in payments) {
      if (p.paymentType == PartyPaymentType.reversal &&
          p.reversesPaymentId != null) {
        ids.add(p.reversesPaymentId!);
      }
    }
    return ids;
  }

  /// Computes exact live financial standing for a single party.
  PartyFinancialSummary calculatePartySummary({
    required PartyEntity party,
    required List<DispatchChallanEntity> challans,
    required List<DispatchItemEntity> dispatchItems,
    required List<BuyerReturnEntity> buyerReturns,
    required List<BuyerReturnItemEntity> buyerReturnItems,
    required List<PartyPaymentEntity> payments,
  }) {
    final revChallans = reversedChallanIds(challans);
    final revReturns = reversedBuyerReturnIds(buyerReturns);
    final revPayments = reversedPartyPaymentIds(payments);

    final activeChallanIds = <String>{};
    var totalDispatchedNetPaise = 0;
    for (final c in challans) {
      if (c.partyId != party.id) continue;
      if (c.isReversal || revChallans.contains(c.id)) continue;
      activeChallanIds.add(c.id);
      totalDispatchedNetPaise += c.netAmountPaise;
    }

    var totalDispatchedPieces = 0;
    for (final item in dispatchItems) {
      if (activeChallanIds.contains(item.challanId)) {
        totalDispatchedPieces += item.quantity;
      }
    }

    final activeReturnIds = <String>{};
    var totalBuyerReturnsPaise = 0;
    for (final r in buyerReturns) {
      if (r.partyId != party.id) continue;
      if (r.isReversal || revReturns.contains(r.id)) continue;
      activeReturnIds.add(r.id);
      totalBuyerReturnsPaise += r.creditAmountPaise;
    }

    var totalReturnedPieces = 0;
    for (final item in buyerReturnItems) {
      if (activeReturnIds.contains(item.buyerReturnId)) {
        totalReturnedPieces += item.quantity;
      }
    }

    var totalReceiptsPaise = 0;
    var totalAdvancesPaise = 0;
    var totalRefundsPaise = 0;
    for (final p in payments) {
      if (p.partyId != party.id) continue;
      if (p.paymentType == PartyPaymentType.reversal ||
          revPayments.contains(p.id)) {
        continue;
      }
      switch (p.paymentType) {
        case PartyPaymentType.receipt:
          totalReceiptsPaise += p.amountPaise;
        case PartyPaymentType.advance:
          totalAdvancesPaise += p.amountPaise;
        case PartyPaymentType.refund:
          totalRefundsPaise += p.amountPaise;
        case PartyPaymentType.reversal:
          break;
      }
    }

    final netBalancePaise =
        party.openingBalancePaise +
        totalDispatchedNetPaise -
        totalBuyerReturnsPaise -
        totalReceiptsPaise -
        totalAdvancesPaise +
        totalRefundsPaise;

    return PartyFinancialSummary(
      partyId: party.id,
      partyName: party.name,
      partyPhone: party.phone,
      partyType: party.partyType,
      isActive: party.isActive,
      openingBalancePaise: party.openingBalancePaise,
      totalDispatchedNetPaise: totalDispatchedNetPaise,
      totalBuyerReturnsPaise: totalBuyerReturnsPaise,
      totalReceiptsPaise: totalReceiptsPaise,
      totalAdvancesPaise: totalAdvancesPaise,
      totalRefundsPaise: totalRefundsPaise,
      netBalancePaise: netBalancePaise,
      totalDispatchedPieces: totalDispatchedPieces,
      totalReturnedPieces: totalReturnedPieces,
    );
  }

  /// Builds chronological running-balance entries (most recent first in UI
  /// after computing exact running balance from opening balance forward).
  List<PartyLedgerEntry> buildLedgerEntries({
    required PartyEntity party,
    required List<DispatchChallanEntity> challans,
    required List<BuyerReturnEntity> buyerReturns,
    required List<PartyPaymentEntity> payments,
    int? fromUtcMillis,
    int? toUtcMillis,
  }) {
    final revChallans = reversedChallanIds(challans);
    final revReturns = reversedBuyerReturnIds(buyerReturns);
    final revPayments = reversedPartyPaymentIds(payments);

    final raw = <({
      String id,
      PartyLedgerEntryKind kind,
      String ref,
      String desc,
      String? notes,
      int debit,
      int credit,
      int txAt,
      int recAt,
      bool isReversed,
      PartyPaymentMode? mode,
    })>[];

    for (final c in challans) {
      if (c.partyId != party.id || c.isReversal) continue;
      raw.add((
        id: c.id,
        kind: PartyLedgerEntryKind.dispatch,
        ref: c.challanNumber,
        desc: 'Challan ${c.challanNumber}',
        notes: c.notes,
        debit: c.netAmountPaise,
        credit: 0,
        txAt: c.transactionAt,
        recAt: c.recordedAt,
        isReversed: revChallans.contains(c.id),
        mode: null,
      ));
    }

    for (final r in buyerReturns) {
      if (r.partyId != party.id || r.isReversal) continue;
      raw.add((
        id: r.id,
        kind: PartyLedgerEntryKind.buyerReturn,
        ref: r.returnNumber,
        desc: 'Return ${r.returnNumber}',
        notes: r.reason,
        debit: 0,
        credit: r.creditAmountPaise,
        txAt: r.transactionAt,
        recAt: r.recordedAt,
        isReversed: revReturns.contains(r.id),
        mode: null,
      ));
    }

    for (final p in payments) {
      if (p.partyId != party.id || p.paymentType == PartyPaymentType.reversal) {
        continue;
      }
      final isRefund = p.paymentType == PartyPaymentType.refund;
      raw.add((
        id: p.id,
        kind: switch (p.paymentType) {
          PartyPaymentType.receipt => PartyLedgerEntryKind.receipt,
          PartyPaymentType.advance => PartyLedgerEntryKind.advance,
          PartyPaymentType.refund => PartyLedgerEntryKind.refund,
          PartyPaymentType.reversal => PartyLedgerEntryKind.receipt,
        },
        ref: p.referenceNo ?? p.paymentMode.dbValue,
        desc: p.paymentType.dbValue,
        notes: p.notes ?? p.reason,
        debit: isRefund ? p.amountPaise : 0,
        credit: isRefund ? 0 : p.amountPaise,
        txAt: p.transactionAt,
        recAt: p.recordedAt,
        isReversed: revPayments.contains(p.id),
        mode: p.paymentMode,
      ));
    }

    raw.sort((a, b) {
      final t = a.txAt.compareTo(b.txAt);
      if (t != 0) return t;
      final r = a.recAt.compareTo(b.recAt);
      if (r != 0) return r;
      return a.id.compareTo(b.id);
    });

    var running = party.openingBalancePaise;
    final built = <PartyLedgerEntry>[];
    for (final row in raw) {
      if (!row.isReversed) {
        running += row.debit - row.credit;
      }
      if (fromUtcMillis != null && row.txAt < fromUtcMillis) continue;
      if (toUtcMillis != null && row.txAt > toUtcMillis) continue;
      built.add(
        PartyLedgerEntry(
          id: row.id,
          kind: row.kind,
          referenceNumber: row.ref,
          description: row.desc,
          notes: row.notes,
          debitPaise: row.debit,
          creditPaise: row.credit,
          runningBalancePaise: running,
          transactionAt: row.txAt,
          recordedAt: row.recAt,
          isReversed: row.isReversed,
          paymentMode: row.mode,
        ),
      );
    }

    return built.reversed.toList();
  }

  /// Computes physical stock delta per `design_colour_id` across all active
  /// dispatch challans & buyer returns.
  Map<String, PartyDispatchStockDelta> buildStockDeltasByColour({
    required List<DispatchChallanEntity> challans,
    required List<DispatchItemEntity> dispatchItems,
    required List<BuyerReturnEntity> buyerReturns,
    required List<BuyerReturnItemEntity> buyerReturnItems,
  }) {
    final revChallans = reversedChallanIds(challans);
    final revReturns = reversedBuyerReturnIds(buyerReturns);

    final activeChallanIds = {
      for (final c in challans)
        if (!c.isReversal && !revChallans.contains(c.id)) c.id,
    };
    final activeReturnIds = {
      for (final r in buyerReturns)
        if (!r.isReversal && !revReturns.contains(r.id)) r.id,
    };

    final outByColour = <String, int>{};
    final retGoodByColour = <String, int>{};
    final retDamagedByColour = <String, int>{};

    for (final item in dispatchItems) {
      if (!activeChallanIds.contains(item.challanId)) continue;
      outByColour.update(
        item.designColourId,
        (v) => v + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }

    for (final item in buyerReturnItems) {
      if (!activeReturnIds.contains(item.buyerReturnId)) continue;
      final target = item.returnCondition == BuyerReturnCondition.good
          ? retGoodByColour
          : retDamagedByColour;
      target.update(
        item.designColourId,
        (v) => v + item.quantity,
        ifAbsent: () => item.quantity,
      );
    }

    final allColourIds = <String>{
      ...outByColour.keys,
      ...retGoodByColour.keys,
      ...retDamagedByColour.keys,
    };

    return {
      for (final id in allColourIds)
        id: PartyDispatchStockDelta(
          dispatchedOutQty: outByColour[id] ?? 0,
          buyerReturnedGoodQty: retGoodByColour[id] ?? 0,
          buyerReturnedDamagedQty: retDamagedByColour[id] ?? 0,
        ),
    };
  }
}
