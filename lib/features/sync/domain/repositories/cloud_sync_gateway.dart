import 'dart:typed_data';

/// Abstract cloud transport for StitchFlow v1.5 sync.
/// Isolates `supabase_flutter` inside `data/` so `SyncEngine` can be tested
/// deterministically without a live network connection.
abstract interface class CloudSyncGateway {
  bool get isConfigured;

  /// Upserts a batch of rows for [tableName] scoped to [businessId] & [ownerId].
  Future<void> upsertRows({
    required String tableName,
    required String businessId,
    required String ownerId,
    required List<Map<String, Object?>> rows,
  });

  /// Pulls incremental rows where `business_id = businessId` and
  /// `server_updated_at > afterServerUpdatedAt` (or all rows if null).
  Future<List<Map<String, Object?>>> pullDeltaRows({
    required String tableName,
    required String businessId,
    String? afterServerUpdatedAt,
    int limit = 500,
  });

  /// Counts key business rows in cloud for first-login merge detection.
  Future<int> countCloudBusinessRows({required String businessId});

  /// Publishes a lightweight wake-up ping to `sync_notifications` so other
  /// online devices of the same owner pull immediately.
  Future<void> publishSyncNotification({
    required String businessId,
    required String ownerId,
    required String deviceId,
    required String lastTable,
  });

  /// Subscribes to Realtime wake-up notifications for [businessId], invoking
  /// [onRemoteChange] when another device pushes changes.
  Future<void> subscribeToSyncNotifications({
    required String businessId,
    required String currentDeviceId,
    required void Function() onRemoteChange,
  });

  Future<void> unsubscribeFromSyncNotifications();

  /// Uploads raw bytes to private bucket `stitchflow-media/<remotePath>`
  /// with upsert idempotency (SHA-256 keyed path deduplicates automatically).
  Future<void> uploadMediaBytes({
    required String remotePath,
    required Uint8List bytes,
    required String contentType,
  });

  /// Downloads raw bytes from private bucket `stitchflow-media/<remotePath>`.
  Future<Uint8List> downloadMediaBytes({required String remotePath});
}
