import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/design_system/app_typography.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/security/domain/entities/security_entities.dart';
import 'package:business_manager/features/security/domain/services/pin_hasher.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:business_manager/features/security/presentation/widgets/pin_keypad.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

enum _PinSetupStep { enterPin, confirmPin, recoveryKey }

/// First-time PIN setup OR Change PIN flow (after current PIN was verified).
/// Enforces `FLAG_SECURE` while open so recovery keys are never screenshotted.
final class PinSetupPage extends StatefulWidget {
  const PinSetupPage({super.key, this.isChangeMode = false});

  final bool isChangeMode;

  @override
  State<PinSetupPage> createState() => _PinSetupPageState();
}

final class _PinSetupPageState extends State<PinSetupPage> {
  _PinSetupStep _step = _PinSetupStep.enterPin;
  int _pinLength = 4;
  String _firstPin = '';
  String _confirmPin = '';
  String? _recoveryKey;
  bool _recoveryConfirmed = false;
  bool _enableBiometric = false;
  bool _saving = false;
  String? _errorText;
  late final AppLockCubit _lockCubit;

  @override
  void initState() {
    super.initState();
    _lockCubit = context.read<AppLockCubit>();
    _lockCubit.setSensitiveScreenActive(true);
    _enableBiometric =
        _lockCubit.state.biometricAvailability ==
        BiometricAvailability.available;
  }

  @override
  void dispose() {
    _firstPin = '';
    _confirmPin = '';
    _recoveryKey = null;
    _lockCubit.setSensitiveScreenActive(false);
    super.dispose();
  }

  Future<void> _onDigit(String digit) async {
    if (_saving) return;
    if (_step == _PinSetupStep.enterPin) {
      if (_firstPin.length >= _pinLength) return;
      final next = '$_firstPin$digit';
      setState(() {
        _firstPin = next;
        _errorText = null;
      });
      if (next.length == _pinLength) {
        setState(() {
          _step = _PinSetupStep.confirmPin;
          _confirmPin = '';
        });
      }
      return;
    }

    if (_step == _PinSetupStep.confirmPin) {
      if (_confirmPin.length >= _pinLength) return;
      final next = '$_confirmPin$digit';
      setState(() {
        _confirmPin = next;
        _errorText = null;
      });
      if (next.length == _pinLength) {
        if (next != _firstPin) {
          setState(() {
            _confirmPin = '';
            _errorText = context.l10n.securityPinMismatchError;
          });
          return;
        }
        if (widget.isChangeMode) {
          await _finishChangePin();
        } else {
          setState(() {
            _recoveryKey = PinHasher.generateRecoveryKey();
            _recoveryConfirmed = false;
            _step = _PinSetupStep.recoveryKey;
          });
        }
      }
    }
  }

