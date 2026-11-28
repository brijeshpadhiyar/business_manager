import 'dart:convert';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_identity.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/migrations/database_migration_manager.dart';
import 'package:business_manager/core/platform/web_browser_bridge.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/backup/domain/entities/backup_entities.dart';
import 'package:business_manager/features/backup/domain/services/backup_restore_service.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

/// Pure-Dart offline Web backup & transactional restore implementation using
/// SHA-256 verified JSON snapshots across all StitchFlow Schema v8 tables.
final class WebBackupRestoreService implements BackupRestoreService {
  WebBackupRestoreService(this._db, this._config, this._idGenerator);

  final AppDatabase _db;
  final AppConfig _config;
  final IdGenerator _idGenerator;

  /// Ordered parent-before-child table list for FK-safe export & restore.
  static const List<String> _orderedTables = [
    'business_profile',
    'colour_master',
    'processes',
    'members',
    'member_processes',
    'member_process_rates',
    'lots',
    'lot_designs',
    'design_colours',
    'job_processes',
    'stock_movements',
    'process_handovers',
    'process_additional_charges',
    'process_rate_history',
    'production_returns',
    'production_inspections',
    'rejection_records',
    'rejection_repairs',
    'labour_entries',
    'payments',
    'worker_ledger_adjustments',
    'parties',
    'dispatch_challans',
    'dispatch_items',
    'buyer_returns',
    'buyer_return_items',
    'party_payments',
    'lot_direct_costs',
    'workshop_expenses',
    'cashbook_entries',
    'attachments',
    'audit_logs',
  ];

  static final Map<String, Uint8List> _stagedPayloads = <String, Uint8List>{};

  /// Stores bytes picked via browser FilePicker and returns a synthetic token
  /// path consumable by [validateBackupZip] and [restoreFromZip].
  static String stagePickedBytes(Uint8List bytes, {String? fileName}) {
    final token =
        'web://picked/${DateTime.now().microsecondsSinceEpoch}_${fileName ?? 'backup.json'}';
    _stagedPayloads[token] = bytes;
    return token;
  }

  /// Exposed for automated tests verifying snapshot generation directly.
  Future<(Uint8List bytes, BackupManifest manifest)> buildSnapshotBytes({
    BackupProgressCallback? onProgress,
  }) async {
    onProgress?.call(const BackupProgress(stageCode: 'reading', fraction: 0.2));
    final tablesData = <String, List<Map<String, Object?>>>{};
    for (final table in _orderedTables) {
      final rows = await _db.customSelect('SELECT * FROM $table').get();
      tablesData[table] = rows
          .map((r) => Map<String, Object?>.of(r.data))
          .toList();
    }

    onProgress?.call(
      const BackupProgress(stageCode: 'checksums', fraction: 0.65),
    );
    final canonicalTablesJson = jsonEncode(tablesData);
    final tablesBytes = utf8.encode(canonicalTablesJson);
    final sha = sha256.convert(tablesBytes).toString();
    final nowUtc = IstDateTimeHelper.nowUtcMillis();

    final manifest = BackupManifest(
      formatVersion: BackupManifest.currentFormatVersion,
      appVersion: '${AppIdentity.appVersion}+${AppIdentity.appBuildNumber}',
      flavor: _config.flavor.name,
      schemaVersion: DatabaseMigrationManager.currentSchemaVersion,
      createdAtUtc: DateTime.fromMillisecondsSinceEpoch(
        nowUtc,
        isUtc: true,
      ).toIso8601String(),
      createdAtIst: IstDateTimeHelper.formatIstIsoDateTime(nowUtc),
      databaseSha256: sha,
      databaseSizeBytes: tablesBytes.length,
      attachmentsCount: 0,
      attachments: const [],
      summaryCounts: BackupSummaryCounts(
        lotsCount: tablesData['lots']?.length ?? 0,
        workersCount: tablesData['members']?.length ?? 0,
        processesCount: tablesData['processes']?.length ?? 0,
        movementsCount: tablesData['stock_movements']?.length ?? 0,
        paymentsCount: tablesData['payments']?.length ?? 0,
      ),
    );

    final envelope = <String, dynamic>{
      'manifest': manifest.toJson(),
      'tables': tablesData,
    };
    final outBytes = Uint8List.fromList(utf8.encode(jsonEncode(envelope)));
    return (outBytes, manifest);
  }

