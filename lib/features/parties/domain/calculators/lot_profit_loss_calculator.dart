import 'package:business_manager/features/accounting/domain/calculators/ledger_calculator.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/parties/domain/calculators/party_ledger_calculator.dart';
import 'package:business_manager/features/parties/domain/entities/party_entities.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';

/// Pure Dart Lot Profit & Loss calculator.
///
/// Computes:
/// `Net Profit = Net Dispatch Revenue - Worker Labour - Direct Lot Costs`
/// (all in exact integer paise, excluding reversed rows).
final class LotProfitLossCalculator {
  const LotProfitLossCalculator({
    LedgerCalculator ledgerCalculator = const LedgerCalculator(),
    PartyLedgerCalculator partyLedgerCalculator = const PartyLedgerCalculator(),
  }) : _ledgerCalc = ledgerCalculator,
       _partyCalc = partyLedgerCalculator;

  final LedgerCalculator _ledgerCalc;
  final PartyLedgerCalculator _partyCalc;

  Set<String> reversedDirectCostIds(List<LotDirectCostEntity> costs) {
    final ids = <String>{};
    for (final c in costs) {
      if (c.reversesCostId != null) {
        ids.add(c.reversesCostId!);
      }
    }
    return ids;
  }

  /// Computes exact P&L for a single lot using live colour balances, challans,
  /// buyer returns, worker labour entries, and direct lot costs.
  LotProfitLossSummary calculateForLot({
    required String lotId,
    required String lotNumber,
    String? lotTitle,
    required List<DesignColourStockBalance> colourBalances,
    required List<DispatchChallanEntity> challans,
    required List<DispatchItemEntity> dispatchItems,
    required List<BuyerReturnEntity> buyerReturns,
    required List<BuyerReturnItemEntity> buyerReturnItems,
    required List<LabourEntryEntity> labourEntries,
    required List<LotDirectCostEntity> directCosts,
  }) {
    final revChallans = _partyCalc.reversedChallanIds(challans);
    final revReturns = _partyCalc.reversedBuyerReturnIds(buyerReturns);
    final revLabour = _ledgerCalc.reversedLabourIds(labourEntries);
    final revCosts = reversedDirectCostIds(directCosts);

    final activeChallanById = {
      for (final c in challans)
        if (!c.isReversal && !revChallans.contains(c.id)) c.id: c,
    };
    final activeReturnIds = {
      for (final r in buyerReturns)
        if (!r.isReversal && !revReturns.contains(r.id)) r.id,
    };

    // Attribute challan-level discount & other charges proportionally across
    // multi-lot challans when needed, or exact 100% when single-lot challan.
    final lotLineTotalsByChallan = <String, int>{};
    final challanAllLineTotals = <String, int>{};
    var dispatchedPieces = 0;

    for (final item in dispatchItems) {
      if (!activeChallanById.containsKey(item.challanId)) continue;
      challanAllLineTotals.update(
        item.challanId,
        (v) => v + item.lineTotalPaise,
        ifAbsent: () => item.lineTotalPaise,
      );
      if (item.lotId == lotId) {
        dispatchedPieces += item.quantity;
        lotLineTotalsByChallan.update(
          item.challanId,
          (v) => v + item.lineTotalPaise,
          ifAbsent: () => item.lineTotalPaise,
        );
      }
    }

    var grossDispatchRevenuePaise = 0;
    for (final entry in lotLineTotalsByChallan.entries) {
      final challan = activeChallanById[entry.key]!;
      final allLines = challanAllLineTotals[entry.key] ?? 0;
      if (allLines <= 0) {
        grossDispatchRevenuePaise += challan.netAmountPaise;
      } else if (entry.value == allLines) {
        grossDispatchRevenuePaise += challan.netAmountPaise;
      } else {
        grossDispatchRevenuePaise +=
            ((challan.netAmountPaise * entry.value) / allLines).round();
      }
    }

    var buyerReturnsCreditPaise = 0;
    var returnedPieces = 0;
    for (final item in buyerReturnItems) {
      if (item.lotId != lotId || !activeReturnIds.contains(item.buyerReturnId)) {
        continue;
      }
      returnedPieces += item.quantity;
      buyerReturnsCreditPaise += item.lineCreditPaise;
    }

    var workerLabourPaise = 0;
    for (final l in labourEntries) {
      if (l.lotId != lotId) continue;
      if (l.basisType == LabourBasisType.reversal ||
          revLabour.contains(l.id) ||
          !l.isPayable) {
        continue;
      }
      workerLabourPaise += l.amountPaise;
    }

    var directCostsPaise = 0;
    final directByCategory = <LotCostCategory, int>{};
    for (final c in directCosts) {
      if (c.lotId != lotId) continue;
      if (c.isReversal || revCosts.contains(c.id)) continue;
      directCostsPaise += c.amountPaise;
      directByCategory.update(
        c.category,
        (v) => v + c.amountPaise,
        ifAbsent: () => c.amountPaise,
      );
    }

    var totalInitialPieces = 0;
    var availableGoodPieces = 0;
    var inProductionOrQcPieces = 0;
    var damagedPieces = 0;
    var lostAndShortagePieces = 0;
    var unsoldEstimatedValuePaise = 0;

    for (final b in colourBalances) {
      if (b.lotId != lotId) continue;
      totalInitialPieces += b.initialQuantity;
      availableGoodPieces += b.physicalAvailableInHouse;
      inProductionOrQcPieces +=
          b.totalPendingWithWorkers + b.totalPendingInspection;
      damagedPieces += b.damagedBucket;
      lostAndShortagePieces += b.totalLost + b.totalShortage;
      if (b.physicalAvailableInHouse > 0) {
        unsoldEstimatedValuePaise +=
            b.physicalAvailableInHouse * b.unitPricePaise;
      }
    }

    final netRevenuePaise = grossDispatchRevenuePaise - buyerReturnsCreditPaise;
    final netProfitPaise =
        netRevenuePaise - workerLabourPaise - directCostsPaise;
    final double? profitMarginPercent = netRevenuePaise > 0
        ? (netProfitPaise * 100.0) / netRevenuePaise
        : null;

    return LotProfitLossSummary(
      lotId: lotId,
      lotNumber: lotNumber,
      lotTitle: lotTitle,
      totalInitialPieces: totalInitialPieces,
      availableGoodPieces: availableGoodPieces,
      inProductionOrQcPieces: inProductionOrQcPieces,
      damagedPieces: damagedPieces,
      lostAndShortagePieces: lostAndShortagePieces,
      netDispatchedPieces: dispatchedPieces - returnedPieces,
      grossDispatchRevenuePaise: grossDispatchRevenuePaise,
      buyerReturnsCreditPaise: buyerReturnsCreditPaise,
      netRevenuePaise: netRevenuePaise,
      workerLabourPaise: workerLabourPaise,
      directCostsPaise: directCostsPaise,
      directCostsByCategoryPaise: directByCategory,
      netProfitPaise: netProfitPaise,
      profitMarginPercent: profitMarginPercent,
      unsoldEstimatedValuePaise: unsoldEstimatedValuePaise,
    );
  }
}
