import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final featuresRoot = Directory('lib/features');

  test(
    'domain layer files stay pure Dart with no Flutter, Drift, or Data imports',
    () {
      expect(featuresRoot.existsSync(), isTrue);

      final forbiddenPatterns = <(String label, RegExp pattern)>[
        ('package:flutter', RegExp(r'''package:flutter/''')),
        ('package:flutter_bloc', RegExp(r'''package:flutter_bloc/''')),
        ('package:drift', RegExp(r'''package:drift/''')),
        ('AppDatabase import', RegExp(r'''core/database/app_database\.dart''')),
        ('core/database/migrations import', RegExp(r'''core/database/migrations/''')),
        ('core/database/daos import', RegExp(r'''core/database/daos/''')),
        ('feature data layer import', RegExp(r'''features/[^/]+/data/''')),
      ];

      final violations = <String>[];
      for (final entity in featuresRoot.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final relPath = entity.path.replaceAll('\\', '/');
        if (!relPath.contains('/domain/')) continue;

        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trimLeft();
          if (!line.startsWith('import ') && !line.startsWith('export ')) {
            continue;
          }
          for (final (label, pattern) in forbiddenPatterns) {
            if (pattern.hasMatch(line)) {
              violations.add('$relPath:${i + 1} [$label] -> $line');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Domain layer must remain framework-independent pure Dart:\n'
            '${violations.join('\n')}',
      );
    },
  );

  test(
    'presentation layer files do not directly import Drift, DAOs, AppDatabase, Supabase SDK, or SyncEngine',
    () {
      expect(featuresRoot.existsSync(), isTrue);

      final forbiddenPatterns = <(String label, RegExp pattern)>[
        ('package:drift', RegExp(r'''package:drift/''')),
        ('AppDatabase import', RegExp(r'''core/database/app_database\.dart''')),
        ('core/database/daos import', RegExp(r'''core/database/daos/''')),
        ('package:supabase_flutter', RegExp(r'''package:supabase_flutter/''')),
        ('SyncEngine import', RegExp(r'''features/sync/data/services/sync_engine\.dart''')),
      ];

      final violations = <String>[];
      for (final entity in featuresRoot.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        final relPath = entity.path.replaceAll('\\', '/');
        if (!relPath.contains('/presentation/')) continue;

        final lines = entity.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trimLeft();
          if (!line.startsWith('import ')) continue;
          for (final (label, pattern) in forbiddenPatterns) {
            if (pattern.hasMatch(line)) {
              violations.add('$relPath:${i + 1} [$label] -> $line');
            }
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Presentation layer must talk through repositories/cubits instead '
            'of importing DB/Sync internals directly:\n${violations.join('\n')}',
      );
    },
  );
}
