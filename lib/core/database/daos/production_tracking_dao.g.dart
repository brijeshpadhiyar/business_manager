// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'production_tracking_dao.dart';

// ignore_for_file: type=lint
mixin _$ProductionTrackingDaoMixin on DatabaseAccessor<AppDatabase> {
  $LotsTable get lots => attachedDatabase.lots;
  $LotDesignsTable get lotDesigns => attachedDatabase.lotDesigns;
  $DesignColoursTable get designColours => attachedDatabase.designColours;
  $ProcessesTable get processes => attachedDatabase.processes;
  $MembersTable get members => attachedDatabase.members;
  $MemberProcessRatesTable get memberProcessRates =>
      attachedDatabase.memberProcessRates;
  $StockMovementsTable get stockMovements => attachedDatabase.stockMovements;
  $JobProcessesTable get jobProcesses => attachedDatabase.jobProcesses;
  $ProductionReturnsTable get productionReturns =>
      attachedDatabase.productionReturns;
  $LabourEntriesTable get labourEntries => attachedDatabase.labourEntries;
  $ProductionInspectionsTable get productionInspections =>
      attachedDatabase.productionInspections;
  $RejectionRecordsTable get rejectionRecords =>
      attachedDatabase.rejectionRecords;
  $RejectionRepairsTable get rejectionRepairs =>
      attachedDatabase.rejectionRepairs;
  ProductionTrackingDaoManager get managers =>
      ProductionTrackingDaoManager(this);
}

class ProductionTrackingDaoManager {
  final _$ProductionTrackingDaoMixin _db;
  ProductionTrackingDaoManager(this._db);
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
  $$JobProcessesTableTableManager get jobProcesses =>
      $$JobProcessesTableTableManager(_db.attachedDatabase, _db.jobProcesses);
  $$ProductionReturnsTableTableManager get productionReturns =>
      $$ProductionReturnsTableTableManager(
        _db.attachedDatabase,
        _db.productionReturns,
      );
  $$LabourEntriesTableTableManager get labourEntries =>
      $$LabourEntriesTableTableManager(_db.attachedDatabase, _db.labourEntries);
  $$ProductionInspectionsTableTableManager get productionInspections =>
      $$ProductionInspectionsTableTableManager(
        _db.attachedDatabase,
        _db.productionInspections,
      );
  $$RejectionRecordsTableTableManager get rejectionRecords =>
      $$RejectionRecordsTableTableManager(
        _db.attachedDatabase,
        _db.rejectionRecords,
      );
  $$RejectionRepairsTableTableManager get rejectionRepairs =>
      $$RejectionRepairsTableTableManager(
        _db.attachedDatabase,
        _db.rejectionRepairs,
      );
}
