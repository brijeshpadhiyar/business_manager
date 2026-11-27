import 'package:business_manager/features/sync/domain/services/sync_table_registry.dart';

enum ConflictWinner { remote, local }

final class ConflictResolution {
  const ConflictResolution({
    required this.winner,
    required this.winningRow,
    required this.hadConflict,
    this.supersededLocalRow,
  });

  final ConflictWinner winner;
  final Map<String, Object?> winningRow;
  final bool hadConflict;
  final Map<String, Object?>? supersededLocalRow;
}

/// Pure Dart conflict resolver for StitchFlow v1.5 offline-first sync.
///
/// Rules:
/// - **Append-only tables** (`stock_movements`, `labour_entries`, `payments`,
///   `worker_ledger_adjustments`, `audit_logs`, `production_returns`,
///   `production_inspections`, `process_handovers`, `process_additional_charges`,
///   `process_rate_history`): union-merged without conflict. If a row already
///   exists locally, it is preserved untouched.
/// - **Mutable tables** (`lots`, `members`, `processes`, `business_profile`,
///   etc.): Last-Write-Wins using `updated_at` epoch millis (remote wins ties).
///   When a pending local edit is superseded by a newer remote edit,
///   [ConflictResolution.hadConflict] is `true` so the caller logs an audit diff.
final class SyncConflictResolver {
  const SyncConflictResolver();

  ConflictResolution resolve({
    required String tableName,
    required Map<String, Object?>? localRow,
    required Map<String, Object?> remoteRow,
    required bool hasPendingLocalEdit,
  }) {
    if (localRow == null) {
      return ConflictResolution(
        winner: ConflictWinner.remote,
        winningRow: remoteRow,
        hadConflict: false,
      );
    }

    if (SyncTableRegistry.isAppendOnly(tableName)) {
      return ConflictResolution(
        winner: ConflictWinner.local,
        winningRow: localRow,
        hadConflict: false,
      );
    }

    final localUpdatedAt = _extractTimestamp(localRow);
    final remoteUpdatedAt = _extractTimestamp(remoteRow);

    if (hasPendingLocalEdit && localUpdatedAt > remoteUpdatedAt) {
      // Local edit is strictly newer — keep local and let outbox push it.
      return ConflictResolution(
        winner: ConflictWinner.local,
        winningRow: localRow,
        hadConflict: true,
      );
    }

    final superseded =
        hasPendingLocalEdit && _hasMeaningfulDiff(localRow, remoteRow);
    return ConflictResolution(
      winner: ConflictWinner.remote,
      winningRow: remoteRow,
      hadConflict: superseded,
      supersededLocalRow: superseded ? localRow : null,
    );
  }

  static int _extractTimestamp(Map<String, Object?> row) {
    final updated = row['updated_at'] ?? row['changed_at'] ?? row['created_at'];
    if (updated is int) return updated;
    if (updated is num) return updated.toInt();
    if (updated is String) return int.tryParse(updated) ?? 0;
    return 0;
  }

  static bool _hasMeaningfulDiff(
    Map<String, Object?> localRow,
    Map<String, Object?> remoteRow,
  ) {
    const ignoredKeys = {
      'business_id',
      'owner_id',
      'server_updated_at',
      'updated_at',
    };
    for (final entry in localRow.entries) {
      if (ignoredKeys.contains(entry.key)) continue;
      if (!remoteRow.containsKey(entry.key)) continue;
      if (entry.value != remoteRow[entry.key]) return true;
    }
    return false;
  }
}
