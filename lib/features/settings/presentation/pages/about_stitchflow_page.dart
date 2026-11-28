import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_identity.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// About StitchFlow screen showing brand identity, version/build, active flavor,
/// offline local data privacy guarantee, and open-source licenses.
final class AboutStitchFlowPage extends StatelessWidget {
  const AboutStitchFlowPage({super.key, required this.config});

  final AppConfig config;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: l10n.settingsAboutTitle,
      contentWidth: AppContentWidth.narrow,
      body: ListView(
        children: [
          AppCard(
            gradient: context.themePresetPalette.heroGradientFor(
              Theme.of(context).brightness,
            ),
            borderRadius: AppRadius.xlBorder,
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.onHero.withValues(alpha: 0.14),
                    borderRadius: AppRadius.lgBorder,
                    border: Border.all(
                      color: AppColors.onHero.withValues(alpha: 0.24),
                    ),
                  ),
                  child: Image.asset(
                    AppIdentity.symbolPngAsset,
                    width: 64,
                    height: 64,
                    cacheWidth: 192,
                    cacheHeight: 192,
                    errorBuilder: (_, _, _) => const Icon(
                      AppIcons.brand,
                      color: AppColors.onHero,
                      size: 48,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  config.isDev ? l10n.appTitleDev : l10n.appTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.onHero,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.appTagline,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onHero.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(l10n.aboutDescriptionBody),
                const SizedBox(height: AppSpacing.md),
                const AppDivider(),
                const SizedBox(height: AppSpacing.sm),
                _MetaRow(
                  label: l10n.aboutVersionLabel,
                  value:
                      '${AppIdentity.appVersion} (${l10n.aboutBuildLabel} ${AppIdentity.appBuildNumber})',
                ),
                const SizedBox(height: AppSpacing.xs),
                _MetaRow(
                  label: l10n.environmentFlavorLabel,
                  value: config.isDev
                      ? l10n.environmentFlavorDev
                      : l10n.environmentFlavorProd,
                ),
                const SizedBox(height: AppSpacing.xs),
                _MetaRow(
                  label: l10n.environmentDatabaseLabel,
                  value: config.databaseName,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            color: colorScheme.surfaceContainer,
            elevated: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      AppIcons.security,
                      size: 20,
                      color: context.semanticColors.goodStock,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppText(
                        l10n.aboutPrivacyTitle,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                AppText(
                  l10n.aboutPrivacyBody,
                  variant: AppTextVariant.bodySmall,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l10n.aboutLicensesAction,
            icon: AppIcons.document,
            variant: AppButtonVariant.outlined,
            isExpanded: true,
            onPressed: () => showLicensePage(
              context: context,
              applicationName: config.isDev ? l10n.appTitleDev : l10n.appTitle,
              applicationVersion:
                  '${AppIdentity.appVersion}+${AppIdentity.appBuildNumber}',
              applicationIcon: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Image.asset(
                  AppIdentity.symbolPngAsset,
                  width: 48,
                  height: 48,
                  cacheWidth: 144,
                  cacheHeight: 144,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

final class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppText(
            label,
            variant: AppTextVariant.bodySmall,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: AppText(
            value,
            variant: AppTextVariant.numeric,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
