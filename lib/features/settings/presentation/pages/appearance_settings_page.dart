import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_theme_presets.dart';
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

/// Appearance settings: Theme mode (System / Light / Dark), Surface Style
/// (Modern Frosted Glass / Liquid Aurora Glass / Classic Solid), Color Theme
/// presets, App language (System / English / Gujarati), and live glass preview.
final class AppearanceSettingsPage extends StatelessWidget {
  const AppearanceSettingsPage({super.key});

  String _presetLabel(BuildContext context, AppThemePreset preset) {
    final l10n = context.l10n;
    return switch (preset) {
      AppThemePreset.indigoThread => l10n.appearancePresetIndigoThread,
      AppThemePreset.emeraldMint => l10n.appearancePresetEmeraldMint,
      AppThemePreset.midnightCyan => l10n.appearancePresetMidnightCyan,
      AppThemePreset.royalSaffron => l10n.appearancePresetRoyalSaffron,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final d = context.density;

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
                  const AppGap.sm(),
                  BlocBuilder<ThemeCubit, ThemeState>(
                    buildWhen: (prev, curr) => prev.preference != curr.preference,
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
          const AppGap.md(),
          AppMotionEntrance(
            index: 1,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeading(
                    l10n.appearanceSurfaceStyleTitle,
                    level: AppHeadingLevel.h3,
                  ),
                  const AppGap.sm(),
                  BlocBuilder<ThemeCubit, ThemeState>(
                    buildWhen: (prev, curr) =>
                        prev.surfaceStyle != curr.surfaceStyle,
                    builder: (context, themeState) =>
                        AppRadio<AppSurfaceStyle>(
                          groupValue: themeState.surfaceStyle,
                          onChanged: (style) {
                            if (style != null) {
                              context.read<ThemeCubit>().setSurfaceStyle(style);
                            }
                          },
                          options: [
                            AppRadioOption(
                              value: AppSurfaceStyle.modernGlass,
                              label: l10n.appearanceSurfaceModernGlass,
                              subtitle: l10n.appearanceSurfaceModernGlassDesc,
                            ),
                            AppRadioOption(
                              value: AppSurfaceStyle.liquidAurora,
                              label: l10n.appearanceSurfaceLiquidAurora,
                              subtitle: l10n.appearanceSurfaceLiquidAuroraDesc,
                            ),
                            AppRadioOption(
                              value: AppSurfaceStyle.classicSolid,
                              label: l10n.appearanceSurfaceClassicSolid,
                              subtitle: l10n.appearanceSurfaceClassicSolidDesc,
                            ),
                          ],
                        ),
                  ),
                ],
              ),
            ),
          ),
          const AppGap.md(),
          AppMotionEntrance(
            index: 2,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeading(
                    l10n.appearanceColorPresetTitle,
                    level: AppHeadingLevel.h3,
                  ),
                  const AppGap.sm(),
                  BlocBuilder<ThemeCubit, ThemeState>(
                    buildWhen: (prev, curr) => prev.preset != curr.preset,
                    builder: (context, themeState) => Wrap(
                      spacing: d.sm,
                      runSpacing: d.sm,
                      children: [
                        for (final preset in AppThemePreset.values)
                          AppChip(
                            label: _presetLabel(context, preset),
                            selected: themeState.preset == preset,
                            showCheckmark: false,
                            avatar: SizedBox.square(
                              dimension: d.iconSm,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppPresetPalette.of(preset).swatchColor,
                                  borderRadius: AppRadius.fullBorder,
                                  border: Border.all(
                                    color: AppColors.onHero,
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            onSelected: (_) =>
                                context.read<ThemeCubit>().setPreset(preset),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const AppGap.md(),
          AppMotionEntrance(
            index: 3,
            child: AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeading(
                    l10n.languageSectionTitle,
                    level: AppHeadingLevel.h3,
                  ),
                  const AppGap.sm(),
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
          const AppGap.md(),
          if (context.read<DensityCubit?>() != null) ...[
            AppMotionEntrance(
              index: 4,
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppHeading(
                      l10n.densitySectionTitle,
                      level: AppHeadingLevel.h3,
                    ),
                    const AppGap.sm(),
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
            const AppGap.md(),
          ],
          AppMotionEntrance(
            index: 5,
            child: AppCard(
              glassStyle: AppGlassStyle.full,
              blurSigma: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppHeading(
                    l10n.settingsAppearancePreviewTitle,
                    level: AppHeadingLevel.h3,
                    subtitle: l10n.settingsAppearancePreviewBody,
                  ),
                  const AppGap.md(),
                  AppResponsiveGrid(
                    compactColumns: 2,
                    mediumColumns: 3,
                    expandedColumns: 3,
                    compactModeExtraCompact: 1,
                    compactModeExtraMedium: 0,
                    compactModeExtraExpanded: 0,
                    children: [
                      AppMetricTile(
                        label: l10n.dashboardTotalLotsLabel,
                        value: 18,
                        icon: AppIcons.lot,
                        tone: AppStatusTone.neutral,
                      ),
                      AppMetricTile(
                        label: l10n.stockAvailableGoodLabel,
                        value: 120,
                        suffix: l10n.piecesUnit,
                        icon: AppIcons.successOutline,
                        tone: AppStatusTone.good,
                      ),
                      AppMetricTile(
                        label: l10n.accountingEarnedLabourLabel,
                        value: 125000,
                        isCurrencyPaise: true,
                        icon: AppIcons.work,
                        tone: AppStatusTone.info,
                      ),
                    ],
                  ),
                  const AppGap.sm(),
                  Wrap(
                    spacing: d.sm,
                    runSpacing: d.xs,
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
