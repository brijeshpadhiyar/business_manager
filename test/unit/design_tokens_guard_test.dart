import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps feature screens on the design tokens in `lib/core/design_system/`
/// (colours, spacing, radius, type) so light/dark mode, density and future
/// re-theming stay consistent, and keeps raw exception text away from users.
void main() {
  /// Rule name → (pattern, what to use instead, files allowed with reason).
  final rules = <String, ({RegExp pattern, String instead, Map<String, String> allowed})>{
    'raw colour': (
      pattern: RegExp(r'\bColors\.(white|black)\w*\b|\bColor\(0x'),
      instead:
          'colorScheme / AppColors.onHero / AppSemanticColors / '
          'AppSurfaceTokens',
      allowed: {
        'lib/features/guidance/presentation/widgets/guide_spotlight_overlay.dart':
            'spotlight scrim and shadow are black by design',
        'lib/features/slips/presentation/widgets/slip_preview_card.dart':
            'print preview of a paper slip',
        'lib/features/lots/presentation/widgets/visual_colour_picker_sheet.dart':
            'the user picks raw colours here',
      },
    ),
    'raw font size': (
      pattern: RegExp(r'fontSize:\s*\d'),
      instead: 'Theme.of(context).textTheme.*',
      allowed: {
        'lib/features/slips/presentation/widgets/slip_preview_card.dart':
            'print preview of a paper slip',
        'lib/features/reports/presentation/widgets/report_trend_chart.dart':
            'chart axis labels drawn on a canvas',
        'lib/features/lots/presentation/pages/lot_detail_page.dart':
            '10sp label inside a small colour swatch',
      },
    ),
    'raw radius': (
      pattern: RegExp(r'BorderRadius\.circular\(\s*\d'),
      instead: 'AppRadius.*Border',
      allowed: {
        'lib/features/slips/presentation/widgets/slip_preview_card.dart':
            'print preview of a paper slip',
        'lib/features/reports/presentation/widgets/report_trend_chart.dart':
            '3dp legend dot sized to the chart, not a surface',
      },
    ),
    'raw SizedBox gap': (
      pattern: RegExp(r'SizedBox\((height|width):\s*\d'),
      instead: 'AppSpacing.*',
      allowed: {
        'lib/features/slips/presentation/widgets/slip_preview_card.dart':
            'print preview of a paper slip',
        'lib/features/lots/presentation/widgets/visual_colour_picker_sheet.dart':
            'fixed-width R/G/B slider label',
      },
    ),
    'raw error text': (
      pattern: RegExp(
        r'showError\(\s*\w+,\s*e\.toString\(\)|= e\.toString\(\);',
      ),
      instead: 'ValidationLocalizer.describeError(l10n, e)',
      allowed: const {},
    ),
  };

  Iterable<(String, List<String>)> presentationFiles() sync* {
    for (final entity in Directory('lib/features').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (!path.contains('/presentation/')) continue;
      if (path.contains('/bloc/')) continue;
      yield (path, entity.readAsLinesSync());
    }
  }

  for (final MapEntry(key: name, value: rule) in rules.entries) {
    test('no $name in feature screens', () {
      final offenders = <String>[];
      for (final (path, lines) in presentationFiles()) {
        if (rule.allowed.containsKey(path)) continue;
        for (var i = 0; i < lines.length; i++) {
          final trimmed = lines[i].trimLeft();
          if (trimmed.startsWith('//') || trimmed.startsWith('*')) continue;
          if (rule.pattern.hasMatch(lines[i])) {
            offenders.add('$path:${i + 1}  ${lines[i].trim()}');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'Use ${rule.instead} instead:\n${offenders.join('\n')}',
      );
    });

    test('$name allowlist entries still exist', () {
      for (final path in rule.allowed.keys) {
        expect(File(path).existsSync(), isTrue, reason: '$path was removed');
      }
    });
  }
}
