import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/connection/database_connection_native.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/data/repositories/accounting_repository_impl.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/backup/data/services/native_backup_restore_service.dart';
import 'package:business_manager/features/lots/data/repositories/lot_repository_impl.dart';
import 'package:business_manager/features/processes/data/repositories/process_repository_impl.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/rates/data/repositories/rate_repository_impl.dart';
import 'package:business_manager/features/reports/data/repositories/reports_repository_impl.dart';
import 'package:business_manager/features/stock_movements/data/repositories/stock_movement_repository_impl.dart';
import 'package:business_manager/features/workers/data/repositories/worker_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory baseDir;
  late Directory tempDir;

  setUpAll(() {
    IstDateTimeHelper.initialize();
  });

  setUp(() async {
    baseDir = await Directory.systemTemp.createTemp('sf_e2e_base_');
    tempDir = await Directory.systemTemp.createTemp('sf_e2e_tmp_');
  });

  tearDown(() async {
    if (baseDir.existsSync()) await baseDir.delete(recursive: true);
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  test('complete 18-step StitchFlow workflow: Lot -> Stock -> Labour -> Ledger -> Backup -> Restore', () async {
    final config = AppConfig.dev();
    final idGen = IdGenerator();
    final dbFile = await resolvePrivateDatabaseFile(
      config,
      baseDirectoryOverride: baseDir,
    );
    var db = AppDatabase.forTesting(NativeDatabase(dbFile));
    var tx = DatabaseTransactionRunner(db);
    final media = NativeMediaStorageService(
      config: config,
      idGenerator: idGen,
      baseDirectoryOverride: baseDir,
    );

    final lotRepo = LotRepositoryImpl(db, tx, idGen, media);
    final procRepo = ProcessRepositoryImpl(db, tx, idGen);
    final workerRepo = WorkerRepositoryImpl(db, tx, idGen);
    final rateRepo = RateRepositoryImpl(db, tx, idGen);
    final stockRepo = StockMovementRepositoryImpl(db, tx, idGen);
    final acctRepo = AccountingRepositoryImpl(db, tx, idGen);
    final reportsRepo = ReportsRepositoryImpl(db, stockRepo, acctRepo);
    final backupSvc = NativeBackupRestoreService(
      db,
      config,
      idGen,
      baseDirectoryOverride: baseDir,
      tempDirectoryOverride: tempDir,
    );

    // 1-3. Create Lot, Photo, Design, Colour (100 pcs @ ₹250)
    final nov28Ist = IstDateTimeHelper.istDateTimeToUtcMillis(
      year: 2026,
      month: 11,
      day: 28,
      hour: 10,
    );
    final dec05Ist = IstDateTimeHelper.istDateTimeToUtcMillis(
      year: 2026,
      month: 12,
      day: 5,
      hour: 15,
    );

    final lot = await lotRepo.createLot(
      lotNumber: 'LOT-1001',
      title: 'Festive Kurta Batch',
      transactionAtUtcMillis: nov28Ist,
    );
    final photoBytes = Uint8List.fromList([137, 80, 78, 71, 1, 2, 3, 4, 5]);
    final photo = await lotRepo.addLotPhoto(
      lotId: lot.id,
      bytes: photoBytes,
      fileExtension: 'png',
      mimeType: 'image/png',
      caption: 'Fabric swatch',
    );
    final design = await lotRepo.createDesign(
      lotId: lot.id,
      designName: 'Design A',
    );
    final colour = await lotRepo.createDesignColour(
      lotDesignId: design.id,
      colourName: 'Royal Red',
      initialQuantity: 100,
      unitPricePaise: 25000,
    );

    // 4-6. Processes, Workers & Assignments
    final cutting = await procRepo.createProcess(name: 'Cutting');
    final stitching = await procRepo.createProcess(
      name: 'Stitching',
      includeDamagedInLabour: true,
    );
    final packing = await procRepo.createProcess(
      name: 'Packing',
      billingModeOverride: ProcessBillingModeOverride.givenQty,
    );

    final hasmukh = await workerRepo.createWorker(
      name: 'Hasmukh Bhai',
      phone: '9876543210',
    );
    final ravi = await workerRepo.createWorker(name: 'Ravi Bhai');

    await workerRepo.assignProcessToWorker(
      workerId: hasmukh.id,
      processId: cutting.id,
    );
    await workerRepo.assignProcessToWorker(
      workerId: ravi.id,
      processId: stitching.id,
    );
    await workerRepo.assignProcessToWorker(
      workerId: ravi.id,
      processId: packing.id,
    );

    // 7. Historical Rates: Cutting ₹20 until Nov 30, ₹30 from Dec 1; Stitching ₹40
    await rateRepo.addRate(
      workerId: hasmukh.id,
      processId: cutting.id,
      ratePaise: 2000,
      effectiveFrom: '2026-11-01',
      effectiveTo: '2026-11-30',
    );
    await rateRepo.addRate(
      workerId: hasmukh.id,
      processId: cutting.id,
      ratePaise: 3000,
      effectiveFrom: '2026-12-01',
    );
    await rateRepo.addRate(
      workerId: ravi.id,
      processId: stitching.id,
      ratePaise: 4000,
      effectiveFrom: '2026-11-01',
    );

    // 8. Issue 100 pcs to Cutting on Nov 28 -> locks ₹20 rate
    final reqId = idGen.nextRequestId();
    final issue1 = await stockRepo.issueStock(
      designColourId: colour.id,
      processId: cutting.id,
      workerId: hasmukh.id,
      quantity: 100,
      transactionAtUtcMillis: nov28Ist,
      clientRequestId: reqId,
    );
    expect(issue1.appliedRatePaise, 2000);

    // Duplicate submission with same clientRequestId is idempotent
    final dupIssue = await stockRepo.issueStock(
      designColourId: colour.id,
      processId: cutting.id,
      workerId: hasmukh.id,
      quantity: 100,
      transactionAtUtcMillis: nov28Ist,
      clientRequestId: reqId,
    );
    expect(dupIssue.id, issue1.id);

    // 9. Receive partial 80 good pcs on Dec 5 (AFTER Dec 1 hike to ₹30) -> inherits ₹20!
    final ret1 = await stockRepo.recordSettlement(
      parentIssueId: issue1.id,
      goodQuantity: 80,
      damagedQuantity: 0,
      lostQuantity: 0,
      shortageQuantity: 0,
      transactionAtUtcMillis: dec05Ist,
    );
    expect(ret1.remainingPending, 20);
    expect(ret1.createdMovements.single.appliedRatePaise, 2000);

    // 10. Settle remaining 20 as 15 good + 3 damaged + 2 lost
    final ret2 = await stockRepo.recordSettlement(
      parentIssueId: issue1.id,
      goodQuantity: 15,
      damagedQuantity: 3,
      lostQuantity: 2,
      shortageQuantity: 0,
      transactionAtUtcMillis: dec05Ist + 1000,
      reason: 'Fabric tear and transit loss',
    );
    expect(ret2.remainingPending, 0);

    // 11. Issue 80 good pcs to Stitching (Ravi Bhai)
    final issue2 = await stockRepo.issueStock(
      designColourId: colour.id,
      processId: stitching.id,
      workerId: ravi.id,
      quantity: 80,
      transactionAtUtcMillis: dec05Ist + 2000,
    );
    expect(issue2.appliedRatePaise, 4000);

    // Attempting to reverse ret1 (80 good returned) MUST be blocked by downstream issue2!
    await expectLater(
      stockRepo.reverseMovement(
        movementId: ret1.createdMovements.single.id,
        reason: 'Try invalid reversal',
        transactionAtUtcMillis: dec05Ist + 3000,
      ),
      throwsA(
        isA<DomainValidationException>().having(
          (e) => e.code,
          'code',
          'downstream_stock_dependency',
        ),
      ),
    );

    // 12. Repair 2 of 3 damaged pcs back to good
    await stockRepo.recordDamagedToGoodAdjustment(
      designColourId: colour.id,
      quantity: 2,
      reason: 'Re-stitched in house',
      transactionAtUtcMillis: dec05Ist + 4000,
    );

    final liveBal = await stockRepo.getDesignColourBalance(colour.id);
    expect(liveBal!.physicalAvailableInHouse, 17); // 95 - 80 + 2
    expect(liveBal.damagedBucket, 1);
    expect(liveBal.totalPendingWithWorkers, 80);
    expect(liveBal.totalLost, 2);

    // 13-15. Labour, Advance, Payment, Adjustment & Worker Ledger
    // Hasmukh Bhai earned (80 + 15) * ₹20 = ₹1,900 (damaged 3 not included on Cutting)
    await acctRepo.recordPayment(
      workerId: hasmukh.id,
      paymentType: PaymentType.advance,
      amountPaise: 100000, // ₹1,000 advance
      paymentMode: PaymentMode.cash,
      transactionAtUtcMillis: nov28Ist,
    );
    await acctRepo.recordPayment(
      workerId: hasmukh.id,
      paymentType: PaymentType.regular,
      amountPaise: 50000, // ₹500 regular payment
      paymentMode: PaymentMode.upi,
      referenceNo: 'UPI-8899',
      transactionAtUtcMillis: dec05Ist + 5000,
    );
    await acctRepo.recordAdjustment(
      workerId: hasmukh.id,
      adjustmentType: WorkerAdjustmentType.credit,
      amountPaise: 10000, // +₹100 bonus
      reason: 'Urgent delivery bonus',
      transactionAtUtcMillis: dec05Ist + 6000,
    );

    final hasmukhLedger = await acctRepo.getWorkerLedgerDetail(hasmukh.id);
    expect(hasmukhLedger!.summary.earnedLabourPaise, 190000);
    expect(hasmukhLedger.summary.advancePaymentsPaise, 100000);
    expect(hasmukhLedger.summary.regularPaymentsPaise, 50000);
    expect(hasmukhLedger.summary.adjustmentCreditsPaise, 10000);
    // 1900 + 100 - 1000 - 500 = ₹500 outstanding
    expect(hasmukhLedger.summary.outstandingPayablePaise, 50000);
    expect(hasmukhLedger.summary.advanceCreditBalancePaise, 0);

    // Dashboard & Reports verification
    final dash = await reportsRepo.getDashboardSnapshot();
    expect(dash.totalLots, 1);
    expect(dash.availableGoodStock, 17);
    expect(dash.damagedStock, 1);
    expect(dash.pendingWorkerStock, 80);
    expect(dash.totalEarnedLabourPaise, 190000);
    expect(dash.totalOutstandingPayablePaise, 50000);

    final reports = await reportsRepo.getBusinessReports();
    expect(reports.lotRows.single.availableGoodStock, 17);
    expect(reports.openIssues.length, 1);
    expect(reports.damagedLostShortageMovements.length, 3);
    expect(reports.payments.length, 2);

    // 16. Export Raw SQLite + Full ZIP Backup
    final rawExport = await backupSvc.exportRawSqlite(
      destinationDirectoryPath: tempDir.path,
    );
    expect(File(rawExport.filePath).existsSync(), isTrue);
    expect(rawExport.sizeBytes, greaterThan(0));

    final fullBackup = await backupSvc.createFullZipBackup(
      destinationDirectoryPath: tempDir.path,
    );
    expect(File(fullBackup.filePath).existsSync(), isTrue);
    expect(fullBackup.manifest!.attachmentsCount, 1);
    expect(fullBackup.manifest!.summaryCounts.lotsCount, 1);

    // Cross-flavor safety: Prod service rejects Dev backup
    final prodBackupSvc = NativeBackupRestoreService(
      db,
      AppConfig.prod(),
      idGen,
      baseDirectoryOverride: baseDir,
      tempDirectoryOverride: tempDir,
    );
    final prodCheck = await prodBackupSvc.validateBackupZip(
      fullBackup.filePath,
    );
    expect(prodCheck.isValid, isFalse);
    expect(prodCheck.errorCodes, contains('cross_flavor_blocked'));

    // Tampered ZIP checksum detection
    final tamperedPath = p.join(tempDir.path, 'tampered.zip');
    final origArchive = ZipDecoder().decodeBytes(
      await File(fullBackup.filePath).readAsBytes(),
    );
    final badArchive = Archive();
    for (final f in origArchive) {
      if (f.name == 'database.sqlite') {
        badArchive.addFile(ArchiveFile(f.name, 4, [1, 2, 3, 4]));
      } else {
        badArchive.addFile(f);
      }
    }
    await File(tamperedPath).writeAsBytes(ZipEncoder().encode(badArchive));
    final tamperCheck = await backupSvc.validateBackupZip(tamperedPath);
    expect(tamperCheck.isValid, isFalse);
    expect(tamperCheck.errorCodes, contains('database_checksum_mismatch'));

    // 17. Mutate live DB (add extra lot + delete media photo) then Restore
    await lotRepo.createLot(
      lotNumber: 'LOT-TEMP-AFTER-BACKUP',
      transactionAtUtcMillis: dec05Ist + 9000,
    );
    await media.deleteIfExists(photo.relativePath);
    expect(await media.exists(photo.relativePath), isFalse);

    // 18. Execute Atomic Restore -> verify ALL original data & photo restored!
    final restoreResult = await backupSvc.restoreFromZip(fullBackup.filePath);
    expect(restoreResult.restoredAttachmentsCount, 1);

    // Reopen fresh DB handle against restored file
    db = AppDatabase.forTesting(NativeDatabase(dbFile));
    tx = DatabaseTransactionRunner(db);
    final restoredLotRepo = LotRepositoryImpl(db, tx, idGen, media);
    final restoredStockRepo = StockMovementRepositoryImpl(db, tx, idGen);
    final restoredAcctRepo = AccountingRepositoryImpl(db, tx, idGen);

    final restoredLots = await restoredLotRepo.getLots();
    expect(restoredLots.length, 1);
    expect(restoredLots.single.lotNumber, 'LOT-1001');

    // Photo bytes & SHA-256 preserved!
    final restoredPhotoBytes = await media.readBytes(photo.relativePath);
    expect(restoredPhotoBytes, photoBytes);

    // Stock & Worker Ledger intact after restore!
    final restoredBal = await restoredStockRepo.getDesignColourBalance(
      colour.id,
    );
    expect(restoredBal!.physicalAvailableInHouse, 17);
    expect(restoredBal.damagedBucket, 1);
    expect(restoredBal.totalPendingWithWorkers, 80);

    final restoredLedger = await restoredAcctRepo.getWorkerLedgerDetail(
      hasmukh.id,
    );
    expect(restoredLedger!.summary.outstandingPayablePaise, 50000);

    // BACKUP_RESTORE audit log present!
    final auditLogs = await db.attachmentAuditDao.getRecentAuditLogs(limit: 5);
    expect(auditLogs.any((a) => a.actionType == 'BACKUP_RESTORE'), isTrue);

    await db.close();
  });
}
