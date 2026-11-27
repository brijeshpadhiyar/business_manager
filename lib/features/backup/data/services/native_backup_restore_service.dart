import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_identity.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/connection/database_connection_native.dart';
import 'package:business_manager/core/database/migrations/database_migration_manager.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/backup/domain/entities/backup_entities.dart';
import 'package:business_manager/features/backup/domain/services/backup_restore_service.dart';
import 'package:business_manager/features/notifications/data/services/notification_refresh_coordinator.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:business_manager/core/platform/app_data_directory.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

/// Native (Android, Windows, macOS, Linux, iOS) implementation of StitchFlow's
/// WAL-safe backup, raw `.sqlite` export, and atomic fail-safe `.zip` restore.
final class NativeBackupRestoreService implements BackupRestoreService {
  NativeBackupRestoreService(
    this._db,
    this._config,
    this._idGenerator, {
    this.baseDirectoryOverride,
    this.tempDirectoryOverride,
  });

  static String get appVersionString =>
      '${AppIdentity.appVersion}+${AppIdentity.appBuildNumber}';

  final AppDatabase _db;
  final AppConfig _config;
  final IdGenerator _idGenerator;
  final Directory? baseDirectoryOverride;
  final Directory? tempDirectoryOverride;

  Future<Directory> _resolveBaseDir() async {
    return baseDirectoryOverride ?? await resolveAppDataDirectory();
  }

  Future<Directory> _resolveTempDir() async {
    return tempDirectoryOverride ?? await getTemporaryDirectory();
  }

  Future<File> _resolveLiveDbFile() async {
    return resolvePrivateDatabaseFile(
      _config,
      baseDirectoryOverride: baseDirectoryOverride,
    );
  }

  Future<Directory> _resolveLiveMediaDir() async {
    final base = await _resolveBaseDir();
    return Directory(p.join(base.path, _config.mediaDirName));
  }

  Future<Directory> _resolveExportsDir(String? overridePath) async {
    if (overridePath != null && overridePath.trim().isNotEmpty) {
      final dir = Directory(overridePath);
      if (!dir.existsSync()) await dir.create(recursive: true);
      return dir;
    }
    final temp = await _resolveTempDir();
    final exports = Directory(p.join(temp.path, 'stitchflow_exports'));
    if (!exports.existsSync()) await exports.create(recursive: true);
    return exports;
  }

  String _escapeSqlLiteral(String value) => value.replaceAll("'", "''");

  Future<String> _sha256File(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }

  /// Creates a WAL-consistent, compacted, self-contained SQLite snapshot using
  /// `PRAGMA wal_checkpoint(TRUNCATE)` + `VACUUM INTO '<targetPath>'`.
  Future<void> _createConsistentSnapshot(
    AppDatabase db,
    String targetFilePath,
  ) async {
    final targetFile = File(targetFilePath);
    if (targetFile.existsSync()) {
      await targetFile.delete();
    }
    if (!targetFile.parent.existsSync()) {
      await targetFile.parent.create(recursive: true);
    }

    await db.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
    final escaped = _escapeSqlLiteral(targetFilePath);
    await db.customStatement("VACUUM INTO '$escaped';");

    if (!targetFile.existsSync() || targetFile.lengthSync() == 0) {
      throw const LocalStorageException(
        'SQLite snapshot creation failed (empty or missing output file).',
      );
    }

    _verifySqliteIntegrityReadOnly(targetFilePath);
  }

  void _verifySqliteIntegrityReadOnly(String sqliteFilePath) {
    final rawDb = sqlite.sqlite3.open(
      sqliteFilePath,
      mode: sqlite.OpenMode.readOnly,
    );
    try {
      final result = rawDb.select('PRAGMA integrity_check;');
      if (result.isEmpty ||
          result.first.values.first?.toString().toLowerCase() != 'ok') {
        throw LocalStorageException(
          'SQLite integrity_check failed: ${result.map((r) => r.values.first).join(', ')}',
        );
      }
    } finally {
      rawDb.close();
    }
  }

