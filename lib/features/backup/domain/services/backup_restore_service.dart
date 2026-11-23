import 'package:business_manager/features/backup/domain/entities/backup_entities.dart';

/// Offline backup, raw SQLite inspection export, and fail-safe atomic restore
/// contract (`docs/14_backup_restore_strategy.md`).
abstract interface class BackupRestoreService {
  /// Exports a WAL-consistent, compacted, integrity-verified raw `.sqlite`
  /// file for external inspection tools (`VACUUM INTO`).
  Future<BackupExportResult> exportRawSqlite({
    String? destinationDirectoryPath,
    BackupProgressCallback? onProgress,
  });

  /// Creates a complete unencrypted `.zip` backup bundle containing
  /// `manifest.json`, WAL-consistent `database.sqlite`, and all private media.
  Future<BackupExportResult> createFullZipBackup({
    String? destinationDirectoryPath,
    BackupProgressCallback? onProgress,
  });

  /// Inspects and validates a `.zip` backup archive in an isolated staging
  /// directory without touching any live database or media files.
  Future<BackupValidationResult> validateBackupZip(
    String zipFilePath, {
    BackupProgressCallback? onProgress,
  });

  /// Executes a fail-safe atomic restore from a validated `.zip` archive:
  /// 1. Re-validates archive, SHA-256 checksums, SQLite integrity & flavor rules.
  /// 2. Creates a pre-restore rollback snapshot of live DB + media.
  /// 3. Closes live DB, swaps DB + media, removes stale `-wal`/`-shm` files.
  /// 4. Opens & verifies restored DB (applying Drift migrations if older schema)
  ///    and logs `BACKUP_RESTORE` audit record.
  /// 5. Automatically rolls back to the pre-restore snapshot on any failure.
  Future<BackupRestoreResult> restoreFromZip(
    String zipFilePath, {
    BackupProgressCallback? onProgress,
  });
}
