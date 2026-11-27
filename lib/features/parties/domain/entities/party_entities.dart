/// Classification of a commercial party in StitchFlow.
enum PartyType {
  buyer('BUYER'),
  jobClient('JOB_CLIENT'),
  both('BOTH');

  const PartyType(this.dbValue);
  final String dbValue;

  static PartyType fromDbValue(String? raw) {
    return PartyType.values.firstWhere(
      (e) => e.dbValue == raw?.trim().toUpperCase(),
      orElse: () => PartyType.both,
    );
  }
}

/// Condition of pieces returned by a buyer/party.
enum BuyerReturnCondition {
  good('GOOD'),
  damaged('DAMAGED');

  const BuyerReturnCondition(this.dbValue);
  final String dbValue;

  static BuyerReturnCondition fromDbValue(String raw) {
    return BuyerReturnCondition.values.firstWhere(
      (e) => e.dbValue == raw.trim().toUpperCase(),
      orElse: () => BuyerReturnCondition.good,
    );
  }
}

/// Strict discriminator matching `party_payments.payment_type`.
enum PartyPaymentType {
  receipt('RECEIPT'),
  advance('ADVANCE'),
  refund('REFUND'),
  reversal('REVERSAL');

  const PartyPaymentType(this.dbValue);
  final String dbValue;

  static PartyPaymentType fromDbValue(String raw) {
    return PartyPaymentType.values.firstWhere(
      (e) => e.dbValue == raw.trim().toUpperCase(),
      orElse: () => throw ArgumentError('Unknown PartyPaymentType: $raw'),
    );
  }
}

/// Payment instrument used by a party.
enum PartyPaymentMode {
  cash('CASH'),
  upi('UPI'),
  bankTransfer('BANK_TRANSFER'),
  cheque('CHEQUE'),
  other('OTHER');

  const PartyPaymentMode(this.dbValue);
  final String dbValue;

  static PartyPaymentMode fromDbValue(String raw) {
    return PartyPaymentMode.values.firstWhere(
      (e) => e.dbValue == raw.trim().toUpperCase(),
      orElse: () => PartyPaymentMode.other,
    );
  }
}

/// Category for optional non-labour direct costs on a Lot.
enum LotCostCategory {
  fabric('FABRIC'),
  trims('TRIMS'),
  transport('TRANSPORT'),
  packing('PACKING'),
  other('OTHER');

  const LotCostCategory(this.dbValue);
  final String dbValue;

  static LotCostCategory fromDbValue(String raw) {
    return LotCostCategory.values.firstWhere(
      (e) => e.dbValue == raw.trim().toUpperCase(),
      orElse: () => LotCostCategory.other,
    );
  }
}

