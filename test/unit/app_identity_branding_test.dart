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
    test('uses exact official StitchFlow hex color tokens', () {
      expect(AppColors.brandNavy, const Color(0xFF172B4D));
      expect(AppColors.brandTeal, const Color(0xFF0D9488));
      expect(AppColors.brandAmber, const Color(0xFFF4A340));
      expect(AppColors.brandSoftWhite, const Color(0xFFF5F7FA));
    });

    test('integrates brand colors into Light & Dark Material 3 themes while preserving semantics', () {
      final light = AppTheme.light();
      final dark = AppTheme.dark();

      expect(light.colorScheme.primary, AppColors.brandNavy);
      expect(light.colorScheme.secondary, AppColors.brandTeal);
      expect(light.colorScheme.tertiary, AppColors.brandAmber);
      expect(light.colorScheme.surface, AppColors.brandSoftWhite);

      expect(dark.brightness, Brightness.dark);
      expect(dark.colorScheme.secondary, AppColors.brandTeal);
      expect(dark.colorScheme.tertiary, AppColors.brandAmber);

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
