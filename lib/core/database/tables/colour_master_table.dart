import 'package:drift/drift.dart';

/// 2.19 `colour_master` — Offline-first textile colour catalog storing curated
/// standard colours, user-created custom colours (HEX + RGB), and recently-used
/// timestamps. Added in schema v6.
@DataClassName('ColourMasterRow')
class ColourMasters extends Table {
  @override
  String get tableName => 'colour_master';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get hexCode => text()();
  IntColumn get isCustom => integer().withDefault(const Constant(0))();
  IntColumn get lastUsedAt => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK(length(trim(name)) > 0)',
    'CHECK(length(trim(hex_code)) = 7)',
    'CHECK(is_custom IN (0, 1))',
  ];
}
