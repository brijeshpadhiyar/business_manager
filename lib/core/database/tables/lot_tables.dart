import 'package:drift/drift.dart';

/// 2.2 `lots` — Production lots with unique active lot numbers.
@DataClassName('LotRow')
class Lots extends Table {
  @override
  String get tableName => 'lots';

  TextColumn get id => text()();
  TextColumn get lotNumber => text()();
  TextColumn get title => text().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('ACTIVE'))();
  IntColumn get transactionAt => integer()();
  IntColumn get recordedAt => integer()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get updatedBy => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK(status IN ('ACTIVE', 'COMPLETED', 'ARCHIVED'))",
  ];
}

/// 2.3 `lot_designs` — Designs nested within a lot.
@DataClassName('LotDesignRow')
class LotDesigns extends Table {
  @override
  String get tableName => 'lot_designs';

  TextColumn get id => text()();
  TextColumn get lotId =>
      text().references(Lots, #id, onDelete: KeyAction.restrict)();
  TextColumn get designName => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get updatedBy => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// 2.4 `design_colours` — Atomic quantity-tracked Design + Colour SKU units.
@DataClassName('DesignColourRow')
class DesignColours extends Table {
  @override
  String get tableName => 'design_colours';

  TextColumn get id => text()();
  TextColumn get lotDesignId =>
      text().references(LotDesigns, #id, onDelete: KeyAction.restrict)();
  TextColumn get colourName => text()();
  TextColumn get colourHex => text().nullable()();
  IntColumn get initialQuantity => integer()();
  IntColumn get unitPricePaise => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  TextColumn get createdBy => text().nullable()();
  TextColumn get updatedBy => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK(initial_quantity > 0)',
    'CHECK(unit_price_paise >= 0)',
  ];
}
