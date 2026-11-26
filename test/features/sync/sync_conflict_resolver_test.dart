import 'package:business_manager/features/sync/domain/services/sync_conflict_resolver.dart';
import 'package:business_manager/features/sync/domain/services/sync_table_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = SyncConflictResolver();

  group('SyncConflictResolver', () {
    test('accepts remote row when no local row exists', () {
      final res = resolver.resolve(
        tableName: 'lots',
        localRow: null,
        remoteRow: {'id': 'l1', 'title': 'Cloud Lot', 'updated_at': 2000},
        hasPendingLocalEdit: false,
      );
      expect(res.winner, ConflictWinner.remote);
      expect(res.hadConflict, isFalse);
    });

    test('preserves local row on append-only tables (conflict-free union)', () {
      final local = {'id': 'sm1', 'quantity': 10, 'updated_at': 1000};
      final remote = {'id': 'sm1', 'quantity': 10, 'updated_at': 2000};
      final res = resolver.resolve(
        tableName: 'stock_movements',
        localRow: local,
        remoteRow: remote,
        hasPendingLocalEdit: true,
      );
      expect(res.winner, ConflictWinner.local);
      expect(res.hadConflict, isFalse);
    });

    test('mutable table keeps strictly newer pending local edit (LWW)', () {
      final local = {'id': 'l1', 'title': 'Local Newer', 'updated_at': 3000};
      final remote = {'id': 'l1', 'title': 'Remote Older', 'updated_at': 2000};
      final res = resolver.resolve(
        tableName: 'lots',
        localRow: local,
        remoteRow: remote,
        hasPendingLocalEdit: true,
      );
      expect(res.winner, ConflictWinner.local);
      expect(res.hadConflict, isTrue);
    });

    test('mutable table lets newer remote edit win and returns superseded diff',
        () {
      final local = {'id': 'l1', 'title': 'Local Older', 'updated_at': 1000};
      final remote = {'id': 'l1', 'title': 'Remote Newer', 'updated_at': 5000};
      final res = resolver.resolve(
        tableName: 'lots',
        localRow: local,
        remoteRow: remote,
        hasPendingLocalEdit: true,
      );
      expect(res.winner, ConflictWinner.remote);
      expect(res.hadConflict, isTrue);
      expect(res.supersededLocalRow, equals(local));
    });
  });

  group('SyncTableRegistry', () {
    test('sorts self-referencing stock_movements parents before children', () {
      final reversal = {
        'id': 'sm-3',
        'parent_issue_id': 'sm-1',
        'reverses_movement_id': 'sm-2',
      };
      final ret = {'id': 'sm-2', 'parent_issue_id': 'sm-1'};
      final issue = {'id': 'sm-1'};

      final sorted = SyncTableRegistry.sortSelfReferencingRows(
        'stock_movements',
        [reversal, ret, issue],
      );
      expect(sorted.map((r) => r['id']).toList(), ['sm-1', 'sm-2', 'sm-3']);
    });

    test('exponential backoff caps at 5 minutes', () {
      expect(SyncTableRegistry.backoffForRetry(1), const Duration(seconds: 5));
      expect(SyncTableRegistry.backoffForRetry(2), const Duration(seconds: 15));
      expect(SyncTableRegistry.backoffForRetry(3), const Duration(seconds: 60));
      expect(SyncTableRegistry.backoffForRetry(4), const Duration(minutes: 5));
      expect(SyncTableRegistry.backoffForRetry(9), const Duration(minutes: 5));
    });
  });
}
