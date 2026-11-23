import 'package:drift/drift.dart';

/// 2.5 `processes` — 100% dynamic production processes (no hardcoded sequence).
@DataClassName('ProcessRow')
class Processes extends Table {
  @override
  String get tableName => 'processes';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get isActive => integer().withDefault(const Constant(1))();
  TextColumn get billingModeOverride => text().nullable()();
  IntColumn get includeDamagedInLabour =>
      integer().withDefault(const Constant(0))();
  TextColumn get createdBy => text().nullable()();
  TextColumn get updatedBy => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    'CHECK(is_active IN (0, 1))',
    "CHECK(billing_mode_override IS NULL OR billing_mode_override IN ('RECEIVED_QTY', 'GIVEN_QTY'))",
    'CHECK(include_damaged_in_labour IN (0, 1))',
  ];
}

/// 2.6 `members` — Workers / Karigars.
@DataClassName('MemberRow')
class Members extends Table {
  @override
  String get tableName => 'members';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get isActive => integer().withDefault(const Constant(1))();
  TextColumn get createdBy => text().nullable()();
  TextColumn get updatedBy => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const ['CHECK(is_active IN (0, 1))'];
}

/// 2.7 `member_processes` — Many-to-many Member <-> Process linkage.
@DataClassName('MemberProcessRow')
class MemberProcesses extends Table {
  @override
  String get tableName => 'member_processes';

  TextColumn get id => text()();
  TextColumn get memberId =>
      text().references(Members, #id, onDelete: KeyAction.restrict)();
  TextColumn get processId =>
      text().references(Processes, #id, onDelete: KeyAction.restrict)();
  IntColumn get isActive => integer().withDefault(const Constant(1))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const ['CHECK(is_active IN (0, 1))'];
}

/// 2.8 `member_process_rates` — Historical effective-dated piece rates (IST YYYY-MM-DD).
@DataClassName('MemberProcessRateRow')
class MemberProcessRates extends Table {
  @override
  String get tableName => 'member_process_rates';

  TextColumn get id => text()();
  TextColumn get memberId =>
      text().references(Members, #id, onDelete: KeyAction.restrict)();
  TextColumn get processId =>
      text().references(Processes, #id, onDelete: KeyAction.restrict)();
  IntColumn get ratePaise => integer()();
  TextColumn get effectiveFrom => text()();
  TextColumn get effectiveTo => text().nullable()();
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
    'CHECK(rate_paise >= 0)',
    'CHECK(effective_to IS NULL OR effective_to >= effective_from)',
  ];
}
