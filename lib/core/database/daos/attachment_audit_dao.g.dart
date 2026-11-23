// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attachment_audit_dao.dart';

// ignore_for_file: type=lint
mixin _$AttachmentAuditDaoMixin on DatabaseAccessor<AppDatabase> {
  $AttachmentsTable get attachments => attachedDatabase.attachments;
  $AuditLogsTable get auditLogs => attachedDatabase.auditLogs;
  AttachmentAuditDaoManager get managers => AttachmentAuditDaoManager(this);
}

class AttachmentAuditDaoManager {
  final _$AttachmentAuditDaoMixin _db;
  AttachmentAuditDaoManager(this._db);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db.attachedDatabase, _db.attachments);
  $$AuditLogsTableTableManager get auditLogs =>
      $$AuditLogsTableTableManager(_db.attachedDatabase, _db.auditLogs);
}
