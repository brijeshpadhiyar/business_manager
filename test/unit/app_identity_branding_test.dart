import 'dart:io';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_identity.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('AppIdentity & flavor separation', () {
    test('exposes official StitchFlow brand identity and URL scheme', () {
      expect(AppIdentity.appName, 'StitchFlow');
      expect(AppIdentity.shortName, 'StitchFlow');
      expect(AppIdentity.appVersion, '1.5.0');
      expect(AppIdentity.appBuildNumber, '5');
      expect(AppIdentity.tagline, 'From Fabric to Finished.');
      expect(AppIdentity.urlScheme, 'stitchflow');
    });

    test('separates dev and prod identifiers cleanly', () {
      final dev = AppConfig.dev();
      final prod = AppConfig.prod();

      expect(AppIdentity.displayNameFor(dev), 'StitchFlow Dev');
      expect(AppIdentity.displayNameFor(prod), 'StitchFlow');
      expect(AppIdentity.androidIdFor(dev), 'com.brijesh.stitchflow.dev');
      expect(AppIdentity.androidIdFor(prod), 'com.brijesh.stitchflow');
      expect(AppIdentity.appleBundleIdFor(dev), 'com.brijesh.stitchflow.dev');
      expect(AppIdentity.appleBundleIdFor(prod), 'com.brijesh.stitchflow');
      expect(AppIdentity.linuxAppId, 'com.brijesh.stitchflow');
    });
  });

  group('StitchFlow brand color tokens & theme integration', () {
    test('uses the v1.4 Indigo Thread brand color tokens', () {
      expect(AppColors.brandPrimary, const Color(0xFF4F46E5));
      expect(AppColors.brandSecondary, const Color(0xFF059669));
      expect(AppColors.brandAccent, const Color(0xFFF59E0B));
      expect(AppColors.brandSurface, const Color(0xFFF8FAFC));
    });

    test('integrates brand colors into Light & Dark Material 3 themes while preserving semantics', () {
      final light = AppTheme.light();
      final dark = AppTheme.dark();

      expect(light.colorScheme.primary, AppColors.brandPrimary);
      expect(light.colorScheme.secondary, AppColors.brandSecondary);
      expect(light.colorScheme.tertiary, AppColors.brandAccent);
      expect(light.colorScheme.surface, AppColors.brandSurface);

      expect(dark.brightness, Brightness.dark);
      expect(dark.colorScheme.primary, AppColors.indigo400);
      expect(dark.colorScheme.surface, AppColors.darkSurface);

      // Existing semantic status tokens remain intact
      expect(
        light.extension<AppSemanticColors>()?.goodStock,
        AppColors.lightGoodStock,
      );
      expect(
        dark.extension<AppSemanticColors>()?.damaged,
        AppColors.darkDamaged,
      );
    });
  });

  group('Branding asset availability', () {
    test(
      'all required master logos, icons, and splash assets exist on disk',
      () {
        const requiredFiles = [
          'assets/branding/logo/stitchflow_logo.svg',
          'assets/branding/logo/stitchflow_logo.png',
          'assets/branding/logo/stitchflow_logo_horizontal.svg',
          'assets/branding/logo/stitchflow_logo_horizontal.png',
          'assets/branding/logo/stitchflow_logo_dark.svg',
          'assets/branding/logo/stitchflow_logo_monochrome.svg',
          'assets/branding/logo/stitchflow_symbol.svg',
          'assets/branding/logo/stitchflow_symbol.png',
          'assets/branding/icons/android_adaptive_foreground.png',
          'assets/branding/icons/android_adaptive_background.png',
          'assets/branding/icons/android_adaptive_monochrome.png',
          'assets/branding/icons/stitchflow_ios_1024.png',
          'assets/branding/icons/stitchflow_windows.ico',
          'assets/branding/icons/stitchflow_macos.icns',
          'assets/branding/icons/stitchflow_linux_512.png',
          'assets/branding/icons/stitchflow_linux.svg',
          'assets/branding/splash/stitchflow_splash_light.png',
          'assets/branding/splash/stitchflow_splash_dark.png',
        ];

        for (final path in requiredFiles) {
          final file = File(path);
          expect(
            file.existsSync(),
            isTrue,
            reason: 'Missing brand asset: $path',
          );
          expect(
            file.lengthSync(),
            greaterThan(0),
            reason: 'Empty asset: $path',
          );
        }
      },
    );
  });
}
