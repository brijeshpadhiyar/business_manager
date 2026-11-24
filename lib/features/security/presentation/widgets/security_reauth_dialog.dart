import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/security/domain/entities/security_entities.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:business_manager/features/security/presentation/widgets/pin_keypad.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

/// Reusable authentication gate for sensitive workshop operations:
/// - Restore from Backup (PIN or Biometric)
/// - Export Raw SQLite (PIN or Biometric)
/// - Change PIN / Disable PIN / Regenerate Recovery Key (PIN-only)
///
/// Immediately returns `true` if App Lock is disabled.
abstract final class SecurityReauthDialog {
  static Future<bool> verify(
    BuildContext context, {
    required String title,
    required String subtitle,
    bool allowBiometric = true,
  }) async {
    final cubit = context.read<AppLockCubit>();
    if (!cubit.state.isPinEnabled) return true;

    await cubit.setSensitiveScreenActive(true);
    try {
      if (!context.mounted) return false;
      final verified = await AppDialog.showCustom<bool>(
        context,
        barrierDismissible: false,
        builder: (_) => BlocProvider<AppLockCubit>.value(
          value: cubit,
          child: _SecurityReauthContent(
            title: title,
            subtitle: subtitle,
            allowBiometric: allowBiometric,
          ),
        ),
      );
      return verified == true;
    } finally {
      await cubit.setSensitiveScreenActive(false);
    }
  }
}

final class _SecurityReauthContent extends StatefulWidget {
  const _SecurityReauthContent({
    required this.title,
    required this.subtitle,
    required this.allowBiometric,
  });

  final String title;
  final String subtitle;
  final bool allowBiometric;

  @override
  State<_SecurityReauthContent> createState() => _SecurityReauthContentState();
}

final class _SecurityReauthContentState extends State<_SecurityReauthContent> {
  String _pin = '';
  bool _verifying = false;
  String? _errorText;

  @override
  void dispose() {
    _pin = '';
    super.dispose();
  }

  Future<void> _onDigit(String digit, int pinLength) async {
    if (_verifying || _pin.length >= pinLength) return;
    final next = '$_pin$digit';
    setState(() {
      _pin = next;
      _errorText = null;
    });

    if (next.length == pinLength) {
      setState(() => _verifying = true);
      final cubit = context.read<AppLockCubit>();
      final result = await cubit.verifyPinForSensitiveAction(next);
      if (!mounted) return;
      if (result.success) {
        Navigator.of(context).pop(true);
        return;
      }
      final l10n = context.l10n;
      setState(() {
        _pin = '';
        _verifying = false;
        _errorText = result.errorCode == 'locked_out'
            ? l10n.securityLockoutCountdown(
                '${cubit.state.remainingLockoutSeconds}s',
              )
            : l10n.securityWrongPinError;
      });
    }
  }

  Future<void> _tryBiometric() async {
    final cubit = context.read<AppLockCubit>();
    if (!widget.allowBiometric || !cubit.state.canUseBiometrics) return;
    final outcome = await cubit.verifyBiometricForSensitiveAction(
      localizedReason: widget.subtitle,
    );
    if (!mounted) return;
    if (outcome == BiometricAuthOutcome.success) {
      Navigator.of(context).pop(true);
    } else if (outcome != BiometricAuthOutcome.canceled) {
      setState(() => _errorText = context.l10n.securityBiometricFailedFallback);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocBuilder<AppLockCubit, AppLockState>(
      builder: (context, state) {
        final pinLen = state.settings.pinLength;
        final isLockedOut = state.isLockedOut;
        final showBio = widget.allowBiometric && state.canUseBiometrics;

        return AppDialog(
          title: widget.title,
          icon: Icons.lock_outline_rounded,
          cancelLabel: _verifying ? null : l10n.actionCancel,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                widget.subtitle,
                variant: AppTextVariant.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              if (_errorText != null || isLockedOut) ...[
                AppStatusBadge(
                  label: isLockedOut
                      ? l10n.securityLockoutCountdown(
                          '${state.remainingLockoutSeconds}s',
                        )
                      : _errorText!,
                  tone: AppStatusTone.damaged,
                  icon: Icons.error_outline_rounded,
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              PinKeypad(
                pinLength: pinLen,
                enteredLength: _pin.length,
                enabled: !_verifying && !isLockedOut,
                showBiometricButton: showBio,
                onBiometricPressed: _tryBiometric,
                biometricTooltip: l10n.securityUseBiometricAction,
                onDigitPressed: (d) => _onDigit(d, pinLen),
                onBackspacePressed: () {
                  if (_pin.isNotEmpty) {
                    setState(() => _pin = _pin.substring(0, _pin.length - 1));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
