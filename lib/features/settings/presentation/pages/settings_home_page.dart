import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_identity.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/localization/locale_cubit.dart';
import 'package:business_manager/core/localization/locale_state.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/theme/theme_cubit.dart';
import 'package:business_manager/core/theme/theme_state.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Centralized Settings Hub organizing Appearance, Business Profile,
/// Stock & Labour Preferences, Backup & Data Safety, Help & Guidance,
/// and About StitchFlow in one clear, mobile-first screen.
final class SettingsHomePage extends StatelessWidget {
  const SettingsHomePage({
    super.key,
    required this.config,
    this.showAppBar = false,
  });

  final AppConfig config;
  final bool showAppBar;

  String _themeLabel(BuildContext context, AppThemePreference pref) {
    final l10n = context.l10n;
    return switch (pref) {
      AppThemePreference.system => l10n.themeSystem,
      AppThemePreference.light => l10n.themeLight,
      AppThemePreference.dark => l10n.themeDark,
    };
  }

  String _localeLabel(BuildContext context, AppLocalePreference pref) {
    final l10n = context.l10n;
    return switch (pref) {
      AppLocalePreference.system => l10n.languageSystemDefault,
      AppLocalePreference.en => l10n.languageEnglish,
      AppLocalePreference.gu => l10n.languageGujarati,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    final content = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppSizing.narrowContentWidth,
        ),
        child: ListView(
          padding: AppSpacing.screenAll,
          children: [
            if (!showAppBar) ...[
              AppHeading(
                l10n.settingsHeading,
                level: AppHeadingLevel.h2,
                subtitle: l10n.settingsSubtitle,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Section 1: App & Workshop Setup
            AppMotionEntrance(
              index: 0,
              slideOffsetY: 0,
              child: _SettingsSectionCard(
              children: [
                BlocBuilder<ThemeCubit, ThemeState>(
                  builder: (context, themeState) =>
                      BlocBuilder<LocaleCubit, LocaleState>(
                        builder: (context, localeState) => _SettingsTile(
                          icon: Icons.palette_outlined,
                          iconBg: colorScheme.secondaryContainer,
                          iconColor: colorScheme.onSecondaryContainer,
                          title: l10n.settingsAppearanceTitle,
                          subtitle: l10n.settingsAppearanceSubtitle,
                          badgeText:
                              '${_themeLabel(context, themeState.preference)} • ${_localeLabel(context, localeState.preference)}',
                          onTap: () =>
                              context.push(RoutePaths.settingsAppearance),
                        ),
                      ),
                ),
                const Divider(indent: 64),
                _SettingsTile(
                  icon: Icons.storefront_outlined,
                  iconBg: colorScheme.primaryContainer,
                  iconColor: colorScheme.onPrimaryContainer,
                  title: l10n.settingsBusinessTitle,
                  subtitle: l10n.settingsBusinessSubtitle,
                  onTap: () => context.push(RoutePaths.settingsBusinessProfile),
                ),
                const Divider(indent: 64),
                _SettingsTile(
                  icon: Icons.tune_rounded,
                  iconBg: context.semanticColors.pendingContainer,
                  iconColor: context.semanticColors.pending,
                  title: l10n.settingsStockLabourTitle,
                  subtitle: l10n.settingsStockLabourSubtitle,
                  onTap: () => context.push(RoutePaths.settingsStockLabour),
                ),
                const Divider(indent: 64),
                _SettingsTile(
                  icon: Icons.style_outlined,
                  iconBg: colorScheme.secondaryContainer,
                  iconColor: colorScheme.onSecondaryContainer,
                  title: l10n.navDesignsColours,
                  subtitle: l10n.designsColoursSubtitle,
                  onTap: () => context.push(RoutePaths.designsColours),
                ),
              ],
            ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Section 2: Security, Data Safety & Guidance
            AppMotionEntrance(
              index: 1,
              child: _SettingsSectionCard(
              children: [
                BlocBuilder<AppLockCubit, AppLockState>(
                  builder: (context, lockState) => _SettingsTile(
                    icon: lockState.isPinEnabled
                        ? Icons.verified_user_outlined
                        : Icons.lock_outline_rounded,
                    iconBg: lockState.isPinEnabled
                        ? context.semanticColors.goodStockContainer
                        : colorScheme.surfaceContainerHighest,
                    iconColor: lockState.isPinEnabled
                        ? context.semanticColors.goodStock
                        : colorScheme.onSurfaceVariant,
                    title: l10n.settingsSecurityTitle,
                    subtitle: l10n.settingsSecuritySubtitle,
                    badgeText: lockState.isPinEnabled
                        ? l10n.securityBadgeEnabled
                        : l10n.securityBadgeOff,
                    onTap: () => context.push(RoutePaths.settingsSecurity),
                  ),
                ),
                const Divider(indent: 64),
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  iconBg: context.semanticColors.pendingContainer,
                  iconColor: context.semanticColors.pending,
                  title: l10n.settingsNotificationsTitle,
                  subtitle: l10n.settingsNotificationsSubtitle,
                  onTap: () => context.push(RoutePaths.settingsNotifications),
                ),
                const Divider(indent: 64),
                _SettingsTile(
                  icon: Icons.backup_outlined,
                  iconBg: context.semanticColors.goodStockContainer,
                  iconColor: context.semanticColors.goodStock,
                  title: l10n.settingsBackupTitle,
                  subtitle: l10n.settingsBackupSubtitle,
                  onTap: () => context.push(RoutePaths.settingsBackup),
                ),
                const Divider(indent: 64),
                _SettingsTile(
                  icon: Icons.menu_book_outlined,
                  iconBg: context.semanticColors.advanceCreditContainer,
                  iconColor: context.semanticColors.advanceCredit,
                  title: l10n.settingsHelpTitle,
                  subtitle: l10n.settingsHelpSubtitle,
                  onTap: () => context.push(RoutePaths.settingsHelp),
                ),
              ],
            ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Section 3: About & Diagnostics
            AppMotionEntrance(
              index: 2,
              child: _SettingsSectionCard(
              children: [
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  iconBg: colorScheme.surfaceContainerHighest,
                  iconColor: colorScheme.onSurfaceVariant,
                  title: l10n.settingsAboutTitle,
                  subtitle: l10n.settingsAboutSubtitle,
                  badgeText:
                      'v${AppIdentity.appVersion} (${config.isDev ? l10n.environmentFlavorDev : l10n.environmentFlavorProd})',
                  onTap: () => context.push(RoutePaths.settingsAbout),
                ),
                if (config.isDev) ...[
                  const Divider(indent: 64),
                  _SettingsTile(
                    icon: Icons.design_services_outlined,
                    iconBg: colorScheme.tertiaryContainer,
                    iconColor: colorScheme.onTertiaryContainer,
                    title: l10n.navDesignShowcase,
                    subtitle: l10n.foundationSubtitle,
                    onTap: () => context.push(RoutePaths.showcase),
                  ),
                ],
              ],
            ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );

    if (showAppBar) {
      return AppScaffold(
        title: l10n.settingsHeading,
        padding: EdgeInsets.zero,
        constrainMaxWidth: false,
        body: content,
      );
    }
    return content;
  }
}

final class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

final class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.badgeText,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badgeText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.lgBorder,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: AppRadius.mdBorder,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    title,
                    variant: AppTextVariant.bodyLarge,
                    fontWeight: FontWeight.w600,
                  ),
                  const SizedBox(height: 2),
                  AppText(
                    subtitle,
                    variant: AppTextVariant.bodySmall,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  if (badgeText != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    AppStatusBadge(
                      label: badgeText!,
                      tone: AppStatusTone.neutral,
                    ),
                  ],
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
      ),
    );
  }
}
