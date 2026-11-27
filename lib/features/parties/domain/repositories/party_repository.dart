import 'package:business_manager/features/parties/domain/entities/party_entities.dart';

abstract interface class PartyRepository {
  Future<List<PartyFinancialSummary>> getAllPartySummaries({
    String? searchQuery,
    bool includeInactive = true,
  });

  Future<PartyEntity?> getPartyById(String partyId);

  Future<PartyLedgerDetail?> getPartyLedgerDetail(
    String partyId, {
    int? fromUtcMillis,
    int? toUtcMillis,
  });

  Future<PartyEntity> createParty({
    required String name,
    String? phone,
    String? address,
    PartyType partyType = PartyType.both,
    String? gstin,
    int openingBalancePaise = 0,
    String? notes,
  });

  Future<PartyEntity> updateParty({
    required String partyId,
    required String name,
    String? phone,
    String? address,
    required PartyType partyType,
    String? gstin,
    required int openingBalancePaise,
    String? notes,
    required bool isActive,
  });

  Future<String> suggestNextChallanNumber();

  Future<String> suggestNextReturnNumber();

  Future<List<DispatchChallanView>> getDispatchChallans({String? partyId});

  Future<DispatchChallanView?> getDispatchChallanDetail(String challanId);

  Future<DispatchChallanView> createDispatchChallan({
    required String partyId,
    required String challanNumber,
    required List<DispatchLineDraft> items,
    int discountPaise = 0,
    int otherChargesPaise = 0,
    String? notes,
    required int transactionAtUtcMillis,
    String? clientRequestId,
  });

  Future<DispatchChallanEntity> reverseDispatchChallan({
    required String challanId,
    required String reason,
    String? notes,
    int? transactionAtUtcMillis,
  });

  Future<BuyerReturnView> createBuyerReturn({
    required String partyId,
    String? challanId,
    required String returnNumber,
    required List<BuyerReturnLineDraft> items,
    required String reason,
    String? notes,
    required int transactionAtUtcMillis,
    String? clientRequestId,
  });

  Future<BuyerReturnEntity> reverseBuyerReturn({
    required String buyerReturnId,
    required String reason,
    String? notes,
    int? transactionAtUtcMillis,
  });

  Future<PartyPaymentEntity> recordPartyPayment({
    required String partyId,
    String? challanId,
    required PartyPaymentType paymentType,
    required PartyPaymentMode paymentMode,
    required int amountPaise,
    String? referenceNo,
    String? notes,
    required int transactionAtUtcMillis,
    String? clientRequestId,
  });

  Future<PartyPaymentEntity> reversePartyPayment({
    required String paymentId,
    required String reason,
    String? notes,
    int? transactionAtUtcMillis,
  });

  Future<List<LotDirectCostEntity>> getLotDirectCosts(String lotId);

  Future<LotDirectCostEntity> addLotDirectCost({
    required String lotId,
    required LotCostCategory category,
    required String description,
    required int amountPaise,
    String? notes,
    required int transactionAtUtcMillis,
    String? clientRequestId,
  });

  Future<LotDirectCostEntity> reverseLotDirectCost({
    required String costId,
    required String reason,
    String? notes,
    int? transactionAtUtcMillis,
  });

  Future<LotProfitLossSummary?> getLotProfitLoss(String lotId);

  Future<List<LotProfitLossSummary>> getAllLotProfitLoss();
}