  @override
  Future<BackupExportResult> createFullZipBackup({
    String? destinationDirectoryPath,
    BackupProgressCallback? onProgress,
  }) async {
    final (bytes, manifest) = await buildSnapshotBytes(onProgress: onProgress);
    final nowUtc = IstDateTimeHelper.nowUtcMillis();
    final stamp = IstDateTimeHelper.formatIstFileTimestamp(nowUtc);
    final fileName = 'stitchflow_web_backup_${_config.flavor.name}_$stamp.json';

    downloadBytesInBrowser(bytes, fileName, 'application/json');
    await _recordAudit('BACKUP_EXPORT', {
      'file_name': fileName,
      'size_bytes': bytes.length,
      'platform': 'web',
    });

    onProgress?.call(const BackupProgress(stageCode: 'done', fraction: 1.0));
    return BackupExportResult(
      filePath: 'browser://downloads/$fileName',
      fileName: fileName,
      sizeBytes: bytes.length,
      createdAtUtcMillis: nowUtc,
      manifest: manifest,
    );
  }

  @override
  Future<BackupExportResult> exportRawSqlite({
    String? destinationDirectoryPath,
    BackupProgressCallback? onProgress,
  }) {
    return createFullZipBackup(
      destinationDirectoryPath: destinationDirectoryPath,
      onProgress: onProgress,
    );
  }

  @override
  Future<BackupValidationResult> validateBackupZip(
    String zipFilePath, {
    BackupProgressCallback? onProgress,
  }) async {
    onProgress?.call(
      const BackupProgress(stageCode: 'validating', fraction: 0.3),
    );
    final bytes = _stagedPayloads[zipFilePath];
    if (bytes == null || bytes.isEmpty) {
      return const BackupValidationResult(
        isValid: false,
        errorCodes: ['BACKUP_MISSING_PAYLOAD'],
        errors: ['Selected backup file payload was not found.'],
      );
    }

    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        return const BackupValidationResult(
          isValid: false,
          errorCodes: ['BACKUP_INVALID_JSON'],
          errors: ['Backup file is not a valid StitchFlow JSON snapshot.'],
        );
      }
      final manifestJson = decoded['manifest'];
      final tablesJson = decoded['tables'];
      if (manifestJson is! Map<String, dynamic> ||
          tablesJson is! Map<String, dynamic>) {
        return const BackupValidationResult(
          isValid: false,
          errorCodes: ['BACKUP_INVALID_STRUCTURE'],
          errors: ['Backup manifest or table data is missing.'],
        );
      }

      final manifest = BackupManifest.fromJson(manifestJson);
      final errors = <String>[];
      final codes = <String>[];

      if (manifest.flavor != _config.flavor.name) {
        codes.add('BACKUP_FLAVOR_MISMATCH');
        errors.add(
          'Flavor mismatch: backup is "${manifest.flavor}", app is "${_config.flavor.name}".',
        );
      }
      if (manifest.schemaVersion >
          DatabaseMigrationManager.currentSchemaVersion) {
        codes.add('BACKUP_SCHEMA_TOO_NEW');
        errors.add(
          'Backup schema v${manifest.schemaVersion} is newer than this app (v${DatabaseMigrationManager.currentSchemaVersion}).',
        );
      }

      final actualSha = sha256
          .convert(utf8.encode(jsonEncode(tablesJson)))
          .toString();
      if (actualSha != manifest.databaseSha256) {
        codes.add('BACKUP_CHECKSUM_MISMATCH');
        errors.add('Backup integrity checksum failed — file may be modified.');
      }

