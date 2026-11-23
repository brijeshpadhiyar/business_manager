import 'package:business_manager/core/database/tables/attachment_audit_tables.dart';
import 'package:drift/drift.dart';

/// 2.1 `business_profile` — Singleton configurable branding & global defaults.
@DataClassName('BusinessProfileRow')
class BusinessProfiles extends Table {
  @override
  String get tableName => 'business_profile';

  TextColumn get id => text()();
  TextColumn get nameEn =>
      text().withDefault(const Constant('Business Manager'))();
  TextColumn get nameGu =>
      text().withDefault(const Constant('બિઝનેસ મેનેજર'))();
  TextColumn get ownerName => text().nullable()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get logoAttachmentId => text().nullable().references(
    Attachments,
    #id,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get defaultBillingMode =>
      text().withDefault(const Constant('RECEIVED_QTY'))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK(default_billing_mode IN ('RECEIVED_QTY', 'GIVEN_QTY'))",
  ];
}
