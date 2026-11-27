import 'dart:io';

import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/stitch_icons.g.dart';
import 'package:flutter_test/flutter_test.dart';

/// Keeps the icon vocabulary consistent: screens must use the semantic
/// AppIcons registry ("one meaning = one icon"), never raw `Icons.`.
void main() {
  test('no raw Icons.* outside the AppIcons registry', () {
    final offenders = <String>[];
    final pattern = RegExp(r'\bIcons\.[a-zA-Z0-9_]+');
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll(r'\', '/');
      if (path.endsWith('core/design_system/app_icons.dart') ||
          path.contains('/generated/')) {
        continue;
      }
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (pattern.hasMatch(lines[i])) offenders.add('$path:${i + 1}');
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Use AppIcons.<meaning> instead of Icons.* in:\n'
          '${offenders.join('\n')}',
    );
  });

  test('custom StitchIcons glyphs use the bundled font', () {
    expect(StitchIcons.all, isNotEmpty);
    for (final icon in StitchIcons.all.values) {
      expect(icon.fontFamily, 'StitchIcons');
    }
    expect(File('assets/fonts/StitchIcons.ttf').existsSync(), isTrue);
    expect(AppIcons.stockIssue, StitchIcons.stockIssue);
    expect(AppIcons.processIcon('Cutting'), AppIcons.cutting);
    expect(AppIcons.processIcon('Final stitching'), AppIcons.stitching);
    expect(AppIcons.processIcon('Dyeing'), AppIcons.process);
  });
}