  void _onBackspace() {
    if (_saving) return;
    if (_step == _PinSetupStep.enterPin && _firstPin.isNotEmpty) {
      setState(() => _firstPin = _firstPin.substring(0, _firstPin.length - 1));
    } else if (_step == _PinSetupStep.confirmPin && _confirmPin.isNotEmpty) {
      setState(
        () => _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1),
      );
    }
  }

  Future<void> _finishChangePin() async {
    setState(() => _saving = true);
    try {
      await _lockCubit.changePin(newPin: _firstPin);
      if (!mounted) return;
      AppFeedback.showSuccess(context, context.l10n.securityPinChangedSuccess);
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorText = e.toString();
      });
    }
  }

  Future<void> _finishInitialSetup() async {
    final key = _recoveryKey;
    if (key == null || !_recoveryConfirmed || _saving) return;
    setState(() => _saving = true);
    try {
      await _lockCubit.enablePin(
        pin: _firstPin,
        recoveryKey: key,
        enableBiometric: _enableBiometric,
      );
      if (!mounted) return;
      AppFeedback.showSuccess(context, context.l10n.securityPinEnabledSuccess);
      context.pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _errorText = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final title = widget.isChangeMode
        ? l10n.securityChangePinAction
        : l10n.securitySetupPinTitle;

    return AppScaffold(
      title: title,
      body: ListView(
        children: [
          if (_step != _PinSetupStep.recoveryKey) ...[
            if (_step == _PinSetupStep.enterPin) ...[
              Center(
                child: Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.securityPinLength4Label),
                      selected: _pinLength == 4,
                      onSelected: (_) => setState(() {
                        _pinLength = 4;
                        _firstPin = '';
                        _confirmPin = '';
                        _errorText = null;
                      }),
                    ),
                    ChoiceChip(
                      label: Text(l10n.securityPinLength6Label),
                      selected: _pinLength == 6,
                      onSelected: (_) => setState(() {
                        _pinLength = 6;
                        _firstPin = '';
                        _confirmPin = '';
                        _errorText = null;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            AppHeading(
              _step == _PinSetupStep.enterPin
                  ? (widget.isChangeMode
                        ? l10n.securityEnterNewPinTitle
                        : l10n.securityCreatePinTitle)
                  : l10n.securityConfirmPinTitle,
              level: AppHeadingLevel.h3,
              subtitle: _step == _PinSetupStep.enterPin
                  ? l10n.securityCreatePinSubtitle(_pinLength)
                  : l10n.securityConfirmPinSubtitle,
            ),
            const SizedBox(height: AppSpacing.md),
            if (_errorText != null) ...[
              Center(
                child: AppStatusBadge(
                  label: _errorText!,
                  tone: AppStatusTone.damaged,
                  icon: Icons.error_outline_rounded,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (_saving)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(child: AppLoader()),
              )
            else
              Center(
                child: PinKeypad(
                  pinLength: _pinLength,
                  enteredLength: _step == _PinSetupStep.enterPin
                      ? _firstPin.length
                      : _confirmPin.length,
                  onDigitPressed: _onDigit,
                  onBackspacePressed: _onBackspace,
                ),
              ),
            if (_step == _PinSetupStep.confirmPin) ...[
              const SizedBox(height: AppSpacing.md),
              Center(
                child: AppButton(
                  label: l10n.securityStartOverAction,
                  variant: AppButtonVariant.text,
                  onPressed: () => setState(() {
                    _step = _PinSetupStep.enterPin;
                    _firstPin = '';
                    _confirmPin = '';
                    _errorText = null;
                  }),
                ),
              ),
            ],
          ] else ...[
            // Step 3: Mandatory Offline Recovery Key Display & Confirmation
            AppCard(
              borderColor: context.semanticColors.pending.withValues(
                alpha: 0.6,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.vpn_key_outlined,
                        color: context.semanticColors.pending,
                        size: 28,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppHeading(
                          l10n.securityRecoveryKeyTitle,
                          level: AppHeadingLevel.h3,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppText(
                    l10n.securityRecoveryKeyWriteDownBody,
                    variant: AppTextVariant.bodySmall,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.lg,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: AppRadius.lgBorder,
                      border: Border.all(color: colorScheme.primary),
                    ),
                    child: SelectableText(
                      _recoveryKey ?? '',
                      textAlign: TextAlign.center,
                      style: AppTypography.tabular(
                        Theme.of(context).textTheme.headlineMedium!.copyWith(
                          letterSpacing: 3,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (_lockCubit.state.biometricAvailability ==
                      BiometricAvailability.available) ...[
                    AppSwitch(
                      label: l10n.securityEnableBiometricLabel,
                      subtitle: l10n.securityEnableBiometricSubtitle,
                      value: _enableBiometric,
                      onChanged: (v) => setState(() => _enableBiometric = v),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  AppCheckbox(
                    label: l10n.securityRecoveryKeyConfirmedCheckbox,
                    value: _recoveryConfirmed,
                    onChanged: (v) =>
                        setState(() => _recoveryConfirmed = v ?? false),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    label: l10n.securityActivateAppLockAction,
                    icon: Icons.lock_outline_rounded,
                    isExpanded: true,
                    isLoading: _saving,
                    onPressed: _recoveryConfirmed && !_saving
                        ? _finishInitialSetup
                        : null,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}
