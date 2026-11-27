import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/guidance/domain/catalog/guide_catalog.dart';
import 'package:business_manager/features/guidance/domain/entities/guide_entities.dart';
import 'package:business_manager/features/guidance/presentation/bloc/guide_cubit.dart';
import 'package:business_manager/features/guidance/presentation/bloc/guide_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Quick Guide action sheet opened from the top-bar Guide (`?`) button on any
/// screen across mobile, tablet, and desktop.
abstract final class GuideQuickMenuSheet {
  static Future<void> show(BuildContext context) {
    return AppBottomSheet.show<void>(
      context,
      title: context.l10n.guideTitle,
      builder: (_) => const _GuideQuickMenuBody(),
    );
  }
}

final class _GuideQuickMenuBody extends StatelessWidget {
  const _GuideQuickMenuBody();

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
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    final colorScheme = Theme.of(context).colorScheme;
    final cubit = context.read<GuideCubit?>();
    if (cubit == null) return const SizedBox.shrink();

    return BlocBuilder<GuideCubit, GuideState>(
      builder: (context, state) {
        final currentScreenId =
            GuideScreenId.fromLocation(state.currentLocation) ??
            GuideScreenId.home;
        final totalChapters = GuideCatalog.chapters.length;
        final completed = state.completedChaptersCount;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Explain Buttons on This Screen
            _MenuActionCard(
              icon: AppIcons.spotlight,
              iconBg: colorScheme.primaryContainer,
              iconColor: colorScheme.onPrimaryContainer,
              title: l10n.guideTourThisScreen,
              subtitle: l10n.guideFirstVisitHint,
              onTap: () {
                Navigator.of(context).pop();
                cubit.startScreenTour(currentScreenId, localeCode: localeCode);
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // 2. Start / Resume End-to-End Training
            _MenuActionCard(
              icon: AppIcons.training,
              iconBg: colorScheme.secondaryContainer,
              iconColor: colorScheme.onSecondaryContainer,
              title: completed > 0 && completed < totalChapters
                  ? l10n.guideResumeTraining
                  : l10n.guideStartFullTraining,
              subtitle: l10n.guideProgressSummary(completed, totalChapters),
              onTap: () {
                Navigator.of(context).pop();
                cubit.startEndToEndJourney(
                  fromChapterIndex: completed > 0 && completed < totalChapters
                      ? state.progress.lastChapterIndex
                      : 0,
                  localeCode: localeCode,
                );
              },
            ),
            const SizedBox(height: AppSpacing.sm),

            // 3. Complete Bilingual User Guide Hub
            _MenuActionCard(
              icon: AppIcons.guide,
              iconBg: colorScheme.tertiaryContainer,
              iconColor: colorScheme.onTertiaryContainer,
              title: l10n.guideOpenUserGuide,
              subtitle: l10n.settingsHelpSubtitle,
              onTap: () {
                Navigator.of(context).pop();
                context.push(RoutePaths.settingsHelp);
              },
            ),
            const SizedBox(height: AppSpacing.md),

            // 4. Quick Voice Controls
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                AppChip.filter(
                  icon: state.progress.voiceEnabled
                      ? AppIcons.voiceOn
                      : AppIcons.voiceOff,
                  label: state.progress.voiceEnabled
                      ? l10n.guideVoiceOn
                      : l10n.guideVoiceOff,
                  selected: state.progress.voiceEnabled,
                  onSelected: (_) =>
                      cubit.toggleVoice(currentLocaleCode: localeCode),
                ),
                AppChip.action(
                  icon: AppIcons.speed,
                  label: _speedLabel(context, state.progress.speechRate),
                  onPressed: () =>
                      cubit.cycleSpeechRate(currentLocaleCode: localeCode),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        );
      },
    );
  }
}

final class _MenuActionCard extends StatelessWidget {
  const _MenuActionCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: AppRadius.mdBorder,
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  variant: AppTextVariant.bodyLarge,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: AppSpacing.xxs),
                AppText(
                  subtitle,
                  variant: AppTextVariant.bodySmall,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          Icon(AppIcons.chevronRight, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
