import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:material_ui/material_ui.dart';

/// Soft, layered elevation tokens (Stripe / Linear / Tailwind style).
///
/// Every level pairs a tight "contact" shadow with a softer "ambient" shadow.
/// Light mode is tinted with Slate 900 rather than pure black so shadows feel
/// natural on the cool Slate background; dark mode uses deeper black shadows
/// because surfaces there are separated mostly by lightness and borders.
///
/// Usage: `boxShadow: AppShadows.of(context).sm`
@immutable
final class AppShadows {
  const AppShadows._({
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.focus,
    required this.brandGlow,
  });

  /// Chips, inputs, small controls.
  final List<BoxShadow> xs;

  /// Resting cards and list tiles.
  final List<BoxShadow> sm;

  /// Hovered / raised cards, menus, popovers.
  final List<BoxShadow> md;

  /// Dialogs, bottom sheets, floating navigation.
  final List<BoxShadow> lg;

  /// Modals and hero banners.
  final List<BoxShadow> xl;

  /// Keyboard focus ring (3px Indigo halo).
  final List<BoxShadow> focus;

  /// Coloured glow for the primary CTA and hero only — use sparingly.
  final List<BoxShadow> brandGlow;

  static AppShadows of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;

  static AppShadows forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  static List<BoxShadow> _pair(
    Color ink,
    double scale, {
    required Offset o1,
    required double b1,
    double s1 = 0,
    required double a1,
    required Offset o2,
    required double b2,
    double s2 = 0,
    required double a2,
  }) => [
    BoxShadow(
      color: ink.withValues(alpha: (a1 * scale).clamp(0.0, 1.0)),
      offset: o1,
      blurRadius: b1,
      spreadRadius: s1,
    ),
    BoxShadow(
      color: ink.withValues(alpha: (a2 * scale).clamp(0.0, 1.0)),
      offset: o2,
      blurRadius: b2,
      spreadRadius: s2,
    ),
  ];

  static AppShadows _build({
    required Color ink,
    required double scale,
    required Color focusColor,
    required Color glowColor,
  }) {
    return AppShadows._(
      xs: [
        BoxShadow(
          color: ink.withValues(alpha: (0.05 * scale).clamp(0.0, 1.0)),
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
      ],
      sm: _pair(
        ink,
        scale,
        o1: const Offset(0, 1),
        b1: 3,
        a1: 0.08,
        o2: const Offset(0, 1),
        b2: 2,
        s2: -1,
        a2: 0.06,
      ),
      md: _pair(
        ink,
        scale,
        o1: const Offset(0, 4),
        b1: 6,
        s1: -1,
        a1: 0.08,
        o2: const Offset(0, 2),
        b2: 4,
        s2: -2,
        a2: 0.06,
      ),
      lg: _pair(
        ink,
        scale,
        o1: const Offset(0, 10),
        b1: 15,
        s1: -3,
        a1: 0.10,
        o2: const Offset(0, 4),
        b2: 6,
        s2: -4,
        a2: 0.08,
      ),
      xl: _pair(
        ink,
        scale,
        o1: const Offset(0, 20),
        b1: 25,
        s1: -5,
        a1: 0.12,
        o2: const Offset(0, 8),
        b2: 10,
        s2: -6,
        a2: 0.08,
      ),
      focus: [BoxShadow(color: focusColor, spreadRadius: 3)],
      brandGlow: [
        BoxShadow(color: glowColor, offset: const Offset(0, 8), blurRadius: 24),
      ],
    );
  }

  static final AppShadows light = _build(
    ink: AppColors.shadowInk,
    scale: 1,
    focusColor: AppColors.indigo500.withValues(alpha: 0.35),
    glowColor: AppColors.indigo600.withValues(alpha: 0.25),
  );

  static final AppShadows dark = _build(
    ink: Colors.black,
    scale: 2.5,
    focusColor: AppColors.indigo400.withValues(alpha: 0.45),
    glowColor: AppColors.indigo500.withValues(alpha: 0.30),
  );
}
