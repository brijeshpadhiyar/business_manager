import 'package:business_manager/features/backup/domain/calculators/data_health_calculator.dart';
import 'package:business_manager/features/backup/domain/entities/data_health_entities.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calc = DataHealthCalculator();

  StockMovementEntity movement({
    required String id,
    required StockMovementType type,
    required int qty,
    String? parentIssueId,
  }) => StockMovementEntity(
    id: id,
    lotId: 'lot-1',
    lotDesignId: 'des-1',
    designColourId: 'col-1',
    processId: 'proc-1',
    memberId: 'mem-1',
    parentIssueId: parentIssueId,
    movementType: type,
    quantity: qty,
    appliedRatePaise: 5000,
    isRateOverridden: false,
    lockedIncludeDamaged: false,
    transactionAt: 1700000000000,
    recordedAt: 1700000000000,
    createdAt: 1700000000000,
    updatedAt: 1700000000000,
  );

  group('DataHealthCalculator', () {
    test('reconciles valid golden stock equation including pending QC', () {
      final issues = calc.evaluateStockReconciliation([
        ColourReconciliationInput(
          designColourId: 'col-1',
          lotId: 'lot-1',
          lotNumber: 'LOT-001',
          lotDesignId: 'des-1',
          designName: 'Kurti',
          colourName: 'Indigo',
          unitPricePaise: 10000,
          initialQuantity: 100,
          pendingInspectionQuantity: 10,
          movements: [
            movement(id: 'm1', type: StockMovementType.issue, qty: 60),
            movement(
              id: 'm2',
              type: StockMovementType.returnGood,
              qty: 20,
              parentIssueId: 'm1',
            ),
            movement(
              id: 'm3',
              type: StockMovementType.returnDamaged,
              qty: 5,
              parentIssueId: 'm1',
            ),
          ],
        ),
      ]);

      expect(issues, isEmpty);
    });

    test('detects negative stock bucket when over-issued', () {
      final issues = calc.evaluateStockReconciliation([
        ColourReconciliationInput(
          designColourId: 'col-1',
          lotId: 'lot-1',
          lotNumber: 'LOT-002',
          lotDesignId: 'des-1',
          designName: 'Saree',
          colourName: 'Emerald',
          unitPricePaise: 10000,
          initialQuantity: 50,
          pendingInspectionQuantity: 0,
          movements: [
            movement(id: 'm1', type: StockMovementType.issue, qty: 75),
          ],
        ),
      ]);

      expect(issues, hasLength(1));
      expect(issues.first.reasonCode, 'NEGATIVE_BUCKET');
      expect(issues.first.availableGoodQty, -25);
    });

    test('computes orphan and missing media paths cleanly', () {
      final parity = calc.evaluateMediaParity(
        referencedRelativePaths: {'lots/l1/a.jpg', 'lots/l1/missing.jpg'},
        storedRelativePaths: {'lots/l1/a.jpg', 'lots/l1/orphan.jpg'},
        hasLocalMediaFilesystem: true,
      );

      expect(parity.orphanPaths, ['lots/l1/orphan.jpg']);
      expect(parity.missingPaths, ['lots/l1/missing.jpg']);
    });

    test('classifies report status accurately and formats export', () {
      final healthy = calc.buildReport(
        checkedAtUtcMillis: 1700000000000,
        schemaVersion: 10,
        sqliteIntegrityOk: true,
        sqliteIntegrityMessages: const ['ok'],
        foreignKeyViolations: const [],
        totalColoursChecked: 4,
        stockIssues: const [],
        ledgerIssues: const [],
        syncOutboxPending: 2,
        syncOutboxFailed: 0,
        syncMediaPending: 0,
        syncMediaFailed: 0,
        orphanMediaPaths: const [],
        missingMediaPaths: const [],
        estimatedDbSizeBytes: 65536,
      );
      expect(healthy.status, DataHealthStatus.healthy);
      final text = calc.formatDiagnosticExport(healthy);
      expect(text, contains('StitchFlow Data Health Diagnostic Report'));
      expect(text, contains('Overall Status: HEALTHY'));

      final warning = calc.buildReport(
        checkedAtUtcMillis: 1700000000000,
        schemaVersion: 10,
        sqliteIntegrityOk: true,
        sqliteIntegrityMessages: const ['ok'],
        foreignKeyViolations: const [],
        totalColoursChecked: 4,
        stockIssues: const [],
        ledgerIssues: const [],
        syncOutboxPending: 1,
        syncOutboxFailed: 1,
        syncMediaPending: 0,
        syncMediaFailed: 0,
        orphanMediaPaths: const [],
        missingMediaPaths: const [],
        estimatedDbSizeBytes: 65536,
      );
      expect(warning.status, DataHealthStatus.warning);
    });
  });
}
