import 'package:business_manager/core/config/app_config.dart';

/// Centralized official StitchFlow brand and platform identity metadata.
/// Complements [AppConfig] without duplicating environment configuration.
abstract final class AppIdentity {
  static const String appName = 'StitchFlow';
  static const String shortName = 'StitchFlow';
  static const String devAppName = 'StitchFlow Dev';
  static const String tagline = 'From Fabric to Finished.';
  static const String category = 'Garment & Production Management';
  static const String urlScheme = 'stitchflow';

  // Official cross-platform application identifiers
  static const String androidProdId = 'com.brijesh.stitchflow';
  static const String androidDevId = 'com.brijesh.stitchflow.dev';
  static const String appleProdBundleId = 'com.brijesh.stitchflow';
  static const String appleDevBundleId = 'com.brijesh.stitchflow.dev';
  static const String linuxAppId = 'com.brijesh.stitchflow';

  // Master brand asset paths
  static const String symbolPngAsset =
      'assets/branding/logo/stitchflow_symbol.png';
  static const String logoPngAsset = 'assets/branding/logo/stitchflow_logo.png';
  static const String horizontalLogoPngAsset =
      'assets/branding/logo/stitchflow_logo_horizontal.png';
  static const String splashLightAsset =
      'assets/branding/splash/stitchflow_splash_light.png';
  static const String splashDarkAsset =
      'assets/branding/splash/stitchflow_splash_dark.png';

  static String displayNameFor(AppConfig config) =>
      config.isDev ? devAppName : appName;

  static String androidIdFor(AppConfig config) =>
      config.isDev ? androidDevId : androidProdId;

  static String appleBundleIdFor(AppConfig config) =>
      config.isDev ? appleDevBundleId : appleProdBundleId;
}
