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
import 'package:business_manager/features/settings/domain/help_topics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Complete bilingual Interactive Training & User Guide Hub.
///
/// Combines:
/// 1. **Interactive End-to-End Training Roadmap** (9 action-wise workshop
///    chapters with progress tracking, live button-upper spotlights, and
///    offline voice narration).
/// 2. **Searchable Complete User Guide** (all 19 practical garment workshop
///    topics with step-highlighted voice playback, live screen links, and
///    "What To Do Next" transitions).
final class HelpGuidancePage extends StatefulWidget {
  const HelpGuidancePage({super.key});

  @override
  State<HelpGuidancePage> createState() => _HelpGuidancePageState();
}

final class _HelpGuidancePageState extends State<HelpGuidancePage> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  int _selectedTab = 0;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  IconData _chapterIcon(String key) {
    return switch (key) {
      'dashboard' => AppIcons.dashboard,
      'business' => AppIcons.business,
      'process' => AppIcons.process,
      'workers' => AppIcons.workers,
      'lot' => AppIcons.lot,
      'stockIssue' => AppIcons.stockIssue,
      'receiveReturn' => AppIcons.receiveReturn,
      'accounting' => AppIcons.accounting,
      'reports' => AppIcons.reports,
      _ => AppIcons.training,
    };
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
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    final colorScheme = Theme.of(context).colorScheme;
    final guideCubit = context.read<GuideCubit?>();

