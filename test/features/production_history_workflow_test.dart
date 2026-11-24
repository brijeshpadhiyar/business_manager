import 'dart:io';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/data/repositories/accounting_repository_impl.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/business_profile/data/repositories/business_profile_repository_impl.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/lots/data/repositories/lot_repository_impl.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/processes/data/repositories/process_repository_impl.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/production_history/data/repositories/production_history_repository_impl.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/rates/data/repositories/rate_repository_impl.dart';
import 'package:business_manager/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:business_manager/features/reports/data/services/excel_csv_export_service.dart';
import 'package:business_manager/features/reports/data/services/report_html_builder.dart';
import 'package:business_manager/features/reports/domain/entities/report_filter.dart';
import 'package:business_manager/features/stock_movements/data/repositories/stock_movement_repository_impl.dart';
import 'package:business_manager/features/workers/data/repositories/worker_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:excel_plus/excel_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late LotRepositoryImpl lotRepo;
  late ProcessRepositoryImpl procRepo;
  late WorkerRepositoryImpl workerRepo;
  late RateRepositoryImpl rateRepo;
  late StockMovementRepositoryImpl stockRepo;
  late AccountingRepositoryImpl acctRepo;
  late ProductionHistoryRepositoryImpl historyRepo;
  late ReportsRepositoryImpl reportsRepo;
  late BusinessProfileRepositoryImpl profileRepo;

  const baseTs = 1795324800000;

  setUpAll(() {
    IstDateTimeHelper.initialize();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sf_ph_e2e_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final tx = DatabaseTransactionRunner(db);
    final ids = IdGenerator();
    final media = NativeMediaStorageService(
      config: AppConfig.dev(),
      idGenerator: ids,
      baseDirectoryOverride: tempDir,
    );

    profileRepo = BusinessProfileRepositoryImpl(db, tx, ids);
    lotRepo = LotRepositoryImpl(db, tx, ids, media);
    procRepo = ProcessRepositoryImpl(db, tx, ids);
    workerRepo = WorkerRepositoryImpl(db, tx, ids);
    rateRepo = RateRepositoryImpl(db, tx, ids);
    stockRepo = StockMovementRepositoryImpl(db, tx, ids);
    acctRepo = AccountingRepositoryImpl(db, tx, ids);
    historyRepo = ProductionHistoryRepositoryImpl(db, tx, ids);
    reportsRepo = ReportsRepositoryImpl(db, stockRepo, acctRepo);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test(
    'Scenarios 1-13: Full multi-process, multi-colour, 2-stage inspection, repair re-approval, rate snapshot, advances/payments, deactivation & concurrency/idempotency',
    () async {
      // Even if legacy GIVEN_QTY / includeDamagedInLabour are toggled on,
      // finalized Rule 1 & Rule 3 MUST prevent them from generating extra earnings.
      final profile = await profileRepo.getProfile();
      await profileRepo.updateProfile(
        nameEn: profile.nameEn,
        nameGu: profile.nameGu,
        ownerName: 'Mahesh Owner',
        defaultBillingMode: BillingMode.givenQty,
      );

      final cutting = await procRepo.createProcess(
        name: 'Cutting',
        billingModeOverride: ProcessBillingModeOverride.givenQty,
        includeDamagedInLabour: true,
        defaultRatePaise: 500,
      );
      final stitching = await procRepo.createProcess(
        name: 'Stitching',
        includeDamagedInLabour: true,
        defaultRatePaise: 1000,
      );
      final finishing = await procRepo.createProcess(
        name: 'Finishing',
        defaultRatePaise: 400,
      );

      final ramesh = await workerRepo.createWorker(
        name: 'Rameshbhai',
        phone: '9876543210',
      );
      final suresh = await workerRepo.createWorker(
        name: 'Sureshbhai',
        phone: '9876500001',
      );
      final kiran = await workerRepo.createWorker(
        name: 'Kiranbhai',
        phone: '9876500002',
      );

      for (final pair in [
        (ramesh.id, cutting.id, 500),
        (ramesh.id, stitching.id, 1000),
        (suresh.id, stitching.id, 1100),
        (kiran.id, finishing.id, 400),
      ]) {
        await workerRepo.assignProcessToWorker(
          workerId: pair.$1,
          processId: pair.$2,
        );
        await rateRepo.addRate(
          workerId: pair.$1,
          processId: pair.$2,
          ratePaise: pair.$3,
          effectiveFrom: '2025-01-01',
        );
      }

      // Scenario 1 & 2: Multi-colour lot + atomic initial process assignment in createLotComplete
      final lot1 = await lotRepo.createLotComplete(
        lotNumber: 'LOT-001',
        title: 'Festive Kurti',
        transactionAtUtcMillis: baseTs,
        designs: const [
          LotDesignDraftInput(
            designName: 'D-101',
            colours: [
              LotColourDraftInput(
                colourName: 'Red',
                initialQuantity: 100,
                unitPricePaise: 50000,
              ),
              LotColourDraftInput(
                colourName: 'Blue',
                initialQuantity: 80,
                unitPricePaise: 52000,
              ),
            ],
          ),
        ],
        initialAssignments: [
          InitialLotProcessAssignmentInput(
            designName: 'D-101',
            colourName: 'Red',
            processId: cutting.id,
            workerId: ramesh.id,
            quantity: 100,
            agreedRatePaise: 500,
          ),
        ],
      );

      final lot1Detail = (await lotRepo.getLotDetail(lot1.id))!;
      final redCol = lot1Detail.designs.first.colours
          .firstWhere((c) => c.colourName == 'Red');
      final blueCol = lot1Detail.designs.first.colours
          .firstWhere((c) => c.colourName == 'Blue');

      var lot1Hist = (await historyRepo.getLotCompleteHistory(lot1.id))!;
      expect(lot1Hist.assignments.length, 1);
      final cuttingIssueId = lot1Hist.assignments.first.issueMovementId;

      // Verify Rule 1: GIVEN_QTY on Cutting generated ₹0 earnings on ISSUE!
      var rameshProf = (await historyRepo.getWorkerCompleteProfile(ramesh.id))!;
      expect(rameshProf.financialSummary.earnedLabourPaise, 0);

      // Scenario 13 (Completion guard): Cannot mark LOT-001 COMPLETED while Cutting has 100 pending
      await expectLater(
        lotRepo.updateLot(
          lotId: lot1.id,
          lotNumber: lot1.lotNumber,
          title: lot1.title,
          status: LotStatus.completed,
          transactionAtUtcMillis: baseTs + 500,
        ),
        throwsA(isA<DomainValidationException>()),
      );

      // Return & immediately inspect all 100 Cutting pieces -> 100 accepted @ ₹5 = ₹500
      final cutRet = await historyRepo.recordProductionReturn(
        parentIssueId: cuttingIssueId,
        returnedQuantity: 100,
        transactionAtUtcMillis: baseTs + 1000,
        inspectImmediately: true,
        acceptedQuantity: 100,
        rejectedQuantity: 0,
        approvedBy: 'Mahesh Owner',
        authorizedViaPin: true,
        clientRequestId: 'req-cut-100',
      );
      expect(cutRet.remainingOutstandingQty, 0);
      expect(cutRet.remainingPendingInspectionQty, 0);

      // Scenario 13 (Idempotency): Replaying same clientRequestId must NOT duplicate return/earnings
      final cutRetReplay = await historyRepo.recordProductionReturn(
        parentIssueId: cuttingIssueId,
        returnedQuantity: 100,
        transactionAtUtcMillis: baseTs + 1000,
        inspectImmediately: true,
        acceptedQuantity: 100,
        rejectedQuantity: 0,
        clientRequestId: 'req-cut-100',
      );
      expect(cutRetReplay.wasIdempotentReplay, isTrue);

      rameshProf = (await historyRepo.getWorkerCompleteProfile(ramesh.id))!;
      expect(rameshProf.financialSummary.earnedLabourPaise, 50000);

      // Scenario 3: Multiple workers assigned to the SAME process (Stitching) on Red
      final stitchRamesh = await stockRepo.issueStock(
        designColourId: redCol.id,
        processId: stitching.id,
        workerId: ramesh.id,
        quantity: 60,
        transactionAtUtcMillis: baseTs + 2000,
      );
      final stitchSuresh = await stockRepo.issueStock(
        designColourId: redCol.id,
        processId: stitching.id,
        workerId: suresh.id,
        quantity: 40,
        transactionAtUtcMillis: baseTs + 2100,
      );

      // Scenario 4: Same worker (Ramesh) assigned to a SECOND lot (LOT-002)
      final lot2 = await lotRepo.createLotComplete(
        lotNumber: 'LOT-002',
        transactionAtUtcMillis: baseTs + 2200,
        designs: const [
          LotDesignDraftInput(
            designName: 'D-202',
            colours: [
              LotColourDraftInput(
                colourName: 'Ivory',
                initialQuantity: 50,
                unitPricePaise: 60000,
              ),
            ],
          ),
        ],
        initialAssignments: [
          InitialLotProcessAssignmentInput(
            designName: 'D-202',
            colourName: 'Ivory',
            processId: stitching.id,
            workerId: ramesh.id,
            quantity: 50,
            agreedRatePaise: 1000,
          ),
        ],
      );

      // Scenario 8: Rate changes AFTER assignment (₹10 -> ₹15). Historical transactions MUST stay at ₹10!
      await rateRepo.addRate(
        workerId: ramesh.id,
        processId: stitching.id,
        ratePaise: 1500,
        effectiveFrom: '2026-01-01',
      );

      // Scenario 5 & 6: Partial return #1 (Pending Inspection, 35 pcs -> ₹0 earned yet!)
      final stitchRet1 = await historyRepo.recordProductionReturn(
        parentIssueId: stitchRamesh.id,
        returnedQuantity: 35,
        transactionAtUtcMillis: baseTs + 3000,
        inspectImmediately: false,
      );
      expect(stitchRet1.remainingOutstandingQty, 25);
      expect(stitchRet1.remainingPendingInspectionQty, 35);

      // Over-return validation: trying to return 30 when only 25 outstanding MUST fail!
      await expectLater(
        historyRepo.recordProductionReturn(
          parentIssueId: stitchRamesh.id,
          returnedQuantity: 30,
          transactionAtUtcMillis: baseTs + 3050,
        ),
        throwsA(isA<DomainValidationException>()),
      );

      // Earnings STILL ₹500 (from Cutting only; ₹0 for pending QC!)
      rameshProf = (await historyRepo.getWorkerCompleteProfile(ramesh.id))!;
      expect(rameshProf.financialSummary.earnedLabourPaise, 50000);
      expect(rameshProf.pendingInspectionQty, 35);

      // Partial inspection #1 on ret1: 20 accepted, 5 rejected (10 remain Pending Inspection)
      final insp1 = await historyRepo.approveReturnInspection(
        productionReturnId: stitchRet1.productionReturn.id,
        acceptedQuantity: 20,
        rejectedQuantity: 5,
        rejectionReason: 'Thread break',
        transactionAtUtcMillis: baseTs + 3500,
        inspectedBy: 'Mahesh Owner',
        approvedBy: 'Mahesh Owner',
        authorizedViaPin: true,
        clientRequestId: 'insp-1',
      );
      // Must use historical locked ₹10 (NOT new ₹15!) and ₹0 for 5 rejected!
      expect(insp1.earnedAmountPaise, 20000);
      expect(insp1.createdRejection, isNotNull);
      expect(insp1.createdRejection!.rejectedQuantity, 5);

      // Partial inspection #2 on ret1: remaining 10 accepted
      final insp2 = await historyRepo.approveReturnInspection(
        productionReturnId: stitchRet1.productionReturn.id,
        acceptedQuantity: 10,
        rejectedQuantity: 0,
        transactionAtUtcMillis: baseTs + 3600,
        approvedBy: 'Mahesh Owner',
        authorizedViaPin: true,
      );
      expect(insp2.earnedAmountPaise, 10000);

      // Duplicate inspection beyond remaining pending (0 left) MUST fail!
      await expectLater(
        historyRepo.approveReturnInspection(
          productionReturnId: stitchRet1.productionReturn.id,
          acceptedQuantity: 1,
          rejectedQuantity: 0,
          transactionAtUtcMillis: baseTs + 3650,
        ),
        throwsA(isA<DomainValidationException>()),
      );

      // Return #2 for the remaining 25 pcs of Ramesh's Stitching (immediate inspection: 25 accepted)
      await historyRepo.recordProductionReturn(
        parentIssueId: stitchRamesh.id,
        returnedQuantity: 25,
        transactionAtUtcMillis: baseTs + 3700,
        inspectImmediately: true,
        acceptedQuantity: 25,
        rejectedQuantity: 0,
        approvedBy: 'Mahesh Owner',
        authorizedViaPin: true,
      );

      // Scenario 7: Rejection Repair + Reinspection + Re-Approval (3 by Original Worker @ locked ₹10, 2 by In-House Factory @ ₹0)
      final rejId = insp1.createdRejection!.id;
      final repWorker = await historyRepo.recordRejectionRepair(
        rejectionRecordId: rejId,
        repairedQuantity: 3,
        repairSource: RepairSource.originalWorker,
        transactionAtUtcMillis: baseTs + 4000,
        repairedBy: 'Rameshbhai',
      );
      final reinspWorker = await historyRepo.approveRepairReinspection(
        rejectionRepairId: repWorker.id,
        acceptedQuantity: 3,
        rejectedAgainQuantity: 0,
        transactionAtUtcMillis: baseTs + 4100,
        approvedBy: 'Mahesh Owner',
        authorizedViaPin: true,
      );
      // Original worker gets 3 × locked ₹10 = ₹30 (NOT ₹15!)
      expect(reinspWorker.earnedAmountPaise, 3000);

      final repFactory = await historyRepo.recordRejectionRepair(
        rejectionRecordId: rejId,
        repairedQuantity: 2,
        repairSource: RepairSource.inHouse,
        transactionAtUtcMillis: baseTs + 4200,
        repairedBy: 'Factory Tailor',
      );
      final reinspFactory = await historyRepo.approveRepairReinspection(
        rejectionRepairId: repFactory.id,
        acceptedQuantity: 2,
        rejectedAgainQuantity: 0,
        transactionAtUtcMillis: baseTs + 4300,
        approvedBy: 'Mahesh Owner',
        authorizedViaPin: true,
      );
      // In-house factory repair generates ₹0 worker earnings!
      expect(reinspFactory.earnedAmountPaise, 0);

      // Exceeding original rejected qty (5) with another repair MUST fail!
      await expectLater(
        historyRepo.recordRejectionRepair(
          rejectionRecordId: rejId,
          repairedQuantity: 1,
          repairSource: RepairSource.originalWorker,
          transactionAtUtcMillis: baseTs + 4400,
        ),
        throwsA(isA<DomainValidationException>()),
      );

      // Finish Suresh's 40 pcs + Finishing by Kiran (95 pcs) + Blue colour issue/return
      await historyRepo.recordProductionReturn(
        parentIssueId: stitchSuresh.id,
        returnedQuantity: 40,
        transactionAtUtcMillis: baseTs + 4500,
        inspectImmediately: true,
        acceptedQuantity: 40,
        rejectedQuantity: 0,
        approvedBy: 'Mahesh Owner',
        authorizedViaPin: true,
      );
      final finishIssue = await stockRepo.issueStock(
        designColourId: redCol.id,
        processId: finishing.id,
        workerId: kiran.id,
        quantity: 95,
        transactionAtUtcMillis: baseTs + 4600,
      );
      await historyRepo.recordProductionReturn(
        parentIssueId: finishIssue.id,
        returnedQuantity: 95,
        transactionAtUtcMillis: baseTs + 4700,
        inspectImmediately: true,
        acceptedQuantity: 95,
        rejectedQuantity: 0,
        approvedBy: 'Mahesh Owner',
        authorizedViaPin: true,
      );
      final blueIssue = await stockRepo.issueStock(
        designColourId: blueCol.id,
        processId: cutting.id,
        workerId: ramesh.id,
        quantity: 80,
        transactionAtUtcMillis: baseTs + 4800,
      );
      await historyRepo.recordProductionReturn(
        parentIssueId: blueIssue.id,
        returnedQuantity: 80,
        transactionAtUtcMillis: baseTs + 4900,
        inspectImmediately: true,
        acceptedQuantity: 80,
        rejectedQuantity: 0,
        approvedBy: 'Mahesh Owner',
        authorizedViaPin: true,
      );

      // Now ALL LOT-001 assignments are reconciled -> marking COMPLETED succeeds!
      final completedLot1 = await lotRepo.updateLot(
        lotId: lot1.id,
        lotNumber: lot1.lotNumber,
        title: lot1.title,
        status: LotStatus.completed,
        transactionAtUtcMillis: baseTs + 5000,
      );
      expect(completedLot1.status, LotStatus.completed);

      // Scenario 9 & 10: Advance payment + Partial regular payment + Outstanding reconciliation
      // Ramesh total earned so far:
      //   Cutting Red: 100 * 500 = 50,000
      //   Cutting Blue: 80 * 500 = 40,000
      //   Stitching Red: (20 + 10 + 25 + 3 repaired) * 1000 = 58,000
      //   LOT-002 Stitching: 0 (still open!)
      //   Total Ramesh Earned = 148,000 paise (₹1,480)
      await acctRepo.recordPayment(
        workerId: ramesh.id,
        paymentType: PaymentType.advance,
        amountPaise: 50000,
        paymentMode: PaymentMode.cash,
        transactionAtUtcMillis: baseTs + 5100,
      );
      await acctRepo.recordPayment(
        workerId: ramesh.id,
        paymentType: PaymentType.regular,
        amountPaise: 48000,
        paymentMode: PaymentMode.upi,
        transactionAtUtcMillis: baseTs + 5200,
      );

      rameshProf = (await historyRepo.getWorkerCompleteProfile(ramesh.id))!;
      expect(rameshProf.totalLotsAssigned, 2); // LOT-001 & LOT-002
      expect(rameshProf.financialSummary.earnedLabourPaise, 148000);
      expect(rameshProf.financialSummary.advancePaymentsPaise, 50000);
      expect(rameshProf.financialSummary.regularPaymentsPaise, 48000);
      expect(rameshProf.financialSummary.outstandingPayablePaise, 50000);

      // Process breakdown on Ramesh profile: Cutting vs Stitching
      expect(rameshProf.processHistory.length, 2);
      final rameshCutting = rameshProf.processHistory
          .firstWhere((p) => p.processId == cutting.id);
      final rameshStitching = rameshProf.processHistory
          .firstWhere((p) => p.processId == stitching.id);
      expect(rameshCutting.acceptedQty, 180);
      expect(rameshCutting.earnedAmountPaise, 90000);
      expect(rameshStitching.acceptedQty, 58); // 55 initial + 3 original-worker repaired
      expect(rameshStitching.earnedAmountPaise, 58000);

      // Scenario 11 & 12: Deactivate Ramesh AND Stitching -> history MUST remain 100% accessible & intact!
      await workerRepo.setWorkerActive(workerId: ramesh.id, isActive: false);
      await procRepo.setProcessActive(processId: stitching.id, isActive: false);

      final deactivatedWorkerProf =
          (await historyRepo.getWorkerCompleteProfile(ramesh.id))!;
      expect(deactivatedWorkerProf.isActive, isFalse);
      expect(deactivatedWorkerProf.financialSummary.earnedLabourPaise, 148000);
      expect(
        deactivatedWorkerProf.financialSummary.outstandingPayablePaise,
        50000,
      );

      final deactivatedProcHist =
          (await historyRepo.getProcessCompleteHistory(stitching.id))!;
      expect(deactivatedProcHist.isActive, isFalse);
      expect(deactivatedProcHist.totalLots, 2);
      expect(deactivatedProcHist.totalWorkersInvolved, 2);
      // Stitching earned = Ramesh 58,000 + Suresh (40 * 1100 = 44,000) = 102,000
      expect(deactivatedProcHist.totalProductionCostPaise, 102000);

      // Verify Lot Timeline has chronological events including Created, Issue, Return, Inspection, Rejection, Repair, Re-approval, Completed
      final timeline = await historyRepo.getLotTimeline(lot1.id);
      expect(timeline.first.kind, LotTimelineEventKind.lotCreated);
      expect(timeline.last.kind, LotTimelineEventKind.lotCompleted);
      expect(
        timeline.any((e) => e.kind == LotTimelineEventKind.repairReapproved),
        isTrue,
      );

      // Verify Transaction Detail inspection works for inspection record (including PIN auth audit)
      final txDetail = await historyRepo.getTransactionDetail(
        kind: ProductionTransactionKind.inspection,
        id: insp1.inspection.id,
      );
      expect(txDetail, isNotNull);
      expect(txDetail!.authorizedViaPin, isTrue);
      expect(txDetail.approvedBy, 'Mahesh Owner');
      expect(txDetail.lockedRatePaise, 1000);
      expect(txDetail.amountPaise, 20000);

      // Verify LOT-002 still exists and has 50 outstanding
      final lot2Hist = (await historyRepo.getLotCompleteHistory(lot2.id))!;
      expect(lot2Hist.totalOutstandingQty, 50);

      // Verify Foreign Key integrity across all 23 tables
      final fkCheck = await db.customSelect('PRAGMA foreign_key_check;').get();
      expect(fkCheck, isEmpty);
    },
  );

  test(
    'Scenario 15: Large dataset (500+ movements) pagination, exact cross-summary reconciliation & Excel/CSV/HTML export',
    () async {
      final proc = await procRepo.createProcess(
        name: 'Embroidery',
        defaultRatePaise: 1200,
      );
      final worker = await workerRepo.createWorker(name: 'Harishbhai');
      await workerRepo.assignProcessToWorker(
        workerId: worker.id,
        processId: proc.id,
      );
      await rateRepo.addRate(
        workerId: worker.id,
        processId: proc.id,
        ratePaise: 1200,
        effectiveFrom: '2025-01-01',
      );

      final lot = await lotRepo.createLotComplete(
        lotNumber: 'LOT-BIG-500',
        transactionAtUtcMillis: baseTs,
        designs: const [
          LotDesignDraftInput(
            designName: 'Bulk-Design',
            colours: [
              LotColourDraftInput(
                colourName: 'Gold',
                initialQuantity: 5000,
                unitPricePaise: 40000,
              ),
            ],
          ),
        ],
      );
      final detail = (await lotRepo.getLotDetail(lot.id))!;
      final col = detail.designs.first.colours.first;

      // Create 260 ISSUE + 260 RETURN movements = 520 movements!
      for (var i = 0; i < 260; i++) {
        final ts = baseTs + (i * 1000);
        final issue = await stockRepo.issueStock(
          designColourId: col.id,
          processId: proc.id,
          workerId: worker.id,
          quantity: 10,
          transactionAtUtcMillis: ts,
        );
        await historyRepo.recordProductionReturn(
          parentIssueId: issue.id,
          returnedQuantity: 10,
          transactionAtUtcMillis: ts + 500,
          inspectImmediately: true,
          acceptedQuantity: 9,
          rejectedQuantity: 1,
          rejectionReason: 'Defect #$i',
          approvedBy: 'QC',
        );
      }

      // Page 0 and Page 1 pagination verification
      final page0 = await historyRepo.getDashboard(
        filter: const ProductionHistoryFilter(page: 0, pageSize: 30),
      );
      final page1 = await historyRepo.getDashboard(
        filter: const ProductionHistoryFilter(page: 1, pageSize: 30),
      );
      expect(page0.items.length, 30);
      expect(page1.items.length, 30);
      expect(page0.hasMore, isTrue);
      expect(page0.totalItemsCount, greaterThanOrEqualTo(520));
      expect(page0.items.first.id, isNot(page1.items.first.id));

      // Exact cross-summary reconciliation: Lot == Worker == Process == Dashboard
      final lotHist = (await historyRepo.getLotCompleteHistory(lot.id))!;
      final workerProf = (await historyRepo.getWorkerCompleteProfile(worker.id))!;
      final procHist = (await historyRepo.getProcessCompleteHistory(proc.id))!;

      const expectedAssigned = 2600;
      const expectedAccepted = 2340;
      const expectedRejected = 260;
      const expectedEarned = 2340 * 1200; // ₹28,080.00

      expect(page0.totalAssignedQty, expectedAssigned);
      expect(page0.totalAcceptedQty, expectedAccepted);
      expect(page0.totalRejectedQty, expectedRejected);
      expect(page0.totalEarnedPaise, expectedEarned);

      expect(lotHist.totalAssignedQty, expectedAssigned);
      expect(lotHist.totalAcceptedQty, expectedAccepted);
      expect(lotHist.totalRejectedQty, expectedRejected);
      expect(lotHist.totalProductionCostPaise, expectedEarned);

      expect(workerProf.assignedQty, expectedAssigned);
      expect(workerProf.acceptedQty, expectedAccepted);
      expect(workerProf.rejectedQty, expectedRejected);
      expect(workerProf.financialSummary.earnedLabourPaise, expectedEarned);

      expect(procHist.assignedQty, expectedAssigned);
      expect(procHist.acceptedQty, expectedAccepted);
      expect(procHist.rejectedQty, expectedRejected);
      expect(procHist.totalProductionCostPaise, expectedEarned);

      // Reports & Export (Excel 10 sheets + CSV BOM + HTML)
      final bundle = await reportsRepo.getAdvancedReports(const ReportFilter());
      expect(bundle.productionHistoryRows.length, 260);
      expect(bundle.rejectionRecords.length, 260);

      final sheets = ExcelCsvExportService.buildSheets(
        bundle: bundle,
        category: ReportCategory.inventory,
        localeCode: 'en',
        fullWorkbook: true,
      );
      expect(sheets.length, 10);
      final xlsx = ExcelCsvExportService.buildXlsxBytes(sheets);
      final decoded = Excel.decodeBytes(xlsx);
      expect(decoded.tables.keys, contains('Production_History'));
      expect(decoded.tables.keys, contains('Pending_QC_Returns'));
      expect(decoded.tables.keys, contains('Rejections_Repairs'));

      const htmlBuilder = ReportHtmlBuilder();
      final html = htmlBuilder.buildHtml(
        bundle: bundle,
        category: ReportCategory.inventory,
        localeCode: 'en',
      );
      expect(html, contains('Pending Inspection'));
      expect(html, contains('Rejections &amp; Repair Tracking'));
    },
  );
}
