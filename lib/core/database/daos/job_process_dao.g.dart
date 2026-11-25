// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'job_process_dao.dart';

// ignore_for_file: type=lint
mixin _$JobProcessDaoMixin on DatabaseAccessor<AppDatabase> {
  $LotsTable get lots => attachedDatabase.lots;
  $LotDesignsTable get lotDesigns => attachedDatabase.lotDesigns;
  $DesignColoursTable get designColours => attachedDatabase.designColours;
  $ProcessesTable get processes => attachedDatabase.processes;
  $MembersTable get members => attachedDatabase.members;
  $MemberProcessRatesTable get memberProcessRates =>
      attachedDatabase.memberProcessRates;
  $StockMovementsTable get stockMovements => attachedDatabase.stockMovements;
  $JobProcessesTable get jobProcesses => attachedDatabase.jobProcesses;
  $ProcessHandoversTable get processHandovers =>
      attachedDatabase.processHandovers;
  $ProcessAdditionalChargesTable get processAdditionalCharges =>
      attachedDatabase.processAdditionalCharges;
  $ProcessRateHistoriesTable get processRateHistories =>
      attachedDatabase.processRateHistories;
  JobProcessDaoManager get managers => JobProcessDaoManager(this);
}

class JobProcessDaoManager {
  final _$JobProcessDaoMixin _db;
  JobProcessDaoManager(this._db);
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
  $$ProcessHandoversTableTableManager get processHandovers =>
      $$ProcessHandoversTableTableManager(
        _db.attachedDatabase,
        _db.processHandovers,
      );
  $$ProcessAdditionalChargesTableTableManager get processAdditionalCharges =>
      $$ProcessAdditionalChargesTableTableManager(
        _db.attachedDatabase,
        _db.processAdditionalCharges,
      );
  $$ProcessRateHistoriesTableTableManager get processRateHistories =>
      $$ProcessRateHistoriesTableTableManager(
        _db.attachedDatabase,
        _db.processRateHistories,
      );
}
