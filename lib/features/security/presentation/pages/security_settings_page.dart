import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/design_system/app_typography.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/security/domain/entities/security_entities.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:business_manager/features/security/presentation/widgets/security_reauth_dialog.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Centralized Local App Lock & Security configuration screen (`/settings/security`).
final class SecuritySettingsPage extends StatefulWidget {
  const SecuritySettingsPage({super.key});

  @override
  State<SecuritySettingsPage> createState() => _SecuritySettingsPageState();
}

final class _SecuritySettingsPageState extends State<SecuritySettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AppLockCubit>().refreshBiometricAvailability();
  }

  String _timeoutLabel(BuildContext context, LockTimeoutOption opt) {
    final l10n = context.l10n;
    return switch (opt) {
      LockTimeoutOption.immediate => l10n.securityTimeoutImmediate,
      LockTimeoutOption.seconds30 => l10n.securityTimeout30s,
      LockTimeoutOption.minute1 => l10n.securityTimeout1m,
      LockTimeoutOption.minutes5 => l10n.securityTimeout5m,
      LockTimeoutOption.minutes15 => l10n.securityTimeout15m,
    };
  }

  String _biometricSubtitle(BuildContext context, BiometricAvailability avail) {
    final l10n = context.l10n;
    return switch (avail) {
      BiometricAvailability.available => l10n.securityEnableBiometricSubtitle,
      BiometricAvailability.notEnrolled =>
        l10n.securityBiometricNotEnrolledHint,
      BiometricAvailability.noHardware => l10n.securityBiometricNoHardwareHint,
      BiometricAvailability.unavailable =>
        l10n.securityBiometricUnavailableHint,
    };
  }

  Future<void> _handleChangePin(BuildContext context) async {
    final l10n = context.l10n;
    final ok = await SecurityReauthDialog.verify(
      context,
      title: l10n.securityVerifyCurrentPinTitle,
      subtitle: l10n.securityVerifyChangePinSubtitle,
      allowBiometric: false,
    );
    if (!ok || !context.mounted) return;
    await context.push(RoutePaths.settingsSecurityPinChange);
  }

  Future<void> _handleDisablePin(BuildContext context) async {
    final l10n = context.l10n;
    final ok = await SecurityReauthDialog.verify(
      context,
      title: l10n.securityVerifyCurrentPinTitle,
      subtitle: l10n.securityVerifyDisablePinSubtitle,
      allowBiometric: false,
    );
    if (!ok || !context.mounted) return;

    final confirmed = await AppDialog.showConfirmation(
      context,
      title: l10n.securityDisablePinConfirmTitle,
      message: l10n.securityDisablePinConfirmMessage,
      confirmLabel: l10n.securityDisablePinAction,
      cancelLabel: l10n.actionCancel,
      isDestructive: true,
    );
    if (confirmed != true || !context.mounted) return;

    await context.read<AppLockCubit>().disablePin();
    if (context.mounted) {
      AppFeedback.showInfo(context, l10n.securityPinDisabledSuccess);
    }
  }

  Future<void> _handleRegenerateRecoveryKey(BuildContext context) async {
    final l10n = context.l10n;
    final cubit = context.read<AppLockCubit>();
    final ok = await SecurityReauthDialog.verify(
      context,
      title: l10n.securityVerifyCurrentPinTitle,
      subtitle: l10n.securityVerifyRecoveryRegenSubtitle,
      allowBiometric: false,
    );
    if (!ok || !context.mounted) return;

    final newKey = await cubit.regenerateRecoveryKey();
    if (!context.mounted) return;

    await cubit.setSensitiveScreenActive(true);
    try {
      if (!context.mounted) return;
      await AppDialog.showCustom<void>(
        context,
        barrierDismissible: false,
        builder: (dialogCtx) => AlertDialog(
          title: Text(l10n.securityNewRecoveryKeyTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppText(
                l10n.securityRecoveryKeyWriteDownBody,
                variant: AppTextVariant.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(dialogCtx).colorScheme.primaryContainer,
                  borderRadius: AppRadius.mdBorder,
                ),
                child: SelectableText(
                  newKey,
                  textAlign: TextAlign.center,
                  style: AppTypography.tabular(
                    Theme.of(dialogCtx).textTheme.headlineSmall!.copyWith(
                      letterSpacing: 3,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(dialogCtx).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            AppButton(
              label: l10n.actionDone,
              onPressed: () => Navigator.of(dialogCtx).pop(),
            ),
          ],
        ),
      );
    } finally {
      await cubit.setSensitiveScreenActive(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppScaffold(
      title: l10n.settingsSecurityTitle,
      body: BlocBuilder<AppLockCubit, AppLockState>(
        builder: (context, state) {
          final settings = state.settings;
          final enabled = settings.pinEnabled;
          final bioAvailable =
              state.biometricAvailability == BiometricAvailability.available;

          return ListView(
            children: [
              // Status Hero Card
              AppCard(
                gradient: enabled
                    ? (isDark
                          ? AppColors.heroGradientDark
                          : AppColors.heroGradientLight)
                    : null,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: enabled
                            ? Colors.white.withValues(alpha: 0.16)
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: AppRadius.mdBorder,
                      ),
                      child: Icon(
                        enabled
                            ? Icons.verified_user_rounded
                            : Icons.lock_open_rounded,
                        color: enabled
                            ? Colors.white
                            : colorScheme.onSurfaceVariant,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            enabled
                                ? l10n.securityStatusProtected
                                : l10n.securityStatusOff,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: enabled ? Colors.white : null,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            enabled
                                ? l10n.securityStatusProtectedDesc(
                                    settings.pinLength,
                                    _timeoutLabel(context, settings.timeout),
                                  )
                                : l10n.securityStatusOffDesc,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: enabled
                                      ? Colors.white.withValues(alpha: 0.88)
                                      : colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              if (!enabled) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppHeading(
                        l10n.securitySetupPinTitle,
                        level: AppHeadingLevel.h3,
                        subtitle: l10n.securitySetupBenefitsBody,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: l10n.securityEnablePinAction,
                        icon: Icons.lock_outline_rounded,
                        isExpanded: true,
                        onPressed: () =>
                            context.push(RoutePaths.settingsSecurityPinSetup),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Lock Actions Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          AppButton(
                            label: l10n.securityLockNowAction,
                            icon: Icons.lock_rounded,
                            onPressed: () =>
                                context.read<AppLockCubit>().lockNow(),
                          ),
                          AppButton(
                            label: l10n.securityChangePinAction,
                            icon: Icons.pin_outlined,
                            variant: AppButtonVariant.secondary,
                            onPressed: () => _handleChangePin(context),
                          ),
                          AppButton(
                            label: l10n.securityRegenerateRecoveryKeyAction,
                            icon: Icons.vpn_key_outlined,
                            variant: AppButtonVariant.outlined,
                            onPressed: () =>
                                _handleRegenerateRecoveryKey(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Biometric & Privacy Controls
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppHeading(
                        l10n.securityUnlockOptionsTitle,
                        level: AppHeadingLevel.h3,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      AppSwitch(
                        label: l10n.securityEnableBiometricLabel,
                        subtitle: _biometricSubtitle(
                          context,
                          state.biometricAvailability,
                        ),
                        value: settings.biometricEnabled && bioAvailable,
                        onChanged: bioAvailable
                            ? (v) => context
                                  .read<AppLockCubit>()
                                  .setBiometricEnabled(v)
                            : null,
                      ),
                      const Divider(),
                      AppSwitch(
                        label: l10n.securityScreenshotProtectionLabel,
                        subtitle: l10n.securityScreenshotProtectionSubtitle,
                        value: settings.screenshotProtectionEnabled,
                        onChanged: (v) => context
                            .read<AppLockCubit>()
                            .setScreenshotProtectionEnabled(v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Auto-Lock Timeout Selector
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppHeading(
                        l10n.securityAutoLockTimeoutTitle,
                        level: AppHeadingLevel.h3,
                        subtitle: l10n.securityAutoLockTimeoutSubtitle,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          for (final opt in LockTimeoutOption.values)
                            ChoiceChip(
                              label: Text(_timeoutLabel(context, opt)),
                              selected: settings.timeout == opt,
                              onSelected: (_) =>
                                  context.read<AppLockCubit>().setTimeout(opt),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Disable PIN Card
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppHeading(
                        l10n.securityDisablePinAction,
                        level: AppHeadingLevel.h3,
                        subtitle: l10n.securityDisablePinDesc,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        label: l10n.securityDisablePinAction,
                        icon: Icons.lock_open_rounded,
                        variant: AppButtonVariant.destructive,
                        onPressed: () => _handleDisablePin(context),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.md),

              // Honest Offline Privacy Disclosure (No false SQLite encryption claims)
              AppCard(
                elevated: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      l10n.securityPrivacyNoteTitle,
                      variant: AppTextVariant.label,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppText(
                      l10n.securityPrivacyNoteBody,
                      variant: AppTextVariant.bodySmall,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }
}