      onProgress?.call(const BackupProgress(stageCode: 'done', fraction: 1.0));
      return BackupValidationResult(
        isValid: errors.isEmpty,
        manifest: manifest,
        errorCodes: codes,
        errors: errors,
      );
    } catch (e) {
      return BackupValidationResult(
        isValid: false,
        errorCodes: const ['BACKUP_PARSE_ERROR'],
        errors: ['Could not read backup file: $e'],
      );
    }
  }

  @override
  Future<BackupRestoreResult> restoreFromZip(
    String zipFilePath, {
    BackupProgressCallback? onProgress,
  }) async {
    final validation = await validateBackupZip(
      zipFilePath,
      onProgress: onProgress,
    );
    if (!validation.isValid || validation.manifest == null) {
      throw StateError(validation.errors.join(' '));
    }

    final bytes = _stagedPayloads[zipFilePath]!;
    final decoded = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final tablesJson = decoded['tables'] as Map<String, dynamic>;

    onProgress?.call(
      const BackupProgress(stageCode: 'restoring', fraction: 0.6),
    );

    await _db.customStatement('PRAGMA foreign_keys = OFF;');
    try {
      await _db.transaction(() async {
        // Clear existing data in reverse child-before-parent order.
        for (final table in _orderedTables.reversed) {
          await _db.customStatement('DELETE FROM $table;');
        }

        // Re-insert rows in parent-before-child order.
        for (final table in _orderedTables) {
          final rawRows = tablesJson[table];
          if (rawRows is! List) continue;
          for (final rawRow in rawRows) {
            if (rawRow is! Map) continue;
            final cols = <String>[];
            final placeholders = <String>[];
            final vars = <Variable<Object>>[];
            for (final entry in rawRow.entries) {
              cols.add('"${entry.key}"');
              placeholders.add('?');
              vars.add(_toVariable(entry.value));
            }
            if (cols.isEmpty) continue;
            await _db.customInsert(
              'INSERT INTO $table (${cols.join(', ')}) VALUES (${placeholders.join(', ')})',
              variables: vars,
            );
          }
        }
      });
    } finally {
      await _db.customStatement('PRAGMA foreign_keys = ON;');
    }

    _stagedPayloads.remove(zipFilePath);
    await _recordAudit('BACKUP_RESTORE', {
      'source': zipFilePath,
      'schema_version': validation.manifest!.schemaVersion,
      'platform': 'web',
    });

    onProgress?.call(const BackupProgress(stageCode: 'done', fraction: 1.0));
    return BackupRestoreResult(
      manifest: validation.manifest!,
      restoredAtUtcMillis: IstDateTimeHelper.nowUtcMillis(),
      restoredAttachmentsCount: 0,
    );
  }

  Variable<Object> _toVariable(Object? value) {
    if (value == null) return const Variable<Object>(null);
    if (value is bool) return Variable<bool>(value);
    if (value is int) return Variable<int>(value);
    if (value is double) return Variable<double>(value);
    if (value is num) return Variable<int>(value.toInt());
    return Variable<String>(value.toString());
  }

  Future<void> _recordAudit(
    String actionType,
    Map<String, Object?> payload,
  ) async {
    final now = IstDateTimeHelper.nowUtcMillis();
    final profile = await _db.businessProfileDao.getProfile();
    final actor = profile?.ownerName?.trim().isNotEmpty == true
        ? profile!.ownerName!.trim()
        : 'local_owner';
    await _db.attachmentAuditDao.insertAuditLog(
      AuditLogsCompanion(
        id: Value(_idGenerator.nextEntityId()),
        entityType: const Value('backup'),
        entityId: Value(_config.flavor.name),
        actionType: Value(actionType),
        actor: Value(actor),
        newValueJson: Value(jsonEncode(payload)),
        transactionAt: Value(now),
        recordedAt: Value(now),
      ),
    );
  }
}
