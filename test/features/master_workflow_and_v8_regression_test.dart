import 'dart:convert';
import 'dart:io';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/data/repositories/accounting_repository_impl.dart';
import 'package:business_manager/features/accounting/domain/calculators/labour_calculator.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/backup/data/services/web_backup_restore_service.dart';
import 'package:business_manager/features/business_profile/domain/entities/business_profile_entity.dart';
import 'package:business_manager/features/lots/data/repositories/colour_master_repository_impl.dart';
import 'package:business_manager/features/lots/data/repositories/lot_repository_impl.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/lots/presentation/bloc/designs_colours_cubit.dart';
import 'package:business_manager/features/parties/data/repositories/party_repository_impl.dart';
import 'package:business_manager/features/processes/data/repositories/process_repository_impl.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/production_history/data/repositories/production_history_repository_impl.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/rates/data/repositories/rate_repository_impl.dart';
import 'package:business_manager/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:business_manager/features/reports/domain/entities/report_filter.dart';
import 'package:business_manager/features/stock_movements/data/repositories/stock_movement_repository_impl.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/workers/data/repositories/worker_repository_impl.dart';
import 'package:drift/drift.dart' show Uint8List;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DatabaseTransactionRunner txRunner;
  late IdGenerator idGen;
  late Directory tempDir;
  late LotRepositoryImpl lotRepo;
  late ColourMasterRepositoryImpl colourRepo;
  late ProcessRepositoryImpl processRepo;
  late WorkerRepositoryImpl workerRepo;
  late RateRepositoryImpl rateRepo;
  late StockMovementRepositoryImpl stockRepo;
  late AccountingRepositoryImpl accountingRepo;
  late ProductionHistoryRepositoryImpl historyRepo;
  late ReportsRepositoryImpl reportsRepo;

  setUpAll(() {
    IstDateTimeHelper.initialize();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sf_master_qa_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.verifyPragmas();
    txRunner = DatabaseTransactionRunner(db);
    idGen = IdGenerator();
    final config = AppConfig.dev();
    final media = NativeMediaStorageService(
      config: config,
      idGenerator: idGen,
      baseDirectoryOverride: tempDir,
    );
    lotRepo = LotRepositoryImpl(db, txRunner, idGen, media);
    colourRepo = ColourMasterRepositoryImpl(db, txRunner, idGen);
    processRepo = ProcessRepositoryImpl(db, txRunner, idGen);
    workerRepo = WorkerRepositoryImpl(db, txRunner, idGen);
    rateRepo = RateRepositoryImpl(db, txRunner, idGen);
    stockRepo = StockMovementRepositoryImpl(db, txRunner, idGen);
    accountingRepo = AccountingRepositoryImpl(db, txRunner, idGen);
    historyRepo = ProductionHistoryRepositoryImpl(db, txRunner, idGen);
    final partyRepo = PartyRepositoryImpl(db, txRunner, idGen);
    reportsRepo = ReportsRepositoryImpl(db, stockRepo, accountingRepo, partyRepo);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Final Worker Payment Rules (Accepted-Only Earnings Enforcement)', () {
    test(
      'Legacy GIVEN_QTY and includeDamagedInLabour cannot alter new worker earnings',
      () {
        const calc = LabourCalculator();

        // Effective billing mode always resolves to receivedQty (Accepted Qty)
        expect(
          calc.resolveEffectiveBillingMode(
            globalDefault: BillingMode.givenQty,
            processOverride: BillingMode.givenQty,
          ),
          BillingMode.receivedQty,
        );

        // Rule 1: Even when legacy billingMode == givenQty, ISSUE is non-payable.
        final onIssue = calc.planForIssue(
          quantity: 100,
          appliedRatePaise: 1500,
          lockedBillingMode: BillingMode.givenQty,
        );
        expect(onIssue.isPayable, isFalse);

        // Rule 1 & 3: Accepted quantity generates earnings; rejected earns ₹0
        // even when legacy lockedIncludeDamaged == true.
        final onGood = calc.planForSettlement(
          movementType: StockMovementType.returnGood,
          quantity: 80,
          lockedRatePaise: 1500,
          lockedBillingMode: BillingMode.givenQty,
          lockedIncludeDamaged: true,
        );
        expect(onGood, isNotNull);
        expect(onGood!.quantity, 80);
        expect(onGood.amountPaise, 80 * 1500);
        expect(onGood.isPayable, isTrue);

        final onDamaged = calc.planForSettlement(
          movementType: StockMovementType.returnDamaged,
          quantity: 20,
          lockedRatePaise: 1500,
          lockedBillingMode: BillingMode.givenQty,
          lockedIncludeDamaged: true,
        );
        expect(onDamaged, isNull);

        // Rule 3: Post-repair re-approval credits Original Worker at historical rate,
        // while Factory / In-House repair generates ₹0.
        final origRepair = calc.planForRepairReapproval(
          acceptedQuantity: 12,
          lockedRatePaise: 1500,
          creditOriginalWorker: true,
        );
        expect(origRepair, isNotNull);
        expect(origRepair!.amountPaise, 12 * 1500);

        final inHouseRepair = calc.planForRepairReapproval(
          acceptedQuantity: 12,
          lockedRatePaise: 1500,
          creditOriginalWorker: false,
        );
        expect(inHouseRepair, isNull);
      },
    );
  });

  group('19-Step Complete Manufacturing Regression & All 15 Schema v8 Scenarios', () {
    test(
      'Executes full workflow with exact cross-screen reconciliation, inactive preservation, idempotency, and Web backup/restore round-trip',
      () async {
        final day1 = IstDateTimeHelper.istDateTimeToUtcMillis(
          year: 2026,
          month: 10,
          day: 1,
          hour: 10,
        );
        final day2 = IstDateTimeHelper.istDateTimeToUtcMillis(
          year: 2026,
          month: 10,
          day: 5,
          hour: 14,
        );

        // 1–2. Colour Master CRUD + Designs & Colours catalog check
        final customCol = await colourRepo.createCustomColour(
          name: 'Indigo Silk',
          hexCode: '#312E81',
        );
        expect(customCol.hexCode, '#312E81');

        // 3–4. Create multiple processes & multiple workers
        final cutting = await processRepo.createProcess(
          name: 'Cutting',
          billingModeOverride: ProcessBillingModeOverride.givenQty,
          includeDamagedInLabour: true, // Legacy flag — MUST NOT affect earnings
        );
        final stitching = await processRepo.createProcess(name: 'Stitching');
        final finishing = await processRepo.createProcess(name: 'Finishing');

        final ramesh = await workerRepo.createWorker(
          name: 'Rameshbhai',
          phone: '9876543210',
        );
        final suresh = await workerRepo.createWorker(
          name: 'Sureshbhai',
          phone: '9876500001',
        );

        // 5–6. Assign workers to processes & set historical rates on Day 1
        await workerRepo.assignProcessToWorker(
          workerId: ramesh.id,
          processId: cutting.id,
        );
        await workerRepo.assignProcessToWorker(
          workerId: ramesh.id,
          processId: stitching.id,
        );
        await workerRepo.assignProcessToWorker(
          workerId: suresh.id,
          processId: stitching.id,
        );
        await workerRepo.assignProcessToWorker(
          workerId: suresh.id,
          processId: finishing.id,
        );

        await rateRepo.addRate(
          workerId: ramesh.id,
          processId: cutting.id,
          ratePaise: 500, // ₹5/pc
          effectiveFrom: '2026-09-01',
        );
        await rateRepo.addRate(
          workerId: ramesh.id,
          processId: stitching.id,
          ratePaise: 1000, // ₹10/pc
          effectiveFrom: '2026-09-01',
        );
        await rateRepo.addRate(
          workerId: suresh.id,
          processId: stitching.id,
          ratePaise: 1200, // ₹12/pc
          effectiveFrom: '2026-09-01',
        );

        // 7–10. Create multi-colour, multi-process lot with initial assignment
        final lot = await lotRepo.createLotComplete(
          lotNumber: 'LOT-2026-001',
          title: 'Festive Anarkali Batch',
          transactionAtUtcMillis: day1,
          designs: const [
            LotDesignDraftInput(
              designName: 'Anarkali Gold',
              colours: [
                LotColourDraftInput(
                  colourName: 'Indigo Silk',
                  colourHex: '#312E81',
                  initialQuantity: 100,
                  unitPricePaise: 85000,
                ),
                LotColourDraftInput(
                  colourName: 'Maroon',
                  colourHex: '#7F1D1D',
                  initialQuantity: 50,
                  unitPricePaise: 90000,
                ),
              ],
            ),
          ],
          initialAssignments: [
            InitialLotProcessAssignmentInput(
              designName: 'Anarkali Gold',
              colourName: 'Indigo Silk',
              processId: cutting.id,
              workerId: ramesh.id,
              quantity: 40,
              agreedRatePaise: 500,
            ),
          ],
        );

        final lotDetail = await lotRepo.getLotDetail(lot.id);
        expect(lotDetail, isNotNull);
        final indigoColour = lotDetail!.designs.first.colours.first;
        final maroonColour = lotDetail.designs.first.colours[1];

        // Verify DesignsColoursCubit aggregates cross-lot designs & colours cleanly
        final dcCubit = DesignsColoursCubit(lotRepo, colourRepo);
        await dcCubit.load();
        expect(dcCubit.state.designs.length, 1);
        expect(dcCubit.state.designs.first.designName, 'Anarkali Gold');
        expect(dcCubit.state.designs.first.totalInitialQuantity, 150);
        await dcCubit.close();

        // Issue additional stitching to BOTH Ramesh (60 pcs @ ₹10) & Suresh (40 pcs @ ₹12)
        final issueRameshStitch = await stockRepo.issueStock(
          designColourId: indigoColour.id,
          processId: stitching.id,
          workerId: ramesh.id,
          quantity: 60,
          transactionAtUtcMillis: day1,
          clientRequestId: 'req-issue-ramesh-60',
        );
        // Verify idempotency replay prevents duplicate issue
        final replayIssue = await stockRepo.issueStock(
          designColourId: indigoColour.id,
          processId: stitching.id,
          workerId: ramesh.id,
          quantity: 60,
          transactionAtUtcMillis: day1,
          clientRequestId: 'req-issue-ramesh-60',
        );
        expect(replayIssue.id, issueRameshStitch.id);

        final issueSureshStitch = await stockRepo.issueStock(
          designColourId: maroonColour.id,
          processId: stitching.id,
          workerId: suresh.id,
          quantity: 40,
          transactionAtUtcMillis: day1,
        );

        // Increase Ramesh's stitching rate AFTER assignment to ₹15/pc on Day 2
        await rateRepo.addRate(
          workerId: ramesh.id,
          processId: stitching.id,
          ratePaise: 1500, // ₹15/pc — MUST NOT retroactively change ₹10 snapshot!
          effectiveFrom: '2026-10-03',
          autoClosePreviousOpenRate: true,
        );

        // 11. Record partial return as PENDING INSPECTION (₹0 earned until QC approves!)
        final retPending = await historyRepo.recordProductionReturn(
          parentIssueId: issueRameshStitch.id,
          returnedQuantity: 30,
          transactionAtUtcMillis: day2,
          inspectImmediately: false,
          clientRequestId: 'req-ret-pending-1',
        );
        expect(retPending.remainingPendingInspectionQty, 30);
        expect(retPending.remainingOutstandingQty, 30);

        // Verify ₹0 earned while pending inspection
        final rameshBeforeQc = await accountingRepo.getWorkerLedgerDetail(
          ramesh.id,
        );
        expect(rameshBeforeQc!.summary.earnedLabourPaise, 0);

        // Lot completion MUST be blocked while work is outstanding or pending QC
        await expectLater(
          () => lotRepo.updateLot(
            lotId: lot.id,
            lotNumber: lot.lotNumber,
            title: lot.title,
            status: LotStatus.completed,
            transactionAtUtcMillis: day2,
          ),
          throwsA(isA<DomainValidationException>()),
        );

        // 12–13. Inspect pending return: 25 Accepted + 5 Rejected (at locked ₹10/pc!)
        final qc1 = await historyRepo.approveReturnInspection(
          productionReturnId: retPending.productionReturn.id,
          acceptedQuantity: 25,
          rejectedQuantity: 5,
          rejectionReason: 'Loose seam',
          transactionAtUtcMillis: day2,
          inspectedBy: 'Owner',
          approvedBy: 'Owner',
          authorizedViaPin: true,
          clientRequestId: 'req-qc-1',
        );
        expect(qc1.earnedAmountPaise, 25 * 1000); // ₹250 (locked ₹10, NOT ₹15!)
        expect(qc1.createdRejection, isNotNull);

        // Second return on same assignment: remaining 30 pcs immediately inspected (30 Accepted)
        final ret2 = await historyRepo.recordProductionReturn(
          parentIssueId: issueRameshStitch.id,
          returnedQuantity: 30,
          transactionAtUtcMillis: day2,
          inspectImmediately: true,
          acceptedQuantity: 30,
          rejectedQuantity: 0,
          inspectedBy: 'Owner',
          approvedBy: 'Owner',
          authorizedViaPin: true,
        );
        expect(ret2.remainingOutstandingQty, 0);
        expect(ret2.remainingPendingInspectionQty, 0);

        // Repair 4 of the 5 rejected pieces by Original Worker -> re-approve 3 (credits ₹10 × 3 = ₹30)
        final repair1 = await historyRepo.recordRejectionRepair(
          rejectionRecordId: qc1.createdRejection!.id,
          repairedQuantity: 4,
          repairSource: RepairSource.originalWorker,
          transactionAtUtcMillis: day2,
        );
        final reinsp1 = await historyRepo.approveRepairReinspection(
          rejectionRepairId: repair1.id,
          acceptedQuantity: 3,
          rejectedAgainQuantity: 1,
          rejectionReason: 'Fabric tear',
          transactionAtUtcMillis: day2,
          approvedBy: 'Owner',
          authorizedViaPin: true,
        );
        expect(reinsp1.earnedAmountPaise, 3 * 1000); // Historical locked ₹10/pc!

        // Repair remaining 1 rejected piece In-House (Factory) -> ₹0 worker earning
        final repair2 = await historyRepo.recordRejectionRepair(
          rejectionRecordId: qc1.createdRejection!.id,
          repairedQuantity: 1,
          repairSource: RepairSource.inHouse,
          transactionAtUtcMillis: day2,
        );
        final reinsp2 = await historyRepo.approveRepairReinspection(
          rejectionRepairId: repair2.id,
          acceptedQuantity: 1,
          rejectedAgainQuantity: 0,
          transactionAtUtcMillis: day2,
          approvedBy: 'Owner',
          authorizedViaPin: true,
        );
        expect(reinsp2.earnedAmountPaise, 0);

        // Also settle Suresh's 40 pcs stitching immediately (38 accepted, 2 rejected)
        await historyRepo.recordProductionReturn(
          parentIssueId: issueSureshStitch.id,
          returnedQuantity: 40,
          transactionAtUtcMillis: day2,
          inspectImmediately: true,
          acceptedQuantity: 38,
          rejectedQuantity: 2,
          rejectionReason: 'Stain',
          approvedBy: 'Owner',
          authorizedViaPin: true,
        );

        // 14–15. Verify Worker Earnings & record Advance + Regular Payment
        // Ramesh total accepted = 25 + 30 + 3 (orig repair) = 58 pcs @ ₹10 = ₹580 (58000 paise)
        final rameshLedger = await accountingRepo.getWorkerLedgerDetail(
          ramesh.id,
        );
        expect(rameshLedger!.summary.earnedLabourPaise, 58000);

        await accountingRepo.recordPayment(
          workerId: ramesh.id,
          amountPaise: 20000, // ₹200 advance
          paymentType: PaymentType.advance,
          paymentMode: PaymentMode.cash,
          transactionAtUtcMillis: day2,
        );
        await accountingRepo.recordPayment(
          workerId: ramesh.id,
          amountPaise: 15000, // ₹150 regular
          paymentType: PaymentType.regular,
          paymentMode: PaymentMode.upi,
          transactionAtUtcMillis: day2,
        );

        final rameshAfterPay = await accountingRepo.getWorkerLedgerDetail(
          ramesh.id,
        );
        expect(rameshAfterPay!.summary.earnedLabourPaise, 58000);
        expect(rameshAfterPay.summary.netPaidToWorkerPaise, 35000);
        expect(rameshAfterPay.summary.outstandingPayablePaise, 23000);

        // Deactivate worker & process -> verify historical records stay 100% accessible!
        await workerRepo.setWorkerActive(workerId: suresh.id, isActive: false);
        await processRepo.setProcessActive(
          processId: stitching.id,
          isActive: false,
        );

        // 16–19. Verify Exact Cross-Summary Reconciliation (Lot == Worker == Process == Reports)
        final lotHist = await historyRepo.getLotCompleteHistory(lot.id);
        expect(lotHist, isNotNull);
        const expectedTotalEarned = 58000 + (38 * 1200);
        expect(lotHist!.totalProductionCostPaise, expectedTotalEarned);

        final timeline = await historyRepo.getLotTimeline(lot.id);
        expect(timeline.length, greaterThanOrEqualTo(6));

        final workerProfiles = await historyRepo.getAllWorkerProfiles();
        final workerEarnedSum = workerProfiles.fold<int>(
          0,
          (s, w) => s + w.financialSummary.earnedLabourPaise,
        );
        expect(workerEarnedSum, expectedTotalEarned);

        final procHistories = await historyRepo.getAllProcessHistories();
        final stitchHist = procHistories.firstWhere(
          (p) => p.processId == stitching.id,
        );
        expect(stitchHist.isActive, isFalse);
        expect(stitchHist.totalProductionCostPaise, expectedTotalEarned);
        expect(stitchHist.totalWorkersInvolved, 2);

        final reportBundle = await reportsRepo.getAdvancedReports(
          const ReportFilter(),
        );
        expect(
          reportBundle.financial.periodEarnedLabourPaise,
          expectedTotalEarned,
        );

        // Offline Web Backup & Transactional Restore Round-Trip Verification
        final webBackup = WebBackupRestoreService(db, AppConfig.dev(), idGen);
        final (snapBytes, snapManifest) = await webBackup.buildSnapshotBytes();
        expect(snapManifest.summaryCounts.lotsCount, 1);
        expect(snapManifest.summaryCounts.workersCount, 2);

        // Verify tamper detection rejects modified payload
        final tamperedMap =
            jsonDecode(utf8.decode(snapBytes)) as Map<String, dynamic>;
        (tamperedMap['tables'] as Map<String, dynamic>)['lots'] = <dynamic>[];
        final tamperedToken = WebBackupRestoreService.stagePickedBytes(
          Uint8List.fromList(utf8.encode(jsonEncode(tamperedMap))),
        );
        final tamperedVal = await webBackup.validateBackupZip(tamperedToken);
        expect(tamperedVal.isValid, isFalse);
        expect(tamperedVal.errorCodes, contains('BACKUP_CHECKSUM_MISMATCH'));

        // Restore cleanly from verified Web snapshot & confirm identical reconciliation
        final validToken = WebBackupRestoreService.stagePickedBytes(snapBytes);
        final restoreResult = await webBackup.restoreFromZip(validToken);
        expect(restoreResult.manifest.summaryCounts.lotsCount, 1);

        final restoredLotHist = await historyRepo.getLotCompleteHistory(lot.id);
        expect(restoredLotHist!.totalProductionCostPaise, expectedTotalEarned);
      },
    );
  });

  group('Phase 5 & 6 Performance Validation (Realistic 500+ Movement Dataset)', () {
    test(
      'Reconciles 50 lots, 20 workers, and 500+ movements within production latency budget',
      () async {
        final baseTime = IstDateTimeHelper.istDateTimeToUtcMillis(
          year: 2026,
          month: 10,
          day: 1,
          hour: 9,
        );

        final proc = await processRepo.createProcess(name: 'Stitching');
        final workers = <String>[];
        for (var i = 0; i < 20; i++) {
          final w = await workerRepo.createWorker(name: 'Worker $i');
          await workerRepo.assignProcessToWorker(
            workerId: w.id,
            processId: proc.id,
          );
          await rateRepo.addRate(
            workerId: w.id,
            processId: proc.id,
            ratePaise: 1000,
            effectiveFrom: '2026-09-01',
          );
          workers.add(w.id);
        }

        // Seed 50 lots × 5 issues + 5 returns = 500 stock movements
        for (var l = 0; l < 50; l++) {
          final lot = await lotRepo.createLotComplete(
            lotNumber: 'PERF-LOT-${l.toString().padLeft(3, '0')}',
            transactionAtUtcMillis: baseTime + (l * 60000),
            designs: [
              LotDesignDraftInput(
                designName: 'Design ${l % 10}',
                colours: const [
                  LotColourDraftInput(
                    colourName: 'Blue',
                    initialQuantity: 200,
                    unitPricePaise: 40000,
                  ),
                ],
              ),
            ],
          );
          final detail = await lotRepo.getLotDetail(lot.id);
          final colourId = detail!.designs.first.colours.first.id;
          for (var j = 0; j < 5; j++) {
            final workerId = workers[(l + j) % workers.length];
            final iss = await stockRepo.issueStock(
              designColourId: colourId,
              processId: proc.id,
              workerId: workerId,
              quantity: 20,
              transactionAtUtcMillis: baseTime + (l * 60000) + (j * 1000),
            );
            await stockRepo.recordSettlement(
              parentIssueId: iss.id,
              goodQuantity: 18,
              damagedQuantity: 2,
              lostQuantity: 0,
              shortageQuantity: 0,
              reason: 'Batch QC',
              transactionAtUtcMillis: baseTime + (l * 60000) + (j * 1000) + 500,
            );
          }
        }

        final swDashboard = Stopwatch()..start();
        final dash = await historyRepo.getDashboard();
        swDashboard.stop();

        final swReports = Stopwatch()..start();
        final reports = await reportsRepo.getAdvancedReports(
          const ReportFilter(),
        );
        swReports.stop();

        expect(dash.totalAssignedQty, 50 * 5 * 20);
        expect(dash.totalAcceptedQty, 50 * 5 * 18);
        expect(dash.totalRejectedQty, 50 * 5 * 2);
        expect(dash.totalEarnedPaise, 50 * 5 * 18 * 1000);
        expect(reports.financial.periodEarnedLabourPaise, dash.totalEarnedPaise);

        // ignore: avoid_print
        print(
          'PERF_BENCHMARK_500_MOVEMENTS: '
          'historyDashboardMs=${swDashboard.elapsedMilliseconds}ms, '
          'reportsBundleMs=${swReports.elapsedMilliseconds}ms',
        );
        expect(swDashboard.elapsedMilliseconds, lessThan(5000));
        expect(swReports.elapsedMilliseconds, lessThan(5000));
      },
    );
  });
}
