import 'dart:async';
import 'dart:ui';

import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_glass_quality.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_shadows.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:material_ui/material_ui.dart';
import 'package:toastification/toastification.dart';
import 'package:business_manager/core/widgets/app_loader.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Semantic notification severity levels supported by [AppMessageService].
enum AppMessageType { success, error, warning, info, loading }

/// Opaque handle returned by [AppMessageService] so callers can dismiss a
/// specific notification (such as a loading banner) without depending on any
/// third-party notification package.
final class AppMessageHandle {
  const AppMessageHandle._(this._item);

  final ToastificationItem? _item;
}

/// Centralized Glassmorphism Application Messaging Service for StitchFlow V1.3.
///
/// Wraps `toastification` behind a clean service abstraction so feature modules
/// never import the third-party notification package directly.
///
/// Features:
/// - Light Glass & Dark Glass translucent frosted cards with luminous borders
/// - Semantic icon containers (Success, Error, Warning, Info, Loading)
/// - Responsive placement (top-right on tablet/desktop, top-center on mobile)
/// - Duplicate rapid-message throttling (1.2s window)
/// - Mounted-context safety & graceful `ScaffoldMessenger` fallback in isolated
///   tests where `ToastificationWrapper` is not mounted
abstract final class AppMessageService {
  static String? _lastDedupKey;
  static DateTime? _lastShownAt;
  static const Duration _dedupWindow = Duration(milliseconds: 1200);
  static final Map<ToastificationItem, Timer> _autoCloseTimers = {};

