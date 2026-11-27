import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/guidance/presentation/bloc/guide_cubit.dart';
import 'package:business_manager/features/guidance/presentation/bloc/guide_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Compact floating "What To Do Next" Action Coach bar shown when the user
/// minimizes the full spotlight to interact freely with a screen or form
/// during End-to-End Training.
final class GuideActionCoachBanner extends StatelessWidget {
  const GuideActionCoachBanner({super.key, required this.state});

  final GuideState state;

  @override
  Widget build(BuildContext context) {
    final step = state.currentStep;
    if (step == null) return const SizedBox.shrink();

    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    final colorScheme = Theme.of(context).colorScheme;
    final cubit = context.read<GuideCubit>();
    final media = MediaQuery.of(context);
    final bottomInset =
        media.padding.bottom + (media.size.width < 600 ? 78 : 16);

    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      bottom: bottomInset,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Material(
            elevation: 10,
            borderRadius: AppRadius.xlBorder,
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        AppIcons.training,
                        size: 18,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: AppText(
                          '${l10n.guideStepCounter(state.currentStepIndex + 1, state.steps.length)} • ${step.title(localeCode)}',
                          variant: AppTextVariant.label,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onPrimaryContainer,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      AppIconButton(
                        tooltip: l10n.guideVoiceReplay,
                        icon: state.isSpeaking
                            ? AppIcons.stop
                            : AppIcons.voiceOn,
                        color: colorScheme.onPrimaryContainer,
                        compact: true,
                        onPressed: () {
                          if (state.isSpeaking) {
                            cubit.stopVoice();
                          } else {
                            cubit.replayCurrentStepVoice(localeCode);
                          }
                        },
                      ),
                      AppIconButton(
                        tooltip: l10n.guideActionSkip,
                        icon: AppIcons.close,
                        color: colorScheme.onPrimaryContainer,
                        compact: true,
                        onPressed: cubit.skipTour,
                      ),
                    ],
                  ),
                  AppText(
                    step.nextActionHint(localeCode),
                    variant: AppTextVariant.bodySmall,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AppButton(
                        label: l10n.guideExpandSpotlight,
                        icon: AppIcons.spotlight,
                        variant: AppButtonVariant.text,
                        onPressed: cubit.expandFromCoachBar,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      AppButton(
                        label: state.isLastStep
                            ? l10n.guideActionFinish
                            : l10n.guideActionNext,
                        icon: state.isLastStep
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
      ),
    );
  }
}
