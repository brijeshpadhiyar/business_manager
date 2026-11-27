import 'dart:convert';

import 'package:business_manager/core/config/app_logger.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/migrations/sync_schema.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/auth/domain/entities/auth_entities.dart';
import 'package:business_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:business_manager/features/sync/domain/entities/sync_entities.dart';
import 'package:business_manager/features/sync/domain/repositories/cloud_sync_gateway.dart';
import 'package:business_manager/features/sync/domain/services/sync_conflict_resolver.dart';
import 'package:business_manager/features/sync/domain/services/sync_table_registry.dart';
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

/// Core bidirectional offline-first sync engine for StitchFlow v1.5.
///
/// Cycle order:
/// 1. **Push** due `sync_outbox` rows in strict FK topological order
///    (parents before children, including self-referencing ledger rows).
/// 2. **Delta Pull** per table using Postgres `server_updated_at > cursor`,
///    applying rows inside `runAsRemoteApply` (no trigger echo) and resolving
///    conflicts via [SyncConflictResolver] with `audit_logs` diff recording.
/// 3. **Cloud Media Sync** uploading queued local photos to Supabase Storage
///    (SHA-256 keyed path) and lazily downloading missing remote photos.
/// 4. **Notify & Heartbeat** updating `user_devices` and `sync_notifications`.
@lazySingleton
final class SyncEngine {
  SyncEngine(
    this._db,
    this._gateway,
    this._mediaStorage,
    this._authRepository,
    this._idGenerator,
    this._logger, {
    @ignoreParam SyncConflictResolver? conflictResolver,
  }) : _conflictResolver = conflictResolver ?? const SyncConflictResolver();

  final AppDatabase _db;
  final CloudSyncGateway _gateway;
  final MediaStorageService _mediaStorage;
  final AuthRepository _authRepository;
  final IdGenerator _idGenerator;
  final AppLogger _logger;
  final SyncConflictResolver _conflictResolver;

  bool _isRunning = false;

  bool get isRunning => _isRunning;
  bool get isCloudConfigured => _gateway.isConfigured;

  /// Inspects local vs cloud row counts on first sign-in to decide whether to
  /// show the Smart Merge Prompt.
  Future<FirstLoginMergeSummary> inspectFirstLoginMerge(AuthUser user) async {
    final localCount = await _db.syncDao.countLocalUserBusinessRows();
    final cloudCount = await _gateway.countCloudBusinessRows(
      businessId: user.businessId,
    );
    return FirstLoginMergeSummary(
      localRowCount: localCount,
      cloudRowCount: cloudCount,
    );
  }

  /// Executes the user's chosen first-login merge strategy and runs a full sync.
  Future<SyncRunSummary> executeFirstLoginMerge(
    AuthUser user,
    FirstLoginMergeChoice choice,
  ) async {
    switch (choice) {
      case FirstLoginMergeChoice.mergeBoth:
        await _db.syncDao.clearAllCursors();
        await _db.syncDao.enqueueAllLocalRowsForInitialSync();
        return runSyncCycle(user);
      case FirstLoginMergeChoice.keepCloudOnly:
        await _db.syncDao.wipeLocalDomainDataForCloudReplace();
        return runSyncCycle(user);
      case FirstLoginMergeChoice.overwriteCloudWithLocal:
        await _db.syncDao.enqueueAllLocalRowsForInitialSync();
        final summary = await runSyncCycle(user);
        return summary;
    }
  }

  /// Executes one serialized bidirectional sync cycle (`Push -> Pull -> Media`).
  Future<SyncRunSummary> runSyncCycle(AuthUser user) async {
    if (_isRunning) {
      return const SyncRunSummary();
    }
    if (!_gateway.isConfigured) {
      return const SyncRunSummary();
    }
    _isRunning = true;
    try {
      final session = await _db.syncDao.getSessionState();
      final now = IstDateTimeHelper.nowUtcMillis();

      // 1. Push local outbox in FK topological order.
      final pushResult = await _pushOutbox(user, now);

      // 2. Pull incremental deltas for all 23 tables.
      final pullResult = await _pullDeltas(user, now);

      // 3. Sync queued media uploads & downloads.
      final mediaResult = await _syncMediaQueue(user, now);

      final completedAt = IstDateTimeHelper.nowUtcMillis();
      await _db.syncDao.markLastFullSyncAt(completedAt);

      // 4. Notify other devices via Realtime wake-up table + device heartbeat.
      if (pushResult.pushed > 0 && pushResult.lastTable != null) {
        try {
          await _gateway.publishSyncNotification(
            businessId: user.businessId,
            ownerId: user.id,
            deviceId: session.deviceId,
            lastTable: pushResult.lastTable!,
          );
        } catch (e) {
          _logger.warning('Sync notification broadcast failed: $e');
        }
      }

      try {
        await _authRepository.registerCurrentDevice(
          deviceId: session.deviceId,
          businessId: user.businessId,
          lastSyncedAtUtcMillis: completedAt,
        );
      } catch (e) {
        _logger.warning('Device heartbeat skipped: $e');
      }

      return SyncRunSummary(
        pushedCount: pushResult.pushed,
        pulledCount: pullResult.pulled,
        conflictsResolved: pullResult.conflicts,
        mediaSyncedCount: mediaResult.synced,
        failedCount: pushResult.failed + mediaResult.failed,
        completedAtUtcMillis: completedAt,
      );
    } finally {
      _isRunning = false;
    }
  }