  /// Shows a green semantic success notification.
  static AppMessageHandle? success(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return _show(
      context,
      type: AppMessageType.success,
      title: title,
      message: message,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Shows a red semantic error notification with optional retry action.
  static AppMessageHandle? error(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return _show(
      context,
      type: AppMessageType.error,
      title: title,
      message: message,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Shows an amber semantic warning notification.
  static AppMessageHandle? warning(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return _show(
      context,
      type: AppMessageType.warning,
      title: title,
      message: message,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Shows a blue/neutral informational notification.
  static AppMessageHandle? info(
    BuildContext context,
    String message, {
    String? title,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return _show(
      context,
      type: AppMessageType.info,
      title: title,
      message: message,
      duration: duration,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }

  /// Shows a persistent glass loading notification until manually dismissed via
  /// [dismiss] or [dismissAll].
  static AppMessageHandle? loading(
    BuildContext context,
    String message, {
    String? title,
  }) {
    return _show(
      context,
      type: AppMessageType.loading,
      title: title,
      message: message,
      duration: null,
    );
  }

  /// Dismisses a specific active notification handle.
  static void dismiss(AppMessageHandle? handle) {
    final item = handle?._item;
    if (item != null) {
      _autoCloseTimers.remove(item)?.cancel();
      toastification.dismiss(item);
    }
  }

  /// Cancels all managed auto-close timers synchronously without scheduling
  /// exit-animation timers. Called on app teardown to prevent leaked timers.
  static void cancelPendingTimers() {
    for (final timer in _autoCloseTimers.values) {
      timer.cancel();
    }
    _autoCloseTimers.clear();
    _lastDedupKey = null;
    _lastShownAt = null;
  }

  /// Dismisses all active notifications (also clears duplicate throttle state).
  static void dismissAll({bool delayForAnimation = false}) {
    cancelPendingTimers();
    toastification.dismissAll(delayForAnimation: delayForAnimation);
  }

  static AppMessageHandle? _show(
    BuildContext context, {
    required AppMessageType type,
    required String message,
    String? title,
    required Duration? duration,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if (!context.mounted) return null;
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty) return null;

    // Duplicate rapid-notification throttling (skipped for explicit loading).
    if (type != AppMessageType.loading) {
      final key = '${type.name}|$cleanMessage';
      final now = DateTime.now();
      if (_lastDedupKey == key &&
          _lastShownAt != null &&
          now.difference(_lastShownAt!) < _dedupWindow) {
        return null;
      }
      _lastDedupKey = key;
      _lastShownAt = now;
    }

    final resolvedTitle = title ?? _defaultTitle(context, type);
    final media = MediaQuery.maybeOf(context);
    final isWide = (media?.size.width ?? 400) >= AppBreakpoints.tabletMinWidth;
    final alignment = isWide ? Alignment.topRight : Alignment.topCenter;
    final reduceMotion = AppMotion.reduceMotion(context);

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      _fallbackSnackBar(context, type: type, message: cleanMessage);
      return const AppMessageHandle._(null);
    }

    try {
      final item = toastification.showCustom(
        context: context,
        alignment: alignment,
        autoCloseDuration: null,
        animationDuration: reduceMotion ? Duration.zero : AppMotion.fast,
        builder: (toastCtx, holder) => _GlassToastCard(
          type: type,
          title: resolvedTitle,
          message: cleanMessage,
          actionLabel: actionLabel,
          onAction: onAction == null
              ? null
              : () {
                  _autoCloseTimers.remove(holder)?.cancel();
                  toastification.dismiss(holder);
                  onAction();
                },
          onClose: () {
            _autoCloseTimers.remove(holder)?.cancel();
            toastification.dismiss(holder);
          },
        ),
      );
      if (duration != null) {
        _autoCloseTimers[item] = Timer(duration, () {
          _autoCloseTimers.remove(item);
          toastification.dismiss(item);
        });
      }
      return AppMessageHandle._(item);
    } catch (_) {
      _fallbackSnackBar(context, type: type, message: cleanMessage);
      return const AppMessageHandle._(null);
    }
  }

  static String _defaultTitle(BuildContext context, AppMessageType type) {
    final l10n = context.l10nOrNull;
    if (l10n != null) {
      return switch (type) {
        AppMessageType.success => l10n.msgTitleSuccess,
        AppMessageType.error => l10n.msgTitleError,
        AppMessageType.warning => l10n.msgTitleWarning,
        AppMessageType.info => l10n.msgTitleInfo,
        AppMessageType.loading => l10n.msgTitleLoading,
      };
    }
    return switch (type) {
      AppMessageType.success => 'Success',
      AppMessageType.error => 'Error',
      AppMessageType.warning => 'Warning',
      AppMessageType.info => 'Information',
      AppMessageType.loading => 'Working...',
    };
  }

  static void _fallbackSnackBar(
    BuildContext context, {
    required AppMessageType type,
    required String message,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (icon, color) = _visualsFor(type, isDark);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(message)),
            ],
          ),
        ),
      );
  }

  static (IconData, Color) _visualsFor(AppMessageType type, bool isDark) {
    return switch (type) {
      AppMessageType.success => (
        AppIcons.success,
        isDark ? AppColors.darkGoodStock : AppColors.lightGoodStock,
      ),
      AppMessageType.error => (
        AppIcons.error,
        isDark ? AppColors.darkDamaged : AppColors.lightDamaged,
      ),
      AppMessageType.warning => (
        AppIcons.warning,
        isDark ? AppColors.darkPending : AppColors.lightPending,
      ),
      AppMessageType.info => (
        AppIcons.info,
        isDark ? AppColors.darkInfo : AppColors.lightInfo,
      ),
      AppMessageType.loading => (
        AppIcons.waiting,
        isDark ? AppColors.darkInfo : AppColors.lightInfo,
      ),
    };
  }
}

final class _GlassToastCard extends StatelessWidget {
  const _GlassToastCard({
    required this.type,
    required this.title,
    required this.message,
    required this.onClose,
    this.actionLabel,
    this.onAction,
  });

  final AppMessageType type;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tokens =
        theme.extension<AppSurfaceTokens>() ??
        (isDark ? AppSurfaceTokens.dark : AppSurfaceTokens.light);
    final (icon, accent) = AppMessageService._visualsFor(type, isDark);

    return Semantics(
      liveRegion: true,
      label: '$title: $message',
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: RepaintBoundary(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: AppRadius.lgBorder,
                boxShadow: AppShadows.of(context).lg,
              ),
              child: ClipRRect(
                borderRadius: AppRadius.lgBorder,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: AppGlassQuality.resolve(context).chromeBlurSigma,
                    sigmaY: AppGlassQuality.resolve(context).chromeBlurSigma,
                  ),
                  enabled: AppGlassQuality.resolve(context).enableBackdropBlur,
                  child: Material(
                    color: Colors.transparent,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: tokens.dialogGlassFill,
                        borderRadius: AppRadius.lgBorder,
                        border: Border.all(
                          color: accent.withValues(alpha: isDark ? 0.45 : 0.32),
                          width: 1.2,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm + 2,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: accent.withValues(
                                  alpha: isDark ? 0.20 : 0.13,
                                ),
                                borderRadius: AppRadius.mdBorder,
                                border: Border.all(
                                  color: accent.withValues(alpha: 0.30),
                                ),
                              ),
                              child: Center(
                                child: type == AppMessageType.loading
                                    ? AppSpinner.small(color: accent)
                                    : Icon(icon, size: 19, color: accent),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    message,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      height: 1.35,
                                    ),
                                  ),
                                  if (actionLabel != null &&
                                      onAction != null) ...[
                                    const SizedBox(height: 6),
                                    TextButton(
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        minimumSize: const Size(
                                          AppSizing.touchTargetMin,
                                          32,
                                        ),
                                        // Padded keeps a 48dp hit area while
                                        // the visible button stays small.
                                        tapTargetSize:
                                            MaterialTapTargetSize.padded,
                                      ),
                                      onPressed: onAction,
                                      child: Text(
                                        actionLabel!,
                                        style: theme.textTheme.labelMedium
                                            ?.copyWith(
                                              color: accent,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (type != AppMessageType.loading)
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 28,
                                  minHeight: 28,
                                ),
                                icon: Icon(
                                  AppIcons.close,
                                  size: 16,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                tooltip: MaterialLocalizations.of(context)
                                    .closeButtonTooltip,
                                onPressed: onClose,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
