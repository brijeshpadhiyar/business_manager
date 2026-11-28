import 'dart:typed_data';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_logger.dart';
import 'package:business_manager/core/platform/platform_env.dart';
import 'package:business_manager/features/sync/domain/repositories/cloud_sync_gateway.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

/// Supabase PostgREST + Realtime + Storage implementation of [CloudSyncGateway].
@LazySingleton(as: CloudSyncGateway)
final class SupabaseCloudSyncGateway implements CloudSyncGateway {
  SupabaseCloudSyncGateway(this._config, this._logger);

  final AppConfig _config;
  final AppLogger _logger;
  supa.RealtimeChannel? _realtimeChannel;

  static const String _mediaBucket = 'stitchflow-media';

  @override
  bool get isConfigured => _config.isCloudConfigured;

  supa.SupabaseClient get _client {
    if (!isConfigured) {
      throw StateError('Supabase cloud sync is not configured.');
    }
    return supa.Supabase.instance.client;
  }

  @override
  Future<void> upsertRows({
    required String tableName,
    required String businessId,
    required String ownerId,
    required List<Map<String, Object?>> rows,
  }) async {
    if (rows.isEmpty) return;
    final payload = rows.map((row) {
      final copy = Map<String, Object?>.from(row);
      copy.remove('server_updated_at');
      copy['business_id'] = businessId;
      copy['owner_id'] = ownerId;
      return copy;
    }).toList();

    await _client.from(tableName).upsert(payload, onConflict: 'business_id,id');
  }

  @override
  Future<List<Map<String, Object?>>> pullDeltaRows({
    required String tableName,
    required String businessId,
    String? afterServerUpdatedAt,
    int limit = 500,
  }) async {
    var query = _client.from(tableName).select().eq('business_id', businessId);
    if (afterServerUpdatedAt != null && afterServerUpdatedAt.isNotEmpty) {
      query = query.gt('server_updated_at', afterServerUpdatedAt);
    }
    final response = await query
        .order('server_updated_at', ascending: true)
        .limit(limit);
    return (response as List<dynamic>)
        .map((e) => Map<String, Object?>.from(e as Map))
        .toList();
  }

  @override
  Future<int> countCloudBusinessRows({required String businessId}) async {
    const keyTables = [
      'lots',
      'members',
      'processes',
      'stock_movements',
      'payments',
      'labour_entries',
    ];
    var total = 0;
    for (final table in keyTables) {
      final rows = await _client
          .from(table)
          .select('id')
          .eq('business_id', businessId)
          .limit(1);
      total += (rows as List<dynamic>).length;
    }
    return total;
  }

  @override
  Future<void> publishSyncNotification({
    required String businessId,
    required String ownerId,
    required String deviceId,
    required String lastTable,
  }) async {
    await _client.from('sync_notifications').upsert({
      'business_id': businessId,
      'owner_id': ownerId,
      'last_device_id': deviceId,
      'last_table': lastTable,
      'last_change_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'business_id');
  }

  @override
  Future<void> subscribeToSyncNotifications({
    required String businessId,
    required String currentDeviceId,
    required void Function() onRemoteChange,
  }) async {
    if (!isConfigured || isFlutterTestEnv) return;
    await unsubscribeFromSyncNotifications();
    try {
      final channel = _client.channel('sync_notifications:$businessId');
      channel.onPostgresChanges(
        event: supa.PostgresChangeEvent.all,
        schema: 'public',
        table: 'sync_notifications',
        filter: supa.PostgresChangeFilter(
          type: supa.PostgresChangeFilterType.eq,
          column: 'business_id',
          value: businessId,
        ),
        callback: (payload) {
          final remoteDevice = payload.newRecord['last_device_id']?.toString();
          if (remoteDevice != null && remoteDevice == currentDeviceId) {
            return; // Ignore our own push echo.
          }
          onRemoteChange();
        },
      );
      channel.subscribe();
      _realtimeChannel = channel;
    } catch (e) {
      _logger.warning('Realtime subscription skipped: $e');
    }
  }

  @override
  Future<void> unsubscribeFromSyncNotifications() async {
    final ch = _realtimeChannel;
    _realtimeChannel = null;
    if (ch != null) {
      try {
        await _client.removeChannel(ch);
      } catch (e) {
        _logger.warning('Realtime channel removal skipped: $e');
      }
    }
  }

  @override
  Future<void> uploadMediaBytes({
    required String remotePath,
    required Uint8List bytes,
    required String contentType,
  }) async {
    await _client.storage
        .from(_mediaBucket)
        .uploadBinary(
          remotePath,
          bytes,
          fileOptions: supa.FileOptions(contentType: contentType, upsert: true),
        );
  }

  @override
  Future<Uint8List> downloadMediaBytes({required String remotePath}) async {
    return _client.storage.from(_mediaBucket).download(remotePath);
  }
}
