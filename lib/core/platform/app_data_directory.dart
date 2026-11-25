import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Root folder for the app's private data (SQLite database, lot photos,
/// backup staging).
///
/// * Android / iOS / macOS: the app's private documents folder (unchanged).
/// * Windows / Linux: the per-user application-support folder
///   (`%APPDATA%\com.brijesh\StitchFlow` on Windows). The documents folder
///   there is the user's visible Documents folder, often synced by OneDrive,
///   which can lock or corrupt a live SQLite file.
Future<Directory> resolveAppDataDirectory() async {
  if (Platform.isWindows || Platform.isLinux) {
    return getApplicationSupportDirectory();
  }
  return getApplicationDocumentsDirectory();
}
