import 'package:business_manager/app.dart';
import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_logger.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:flutter/widgets.dart';

/// Shared application startup sequence across all flavors and platforms.
Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  IstDateTimeHelper.initialize();
  await configureDependencies(config);

  getIt<AppLogger>().info(
    'Bootstrapped flavor=${config.flavor.name}, db=${config.databaseName}',
  );

  runApp(BusinessManagerApp(config: config));
}
