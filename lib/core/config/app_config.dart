import 'package:business_manager/core/config/app_flavor.dart';

/// Immutable environment configuration isolating `dev` and `prod` storage,
/// identifiers, and logging behavior.
final class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.databaseName,
    required this.mediaDirName,
    required this.enableDebugLogs,
  });

  factory AppConfig.dev() {
    const dbName = String.fromEnvironment(
      'DATABASE_NAME',
      defaultValue: 'business_manager_dev.sqlite',
    );
    const mediaDir = String.fromEnvironment(
      'MEDIA_DIR_NAME',
      defaultValue: 'media_dev',
    );
    return const AppConfig(
      flavor: AppFlavor.dev,
      databaseName: dbName,
      mediaDirName: mediaDir,
      enableDebugLogs: true,
    );
  }

  factory AppConfig.prod() {
    const dbName = String.fromEnvironment(
      'DATABASE_NAME',
      defaultValue: 'business_manager_prod.sqlite',
    );
    const mediaDir = String.fromEnvironment(
      'MEDIA_DIR_NAME',
      defaultValue: 'media_prod',
    );
    return const AppConfig(
      flavor: AppFlavor.prod,
      databaseName: dbName,
      mediaDirName: mediaDir,
      // Debug logging is strictly disabled in production regardless of defines.
      enableDebugLogs: false,
    );
  }

  factory AppConfig.fromEnvironment() {
    const flavorName = String.fromEnvironment('APP_FLAVOR', defaultValue: 'dev');
    return flavorName == 'prod' ? AppConfig.prod() : AppConfig.dev();
  }

  final AppFlavor flavor;
  final String databaseName;
  final String mediaDirName;
  final bool enableDebugLogs;

  bool get isDev => flavor.isDev;
  bool get isProd => flavor.isProd;
}
