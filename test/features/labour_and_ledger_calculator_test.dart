import 'package:business_manager/features/accounting/domain/calculators/labour_calculator.dart';
import 'package:business_manager/features/accounting/domain/calculators/ledger_calculator.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const labourCalc = LabourCalculator();
  const ledgerCalc = LedgerCalculator();
  const baseTs = 1795324800000;

  group('LabourCalculator — billing modes & anti-double-counting', () {
    test(
      'default RECEIVED_QTY pays only on RETURN_GOOD (95 x ₹20 = ₹1,900)',
      () {
        final onIssue = labourCalc.planForIssue(
          quantity: 100,
          appliedRatePaise: 2000,
          lockedBillingMode: BillingMode.receivedQty,
        );
        expect(onIssue.isPayable, isFalse);
        expect(onIssue.amountPaise, 200000);

        final onGood = labourCalc.planForSettlement(
          movementType: StockMovementType.returnGood,
          quantity: 95,
          lockedRatePaise: 2000,
          lockedBillingMode: BillingMode.receivedQty,
          lockedIncludeDamaged: false,
        );
        expect(onGood?.isPayable, isTrue);
        expect(onGood?.amountPaise, 190000);

        final onDamaged = labourCalc.planForSettlement(
          movementType: StockMovementType.returnDamaged,
          quantity: 3,
          lockedRatePaise: 2000,
          lockedBillingMode: BillingMode.receivedQty,
          lockedIncludeDamaged: false,
        );
        expect(onDamaged, isNull);

        final onLost = labourCalc.planForSettlement(
          movementType: StockMovementType.settlementLost,
          quantity: 2,
          lockedRatePaise: 2000,
          lockedBillingMode: BillingMode.receivedQty,
          lockedIncludeDamaged: true,
        );
        expect(onLost, isNull);
      },
    );

    test('process override includeDamaged=true includes damaged returns in labour (₹1,960)', () {
      final onGood = labourCalc.planForSettlement(
        movementType: StockMovementType.returnGood,
        quantity: 95,
        lockedRatePaise: 2000,
        lockedBillingMode: BillingMode.receivedQty,
        lockedIncludeDamaged: true,
      );
      final onDamaged = labourCalc.planForSettlement(
        movementType: StockMovementType.returnDamaged,
        quantity: 3,
        lockedRatePaise: 2000,
        lockedBillingMode: BillingMode.receivedQty,
        lockedIncludeDamaged: true,
      );

      // Finalized Rule 1 & Rule 3: legacy includeDamagedInLabour flag is retired
      // and NEVER generates payable earnings for rejected/damaged pieces.
      expect(onGood!.amountPaise, 190000);
      expect(onDamaged, isNull);
    });

    test('retired legacy GIVEN_QTY cannot generate earnings on ISSUE; pays strictly on ACCEPTED return', () {
      final onIssue = labourCalc.planForIssue(
        quantity: 100,
        appliedRatePaise: 2000,
        lockedBillingMode: BillingMode.givenQty,
      );
      expect(onIssue.isPayable, isFalse);

      final onGood = labourCalc.planForSettlement(
        movementType: StockMovementType.returnGood,
        quantity: 80,
        lockedRatePaise: 2000,
        lockedBillingMode: BillingMode.givenQty,
        lockedIncludeDamaged: true,
      );
      expect(onGood?.isPayable, isTrue);
      expect(onGood?.amountPaise, 160000);

      final onDamaged = labourCalc.planForSettlement(
        movementType: StockMovementType.returnDamaged,
        quantity: 5,
        lockedRatePaise: 2000,
        lockedBillingMode: BillingMode.givenQty,
        lockedIncludeDamaged: true,
      );
      expect(onDamaged, isNull);
    });
  });

  group('LedgerCalculator — advances, negative balance & running ledger', () {
    test('tracks full advance lifecycle accurately without treating advance as earned labour', () {
      // Step 1: Worker takes ₹1,000 advance
      final adv = PaymentEntity(
        id: 'pay-adv',
        memberId: 'w-1',
        paymentType: PaymentType.advance,
        amountPaise: 100000,
        paymentMode: PaymentMode.cash,
        transactionAt: baseTs + 1000,
        recordedAt: baseTs + 1000,
        createdAt: baseTs + 1000,
        updatedAt: baseTs + 1000,
      );

      final s1 = ledgerCalc.calculateWorkerSummary(
        workerId: 'w-1',
        workerName: 'Hasmukh Bhai',
        workerIsActive: true,
        labourEntries: const [],
        payments: [adv],
        adjustments: const [],
      );
      expect(s1.earnedLabourPaise, 0);
      expect(s1.advancePaymentsPaise, 100000);
      expect(s1.netBalancePaise, -100000);
      expect(s1.outstandingPayablePaise, 0);
      expect(s1.advanceCreditBalancePaise, 100000);

      // Step 2: Worker earns ₹600 -> Advance Credit drops to ₹400
      final lab1 = LabourEntryEntity(
        id: 'lab-1',
        stockMovementId: 'sm-1',
        memberId: 'w-1',
        processId: 'p-1',
        lotId: 'l-1',
        basisType: LabourBasisType.receivedGood,
        quantity: 30,
        ratePaise: 2000,
        amountPaise: 60000,
        isPayable: true,
        transactionAt: baseTs + 2000,
        recordedAt: baseTs + 2000,
        createdAt: baseTs + 2000,
        updatedAt: baseTs + 2000,
      );
      final s2 = ledgerCalc.calculateWorkerSummary(
        workerId: 'w-1',
        workerName: 'Hasmukh Bhai',
        workerIsActive: true,
        labourEntries: [lab1],
        payments: [adv],
        adjustments: const [],
      );
      expect(s2.netBalancePaise, -40000);
      expect(s2.advanceCreditBalancePaise, 40000);
      expect(s2.outstandingPayablePaise, 0);

      // Step 3: Worker earns ₹1,000 more -> Outstanding Payable = ₹600
      final lab2 = LabourEntryEntity(
        id: 'lab-2',
        stockMovementId: 'sm-2',
        memberId: 'w-1',
        processId: 'p-1',
        lotId: 'l-1',
        basisType: LabourBasisType.receivedGood,
        quantity: 50,
        ratePaise: 2000,
        amountPaise: 100000,
        isPayable: true,
        transactionAt: baseTs + 3000,
        recordedAt: baseTs + 3000,
        createdAt: baseTs + 3000,
        updatedAt: baseTs + 3000,
      );
      final s3 = ledgerCalc.calculateWorkerSummary(
        workerId: 'w-1',
        workerName: 'Hasmukh Bhai',
        workerIsActive: true,
        labourEntries: [lab1, lab2],
        payments: [adv],
        adjustments: const [],
      );
      expect(s3.earnedLabourPaise, 160000);
      expect(s3.netBalancePaise, 60000);
      expect(s3.outstandingPayablePaise, 60000);
      expect(s3.advanceCreditBalancePaise, 0);

      // Verify chronological running balances & date-filtered opening balance
      final ledger = ledgerCalc.buildLedgerLines(
        workerId: 'w-1',
        labourEntries: [lab1, lab2],
        payments: [adv],
        adjustments: const [],
        newestFirst: false,
      );
      expect(ledger.lines.map((l) => l.runningBalancePaise).toList(), [
        -100000,
        -40000,
        60000,
      ]);

      final filtered = ledgerCalc.buildLedgerLines(
        workerId: 'w-1',
        labourEntries: [lab1, lab2],
        payments: [adv],
        adjustments: const [],
        fromUtcMillis: baseTs + 2500,
      );
      expect(filtered.openingBalancePaise, -40000);
      expect(filtered.lines.length, 1);
      expect(filtered.lines.first.runningBalancePaise, 60000);
    });

    test('handles worker adjustments (credit/debit) and payment reversals accurately', () {
      final adjCredit = WorkerAdjustmentEntity(
        id: 'adj-1',
        memberId: 'w-1',
        adjustmentType: WorkerAdjustmentType.credit,
        amountPaise: 25000,
        reason: 'Overtime bonus',
        transactionAt: baseTs + 1000,
        recordedAt: baseTs + 1000,
        createdAt: baseTs + 1000,
        updatedAt: baseTs + 1000,
      );
      final pay = PaymentEntity(
        id: 'pay-1',
        memberId: 'w-1',
        paymentType: PaymentType.regular,
        amountPaise: 25000,
        paymentMode: PaymentMode.upi,
        transactionAt: baseTs + 2000,
        recordedAt: baseTs + 2000,
        createdAt: baseTs + 2000,
        updatedAt: baseTs + 2000,
      );
      final payRev = PaymentEntity(
        id: 'pay-rev-1',
        memberId: 'w-1',
        paymentType: PaymentType.reversal,
        reversesPaymentId: 'pay-1',
        amountPaise: 25000,
        paymentMode: PaymentMode.upi,
        reason: 'UPI failed',
        transactionAt: baseTs + 3000,
        recordedAt: baseTs + 3000,
        createdAt: baseTs + 3000,
        updatedAt: baseTs + 3000,
      );

      final summary = ledgerCalc.calculateWorkerSummary(
        workerId: 'w-1',
        workerName: 'Ravi Bhai',
        workerIsActive: true,
        labourEntries: const [],
        payments: [pay, payRev],
        adjustments: [adjCredit],
      );

      expect(summary.adjustmentCreditsPaise, 25000);
      expect(summary.regularPaymentsPaise, 0);
      expect(summary.outstandingPayablePaise, 25000);
    });
  });
}
