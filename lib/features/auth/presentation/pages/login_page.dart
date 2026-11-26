import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_sizing.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/auth/domain/entities/auth_entities.dart';
import 'package:business_manager/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// Optional offline-first Sign-In screen supporting Google Sign-In,
/// Phone Number (SMS OTP), and "Continue Offline (Local Only)".
final class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

final class _LoginPageState extends State<LoginPage> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _showPhoneForm = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleGoogle() async {
    final ok = await context.read<AuthCubit>().signInWithGoogle();
    if (ok && mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RoutePaths.home);
      }
    }
  }

  Future<void> _handleSendOtp() async {
    await context.read<AuthCubit>().sendPhoneOtp(_phoneCtrl.text.trim());
  }

  Future<void> _handleVerifyOtp() async {
    final ok = await context.read<AuthCubit>().verifyPhoneOtp(
      _otpCtrl.text.trim(),
    );
    if (ok && mounted) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(RoutePaths.home);
      }
    }
  }

  void _handleContinueOffline() {
    context.read<AuthCubit>().continueOffline();
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(RoutePaths.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: l10n.authSignInHeading,
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
              final hasPendingOtp = state.pendingOtpPhone != null;
              return ListView(
                padding: AppSpacing.screenAll,
                children: [
                  AppHeading(
                    l10n.authSignInHeading,
                    level: AppHeadingLevel.h2,
                    subtitle: l10n.authSignInSubtitle,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (!state.isCloudConfigured) ...[
                    AppCard(
                      elevated: false,
                      child: Row(
                        children: [
                          Icon(AppIcons.cloudOff, color: colorScheme.primary),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppText(
                              l10n.authCloudNotConfiguredBanner,
                              variant: AppTextVariant.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
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
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppButton(
                          label: l10n.authContinueWithGoogle,
                          icon: AppIcons.google,
                          isExpanded: true,
                          isLoading: state.isBusy && !_showPhoneForm,
                          onPressed:
                              state.isCloudConfigured && !state.isBusy
                                  ? _handleGoogle
                                  : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (!_showPhoneForm && !hasPendingOtp)
                          AppButton(
                            label: l10n.authContinueWithPhone,
                            icon: AppIcons.phone,
                            variant: AppButtonVariant.secondary,
                            isExpanded: true,
                            onPressed: state.isCloudConfigured && !state.isBusy
                                ? () => setState(() => _showPhoneForm = true)
                                : null,
                          )
                        else if (!hasPendingOtp) ...[
                          AppTextField(
                            controller: _phoneCtrl,
                            label: l10n.authPhoneLabel,
                            hint: l10n.authPhoneHint,
                            prefixIcon: AppIcons.phone,
                            keyboardType: TextInputType.phone,
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            label: l10n.authSendOtpAction,
                            icon: AppIcons.sms,
                            isExpanded: true,
                            isLoading: state.isBusy,
                            onPressed: !state.isBusy ? _handleSendOtp : null,
                          ),
                        ] else ...[
                          AppStatusBadge(
                            label: l10n.authOtpSentMessage(
                              state.pendingOtpPhone!,
                            ),
                            tone: AppStatusTone.good,
                            icon: AppIcons.sms,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            controller: _otpCtrl,
                            label: l10n.authOtpLabel,
                            hint: l10n.authOtpHint,
                            prefixIcon: AppIcons.pin,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            label: l10n.authVerifyOtpAction,
                            icon: AppIcons.confirm,
                            isExpanded: true,
                            isLoading: state.isBusy,
                            onPressed: !state.isBusy ? _handleVerifyOtp : null,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          AppButton(
                            label: l10n.authChangePhoneAction,
                            variant: AppButtonVariant.text,
                            isExpanded: true,
                            onPressed: !state.isBusy
                                ? () {
                                    _otpCtrl.clear();
                                    context
                                        .read<AuthCubit>()
                                        .cancelPendingOtp();
                                  }
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: l10n.authContinueOffline,
                    icon: AppIcons.cloudOff,
                    variant: AppButtonVariant.text,
                    isExpanded: true,
                    onPressed: _handleContinueOffline,
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
