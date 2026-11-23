// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lot_dao.dart';

// ignore_for_file: type=lint
mixin _$LotDaoMixin on DatabaseAccessor<AppDatabase> {
  $LotsTable get lots => attachedDatabase.lots;
  $LotDesignsTable get lotDesigns => attachedDatabase.lotDesigns;
  $DesignColoursTable get designColours => attachedDatabase.designColours;
  LotDaoManager get managers => LotDaoManager(this);
}

class LotDaoManager {
  final _$LotDaoMixin _db;
  LotDaoManager(this._db);
  $$LotsTableTableManager get lots =>
      $$LotsTableTableManager(_db.attachedDatabase, _db.lots);
  $$LotDesignsTableTableManager get lotDesigns =>
      $$LotDesignsTableTableManager(_db.attachedDatabase, _db.lotDesigns);
  $$DesignColoursTableTableManager get designColours =>
      $$DesignColoursTableTableManager(_db.attachedDatabase, _db.designColours);
}
