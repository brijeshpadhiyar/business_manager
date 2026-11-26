import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/pagination/page_query.dart';
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

  Future<List<AttachmentRow>> getAllActiveAttachments() {
    return (select(attachments)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
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

  Future<List<AuditLogRow>> getRecentAuditLogs({int limit = 25}) {
    return (select(auditLogs)
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
          ..limit(limit))
        .get();
  }

  /// Fast lookup of the latest audit log for a specific action (e.g.,
  /// `BACKUP_EXPORT`), accelerated by `idx_audit_action_rec`.
  Future<AuditLogRow?> getLatestAuditByAction(String actionType) {
    return (select(auditLogs)
          ..where((t) => t.actionType.equals(actionType))
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Indexed SQLite pagination over immutable `audit_logs`.
  Future<PagedResult<AuditLogRow>> getAuditLogsPaged({
    int limit = 50,
    int offset = 0,
    String? entityType,
    String? reason,
  }) async {
    Expression<bool> predicate($AuditLogsTable t) {
      Expression<bool> expr = const Constant(true);
      if (entityType != null && entityType.isNotEmpty) {
        expr = expr & t.entityType.equals(entityType);
      }
      if (reason != null && reason.isNotEmpty) {
        expr = expr & t.reason.equals(reason);
      }
      return expr;
    }

    final countExp = auditLogs.id.count();
    final countRow = await (selectOnly(auditLogs)
          ..addColumns([countExp])
          ..where(predicate(auditLogs)))
        .getSingle();
    final total = countRow.read(countExp) ?? 0;

    final rows = await (select(auditLogs)
          ..where(predicate)
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
          ..limit(limit, offset: offset))
        .get();

    return PagedResult<AuditLogRow>(
      items: rows,
      totalCount: total,
      hasMore: offset + rows.length < total,
    );
  }
}
