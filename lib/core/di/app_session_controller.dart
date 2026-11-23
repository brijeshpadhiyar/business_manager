import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/database_initializer.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:flutter/foundation.dart';

/// Coordinates clean dependency graph re-initialization (e.g. immediately after
/// an atomic SQLite + media restore) so no singleton ever holds a closed DB handle.
final class AppSessionController extends ChangeNotifier {
  AppSessionController._();

  static final AppSessionController instance = AppSessionController._();

  int _generation = 0;

  int get generation => _generation;

  Future<void> reloadSession(AppConfig config) async {
    await getIt.reset();
    await configureDependencies(config);
    await getIt<DatabaseInitializer>().initialize();
    _generation++;
    notifyListeners();
  }
}