  BackupSummaryCounts _readSummaryCountsReadOnly(String sqliteFilePath) {
    final rawDb = sqlite.sqlite3.open(
      sqliteFilePath,
      mode: sqlite.OpenMode.readOnly,
    );
    try {
      int countTable(String table, {bool filterDeleted = false}) {
        try {
          final where = filterDeleted ? ' WHERE deleted_at IS NULL' : '';
          final rs = rawDb.select('SELECT COUNT(*) AS c FROM $table$where;');
          return (rs.first['c'] as num).toInt();
        } catch (_) {
          return 0;
        }
      }

      return BackupSummaryCounts(
        lotsCount: countTable('lots', filterDeleted: true),
        workersCount: countTable('members', filterDeleted: true),
        processesCount: countTable('processes', filterDeleted: true),
        movementsCount: countTable('stock_movements'),
        paymentsCount: countTable('payments'),
      );
    } finally {
      rawDb.close();
    }
  }

  Future<void> _recordAudit(
    AppDatabase db, {
    required String actionType,
    required Map<String, dynamic> payload,
    required int nowUtc,
  }) async {
    final profile = await db.businessProfileDao.getProfile();
    final actor = profile?.ownerName?.trim().isNotEmpty == true
        ? profile!.ownerName!.trim()
        : 'local_owner';
    await db.attachmentAuditDao.insertAuditLog(
      AuditLogsCompanion(
        id: Value(_idGenerator.nextEntityId()),
        entityType: const Value('backup'),
        entityId: Value(_config.flavor.name),
        actionType: Value(actionType),
        actor: Value(actor),
        newValueJson: Value(jsonEncode(payload)),
        transactionAt: Value(nowUtc),
        recordedAt: Value(nowUtc),
      ),
    );
  }

  @override
  Future<BackupExportResult> exportRawSqlite({
    String? destinationDirectoryPath,
    BackupProgressCallback? onProgress,
  }) async {
    onProgress?.call(
      const BackupProgress(stageCode: 'checkpointing', fraction: 0.2),
    );
    final nowUtc = IstDateTimeHelper.nowUtcMillis();
    final istStamp = IstDateTimeHelper.formatIstFileTimestamp(nowUtc);
    final fileName =
        'stitchflow_${_config.flavor.name}_${istStamp}_inspect.sqlite';
    final exportsDir = await _resolveExportsDir(destinationDirectoryPath);
    final outPath = p.join(exportsDir.path, fileName);

    onProgress?.call(
      const BackupProgress(stageCode: 'snapshotting', fraction: 0.55),
    );
    await _createConsistentSnapshot(_db, outPath);

    onProgress?.call(
      const BackupProgress(stageCode: 'verifying', fraction: 0.85),
    );
    final outFile = File(outPath);
    final sizeBytes = outFile.lengthSync();

    await _recordAudit(
      _db,
      actionType: 'BACKUP_EXPORT',
      payload: {
        'export_kind': 'raw_sqlite',
        'file_name': fileName,
        'size_bytes': sizeBytes,
        'flavor': _config.flavor.name,
      },
      nowUtc: nowUtc,
    );

    onProgress?.call(
      const BackupProgress(stageCode: 'completed', fraction: 1.0),
    );
    return BackupExportResult(
      filePath: outPath,
      fileName: fileName,
      sizeBytes: sizeBytes,
      createdAtUtcMillis: nowUtc,
    );
  }

