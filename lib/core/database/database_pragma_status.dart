/// Snapshot of effective SQLite PRAGMA settings verified after opening the DB.
final class DatabasePragmaStatus {
  const DatabasePragmaStatus({
    required this.foreignKeysEnabled,
    required this.journalMode,
    required this.synchronousLevel,
    required this.busyTimeoutMs,
  });

  final bool foreignKeysEnabled;
  final String journalMode;

  /// SQLite synchronous integer level (`0` = OFF, `1` = NORMAL, `2` = FULL, `3` = EXTRA).
  final int synchronousLevel;
  final int busyTimeoutMs;

  bool get isWalMode => journalMode.toLowerCase() == 'wal';
  bool get isSynchronousFull => synchronousLevel == 2;
}
