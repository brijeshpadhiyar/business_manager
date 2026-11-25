import 'package:business_manager/features/accounting/domain/calculators/labour_calculator.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/production_history/domain/calculators/production_history_calculator.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/stock_movements/domain/calculators/stock_calculator.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const labourCalc = LabourCalculator();
  const stockCalc = StockCalculator();
  const historyCalc = ProductionHistoryCalculator();

  const t0 = 1795324800000;

  group('Final Worker Payment Rules 1 & 3 — Accepted-Only & Legacy Isolation', () {
    test('legacy GIVEN_QTY and includeDamagedInLabour cannot alter new earnings', () {
      for (final mode in BillingMode.values) {
        final onIssue = labourCalc.planForIssue(
          quantity: 100,
          appliedRatePaise: 1000,
          lockedBillingMode: mode,
        );
        // Informational audit entry only — NEVER payable on ISSUE (Rule 1).
        expect(onIssue.isPayable, isFalse);

        for (final includeDamaged in [false, true]) {
          final onAccepted = labourCalc.planForSettlement(
            movementType: StockMovementType.returnGood,
            quantity: 95,
            lockedRatePaise: 1000,
            lockedBillingMode: mode,
            lockedIncludeDamaged: includeDamaged,
          );
          expect(onAccepted, isNotNull);
          expect(onAccepted!.isPayable, isTrue);
          expect(onAccepted.amountPaise, 95000);

          final onRejected = labourCalc.planForSettlement(
            movementType: StockMovementType.returnDamaged,
            quantity: 5,
            lockedRatePaise: 1000,
            lockedBillingMode: mode,
            lockedIncludeDamaged: includeDamaged,
          );
          expect(onRejected, isNull);
        }
      }
    });

    test('repair re-approval credits ORIGINAL_WORKER at locked rate and ₹0 for IN_HOUSE_FACTORY', () {
      final workerPlan = labourCalc.planForRepairReapproval(
        acceptedQuantity: 3,
        lockedRatePaise: 1000,
        creditOriginalWorker: true,
      );
      expect(workerPlan, isNotNull);
      expect(workerPlan!.isPayable, isTrue);
      expect(workerPlan.amountPaise, 3000);

      final factoryPlan = labourCalc.planForRepairReapproval(
        acceptedQuantity: 3,
        lockedRatePaise: 1000,
        creditOriginalWorker: false,
      );
      expect(factoryPlan, isNull);
    });
  });

  group('Final Rules 2, 4, 5 & 7 — Stock Conservation & Reconciliation', () {
    test('conserves pieces across available, outstanding, pending inspection, damaged, lost, shortage', () {
      final movements = [
        const StockMovementEntity(
          id: 'iss-1',
          lotId: 'lot-1',
          lotDesignId: 'des-1',
          designColourId: 'col-1',
          processId: 'proc-1',
          memberId: 'w-1',
          movementType: StockMovementType.issue,
          quantity: 100,
          appliedRatePaise: 1000,
          isRateOverridden: false,
          lockedBillingMode: BillingMode.receivedQty,
          lockedIncludeDamaged: false,
          transactionAt: t0,
          recordedAt: t0,
          createdAt: t0,
          updatedAt: t0,
        ),
        const StockMovementEntity(
          id: 'ret-g1',
          lotId: 'lot-1',
          lotDesignId: 'des-1',
          designColourId: 'col-1',
          processId: 'proc-1',
          memberId: 'w-1',
          parentIssueId: 'iss-1',
          movementType: StockMovementType.returnGood,
          quantity: 50,
          appliedRatePaise: 1000,
          isRateOverridden: false,
          lockedBillingMode: BillingMode.receivedQty,
          lockedIncludeDamaged: false,
          transactionAt: t0 + 1000,
          recordedAt: t0 + 1000,
          createdAt: t0 + 1000,
          updatedAt: t0 + 1000,
        ),
        const StockMovementEntity(
          id: 'ret-d1',
          lotId: 'lot-1',
          lotDesignId: 'des-1',
          designColourId: 'col-1',
          processId: 'proc-1',
          memberId: 'w-1',
          parentIssueId: 'iss-1',
          movementType: StockMovementType.returnDamaged,
          quantity: 10,
          appliedRatePaise: 1000,
          isRateOverridden: false,
          lockedBillingMode: BillingMode.receivedQty,
          lockedIncludeDamaged: false,
          transactionAt: t0 + 1000,
          recordedAt: t0 + 1000,
          createdAt: t0 + 1000,
          updatedAt: t0 + 1000,
        ),
      ];

      // 25 more pieces returned and currently pending QC inspection.
      final bal = stockCalc.calculateDesignColourBalance(
        designColourId: 'col-1',
        lotId: 'lot-1',
        lotNumber: 'LOT-001',
        lotDesignId: 'des-1',
        designName: 'Kurti-A',
        colourName: 'Navy',
        unitPricePaise: 50000,
        initialQuantity: 100,
        allMovementsForColour: movements,
        pendingInspectionQuantity: 25,
      );

      expect(bal.physicalAvailableInHouse, 50);
      expect(bal.totalPendingInspection, 25);
      expect(bal.totalPendingWithWorkers, 15);
      expect(bal.damagedBucket, 10);
      expect(bal.totalLost, 0);
      expect(bal.totalShortage, 0);
      expect(
        bal.physicalAvailableInHouse +
            bal.totalPendingInspection +
            bal.totalPendingWithWorkers +
            bal.damagedBucket +
            bal.totalLost +
            bal.totalShortage,
        100,
      );
    });

    test('ProductionHistoryCalculator reconciles Lot, Worker, Process & Dashboard identically', () {
      const lot = LotEntity(
        id: 'lot-1',
        lotNumber: 'LOT-001',
        status: LotStatus.active,
        transactionAt: t0,
        recordedAt: t0,
        createdAt: t0,
        updatedAt: t0,
      );
      const design = LotDesignEntity(
        id: 'des-1',
        lotId: 'lot-1',
        designName: 'Kurti-A',
        createdAt: t0,
        updatedAt: t0,
      );
      const colour = DesignColourEntity(
        id: 'col-1',
        lotDesignId: 'des-1',
        colourName: 'Navy',
        initialQuantity: 100,
        unitPricePaise: 50000,
        createdAt: t0,
        updatedAt: t0,
      );

      const issue = StockMovementEntity(
        id: 'iss-1',
        lotId: 'lot-1',
        lotDesignId: 'des-1',
        designColourId: 'col-1',
        processId: 'proc-1',
        memberId: 'w-1',
        movementType: StockMovementType.issue,
        quantity: 100,
        appliedRatePaise: 1000,
        isRateOverridden: false,
        lockedBillingMode: BillingMode.receivedQty,
        lockedIncludeDamaged: false,
        transactionAt: t0 + 1000,
        recordedAt: t0 + 1000,
        createdAt: t0 + 1000,
        updatedAt: t0 + 1000,
      );
      const ret1 = ProductionReturnEntity(
        id: 'pr-1',
        lotId: 'lot-1',
        lotDesignId: 'des-1',
        designColourId: 'col-1',
        processId: 'proc-1',
        memberId: 'w-1',
        parentIssueId: 'iss-1',
        returnedQuantity: 80,
        returnMode: ProductionReturnMode.pendingInspection,
        transactionAt: t0 + 2000,
        recordedAt: t0 + 2000,
        createdAt: t0 + 2000,
        updatedAt: t0 + 2000,
      );
      const insp1 = ProductionInspectionEntity(
        id: 'pi-1',
        lotId: 'lot-1',
        lotDesignId: 'des-1',
        designColourId: 'col-1',
        processId: 'proc-1',
        memberId: 'w-1',
        parentIssueId: 'iss-1',
        productionReturnId: 'pr-1',
        inspectionType: ProductionInspectionType.initial,
        acceptedQuantity: 50,
        rejectedQuantity: 10,
        lockedRatePaise: 1000,
        earnedAmountPaise: 50000,
        creditWorkerEarnings: true,
        linkedGoodMovementId: 'sm-g1',
        linkedDamagedMovementId: 'sm-d1',
        linkedLabourEntryId: 'lab-1',
        authorizedViaPin: true,
        inspectedBy: 'Owner',
        approvedBy: 'Owner',
        transactionAt: t0 + 3000,
        recordedAt: t0 + 3000,
        createdAt: t0 + 3000,
      );
      const smGood = StockMovementEntity(
        id: 'sm-g1',
        lotId: 'lot-1',
        lotDesignId: 'des-1',
        designColourId: 'col-1',
        processId: 'proc-1',
        memberId: 'w-1',
        parentIssueId: 'iss-1',
        movementType: StockMovementType.returnGood,
        quantity: 50,
        appliedRatePaise: 1000,
        isRateOverridden: false,
        lockedBillingMode: BillingMode.receivedQty,
        lockedIncludeDamaged: false,
        transactionAt: t0 + 3000,
        recordedAt: t0 + 3000,
        createdAt: t0 + 3000,
        updatedAt: t0 + 3000,
      );
      const smDamaged = StockMovementEntity(
        id: 'sm-d1',
        lotId: 'lot-1',
        lotDesignId: 'des-1',
        designColourId: 'col-1',
        processId: 'proc-1',
        memberId: 'w-1',
        parentIssueId: 'iss-1',
        movementType: StockMovementType.returnDamaged,
        quantity: 10,
        appliedRatePaise: 1000,
        isRateOverridden: false,
        lockedBillingMode: BillingMode.receivedQty,
        lockedIncludeDamaged: false,
        transactionAt: t0 + 3000,
        recordedAt: t0 + 3000,
        createdAt: t0 + 3000,
        updatedAt: t0 + 3000,
      );
      const labour = LabourEntryEntity(
        id: 'lab-1',
        stockMovementId: 'sm-g1',
        memberId: 'w-1',
        processId: 'proc-1',
        lotId: 'lot-1',
        basisType: LabourBasisType.receivedGood,
        quantity: 50,
        ratePaise: 1000,
        amountPaise: 50000,
        isPayable: true,
        transactionAt: t0 + 3000,
        recordedAt: t0 + 3000,
        createdAt: t0 + 3000,
        updatedAt: t0 + 3000,
      );
      const rej = RejectionRecordEntity(
        id: 'rej-1',
        lotId: 'lot-1',
        lotDesignId: 'des-1',
        designColourId: 'col-1',
        processId: 'proc-1',
        memberId: 'w-1',
        parentIssueId: 'iss-1',
        productionReturnId: 'pr-1',
        inspectionId: 'pi-1',
        stockMovementId: 'sm-d1',
        rejectedQuantity: 10,
        rejectionReason: 'Loose seam',
        status: RejectionStatus.open,
        inspectedAt: t0 + 3000,
        createdAt: t0 + 3000,
        updatedAt: t0 + 3000,
      );
      const payment = PaymentEntity(
        id: 'pay-1',
        memberId: 'w-1',
        paymentType: PaymentType.regular,
        amountPaise: 20000,
        paymentMode: PaymentMode.cash,
        transactionAt: t0 + 4000,
        recordedAt: t0 + 4000,
        createdAt: t0 + 4000,
        updatedAt: t0 + 4000,
      );

      const ds = ProductionHistoryDataset(
        lots: {
          'lot-1': (entity: lot, createdBy: 'Owner', updatedBy: 'Owner'),
        },
        designs: {'des-1': design},
        colours: {'col-1': colour},
        processes: {'proc-1': (name: 'Stitching', isActive: true)},
        workers: {
          'w-1': (
            name: 'Rameshbhai',
            phone: '9876543210',
            address: 'Surat',
            notes: null,
            isActive: true,
            createdAt: t0,
          ),
        },
        movements: [issue, smGood, smDamaged],
        returns: [ret1],
        inspections: [insp1],
        rejections: [rej],
        repairs: [],
        labourEntries: [labour],
        payments: [payment],
        adjustments: [],
        handovers: [],
      );

      final lotHist = historyCalc.buildLotCompleteHistory('lot-1', ds)!;
      final workerProf =
          historyCalc.buildWorkerCompleteProfile('w-1', ds)!;
      final procHist = historyCalc
          .buildAllProcessHistories(ds)
          .firstWhere((p) => p.processId == 'proc-1');
      final dash = historyCalc.buildDashboard(ds);

      // 80 returned, 50 accepted, 10 rejected => 20 still pending inspection, 20 still with worker
      expect(lotHist.totalAssignedQty, 100);
      expect(lotHist.totalReturnedQty, 80);
      expect(lotHist.totalAcceptedQty, 50);
      expect(lotHist.totalRejectedQty, 10);
      expect(lotHist.totalPendingInspectionQty, 20);
      expect(lotHist.totalOutstandingQty, 20);
      expect(lotHist.totalProductionCostPaise, 50000);
      expect(lotHist.isFullyReconciled, isFalse);

      // Exact reconciliation across Worker, Process, Dashboard
      expect(workerProf.assignedQty, lotHist.totalAssignedQty);
      expect(workerProf.returnedQty, lotHist.totalReturnedQty);
      expect(workerProf.acceptedQty, lotHist.totalAcceptedQty);
      expect(workerProf.rejectedQty, lotHist.totalRejectedQty);
      expect(workerProf.pendingInspectionQty, lotHist.totalPendingInspectionQty);
      expect(workerProf.outstandingQty, lotHist.totalOutstandingQty);
      expect(workerProf.financialSummary.earnedLabourPaise, 50000);
      expect(workerProf.financialSummary.regularPaymentsPaise, 20000);
      expect(workerProf.financialSummary.outstandingPayablePaise, 30000);

      expect(procHist.assignedQty, lotHist.totalAssignedQty);
      expect(procHist.acceptedQty, lotHist.totalAcceptedQty);
      expect(procHist.pendingInspectionQty, lotHist.totalPendingInspectionQty);
      expect(procHist.outstandingQty, lotHist.totalOutstandingQty);
      expect(procHist.totalProductionCostPaise, 50000);

      expect(dash.totalAssignedQty, 100);
      expect(dash.totalAcceptedQty, 50);
      expect(dash.totalPendingInspectionQty, 20);
      expect(dash.totalOutstandingQty, 20);
      expect(dash.totalEarnedPaise, 50000);
      expect(dash.totalPaidPaise, 20000);
      expect(dash.totalOutstandingPayablePaise, 30000);
    });
  });
}
