import 'package:business_manager/core/config/app_flavor.dart';
import 'package:flutter/foundation.dart';

/// Immutable environment configuration isolating `dev` and `prod` storage,
/// identifiers, and logging behavior.
final class AppConfig {
  const AppConfig({
    required this.flavor,
    required this.databaseName,
    required this.mediaDirName,
    required this.enableDebugLogs,
    this.supabaseUrl = '',
    this.supabaseAnonKey = '',
    this.googleWebClientId = '',
    this.googleIosClientId = '',
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
    const supabaseUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: '',
    );
    const supabaseAnonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    );
    const googleWebClientId = String.fromEnvironment(
      'GOOGLE_WEB_CLIENT_ID',
      defaultValue: '',
    );
    const googleIosClientId = String.fromEnvironment(
      'GOOGLE_IOS_CLIENT_ID',
      defaultValue: '',
    );
    return const AppConfig(
      flavor: AppFlavor.dev,
      databaseName: dbName,
      mediaDirName: mediaDir,
      enableDebugLogs: true,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      googleWebClientId: googleWebClientId,
      googleIosClientId: googleIosClientId,
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
    const supabaseUrl = String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: '',
    );
    const supabaseAnonKey = String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    );
    const googleWebClientId = String.fromEnvironment(
      'GOOGLE_WEB_CLIENT_ID',
      defaultValue: '',
    );
    const googleIosClientId = String.fromEnvironment(
      'GOOGLE_IOS_CLIENT_ID',
      defaultValue: '',
    );
    return const AppConfig(
      flavor: AppFlavor.prod,
      databaseName: dbName,
      mediaDirName: mediaDir,
      // Debug logging is strictly disabled in production regardless of defines.
      enableDebugLogs: false,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      googleWebClientId: googleWebClientId,
      googleIosClientId: googleIosClientId,
    );
  }

  /// Reads `APP_FLAVOR` from `--dart-define-from-file`. There is no silent
  /// default: a build without a flavor fails fast instead of quietly running
  /// against the dev database.
  factory AppConfig.fromEnvironment() {
    const flavorName = String.fromEnvironment('APP_FLAVOR');
    return switch (flavorName) {
      'prod' => AppConfig.prod(),
      'dev' => AppConfig.dev(),
      _ => throw StateError(
        'APP_FLAVOR is not set. Run with '
        '--dart-define-from-file=config/<dev|prod>.local.json, '
        'or use lib/main_dev.dart / lib/main_prod.dart.',
      ),
    };
  }

  final AppFlavor flavor;
  final String databaseName;
  final String mediaDirName;
  final bool enableDebugLogs;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String googleWebClientId;
  final String googleIosClientId;

  bool get isDev => flavor.isDev;
  bool get isProd => flavor.isProd;

  /// True when both Supabase URL and anon key have been supplied via
  /// `--dart-define-from-file=config/<flavor>.local.json` (or `--dart-define`).
  bool get isCloudConfigured =>
      supabaseUrl.trim().isNotEmpty && supabaseAnonKey.trim().isNotEmpty;

  /// Native Google Sign-In on Android/iOS needs `GOOGLE_WEB_CLIENT_ID`;
  /// web and desktop use the Supabase OAuth redirect instead.
  bool get isGoogleSignInConfigured {
    if (!isCloudConfigured) return false;
    final isMobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
    return !isMobile || googleWebClientId.trim().isNotEmpty;
  }
}
