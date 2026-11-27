import 'dart:math' as math;

import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_shadows.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

/// StitchFlow's single, branded animated loading indicator — "the thread".
///
/// A rotating arc that grows and shrinks like thread being pulled, drawn with
/// an Emerald → Indigo sweep and a Saffron knot at its leading end (the same
/// three colours as the logo). Every loading state in the app uses this
/// widget, directly or through [AppLoader] / [AppLoadingOverlay], so loading
/// looks identical on every screen.
///
/// Pass [color] to draw a single-colour thread on coloured surfaces (buttons,
/// hero banners, toasts). Under reduced motion the arc keeps a fixed length
/// and only rotates slowly.
final class AppSpinner extends StatefulWidget {
  const AppSpinner({
    super.key,
    this.size = 24,
    this.strokeWidth,
    this.color,
    this.semanticLabel,
  });

  /// Small spinner for buttons, text fields and list rows.
  const AppSpinner.small({super.key, this.color, this.semanticLabel})
    : size = 16,
      strokeWidth = 2;

  final double size;
  final double? strokeWidth;

  /// Single-colour mode. When null the brand gradient is used.
  final Color? color;
  final String? semanticLabel;

  @override
  State<AppSpinner> createState() => _AppSpinnerState();
}

class _AppSpinnerState extends State<AppSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = AppMotion.reduceMotion(context);
    final stroke = widget.strokeWidth ?? math.max(2.0, widget.size / 10);
    final label =
        widget.semanticLabel ??
        Localizations.of<AppLocalizations>(
          context,
          AppLocalizations,
        )?.msgTitleLoading ??
        'Loading';

    return Semantics(
      label: label,
      liveRegion: true,
      child: RepaintBoundary(
        child: SizedBox.square(
          dimension: widget.size,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => CustomPaint(
              painter: _ThreadPainter(
                t: _controller.value,
                stroke: stroke,
                single: widget.color,
                head: isDark ? AppColors.emerald400 : AppColors.emerald600,
                tail: isDark ? AppColors.indigo400 : AppColors.indigo600,
                knot: isDark ? AppColors.saffron400 : AppColors.saffron500,
                track:
                    (widget.color ??
                            (isDark
                                ? AppColors.indigo400
                                : AppColors.indigo600))
                        .withValues(alpha: 0.14),
                reduceMotion: reduceMotion,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

final class _ThreadPainter extends CustomPainter {
  _ThreadPainter({
    required this.t,
    required this.stroke,
    required this.single,
    required this.head,
    required this.tail,
    required this.knot,
    required this.track,
    required this.reduceMotion,
  });

  final double t;
  final double stroke;
  final Color? single;
  final Color head;
  final Color tail;
  final Color knot;
  final Color track;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2 + 0.5);
    final center = rect.center;
    final radius = arcRect.width / 2;

    // Faint full track so the control reads as a ring even at the short end.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = track,
    );

    // Arc length "breathes" between ~25° and ~270° like thread being pulled.
    final double sweep;
    final double rotation;
    if (reduceMotion) {
      sweep = math.pi * 1.1;
      rotation = t * 2 * math.pi * 0.5;
    } else {
      final pulse = Curves.easeInOutCubic.transform(
        t < 0.5 ? t * 2 : 2 - t * 2,
      );
      sweep = 0.45 + pulse * (math.pi * 1.5 - 0.45);
      rotation = t * 2 * math.pi * 1.5 + (t < 0.5 ? 0 : pulse * math.pi);
    }
    final start = -math.pi / 2 + rotation;

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    if (single != null) {
      arcPaint.color = single!;
    } else {
      arcPaint.shader = SweepGradient(
        startAngle: 0,
        endAngle: sweep,
        colors: [tail, head],
        transform: GradientRotation(start),
      ).createShader(arcRect);
    }
    canvas.drawArc(arcRect, start, sweep, false, arcPaint);

    // Saffron knot at the leading end of the thread.
    final end = start + sweep;
    final knotCenter = Offset(
      center.dx + radius * math.cos(end),
      center.dy + radius * math.sin(end),
    );
    canvas.drawCircle(
      knotCenter,
      stroke * 0.85,
      Paint()..color = single ?? knot,
    );
  }

  @override
  bool shouldRepaint(covariant _ThreadPainter old) =>
      old.t != t ||
      old.single != single ||
      old.head != head ||
      old.stroke != stroke ||
      old.reduceMotion != reduceMotion;
}

/// Standard loading state for a screen or section: the [AppSpinner] on a
/// raised card with an optional localized message and a gentle entrance.
/// Use [AppLoader.inline] for a bare spinner inside cards, tiles or rows.
final class AppLoader extends StatelessWidget {
  const AppLoader({super.key, this.message, this.size = 32}) : _inline = false;

  const AppLoader.inline({super.key, this.size = 20})
    : message = null,
      _inline = true;

  final String? message;
  final double size;
  final bool _inline;

  @override
  Widget build(BuildContext context) {
    if (_inline) {
      return Center(child: AppSpinner(size: size));
    }
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: AppSpacing.screenAll,
        child: AppMotionEntrance(
          slideOffsetY: 10,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: AppRadius.xlBorder,
              border: Border.all(color: colorScheme.outlineVariant),
              boxShadow: AppShadows.of(context).md,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSpinner(size: size, semanticLabel: message),
                  if (message != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      message!,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