final class PartyEntity {
  const PartyEntity({
    required this.id,
    required this.name,
    this.phone,
    this.address,
    required this.partyType,
    this.gstin,
    required this.openingBalancePaise,
    this.notes,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? phone;
  final String? address;
  final PartyType partyType;
  final String? gstin;
  final int openingBalancePaise;
  final String? notes;
  final bool isActive;
  final int createdAt;
  final int updatedAt;
}

final class DispatchItemEntity {
  const DispatchItemEntity({
    required this.id,
    required this.challanId,
    required this.lotId,
    required this.lotDesignId,
    required this.designColourId,
    required this.quantity,
    required this.ratePaise,
    required this.lineTotalPaise,
    required this.createdAt,
    required this.updatedAt,
    this.lotNumber = '',
    this.designName = '',
    this.colourName = '',
    this.colourHex,
  });

  final String id;
  final String challanId;
  final String lotId;
  final String lotDesignId;
  final String designColourId;
  final int quantity;
  final int ratePaise;
  final int lineTotalPaise;
  final int createdAt;
  final int updatedAt;
  final String lotNumber;
  final String designName;
  final String colourName;
  final String? colourHex;
}

final class DispatchChallanEntity {
  const DispatchChallanEntity({
    required this.id,
    required this.challanNumber,
    required this.partyId,
    this.reversesChallanId,
    this.clientRequestId,
    required this.grossAmountPaise,
    required this.discountPaise,
    required this.otherChargesPaise,
    required this.netAmountPaise,
    this.reason,
    this.notes,
    required this.transactionAt,
    required this.recordedAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String challanNumber;
  final String partyId;
  final String? reversesChallanId;
  final String? clientRequestId;
  final int grossAmountPaise;
  final int discountPaise;
  final int otherChargesPaise;
  final int netAmountPaise;
  final String? reason;
  final String? notes;
  final int transactionAt;
  final int recordedAt;
  final String? createdBy;
  final int createdAt;
  final int updatedAt;

  bool get isReversal => reversesChallanId != null;
}

final class DispatchChallanView {
  const DispatchChallanView({
    required this.challan,
    required this.partyName,
    this.partyPhone,
    this.partyAddress,
    required this.items,
    required this.isReversed,
    this.reversedByChallanId,
    this.returnedQtyByItemId = const {},
  });

  final DispatchChallanEntity challan;
  final String partyName;
  final String? partyPhone;
  final String? partyAddress;
  final List<DispatchItemEntity> items;
  final bool isReversed;
  final String? reversedByChallanId;
  final Map<String, int> returnedQtyByItemId;

  int get totalPieces =>
      items.fold<int>(0, (sum, item) => sum + item.quantity);

  int get totalReturnedPieces =>
      returnedQtyByItemId.values.fold<int>(0, (sum, q) => sum + q);

  int get remainingReturnablePieces =>
      (totalPieces - totalReturnedPieces).clamp(0, totalPieces);
}

final class BuyerReturnItemEntity {
  const BuyerReturnItemEntity({
    required this.id,
    required this.buyerReturnId,
    this.dispatchItemId,
    required this.lotId,
    required this.lotDesignId,
    required this.designColourId,
    required this.returnCondition,
    required this.quantity,
    required this.ratePaise,
    required this.lineCreditPaise,
    required this.createdAt,
    required this.updatedAt,
    this.lotNumber = '',
    this.designName = '',
    this.colourName = '',
  });

  final String id;
  final String buyerReturnId;
  final String? dispatchItemId;
  final String lotId;
  final String lotDesignId;
  final String designColourId;
  final BuyerReturnCondition returnCondition;
  final int quantity;
  final int ratePaise;
  final int lineCreditPaise;
  final int createdAt;
  final int updatedAt;
  final String lotNumber;
  final String designName;
  final String colourName;
}

final class BuyerReturnEntity {
  const BuyerReturnEntity({
    required this.id,
    required this.returnNumber,
    required this.partyId,
    this.challanId,
    this.reversesReturnId,
    this.clientRequestId,
    required this.creditAmountPaise,
    required this.reason,
    this.notes,
    required this.transactionAt,
    required this.recordedAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String returnNumber;
  final String partyId;
  final String? challanId;
  final String? reversesReturnId;
  final String? clientRequestId;
  final int creditAmountPaise;
  final String reason;
  final String? notes;
  final int transactionAt;
  final int recordedAt;
  final String? createdBy;
  final int createdAt;
  final int updatedAt;

  bool get isReversal => reversesReturnId != null;
}

final class BuyerReturnView {
  const BuyerReturnView({
    required this.buyerReturn,
    required this.partyName,
    this.challanNumber,
    required this.items,
    required this.isReversed,
  });

  final BuyerReturnEntity buyerReturn;
  final String partyName;
  final String? challanNumber;
  final List<BuyerReturnItemEntity> items;
  final bool isReversed;

  int get totalPieces => items.fold<int>(0, (sum, i) => sum + i.quantity);
}

final class PartyPaymentEntity {
  const PartyPaymentEntity({
    required this.id,
    required this.partyId,
    this.challanId,
    this.reversesPaymentId,
    this.clientRequestId,
    required this.paymentType,
    required this.paymentMode,
    required this.amountPaise,
    this.referenceNo,
    this.reason,
    this.notes,
    required this.transactionAt,
    required this.recordedAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String partyId;
  final String? challanId;
  final String? reversesPaymentId;
  final String? clientRequestId;
  final PartyPaymentType paymentType;
  final PartyPaymentMode paymentMode;
  final int amountPaise;
  final String? referenceNo;
  final String? reason;
  final String? notes;
  final int transactionAt;
  final int recordedAt;
  final String? createdBy;
  final int createdAt;
  final int updatedAt;
}

final class LotDirectCostEntity {
  const LotDirectCostEntity({
    required this.id,
    required this.lotId,
    this.reversesCostId,
    this.clientRequestId,
    required this.category,
    required this.description,
    required this.amountPaise,
    this.reason,
    this.notes,
    required this.transactionAt,
    required this.recordedAt,
    this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String lotId;
  final String? reversesCostId;
  final String? clientRequestId;
  final LotCostCategory category;
  final String description;
  final int amountPaise;
  final String? reason;
  final String? notes;
  final int transactionAt;
  final int recordedAt;
  final String? createdBy;
  final int createdAt;
  final int updatedAt;

  bool get isReversal => reversesCostId != null;
}

enum PartyLedgerEntryKind {
  dispatch,
  buyerReturn,
  receipt,
  advance,
  refund,
}

final class PartyLedgerEntry {
  const PartyLedgerEntry({
    required this.id,
    required this.kind,
    required this.referenceNumber,
    required this.description,
    this.notes,
    required this.debitPaise,
    required this.creditPaise,
    required this.runningBalancePaise,
    required this.transactionAt,
    required this.recordedAt,
    required this.isReversed,
    this.paymentMode,
  });

  final String id;
  final PartyLedgerEntryKind kind;
  final String referenceNumber;
  final String description;
  final String? notes;

  /// Positive receivable charge (Dispatch / Advance Refund).
  final int debitPaise;

  /// Reduces receivable / builds advance credit (Buyer Return / Receipt / Advance).
  final int creditPaise;

  /// Positive = receivable due from party; negative = party advance credit.
  final int runningBalancePaise;
  final int transactionAt;
  final int recordedAt;
  final bool isReversed;
  final PartyPaymentMode? paymentMode;
}

final class PartyFinancialSummary {
  const PartyFinancialSummary({
    required this.partyId,
    required this.partyName,
    this.partyPhone,
    required this.partyType,
    required this.isActive,
    required this.openingBalancePaise,
    required this.totalDispatchedNetPaise,
    required this.totalBuyerReturnsPaise,
    required this.totalReceiptsPaise,
    required this.totalAdvancesPaise,
    required this.totalRefundsPaise,
    required this.netBalancePaise,
    required this.totalDispatchedPieces,
    required this.totalReturnedPieces,
  });

  final String partyId;
  final String partyName;
  final String? partyPhone;
  final PartyType partyType;
  final bool isActive;
  final int openingBalancePaise;
  final int totalDispatchedNetPaise;
  final int totalBuyerReturnsPaise;
  final int totalReceiptsPaise;
  final int totalAdvancesPaise;
  final int totalRefundsPaise;

  /// Signed balance: > 0 means receivable due; < 0 means party advance credit.
  final int netBalancePaise;
  final int totalDispatchedPieces;
  final int totalReturnedPieces;

  int get outstandingReceivablePaise => netBalancePaise > 0 ? netBalancePaise : 0;
  int get advanceCreditPaise => netBalancePaise < 0 ? -netBalancePaise : 0;
  int get totalCollectedNetPaise =>
      totalReceiptsPaise + totalAdvancesPaise - totalRefundsPaise;
}

final class PartyLedgerDetail {
  const PartyLedgerDetail({
    required this.party,
    required this.summary,
    required this.entries,
    required this.challans,
    required this.buyerReturns,
    required this.payments,
  });

  final PartyEntity party;
  final PartyFinancialSummary summary;
  final List<PartyLedgerEntry> entries;
  final List<DispatchChallanView> challans;
  final List<BuyerReturnView> buyerReturns;
  final List<PartyPaymentEntity> payments;
}

final class LotProfitLossSummary {
  const LotProfitLossSummary({
    required this.lotId,
    required this.lotNumber,
    this.lotTitle,
    required this.totalInitialPieces,
    required this.availableGoodPieces,
    required this.inProductionOrQcPieces,
    required this.damagedPieces,
    required this.lostAndShortagePieces,
    required this.netDispatchedPieces,
    required this.grossDispatchRevenuePaise,
    required this.buyerReturnsCreditPaise,
    required this.netRevenuePaise,
    required this.workerLabourPaise,
    required this.directCostsPaise,
    required this.directCostsByCategoryPaise,
    required this.netProfitPaise,
    required this.profitMarginPercent,
    required this.unsoldEstimatedValuePaise,
  });

  final String lotId;
  final String lotNumber;
  final String? lotTitle;
  final int totalInitialPieces;
  final int availableGoodPieces;
  final int inProductionOrQcPieces;
  final int damagedPieces;
  final int lostAndShortagePieces;
  final int netDispatchedPieces;
  final int grossDispatchRevenuePaise;
  final int buyerReturnsCreditPaise;
  final int netRevenuePaise;
  final int workerLabourPaise;
  final int directCostsPaise;
  final Map<LotCostCategory, int> directCostsByCategoryPaise;
  final int netProfitPaise;
  final double? profitMarginPercent;
  final int unsoldEstimatedValuePaise;

  int get totalCostPaise => workerLabourPaise + directCostsPaise;
}

final class DispatchLineDraft {
  const DispatchLineDraft({
    required this.lotId,
    required this.lotDesignId,
    required this.designColourId,
    required this.quantity,
    required this.ratePaise,
  });

  final String lotId;
  final String lotDesignId;
  final String designColourId;
  final int quantity;
  final int ratePaise;
}

final class BuyerReturnLineDraft {
  const BuyerReturnLineDraft({
    this.dispatchItemId,
    required this.lotId,
    required this.lotDesignId,
    required this.designColourId,
    required this.returnCondition,
    required this.quantity,
    required this.ratePaise,
  });

  final String? dispatchItemId;
  final String lotId;
  final String lotDesignId;
  final String designColourId;
  final BuyerReturnCondition returnCondition;
  final int quantity;
  final int ratePaise;
}

/// Aggregated physical stock delta from active party dispatches & buyer returns
/// for a single `design_colour_id`.
final class PartyDispatchStockDelta {
  const PartyDispatchStockDelta({
    this.dispatchedOutQty = 0,
    this.buyerReturnedGoodQty = 0,
    this.buyerReturnedDamagedQty = 0,
  });

  final int dispatchedOutQty;
  final int buyerReturnedGoodQty;
  final int buyerReturnedDamagedQty;

  int get netDispatchedQty =>
      dispatchedOutQty - buyerReturnedGoodQty - buyerReturnedDamagedQty;
}
