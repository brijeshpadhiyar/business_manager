import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/database/migrations/database_migration_manager.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/features/process_routing/data/repositories/process_routing_repository_impl.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/stock_movements/data/repositories/stock_movement_repository_impl.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late DatabaseTransactionRunner txRunner;
  late IdGenerator idGen;
  late StockMovementRepositoryImpl stockRepo;
  late ProcessRoutingRepositoryImpl routingRepo;

  const baseTs = 1795411200000; // 2026-11-24 IST

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    txRunner = DatabaseTransactionRunner(db);
    idGen = IdGenerator();
    stockRepo = StockMovementRepositoryImpl(db, txRunner, idGen);
    routingRepo = ProcessRoutingRepositoryImpl(db, txRunner, stockRepo, idGen);
    await db.verifyPragmas();

    // Seed Job #1001 with 500 pcs
    await db.lotDao.insertLot(
      const LotsCompanion(
        id: Value('lot-1001'),
        lotNumber: Value('1001'),
        title: Value('Festive Kurti Order'),
        transactionAt: Value(baseTs),
        recordedAt: Value(baseTs),
        createdAt: Value(baseTs),
        updatedAt: Value(baseTs),
      ),
    );
    await db.lotDao.insertDesign(
      const LotDesignsCompanion(
        id: Value('des-1'),
        lotId: Value('lot-1001'),
        designName: Value('Anarkali A1'),
        createdAt: Value(baseTs),
        updatedAt: Value(baseTs),
      ),
    );
    await db.lotDao.insertDesignColour(
      const DesignColoursCompanion(
        id: Value('sku-1'),
        lotDesignId: Value('des-1'),
        colourName: Value('Maroon'),
        initialQuantity: Value(500),
        unitPricePaise: Value(45000),
        createdAt: Value(baseTs),
        updatedAt: Value(baseTs),
      ),
    );

    // Seed Operations: Cutting, Stitching, Checking, Finishing, Ironing, Packing, Dispatch
    for (final (id, name) in const [
      ('p-cut', 'Cutting'),
      ('p-stitch', 'Stitching'),
      ('p-check', 'Checking'),
      ('p-finish', 'Finishing'),
      ('p-iron', 'Ironing'),
      ('p-pack', 'Packing'),
      ('p-disp', 'Dispatch'),
    ]) {
      await db.processMemberDao.insertProcess(
        ProcessesCompanion.insert(
          id: id,
          name: name,
          createdAt: baseTs,
          updatedAt: baseTs,
        ),
      );
    }

    // Seed Workers / Departments
    for (final (id, name) in const [
      ('w-dharmesh', 'Dharmesh Bhai'),
      ('w-ramesh', 'Ramesh Tailor'),
      ('w-meena', 'Meena Checker'),
      ('w-packing', 'Packing Department'),
    ]) {
      await db.processMemberDao.insertMember(
        MembersCompanion.insert(
          id: id,
          name: name,
          createdAt: baseTs,
          updatedAt: baseTs,
        ),
      );
    }
  });

  tearDown(() async {
    await db.close();
  });

  test(
    '1 & 2. Adds unlimited operations (including repeated operations) with multiple workers',
    () async {
      // Add Cutting (Pending), Stitching (Pending), Checking #1 (Pending), Checking #2 (Pending)
      final cut = await routingRepo.addJobProcess(
        lotId: 'lot-1001',
        designColourId: 'sku-1',
        processId: 'p-cut',
        workerId: 'w-dharmesh',
        quantity: 200,
        transactionAtUtcMillis: baseTs,
        dispatchImmediately: true,
      );
      final stitch = await routingRepo.addJobProcess(
        lotId: 'lot-1001',
        designColourId: 'sku-1',
        processId: 'p-stitch',
        workerId: 'w-ramesh',
        quantity: 150,
        transactionAtUtcMillis: baseTs + 1000,
        dispatchImmediately: true,
      );
      final check1 = await routingRepo.addJobProcess(
        lotId: 'lot-1001',
        designColourId: 'sku-1',
        processId: 'p-check',
        workerId: 'w-meena',
        quantity: 100,
        transactionAtUtcMillis: baseTs + 2000,
        dispatchImmediately: false,
      );
      // Repeat the exact same Checking operation a second time
      final check2 = await routingRepo.addJobProcess(
        lotId: 'lot-1001',
        designColourId: 'sku-1',
        processId: 'p-check',
        workerId: 'w-meena',
        quantity: 50,
        transactionAtUtcMillis: baseTs + 3000,
        dispatchImmediately: false,
      );

      expect(cut.status, JobProcessStatus.dispatched);
      expect(stitch.status, JobProcessStatus.dispatched);
      expect(check1.status, JobProcessStatus.pending);
      expect(check2.status, JobProcessStatus.pending);

      // Edit planned quantity on pending operation & cancel check2 with audit
      final edited = await routingRepo.editJobProcess(
        jobProcessId: check1.id,
        plannedQuantity: 120,
        notes: 'Extra QC pass',
      );
      expect(edited.plannedQuantity, 120);

      final cancelled = await routingRepo.cancelJobProcess(
        jobProcessId: check2.id,
        reason: 'Merged into Checking #1',
        transactionAtUtcMillis: baseTs + 4000,
      );
      expect(cancelled.status, JobProcessStatus.cancelled);

      final overview = (await routingRepo.getJobRoutingOverview('lot-1001'))!;
      expect(overview.jobProcesses.length, 4);
      expect(overview.totalFactoryAvailable, 150); // 500 - 200 - 150
      expect(overview.totalPendingWithWorkers, 350);
    },
  );

  test(
    '3. Scenario A: Direct Cutting-to-Packing transfer updates both workers & timeline',
    () async {
      // 1. Factory dispatches 500 pcs to Dharmesh Bhai for Cutting
      final cutting = await routingRepo.addJobProcess(
        lotId: 'lot-1001',
        designColourId: 'sku-1',
        processId: 'p-cut',
        workerId: 'w-dharmesh',
        quantity: 500,
        transactionAtUtcMillis: baseTs,
        dispatchImmediately: true,
      );
      expect(cutting.pendingQuantity, 500);

      // 2. Dharmesh directly transfers 500 pcs to Packing Department
      final transfer = await routingRepo.directTransfer(
        sourceJobProcessId: cutting.id,
        destinationProcessId: 'p-pack',
        destinationWorkerId: 'w-packing',
        quantity: 500,
        transactionAtUtcMillis: baseTs + 60000,
        autoConfirmReceipt: false,
        notes: 'Cutting complete, sent straight to Packing',
      );

      expect(transfer.handoverType, ProcessHandoverType.directTransfer);
      expect(transfer.transferReference, startsWith('TRF-'));
      expect(transfer.fromMemberName, 'Dharmesh Bhai');
      expect(transfer.toMemberName, 'Packing Department');
      expect(transfer.quantityDispatched, 500);
      expect(transfer.quantityReceived, 0);
      expect(transfer.status, ProcessHandoverStatus.pendingReceipt);

      // 3. Packing Department confirms receipt (partial 200, then remaining 300)
      final partialRcpt = await routingRepo.confirmHandoverReceipt(
        handoverId: transfer.id,
        receivedQuantity: 200,
        transactionAtUtcMillis: baseTs + 120000,
      );
      expect(partialRcpt.status, ProcessHandoverStatus.partiallyReceived);
      expect(partialRcpt.quantityReceived, 200);

      final fullRcpt = await routingRepo.confirmHandoverReceipt(
        handoverId: transfer.id,
        receivedQuantity: 300,
        transactionAtUtcMillis: baseTs + 180000,
      );
      expect(fullRcpt.status, ProcessHandoverStatus.received);
      expect(fullRcpt.quantityReceived, 500);

      // Verify conservation of stock & both workers' histories
      final overview = (await routingRepo.getJobRoutingOverview('lot-1001'))!;
      expect(overview.totalFactoryAvailable, 0);
      expect(overview.totalPendingWithWorkers, 500);

      final updatedCut = overview.jobProcesses.firstWhere(
        (p) => p.id == cutting.id,
      );
      expect(updatedCut.status, JobProcessStatus.transferred);
      expect(updatedCut.pendingQuantity, 0);
      expect(updatedCut.transferredOutQuantity, 500);

      final packing = overview.jobProcesses.firstWhere(
        (p) => p.id == transfer.toJobProcessId,
      );
      expect(packing.status, JobProcessStatus.inProgress);
      expect(packing.receivedQuantity, 500);
      expect(packing.pendingQuantity, 500);

      final dharmeshHistory = await db.jobProcessDao.getHandoversForMember(
        'w-dharmesh',
      );
      final packingHistory = await db.jobProcessDao.getHandoversForMember(
        'w-packing',
      );
      expect(dharmeshHistory.length, 2); // Dispatch + Direct Transfer
      expect(packingHistory.length, 1); // Direct Transfer received
    },
  );

  test(
    '4 & 5. Scenario B: Return to Factory and Reassign to Packing Worker',
    () async {
      final cutting = await routingRepo.addJobProcess(
        lotId: 'lot-1001',
        designColourId: 'sku-1',
        processId: 'p-cut',
        workerId: 'w-dharmesh',
        quantity: 500,
        transactionAtUtcMillis: baseTs,
        dispatchImmediately: true,
      );

      // Dharmesh returns all 500 pcs to Factory
      final ret = await routingRepo.returnToFactory(
        sourceJobProcessId: cutting.id,
        goodQuantity: 500,
        transactionAtUtcMillis: baseTs + 60000,
        notes: 'Verified at factory gate',
      );
      expect(ret.handoverType, ProcessHandoverType.factoryReturn);
      expect(ret.transferReference, startsWith('RET-'));
      expect(ret.toLocationLabel, 'Factory');

      var overview = (await routingRepo.getJobRoutingOverview('lot-1001'))!;
      expect(overview.totalFactoryAvailable, 500);
      expect(overview.totalPendingWithWorkers, 0);
      expect(
        overview.jobProcesses.first.status,
        JobProcessStatus.returned,
      );

      // Factory reassigns 500 pcs to Packing Department (even after Cutting closed!)
      final reassign = await routingRepo.reassignFromFactory(
        lotId: 'lot-1001',
        designColourId: 'sku-1',
        targetProcessId: 'p-pack',
        targetWorkerId: 'w-packing',
        quantity: 500,
        transactionAtUtcMillis: baseTs + 120000,
      );
      expect(reassign.handoverType, ProcessHandoverType.reassignment);
      expect(reassign.transferReference, startsWith('RAS-'));
      expect(reassign.fromLocationLabel, 'Factory');
      expect(reassign.toLocationLabel, 'Packing Department');

      overview = (await routingRepo.getJobRoutingOverview('lot-1001'))!;
      expect(overview.totalFactoryAvailable, 0);
      expect(overview.totalPendingWithWorkers, 500);
      expect(overview.jobProcesses.length, 2);
      expect(overview.handovers.length, 3);
    },
  );

  test(
    '6 & 10. Scenario C: Partial Transfer (300) + Partial Return (150) + Pending (50) + Complete Timeline',
    () async {
      final cutting = await routingRepo.addJobProcess(
        lotId: 'lot-1001',
        designColourId: 'sku-1',
        processId: 'p-cut',
        workerId: 'w-dharmesh',
        quantity: 500,
        transactionAtUtcMillis: baseTs,
        dispatchImmediately: true,
      );

      // 300 transferred directly to Packing
      await routingRepo.directTransfer(
        sourceJobProcessId: cutting.id,
        destinationProcessId: 'p-pack',
        destinationWorkerId: 'w-packing',
        quantity: 300,
        transactionAtUtcMillis: baseTs + 10000,
        autoConfirmReceipt: true,
      );

      // 150 returned to Factory
      await routingRepo.returnToFactory(
        sourceJobProcessId: cutting.id,
        goodQuantity: 150,
        transactionAtUtcMillis: baseTs + 20000,
      );

      // 50 remain pending with Dharmesh
      final overview = (await routingRepo.getJobRoutingOverview('lot-1001'))!;
      final dharmeshOp = overview.jobProcesses.firstWhere(
        (p) => p.id == cutting.id,
      );
      expect(dharmeshOp.dispatchedQuantity, 500);
      expect(dharmeshOp.transferredOutQuantity, 300);
      expect(dharmeshOp.returnedToFactoryQuantity, 150);
      expect(dharmeshOp.pendingQuantity, 50);
      expect(dharmeshOp.status, JobProcessStatus.partiallyCompleted);

      // Total conservation: 150 (Factory) + 300 (Packing) + 50 (Dharmesh) = 500
      expect(overview.totalFactoryAvailable, 150);
      expect(overview.totalPendingWithWorkers, 350);
      expect(overview.currentLocations.length, 3);
      expect(overview.handovers.length, 3);
      expect(
        overview.handovers.map((h) => h.handoverType).toList(),
        [
          ProcessHandoverType.factoryDispatch,
          ProcessHandoverType.directTransfer,
          ProcessHandoverType.factoryReturn,
        ],
      );
    },
  );

  test('7. Multiple chained transfers across 4 operations', () async {
    final cut = await routingRepo.addJobProcess(
      lotId: 'lot-1001',
      designColourId: 'sku-1',
      processId: 'p-cut',
      workerId: 'w-dharmesh',
      quantity: 400,
      transactionAtUtcMillis: baseTs,
      dispatchImmediately: true,
    );
    final t1 = await routingRepo.directTransfer(
      sourceJobProcessId: cut.id,
      destinationProcessId: 'p-stitch',
      destinationWorkerId: 'w-ramesh',
      quantity: 400,
      transactionAtUtcMillis: baseTs + 1000,
      autoConfirmReceipt: true,
    );
    final t2 = await routingRepo.directTransfer(
      sourceJobProcessId: t1.toJobProcessId!,
      destinationProcessId: 'p-check',
      destinationWorkerId: 'w-meena',
      quantity: 400,
      transactionAtUtcMillis: baseTs + 2000,
      autoConfirmReceipt: true,
    );
    final t3 = await routingRepo.directTransfer(
      sourceJobProcessId: t2.toJobProcessId!,
      destinationProcessId: 'p-pack',
      destinationWorkerId: 'w-packing',
      quantity: 400,
      transactionAtUtcMillis: baseTs + 3000,
      autoConfirmReceipt: true,
    );

    final overview = (await routingRepo.getJobRoutingOverview('lot-1001'))!;
    expect(overview.jobProcesses.length, 4);
    expect(overview.handovers.length, 4);
    expect(overview.totalFactoryAvailable, 100); // 500 - 400
    expect(overview.totalPendingWithWorkers, 400);
    final pack = overview.jobProcesses.firstWhere(
      (p) => p.id == t3.toJobProcessId,
    );
    expect(pack.pendingQuantity, 400);
  });

  test(
    '8 & 9. Enforces strict quantity validations and prevents duplicate submissions',
    () async {
      // Cannot dispatch > available (500)
      await expectLater(
        () => routingRepo.addJobProcess(
          lotId: 'lot-1001',
          designColourId: 'sku-1',
          processId: 'p-cut',
          workerId: 'w-dharmesh',
          quantity: 501,
          transactionAtUtcMillis: baseTs,
          dispatchImmediately: true,
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'insufficient_good_stock',
          ),
        ),
      );

      // Idempotent dispatch with clientRequestId
      final jp1 = await routingRepo.addJobProcess(
        lotId: 'lot-1001',
        designColourId: 'sku-1',
        processId: 'p-cut',
        workerId: 'w-dharmesh',
        quantity: 200,
        transactionAtUtcMillis: baseTs,
        dispatchImmediately: true,
        clientRequestId: 'req-unique-1',
      );
      final jp1Replay = await routingRepo.addJobProcess(
        lotId: 'lot-1001',
        designColourId: 'sku-1',
        processId: 'p-cut',
        workerId: 'w-dharmesh',
        quantity: 200,
        transactionAtUtcMillis: baseTs,
        dispatchImmediately: true,
        clientRequestId: 'req-unique-1',
      );
      expect(jp1Replay.id, jp1.id);

      // Cannot transfer more than held (200)
      await expectLater(
        () => routingRepo.directTransfer(
          sourceJobProcessId: jp1.id,
          destinationProcessId: 'p-pack',
          destinationWorkerId: 'w-packing',
          quantity: 201,
          transactionAtUtcMillis: baseTs + 1000,
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'exceeds_held_quantity',
          ),
        ),
      );

      // Cannot return more than outstanding (200)
      await expectLater(
        () => routingRepo.returnToFactory(
          sourceJobProcessId: jp1.id,
          goodQuantity: 250,
          transactionAtUtcMillis: baseTs + 1000,
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'exceeds_pending_quantity',
          ),
        ),
      );

      // Cannot complete while 200 pcs remain unaccounted
      await expectLater(
        () => routingRepo.markProcessCompleted(
          jobProcessId: jp1.id,
          transactionAtUtcMillis: baseTs + 1000,
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'unaccounted_quantity_remaining',
          ),
        ),
      );

      // Cannot cancel while holding stock
      await expectLater(
        () => routingRepo.cancelJobProcess(
          jobProcessId: jp1.id,
          reason: 'Mistake',
          transactionAtUtcMillis: baseTs + 1000,
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'cannot_cancel_with_pending_stock',
          ),
        ),
      );

      // Direct transfer with duplicate clientRequestId returns same handover
      final t1 = await routingRepo.directTransfer(
        sourceJobProcessId: jp1.id,
        destinationProcessId: 'p-pack',
        destinationWorkerId: 'w-packing',
        quantity: 100,
        transactionAtUtcMillis: baseTs + 2000,
        clientRequestId: 'trf-req-1',
      );
      final t1Replay = await routingRepo.directTransfer(
        sourceJobProcessId: jp1.id,
        destinationProcessId: 'p-pack',
        destinationWorkerId: 'w-packing',
        quantity: 100,
        transactionAtUtcMillis: baseTs + 2000,
        clientRequestId: 'trf-req-1',
      );
      expect(t1Replay.id, t1.id);
      expect(t1Replay.transferReference, t1.transferReference);

      // Cannot receive more than dispatched (100)
      await expectLater(
        () => routingRepo.confirmHandoverReceipt(
          handoverId: t1.id,
          receivedQuantity: 101,
          transactionAtUtcMillis: baseTs + 3000,
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'exceeds_dispatched_quantity',
          ),
        ),
      );
    },
  );

  test(
    '11 & 12. Existing job compatibility and v3 -> v4 migration integrity',
    () async {
      // Simulate existing legacy StockMovement issue before any job_processes exist
      await db.processMemberDao.insertMemberProcess(
        MemberProcessesCompanion.insert(
          id: 'mp-legacy',
          memberId: 'w-dharmesh',
          processId: 'p-cut',
          createdAt: baseTs,
          updatedAt: baseTs,
        ),
      );
      await stockRepo.issueStock(
        designColourId: 'sku-1',
        processId: 'p-cut',
        workerId: 'w-dharmesh',
        quantity: 100,
        transactionAtUtcMillis: baseTs,
        allowRateOverride: true,
        overrideRatePaise: 500,
        overrideReason: 'Legacy issue',
      );

      // Verify routing respects the legacy issue (only 400 pcs available in-house!)
      final overview = (await routingRepo.getJobRoutingOverview('lot-1001'))!;
      expect(overview.totalFactoryAvailable, 400);
      expect(overview.totalPendingWithWorkers, 100);

      // Verify idempotent v3 -> v4 upgrade preserves existing records
      await DatabaseMigrationManager.handleOnUpgrade(
        db.createMigrator(),
        db,
        3,
        4,
      );
      final reopenedLot = await db.lotDao.findLotById('lot-1001');
      expect(reopenedLot, isNotNull);
      expect(reopenedLot!.lotNumber, '1001');
    },
  );
}
