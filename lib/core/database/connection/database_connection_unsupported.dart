import 'package:business_manager/core/config/app_config.dart';
import 'package:drift/drift.dart';

QueryExecutor openPlatformDatabase(AppConfig config) {
  throw UnsupportedError(
    'SQLite database connection is not supported on this platform.',
  );
}
