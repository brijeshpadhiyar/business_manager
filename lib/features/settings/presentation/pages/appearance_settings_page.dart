import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/localization/locale_cubit.dart';
import 'package:business_manager/core/localization/locale_state.dart';
import 'package:business_manager/core/theme/density_cubit.dart';
import 'package:business_manager/core/theme/theme_cubit.dart';
import 'package:business_manager/core/theme/theme_state.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Appearance settings: Theme mode (System / Light Glass / Dark Glass), App
/// language (System / English / Gujarati), and live glass readability preview.
final class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AppScaffold(
      title: l10n.settingsAppearanceTitle,
      contentWidth: AppContentWidth.narrow,
      body: ListView(
        children: [
          AppMotionEntrance(
            index: 0,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeading(l10n.themeSectionTitle, level: AppHeadingLevel.h3),
                  const SizedBox(height: AppSpacing.sm),
                  BlocBuilder<ThemeCubit, ThemeState>(
                    builder: (context, themeState) =>
                        AppRadio<AppThemePreference>(
                          groupValue: themeState.preference,
                          onChanged: (pref) {
                            if (pref != null) {
                              context.read<ThemeCubit>().setPreference(pref);
                            }
                          },
                          options: [
                            AppRadioOption(
                              value: AppThemePreference.system,
                              label: l10n.themeSystem,
                            ),
                            AppRadioOption(
                              value: AppThemePreference.light,
                              label: l10n.themeLight,
                            ),
                            AppRadioOption(
                              value: AppThemePreference.dark,
                              label: l10n.themeDark,
                            ),
                          ],
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppMotionEntrance(
            index: 1,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeading(
                    l10n.languageSectionTitle,
                    level: AppHeadingLevel.h3,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  BlocBuilder<LocaleCubit, LocaleState>(
                    builder: (context, localeState) =>
                        AppRadio<AppLocalePreference>(
                          groupValue: localeState.preference,
                          onChanged: (pref) {
                            if (pref != null) {
                              context.read<LocaleCubit>().setPreference(pref);
                            }
                          },
                          options: [
                            AppRadioOption(
                              value: AppLocalePreference.system,
                              label: l10n.languageSystemDefault,
                            ),
                            AppRadioOption(
                              value: AppLocalePreference.en,
                              label: l10n.languageEnglish,
                            ),
                            AppRadioOption(
                              value: AppLocalePreference.gu,
                              label: l10n.languageGujarati,
                            ),
                          ],
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (context.read<DensityCubit?>() != null) ...[
            AppMotionEntrance(
              index: 2,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppHeading(
                      l10n.densitySectionTitle,
                      level: AppHeadingLevel.h3,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    BlocBuilder<DensityCubit, DensityState>(
                      builder: (context, densityState) =>
                          AppRadio<UiDensityMode>(
                            groupValue: densityState.mode,
                            onChanged: (mode) {
                              if (mode != null) {
                                context.read<DensityCubit>().setMode(mode);
                              }
                            },
                            options: [
                              AppRadioOption(
                                value: UiDensityMode.comfortable,
                                label: l10n.densityComfortable,
                              ),
                              AppRadioOption(
                                value: UiDensityMode.compact,
                                label: l10n.densityCompact,
                              ),
                            ],
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppMotionEntrance(
            index: 3,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeading(
                    l10n.settingsAppearancePreviewTitle,
                    level: AppHeadingLevel.h3,
                    subtitle: l10n.settingsAppearancePreviewBody,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    children: [
                      AppStatusBadge(
                        label: '${l10n.statusGood}: 120 ${l10n.piecesUnit}',
                        tone: AppStatusTone.good,
                        icon: AppIcons.successOutline,
                      ),
                      AppStatusBadge(
                        label: '${l10n.statusPending}: 45 ${l10n.piecesUnit}',
                        tone: AppStatusTone.pending,
                        icon: AppIcons.pending,
                      ),
                      AppStatusBadge(
                        label: '${l10n.statusDamaged}: 3 ${l10n.piecesUnit}',
                        tone: AppStatusTone.damaged,
                        icon: AppIcons.warning,
                      ),
                      AppStatusBadge(
                        label:
                            '${l10n.accountingEarnedLabourLabel}: ${MoneyFormatter.formatPaise(125000)}',
                        tone: AppStatusTone.info,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