    return AppScaffold(
      title: l10n.settingsHelpTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Always-accessible instant bilingual search across all 19 guides
          AppTextField(
            controller: _searchCtrl,
            label: l10n.helpSearchHint,
            prefixIcon: AppIcons.search,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).deleteButtonTooltip,
                    icon: const Icon(AppIcons.close, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_query.trim().isEmpty) ...[
            // Top Segmented Switcher: Interactive Training vs Complete Guide (19)
            SegmentedButton<int>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment<int>(
                  value: 0,
                  icon: const Icon(AppIcons.training, size: 18),
                  label: Text(
                    l10n.guideTrainingTabLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                ButtonSegment<int>(
                  value: 1,
                  icon: const Icon(AppIcons.guide, size: 18),
                  label: Text(
                    l10n.guideTopicsTabLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              selected: <int>{_selectedTab},
              onSelectionChanged: (selection) {
                if (selection.isNotEmpty) {
                  setState(() => _selectedTab = selection.first);
                }
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Expanded(
            child: _query.trim().isEmpty && _selectedTab == 0
                ? _buildInteractiveTrainingTab(
                    context,
                    localeCode: localeCode,
                    colorScheme: colorScheme,
                    guideCubit: guideCubit,
                  )
                : _buildTopicsList(
                    context,
                    localeCode: localeCode,
                    colorScheme: colorScheme,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveTrainingTab(
    BuildContext context, {
    required String localeCode,
    required ColorScheme colorScheme,
    required GuideCubit? guideCubit,
  }) {
    final l10n = context.l10n;
    const chapters = GuideCatalog.chapters;

    Widget buildContent(GuideState guideState) {
      final completed = guideState.completedChaptersCount;
      final total = chapters.length;
      final progressFraction = total == 0 ? 0.0 : completed / total;

      return ListView(
        children: [
          // 1. Overall Training Progress & Replay Card
          AppCard(
            color: colorScheme.primaryContainer.withValues(alpha: 0.42),
            borderColor: colorScheme.primary.withValues(alpha: 0.4),
            elevated: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: AppRadius.mdBorder,
                      ),
                      child: Icon(
                        AppIcons.training,
                        color: colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            l10n.guideWelcomeTitle,
                            variant: AppTextVariant.bodyLarge,
                            fontWeight: FontWeight.w700,
                          ),
                          const SizedBox(height: 2),
                          AppText(
                            l10n.guideProgressSummary(completed, total),
                            variant: AppTextVariant.bodySmall,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                LinearProgressIndicator(value: progressFraction),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppButton(
                      label: completed > 0 && completed < total
                          ? l10n.guideResumeTraining
                          : l10n.guideStartFullTraining,
                      icon: AppIcons.getStarted,
                      onPressed: guideCubit == null
                          ? null
                          : () {
                              guideCubit.startEndToEndJourney(
                                fromChapterIndex:
                                    completed > 0 && completed < total
                                    ? guideState.progress.lastChapterIndex
                                    : 0,
                                localeCode: localeCode,
                              );
                            },
                    ),
                    if (completed > 0)
                      AppButton(
                        label: l10n.guideRestartTraining,
                        icon: AppIcons.replay,
                        variant: AppButtonVariant.outlined,
                        onPressed: guideCubit == null
                            ? null
                            : () {
                                guideCubit.startEndToEndJourney(
                                  fromChapterIndex: 0,
                                  localeCode: localeCode,
                                );
                              },
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. Voice & Screen Tips Controls Card
          if (guideCubit != null) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      FilterChip(
                        avatar: Icon(
                          guideState.progress.voiceEnabled
                              ? AppIcons.voiceOn
                              : AppIcons.voiceOff,
                          size: 16,
                        ),
                        label: Text(
                          guideState.progress.voiceEnabled
                              ? l10n.guideVoiceOn
                              : l10n.guideVoiceOff,
                        ),
                        selected: guideState.progress.voiceEnabled,
                        onSelected: (_) => guideCubit.toggleVoice(
                          currentLocaleCode: localeCode,
                        ),
                      ),
                      ActionChip(
                        avatar: const Icon(AppIcons.speed, size: 16),
                        label: Text(
                          _speedLabel(context, guideState.progress.speechRate),
                        ),
                        onPressed: () => guideCubit.cycleSpeechRate(
                          currentLocaleCode: localeCode,
                        ),
                      ),
                      FilterChip(
                        avatar: const Icon(AppIcons.tip, size: 16),
                        label: Text(l10n.guideNewScreenHintsLabel),
                        selected: guideState.progress.showNewScreenHints,
                        onSelected: (_) => guideCubit.toggleNewScreenHints(),
                      ),
                    ],
                  ),
                  if (completed > 0 ||
                      guideState.progress.welcomeDismissed) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppButton(
                        label: l10n.guideResetProgressAction,
                        icon: AppIcons.restore,
                        variant: AppButtonVariant.text,
                        onPressed: () async {
                          await guideCubit.resetAllProgress();
                          if (context.mounted) {
                            AppFeedback.showInfo(
                              context,
                              l10n.guideResetProgressDone,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // 3. 9-Chapter End-to-End Workshop Roadmap
          for (var i = 0; i < chapters.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _TrainingChapterCard(
                chapter: chapters[i],
                icon: _chapterIcon(chapters[i].iconKey),
                localeCode: localeCode,
                isDone: guideState.progress.completedChapterIds.contains(
                  chapters[i].id,
                ),
                isSpeakingThisChapter:
                    guideState.activeTopicId == 'chapter_${chapters[i].id}' &&
                    guideState.isSpeaking,
                onShowMeLive: guideCubit == null
                    ? null
                    : () => guideCubit.startEndToEndJourney(
                        chapterId: chapters[i].id,
                        localeCode: localeCode,
                      ),
                onListen: guideCubit == null
                    ? null
                    : () {
                        final ch = chapters[i];
                        final topicKey = 'chapter_${ch.id}';
                        if (guideState.activeTopicId == topicKey &&
                            guideState.isSpeaking) {
                          guideCubit.stopVoice();
                        } else {
                          guideCubit.speakTopicSegments(
                            topicId: topicKey,
                            segments: <String>[
                              '${ch.title(localeCode)}. ${ch.summary(localeCode)}',
                              for (final s in ch.steps) s.speech(localeCode),
                            ],
                            localeCode: localeCode,
                          );
                        }
                      },
              ),
            ),
          const SizedBox(height: AppSpacing.xl),
        ],
      );
    }

    if (guideCubit == null) {
      return buildContent(const GuideState(initialized: true));
    }
    return BlocBuilder<GuideCubit, GuideState>(
      builder: (context, state) => buildContent(state),
    );
  }

  Widget _buildTopicsList(
    BuildContext context, {
    required String localeCode,
    required ColorScheme colorScheme,
  }) {
    final l10n = context.l10n;
    final filtered = StitchFlowHelpCatalog.topics
        .where((t) => t.matchesQuery(_query))
        .toList();

    if (filtered.isEmpty) {
      return AppEmptyState(icon: AppIcons.help, title: l10n.helpNoResults);
    }

    return ListView.separated(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final topic = filtered[index];
        return AppCard(
          onTap: () => context.push(RoutePaths.settingsHelpTopic(topic.id)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.14),
                  borderRadius: AppRadius.mdBorder,
                ),
                child: Icon(topic.icon, size: 20, color: colorScheme.secondary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      '${topic.order}. ${topic.title(localeCode)}',
                      variant: AppTextVariant.bodyLarge,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      topic.summary(localeCode),
                      variant: AppTextVariant.bodySmall,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(
                AppIcons.chevronRight,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        );
      },
    );
  }
}

final class _TrainingChapterCard extends StatelessWidget {
  const _TrainingChapterCard({
    required this.chapter,
    required this.icon,
    required this.localeCode,
    required this.isDone,
    required this.isSpeakingThisChapter,
    required this.onShowMeLive,
    required this.onListen,
  });

  final GuideChapter chapter;
  final IconData icon;
  final String localeCode;
  final bool isDone;
  final bool isSpeakingThisChapter;
  final VoidCallback? onShowMeLive;
  final VoidCallback? onListen;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      borderColor: isSpeakingThisChapter
          ? colorScheme.primary
          : (isDone ? colorScheme.secondary.withValues(alpha: 0.45) : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isDone
                      ? colorScheme.secondaryContainer
                      : colorScheme.primaryContainer,
                  borderRadius: AppRadius.mdBorder,
                ),
                child: Icon(
                  isDone ? AppIcons.success : icon,
                  size: 20,
                  color: isDone
                      ? colorScheme.onSecondaryContainer
                      : colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: AppText(
                            '${chapter.order}. ${chapter.title(localeCode)}',
                            variant: AppTextVariant.bodyLarge,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (isDone)
                          AppStatusBadge(
                            label: l10n.guideChapterCompleted,
                            tone: AppStatusTone.good,
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    AppText(
                      chapter.summary(localeCode),
                      variant: AppTextVariant.bodySmall,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Action-wise "What comes next" preview strip
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: AppRadius.smBorder,
            ),
            child: Row(
              children: [
                Icon(
                  AppIcons.nextStep,
                  size: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: AppText(
                    chapter.nextStepLabel(localeCode),
                    variant: AppTextVariant.label,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              AppButton(
                label: l10n.guideShowMeLive,
                icon: AppIcons.spotlight,
                onPressed: onShowMeLive,
              ),
              AppButton(
                label: isSpeakingThisChapter
                    ? l10n.guideVoiceStop
                    : l10n.guideVoiceListen,
                icon: isSpeakingThisChapter ? AppIcons.stop : AppIcons.voiceOn,
                variant: AppButtonVariant.outlined,
                onPressed: onListen,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Detailed view for a single Help topic with:
/// - Offline bilingual **Audio Guide Player** (highlights each step while speaking)
/// - **"Show Me on Screen"** live spotlight button
/// - "When to Use", numbered step cards, practical example, and
///   **"What To Do Next"** action transition to the next topic in the workflow.
final class HelpTopicDetailPage extends StatelessWidget {
  const HelpTopicDetailPage({super.key, required this.topicId});

  final String topicId;

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
    final topic = StitchFlowHelpCatalog.byId(topicId);

    if (topic == null) {
      return AppScaffold(
        title: l10n.settingsHelpTitle,
        body: AppEmptyState(icon: AppIcons.help, title: l10n.helpNoResults),
      );
    }

    final steps = topic.steps(localeCode);
    final actionLink = GuideCatalog.helpTopicLinks[topic.id];
    final nextTopic = actionLink?.nextTopicId == null
        ? null
        : StitchFlowHelpCatalog.byId(actionLink!.nextTopicId!);
    final guideCubit = context.read<GuideCubit?>();

    // Segment 0 = When to Use, 1..N = Steps, N+1 = Example
    final allAudioSegments = <String>[
      '${topic.title(localeCode)}. ${topic.whenToUse(localeCode)}',
      ...steps,
      topic.example(localeCode),
    ];

    Widget buildBody(GuideState guideState) {
      final isThisTopicPlaying =
          guideState.activeTopicId == topic.id &&
          guideState.activeTopicSegmentIndex != null;
      final activeSegment = isThisTopicPlaying
          ? guideState.activeTopicSegmentIndex
          : null;

      return ListView(
        children: [
          // Audio Guide + Live Show Me Action Bar
          if (guideCubit != null) ...[
            AppCard(
              color: colorScheme.primaryContainer.withValues(alpha: 0.35),
              borderColor: colorScheme.primary.withValues(alpha: 0.35),
              elevated: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AppButton(
                        label: isThisTopicPlaying
                            ? l10n.guideVoiceStop
                            : l10n.guideVoiceListen,
                        icon: isThisTopicPlaying
                            ? AppIcons.stop
                            : AppIcons.voiceOn,
                        onPressed: () {
                          if (isThisTopicPlaying) {
                            guideCubit.stopVoice();
                          } else {
                            guideCubit.speakTopicSegments(
                              topicId: topic.id,
                              segments: allAudioSegments,
                              localeCode: localeCode,
                            );
                          }
                        },
                      ),
                      if (actionLink != null)
                        AppButton(
                          label: l10n.guideShowMeOnScreen,
                          icon: AppIcons.spotlight,
                          variant: AppButtonVariant.outlined,
                          onPressed: () {
                            guideCubit.stopVoice();
                            guideCubit.startScreenTour(
                              actionLink.liveScreenId,
                              localeCode: localeCode,
                            );
                          },
                        ),
                      ActionChip(
                        avatar: const Icon(AppIcons.speed, size: 16),
                        label: Text(
                          _speedLabel(context, guideState.progress.speechRate),
                        ),
                        onPressed: () => guideCubit.cycleSpeechRate(
                          currentLocaleCode: localeCode,
                        ),
                      ),
                    ],
                  ),
                  if (guideState.voicePackMissing) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      l10n.guideVoicePackMissingHint,
                      variant: AppTextVariant.label,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // When to Use Card (Segment 0)
          AppCard(
            color: activeSegment == 0
                ? colorScheme.primaryContainer.withValues(alpha: 0.55)
                : colorScheme.surfaceContainer,
            borderColor: activeSegment == 0 ? colorScheme.primary : null,
            elevated: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.secondary.withValues(alpha: 0.16),
                    borderRadius: AppRadius.mdBorder,
                  ),
                  child: Icon(
                    activeSegment == 0 ? AppIcons.voiceOn : topic.icon,
                    size: 22,
                    color: activeSegment == 0
                        ? colorScheme.primary
                        : colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        l10n.helpWhenToUseLabel,
                        variant: AppTextVariant.label,
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppText(topic.whenToUse(localeCode)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Numbered Steps (Segments 1..steps.length)
          AppHeading(l10n.helpStepsLabel, level: AppHeadingLevel.h3),
          const SizedBox(height: AppSpacing.sm),
          for (int i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
                color: activeSegment == i + 1
                    ? colorScheme.primaryContainer.withValues(alpha: 0.45)
                    : null,
                borderColor: activeSegment == i + 1
                    ? colorScheme.primary
                    : null,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: AppRadius.fullBorder,
                      ),
                      child: activeSegment == i + 1
                          ? Icon(
                              AppIcons.voiceOn,
                              size: 16,
                              color: colorScheme.onPrimary,
                            )
                          : Text(
                              '${i + 1}',
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: AppText(steps[i])),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),

          // Practical Example (Segment steps.length + 1)
          AppCard(
            color: activeSegment == steps.length + 1
                ? colorScheme.primaryContainer.withValues(alpha: 0.45)
                : colorScheme.secondary.withValues(alpha: 0.08),
            borderColor: activeSegment == steps.length + 1
                ? colorScheme.primary
                : colorScheme.secondary.withValues(alpha: 0.35),
            elevated: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      activeSegment == steps.length + 1
                          ? AppIcons.voiceOn
                          : AppIcons.tip,
                      size: 18,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: AppText(
                        l10n.helpExampleLabel,
                        variant: AppTextVariant.label,
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                AppText(topic.example(localeCode)),
              ],
            ),
          ),

          // Action-wise "What To Do Next" Card linking to next guide topic
          if (nextTopic != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AppCard(
              borderColor: colorScheme.primary.withValues(alpha: 0.45),
              onTap: () {
                guideCubit?.stopVoice();
                context.pushReplacement(
                  RoutePaths.settingsHelpTopic(nextTopic.id),
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: AppRadius.mdBorder,
                    ),
                    child: Icon(
                      AppIcons.nextStep,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          l10n.guideNextTopicHeading,
                          variant: AppTextVariant.label,
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                        const SizedBox(height: 2),
                        AppText(
                          '${nextTopic.order}. ${nextTopic.title(localeCode)}',
                          variant: AppTextVariant.bodyLarge,
                          fontWeight: FontWeight.w700,
                        ),
                        AppText(
                          nextTopic.summary(localeCode),
                          variant: AppTextVariant.bodySmall,
                          color: colorScheme.onSurfaceVariant,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(AppIcons.chevronRight, color: colorScheme.primary),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      );
    }

    return AppScaffold(
      title: topic.title(localeCode),
      body: guideCubit == null
          ? buildBody(const GuideState(initialized: true))
          : BlocBuilder<GuideCubit, GuideState>(
              builder: (context, state) => buildBody(state),
            ),
    );
  }
}
