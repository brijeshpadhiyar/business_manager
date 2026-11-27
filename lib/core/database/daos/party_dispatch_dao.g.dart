// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'party_dispatch_dao.dart';

// ignore_for_file: type=lint
mixin _$PartyDispatchDaoMixin on DatabaseAccessor<AppDatabase> {
  $PartiesTable get parties => attachedDatabase.parties;
  $DispatchChallansTable get dispatchChallans =>
      attachedDatabase.dispatchChallans;
  $LotsTable get lots => attachedDatabase.lots;
  $LotDesignsTable get lotDesigns => attachedDatabase.lotDesigns;
  $DesignColoursTable get designColours => attachedDatabase.designColours;
  $DispatchItemsTable get dispatchItems => attachedDatabase.dispatchItems;
  $BuyerReturnsTable get buyerReturns => attachedDatabase.buyerReturns;
  $BuyerReturnItemsTable get buyerReturnItems =>
      attachedDatabase.buyerReturnItems;
  $PartyPaymentsTable get partyPayments => attachedDatabase.partyPayments;
  $LotDirectCostsTable get lotDirectCosts => attachedDatabase.lotDirectCosts;
  PartyDispatchDaoManager get managers => PartyDispatchDaoManager(this);
}

class PartyDispatchDaoManager {
  final _$PartyDispatchDaoMixin _db;
  PartyDispatchDaoManager(this._db);
  $$PartiesTableTableManager get parties =>
      $$PartiesTableTableManager(_db.attachedDatabase, _db.parties);
  $$DispatchChallansTableTableManager get dispatchChallans =>
      $$DispatchChallansTableTableManager(
        _db.attachedDatabase,
        _db.dispatchChallans,
      );
  $$LotsTableTableManager get lots =>
      $$LotsTableTableManager(_db.attachedDatabase, _db.lots);
  $$LotDesignsTableTableManager get lotDesigns =>
      $$LotDesignsTableTableManager(_db.attachedDatabase, _db.lotDesigns);
  $$DesignColoursTableTableManager get designColours =>
      $$DesignColoursTableTableManager(_db.attachedDatabase, _db.designColours);
  $$DispatchItemsTableTableManager get dispatchItems =>
      $$DispatchItemsTableTableManager(_db.attachedDatabase, _db.dispatchItems);
  $$BuyerReturnsTableTableManager get buyerReturns =>
      $$BuyerReturnsTableTableManager(_db.attachedDatabase, _db.buyerReturns);
  $$BuyerReturnItemsTableTableManager get buyerReturnItems =>
      $$BuyerReturnItemsTableTableManager(
        _db.attachedDatabase,
        _db.buyerReturnItems,
      );
  $$PartyPaymentsTableTableManager get partyPayments =>
      $$PartyPaymentsTableTableManager(_db.attachedDatabase, _db.partyPayments);
  $$LotDirectCostsTableTableManager get lotDirectCosts =>
      $$LotDirectCostsTableTableManager(
        _db.attachedDatabase,
        _db.lotDirectCosts,
      );
}
