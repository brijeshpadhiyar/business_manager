import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/settings/domain/help_topics.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Searchable bilingual Help & Guidance hub listing all 15 practical workshop
/// instructions without cluttering the main Settings screen.
final class HelpGuidancePage extends StatefulWidget {
  const HelpGuidancePage({super.key});

  @override
  State<HelpGuidancePage> createState() => _HelpGuidancePageState();
}

final class _HelpGuidancePageState extends State<HelpGuidancePage> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    final colorScheme = Theme.of(context).colorScheme;
    final filtered = StitchFlowHelpCatalog.topics
        .where((t) => t.matchesQuery(_query))
        .toList();

    return AppScaffold(
      title: l10n.settingsHelpTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppTextField(
            controller: _searchCtrl,
            label: l10n.helpSearchHint,
            prefixIcon: Icons.search_rounded,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: filtered.isEmpty
                ? AppEmptyState(
                    icon: Icons.help_outline_rounded,
                    title: l10n.helpNoResults,
                  )
                : ListView.separated(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final topic = filtered[index];
                      return AppCard(
                        onTap: () => context.push(
                          RoutePaths.settingsHelpTopic(topic.id),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: colorScheme.secondary.withValues(
                                  alpha: 0.14,
                                ),
                                borderRadius: AppRadius.mdBorder,
                              ),
                              child: Icon(
                                topic.icon,
                                size: 20,
                                color: colorScheme.secondary,
                              ),
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
                              Icons.chevron_right_rounded,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Detailed view for a single Help topic with "When to Use", numbered step
/// cards, and a practical garment workshop example in English or Gujarati.
final class HelpTopicDetailPage extends StatelessWidget {
  const HelpTopicDetailPage({super.key, required this.topicId});

  final String topicId;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final localeCode = Localizations.localeOf(context).languageCode;
    final colorScheme = Theme.of(context).colorScheme;
    final topic = StitchFlowHelpCatalog.byId(topicId);

    if (topic == null) {
      return AppScaffold(
        title: l10n.settingsHelpTitle,
        body: AppEmptyState(
          icon: Icons.help_outline_rounded,
          title: l10n.helpNoResults,
        ),
      );
    }

    final steps = topic.steps(localeCode);

    return AppScaffold(
      title: topic.title(localeCode),
      body: ListView(
        children: [
          AppCard(
            color: colorScheme.surfaceContainer,
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
                    topic.icon,
                    size: 22,
                    color: colorScheme.secondary,
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
          AppHeading(l10n.helpStepsLabel, level: AppHeadingLevel.h3),
          const SizedBox(height: AppSpacing.sm),
          for (int i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: AppCard(
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
                      child: Text(
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
          AppCard(
            color: colorScheme.secondary.withValues(alpha: 0.08),
            borderColor: colorScheme.secondary.withValues(alpha: 0.35),
            elevated: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
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
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
