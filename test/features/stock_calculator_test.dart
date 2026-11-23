import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/stock_movements/domain/calculators/stock_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calc = StockCalculator();
  const baseTs = 1795324800000;

  StockMovementEntity mov({
    required String id,
    required StockMovementType type,
    required int qty,
    String? processId = 'proc-cut',
    String? memberId = 'w-1',
    String? parentIssueId,
    String? reversesMovementId,
    int offsetMs = 0,
    String? reason,
  }) {
    return StockMovementEntity(
      id: id,
      lotId: 'lot-1',
      lotDesignId: 'des-1',
      designColourId: 'col-1',
      processId: processId,
      memberId: memberId,
      parentIssueId: parentIssueId,
      reversesMovementId: reversesMovementId,
      movementType: type,
      quantity: qty,
      appliedRatePaise: 2000,
      isRateOverridden: false,
      lockedBillingMode: BillingMode.receivedQty,
      lockedIncludeDamaged: false,
      reason: reason,
      transactionAt: baseTs + offsetMs,
      recordedAt: baseTs + offsetMs,
      createdAt: baseTs + offsetMs,
      updatedAt: baseTs + offsetMs,
    );
  }

  group('StockCalculator — multi-process flow & settlements', () {
    test('supports partial return from Cutting and re-issuing 80 good pcs to Stitching', () {
      final movements = [
        mov(
          id: 'iss-cut',
          type: StockMovementType.issue,
          qty: 100,
          offsetMs: 1000,
        ),
        mov(
          id: 'ret-cut-1',
          type: StockMovementType.returnGood,
          qty: 80,
          parentIssueId: 'iss-cut',
          offsetMs: 2000,
        ),
        mov(
          id: 'iss-stitch',
          type: StockMovementType.issue,
          qty: 80,
          processId: 'proc-stitch',
          memberId: 'w-2',
          offsetMs: 3000,
        ),
      ];

      final balance = calc.calculateDesignColourBalance(
        designColourId: 'col-1',
        lotId: 'lot-1',
        lotNumber: '1001',
        lotDesignId: 'des-1',
        designName: 'Design A',
        colourName: 'Red',
        unitPricePaise: 25000,
        initialQuantity: 100,
        allMovementsForColour: movements,
        processNamesById: const {
          'proc-cut': 'Cutting',
          'proc-stitch': 'Stitching',
        },
      );

      expect(balance.physicalAvailableInHouse, 0);
      expect(balance.totalPendingWithWorkers, 100);
      expect(balance.totalGoodPhysicalStock, 100);
      expect(balance.damagedBucket, 0);

      final cutting = balance.processBreakdown.firstWhere(
        (p) => p.processId == 'proc-cut',
      );
      final stitching = balance.processBreakdown.firstWhere(
        (p) => p.processId == 'proc-stitch',
      );
      expect(cutting.pending, 20);
      expect(cutting.goodReturned, 80);
      expect(stitching.pending, 80);

      // Cannot issue even 1 more piece while 0 available
      expect(
        calc.validateIssueQuantity(
          initialQuantity: 100,
          existingMovementsForColour: movements,
          issueQuantity: 1,
        ),
        'insufficient_good_stock',
      );
    });

    test('handles 95 good + 3 damaged + 2 lost settlement and later repair of 2 damaged pcs', () {
      final movements = [
        mov(
          id: 'iss-1',
          type: StockMovementType.issue,
          qty: 100,
          offsetMs: 1000,
        ),
        mov(
          id: 'ret-good',
          type: StockMovementType.returnGood,
          qty: 95,
          parentIssueId: 'iss-1',
          offsetMs: 2000,
        ),
        mov(
          id: 'ret-dmg',
          type: StockMovementType.returnDamaged,
          qty: 3,
          parentIssueId: 'iss-1',
          reason: 'Needle tear',
          offsetMs: 2001,
        ),
        mov(
          id: 'set-lost',
          type: StockMovementType.settlementLost,
          qty: 2,
          parentIssueId: 'iss-1',
          reason: 'Lost in transit',
          offsetMs: 2002,
        ),
      ];

      final beforeRepair = calc.calculateDesignColourBalance(
        designColourId: 'col-1',
        lotId: 'lot-1',
        lotNumber: '1001',
        lotDesignId: 'des-1',
        designName: 'Design A',
        colourName: 'Red',
        unitPricePaise: 25000,
        initialQuantity: 100,
        allMovementsForColour: movements,
      );

      expect(beforeRepair.totalPendingWithWorkers, 0);
      expect(beforeRepair.physicalAvailableInHouse, 95);
      expect(beforeRepair.damagedBucket, 3);
      expect(beforeRepair.totalLost, 2);
      expect(beforeRepair.totalGoodPhysicalStock, 95);

      // Repair 2 of 3 damaged back to good
      final afterRepairList = [
        ...movements,
        mov(
          id: 'adj-rep',
          type: StockMovementType.adjustmentDamagedToGood,
          qty: 2,
          processId: null,
          memberId: null,
          reason: 'Re-stitched collar',
          offsetMs: 3000,
        ),
      ];

      final afterRepair = calc.calculateDesignColourBalance(
        designColourId: 'col-1',
        lotId: 'lot-1',
        lotNumber: '1001',
        lotDesignId: 'des-1',
        designName: 'Design A',
        colourName: 'Red',
        unitPricePaise: 25000,
        initialQuantity: 100,
        allMovementsForColour: afterRepairList,
      );

      expect(afterRepair.damagedBucket, 1);
      expect(afterRepair.physicalAvailableInHouse, 97);
      expect(afterRepair.totalGoodPhysicalStock, 97);

      // Reject repairing 2 when only 1 damaged remains
      expect(
        calc.validateDamagedToGoodAdjustment(
          initialQuantity: 100,
          existingMovementsForColour: afterRepairList,
          quantity: 2,
          reason: 'Over repair',
        ),
        'exceeds_damaged_stock',
      );
    });

    test('chronological prefix replay blocks reversals that break downstream stock or damaged bucket', () {
      final movements = [
        mov(
          id: 'iss-cut',
          type: StockMovementType.issue,
          qty: 100,
          offsetMs: 1000,
        ),
        mov(
          id: 'ret-cut',
          type: StockMovementType.returnGood,
          qty: 80,
          parentIssueId: 'iss-cut',
          offsetMs: 2000,
        ),
        mov(
          id: 'iss-stitch',
          type: StockMovementType.issue,
          qty: 80,
          processId: 'proc-stitch',
          offsetMs: 3000,
        ),
      ];

      // Cannot reverse ret-cut because iss-stitch depends on those 80 good pcs
      final revReturn = calc.validateReversal(
        initialQuantity: 100,
        allMovementsForColour: movements,
        targetMovementId: 'ret-cut',
        reason: 'Mistake',
      );
      expect(revReturn, isA<StockReversalBlocked>());
      expect(
        (revReturn as StockReversalBlocked).code,
        'downstream_stock_dependency',
      );
      expect(revReturn.blockingMovementId, 'iss-stitch');

      // Cannot reverse parent issue while active child return exists
      final revParent = calc.validateReversal(
        initialQuantity: 100,
        allMovementsForColour: movements,
        targetMovementId: 'iss-cut',
        reason: 'Mistake',
      );
      expect(revParent, isA<StockReversalBlocked>());
      expect(
        (revParent as StockReversalBlocked).code,
        'issue_has_active_settlements',
      );

      // Can reverse leaf movement iss-stitch safely
      final revLeaf = calc.validateReversal(
        initialQuantity: 100,
        allMovementsForColour: movements,
        targetMovementId: 'iss-stitch',
        reason: 'Wrong worker',
      );
      expect(revLeaf, isA<StockReversalAllowed>());
    });

    test(
      'validates settlement over-return and mandatory reason on damaged/lost',
      () {
        final issue = mov(id: 'iss-1', type: StockMovementType.issue, qty: 50);
        expect(
          calc.validateSettlementBatch(
            parentIssue: issue,
            existingMovementsForColour: [issue],
            goodQty: 40,
            damagedQty: 15,
            lostQty: 0,
            shortageQty: 0,
            reason: 'Tear',
          ),
          'exceeds_pending_quantity',
        );
        expect(
          calc.validateSettlementBatch(
            parentIssue: issue,
            existingMovementsForColour: [issue],
            goodQty: 45,
            damagedQty: 5,
            lostQty: 0,
            shortageQty: 0,
            reason: '   ',
          ),
          'reason_required',
        );
      },
    );
  });
}
