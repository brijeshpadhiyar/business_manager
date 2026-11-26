import 'dart:typed_data';

/// Categories matching the portable `media_<flavor>/` directory layout.
enum MediaCategory {
  lots('lots'),
  movements('movements'),
  payments('payments'),
  profile('profile');

  const MediaCategory(this.folderName);

  final String folderName;
}

/// Metadata produced when saving a local private media/attachment file.
final class SavedMediaFile {
  const SavedMediaFile({
    required this.relativePath,
    required this.fileSizeBytes,
    required this.sha256Hex,
    required this.mimeType,
  });

  /// Portable POSIX-style path relative to the flavor media root
  /// (e.g., `lots/<lot_id>/<uuid>.jpg`).
  final String relativePath;
  final int fileSizeBytes;
  final String sha256Hex;
  final String mimeType;
}

/// Platform-independent abstraction for storing and reading private media files.
abstract interface class MediaStorageService {
  Future<SavedMediaFile> saveBytes({
    required Uint8List bytes,
    required MediaCategory category,
    required String entityId,
    required String fileExtension,
    required String mimeType,
  });

  Future<Uint8List?> readBytes(String relativePath);

  /// Writes raw bytes directly to a validated relative path (used by cloud
  /// media sync when caching downloaded attachments locally).
  Future<void> writeBytesAtRelativePath(String relativePath, Uint8List bytes);

  Future<bool> exists(String relativePath);

  Future<bool> deleteIfExists(String relativePath);

  /// Lists all POSIX-normalized relative file paths currently stored inside the
  /// private flavor media root (returns empty list on platforms without local
  /// filesystem storage such as Web).
  Future<List<String>> listAllRelativePaths();

  /// Computes SHA-256 checksum hex for any byte payload.
  String computeSha256(Uint8List bytes);
}
