import 'package:business_manager/core/config/app_config.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Opens a flavor-isolated WebAssembly SQLite database on Web via `drift_flutter`.
/// Automatically negotiates OPFS (when COOP/COEP headers are present) and falls
/// back gracefully to IndexedDB. Requires `web/sqlite3.wasm` and `web/drift_worker.js`.
QueryExecutor openPlatformDatabase(AppConfig config) {
  final webDbName = config.databaseName.replaceAll('.sqlite', '');
  return driftDatabase(
    name: webDbName,
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
