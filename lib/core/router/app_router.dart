import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/localization/locale_cubit.dart';
import 'package:business_manager/core/localization/locale_state.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

GoRouter createAppRouter(AppConfig config) {
  return GoRouter(
    initialLocation: RoutePaths.foundation,
    routes: [
      GoRoute(
        path: RoutePaths.foundation,
        builder: (context, state) => FoundationStatusPage(config: config),
      ),
    ],
  );
}

/// Minimal Milestone 1 verification screen confirming `material_ui: ^1.11.1`,
/// active flavor isolation, and live EN/GU localization + Noto Sans Gujarati.
/// Business screens will replace this route in Milestone 2+.
final class FoundationStatusPage extends StatelessWidget {
  const FoundationStatusPage({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final appBarTitle = config.isDev ? l10n.appTitleDev : l10n.appTitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              l10n.foundationTitle,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.foundationSubtitle,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.environmentSectionTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _KeyValueRow(
                      label: l10n.environmentFlavorLabel,
                      value: config.isDev
                          ? l10n.environmentFlavorDev
                          : l10n.environmentFlavorProd,
                    ),
                    const SizedBox(height: 4),
                    _KeyValueRow(
                      label: l10n.environmentDatabaseLabel,
                      value: config.databaseName,
                    ),
                    const SizedBox(height: 4),
                    _KeyValueRow(
                      label: l10n.environmentLoggingLabel,
                      value: config.enableDebugLogs
                          ? l10n.statusEnabled
                          : l10n.statusDisabled,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: BlocBuilder<LocaleCubit, LocaleState>(
                  builder: (context, localeState) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.languageSectionTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<AppLocalePreference>(
                          segments: [
                            ButtonSegment<AppLocalePreference>(
                              value: AppLocalePreference.system,
                              label: Text(l10n.languageSystemDefault),
                            ),
                            ButtonSegment<AppLocalePreference>(
                              value: AppLocalePreference.en,
                              label: Text(l10n.languageEnglish),
                            ),
                            ButtonSegment<AppLocalePreference>(
                              value: AppLocalePreference.gu,
                              label: Text(l10n.languageGujarati),
                            ),
                          ],
                          selected: {localeState.preference},
                          onSelectionChanged: (selection) {
                            context
                                .read<LocaleCubit>()
                                .setPreference(selection.first);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: textTheme.bodyMedium),
        Flexible(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
