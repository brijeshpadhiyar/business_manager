import 'package:business_manager/core/database/app_database.dart';
import 'package:injectable/injectable.dart';

/// Reusable atomic transaction infrastructure ensuring read -> validate ->
/// multi-table write -> audit log operations either all commit or all roll back.
@lazySingleton
final class DatabaseTransactionRunner {
  DatabaseTransactionRunner(this._database);

  final AppDatabase _database;

  Future<T> runInTransaction<T>(Future<T> Function() action) {
    return _database.transaction(action);
  }
}
