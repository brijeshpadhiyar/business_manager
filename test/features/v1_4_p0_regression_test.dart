// v1.4 Phase 0 safety net: one regression test per P0 finding in the v1.3
// system audit, plus the golden stock reconciliation rule. Each test states
// the CORRECT behaviour; it failed on v1.3 and must pass from v1.4 onwards.

import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/reports/domain/entities/report_filter.dart';
import 'package:drift/drift.dart' show Variable;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/v14_fixture.dart';

void main() {
  late V14Fixture f;

  setUpAll(IstDateTimeHelper.initialize);

  setUp(() async {
    f = await V14Fixture.create();
  });

  tearDown(() => f.dispose());

  group('P0-1 one production engine: Routing reads Stock', () {
    test('settling in Stock clears pending in Routing', () async {
      final jp = await f.routingRepo.addJobProcess(
        lotId: f.lot.id,
        designColourId: f.colourId,
        processId: f.stitching.id,
        workerId: f.ramesh.id,
        quantity: 100,
        transactionAtUtcMillis: v14BaseTs,
      );
      await f.stockRepo.recordSettlement(
        parentIssueId: jp.linkedIssueMovementId!,
        goodQuantity: 100,
        damagedQuantity: 0,
        lostQuantity: 0,
        shortageQuantity: 0,
        transactionAtUtcMillis: v14BaseTs + 1000,
      );

      final overview = (await f.routingRepo.getJobRoutingOverview(f.lot.id))!;
      final row = overview.jobProcesses.single;
      expect(row.pendingQuantity, 0);
      expect(overview.currentLocations.where((l) => !l.isFactory), isEmpty);
      final factory = overview.currentLocations.where((l) => l.isFactory);
      expect(factory.fold<int>(0, (s, l) => s + l.quantity), 100);
      expectReconciled(await f.balance());
    });

    test('reversing a Stock settlement puts pieces back with the worker in Routing', () async {
      final jp = await f.routingRepo.addJobProcess(
        lotId: f.lot.id,
        designColourId: f.colourId,
        processId: f.stitching.id,
        workerId: f.ramesh.id,
        quantity: 100,
        transactionAtUtcMillis: v14BaseTs,
      );
      final batch = await f.stockRepo.recordSettlement(
        parentIssueId: jp.linkedIssueMovementId!,
        goodQuantity: 30,
        damagedQuantity: 0,
        lostQuantity: 0,
        shortageQuantity: 0,
        transactionAtUtcMillis: v14BaseTs + 1000,
      );
      await f.stockRepo.reverseMovement(
        movementId: batch.createdMovements.single.id,
        reason: 'Entered by mistake',
        transactionAtUtcMillis: v14BaseTs + 2000,
      );
      final overview = (await f.routingRepo.getJobRoutingOverview(f.lot.id))!;
      expect(overview.jobProcesses.single.pendingQuantity, 100);
    });
  });

  group('P0-2 charges and deductions go through the worker ledger', () {
    test(
      'extra charge credits and deduction debits the worker balance',
      () async {
        final jp = await f.routingRepo.addJobProcess(
          lotId: f.lot.id,
          designColourId: f.colourId,
          processId: f.stitching.id,
          workerId: f.ramesh.id,
          quantity: 10,
          transactionAtUtcMillis: v14BaseTs,
        );
        final before = await f.netBalancePaise(f.ramesh.id);
        await f.routingRepo.addAdditionalCharge(
          jobProcessId: jp.id,
          chargeType: ProcessChargeType.extraCharge,
          description: 'Urgent work',
          amountPaise: 5000,
          transactionAtUtcMillis: v14BaseTs + 1000,
        );
        expect(await f.netBalancePaise(f.ramesh.id), before + 5000);

        await f.routingRepo.addAdditionalCharge(
          jobProcessId: jp.id,
          chargeType: ProcessChargeType.deduction,
          description: 'Thread wastage',
          amountPaise: 2000,
          transactionAtUtcMillis: v14BaseTs + 2000,
        );
        expect(await f.netBalancePaise(f.ramesh.id), before + 3000);
      },
    );
  });

  group('P0-3 routing payable follows accepted quantity', () {
    test('payable = accepted qty x per-piece rate, not planned qty', () async {
      final jp = await f.routingRepo.addJobProcess(
        lotId: f.lot.id,
        designColourId: f.colourId,
        processId: f.stitching.id,
        workerId: f.ramesh.id,
        quantity: 100,
        transactionAtUtcMillis: v14BaseTs,
      );
      await f.stockRepo.recordSettlement(
        parentIssueId: jp.linkedIssueMovementId!,
        goodQuantity: 60,
        damagedQuantity: 40,
        lostQuantity: 0,
        shortageQuantity: 0,
        reason: 'Stitch defects',
        transactionAtUtcMillis: v14BaseTs + 1000,
      );
      final overview = (await f.routingRepo.getJobRoutingOverview(f.lot.id))!;
      expect(overview.jobProcesses.single.payableAmountPaise, 60 * 1000);
      expect(overview.costSummary.totalBasePaise, 60 * 1000);
      expect(await f.earnedPaise(f.ramesh.id), 60 * 1000);
    });
  });

  group('P0-4 multi-batch dispatch', () {
    test('pieces from every dispatch batch can be returned', () async {
      final jp = await f.routingRepo.addJobProcess(
        lotId: f.lot.id,
        designColourId: f.colourId,
        processId: f.stitching.id,
        workerId: f.ramesh.id,
        quantity: 50,
        transactionAtUtcMillis: v14BaseTs,
      );
      await f.routingRepo.dispatchJobProcess(
        jobProcessId: jp.id,
        quantity: 50,
        transactionAtUtcMillis: v14BaseTs + 1000,
      );
      await f.routingRepo.returnToFactory(
        sourceJobProcessId: jp.id,
        goodQuantity: 100,
        transactionAtUtcMillis: v14BaseTs + 2000,
      );
      final overview = (await f.routingRepo.getJobRoutingOverview(f.lot.id))!;
      expect(overview.jobProcesses.single.pendingQuantity, 0);
      expect(await f.earnedPaise(f.ramesh.id), 100 * 1000);
      expectReconciled(await f.balance());
    });
  });

  group('P0-5 createLotComplete converts pricing unit', () {
    test('PER_DOZEN agreed rate is locked as a per-piece rate', () async {
      final lot = await f.lotRepo.createLotComplete(
        lotNumber: 'LOT-DOZEN',
        transactionAtUtcMillis: v14BaseTs,
        designs: const [
          LotDesignDraftInput(
            designName: 'D-2',
            colours: [
              LotColourDraftInput(
                colourName: 'Blue',
                initialQuantity: 24,
                unitPricePaise: 1000,
              ),
            ],
          ),
        ],
        initialAssignments: [
          InitialLotProcessAssignmentInput(
            designName: 'D-2',
            colourName: 'Blue',
            processId: f.stitching.id,
            workerId: f.ramesh.id,
            quantity: 24,
            agreedRatePaise: 12000,
            pricingUnit: 'PER_DOZEN',
            rateOverrideReason: 'Dozen rate',
          ),
        ],
      );
      final issues = await f.stockRepo.getOpenIssues(lotId: lot.id);
      expect(issues.single.issueView.movement.appliedRatePaise, 1000);

      final hist = (await f.historyRepo.getLotCompleteHistory(lot.id))!;
      await f.stockRepo.recordSettlement(
        parentIssueId: hist.assignments.single.issueMovementId,
        goodQuantity: 24,
        damagedQuantity: 0,
        lostQuantity: 0,
        shortageQuantity: 0,
        transactionAtUtcMillis: v14BaseTs + 1000,
      );
      expect(await f.earnedPaise(f.ramesh.id), 24 * 1000);
    });
  });

  group('P0-6 pending-QC pieces are counted once everywhere', () {
    test(
      'dashboard, advanced and lot reports reconcile with pending QC',
      () async {
        final issue = await f.issue(100);
        await f.historyRepo.recordProductionReturn(
          parentIssueId: issue.id,
          returnedQuantity: 40,
          transactionAtUtcMillis: v14BaseTs + 1000,
        );

        final b = await f.balance();
        expect(b.totalPendingInspection, 40);
        expect(b.totalPendingWithWorkers, 60);
        expectReconciled(b);

        final dash = await f.reportsRepo.getDashboardSnapshot();
        expect(dash.pendingWorkerStock, 60);
        expect(dash.pendingInspectionStock, 40);
        expect(
          dash.availableGoodStock +
              dash.pendingWorkerStock +
              dash.pendingInspectionStock +
              dash.damagedStock +
              dash.lostStock +
              dash.shortageStock,
          dash.totalInitialStock,
        );

        final adv = await f.reportsRepo.getAdvancedReports(
          const ReportFilter(preset: ReportDatePreset.allTime),
        );
        expect(adv.currentTotalPendingQty, 60);
        expect(adv.currentTotalPendingInspectionQty, 40);
        expect(adv.inventory.pendingWithWorkers, 60);
        expect(adv.inventory.pendingInspection, 40);
        final w = adv.workerPerformance.firstWhere(
          (r) => r.workerId == f.ramesh.id,
        );
        expect(w.currentPendingQty, 60);
        expect(w.currentPendingInspectionQty, 40);
        final lotRow = adv.inventory.lotRows.single;
        expect(lotRow.pendingWithWorkers, 60);
        expect(lotRow.pendingInspection, 40);

        final biz = await f.reportsRepo.getBusinessReports();
        final bizLot = biz.lotRows.single;
        expect(bizLot.pendingWithWorkers, 60);
        expect(bizLot.pendingInspection, 40);
      },
    );
  });

  group('P0-7 reversal and repair guards', () {
    test('an ISSUE with pieces waiting for QC cannot be reversed', () async {
      final issue = await f.issue(100);
      await f.historyRepo.recordProductionReturn(
        parentIssueId: issue.id,
        returnedQuantity: 40,
        transactionAtUtcMillis: v14BaseTs + 1000,
      );
      await expectLater(
        f.stockRepo.reverseMovement(
          movementId: issue.id,
          reason: 'Wrong worker',
          transactionAtUtcMillis: v14BaseTs + 2000,
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'pending_inspection_exists',
          ),
        ),
      );
      expectReconciled(await f.balance());
    });

    test(
      'the two repair flows cannot repair the same damaged pieces twice',
      () async {
        final issue = await f.issue(100);
        final ret = await f.historyRepo.recordProductionReturn(
          parentIssueId: issue.id,
          returnedQuantity: 100,
          transactionAtUtcMillis: v14BaseTs + 1000,
          inspectImmediately: true,
          acceptedQuantity: 90,
          rejectedQuantity: 10,
          rejectionReason: 'Torn seam',
        );
        final rejection = ret.immediateInspection!;
        expect((await f.balance()).damagedBucket, 10);

        // Flow A: generic damaged -> good adjustment.
        await f.stockRepo.recordDamagedToGoodAdjustment(
          designColourId: f.colourId,
          quantity: 10,
          reason: 'Repaired in house',
          transactionAtUtcMillis: v14BaseTs + 2000,
        );
        expect((await f.balance()).damagedBucket, 0);

        // Flow B: rejection repair + re-inspection for the same 10 pieces.
        final rejections = await f.historyRepo.getRejectionRecords();
        final rejRecord = rejections.firstWhere(
          (r) => r.record.inspectionId == rejection.id,
        );
        await expectLater(() async {
          final repair = await f.historyRepo.recordRejectionRepair(
            rejectionRecordId: rejRecord.record.id,
            repairedQuantity: 10,
            repairSource: RepairSource.inHouse,
            transactionAtUtcMillis: v14BaseTs + 3000,
          );
          await f.historyRepo.approveRepairReinspection(
            rejectionRepairId: repair.id,
            acceptedQuantity: 10,
            rejectedAgainQuantity: 0,
            transactionAtUtcMillis: v14BaseTs + 4000,
          );
        }(), throwsA(isA<DomainValidationException>()));
        expectReconciled(await f.balance());
      },
    );
  });

  group('P0-12 legacy GIVEN_QTY issue is not paid twice', () {
    test('settlement earns nothing when the ISSUE already paid labour', () async {
      final issue = await f.issue(100);
      // Simulate a pre-v1.2 issue: GIVEN_QTY locked and payable labour at issue.
      await f.db.customStatement(
        "UPDATE stock_movements SET locked_billing_mode = 'GIVEN_QTY' WHERE id = ?",
        [issue.id],
      );
      await f.db.customStatement(
        'UPDATE labour_entries SET is_payable = 1 WHERE stock_movement_id = ?',
        [issue.id],
      );
      final rows = await f.db
          .customSelect(
            'SELECT amount_paise FROM labour_entries WHERE stock_movement_id = ?',
            variables: [Variable.withString(issue.id)],
          )
          .get();
      expect(rows.single.read<int>('amount_paise'), 100 * 1000);
      expect(await f.earnedPaise(f.ramesh.id), 100 * 1000);

      await f.stockRepo.recordSettlement(
        parentIssueId: issue.id,
        goodQuantity: 100,
        damagedQuantity: 0,
        lostQuantity: 0,
        shortageQuantity: 0,
        transactionAtUtcMillis: v14BaseTs + 1000,
      );
      expect(await f.earnedPaise(f.ramesh.id), 100 * 1000);
    });
  });

  group('Golden reconciliation', () {
    test(
      'every piece is in exactly one bucket through a full mixed flow',
      () async {
        final a = await f.issue(60);
        expectReconciled(await f.balance());
        final b = await f.issue(30, workerId: f.suresh.id, offsetMs: 10);
        expectReconciled(await f.balance());

        await f.stockRepo.recordSettlement(
          parentIssueId: a.id,
          goodQuantity: 20,
          damagedQuantity: 5,
          lostQuantity: 2,
          shortageQuantity: 3,
          reason: 'Mixed',
          transactionAtUtcMillis: v14BaseTs + 1000,
        );
        expectReconciled(await f.balance());

        await f.historyRepo.recordProductionReturn(
          parentIssueId: b.id,
          returnedQuantity: 25,
          transactionAtUtcMillis: v14BaseTs + 2000,
        );
        expectReconciled(await f.balance());

        final pending = await f.historyRepo.getPendingReturns();
        await f.historyRepo.approveReturnInspection(
          productionReturnId: pending.single.productionReturn.id,
          acceptedQuantity: 20,
          rejectedQuantity: 5,
          rejectionReason: 'Stains',
          transactionAtUtcMillis: v14BaseTs + 3000,
        );
        final bal = await f.balance();
        expectReconciled(bal);
        expect(bal.damagedBucket, 10);
        expect(bal.totalPendingWithWorkers, 30 + 5);
      },
    );
  });
}
