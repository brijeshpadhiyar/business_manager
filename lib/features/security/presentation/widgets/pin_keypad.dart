import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_radius.dart';
import 'package:business_manager/core/design_system/app_spacing.dart';
import 'package:business_manager/core/design_system/app_typography.dart';
import 'package:business_manager/core/localization/l10n_extensions.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:business_manager/core/design_system/app_icons.dart';

/// Accessible, 360dp-safe numeric PIN keypad with masked indicator dots and
/// optional bottom-left biometric trigger button.
final class PinKeypad extends StatelessWidget {
  const PinKeypad({
    super.key,
    required this.pinLength,
    required this.enteredLength,
    required this.onDigitPressed,
    required this.onBackspacePressed,
    this.enabled = true,
    this.showBiometricButton = false,
    this.onBiometricPressed,
    this.biometricTooltip,
    this.onDarkBackground = false,
  });

  final int pinLength;
  final int enteredLength;
  final ValueChanged<String> onDigitPressed;
  final VoidCallback onBackspacePressed;
  final bool enabled;
  final bool showBiometricButton;
  final VoidCallback? onBiometricPressed;
  final String? biometricTooltip;
  final bool onDarkBackground;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dotFill = onDarkBackground ? AppColors.onHero : colorScheme.primary;
    final dotBorder = onDarkBackground
        ? AppColors.onHero.withValues(alpha: 0.45)
        : colorScheme.outline;

    // Desktop and web: type the PIN on a physical keyboard (digits, numpad,
    // Backspace) as well as tapping the keys.
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (!enabled || event is KeyUpEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.backspace ||
            key == LogicalKeyboardKey.delete) {
          if (enteredLength > 0) onBackspacePressed();
          return KeyEventResult.handled;
        }
        final digit = _digitFor(key);
        if (digit != null) {
          if (enteredLength < pinLength) onDigitPressed(digit);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Masked PIN Dots: announced as "2 of 4 digits entered", never
          // the digits themselves.
          Semantics(
            liveRegion: true,
            label:
                context.l10nOrNull?.securityPinProgress(
                  enteredLength,
                  pinLength,
                ) ??
                '$enteredLength / $pinLength',
            child: ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pinLength, (index) {
                  final filled = index < enteredLength;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    margin: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? dotFill : Colors.transparent,
                      border: Border.all(
                        color: filled ? dotFill : dotBorder,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3x4 Keypad Grid (large >= 56dp accessible touch targets)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 288),
            child: Column(
              children: [
                _buildRow(context, const ['1', '2', '3']),
                const SizedBox(height: AppSpacing.sm),
                _buildRow(context, const ['4', '5', '6']),
                const SizedBox(height: AppSpacing.sm),
                _buildRow(context, const ['7', '8', '9']),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    SizedBox(
                      width: 68,
                      height: 58,
                      child: showBiometricButton && onBiometricPressed != null
                          ? Tooltip(
                              message: biometricTooltip ?? '',
                              child: _KeyButton(
                                onDarkBackground: onDarkBackground,
                                enabled: enabled,
                                onTap: onBiometricPressed!,
                                child: Icon(
                                  AppIcons.biometric,
                                  size: 30,
                                  color: onDarkBackground
                                      ? AppColors.onHero
                                      : colorScheme.secondary,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    _digitKey(context, '0'),
                    SizedBox(
                      width: 68,
                      height: 58,
                      child: Tooltip(
                        message: MaterialLocalizations.of(context)
                            .deleteButtonTooltip,
                        excludeFromSemantics: true,
                        child: Semantics(
                          button: true,
                          label: MaterialLocalizations.of(context)
                              .deleteButtonTooltip,
                          child: _KeyButton(
                            onDarkBackground: onDarkBackground,
                            enabled: enabled && enteredLength > 0,
                            onTap: onBackspacePressed,
                            child: Icon(
                              AppIcons.backspace,
                              size: 24,
                              color: onDarkBackground
                                  ? AppColors.onHero.withValues(
                                      alpha: enteredLength > 0 ? 1 : 0.4,
                                    )
                                  : colorScheme.onSurface.withValues(
                                      alpha: enteredLength > 0 ? 1 : 0.38,
                                    ),
                            ),
                          ),
                        ),
                      ),
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

  static final Map<LogicalKeyboardKey, String> _digitKeys = {
    for (var i = 0; i <= 9; i++) ...{
      LogicalKeyboardKey(LogicalKeyboardKey.digit0.keyId + i): '$i',
      LogicalKeyboardKey(LogicalKeyboardKey.numpad0.keyId + i): '$i',
    },
  };

  static String? _digitFor(LogicalKeyboardKey key) => _digitKeys[key];

  Widget _buildRow(BuildContext context, List<String> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [for (final d in digits) _digitKey(context, d)],
    );
  }

  Widget _digitKey(BuildContext context, String digit) {
    final textColor = onDarkBackground
        ? AppColors.onHero
        : Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      width: 68,
      height: 58,
      child: _KeyButton(
        onDarkBackground: onDarkBackground,
        enabled: enabled,
        onTap: () {
          HapticFeedback.selectionClick();
          onDigitPressed(digit);
        },
        child: Text(
          digit,
          style: AppTypography.tabular(
            Theme.of(context).textTheme.headlineSmall!
                .copyWith(color: textColor, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

final class _KeyButton extends StatelessWidget {
  const _KeyButton({
    required this.onDarkBackground,
    required this.enabled,
    required this.onTap,
    required this.child,
  });

  final bool onDarkBackground;
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = onDarkBackground
        ? AppColors.onHero.withValues(alpha: enabled ? 0.12 : 0.05)
        : colorScheme.surfaceContainerHighest.withValues(
            alpha: enabled ? 0.75 : 0.35,
          );
    final border = onDarkBackground
        ? AppColors.onHero.withValues(alpha: 0.18)
        : colorScheme.outlineVariant;

    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgBorder,
        side: BorderSide(color: border),
      ),
      child: InkWell(
        borderRadius: AppRadius.lgBorder,
        onTap: enabled ? onTap : null,
        child: Center(child: child),
      ),
    );
  }
}
