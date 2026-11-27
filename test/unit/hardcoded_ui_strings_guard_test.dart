import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'feature presentation layers have zero unintended hardcoded English UI literals',
    () {
      final featuresRoot = Directory('lib/features');
      expect(featuresRoot.existsSync(), isTrue);

      // Checks Text('...'), label: '...', title: '...', subtitle: '...',
      // hint: '...', and tooltip: '...' across every feature's presentation/.
      final uiLiteralPattern = RegExp(
        r'''(?:Text\(\s*(?:const\s+)?['"][A-Za-z]|(?:label|title|subtitle|hint|tooltip):\s*['"][A-Za-z])''',
      );

      // Intentional technical tokens (not user-facing English sentences).
      const allowedTechnicalLines = <String, Set<String>>{
        'lib/features/backup/presentation/pages/data_health_page.dart': {
          "label: 'v\${report.schemaVersion}',",
        },
        'lib/features/lots/presentation/widgets/visual_colour_picker_sheet.dart': {
          "label: 'R',",
          "label: 'G',",
          "label: 'B',",
        },
        'lib/features/security/presentation/pages/pin_recovery_page.dart': {
          "hint: 'XXXX-XXXX',",
        },
      };

      final violations = <String>[];
      for (final entity in featuresRoot.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final relPath = entity.path.replaceAll('\\', '/');
        if (!relPath.contains('/presentation/')) continue;

        final allowedForFile = allowedTechnicalLines[relPath] ?? const <String>{};
        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.trimLeft().startsWith('//')) continue;
          if (!uiLiteralPattern.hasMatch(line)) continue;
          if (allowedForFile.contains(line.trim())) continue;
          violations.add('$relPath:${i + 1}: ${line.trim()}');
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Hardcoded English UI strings found in presentation layers:\n'
            '${violations.join('\n')}',
      );
    },
  );
}
