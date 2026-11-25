// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'colour_master_dao.dart';

// ignore_for_file: type=lint
mixin _$ColourMasterDaoMixin on DatabaseAccessor<AppDatabase> {
  $ColourMastersTable get colourMasters => attachedDatabase.colourMasters;
  ColourMasterDaoManager get managers => ColourMasterDaoManager(this);
}

class ColourMasterDaoManager {
  final _$ColourMasterDaoMixin _db;
  ColourMasterDaoManager(this._db);
  $$ColourMastersTableTableManager get colourMasters =>
      $$ColourMastersTableTableManager(_db.attachedDatabase, _db.colourMasters);
}
