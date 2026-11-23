import 'package:business_manager/core/config/app_logger.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_pragma_status.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:injectable/injectable.dart';

/// Idempotent database initializer that opens the local SQLite database once,
/// verifies effective PRAGMAs (`foreign_keys`, `WAL`, `synchronous = FULL`),
/// and surfaces initialization errors cleanly.
@lazySingleton
final class DatabaseInitializer {
  DatabaseInitializer(this._database, this._logger);

  final AppDatabase _database;
  final AppLogger _logger;

  Future<DatabasePragmaStatus>? _initFuture;

  Future<DatabasePragmaStatus> initialize() {
    return _initFuture ??= _runInitialization();
  }

  Future<DatabasePragmaStatus> _runInitialization() async {
    try {
      final status = await _database.verifyPragmas();
      if (!status.foreignKeysEnabled) {
        throw const LocalStorageException(
          'SQLite foreign_keys PRAGMA failed to enable.',
        );
      }
      _logger.info(
        'SQLite initialized: fk=${status.foreignKeysEnabled}, '
        'journal=${status.journalMode}, sync=${status.synchronousLevel}, '
        'timeout=${status.busyTimeoutMs}ms',
      );
      return status;
    } catch (error) {
      _initFuture = null;
      _logger.error('Database initialization failed', error: error);
      if (error is LocalStorageException) rethrow;
      throw LocalStorageException('Failed to initialize SQLite database.', error);
    }
  }
}
