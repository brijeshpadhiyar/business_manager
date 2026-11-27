/// Current operational state of the offline-first cloud sync engine.
enum SyncPhase {
  /// User has not signed in (local-only offline mode).
  localOnly,

  /// Signed in, device has no internet connection; writes queue locally.
  offline,

  /// Signed in, online, and all local/remote data is up to date.
  synced,

  /// Actively pushing outbox, pulling deltas, or syncing media.
  syncing,

  /// Signed in with pending/failed items needing retry or attention.
  needsAttention,

  /// First login detected both local and cloud data; awaiting user's merge choice.
  awaitingMergeChoice,
}

final class SyncFailedItem {
  const SyncFailedItem({
    required this.entryKey,
    required this.tableName,
    required this.rowId,
    required this.retryCount,
    required this.lastError,
  });

  final String entryKey;
  final String tableName;
  final String rowId;
  final int retryCount;
  final String lastError;
}

final class FirstLoginMergeSummary {
  const FirstLoginMergeSummary({
    required this.localRowCount,
    required this.cloudRowCount,
  });

  final int localRowCount;
  final int cloudRowCount;

  bool get needsUserPrompt => localRowCount > 0 && cloudRowCount > 0;
}

final class SyncRunSummary {
  const SyncRunSummary({
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.conflictsResolved = 0,
    this.mediaSyncedCount = 0,
    this.failedCount = 0,
    this.completedAtUtcMillis,
  });

  final int pushedCount;
  final int pulledCount;
  final int conflictsResolved;
  final int mediaSyncedCount;
  final int failedCount;
  final int? completedAtUtcMillis;
}

final class SyncState {
  const SyncState({
    this.phase = SyncPhase.localOnly,
    this.isOnline = true,
    this.pendingOutboxCount = 0,
    this.pendingMediaCount = 0,
    this.failedItems = const [],
    this.lastSyncedAtUtcMillis,
    this.lastSummary,
    this.pendingMergeSummary,
    this.errorMessage,
  });

  final SyncPhase phase;
  final bool isOnline;
  final int pendingOutboxCount;
  final int pendingMediaCount;
  final List<SyncFailedItem> failedItems;
  final int? lastSyncedAtUtcMillis;
  final SyncRunSummary? lastSummary;
  final FirstLoginMergeSummary? pendingMergeSummary;
  final String? errorMessage;

  int get totalPendingCount => pendingOutboxCount + pendingMediaCount;

  SyncState copyWith({
    SyncPhase? phase,
    bool? isOnline,
    int? pendingOutboxCount,
    int? pendingMediaCount,
    List<SyncFailedItem>? failedItems,
    int? lastSyncedAtUtcMillis,
    SyncRunSummary? lastSummary,
    FirstLoginMergeSummary? pendingMergeSummary,
    bool clearPendingMerge = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SyncState(
      phase: phase ?? this.phase,
      isOnline: isOnline ?? this.isOnline,
      pendingOutboxCount: pendingOutboxCount ?? this.pendingOutboxCount,
      pendingMediaCount: pendingMediaCount ?? this.pendingMediaCount,
      failedItems: failedItems ?? this.failedItems,
      lastSyncedAtUtcMillis:
          lastSyncedAtUtcMillis ?? this.lastSyncedAtUtcMillis,
      lastSummary: lastSummary ?? this.lastSummary,
      pendingMergeSummary: clearPendingMerge
          ? null
          : (pendingMergeSummary ?? this.pendingMergeSummary),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Pure-Dart projection of `sync_session_state`.
final class SyncSessionSummary {
  const SyncSessionSummary({
    required this.deviceId,
    this.boundUserId,
    this.boundBusinessId,
    this.lastFullSyncAt,
  });

  final String deviceId;
  final String? boundUserId;
  final String? boundBusinessId;
  final int? lastFullSyncAt;
}
