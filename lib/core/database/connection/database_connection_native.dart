import 'dart:io';

import 'package:business_manager/core/config/app_config.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens a private, flavor-isolated native SQLite database inside OS application
/// documents storage (`<appDocsDir>/db/<config.databaseName>`).
/// Runs SQLite on a background isolate to protect UI frame rendering.
QueryExecutor openPlatformDatabase(AppConfig config) {
  return LazyDatabase(() async {
    final file = await resolvePrivateDatabaseFile(config);
    return NativeDatabase.createInBackground(file);
  });
}

/// Resolves the private application storage path for the flavor's SQLite file.
Future<File> resolvePrivateDatabaseFile(
  AppConfig config, {
  Directory? baseDirectoryOverride,
}) async {
  final baseDir =
      baseDirectoryOverride ?? await getApplicationDocumentsDirectory();
  final dbDir = Directory(p.join(baseDir.path, 'db'));
  if (!dbDir.existsSync()) {
    await dbDir.create(recursive: true);
  }
  return File(p.join(dbDir.path, config.databaseName));
}
