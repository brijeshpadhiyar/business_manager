import 'package:business_manager/core/config/app_identity.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:business_manager/features/security/presentation/pages/pin_recovery_page.dart';
import 'package:business_manager/features/security/presentation/widgets/pin_keypad.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/widgets/widgets.dart';

/// Root branded Lock Screen rendered above all routes whenever [AppLockCubit]
/// is in `locked` state. Prevents any flash of Dashboard or sensitive data.
final class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

final class _AppLockScreenState extends State<AppLockScreen> {
  String _pin = '';
  bool _biometricAutoTriggered = false;
  bool _showingRecovery = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_biometricAutoTriggered) {
      _biometricAutoTriggered = true;
      final cubit = context.read<AppLockCubit>();
      if (cubit.state.canUseBiometrics) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _triggerBiometric();
        });
      }
    }
  }

  @override
  void dispose() {
    _pin = '';
    super.dispose();
  }

  Future<void> _triggerBiometric() async {
    final cubit = context.read<AppLockCubit>();
    if (!cubit.state.canUseBiometrics) return;
    await cubit.unlockWithBiometrics(
      localizedReason: context.l10n.securityBiometricPromptReason,
    );
  }

  Future<void> _onDigit(String digit, int pinLength) async {
    if (_pin.length >= pinLength) return;
    context.read<AppLockCubit>().clearError();
    final next = '$_pin$digit';
    setState(() => _pin = next);

    if (next.length == pinLength) {
      final ok = await context.read<AppLockCubit>().unlockWithPin(next);
      if (!mounted) return;
      setState(() => _pin = '');
      if (ok) {
        _biometricAutoTriggered = false;
      }
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  String _formatCountdown(int seconds) {
    return AppDateTimeFormatter.formatCountdownSeconds(seconds);
  }

  String? _resolveErrorText(BuildContext context, AppLockState state) {
    final l10n = context.l10n;
    if (state.isLockedOut) {
      return l10n.securityLockoutCountdown(
        _formatCountdown(state.remainingLockoutSeconds),
      );
    }
    return switch (state.errorCode) {
      'invalid_pin' => l10n.securityWrongPinError,
      'locked_out' => l10n.securityLockoutCountdown(
        _formatCountdown(state.remainingLockoutSeconds),
      ),
      'biometric_temp_lockout' ||
      'biometric_perm_lockout' => l10n.securityBiometricLockoutFallback,
      'biometric_not_enrolled' ||
      'biometric_no_hardware' => l10n.securityBiometricUnavailableFallback,
      'biometric_failed' => l10n.securityBiometricFailedFallback,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (_showingRecovery) {
      return PinRecoveryPage(
        onBackToLock: () {
          if (mounted) {
            setState(() => _showingRecovery = false);
          }
        },
      );
    }

    final l10n = context.l10n;
    return BlocBuilder<AppLockCubit, AppLockState>(
      builder: (context, state) {
        final errorText = _resolveErrorText(context, state);
        final pinLen = state.settings.pinLength;
        final canEnterPin = !state.isVerifying && !state.isLockedOut;

        return PopScope(
          canPop: false,
          child: Scaffold(
            body: Container(
              width: double.infinity,
              height: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.heroGradientDark,
              ),
              child: SafeArea(
                child: Center(
                  child: SingleChildScrollView(
                    padding: AppSpacing.screenAll,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // StitchFlow Brand Symbol
                          Container(
                            width: 68,
                            height: 68,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: AppRadius.xlBorder,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Image.asset(
                              AppIdentity.symbolPngAsset,
                              cacheWidth: 192,
                              cacheHeight: 192,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.lock_outline_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            l10n.securityLockScreenTitle,
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.securityLockScreenSubtitle,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Feedback / Lockout Banner
                          ConstrainedBox(
                            constraints: const BoxConstraints(minHeight: 44),
                            child: Center(
                              child: state.isVerifying
                                  ? const AppSpinner(
                                      size: 24,
                                      color: Colors.white,
                                    )
                                  : errorText != null
                                  ? Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.md,
                                        vertical: AppSpacing.xs + 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.darkDamagedContainer
                                            .withValues(alpha: 0.85),
                                        borderRadius: AppRadius.mdBorder,
                                      ),
                                      child: Text(
                                        errorText,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColors.darkDamaged,
                                              fontWeight: FontWeight.w600,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    )
                                  : const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),

                          PinKeypad(
                            pinLength: pinLen,
                            enteredLength: _pin.length,
                            enabled: canEnterPin,
                            onDarkBackground: true,
                            showBiometricButton: state.canUseBiometrics,
                            onBiometricPressed: _triggerBiometric,
                            biometricTooltip: l10n.securityUseBiometricAction,
                            onDigitPressed: (d) => _onDigit(d, pinLen),
                            onBackspacePressed: _onBackspace,
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          if (state.canUseBiometrics) ...[
                            TextButton.icon(
                              onPressed: canEnterPin ? _triggerBiometric : null,
                              icon: const Icon(
                                Icons.fingerprint_rounded,
                                color: Colors.white,
                              ),
                              label: Text(
                                l10n.securityUseBiometricAction,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ],

                          TextButton(
                            onPressed: () {
                              setState(() {
                                _pin = '';
                                _showingRecovery = true;
                              });
                            },
                            child: Text(
                              l10n.securityForgotPinAction,
                              style: const TextStyle(
                                color: AppColors.saffron400,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
