import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_density.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/theme/theme_state.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// Resolved adaptive rendering capabilities for StitchFlow's 3-tier glass
/// quality policy (`Classic Solid`, `Modern Glass`, `Liquid Aurora`).
///
/// Automatically scales blur sigmas and shader usage based on:
/// - Selected [AppSurfaceStyle]
/// - [UiDensityMode.compact] (preserves 120Hz crispness in Compact ERP mode)
/// - Platform reduced-motion accessibility setting
/// - Fragment shader / Impeller platform support
@immutable
final class AppGlassQuality {
  const AppGlassQuality({
    required this.style,
    required this.enableBackdropBlur,
    required this.enableLiquidShader,
    required this.enableAnimatedMesh,
    required this.chromeBlurSigma,
    required this.cardBlurSigma,
  });

  final AppSurfaceStyle style;
  final bool enableBackdropBlur;
  final bool enableLiquidShader;
  final bool enableAnimatedMesh;
  final double chromeBlurSigma;
  final double cardBlurSigma;

  static bool get isTestBinding {
    final bindingName = WidgetsBinding.instance.runtimeType.toString();
    return bindingName.contains('Test');
  }

  /// Fragment shaders (LiquidGlass & OMeshGradient) run best on native
  /// Impeller platforms (Android/iOS/macOS) and gracefully fall back to
  /// BackdropFilter + gradient orbs on Web/Windows/Linux or inside widget tests.
  static bool get supportsFragmentShaders {
    if (kIsWeb || isTestBinding) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  static AppGlassQuality resolve(BuildContext context) {
    final tokens = context.surfaceTokens;
    final style = tokens.surfaceStyle;
    if (style == AppSurfaceStyle.classicSolid) {
      return const AppGlassQuality(
        style: AppSurfaceStyle.classicSolid,
        enableBackdropBlur: false,
        enableLiquidShader: false,
        enableAnimatedMesh: false,
        chromeBlurSigma: 0,
        cardBlurSigma: 0,
      );
    }

    final isCompact = context.isCompactDensity;
    final reduceMotion = AppMotion.reduceMotion(context);
    final isAurora = style == AppSurfaceStyle.liquidAurora;
    final canRunShaders = supportsFragmentShaders;

    return AppGlassQuality(
      style: style,
      enableBackdropBlur: true,
      enableLiquidShader: false,
      enableAnimatedMesh: isAurora && canRunShaders && !isCompact && !reduceMotion,
      chromeBlurSigma: isCompact ? 8.0 : (isAurora ? 14.0 : 12.0),
      cardBlurSigma: isCompact ? 8.0 : (isAurora ? 14.0 : 12.0),
    );
  }
}

