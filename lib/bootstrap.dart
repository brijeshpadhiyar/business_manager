import 'package:business_manager/app.dart';
import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_logger.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_initializer.dart';
import 'package:business_manager/core/dev/dev_perf_seeder.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/notifications/data/services/notification_refresh_coordinator.dart';
import 'package:business_manager/features/notifications/domain/services/local_notification_service.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:flutter/widgets.dart';

/// Shared application startup sequence across all flavors and platforms.
Future<void> bootstrap(AppConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Keep decoded image memory bounded on mobile while preserving smooth scroll
  // thumbnail caching (default Flutter ceiling is 100 MB / 1000 images).
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSize = 200;
  imageCache.maximumSizeBytes = 64 << 20;

  IstDateTimeHelper.initialize();
  await configureDependencies(config);
  await getIt<DatabaseInitializer>().initialize();
  if (config.isDev && DevPerfSeeder.enabled) {
    await DevPerfSeeder.seedIfRequested(
      config: config,
      db: getIt<AppDatabase>(),
      mediaStorage: getIt<MediaStorageService>(),
      logger: getIt<AppLogger>(),
    );
  }
  await getIt<AppLockCubit>().initialize();

  // Initialize offline Android notifications & lock-safe cold-launch deep-link queue
  final notifService = getIt<LocalNotificationService>();
  await notifService.initialize(
    onDeepLinkTap: (route) => getIt<AppLockCubit>().queueDeepLinkRoute(route),
  );
  final launchRoute = await notifService.consumeLaunchRoute();
  if (launchRoute != null) {
    getIt<AppLockCubit>().queueDeepLinkRoute(launchRoute);
  }
  getIt<NotificationRefreshCoordinator>().triggerBackgroundRefresh();

  getIt<AppLogger>().info(
    'Bootstrapped flavor=${config.flavor.name}, db=${config.databaseName}',
  );

  runApp(BusinessManagerApp(config: config));
}
