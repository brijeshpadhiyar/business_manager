import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/auth/domain/entities/auth_entities.dart';
import 'package:business_manager/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:business_manager/features/sync/presentation/bloc/sync_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Account & Identity Linking page:
/// - Displays signed-in user profile & business ID
/// - Lets user link Google and Phone Number to the same account
/// - Lists synced devices under this owner
/// - Safe Sign-Out with unsynced local changes guard
final class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

final class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _linkPhoneCtrl = TextEditingController();
  final _linkOtpCtrl = TextEditingController();
  bool _showLinkPhone = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().refreshDevices();
  }

  @override
  void dispose() {
    _linkPhoneCtrl.dispose();
    _linkOtpCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirmSignOut() async {
    final l10n = context.l10n;
    final authCubit = context.read<AuthCubit>();
    final syncCubit = context.read<SyncCubit>();
    final unsynced = await authCubit.getUnsyncedChangesCount();
    if (!mounted) return;

    final action = await AppDialog.showChoices<String>(
      context,
      title: l10n.authSignOutConfirmTitle,
      message: unsynced > 0
          ? l10n.authSignOutUnsyncedWarning(unsynced)
          : l10n.authSignOutConfirmBody,
      choices: [
        AppDialogAction(label: l10n.actionCancel, value: 'cancel'),
        if (unsynced > 0)
          AppDialogAction(
            label: l10n.authSyncAndSignOutAction,
            value: 'sync_then_out',
            variant: AppButtonVariant.primary,
          ),
        AppDialogAction(
          label: unsynced > 0
              ? l10n.authSignOutAnywayAction
              : l10n.authSignOutAction,
          value: 'sign_out',
          variant: unsynced > 0
              ? AppButtonVariant.text
              : AppButtonVariant.destructive,
        ),
      ],
    );

    if (action == 'sync_then_out') {
      await syncCubit.syncNow();
      await authCubit.signOut();
    } else if (action == 'sign_out') {
      await authCubit.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: l10n.authAccountTitle,
      constrainMaxWidth: false,
      padding: EdgeInsets.zero,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: AppSizing.narrowContentWidth,
          ),
          child: BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (!state.isAuthenticated || state.user == null) {
                return ListView(
                  padding: context.density.screenAll,
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                AppIcons.cloudOff,
                                size: 32,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AppText(
                                      l10n.authOfflineModeBadge,
                                      variant: AppTextVariant.bodyLarge,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    const SizedBox(height: AppSpacing.xxs),
                                    AppText(
                                      l10n.authSignInPromptCardSubtitle,
                                      variant: AppTextVariant.bodySmall,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          AppButton(
                            label: l10n.authSignInHeading,
                            icon: AppIcons.signIn,
                            isExpanded: true,
                            onPressed: () => context.push(RoutePaths.authLogin),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }

              final user = state.user!;
              return ListView(
                padding: context.density.screenAll,
                children: [
                  if (state.errorMessage != null) ...[
                    AppStatusBadge(
                      label: state.errorMessage == 'invalid_phone'
                          ? l10n.authInvalidPhoneError
                          : state.errorMessage!,
                      tone: AppStatusTone.damaged,
                      icon: AppIcons.error,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  // Account Summary Card
                  AppCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(
                            AppIcons.account,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                user.primaryLabel,
                                variant: AppTextVariant.bodyLarge,
                                fontWeight: FontWeight.w600,
                              ),
                              if (user.email != null &&
                                  user.email!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xxs),
                                AppText(
                                  user.email!,
                                  variant: AppTextVariant.bodySmall,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                              if (user.phone != null &&
                                  user.phone!.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xxs),
                                AppText(
                                  user.phone!,
                                  variant: AppTextVariant.bodySmall,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ],
                          ),
                        ),
                        AppStatusBadge(
                          label: l10n.authSignedInBadge,
                          tone: AppStatusTone.good,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Linked Login Methods
                  AppHeading(
                    l10n.authLinkedIdentitiesHeading,
                    level: AppHeadingLevel.h3,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Icon(AppIcons.google),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    l10n.authGoogleProvider,
                                    variant: AppTextVariant.bodyMedium,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  AppText(
                                    user.hasGoogleLinked
                                        ? (user.email ?? l10n.authLinkedStatus)
                                        : l10n.authNotLinkedStatus,
                                    variant: AppTextVariant.bodySmall,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                            if (user.hasGoogleLinked)
                              AppStatusBadge(
                                label: l10n.authLinkedStatus,
                                tone: AppStatusTone.good,
                              )
                            else
                              AppButton(
                                label: l10n.authLinkAction,
                                variant: AppButtonVariant.secondary,
                                onPressed: !state.isBusy
                                    ? () => context
                                          .read<AuthCubit>()
                                          .linkGoogleIdentity()
                                    : null,
                              ),
                          ],
                        ),
                        const AppDivider(height: AppSpacing.lg),
                        Row(
                          children: [
                            const Icon(AppIcons.phone),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppText(
                                    l10n.authPhoneProvider,
                                    variant: AppTextVariant.bodyMedium,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  AppText(
                                    user.hasPhoneLinked
                                        ? (user.phone ?? l10n.authLinkedStatus)
                                        : l10n.authNotLinkedStatus,
                                    variant: AppTextVariant.bodySmall,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ],
                              ),
                            ),
                            if (user.hasPhoneLinked)
                              AppStatusBadge(
                                label: l10n.authLinkedStatus,
                                tone: AppStatusTone.good,
                              )
                            else
                              AppButton(
                                label: l10n.authLinkAction,
                                variant: AppButtonVariant.secondary,
                                onPressed: !state.isBusy
                                    ? () => setState(
                                        () => _showLinkPhone = !_showLinkPhone,
                                      )
                                    : null,
                              ),
                          ],
                        ),
                        if (_showLinkPhone && !user.hasPhoneLinked) ...[
                          const SizedBox(height: AppSpacing.md),
                          if (state.pendingOtpPhone == null) ...[
                            AppTextField(
                              controller: _linkPhoneCtrl,
                              label: l10n.authPhoneLabel,
                              hint: l10n.authPhoneHint,
                              prefixIcon: AppIcons.phone,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            AppButton(
                              label: l10n.authSendOtpAction,
                              icon: AppIcons.sms,
                              isExpanded: true,
                              isLoading: state.isBusy,
                              onPressed: !state.isBusy
                                  ? () =>
                                        context.read<AuthCubit>().sendPhoneOtp(
                                          _linkPhoneCtrl.text.trim(),
                                          isLinking: true,
                                        )
                                  : null,
                            ),
                          ] else ...[
                            AppTextField(
                              controller: _linkOtpCtrl,
                              label: l10n.authOtpLabel,
                              hint: l10n.authOtpHint,
                              prefixIcon: AppIcons.pin,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            AppButton(
                              label: l10n.authVerifyOtpAction,
                              icon: AppIcons.confirm,
                              isExpanded: true,
                              isLoading: state.isBusy,
                              onPressed: !state.isBusy
                                  ? () async {
                                      final ok = await context
                                          .read<AuthCubit>()
                                          .verifyPhoneOtp(
                                            _linkOtpCtrl.text.trim(),
                                          );
                                      if (ok && mounted) {
                                        setState(() => _showLinkPhone = false);
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Linked Devices
                  AppHeading(
                    l10n.authLinkedDevicesHeading,
                    level: AppHeadingLevel.h3,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppCard(
                    child: state.devices.isEmpty
                        ? AppText(
                            l10n.authNoDevicesYet,
                            variant: AppTextVariant.bodySmall,
                            color: colorScheme.onSurfaceVariant,
                          )
                        : Column(
                            children: [
                              for (
                                var i = 0;
                                i < state.devices.length;
                                i++
                              ) ...[
                                if (i > 0)
                                  const AppDivider(height: AppSpacing.md),
                                Row(
                                  children: [
                                    const Icon(AppIcons.devices),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          AppText(
                                            state.devices[i].deviceName,
                                            variant: AppTextVariant.bodyMedium,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          AppText(
                                            '${state.devices[i].platform} • v${state.devices[i].appVersion}'
                                            '${state.devices[i].lastSyncedAtUtcMillis != null ? ' • ${IstDateTimeHelper.formatIstDateTime(state.devices[i].lastSyncedAtUtcMillis!)}' : ''}',
                                            variant: AppTextVariant.bodySmall,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (state.devices[i].isCurrentDevice)
                                      AppStatusBadge(
                                        label: l10n.authCurrentDeviceBadge,
                                        tone: AppStatusTone.good,
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  AppButton(
                    label: l10n.syncCenterTitle,
                    icon: AppIcons.cloudSync,
                    variant: AppButtonVariant.secondary,
                    isExpanded: true,
                    onPressed: () => context.push(RoutePaths.settingsSync),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: l10n.authSignOutAction,
                    icon: AppIcons.signOut,
                    variant: AppButtonVariant.destructive,
                    isExpanded: true,
                    isLoading: state.isBusy,
                    onPressed: !state.isBusy ? _confirmSignOut : null,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
