import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_identity.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/localization/locale_cubit.dart';
import 'package:business_manager/core/localization/locale_state.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/theme/theme_cubit.dart';
import 'package:business_manager/core/theme/theme_state.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

final class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.config,
    required this.onNavigateTab,
  });

  final AppConfig config;
  final ValueChanged<int> onNavigateTab;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSizing.maxContentWidth),
        child: ListView(
          padding: AppSpacing.screenAll,
          children: [
            AppCard(
              child: Row(
                children: [
                  Image.asset(
                    AppIdentity.symbolPngAsset,
                    width: 48,
                    height: 48,
                    errorBuilder: (_, _, _) => const Icon(Icons.auto_awesome),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppHeading(
                          config.isDev ? l10n.appTitleDev : l10n.appTitle,
                          level: AppHeadingLevel.h2,
                        ),
                        AppText(
                          l10n.appTagline,
                          variant: AppTextVariant.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppHeading(l10n.dashboardQuickActions, level: AppHeadingLevel.h3),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                AppButton(
                  label: l10n.navLots,
                  icon: Icons.inventory_2_outlined,
                  onPressed: () => onNavigateTab(1),
                ),
                AppButton(
                  label: l10n.navProcesses,
                  icon: Icons.precision_manufacturing_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => onNavigateTab(2),
                ),
                AppButton(
                  label: l10n.navWorkers,
                  icon: Icons.people_outline,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => onNavigateTab(3),
                ),
                AppButton(
                  label: l10n.navInventory,
                  icon: Icons.bar_chart_outlined,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => onNavigateTab(4),
                ),
                AppButton(
                  label: l10n.navBusinessProfile,
                  icon: Icons.storefront_outlined,
                  variant: AppButtonVariant.outlined,
                  onPressed: () => onNavigateTab(5),
                ),
                if (config.isDev)
                  AppButton(
                    label: l10n.navDesignShowcase,
                    icon: Icons.palette_outlined,
                    variant: AppButtonVariant.text,
                    onPressed: () => context.push(RoutePaths.showcase),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppHeading(l10n.dashboardPreferences, level: AppHeadingLevel.h3),
            const SizedBox(height: AppSpacing.sm),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    l10n.themeSectionTitle,
                    variant: AppTextVariant.label,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BlocBuilder<ThemeCubit, ThemeState>(
                    builder: (context, themeState) =>
                        SegmentedButton<AppThemePreference>(
                          segments: [
                            ButtonSegment(
                              value: AppThemePreference.system,
                              label: Text(l10n.themeSystem),
                            ),
                            ButtonSegment(
                              value: AppThemePreference.light,
                              label: Text(l10n.themeLight),
                            ),
                            ButtonSegment(
                              value: AppThemePreference.dark,
                              label: Text(l10n.themeDark),
                            ),
                          ],
                          selected: {themeState.preference},
                          onSelectionChanged: (s) =>
                              context.read<ThemeCubit>().setPreference(s.first),
                        ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppText(
                    l10n.languageSectionTitle,
                    variant: AppTextVariant.label,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BlocBuilder<LocaleCubit, LocaleState>(
                    builder: (context, localeState) =>
                        SegmentedButton<AppLocalePreference>(
                          segments: [
                            ButtonSegment(
                              value: AppLocalePreference.system,
                              label: Text(l10n.languageSystemDefault),
                            ),
                            ButtonSegment(
                              value: AppLocalePreference.en,
                              label: Text(l10n.languageEnglish),
                            ),
                            ButtonSegment(
                              value: AppLocalePreference.gu,
                              label: Text(l10n.languageGujarati),
                            ),
                          ],
                          selected: {localeState.preference},
                          onSelectionChanged: (s) => context
                              .read<LocaleCubit>()
                              .setPreference(s.first),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
