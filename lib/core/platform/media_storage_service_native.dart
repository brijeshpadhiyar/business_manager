import 'dart:io';
import 'dart:typed_data';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:crypto/crypto.dart';
import 'package:business_manager/core/platform/app_data_directory.dart';
import 'package:path/path.dart' as p;

/// Native implementation storing media strictly inside OS private application
/// storage (`<appDocsDir>/<config.mediaDirName>/<category>/<entityId>/<uuid>.<ext>`).
final class NativeMediaStorageService implements MediaStorageService {
  NativeMediaStorageService({
    required this.config,
    required this.idGenerator,
    this.baseDirectoryOverride,
  });

  final AppConfig config;
  final IdGenerator idGenerator;
  final Directory? baseDirectoryOverride;

  Future<Directory> _resolveMediaRoot() async {
    final baseDir =
        baseDirectoryOverride ?? await resolveAppDataDirectory();
    final mediaRoot = Directory(p.join(baseDir.path, config.mediaDirName));
    if (!mediaRoot.existsSync()) {
      await mediaRoot.create(recursive: true);
    }
    return mediaRoot;
  }

  /// Resolves a portable POSIX relative path safely inside the flavor media root,
  /// blocking directory traversal (`..`).
  Future<File> resolveSafeFile(String relativePath) async {
    final normalized = p.posix.normalize(relativePath.replaceAll('\\', '/'));
    if (normalized.isEmpty ||
        normalized.startsWith('/') ||
        normalized.startsWith('..') ||
        normalized.split('/').contains('..')) {
      throw LocalStorageException('Invalid relative media path: $relativePath');
    }
    final root = await _resolveMediaRoot();
    final segments = normalized.split('/');
    final targetPath = p.joinAll([root.path, ...segments]);
    return File(targetPath);
  }

  @override
  String computeSha256(Uint8List bytes) => sha256.convert(bytes).toString();

  @override
  Future<SavedMediaFile> saveBytes({
    required Uint8List bytes,
    required MediaCategory category,
    required String entityId,
    required String fileExtension,
    required String mimeType,
  }) async {
    try {
      final cleanExt = fileExtension.replaceFirst(RegExp(r'^\.+'), '').trim();
      final ext = cleanExt.isEmpty ? 'bin' : cleanExt.toLowerCase();
      final safeEntityId = entityId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName = '${idGenerator.nextEntityId()}.$ext';
      final relativePath = p.posix.join(
        category.folderName,
        safeEntityId,
        fileName,
      );

      final file = await resolveSafeFile(relativePath);
      if (!file.parent.existsSync()) {
        await file.parent.create(recursive: true);
      }
      await file.writeAsBytes(bytes, flush: true);

      return SavedMediaFile(
        relativePath: relativePath,
        fileSizeBytes: bytes.length,
        sha256Hex: computeSha256(bytes),
        mimeType: mimeType,
      );
    } on LocalStorageException {
      rethrow;
    } catch (error) {
      throw LocalStorageException('Failed to save private media file.', error);
    }
  }

  @override
  Future<Uint8List?> readBytes(String relativePath) async {
    try {
      final file = await resolveSafeFile(relativePath);
      if (!file.existsSync()) return null;
      return await file.readAsBytes();
    } on LocalStorageException {
      rethrow;
    } catch (error) {
      throw LocalStorageException('Failed to read private media file.', error);
    }
  }

  @override
  Future<bool> exists(String relativePath) async {
    try {
      final file = await resolveSafeFile(relativePath);
      return file.existsSync();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> deleteIfExists(String relativePath) async {
    try {
      final file = await resolveSafeFile(relativePath);
      if (!file.existsSync()) return false;
      await file.delete();
      return true;
    } on LocalStorageException {
      rethrow;
    } catch (error) {
      throw LocalStorageException(
        'Failed to delete private media file.',
        error,
      );
    }
  }
}

MediaStorageService createPlatformMediaStorageService(
  AppConfig config,
  IdGenerator idGenerator,
) {
  return NativeMediaStorageService(config: config, idGenerator: idGenerator);
}