  Future<({int pushed, int failed, String? lastTable})> _pushOutbox(
    AuthUser user,
    int nowUtcMillis,
  ) async {
    var pushed = 0;
    var failed = 0;
    String? lastTable;

    final dueItems = await _db.syncDao.getDueOutboxItems(
      nowUtcMillis: nowUtcMillis,
      limit: 500,
    );
    if (dueItems.isEmpty) {
      return (pushed: 0, failed: 0, lastTable: null);
    }

    // Group by table and sort tables in strict FK topological order.
    final byTable = <String, List<SyncOutboxRow>>{};
    for (final item in dueItems) {
      byTable.putIfAbsent(item.tableNameCol, () => []).add(item);
    }
    final orderedTables = byTable.keys.toList()
      ..sort(
        (a, b) =>
            SyncTableRegistry.orderOf(a)
                .compareTo(SyncTableRegistry.orderOf(b)),
      );

    for (final table in orderedTables) {
      final items = byTable[table]!;
      final rowsToPush = <Map<String, Object?>>[];
      final keysToAck = <String>[];

      for (final item in items) {
        final localRow = await _db.syncDao.getLocalRowById(table, item.rowId);
        if (localRow == null) {
          // Row no longer exists locally; clean up stale outbox entry.
          keysToAck.add(item.entryKey);
          continue;
        }
        rowsToPush.add(localRow);
        keysToAck.add(item.entryKey);
      }

      if (rowsToPush.isEmpty) {
        await _db.syncDao.removeOutboxEntries(keysToAck);
        continue;
      }

      final sortedRows = SyncTableRegistry.sortSelfReferencingRows(
        table,
        rowsToPush,
      );

      try {
        await _gateway.upsertRows(
          tableName: table,
          businessId: user.businessId,
          ownerId: user.id,
          rows: sortedRows,
        );
        await _db.syncDao.removeOutboxEntries(keysToAck);
        pushed += sortedRows.length;
        lastTable = table;
      } catch (e) {
        _logger.warning('Push failed for table=$table: $e');
        for (final item in items) {
          final nextRetry = item.retryCount + 1;
          final backoff = SyncTableRegistry.backoffForRetry(nextRetry);
          await _db.syncDao.markOutboxFailed(
            item.entryKey,
            error: e.toString(),
            retryCount: nextRetry,
            nextRetryAt: nowUtcMillis + backoff.inMilliseconds,
          );
          failed++;
        }
      }
    }

    return (pushed: pushed, failed: failed, lastTable: lastTable);
  }

