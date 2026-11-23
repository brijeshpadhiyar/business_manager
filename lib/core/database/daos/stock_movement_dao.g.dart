// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_movement_dao.dart';

// ignore_for_file: type=lint
mixin _$StockMovementDaoMixin on DatabaseAccessor<AppDatabase> {
  $LotsTable get lots => attachedDatabase.lots;
  $LotDesignsTable get lotDesigns => attachedDatabase.lotDesigns;
  $DesignColoursTable get designColours => attachedDatabase.designColours;
  $ProcessesTable get processes => attachedDatabase.processes;
  $MembersTable get members => attachedDatabase.members;
  $MemberProcessRatesTable get memberProcessRates =>
      attachedDatabase.memberProcessRates;
  $StockMovementsTable get stockMovements => attachedDatabase.stockMovements;
  StockMovementDaoManager get managers => StockMovementDaoManager(this);
}

class StockMovementDaoManager {
  final _$StockMovementDaoMixin _db;
  StockMovementDaoManager(this._db);
  $$LotsTableTableManager get lots =>
      $$LotsTableTableManager(_db.attachedDatabase, _db.lots);
  $$LotDesignsTableTableManager get lotDesigns =>
      $$LotDesignsTableTableManager(_db.attachedDatabase, _db.lotDesigns);
  $$DesignColoursTableTableManager get designColours =>
      $$DesignColoursTableTableManager(_db.attachedDatabase, _db.designColours);
  $$ProcessesTableTableManager get processes =>
      $$ProcessesTableTableManager(_db.attachedDatabase, _db.processes);
  $$MembersTableTableManager get members =>
      $$MembersTableTableManager(_db.attachedDatabase, _db.members);
  $$MemberProcessRatesTableTableManager get memberProcessRates =>
      $$MemberProcessRatesTableTableManager(
        _db.attachedDatabase,
        _db.memberProcessRates,
      );
  $$StockMovementsTableTableManager get stockMovements =>
      $$StockMovementsTableTableManager(
        _db.attachedDatabase,
        _db.stockMovements,
      );
}
