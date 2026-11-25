import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/design_system/app_typography.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/security/domain/services/pin_hasher.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:business_manager/features/security/presentation/widgets/pin_keypad.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';

enum _RecoveryStep { verifyKey, enterNewPin, confirmNewPin, showFreshKey }

/// Offline Recovery Key verification & PIN reset workflow.
/// Preserves 100% of business data and issues a fresh Recovery Key on completion.
final class PinRecoveryPage extends StatefulWidget {
  const PinRecoveryPage({super.key, required this.onBackToLock});

  final VoidCallback onBackToLock;

  @override
  State<PinRecoveryPage> createState() => _PinRecoveryPageState();
}

final class _PinRecoveryPageState extends State<PinRecoveryPage> {
  final _formKey = GlobalKey<FormState>();
  final _keyCtrl = TextEditingController();
  _RecoveryStep _step = _RecoveryStep.verifyKey;
  int _pinLength = 4;
  String _newPin = '';
  String _confirmPin = '';
  String? _freshRecoveryKey;
  bool _freshKeyConfirmed = false;
  bool _working = false;
  bool _submittedKeyOnce = false;
  String? _errorText;
  late final AppLockCubit _lockCubit;

  @override
  void initState() {
    super.initState();
    _lockCubit = context.read<AppLockCubit>();
    _lockCubit.setSensitiveScreenActive(true);
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _newPin = '';
    _confirmPin = '';
    _freshRecoveryKey = null;
    _lockCubit.setSensitiveScreenActive(false);
    super.dispose();
  }

  Future<void> _verifyRecoveryKey() async {
    if (_working) return;
    if (!_submittedKeyOnce) {
      setState(() => _submittedKeyOnce = true);
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final raw = _keyCtrl.text.trim();

    setState(() {
      _working = true;
      _errorText = null;
    });
    final res = await _lockCubit.verifyRecoveryKey(raw);
    if (!mounted) return;

    if (res.success) {
      setState(() {
        _working = false;
        _step = _RecoveryStep.enterNewPin;
      });
    } else {
      final l10n = context.l10n;
      setState(() {
        _working = false;
        _errorText = res.errorCode == 'locked_out'
            ? l10n.securityLockoutCountdown(
                '${_lockCubit.state.remainingLockoutSeconds}s',
              )
            : l10n.securityRecoveryKeyInvalidError;
      });
    }
  }

  void _onDigit(String digit) {
    if (_working) return;
    if (_step == _RecoveryStep.enterNewPin) {
      if (_newPin.length >= _pinLength) return;
      final next = '$_newPin$digit';
      setState(() {
        _newPin = next;
        _errorText = null;
      });
      if (next.length == _pinLength) {
        setState(() {
          _step = _RecoveryStep.confirmNewPin;
          _confirmPin = '';
        });
      }
      return;
    }
    if (_step == _RecoveryStep.confirmNewPin) {
      if (_confirmPin.length >= _pinLength) return;
      final next = '$_confirmPin$digit';
      setState(() {
        _confirmPin = next;
        _errorText = null;
      });
      if (next.length == _pinLength) {
        if (next != _newPin) {
          setState(() {
            _confirmPin = '';
            _errorText = context.l10n.securityPinMismatchError;
          });
          return;
        }
        setState(() {
          _freshRecoveryKey = PinHasher.generateRecoveryKey();
          _freshKeyConfirmed = false;
          _step = _RecoveryStep.showFreshKey;
        });
      }
    }
  }

  void _onBackspace() {
    if (_step == _RecoveryStep.enterNewPin && _newPin.isNotEmpty) {
      setState(() => _newPin = _newPin.substring(0, _newPin.length - 1));
    } else if (_step == _RecoveryStep.confirmNewPin && _confirmPin.isNotEmpty) {
      setState(
        () => _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1),
      );
    }
  }

