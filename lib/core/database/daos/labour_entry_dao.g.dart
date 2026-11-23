// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'labour_entry_dao.dart';

// ignore_for_file: type=lint
mixin _$LabourEntryDaoMixin on DatabaseAccessor<AppDatabase> {
  $LotsTable get lots => attachedDatabase.lots;
  $LotDesignsTable get lotDesigns => attachedDatabase.lotDesigns;
  $DesignColoursTable get designColours => attachedDatabase.designColours;
  $ProcessesTable get processes => attachedDatabase.processes;
  $MembersTable get members => attachedDatabase.members;
  $MemberProcessRatesTable get memberProcessRates =>
      attachedDatabase.memberProcessRates;
  $StockMovementsTable get stockMovements => attachedDatabase.stockMovements;
  $LabourEntriesTable get labourEntries => attachedDatabase.labourEntries;
  LabourEntryDaoManager get managers => LabourEntryDaoManager(this);
}

class LabourEntryDaoManager {
  final _$LabourEntryDaoMixin _db;
  LabourEntryDaoManager(this._db);
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
  $$LabourEntriesTableTableManager get labourEntries =>
      $$LabourEntriesTableTableManager(_db.attachedDatabase, _db.labourEntries);
}
