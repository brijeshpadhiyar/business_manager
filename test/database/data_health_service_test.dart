import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/features/backup/data/services/data_health_service.dart';
import 'package:business_manager/features/backup/domain/entities/data_health_entities.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

final class _InMemoryMediaStorage implements MediaStorageService {
  final Set<String> paths = {};

  @override
  String computeSha256(Uint8List bytes) => 'sha256';

  @override
  Future<bool> deleteIfExists(String relativePath) async =>
      paths.remove(relativePath);

  @override
  Future<bool> exists(String relativePath) async => paths.contains(relativePath);

  @override
  Future<List<String>> listAllRelativePaths() async => paths.toList()..sort();

  @override
  Future<Uint8List?> readBytes(String relativePath) async => null;

  @override
  Future<SavedMediaFile> saveBytes({
    required Uint8List bytes,
    required MediaCategory category,
    required String entityId,
    required String fileExtension,
    required String mimeType,
  }) async {
    final p = '${category.folderName}/$entityId/file.$fileExtension';
    paths.add(p);
    return SavedMediaFile(
      relativePath: p,
      fileSizeBytes: bytes.length,
      sha256Hex: 'sha256',
      mimeType: mimeType,
    );
  }

  @override
  Future<void> writeBytesAtRelativePath(
    String relativePath,
    Uint8List bytes,
  ) async {
    paths.add(relativePath);
  }
}

void main() {
  late AppDatabase db;
  late _InMemoryMediaStorage media;
  late DataHealthService service;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    media = _InMemoryMediaStorage();
    service = DataHealthService(db, media, IdGenerator());
    await db.customSelect('SELECT 1').getSingle();
  });

  tearDown(() async {
    await db.close();
  });

  test('reports healthy on clean DB and logs safe maintenance actions', () async {
    final report = await service.runFullDiagnostics();
    expect(report.sqliteIntegrityOk, isTrue);
    expect(report.foreignKeyViolations, isEmpty);
    expect(report.stockIssues, isEmpty);
    expect(report.ledgerIssues, isEmpty);
    expect(report.status, DataHealthStatus.healthy);

    await service.runWalCheckpoint();
    final audits = await db.attachmentAuditDao.getAuditLogsForEntity(
      'DATA_HEALTH',
      'wal_checkpoint',
    );
    expect(audits, isNotEmpty);
  });

  test('detects and cleans orphan media files without deleting active ones', () async {
    media.paths.addAll(['lots/l1/active.jpg', 'lots/l1/orphan.jpg']);
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.attachmentAuditDao.insertAttachment(
      AttachmentsCompanion.insert(
        id: 'att-1',
        entityType: 'LOT',
        entityId: 'l1',
        relativePath: 'lots/l1/active.jpg',
        mimeType: 'image/jpeg',
        fileSizeBytes: 100,
        sha256: 'abc',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final before = await service.runFullDiagnostics();
    expect(before.orphanMediaPaths, ['lots/l1/orphan.jpg']);
    expect(before.status, DataHealthStatus.warning);

    final deleted = await service.cleanOrphanMediaFiles();
    expect(deleted, 1);
    expect(media.paths, {'lots/l1/active.jpg'});

    final after = await service.runFullDiagnostics();
    expect(after.orphanMediaPaths, isEmpty);
    expect(after.status, DataHealthStatus.healthy);
  });

  test('resets failed sync outbox entries cleanly', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.into(db.syncOutboxes).insert(
      SyncOutboxesCompanion.insert(
        entryKey: 'lots:lot-1',
        tableNameCol: 'lots',
        rowId: 'lot-1',
        enqueuedAt: now,
        status: const Value('FAILED'),
        retryCount: const Value(3),
        lastError: const Value('timeout'),
      ),
    );

    final before = await service.runFullDiagnostics();
    expect(before.syncOutboxFailed, 1);

    final resetCount = await service.retryFailedSyncEntries();
    expect(resetCount, 1);

    final after = await service.runFullDiagnostics();
    expect(after.syncOutboxFailed, 0);
  });
}
