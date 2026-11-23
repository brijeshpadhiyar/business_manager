import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/tables/attachment_audit_tables.dart';
import 'package:drift/drift.dart';

part 'attachment_audit_dao.g.dart';

/// DAO for local `attachments` metadata and strictly append-only `audit_logs`.
@DriftAccessor(tables: [Attachments, AuditLogs])
class AttachmentAuditDao extends DatabaseAccessor<AppDatabase>
    with _$AttachmentAuditDaoMixin {
  AttachmentAuditDao(super.db);

  Future<void> insertAttachment(AttachmentsCompanion entry) =>
      into(attachments).insert(entry);

  Future<List<AttachmentRow>> getActiveAttachments(
    String entityType,
    String entityId,
  ) {
    return (select(attachments)..where(
          (t) =>
              t.entityType.equals(entityType) &
              t.entityId.equals(entityId) &
              t.deletedAt.isNull(),
        ))
        .get();
  }

  Future<int> softDeleteAttachment(String id, int deletedAtUtcMillis) {
    return (update(attachments)..where((t) => t.id.equals(id))).write(
      AttachmentsCompanion(
        deletedAt: Value(deletedAtUtcMillis),
        updatedAt: Value(deletedAtUtcMillis),
      ),
    );
  }

  /// Append-only audit log insertion — never exposes UPDATE or DELETE.
  Future<void> insertAuditLog(AuditLogsCompanion entry) =>
      into(auditLogs).insert(entry);

  Future<List<AuditLogRow>> getAuditLogsForEntity(
    String entityType,
    String entityId,
  ) {
    return (select(auditLogs)
          ..where(
            (t) =>
                t.entityType.equals(entityType) & t.entityId.equals(entityId),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]))
        .get();
  }
}
