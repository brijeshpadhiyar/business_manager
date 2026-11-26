import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('process_routing presentation has zero hardcoded English UI literals', () {
    final dir = Directory('lib/features/process_routing/presentation');
    expect(dir.existsSync(), isTrue);

    final uiLiteralPattern = RegExp(
      r'''(?:Text\(\s*(?:const\s+)?['"][A-Za-z]|(?:label|title|subtitle|hint|tooltip):\s*['"][A-Za-z])''',
    );

    final violations = <String>[];
    for (final entity in dir.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('//') || line.startsWith('///')) continue;
        if (uiLiteralPattern.hasMatch(line)) {
          violations.add('${entity.path}:${i + 1}: $line');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason:
          'Hardcoded English UI strings found in process_routing/presentation:\n${violations.join('\n')}',
    );
  });
}
