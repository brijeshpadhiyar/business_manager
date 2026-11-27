import 'dart:math' as math;

import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG 2.x contrast checks for the colour pairs the app draws text with, in
/// light and dark mode. Body text needs 4.5:1; large or bold text (titles,
/// hero numbers) needs 3:1.
void main() {
  double luminance(Color c) {
    double channel(double v) => v <= 0.03928
        ? v / 12.92
        : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * channel(c.r) +
        0.7152 * channel(c.g) +
        0.0722 * channel(c.b);
  }

  double contrast(Color a, Color b) {
    final la = luminance(a);
    final lb = luminance(b);
    final hi = math.max(la, lb);
    final lo = math.min(la, lb);
    return (hi + 0.05) / (lo + 0.05);
  }

  for (final (name, theme) in [
    ('light', AppTheme.light()),
    ('dark', AppTheme.dark()),
  ]) {
    group('$name theme', () {
      final s = theme.colorScheme;
      final sem = theme.extension<AppSemanticColors>()!;

      final bodyPairs = <String, (Color, Color)>{
        'onSurface / surface': (s.onSurface, s.surface),
        'onSurfaceVariant / surface': (s.onSurfaceVariant, s.surface),
        'onPrimary / primary': (s.onPrimary, s.primary),
        'onPrimaryContainer / primaryContainer': (
          s.onPrimaryContainer,
          s.primaryContainer,
        ),
        'onSecondaryContainer / secondaryContainer': (
          s.onSecondaryContainer,
          s.secondaryContainer,
        ),
        'onError / error': (s.onError, s.error),
        'onErrorContainer / errorContainer': (
          s.onErrorContainer,
          s.errorContainer,
        ),
        'primary text / surface': (s.primary, s.surface),
        'error text / surface': (s.error, s.surface),
        'good badge': (sem.goodStock, sem.goodStockContainer),
        'pending badge': (sem.pending, sem.pendingContainer),
        'damaged badge': (sem.damaged, sem.damagedContainer),
        'advance badge': (sem.advanceCredit, sem.advanceCreditContainer),
      };

      for (final MapEntry(key: label, value: (fg, bg)) in bodyPairs.entries) {
        test('$label ≥ 4.5:1', () {
          final ratio = contrast(fg, bg);
          expect(
            ratio,
            greaterThanOrEqualTo(4.5),
            reason: '$label is ${ratio.toStringAsFixed(2)}:1',
          );
        });
      }

      test('hero text ≥ 3:1 on every gradient stop (large/bold text)', () {
        final gradient = name == 'light'
            ? AppColors.heroGradientLight
            : AppColors.heroGradientDark;
        for (final stop in gradient.colors) {
          final ratio = contrast(AppColors.onHero, stop);
          expect(
            ratio,
            greaterThanOrEqualTo(3.0),
            reason: 'onHero on $stop is ${ratio.toStringAsFixed(2)}:1',
          );
        }
      });
    });
  }
}
