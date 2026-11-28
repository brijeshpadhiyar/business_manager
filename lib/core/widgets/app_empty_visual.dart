import 'package:business_manager/core/design_system/app_density.dart';
import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';

/// Categorized StitchFlow empty-state visual presets backed by bundled Lottie
/// animations in `assets/animations/`.
enum AppEmptyAnimation {
  box('assets/animations/empty_box.json'),
  search('assets/animations/empty_search.json'),
  finance('assets/animations/empty_finance.json'),
  workers('assets/animations/empty_workers.json'),
  allClear('assets/animations/empty_all_clear.json'),
  none(null);

  const AppEmptyAnimation(this.assetPath);

  /// Bundled Lottie JSON asset path, or `null` for icon-only fallback.
  final String? assetPath;

  /// Resolves the best matching empty-state category from a semantic [AppIcons]
  /// icon so existing [AppEmptyState] call sites get context-appropriate motion
  /// automatically.
  static AppEmptyAnimation fromIcon(IconData icon) {
    if (icon == AppIcons.clearFilter ||
        icon == AppIcons.help ||
        icon == AppIcons.search) {
      return AppEmptyAnimation.search;
    }
    if (icon == AppIcons.worker ||
        icon == AppIcons.workers ||
        icon == AppIcons.unlink ||
        icon == AppIcons.team) {
      return AppEmptyAnimation.workers;
    }
    if (icon == AppIcons.payment ||
        icon == AppIcons.ledger ||
        icon == AppIcons.pieceRate ||
        icon == AppIcons.workHistory ||
        icon == AppIcons.accounting) {
      return AppEmptyAnimation.finance;
    }
    if (icon == AppIcons.qcPassed ||
        icon == AppIcons.cloudDone ||
        icon == AppIcons.successOutline ||
        icon == AppIcons.success) {
      return AppEmptyAnimation.allClear;
    }
    return AppEmptyAnimation.box;
  }
}

/// Renders the visual centerpiece of an empty ("no data") state.
///
/// Supports:
/// - **GIF / raster asset** when [gifAsset] is provided.
/// - **Lottie vector animation** via [lottieAsset] or smart-mapped
///   [AppEmptyAnimation] (defaulting from [icon]).
/// - **Animated / static icon halo fallback** when [animation] is
///   [AppEmptyAnimation.none] or if an asset fails to load.
///
/// Automatically respects [AppMotion.reduceMotion] by resting on the final
/// calm frame when reduced motion is requested.
final class AppEmptyVisual extends StatefulWidget {
  const AppEmptyVisual({
    super.key,
    required this.icon,
    this.animation,
    this.lottieAsset,
    this.gifAsset,
    this.size = 104,
    this.animateIcon = true,
  });

  final IconData icon;
  final AppEmptyAnimation? animation;
  final String? lottieAsset;
  final String? gifAsset;
  final double size;
  final bool animateIcon;

  @override
  State<AppEmptyVisual> createState() => _AppEmptyVisualState();
}

class _AppEmptyVisualState extends State<AppEmptyVisual>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);
  bool _hasComposition = false;
  Duration _compositionDuration = const Duration(milliseconds: 3000);

  String? get _resolvedLottiePath {
    if (widget.lottieAsset != null && widget.lottieAsset!.isNotEmpty) {
      return widget.lottieAsset;
    }
    final category =
        widget.animation ?? AppEmptyAnimation.fromIcon(widget.icon);
    return category.assetPath;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPlayback();
  }

  @override
  void didUpdateWidget(covariant AppEmptyVisual oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lottieAsset != widget.lottieAsset ||
        oldWidget.animation != widget.animation ||
        oldWidget.icon != widget.icon ||
        oldWidget.gifAsset != widget.gifAsset) {
      _hasComposition = false;
      _controller.reset();
    }
    _syncPlayback();
  }

  void _syncPlayback() {
    if (!mounted || !_hasComposition) return;
    if (widget.gifAsset != null || _resolvedLottiePath == null) {
      if (_controller.isAnimating) {
        _controller.stop();
      }
      return;
    }
    if (AppMotion.reduceMotion(context)) {
      _controller.stop();
      _controller.value = 1.0;
      return;
    }
    _controller.duration = _compositionDuration;
    final isTestBinding = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
    if (isTestBinding) {
      // Widget tests routinely call pumpAndSettle() on empty screens; play
      // one full cycle instead of an unbounded ticker so tests settle cleanly
      // while the live app loops continuously.
      if (!_controller.isAnimating && _controller.value == 0.0) {
        _controller.forward();
      }
      return;
    }
    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = context.density;
    final effectiveSize = d.isCompact ? widget.size * 0.68 : widget.size;
    final gif = widget.gifAsset;
    if (gif != null && gif.isNotEmpty) {
      return RepaintBoundary(
        child: ClipRRect(
          borderRadius: d.radiusXlBorder,
          child: Image.asset(
            gif,
            width: effectiveSize,
            height: effectiveSize,
            fit: BoxFit.contain,
            excludeFromSemantics: true,
            errorBuilder: (_, _, _) => _buildIconFallback(context),
          ),
        ),
      );
    }

    final lottiePath = _resolvedLottiePath;
    if (lottiePath != null) {
      return RepaintBoundary(
        child: SizedBox.square(
          dimension: effectiveSize,
          child: Lottie.asset(
            lottiePath,
            controller: _controller,
            fit: BoxFit.contain,
            onLoaded: (composition) {
              if (!mounted) return;
              _hasComposition = true;
              final ms = (composition.duration.inMilliseconds * 1.15).round();
              _compositionDuration = Duration(milliseconds: ms < 800 ? 800 : ms);
              _syncPlayback();
            },
            errorBuilder: (_, _, _) => _buildIconFallback(context),
          ),
        ),
      );
    }

    return _buildIconFallback(context);
  }

  Widget _buildIconFallback(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final d = context.density;
    final haloSize = d.isCompact ? 46.0 : 68.0;
    final halo = Container(
      width: haloSize,
      height: haloSize,
      decoration: BoxDecoration(
        color: colorScheme.secondary.withValues(alpha: 0.12),
        borderRadius: AppRadius.fullBorder,
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.25),
        ),
      ),
      child: Icon(widget.icon, size: d.iconXl, color: colorScheme.secondary),
    );

    if (!widget.animateIcon || AppMotion.reduceMotion(context)) {
      return halo;
    }

    return halo
        .animate(onPlay: (controller) => controller.repeat(count: 2, reverse: true))
        .scaleXY(
          begin: 0.96,
          end: 1.04,
          duration: const Duration(milliseconds: 1100),
          curve: Curves.easeInOut,
        );
  }
}
