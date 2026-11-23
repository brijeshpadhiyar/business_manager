import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/reports/domain/calculators/workshop_daily_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    IstDateTimeHelper.initialize();
  });

  const calc = WorkshopDailyCalculator();

  StockMovementEntity makeMove({
    required String id,
    required StockMovementType type,
    required int qty,
    required int txAt,
    String colourId = 'c1',
    String? processId = 'p1',
    String? workerId = 'w1',
    String? parentIssueId,
    String? reversesId,
  }) {
    return StockMovementEntity(
      id: id,
      lotId: 'l1',
      lotDesignId: 'd1',
      designColourId: colourId,
      processId: processId,
      memberId: workerId,
      parentIssueId: parentIssueId,
      reversesMovementId: reversesId,
      movementType: type,
      quantity: qty,
      appliedRatePaise: 2000,
      isRateOverridden: false,
      lockedIncludeDamaged: false,
      transactionAt: txAt,
      recordedAt: txAt,
      createdAt: txAt,
      updatedAt: txAt,
    );
  }

  test('calculateDailySummary respects Asia/Kolkata boundaries and excludes reversals', () {
    // Nov 22 23:55 IST vs Nov 23 00:05 IST
    final nov22Late = IstDateTimeHelper.istDateTimeToUtcMillis(
      year: 2026,
      month: 11,
      day: 22,
      hour: 23,
      minute: 55,
    );
    final nov23Early = IstDateTimeHelper.istDateTimeToUtcMillis(
      year: 2026,
      month: 11,
      day: 23,
      hour: 0,
      minute: 5,
    );
    final nov23Noon = IstDateTimeHelper.istDateTimeToUtcMillis(
      year: 2026,
      month: 11,
      day: 23,
      hour: 12,
      minute: 0,
    );

    final moves = [
      makeMove(
        id: 'm_prev',
        type: StockMovementType.issue,
        qty: 50,
        txAt: nov22Late,
      ),
      makeMove(
        id: 'm_today_issue',
        type: StockMovementType.issue,
        qty: 40,
        txAt: nov23Early,
      ),
      makeMove(
        id: 'm_today_rev_issue',
        type: StockMovementType.issue,
        qty: 99,
        txAt: nov23Early,
      ),
      makeMove(
        id: 'm_today_reversal',
        type: StockMovementType.reversal,
        qty: 99,
        txAt: nov23Noon,
        reversesId: 'm_today_rev_issue',
      ),
      makeMove(
        id: 'm_today_good',
        type: StockMovementType.returnGood,
        qty: 30,
        txAt: nov23Noon,
        parentIssueId: 'm_today_issue',
      ),
      makeMove(
        id: 'm_today_dmg',
        type: StockMovementType.returnDamaged,
        qty: 2,
        txAt: nov23Noon,
        parentIssueId: 'm_today_issue',
      ),
    ];

    final labour = [
      LabourEntryEntity(
        id: 'lab1',
        stockMovementId: 'm_today_good',
        memberId: 'w1',
        processId: 'p1',
        lotId: 'l1',
        basisType: LabourBasisType.receivedGood,
        quantity: 30,
        ratePaise: 2000,
        amountPaise: 60000,
        isPayable: true,
        transactionAt: nov23Noon,
        recordedAt: nov23Noon,
        createdAt: nov23Noon,
        updatedAt: nov23Noon,
      ),
      LabourEntryEntity(
        id: 'lab_info',
        stockMovementId: 'm_today_issue',
        memberId: 'w1',
        processId: 'p1',
        lotId: 'l1',
        basisType: LabourBasisType.issued,
        quantity: 40,
        ratePaise: 2000,
        amountPaise: 80000,
        isPayable: false,
        transactionAt: nov23Early,
        recordedAt: nov23Early,
        createdAt: nov23Early,
        updatedAt: nov23Early,
      ),
    ];

    final payments = [
      PaymentEntity(
        id: 'pay1',
        memberId: 'w1',
        paymentType: PaymentType.regular,
        amountPaise: 25000,
        paymentMode: PaymentMode.cash,
        transactionAt: nov23Noon,
        recordedAt: nov23Noon,
        createdAt: nov23Noon,
        updatedAt: nov23Noon,
      ),
    ];

    final summary = calc.calculateDailySummary(
      targetDayUtcMillis: nov23Noon,
      allMovements: moves,
      allLabourEntries: labour,
      allPayments: payments,
      processNamesById: const {'p1': 'Stitching'},
      workerNamesById: const {'w1': 'Ramesh'},
      currentTotalPendingQty: 58,
      currentTotalDamagedQty: 2,
      currentTotalOutstandingPayablePaise: 35000,
    );

    expect(summary.istDateIso, '2026-11-23');
    expect(summary.issuedQty, 40); // Excludes Nov 22 late & reversed 99
    expect(summary.goodReturnedQty, 30);
    expect(summary.damagedQty, 2);
    expect(summary.labourEarnedPaise, 60000); // Only isPayable == true
    expect(summary.netPaymentsPaise, 25000);
    expect(summary.processActivities.length, 1);
    expect(summary.workerActivities.length, 1);
    expect(summary.workerActivities.first.workerName, 'Ramesh');
  });

  test('deriveRecentIssueSuggestions filters out inactive, unassigned, reversed, and out-of-stock', () {
    final t1 = IstDateTimeHelper.istDateTimeToUtcMillis(
      year: 2026,
      month: 11,
      day: 20,
    );
    final t2 = t1 + 1000;
    final t3 = t2 + 1000;
    final t4 = t3 + 1000;

    final moves = [
      makeMove(
        id: 'i1',
        type: StockMovementType.issue,
        qty: 10,
        txAt: t1,
        colourId: 'c_in_stock',
        processId: 'p_active',
        workerId: 'w_active',
      ),
      makeMove(
        id: 'i2',
        type: StockMovementType.issue,
        qty: 10,
        txAt: t2,
        colourId: 'c_out',
        processId: 'p_inactive',
        workerId: 'w_active',
      ),
      makeMove(
        id: 'i3',
        type: StockMovementType.issue,
        qty: 10,
        txAt: t3,
        colourId: 'c_in_stock',
        processId: 'p_active',
        workerId: 'w_unassigned',
      ),
      makeMove(
        id: 'i4',
        type: StockMovementType.issue,
        qty: 10,
        txAt: t4,
        colourId: 'c_in_stock2',
        processId: 'p_active',
        workerId: 'w_active',
      ),
      makeMove(
        id: 'r4',
        type: StockMovementType.reversal,
        qty: 10,
        txAt: t4 + 10,
        reversesId: 'i4',
      ),
    ];

    final suggestions = calc.deriveRecentIssueSuggestions(
      allMovements: moves,
      activeProcessIds: const {'p_active'},
      activeWorkerIds: const {'w_active', 'w_unassigned'},
      activeAssignmentKeys: const {'w_active::p_active'},
      processNamesById: const {'p_active': 'Cutting'},
      workerNamesById: const {'w_active': 'Hasmukh'},
      inStockColourIds: const {'c_in_stock', 'c_in_stock2'},
    );

    expect(suggestions.workPairs.length, 1);
    expect(suggestions.workPairs.first.workerName, 'Hasmukh');
    expect(suggestions.inStockDesignColourIds, ['c_in_stock']);
  });

  test('pendingAgeDays counts exact IST calendar days', () {
    final day1 = IstDateTimeHelper.istDateTimeToUtcMillis(
      year: 2026,
      month: 11,
      day: 19,
      hour: 22,
    );
    final day2 = IstDateTimeHelper.istDateTimeToUtcMillis(
      year: 2026,
      month: 11,
      day: 23,
      hour: 9,
    );
    expect(WorkshopDailyCalculator.pendingAgeDays(day1, day2), 4);
  });
}
