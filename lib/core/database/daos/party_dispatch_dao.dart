import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/tables/party_dispatch_tables.dart';
import 'package:drift/drift.dart';

part 'party_dispatch_dao.g.dart';

/// Persistence DAO for Parties, Dispatch Challans, Buyer Returns, Party
/// Payments, and Lot Direct Costs.
///
/// Ledger tables (`dispatch_challans`, `dispatch_items`, `buyer_returns`,
/// `buyer_return_items`, `party_payments`, `lot_direct_costs`) are strictly
/// append-only and never mutated or hard-deleted.
@DriftAccessor(
  tables: [
    Parties,
    DispatchChallans,
    DispatchItems,
    BuyerReturns,
    BuyerReturnItems,
    PartyPayments,
    LotDirectCosts,
  ],
)
class PartyDispatchDao extends DatabaseAccessor<AppDatabase>
    with _$PartyDispatchDaoMixin {
  PartyDispatchDao(super.db);

  // ── Parties ───────────────────────────────────────────────────────────────

  Future<void> insertParty(PartiesCompanion entry) =>
      into(parties).insert(entry);

  Future<int> updateParty(String id, PartiesCompanion entry) =>
      (update(parties)..where((t) => t.id.equals(id))).write(entry);

  Future<PartyRow?> findPartyById(String id) =>
      (select(parties)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<PartyRow>> getNonDeletedParties() {
    return (select(parties)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  // ── Dispatch Challans & Items ─────────────────────────────────────────────

  Future<void> insertDispatchChallan(DispatchChallansCompanion entry) =>
      into(dispatchChallans).insert(entry);

  Future<void> insertDispatchItem(DispatchItemsCompanion entry) =>
      into(dispatchItems).insert(entry);

  Future<DispatchChallanRow?> findChallanById(String id) => (select(
    dispatchChallans,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<DispatchChallanRow?> findChallanByClientRequestId(
    String clientRequestId,
  ) => (select(
    dispatchChallans,
  )..where((t) => t.clientRequestId.equals(clientRequestId))).getSingleOrNull();

  Future<DispatchChallanRow?> findReversalForChallan(String challanId) =>
      (select(
        dispatchChallans,
      )..where((t) => t.reversesChallanId.equals(challanId))).getSingleOrNull();

  Future<List<DispatchChallanRow>> getAllChallans() {
    return (select(dispatchChallans)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactionAt),
            (t) => OrderingTerm.desc(t.recordedAt),
          ]))
        .get();
  }

  Future<List<DispatchChallanRow>> getChallansForParty(String partyId) {
    return (select(dispatchChallans)
          ..where((t) => t.partyId.equals(partyId) & t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactionAt),
            (t) => OrderingTerm.desc(t.recordedAt),
          ]))
        .get();
  }

  Future<List<DispatchItemRow>> getAllDispatchItems() {
    return (select(dispatchItems)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<List<DispatchItemRow>> getDispatchItemsForChallan(String challanId) {
    return (select(dispatchItems)
          ..where((t) => t.challanId.equals(challanId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<List<DispatchItemRow>> getDispatchItemsForLot(String lotId) {
    return (select(dispatchItems)
          ..where((t) => t.lotId.equals(lotId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<List<DispatchItemRow>> getDispatchItemsForDesignColour(
    String designColourId,
  ) {
    return (select(dispatchItems)
          ..where(
            (t) =>
                t.designColourId.equals(designColourId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  // ── Buyer Returns & Items ─────────────────────────────────────────────────

  Future<void> insertBuyerReturn(BuyerReturnsCompanion entry) =>
      into(buyerReturns).insert(entry);

  Future<void> insertBuyerReturnItem(BuyerReturnItemsCompanion entry) =>
      into(buyerReturnItems).insert(entry);

  Future<BuyerReturnRow?> findBuyerReturnById(String id) =>
      (select(buyerReturns)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<BuyerReturnRow?> findBuyerReturnByClientRequestId(
    String clientRequestId,
  ) => (select(
    buyerReturns,
  )..where((t) => t.clientRequestId.equals(clientRequestId))).getSingleOrNull();

  Future<BuyerReturnRow?> findReversalForBuyerReturn(String returnId) =>
      (select(
        buyerReturns,
      )..where((t) => t.reversesReturnId.equals(returnId))).getSingleOrNull();

  Future<List<BuyerReturnRow>> getAllBuyerReturns() {
    return (select(buyerReturns)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactionAt),
            (t) => OrderingTerm.desc(t.recordedAt),
          ]))
        .get();
  }

  Future<List<BuyerReturnRow>> getBuyerReturnsForParty(String partyId) {
    return (select(buyerReturns)
          ..where((t) => t.partyId.equals(partyId) & t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactionAt),
            (t) => OrderingTerm.desc(t.recordedAt),
          ]))
        .get();
  }

  Future<List<BuyerReturnItemRow>> getAllBuyerReturnItems() {
    return (select(buyerReturnItems)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<List<BuyerReturnItemRow>> getBuyerReturnItemsForReturn(
    String buyerReturnId,
  ) {
    return (select(buyerReturnItems)
          ..where(
            (t) =>
                t.buyerReturnId.equals(buyerReturnId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<List<BuyerReturnItemRow>> getBuyerReturnItemsForLot(String lotId) {
    return (select(buyerReturnItems)
          ..where((t) => t.lotId.equals(lotId) & t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Future<List<BuyerReturnItemRow>> getBuyerReturnItemsForDesignColour(
    String designColourId,
  ) {
    return (select(buyerReturnItems)
          ..where(
            (t) =>
                t.designColourId.equals(designColourId) & t.deletedAt.isNull(),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  // ── Party Payments ────────────────────────────────────────────────────────

  Future<void> insertPartyPayment(PartyPaymentsCompanion entry) =>
      into(partyPayments).insert(entry);

  Future<PartyPaymentRow?> findPartyPaymentById(String id) =>
      (select(partyPayments)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<PartyPaymentRow?> findPartyPaymentByClientRequestId(
    String clientRequestId,
  ) => (select(
    partyPayments,
  )..where((t) => t.clientRequestId.equals(clientRequestId))).getSingleOrNull();

  Future<PartyPaymentRow?> findReversalForPartyPayment(String paymentId) =>
      (select(
        partyPayments,
      )..where((t) => t.reversesPaymentId.equals(paymentId))).getSingleOrNull();

  Future<List<PartyPaymentRow>> getAllPartyPayments() {
    return (select(partyPayments)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactionAt),
            (t) => OrderingTerm.desc(t.recordedAt),
          ]))
        .get();
  }

  Future<List<PartyPaymentRow>> getPartyPaymentsForParty(String partyId) {
    return (select(partyPayments)
          ..where((t) => t.partyId.equals(partyId) & t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactionAt),
            (t) => OrderingTerm.desc(t.recordedAt),
          ]))
        .get();
  }

  // ── Lot Direct Costs ──────────────────────────────────────────────────────

  Future<void> insertLotDirectCost(LotDirectCostsCompanion entry) =>
      into(lotDirectCosts).insert(entry);

  Future<LotDirectCostRow?> findLotDirectCostById(String id) =>
      (select(lotDirectCosts)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<LotDirectCostRow?> findLotDirectCostByClientRequestId(
    String clientRequestId,
  ) => (select(
    lotDirectCosts,
  )..where((t) => t.clientRequestId.equals(clientRequestId))).getSingleOrNull();

  Future<LotDirectCostRow?> findReversalForLotDirectCost(String costId) =>
      (select(
        lotDirectCosts,
      )..where((t) => t.reversesCostId.equals(costId))).getSingleOrNull();

  Future<List<LotDirectCostRow>> getAllLotDirectCosts() {
    return (select(lotDirectCosts)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactionAt),
            (t) => OrderingTerm.desc(t.recordedAt),
          ]))
        .get();
  }

  Future<List<LotDirectCostRow>> getDirectCostsForLot(String lotId) {
    return (select(lotDirectCosts)
          ..where((t) => t.lotId.equals(lotId) & t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm.desc(t.transactionAt),
            (t) => OrderingTerm.desc(t.recordedAt),
          ]))
        .get();
  }
}
