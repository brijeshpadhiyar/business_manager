/// Manifest item for a single private media file inside a `.zip` backup bundle.
final class BackupAttachmentManifestItem {
  const BackupAttachmentManifestItem({
    required this.relativePath,
    required this.sha256,
    required this.sizeBytes,
  });

  final String relativePath;
  final String sha256;
  final int sizeBytes;

  Map<String, dynamic> toJson() => {
    'relative_path': relativePath,
    'sha256': sha256,
    'size_bytes': sizeBytes,
  };

  static BackupAttachmentManifestItem fromJson(Map<String, dynamic> json) {
    return BackupAttachmentManifestItem(
      relativePath: json['relative_path'] as String,
      sha256: json['sha256'] as String,
      sizeBytes: (json['size_bytes'] as num).toInt(),
    );
  }
}

/// Summary record counts embedded in `manifest.json` so the user can review
/// backup contents before confirming a restore.
final class BackupSummaryCounts {
  const BackupSummaryCounts({
    required this.lotsCount,
    required this.workersCount,
    required this.processesCount,
    required this.movementsCount,
    required this.paymentsCount,
  });

  final int lotsCount;
  final int workersCount;
  final int processesCount;
  final int movementsCount;
  final int paymentsCount;

  Map<String, dynamic> toJson() => {
    'lots': lotsCount,
    'workers': workersCount,
    'processes': processesCount,
    'stock_movements': movementsCount,
    'payments': paymentsCount,
  };

  static BackupSummaryCounts fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const BackupSummaryCounts(
        lotsCount: 0,
        workersCount: 0,
        processesCount: 0,
        movementsCount: 0,
        paymentsCount: 0,
      );
    }
    return BackupSummaryCounts(
      lotsCount: (json['lots'] as num?)?.toInt() ?? 0,
      workersCount: (json['workers'] as num?)?.toInt() ?? 0,
      processesCount: (json['processes'] as num?)?.toInt() ?? 0,
      movementsCount: (json['stock_movements'] as num?)?.toInt() ?? 0,
      paymentsCount: (json['payments'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Structured manifest written to `manifest.json` inside every `.zip` backup.
final class BackupManifest {
  const BackupManifest({
    required this.formatVersion,
    required this.appVersion,
    required this.flavor,
    required this.schemaVersion,
    required this.createdAtUtc,
    required this.createdAtIst,
    required this.databaseSha256,
    required this.databaseSizeBytes,
    required this.attachmentsCount,
    required this.attachments,
    required this.summaryCounts,
  });

  static const int currentFormatVersion = 1;

  final int formatVersion;
  final String appVersion;
  final String flavor;
  final int schemaVersion;
  final String createdAtUtc;
  final String createdAtIst;
  final String databaseSha256;
  final int databaseSizeBytes;
  final int attachmentsCount;
  final List<BackupAttachmentManifestItem> attachments;
  final BackupSummaryCounts summaryCounts;

  Map<String, dynamic> toJson() => {
    'format_version': formatVersion,
    'app_version': appVersion,
    'flavor': flavor,
    'schema_version': schemaVersion,
    'created_at_utc': createdAtUtc,
    'created_at_ist': createdAtIst,
    'database_sha256': databaseSha256,
    'database_size_bytes': databaseSizeBytes,
    'attachments_count': attachmentsCount,
    'attachments': attachments.map((a) => a.toJson()).toList(),
    'summary_counts': summaryCounts.toJson(),
  };

  static BackupManifest fromJson(Map<String, dynamic> json) {
    final rawAttachments = (json['attachments'] as List<dynamic>? ?? const []);
    return BackupManifest(
      formatVersion: (json['format_version'] as num).toInt(),
      appVersion: json['app_version'] as String,
      flavor: json['flavor'] as String,
      schemaVersion: (json['schema_version'] as num).toInt(),
      createdAtUtc: json['created_at_utc'] as String,
      createdAtIst: json['created_at_ist'] as String,
      databaseSha256: json['database_sha256'] as String,
      databaseSizeBytes: (json['database_size_bytes'] as num).toInt(),
      attachmentsCount: (json['attachments_count'] as num).toInt(),
      attachments: rawAttachments
          .map(
            (e) => BackupAttachmentManifestItem.fromJson(
              e as Map<String, dynamic>,
            ),
          )
          .toList(),
      summaryCounts: BackupSummaryCounts.fromJson(
        json['summary_counts'] as Map<String, dynamic>?,
      ),
    );
  }
}

/// Progress update emitted during backup or restore execution.
final class BackupProgress {
  const BackupProgress({required this.stageCode, required this.fraction});

  final String stageCode;
  final double fraction;
}

typedef BackupProgressCallback = void Function(BackupProgress progress);

/// Result of creating a raw `.sqlite` export or full `.zip` backup bundle.
final class BackupExportResult {
  const BackupExportResult({
    required this.filePath,
    required this.fileName,
    required this.sizeBytes,
    required this.createdAtUtcMillis,
    this.manifest,
  });

  final String filePath;
  final String fileName;
  final int sizeBytes;
  final int createdAtUtcMillis;
  final BackupManifest? manifest;
}

/// Non-destructive validation result returned before any live data is modified.
final class BackupValidationResult {
  const BackupValidationResult({
    required this.isValid,
    this.manifest,
    this.errorCodes = const [],
    this.errors = const [],
  });

  final bool isValid;
  final BackupManifest? manifest;
  final List<String> errorCodes;
  final List<String> errors;
}

/// Result of a completed atomic restore.
final class BackupRestoreResult {
  const BackupRestoreResult({
    required this.manifest,
    required this.restoredAtUtcMillis,
    required this.restoredAttachmentsCount,
  });

  final BackupManifest manifest;
  final int restoredAtUtcMillis;
  final int restoredAttachmentsCount;
}