  Future<({int pulled, int conflicts})> _pullDeltas(
    AuthUser user,
    int nowUtcMillis,
  ) async {
    var pulled = 0;
    var conflicts = 0;

    for (final table in SyncSchema.syncedTablesInPushOrder) {
      var cursor = await _db.syncDao.getCursor(table);
      final validColumns = await _db.syncDao.getTableColumns(table);

      while (true) {
        final batch = await _gateway.pullDeltaRows(
          tableName: table,
          businessId: user.businessId,
          afterServerUpdatedAt: cursor,
          limit: 500,
        );
        if (batch.isEmpty) break;

        final sortedBatch = SyncTableRegistry.sortSelfReferencingRows(
          table,
          batch,
        );

        String? maxServerUpdatedAt;
        final auditDiffs = <AuditLogsCompanion>[];
        final pendingMediaDownloads =
            <({String id, String sha256, String relativePath})>[];

        await _db.syncDao.runAsRemoteApply(() async {
          for (final remoteRow in sortedBatch) {
            final rowId = remoteRow['id']?.toString();
            if (rowId == null || rowId.isEmpty) continue;

            final serverTs = remoteRow['server_updated_at']?.toString();
            if (serverTs != null &&
                (maxServerUpdatedAt == null ||
                    serverTs.compareTo(maxServerUpdatedAt!) > 0)) {
              maxServerUpdatedAt = serverTs;
            }

            final localRow = await _db.syncDao.getLocalRowById(table, rowId);
            final hasPending = await _db.syncDao.hasPendingOutboxEntry(
              table,
              rowId,
            );

            final resolution = _conflictResolver.resolve(
              tableName: table,
              localRow: localRow,
              remoteRow: remoteRow,
              hasPendingLocalEdit: hasPending,
            );

            if (resolution.hadConflict) {
              conflicts++;
              if (resolution.winner == ConflictWinner.remote &&
                  resolution.supersededLocalRow != null) {
                auditDiffs.add(
                  AuditLogsCompanion(
                    id: Value(_idGenerator.nextEntityId()),
                    entityType: Value(table),
                    entityId: Value(rowId),
                    actionType: const Value('UPDATE'),
                    actor: Value('sync:${user.id}'),
                    previousValueJson: Value(
                      jsonEncode(resolution.supersededLocalRow),
                    ),
                    newValueJson: Value(jsonEncode(remoteRow)),
                    reason: const Value('sync_conflict_lww'),
                    transactionAt: Value(nowUtcMillis),
                    recordedAt: Value(nowUtcMillis),
                  ),
                );
              }
            }

            if (resolution.winner == ConflictWinner.remote) {
              await _db.syncDao.upsertLocalRowFromRemote(
                table,
                resolution.winningRow,
                cachedColumns: validColumns,
              );
              if (hasPending) {
                await _db.syncDao.removeOutboxEntries(['$table:$rowId']);
              }
              pulled++;

              if (table == 'attachments' &&
                  remoteRow['deleted_at'] == null &&
                  remoteRow['relative_path'] != null &&
                  remoteRow['sha256'] != null) {
                pendingMediaDownloads.add((
                  id: rowId,
                  sha256: remoteRow['sha256']!.toString(),
                  relativePath: remoteRow['relative_path']!.toString(),
                ));
              }
            }
          }
        });

        // Write conflict audit logs (normal local write so they sync cleanly).
        for (final diff in auditDiffs) {
          await _db.attachmentAuditDao.insertAuditLog(diff);
        }

        // Enqueue lazy downloads for remote attachments missing on this device.
        for (final media in pendingMediaDownloads) {
          final existsLocally = await _mediaStorage.exists(media.relativePath);
          if (!existsLocally) {
            await _db.syncDao.enqueueMediaDownload(
              attachmentId: media.id,
              sha256: media.sha256,
              relativePath: media.relativePath,
              remotePath: _remoteMediaPath(
                ownerId: user.id,
                businessId: user.businessId,
                sha256: media.sha256,
                relativePath: media.relativePath,
              ),
            );
          }
        }

        if (maxServerUpdatedAt != null) {
          cursor = maxServerUpdatedAt;
          await _db.syncDao.upsertCursor(
            table,
            serverUpdatedAt: maxServerUpdatedAt!,
            pulledAtMillis: nowUtcMillis,
          );
        }

        if (batch.length < 500) break;
      }
    }

    return (pulled: pulled, conflicts: conflicts);
  }

  Future<({int synced, int failed})> _syncMediaQueue(
    AuthUser user,
    int nowUtcMillis,
  ) async {
    var synced = 0;
    var failed = 0;

    final dueMedia = await _db.syncDao.getDueMediaItems(
      nowUtcMillis: nowUtcMillis,
      limit: 20,
    );

    for (final item in dueMedia) {
      final remotePath =
          item.remotePath ??
          _remoteMediaPath(
            ownerId: user.id,
            businessId: user.businessId,
            sha256: item.sha256,
            relativePath: item.relativePath,
          );

      try {
        if (item.direction == 'UPLOAD') {
          final bytes = await _mediaStorage.readBytes(item.relativePath);
          if (bytes == null) {
            await _db.syncDao.markMediaDone(
              item.attachmentId,
              remotePath: remotePath,
            );
            continue;
          }
          await _gateway.uploadMediaBytes(
            remotePath: remotePath,
            bytes: bytes,
            contentType: _inferMimeType(item.relativePath),
          );
          await _db.syncDao.markMediaDone(
            item.attachmentId,
            remotePath: remotePath,
          );
          synced++;
        } else {
          final bytes = await _gateway.downloadMediaBytes(
            remotePath: remotePath,
          );
          final actualHash = _mediaStorage.computeSha256(bytes);
          if (actualHash != item.sha256) {
            throw StateError(
              'SHA-256 mismatch downloading ${item.attachmentId}',
            );
          }
          await _mediaStorage.writeBytesAtRelativePath(
            item.relativePath,
            bytes,
          );
          await _db.syncDao.markMediaDone(
            item.attachmentId,
            remotePath: remotePath,
          );
          synced++;
        }
      } catch (e) {
        final nextRetry = item.retryCount + 1;
        final backoff = SyncTableRegistry.backoffForRetry(nextRetry);
        await _db.syncDao.markMediaFailed(
          item.attachmentId,
          error: e.toString(),
          retryCount: nextRetry,
          nextRetryAt: nowUtcMillis + backoff.inMilliseconds,
        );
        failed++;
      }
    }

    return (synced: synced, failed: failed);
  }

  static String _remoteMediaPath({
    required String ownerId,
    required String businessId,
    required String sha256,
    required String relativePath,
  }) {
    final dotIdx = relativePath.lastIndexOf('.');
    final ext = dotIdx != -1 ? relativePath.substring(dotIdx) : '.jpg';
    return '$ownerId/$businessId/$sha256$ext';
  }

  static String _inferMimeType(String relativePath) {
    final lower = relativePath.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
