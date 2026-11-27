import 'dart:async';
import 'dart:math' as math;

import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/guidance/domain/catalog/guide_catalog.dart';
import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';
import 'package:business_manager/features/guidance/presentation/bloc/guide_cubit.dart';
import 'package:business_manager/features/guidance/presentation/bloc/guide_state.dart';
import 'package:business_manager/features/guidance/presentation/registry/guide_target_registry.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Custom native Flutter spotlight & button-upper callout overlay.
///
/// Draws a dimmed scrim with a soft glowing cutout over the active
/// [GuideTarget], positions the action explanation card **above the button**
/// whenever vertical space allows (flipping below if near the top edge, or
/// centering cleanly if the target isn't currently mounted), and integrates
/// inline bilingual voice narration controls.
final class GuideSpotlightOverlay extends StatefulWidget {
  const GuideSpotlightOverlay({super.key, required this.state});

  final GuideState state;

  @override
  State<GuideSpotlightOverlay> createState() => _GuideSpotlightOverlayState();
}

final class _GuideSpotlightOverlayState extends State<GuideSpotlightOverlay>
    with SingleTickerProviderStateMixin {
  Rect? _targetRect;
  int _measureGeneration = 0;
  Timer? _resolveTimer;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _scheduleTargetResolution();
  }

  @override
  void didUpdateWidget(covariant GuideSpotlightOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.currentStep?.id != widget.state.currentStep?.id ||
        oldWidget.state.currentLocation != widget.state.currentLocation ||
        oldWidget.state.showSpotlightOverlay !=
            widget.state.showSpotlightOverlay) {
      _scheduleTargetResolution();
    }
  }

  @override
  void dispose() {
    _resolveTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _scheduleTargetResolution() {
    _resolveTimer?.cancel();
    final gen = ++_measureGeneration;
    final step = widget.state.currentStep;
    final targetId = step?.targetId;
    if (targetId == null) {
      if (mounted) setState(() => _targetRect = null);
      return;
    }

    _attemptResolve(targetId: targetId, generation: gen, attempt: 0);
  }

  void _attemptResolve({
    required String targetId,
    required int generation,
    required int attempt,
  }) {
    _resolveTimer?.cancel();
    _resolveTimer = Timer(
      Duration(milliseconds: attempt == 0 ? 40 : 80),
      () async {
        if (!mounted || generation != _measureGeneration) return;
        final ctx = GuideTargetRegistry.instance.contextFor(targetId);
        if (ctx != null) {
          await GuideTargetRegistry.instance.scrollIntoView(targetId);
          if (!mounted || generation != _measureGeneration) return;
          final rect = GuideTargetRegistry.instance.rectFor(targetId);
          if (rect != null && rect.width > 0 && rect.height > 0) {
            setState(() => _targetRect = rect);
            return;
          }
        }
        if (attempt + 1 < 8) {
          _attemptResolve(
            targetId: targetId,
            generation: generation,
            attempt: attempt + 1,
          );
        } else if (mounted && generation == _measureGeneration) {
          setState(() => _targetRect = null);
        }
      },
    );
  }

  String _speedLabel(BuildContext context, GuideSpeechRate rate) {
    final l10n = context.l10n;
    return switch (rate) {
      GuideSpeechRate.slow => l10n.guideSpeedSlow,
      GuideSpeechRate.normal => l10n.guideSpeedNormal,
      GuideSpeechRate.fast => l10n.guideSpeedFast,
    };
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.state.currentStep;
    if (step == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final media = MediaQuery.of(context);
    final screenSize = media.size;
    final padding = media.padding;

    final inflatedTarget = _targetRect?.inflate(6);
    final chapter = GuideCatalog.chapterById(step.chapterId);

    // Determine whether the callout card fits ABOVE the highlighted button,
    // and strictly clamp maxCardHeight so the card NEVER clips off-screen.
    const double preferredCardHeight = 280;
    const double margin = 12;
    const double arrowSize = 10;

    final double safeTop = padding.top + margin;
    final double safeBottom = screenSize.height - padding.bottom - margin;

    bool placeAbove = true;
    double? topPosition;
    double? bottomPosition;
    double availableCardHeight = math.max(
      180.0,
      safeBottom - safeTop - arrowSize,
    );
    bool centeredFallback = inflatedTarget == null;

    if (inflatedTarget != null) {
      final spaceAbove = math.max(
        0.0,
        inflatedTarget.top - safeTop - arrowSize,
      );
      final spaceBelow = math.max(
        0.0,
        safeBottom - inflatedTarget.bottom - arrowSize,
      );
      if (spaceAbove >= preferredCardHeight || spaceAbove >= spaceBelow) {
        placeAbove = true;
        availableCardHeight = math.max(160.0, spaceAbove);
        bottomPosition = math.max(
          padding.bottom + margin,
          screenSize.height - inflatedTarget.top,
        );
      } else {
        placeAbove = false;
        availableCardHeight = math.max(160.0, spaceBelow);
        topPosition = math.max(safeTop, inflatedTarget.bottom);
      }
      // If neither side has comfortable room (e.g. giant target card), center.
      if (availableCardHeight < 180) {
        centeredFallback = true;
        availableCardHeight = math.max(180.0, safeBottom - safeTop);
      }
    }

    final maxCardWidth = math.min(420.0, screenSize.width - margin * 2);
    double cardLeft = (screenSize.width - maxCardWidth) / 2;
    if (inflatedTarget != null) {
      final idealLeft = inflatedTarget.center.dx - (maxCardWidth / 2);
      cardLeft = idealLeft.clamp(
        margin,
        math.max(margin, screenSize.width - maxCardWidth - margin),
      );
    }

    final double? arrowRelativeX = inflatedTarget == null
        ? null
        : (inflatedTarget.center.dx - cardLeft).clamp(
            24.0,
            maxCardWidth - 24.0,
          );

    final cubit = context.read<GuideCubit>();

    final calloutCard = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxCardWidth,
        maxHeight: availableCardHeight,
      ),
      child: Material(
        elevation: 14,
        shadowColor: Colors.black.withValues(alpha: 0.35),
        borderRadius: AppRadius.xlBorder,
        color: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppRadius.xlBorder,
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pinned top progress & action bar
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: AppRadius.fullBorder,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            AppIcons.spotlight,
                            size: 14,
                            color: colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            l10n.guideStepCounter(
                              widget.state.currentStepIndex + 1,
                              widget.state.steps.length,
                            ),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    if (chapter != null)
                      Expanded(
                        child: Text(
                          chapter.title(localeCode),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    if (step.isInteractiveAction)
                      // Flexible: on narrow phones the label ellipsizes
                      // instead of overflowing the header row.
                      Flexible(
                        child: AppButton(
                          label: l10n.guideMinimizeCoach,
                          icon: AppIcons.quick,
                          variant: AppButtonVariant.text,
                          onPressed: cubit.minimizeToCoachBar,
                        ),
                      ),
                    AppIconButton(
                      tooltip: l10n.guideActionSkip,
                      icon: AppIcons.close,
                      compact: true,
                      onPressed: cubit.skipTour,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),

                // Scrollable middle explanation + next-action + voice controls
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppText(
                          step.title(localeCode),
                          variant: AppTextVariant.bodyLarge,
                          fontWeight: FontWeight.w700,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        AppText(
                          step.actionDescription(localeCode),
                          variant: AppTextVariant.bodyMedium,
                          color: colorScheme.onSurface,
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Highlighted "What to do next" action strip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer.withValues(
                              alpha: 0.65,
                            ),
                            borderRadius: AppRadius.mdBorder,
                            border: Border.all(
                              color: colorScheme.secondary.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                AppIcons.nextStep,
                                size: 16,
                                color: colorScheme.onSecondaryContainer,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Expanded(
                                child: Text(
                                  step.nextActionHint(localeCode),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),

                        // Inline Voice Narration Controls
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            AppChip.action(
                              icon: widget.state.progress.voiceEnabled
                                  ? AppIcons.voiceOn
                                  : AppIcons.voiceOff,
                              label: widget.state.progress.voiceEnabled
                                  ? l10n.guideVoiceOn
                                  : l10n.guideVoiceOff,
                              dense: true,
                              onPressed: () => cubit.toggleVoice(
                                currentLocaleCode: localeCode,
                              ),
                            ),
                            AppChip.action(
                              icon: widget.state.isSpeaking
                                  ? AppIcons.stop
                                  : AppIcons.replay,
                              label: widget.state.isSpeaking
                                  ? l10n.guideVoiceStop
                                  : l10n.guideVoiceReplay,
                              dense: true,
                              onPressed: () {
                                if (widget.state.isSpeaking) {
                                  cubit.stopVoice();
                                } else {
                                  cubit.replayCurrentStepVoice(localeCode);
                                }
                              },
                            ),
                            AppChip.action(
                              icon: AppIcons.speed,
                              label: _speedLabel(
                                context,
                                widget.state.progress.speechRate,
                              ),
                              dense: true,
                              onPressed: () => cubit.cycleSpeechRate(
                                currentLocaleCode: localeCode,
                              ),
                            ),
                          ],
                        ),

                        if (widget.state.voicePackMissing &&
                            widget.state.progress.voiceEnabled) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.guideVoicePackMissingHint,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Pinned Navigation Footer (always visible and tappable)
                Row(
                  children: [
                    if (widget.state.canGoBack)
                      AppButton(
                        label: l10n.guideActionBack,
                        variant: AppButtonVariant.outlined,
                        onPressed: () =>
                            cubit.previousStep(localeCode: localeCode),
                      )
                    else
                      AppButton(
                        label: l10n.guideActionSkip,
                        variant: AppButtonVariant.text,
                        onPressed: cubit.skipTour,
                      ),
                    const Spacer(),
                    AppButton(
                      label: widget.state.isLastStep
                          ? l10n.guideActionFinish
                          : l10n.guideActionNext,
                      icon: widget.state.isLastStep
                          ? AppIcons.confirm
                          : AppIcons.nextStep,
                      onPressed: () => cubit.nextStep(localeCode: localeCode),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Positioned.fill(
      child: Stack(
        children: [
          // 1. Dimmed Cutout Scrim with animated glowing ring around target.
          // Using IgnorePointer on the cutout area would require complex hit
          // testing, so we intercept taps outside the target cutout.
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) => CustomPaint(
                painter: _SpotlightScrimPainter(
                  targetRect: inflatedTarget,
                  scrimColor: Colors.black.withValues(alpha: 0.64),
                  ringColor: colorScheme.primary,
                  pulseFactor: _pulseController.value,
                ),
              ),
            ),
          ),

          // Block accidental taps outside the target cutout, while allowing
          // tapping directly inside the cutout on interactive steps.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapUp: (details) {
                if (inflatedTarget != null &&
                    inflatedTarget.contains(details.globalPosition) &&
                    step.allowTargetTap) {
                  if (step.isInteractiveAction) {
                    cubit.minimizeToCoachBar();
                  } else {
                    cubit.nextStep(localeCode: localeCode);
                  }
                }
              },
              child: const SizedBox.expand(),
            ),
          ),

          // 2. Callout Card positioned ABOVE the button (or smart fallback)
          if (centeredFallback)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(margin),
                child: calloutCard,
              ),
            )
          else
            Positioned(
              left: cardLeft,
              top: placeAbove ? null : topPosition,
              bottom: placeAbove ? bottomPosition : null,
              width: maxCardWidth,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!placeAbove && arrowRelativeX != null)
                    Padding(
                      padding: EdgeInsets.only(left: arrowRelativeX - 9),
                      child: CustomPaint(
                        size: const Size(18, arrowSize),
                        painter: _CalloutArrowPainter(
                          color: colorScheme.surface,
                          borderColor: colorScheme.primary.withValues(
                            alpha: 0.45,
                          ),
                          pointingUp: true,
                        ),
                      ),
                    ),
                  calloutCard,
                  if (placeAbove && arrowRelativeX != null)
                    Padding(
                      padding: EdgeInsets.only(left: arrowRelativeX - 9),
                      child: CustomPaint(
                        size: const Size(18, arrowSize),
                        painter: _CalloutArrowPainter(
                          color: colorScheme.surface,
                          borderColor: colorScheme.primary.withValues(
                            alpha: 0.45,
                          ),
                          pointingUp: false,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

final class _SpotlightScrimPainter extends CustomPainter {
  const _SpotlightScrimPainter({
    required this.targetRect,
    required this.scrimColor,
    required this.ringColor,
    required this.pulseFactor,
  });

  final Rect? targetRect;
  final Color scrimColor;
  final Color ringColor;
  final double pulseFactor;

  @override
  void paint(Canvas canvas, Size size) {
    final fullPath = Path()..addRect(Offset.zero & size);
    if (targetRect == null) {
      canvas.drawPath(fullPath, Paint()..color = scrimColor);
      return;
    }

    final rrect = RRect.fromRectAndRadius(
      targetRect!,
      const Radius.circular(14),
    );
    final cutoutPath = Path()..addRRect(rrect);
    final combined = Path.combine(
      PathOperation.difference,
      fullPath,
      cutoutPath,
    );
    canvas.drawPath(combined, Paint()..color = scrimColor);

    // Outer pulsing halo around the spotlighted button.
    final haloPaint = Paint()
      ..color = ringColor.withValues(alpha: 0.25 + (pulseFactor * 0.25))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0 + (pulseFactor * 2.5);
    canvas.drawRRect(rrect.inflate(2 + pulseFactor * 3), haloPaint);

    final borderPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(rrect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SpotlightScrimPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect ||
        oldDelegate.scrimColor != scrimColor ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.pulseFactor != pulseFactor;
  }
}

final class _CalloutArrowPainter extends CustomPainter {
  const _CalloutArrowPainter({
    required this.color,
    required this.borderColor,
    required this.pointingUp,
  });

  final Color color;
  final Color borderColor;
  final bool pointingUp;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    if (pointingUp) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(size.width, 0)
        ..close();
    }
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
  }

  @override
  bool shouldRepaint(covariant _CalloutArrowPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.pointingUp != pointingUp;
  }
}