  @override
  Future<BackupExportResult> createFullZipBackup({
    String? destinationDirectoryPath,
    BackupProgressCallback? onProgress,
  }) async {
    onProgress?.call(
      const BackupProgress(stageCode: 'preparing', fraction: 0.1),
    );
    final nowUtc = IstDateTimeHelper.nowUtcMillis();
    final istStamp = IstDateTimeHelper.formatIstFileTimestamp(nowUtc);
    final zipFileName =
        'stitchflow_backup_${_config.flavor.name}_$istStamp.zip';

    final tempRoot = await _resolveTempDir();
    final stagingDir = Directory(
      p.join(tempRoot.path, 'sf_backup_stage_${_idGenerator.nextEntityId()}'),
    );
    await stagingDir.create(recursive: true);

    try {
      // 1. WAL-consistent SQLite snapshot
      onProgress?.call(
        const BackupProgress(stageCode: 'snapshotting', fraction: 0.3),
      );
      final snapshotDbPath = p.join(stagingDir.path, 'database.sqlite');
      await _createConsistentSnapshot(_db, snapshotDbPath);
      final snapshotDbFile = File(snapshotDbPath);
      final dbSha256 = await _sha256File(snapshotDbFile);
      final dbSize = snapshotDbFile.lengthSync();
      final summaryCounts = _readSummaryCountsReadOnly(snapshotDbPath);

      // 2. Collect all private media files
      onProgress?.call(
        const BackupProgress(stageCode: 'packaging', fraction: 0.55),
      );
      final mediaDir = await _resolveLiveMediaDir();
      final attachmentItems = <BackupAttachmentManifestItem>[];
      final archive = Archive();

      // Add database.sqlite
      final dbBytes = await snapshotDbFile.readAsBytes();
      archive.addFile(ArchiveFile('database.sqlite', dbBytes.length, dbBytes));

      if (mediaDir.existsSync()) {
        await for (final entity in mediaDir.list(recursive: true)) {
          if (entity is! File) continue;
          final relOs = p.relative(entity.path, from: mediaDir.path);
          final relPosix = p.posix.normalize(relOs.replaceAll('\\', '/'));
          if (relPosix.startsWith('..') || relPosix.startsWith('/')) continue;

          final bytes = await entity.readAsBytes();
          final fileHash = sha256.convert(bytes).toString();
          final archiveEntryPath = 'media/$relPosix';
          archive.addFile(ArchiveFile(archiveEntryPath, bytes.length, bytes));
          attachmentItems.add(
            BackupAttachmentManifestItem(
              relativePath: archiveEntryPath,
              sha256: fileHash,
              sizeBytes: bytes.length,
            ),
          );
        }
      }

      // 3. Build manifest.json
      final manifest = BackupManifest(
        formatVersion: BackupManifest.currentFormatVersion,
        appVersion: appVersionString,
        flavor: _config.flavor.name,
        schemaVersion: DatabaseMigrationManager.currentSchemaVersion,
        createdAtUtc: AppDateTimeFormatter.formatUtcIso8601(nowUtc),
        createdAtIst: AppDateTimeFormatter.formatIsoDateTimeIst(nowUtc),
        databaseSha256: dbSha256,
        databaseSizeBytes: dbSize,
        attachmentsCount: attachmentItems.length,
        attachments: attachmentItems,
        summaryCounts: summaryCounts,
      );

      final manifestBytes = utf8.encode(
        const JsonEncoder.withIndent('  ').convert(manifest.toJson()),
      );
      archive.addFile(
        ArchiveFile('manifest.json', manifestBytes.length, manifestBytes),
      );

      // 4. Write ZIP package
      onProgress?.call(
        const BackupProgress(stageCode: 'verifying', fraction: 0.8),
      );
      final exportsDir = await _resolveExportsDir(destinationDirectoryPath);
      final zipOutPath = p.join(exportsDir.path, zipFileName);
      final encodedZip = ZipEncoder().encode(archive);
      final zipFile = File(zipOutPath);
      await zipFile.writeAsBytes(encodedZip, flush: true);

      await _recordAudit(
        _db,
        actionType: 'BACKUP_EXPORT',
        payload: {
          'export_kind': 'full_zip',
          'file_name': zipFileName,
          'size_bytes': zipFile.lengthSync(),
          'attachments_count': attachmentItems.length,
          'schema_version': manifest.schemaVersion,
          'flavor': manifest.flavor,
        },
        nowUtc: nowUtc,
      );

      onProgress?.call(
        const BackupProgress(stageCode: 'completed', fraction: 1.0),
      );
      NotificationRefreshCoordinator.requestBackgroundRefreshIfRegistered(
        forceReschedule: true,
      );
      return BackupExportResult(
        filePath: zipOutPath,
        fileName: zipFileName,
        sizeBytes: zipFile.lengthSync(),
        createdAtUtcMillis: nowUtc,
        manifest: manifest,
      );
    } finally {
      if (stagingDir.existsSync()) {
        await stagingDir.delete(recursive: true);
      }
    }
  }

