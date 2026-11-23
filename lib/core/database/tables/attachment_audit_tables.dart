import 'package:drift/drift.dart';

/// 2.12 `attachments` — Local private media & photos metadata (relative paths + SHA-256).
@DataClassName('AttachmentRow')
class Attachments extends Table {
  @override
  String get tableName => 'attachments';

  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get relativePath => text()();
  TextColumn get mimeType => text()();
  IntColumn get fileSizeBytes => integer()();
  TextColumn get sha256 => text()();
  TextColumn get caption => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK(entity_type IN ('LOT', 'STOCK_MOVEMENT', 'PAYMENT', 'BUSINESS_PROFILE'))",
  ];
}

/// 2.13 `audit_logs` — Complete immutable audit trail across all entities.
@DataClassName('AuditLogRow')
class AuditLogs extends Table {
  @override
  String get tableName => 'audit_logs';

  TextColumn get id => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get actionType => text()();
  TextColumn get actor => text().nullable()();
  TextColumn get previousValueJson => text().nullable()();
  TextColumn get newValueJson => text().nullable()();
  TextColumn get reason => text().nullable()();
  IntColumn get transactionAt => integer()();
  IntColumn get recordedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
    "CHECK(action_type IN ('CREATE', 'UPDATE', 'SOFT_DELETE', 'DEACTIVATE', 'REACTIVATE', 'RATE_OVERRIDE', 'REVERSAL', 'DAMAGED_TO_GOOD_ADJUSTMENT', 'BACKUP_EXPORT', 'BACKUP_RESTORE'))",
  ];
}
