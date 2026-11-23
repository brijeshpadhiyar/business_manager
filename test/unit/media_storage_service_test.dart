import 'dart:io';
import 'dart:typed_data';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bm_media_test_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('saves, reads, checksums, and isolates dev vs prod private media',
      () async {
    final devMedia = NativeMediaStorageService(
      config: AppConfig.dev(),
      idGenerator: IdGenerator(),
      baseDirectoryOverride: tempDir,
    );
    final prodMedia = NativeMediaStorageService(
      config: AppConfig.prod(),
      idGenerator: IdGenerator(),
      baseDirectoryOverride: tempDir,
    );

    final payload = Uint8List.fromList([10, 20, 30, 40, 50]);
    final saved = await devMedia.saveBytes(
      bytes: payload,
      category: MediaCategory.lots,
      entityId: 'lot-1001',
      fileExtension: '.jpg',
      mimeType: 'image/jpeg',
    );

    expect(saved.relativePath, startsWith('lots/lot-1001/'));
    expect(saved.relativePath, endsWith('.jpg'));
    expect(saved.fileSizeBytes, 5);
    expect(saved.sha256Hex, devMedia.computeSha256(payload));

    expect(await devMedia.exists(saved.relativePath), isTrue);
    expect(await devMedia.readBytes(saved.relativePath), equals(payload));

    // Prod media directory is completely isolated from dev
    expect(await prodMedia.exists(saved.relativePath), isFalse);
    expect(await prodMedia.readBytes(saved.relativePath), isNull);

    // Safe deletion & missing file handling
    expect(await devMedia.deleteIfExists(saved.relativePath), isTrue);
    expect(await devMedia.deleteIfExists(saved.relativePath), isFalse);
    expect(await devMedia.readBytes(saved.relativePath), isNull);
  });

  test('blocks directory traversal paths cleanly', () async {
    final media = NativeMediaStorageService(
      config: AppConfig.dev(),
      idGenerator: IdGenerator(),
      baseDirectoryOverride: tempDir,
    );

    await expectLater(
      media.readBytes('../secret.sqlite'),
      throwsA(isA<LocalStorageException>()),
    );
    await expectLater(
      media.readBytes('/etc/passwd'),
      throwsA(isA<LocalStorageException>()),
    );
  });
}