  Future<({BackupValidationResult validation, Directory stagingDir})>
  _extractAndValidateToStaging(
    String zipFilePath, {
    BackupProgressCallback? onProgress,
  }) async {
    final tempRoot = await _resolveTempDir();
    final stagingDir = Directory(
      p.join(tempRoot.path, 'sf_restore_stage_${_idGenerator.nextEntityId()}'),
    );
    await stagingDir.create(recursive: true);

    final errors = <String>[];
    final errorCodes = <String>[];

    final zipFile = File(zipFilePath);
    if (!zipFile.existsSync()) {
      return (
        validation: const BackupValidationResult(
          isValid: false,
          errorCodes: ['backup_file_missing'],
          errors: ['Selected backup file does not exist.'],
        ),
        stagingDir: stagingDir,
      );
    }

    onProgress?.call(
      const BackupProgress(stageCode: 'validating', fraction: 0.25),
    );

    Archive archive;
    try {
      final zipBytes = await zipFile.readAsBytes();
      archive = ZipDecoder().decodeBytes(zipBytes);
    } catch (e) {
      return (
        validation: BackupValidationResult(
          isValid: false,
          errorCodes: const ['invalid_zip'],
          errors: ['Invalid or corrupted ZIP archive: $e'],
        ),
        stagingDir: stagingDir,
      );
    }

    // Safe extraction blocking Zip-Slip directory traversal
    for (final entry in archive) {
      if (!entry.isFile) continue;
      final normalized = p.posix.normalize(entry.name.replaceAll('\\', '/'));
      if (normalized.isEmpty ||
          normalized.startsWith('/') ||
          normalized.startsWith('..') ||
          normalized.split('/').contains('..')) {
        return (
          validation: const BackupValidationResult(
            isValid: false,
            errorCodes: ['unsafe_archive_path'],
            errors: ['Backup archive contains an unsafe file path.'],
          ),
          stagingDir: stagingDir,
        );
      }
      final outPath = p.joinAll([stagingDir.path, ...normalized.split('/')]);
      final outFile = File(outPath);
      await outFile.parent.create(recursive: true);
      await outFile.writeAsBytes(entry.content as List<int>, flush: true);
    }

    // 1. Validate manifest.json
    final manifestFile = File(p.join(stagingDir.path, 'manifest.json'));
    if (!manifestFile.existsSync()) {
      return (
        validation: const BackupValidationResult(
          isValid: false,
          errorCodes: ['missing_manifest'],
          errors: ['Backup archive is missing manifest.json.'],
        ),
        stagingDir: stagingDir,
      );
    }

    BackupManifest manifest;
    try {
      final decoded =
          jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
      manifest = BackupManifest.fromJson(decoded);
    } catch (e) {
      return (
        validation: BackupValidationResult(
          isValid: false,
          errorCodes: const ['invalid_manifest'],
          errors: ['Invalid manifest.json format: $e'],
        ),
        stagingDir: stagingDir,
      );
    }

    if (manifest.formatVersion != BackupManifest.currentFormatVersion) {
      errorCodes.add('unsupported_format_version');
      errors.add(
        'Unsupported backup format version (${manifest.formatVersion}).',
      );
    }

    // 2. Schema version compatibility check
    if (manifest.schemaVersion >
        DatabaseMigrationManager.currentSchemaVersion) {
      errorCodes.add('schema_too_new');
      errors.add(
        'Backup schema v${manifest.schemaVersion} is newer than this app (v${DatabaseMigrationManager.currentSchemaVersion}). Please update StitchFlow before restoring.',
      );
    }

    if (manifest.schemaVersion <
        DatabaseMigrationManager.minimumSupportedSchemaVersion) {
      errorCodes.add('schema_too_old');
      errors.add(
        'Backup schema v${manifest.schemaVersion} is from a pre-release version and cannot be restored. Only backups made with v${DatabaseMigrationManager.minimumSupportedSchemaVersion} or later are supported.',
      );
    }

    // 3. Cross-flavor protection: never allow dev backup into prod
    if (_config.isProd && manifest.flavor != 'prod') {
      errorCodes.add('cross_flavor_blocked');
      errors.add(
        'Cannot restore a "${manifest.flavor}" backup into Production StitchFlow.',
      );
    }

    // 4. Verify database.sqlite exists, SHA-256 matches, and integrity_check passes
    onProgress?.call(
      const BackupProgress(stageCode: 'verifying', fraction: 0.6),
    );
    final stagedDbFile = File(p.join(stagingDir.path, 'database.sqlite'));
    if (!stagedDbFile.existsSync()) {
      errorCodes.add('missing_database');
      errors.add('Backup archive is missing database.sqlite.');
    } else {
      final actualDbHash = await _sha256File(stagedDbFile);
      if (actualDbHash != manifest.databaseSha256) {
        errorCodes.add('database_checksum_mismatch');
        errors.add(
          'Database SHA-256 checksum mismatch (archive may be corrupted).',
        );
      } else {
        try {
          _verifySqliteIntegrityReadOnly(stagedDbFile.path);
        } catch (e) {
          errorCodes.add('database_integrity_failed');
          errors.add('SQLite integrity check failed: $e');
        }
      }
    }

    // 5. Verify all listed attachments exist & match SHA-256
    for (final att in manifest.attachments) {
      final normRel = p.posix.normalize(att.relativePath.replaceAll('\\', '/'));
      if (normRel.startsWith('..') || normRel.startsWith('/')) {
        errorCodes.add('unsafe_attachment_path');
        errors.add('Invalid attachment path in manifest: ${att.relativePath}');
        continue;
      }
      final attFile = File(p.joinAll([stagingDir.path, ...normRel.split('/')]));
      if (!attFile.existsSync()) {
        errorCodes.add('missing_attachment');
        errors.add('Missing attachment file: ${att.relativePath}');
        continue;
      }
      final actualHash = await _sha256File(attFile);
      if (actualHash != att.sha256) {
        errorCodes.add('attachment_checksum_mismatch');
        errors.add('Checksum mismatch for attachment: ${att.relativePath}');
      }
    }

    onProgress?.call(
      const BackupProgress(stageCode: 'completed', fraction: 1.0),
    );
    return (
      validation: BackupValidationResult(
        isValid: errors.isEmpty,
        manifest: manifest,
        errorCodes: errorCodes,
        errors: errors,
      ),
      stagingDir: stagingDir,
    );
  }