  Future<void> _completeRecovery() async {
    final freshKey = _freshRecoveryKey;
    if (freshKey == null || !_freshKeyConfirmed || _working) return;
    setState(() => _working = true);
    try {
      await _lockCubit.changePin(newPin: _newPin, newRecoveryKey: freshKey);
      // AppLockGate will immediately reveal the unlocked app!
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _working = false;
        _errorText = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return AppScaffold(
      title: l10n.securityRecoveryHeading,
      leading: AppIconButton(
        icon: Icons.arrow_back_rounded,
        tooltip: l10n.actionCancel,
        onPressed: widget.onBackToLock,
      ),
      body: BlocBuilder<AppLockCubit, AppLockState>(
        builder: (context, state) {
          return ListView(
            children: [
              if (_step == _RecoveryStep.verifyKey) ...[
                Form(
                  key: _formKey,
                  autovalidateMode: _submittedKeyOnce
                      ? AutovalidateMode.onUserInteraction
                      : AutovalidateMode.disabled,
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppHeading(
                          l10n.securityRecoveryEnterKeyTitle,
                          level: AppHeadingLevel.h3,
                          subtitle: l10n.securityRecoveryEnterKeySubtitle,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        AppTextField(
                          controller: _keyCtrl,
                          label: l10n.securityRecoveryKeyLabel,
                          hint: 'XXXX-XXXX',
                          prefixIcon: Icons.vpn_key_outlined,
                          // Recovery keys are upper-case codes: no
                          // autocorrect or suggestions mangling them.
                          textCapitalization: TextCapitalization.characters,
                          autocorrect: false,
                          textInputAction: TextInputAction.done,
                          onChanged: (_) => setState(() => _errorText = null),
                          validator: ValidationLocalizer.wrap(
                            l10n,
                            AppValidators.recoveryKeyValidator,
                          ),
                        ),
                        if (_errorText != null || state.isLockedOut) ...[
                          const SizedBox(height: AppSpacing.sm),
                          AppStatusBadge(
                            label: state.isLockedOut
                                ? l10n.securityLockoutCountdown(
                                    '${state.remainingLockoutSeconds}s',
                                  )
                                : _errorText!,
                            tone: AppStatusTone.damaged,
                            icon: Icons.error_outline_rounded,
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        AppButton(
                          label: l10n.securityVerifyRecoveryKeyAction,
                          icon: Icons.verified_user_outlined,
                          isExpanded: true,
                          isLoading: _working,
                          onPressed: !_working && !state.isLockedOut
                              ? _verifyRecoveryKey
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                AppCard(
                  elevated: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        l10n.securityLostBothTitle,
                        variant: AppTextVariant.label,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppText(
                        l10n.securityLostBothBody,
                        variant: AppTextVariant.bodySmall,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ] else if (_step == _RecoveryStep.enterNewPin ||
                  _step == _RecoveryStep.confirmNewPin) ...[
                if (_step == _RecoveryStep.enterNewPin) ...[
                  Center(
                    child: Wrap(
                      spacing: AppSpacing.sm,
                      children: [
                        ChoiceChip(
                          label: Text(l10n.securityPinLength4Label),
                          selected: _pinLength == 4,
                          onSelected: (_) => setState(() {
                            _pinLength = 4;
                            _newPin = '';
                            _confirmPin = '';
                          }),
                        ),
                        ChoiceChip(
                          label: Text(l10n.securityPinLength6Label),
                          selected: _pinLength == 6,
                          onSelected: (_) => setState(() {
                            _pinLength = 6;
                            _newPin = '';
                            _confirmPin = '';
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                AppHeading(
                  _step == _RecoveryStep.enterNewPin
                      ? l10n.securityEnterNewPinTitle
                      : l10n.securityConfirmPinTitle,
                  level: AppHeadingLevel.h3,
                  subtitle: _step == _RecoveryStep.enterNewPin
                      ? l10n.securityCreatePinSubtitle(_pinLength)
                      : l10n.securityConfirmPinSubtitle,
                ),
                const SizedBox(height: AppSpacing.md),
                if (_errorText != null) ...[
                  Center(
                    child: AppStatusBadge(
                      label: _errorText!,
                      tone: AppStatusTone.damaged,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Center(
                  child: PinKeypad(
                    pinLength: _pinLength,
                    enteredLength: _step == _RecoveryStep.enterNewPin
                        ? _newPin.length
                        : _confirmPin.length,
                    onDigitPressed: _onDigit,
                    onBackspacePressed: _onBackspace,
                  ),
                ),
              ] else ...[
                AppCard(
                  borderColor: context.semanticColors.goodStock.withValues(
                    alpha: 0.5,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppHeading(
                        l10n.securityNewRecoveryKeyTitle,
                        level: AppHeadingLevel.h3,
                        subtitle: l10n.securityRecoveryKeyWriteDownBody,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: AppRadius.lgBorder,
                          border: Border.all(color: colorScheme.primary),
                        ),
                        child: SelectableText(
                          _freshRecoveryKey ?? '',
                          textAlign: TextAlign.center,
                          style: AppTypography.tabular(
                            Theme.of(context).textTheme.headlineMedium!
                                .copyWith(
                                  letterSpacing: 3,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppCheckbox(
                        label: l10n.securityRecoveryKeyConfirmedCheckbox,
                        value: _freshKeyConfirmed,
                        onChanged: (v) =>
                            setState(() => _freshKeyConfirmed = v ?? false),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppButton(
                        label: l10n.securityCompleteRecoveryAction,
                        icon: Icons.check_circle_outline_rounded,
                        isExpanded: true,
                        isLoading: _working,
                        onPressed: _freshKeyConfirmed && !_working
                            ? _completeRecovery
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
