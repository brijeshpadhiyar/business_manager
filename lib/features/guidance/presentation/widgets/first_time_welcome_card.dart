import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/localization/locale_cubit.dart';
import 'package:business_manager/core/localization/locale_state.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';
import 'package:business_manager/features/guidance/presentation/bloc/guide_cubit.dart';
import 'package:business_manager/features/guidance/presentation/bloc/guide_state.dart';
import 'package:business_manager/features/reports/domain/entities/dashboard_report_entities.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Prominent non-blocking First-Time Welcome & Training Card shown at the top
/// of [DashboardPage] when opening a fresh workshop for the first time.
///
/// Lets the user choose English / ગુજરાતી, toggle Voice Guidance ON/OFF,
/// launch the complete 9-chapter guided training, run a quick Dashboard tour,
/// or skip for now.
final class FirstTimeWelcomeCard extends StatelessWidget {
  const FirstTimeWelcomeCard({super.key, required this.snapshot});

  final DashboardSnapshot snapshot;

  bool get _isFreshWorkshop =>
      snapshot.totalLots == 0 &&
      snapshot.activeProcessesCount == 0 &&
      snapshot.activeWorkersCount == 0;

  @override
  Widget build(BuildContext context) {
    final guideCubit = context.read<GuideCubit?>();
    if (guideCubit == null || !_isFreshWorkshop) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<GuideCubit, GuideState>(
      builder: (context, guideState) {
        if (!guideState.initialized || guideState.progress.welcomeDismissed) {
          return const SizedBox.shrink();
        }

        final l10n = context.l10n;
        final localeCode = Localizations.localeOf(context).languageCode;
        final colorScheme = Theme.of(context).colorScheme;
        final localeCubit = context.read<LocaleCubit?>();

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            color: colorScheme.primaryContainer.withValues(alpha: 0.45),
            borderColor: colorScheme.primary.withValues(alpha: 0.5),
            elevated: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: AppRadius.mdBorder,
                      ),
                      child: Icon(
                        AppIcons.training,
                        color: colorScheme.onPrimary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            l10n.guideWelcomeTitle,
                            variant: AppTextVariant.bodyLarge,
                            fontWeight: FontWeight.w700,
                          ),
                          AppText(
                            l10n.guideWelcomeSubtitle,
                            variant: AppTextVariant.bodySmall,
                            color: colorScheme.onSurfaceVariant,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Quick Language & Voice Selection Strip
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (localeCubit != null) ...[
                      ChoiceChip(
                        avatar: const Icon(AppIcons.language, size: 15),
                        label: Text(l10n.languageEnglish),
                        visualDensity: VisualDensity.compact,
                        selected: localeCode != 'gu',
                        onSelected: (_) =>
                            localeCubit.setPreference(AppLocalePreference.en),
                      ),
                      ChoiceChip(
                        avatar: const Icon(AppIcons.language, size: 15),
                        label: Text(l10n.languageGujarati),
                        visualDensity: VisualDensity.compact,
                        selected: localeCode == 'gu',
                        onSelected: (_) =>
                            localeCubit.setPreference(AppLocalePreference.gu),
                      ),
                    ],
                    FilterChip(
                      avatar: Icon(
                        guideState.progress.voiceEnabled
                            ? AppIcons.voiceOn
                            : AppIcons.voiceOff,
                        size: 15,
                      ),
                      label: Text(
                        guideState.progress.voiceEnabled
                            ? l10n.guideVoiceOn
                            : l10n.guideVoiceOff,
                      ),
                      visualDensity: VisualDensity.compact,
                      selected: guideState.progress.voiceEnabled,
                      onSelected: (_) => guideCubit.toggleVoice(
                        currentLocaleCode: localeCode,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),

                // Action CTAs
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    AppButton(
                      label: l10n.guideStartFullTraining,
                      icon: AppIcons.getStarted,
                      onPressed: () => guideCubit.startEndToEndJourney(
                        fromChapterIndex: 0,
                        localeCode: localeCode,
                      ),
                    ),
                    AppButton(
                      label: l10n.guideTourThisScreen,
                      icon: AppIcons.spotlight,
                      variant: AppButtonVariant.outlined,
                      onPressed: () => guideCubit.startScreenTour(
                        GuideScreenId.home,
                        localeCode: localeCode,
                      ),
                    ),
                    AppButton(
                      label: l10n.guideSkipForNow,
                      variant: AppButtonVariant.text,
                      onPressed: guideCubit.dismissWelcome,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
