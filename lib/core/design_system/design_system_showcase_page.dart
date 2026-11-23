import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/localization/locale_cubit.dart';
import 'package:business_manager/core/localization/locale_state.dart';
import 'package:business_manager/core/theme/theme_cubit.dart';
import 'package:business_manager/core/theme/theme_state.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Development-only Milestone 2 Design System Showcase route for inspecting
/// Material 3 tokens, Theme switching, EN/GU localization, ResponsiveNavigation,
/// and all 20 centralized common widgets. Contains zero business workflows.
final class DesignSystemShowcasePage extends StatefulWidget {
  const DesignSystemShowcasePage({super.key, required this.config});

  final AppConfig config;

  @override
  State<DesignSystemShowcasePage> createState() =>
      _DesignSystemShowcasePageState();
}

final class _DesignSystemShowcasePageState
    extends State<DesignSystemShowcasePage> {
  int _selectedTab = 0;
  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  String? _selectedOption;
  int _selectedDateUtc = IstDateTimeHelper.nowUtcMillis();
  bool _checkboxValue = true;
  bool _switchValue = true;
  String _radioValue = 'opt1';

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final appTitle = widget.config.isDev ? l10n.appTitleDev : l10n.appTitle;

    return ResponsiveNavigation(
      title: appTitle,
      selectedIndex: _selectedTab,
      onDestinationSelected: (index) => setState(() => _selectedTab = index),
      destinations: [
        ResponsiveNavDestination(
          label: l10n.navOverview,
          icon: Icons.dashboard_outlined,
          selectedIcon: Icons.dashboard,
        ),
        ResponsiveNavDestination(
          label: l10n.navInputs,
          icon: Icons.edit_note_outlined,
          selectedIcon: Icons.edit_note,
        ),
        ResponsiveNavDestination(
          label: l10n.navFeedback,
          icon: Icons.widgets_outlined,
          selectedIcon: Icons.widgets,
        ),
      ],
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizing.maxContentWidth,
          ),
          child: switch (_selectedTab) {
            0 => _buildOverviewTab(context),
            1 => _buildInputsTab(context),
            _ => _buildFeedbackTab(context),
          },
        ),
      ),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    final l10n = context.l10n;
    return ListView(
      padding: AppSpacing.screenAll,
      children: [
        AppHeading(
          l10n.foundationTitle,
          level: AppHeadingLevel.h1,
          subtitle: l10n.foundationSubtitle,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeading(l10n.themeSectionTitle, level: AppHeadingLevel.h3),
              const SizedBox(height: AppSpacing.sm),
              BlocBuilder<ThemeCubit, ThemeState>(
                builder: (context, themeState) {
                  return SegmentedButton<AppThemePreference>(
                    segments: [
                      ButtonSegment<AppThemePreference>(
                        value: AppThemePreference.system,
                        label: Text(l10n.themeSystem),
                      ),
                      ButtonSegment<AppThemePreference>(
                        value: AppThemePreference.light,
                        label: Text(l10n.themeLight),
                      ),
                      ButtonSegment<AppThemePreference>(
                        value: AppThemePreference.dark,
                        label: Text(l10n.themeDark),
                      ),
                    ],
                    selected: {themeState.preference},
                    onSelectionChanged: (selection) {
                      context
                          .read<ThemeCubit>()
                          .setPreference(selection.first);
                    },
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeading(l10n.languageSectionTitle, level: AppHeadingLevel.h3),
              const SizedBox(height: AppSpacing.sm),
              BlocBuilder<LocaleCubit, LocaleState>(
                builder: (context, localeState) {
                  return SegmentedButton<AppLocalePreference>(
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
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeading(
                l10n.environmentSectionTitle,
                level: AppHeadingLevel.h3,
              ),
              const SizedBox(height: AppSpacing.sm),
              _InfoRow(
                label: l10n.environmentFlavorLabel,
                value: widget.config.isDev
                    ? l10n.environmentFlavorDev
                    : l10n.environmentFlavorProd,
              ),
              const SizedBox(height: AppSpacing.xs),
              _InfoRow(
                label: l10n.environmentDatabaseLabel,
                value: widget.config.databaseName,
              ),
              const SizedBox(height: AppSpacing.xs),
              _InfoRow(
                label: l10n.environmentLoggingLabel,
                value: widget.config.enableDebugLogs
                    ? l10n.statusEnabled
                    : l10n.statusDisabled,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeading(
                l10n.showcaseLongTextHeading,
                level: AppHeadingLevel.h3,
              ),
              const SizedBox(height: AppSpacing.sm),
              AppText(l10n.showcaseLongTextSample),
              const SizedBox(height: AppSpacing.sm),
              AppText(
                MoneyFormatter.formatPaise(12500050),
                variant: AppTextVariant.numeric,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputsTab(BuildContext context) {
    final l10n = context.l10n;
    return Form(
      key: _formKey,
      child: ListView(
        padding: AppSpacing.screenAll,
        children: [
          AppHeading(l10n.showcaseInputsHeading, level: AppHeadingLevel.h2),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _textController,
                  label: l10n.showcaseSampleFieldLabel,
                  hint: l10n.showcaseSampleFieldHint,
                  prefixIcon: Icons.label_outline,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.validationRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                AppDropdown<String>(
                  label: l10n.showcaseDropdownLabel,
                  value: _selectedOption,
                  items: const ['opt1', 'opt2'],
                  itemLabelBuilder: (item) => item == 'opt1'
                      ? l10n.showcaseOptionOne
                      : l10n.showcaseOptionTwo,
                  onChanged: (value) => setState(() => _selectedOption = value),
                ),
                const SizedBox(height: AppSpacing.md),
                AppDatePicker(
                  label: l10n.showcaseDatePickerLabel,
                  selectedUtcMillis: _selectedDateUtc,
                  onDateSelectedUtcMillis: (utc) =>
                      setState(() => _selectedDateUtc = utc),
                ),
                const SizedBox(height: AppSpacing.sm),
                AppCheckbox(
                  label: l10n.showcaseCheckboxLabel,
                  value: _checkboxValue,
                  onChanged: (v) => setState(() => _checkboxValue = v ?? false),
                ),
                AppSwitch(
                  label: l10n.showcaseSwitchLabel,
                  value: _switchValue,
                  onChanged: (v) => setState(() => _switchValue = v),
                ),
                AppRadio<String>(
                  groupValue: _radioValue,
                  onChanged: (v) {
                    if (v != null) setState(() => _radioValue = v);
                  },
                  options: [
                    AppRadioOption(
                      value: 'opt1',
                      label: l10n.showcaseOptionOne,
                    ),
                    AppRadioOption(
                      value: 'opt2',
                      label: l10n.showcaseOptionTwo,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: l10n.showcaseValidateButton,
                  isExpanded: true,
                  icon: Icons.check_circle_outline,
                  onPressed: () => _formKey.currentState?.validate(),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppHeading(
                  l10n.showcaseButtonsHeading,
                  level: AppHeadingLevel.h3,
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppButton(
                      label: l10n.showcasePrimaryAction,
                      onPressed: () {},
                    ),
                    AppButton(
                      label: l10n.showcaseSecondaryAction,
                      variant: AppButtonVariant.secondary,
                      onPressed: () {},
                    ),
                    AppButton(
                      label: l10n.showcaseOutlinedAction,
                      variant: AppButtonVariant.outlined,
                      onPressed: () {},
                    ),
                    AppButton(
                      label: l10n.showcaseDestructiveAction,
                      variant: AppButtonVariant.destructive,
                      onPressed: () {},
                    ),
                    AppButton(
                      label: l10n.showcaseLoadingAction,
                      isLoading: true,
                      onPressed: () {},
                    ),
                    AppButton(
                      label: l10n.showcaseDisabledAction,
                      onPressed: null,
                    ),
                    AppIconButton(
                      icon: Icons.info_outline,
                      tooltip: l10n.showcaseOpenDialog,
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackTab(BuildContext context) {
    final l10n = context.l10n;
    final sampleRows = [
      (name: l10n.showcaseOptionOne, qty: 100, paise: 200000),
      (name: l10n.showcaseOptionTwo, qty: 80, paise: 240000),
    ];

    return ListView(
      padding: AppSpacing.screenAll,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppHeading(
                l10n.showcaseBadgesHeading,
                level: AppHeadingLevel.h3,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppStatusBadge(
                    label: l10n.statusGood,
                    tone: AppStatusTone.good,
                    icon: Icons.check_circle_outline,
                  ),
                  AppStatusBadge(
                    label: l10n.statusPending,
                    tone: AppStatusTone.pending,
                    icon: Icons.schedule,
                  ),
                  AppStatusBadge(
                    label: l10n.statusDamaged,
                    tone: AppStatusTone.damaged,
                    icon: Icons.warning_amber_outlined,
                  ),
                  AppStatusBadge(
                    label: l10n.statusAdvanceCredit,
                    tone: AppStatusTone.info,
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  AppButton(
                    label: l10n.showcaseOpenDialog,
                    variant: AppButtonVariant.outlined,
                    onPressed: () => AppDialog.showConfirmation(
                      context,
                      title: l10n.showcaseDialogTitle,
                      message: l10n.showcaseDialogMessage,
                      confirmLabel: l10n.actionConfirm,
                      cancelLabel: l10n.actionCancel,
                    ),
                  ),
                  AppButton(
                    label: l10n.showcaseOpenSheet,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => AppBottomSheet.show<void>(
                      context,
                      title: l10n.showcaseDialogTitle,
                      builder: (_) => AppText(l10n.showcaseDialogMessage),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppHeading(l10n.showcaseTableHeading, level: AppHeadingLevel.h3),
        const SizedBox(height: AppSpacing.sm),
        AppDataTable<({String name, int qty, int paise})>(
          columns: [
            AppDataColumn(label: l10n.showcaseColName),
            AppDataColumn(label: l10n.showcaseColQty, numeric: true),
            AppDataColumn(label: l10n.showcaseColAmount, numeric: true),
          ],
          items: sampleRows,
          cellsBuilder: (row) => [
            AppText(row.name),
            AppText('${row.qty}', variant: AppTextVariant.numeric),
            AppText(
              MoneyFormatter.formatPaise(row.paise),
              variant: AppTextVariant.numeric,
            ),
          ],
          mobileCardBuilder: (_, row) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(row.name, fontWeight: FontWeight.w600),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppText('${row.qty}', variant: AppTextVariant.numeric),
                  AppText(
                    MoneyFormatter.formatPaise(row.paise),
                    variant: AppTextVariant.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          child: Column(
            children: [
              AppLoader(message: l10n.showcaseLoadingMessage),
              const Divider(),
              AppEmptyState(
                icon: Icons.inbox_outlined,
                title: l10n.showcaseEmptyTitle,
                subtitle: l10n.showcaseEmptySubtitle,
              ),
              const Divider(),
              AppErrorView(
                title: l10n.showcaseErrorTitle,
                message: l10n.errorUnexpected,
                retryLabel: l10n.actionRetry,
                onRetry: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(label),
        Flexible(
          child: AppText(
            value,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