  @override
  Future<BackupValidationResult> validateBackupZip(
    String zipFilePath, {
    BackupProgressCallback? onProgress,
  }) async {
    final result = await _extractAndValidateToStaging(
      zipFilePath,
      onProgress: onProgress,
    );
    try {
      return result.validation;
    } finally {
      if (result.stagingDir.existsSync()) {
        await result.stagingDir.delete(recursive: true);
      }
    }
  }

  Future<void> _copyDirectoryContents(Directory source, Directory dest) async {
    if (!source.existsSync()) return;
    if (!dest.existsSync()) {
      await dest.create(recursive: true);
    }
    await for (final entity in source.list(recursive: true)) {
      final rel = p.relative(entity.path, from: source.path);
      final targetPath = p.join(dest.path, rel);
      if (entity is Directory) {
        await Directory(targetPath).create(recursive: true);
      } else if (entity is File) {
        await File(targetPath).parent.create(recursive: true);
        await entity.copy(targetPath);
      }
    }
  }

  Future<void> _deleteWalAndShm(String dbPath) async {
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final sidecar = File('$dbPath$suffix');
      if (sidecar.existsSync()) {
        await sidecar.delete();
      }
    }
  }

  @override
  Future<BackupRestoreResult> restoreFromZip(
    String zipFilePath, {
    BackupProgressCallback? onProgress,
  }) async {
    // 1. Validate archive into staging dir BEFORE modifying live data
    onProgress?.call(
      const BackupProgress(stageCode: 'validating', fraction: 0.15),
    );
    final extracted = await _extractAndValidateToStaging(zipFilePath);
    final stagingDir = extracted.stagingDir;
    final validation = extracted.validation;

    if (!validation.isValid || validation.manifest == null) {
      if (stagingDir.existsSync()) {
        await stagingDir.delete(recursive: true);
      }
      throw DomainValidationException(
        validation.errorCodes.isNotEmpty
            ? validation.errorCodes.first
            : 'backup_invalid',
        validation.errors.join(' '),
      );
    }

    final manifest = validation.manifest!;
    final tempRoot = await _resolveTempDir();
    final rollbackDir = Directory(
      p.join(tempRoot.path, 'sf_rollback_${_idGenerator.nextEntityId()}'),
    );
    await rollbackDir.create(recursive: true);

    final liveDbFile = await _resolveLiveDbFile();
    final liveMediaDir = await _resolveLiveMediaDir();
    final rollbackDbPath = p.join(rollbackDir.path, 'database.sqlite');
    final rollbackMediaDir = Directory(p.join(rollbackDir.path, 'media'));

    var swapped = false;
    try {
      // 2. Automatic pre-restore safety snapshot of current live DB + media
      onProgress?.call(
        const BackupProgress(stageCode: 'backingUpCurrent', fraction: 0.35),
      );
      if (liveDbFile.existsSync()) {
        await _createConsistentSnapshot(_db, rollbackDbPath);
      }
      if (liveMediaDir.existsSync()) {
        await _copyDirectoryContents(liveMediaDir, rollbackMediaDir);
      }

      // 3. Close active DB connection cleanly
      onProgress?.call(
        const BackupProgress(stageCode: 'swapping', fraction: 0.55),
      );
      await _db.close();

      // 4. Replace live SQLite file (deleting stale WAL/SHM) and swap media dir
      swapped = true;
      await _deleteWalAndShm(liveDbFile.path);
      if (liveDbFile.existsSync()) {
        await liveDbFile.delete();
      }
      if (!liveDbFile.parent.existsSync()) {
        await liveDbFile.parent.create(recursive: true);
      }
      final stagedDbFile = File(p.join(stagingDir.path, 'database.sqlite'));
      await stagedDbFile.copy(liveDbFile.path);

      if (liveMediaDir.existsSync()) {
        await liveMediaDir.delete(recursive: true);
      }
      await liveMediaDir.create(recursive: true);
      final stagedMediaDir = Directory(p.join(stagingDir.path, 'media'));
      if (stagedMediaDir.existsSync()) {
        await _copyDirectoryContents(stagedMediaDir, liveMediaDir);
      }

      // 5. Open fresh verification DB (applies Drift migrations if needed) & audit
      onProgress?.call(
        const BackupProgress(stageCode: 'verifying', fraction: 0.8),
      );
      final nowUtc = IstDateTimeHelper.nowUtcMillis();
      final verifyDb = AppDatabase.forTesting(NativeDatabase(liveDbFile));
      try {
        final pragmas = await verifyDb.verifyPragmas();
        if (!pragmas.foreignKeysEnabled) {
          throw const LocalStorageException(
            'Restored database failed foreign_keys PRAGMA verification.',
          );
        }
        final integrityRows = await verifyDb
            .customSelect('PRAGMA integrity_check;')
            .get();
        if (integrityRows.isEmpty ||
            integrityRows.first.data.values.first.toString().toLowerCase() !=
                'ok') {
          throw const LocalStorageException(
            'Restored database failed PRAGMA integrity_check.',
          );
        }

        await _recordAudit(
          verifyDb,
          actionType: 'BACKUP_RESTORE',
          payload: {
            'source_flavor': manifest.flavor,
            'backup_created_at_utc': manifest.createdAtUtc,
            'backup_schema_version': manifest.schemaVersion,
            'restored_attachments_count': manifest.attachmentsCount,
          },
          nowUtc: nowUtc,
        );
      } finally {
        await verifyDb.close();
      }

      onProgress?.call(
        const BackupProgress(stageCode: 'completed', fraction: 1.0),
      );
      return BackupRestoreResult(
        manifest: manifest,
        restoredAtUtcMillis: nowUtc,
        restoredAttachmentsCount: manifest.attachmentsCount,
      );
    } catch (error) {
      // Automatic rollback to pre-restore snapshot if swap had started
      if (swapped) {
        onProgress?.call(
          const BackupProgress(stageCode: 'rollingBack', fraction: 0.9),
        );
        try {
          await _deleteWalAndShm(liveDbFile.path);
          final rollbackDbFile = File(rollbackDbPath);
          if (rollbackDbFile.existsSync()) {
            await rollbackDbFile.copy(liveDbFile.path);
          }
          if (liveMediaDir.existsSync()) {
            await liveMediaDir.delete(recursive: true);
          }
          if (rollbackMediaDir.existsSync()) {
            await _copyDirectoryContents(rollbackMediaDir, liveMediaDir);
          }
        } catch (_) {
          // Preserve original error
        }
      }
      if (error is DomainValidationException ||
          error is LocalStorageException) {
        rethrow;
      }
      throw LocalStorageException(
        'Backup restore failed and previous data was rolled back.',
        error,
      );
    } finally {
      if (stagingDir.existsSync()) {
        await stagingDir.delete(recursive: true);
      }
      if (rollbackDir.existsSync()) {
        await rollbackDir.delete(recursive: true);
      }
    }
  }
}
