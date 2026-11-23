import 'dart:typed_data';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:crypto/crypto.dart';

/// Web media storage placeholder — browsers do not expose native private
/// filesystem directories. Full OPFS/IndexedDB blob storage will be wired in
/// Milestone 7/8 (`docs/13_offline_storage_strategy.md`).
final class WebMediaStorageService implements MediaStorageService {
  @override
  String computeSha256(Uint8List bytes) => sha256.convert(bytes).toString();

  @override
  Future<SavedMediaFile> saveBytes({
    required Uint8List bytes,
    required MediaCategory category,
    required String entityId,
    required String fileExtension,
    required String mimeType,
  }) {
    throw UnsupportedError(
      'Private filesystem media storage is not available on Web; OPFS/IndexedDB blob storage is scheduled for Milestone 7/8.',
    );
  }

  @override
  Future<Uint8List?> readBytes(String relativePath) async => null;

  @override
  Future<bool> exists(String relativePath) async => false;

  @override
  Future<bool> deleteIfExists(String relativePath) async => false;
}

MediaStorageService createPlatformMediaStorageService(
  AppConfig config,
  IdGenerator idGenerator,
) {
  return WebMediaStorageService();
}
