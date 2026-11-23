import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/processes/data/repositories/process_repository_impl.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/rates/data/repositories/rate_repository_impl.dart';
import 'package:business_manager/features/rates/domain/entities/rate_entities.dart';
import 'package:business_manager/features/workers/data/repositories/worker_repository_impl.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late ProcessRepositoryImpl processRepo;
  late WorkerRepositoryImpl workerRepo;
  late RateRepositoryImpl rateRepo;

  setUpAll(() {
    IstDateTimeHelper.initialize();
  });

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final txRunner = DatabaseTransactionRunner(db);
    final idGen = IdGenerator();
    processRepo = ProcessRepositoryImpl(db, txRunner, idGen);
    workerRepo = WorkerRepositoryImpl(db, txRunner, idGen);
    rateRepo = RateRepositoryImpl(db, txRunner, idGen);
  });

  tearDown(() async {
    await db.close();
  });

  group('Module A — Dynamic Process Management', () {
    test('creates, updates, searches, activates/deactivates and logs audit history', () async {
      final created = await processRepo.createProcess(
        name: 'Cutting',
        description: 'Initial fabric cutting',
        billingModeOverride: ProcessBillingModeOverride.receivedQty,
        includeDamagedInLabour: false,
      );
      expect(created.name, 'Cutting');
      expect(created.isActive, isTrue);

      // Duplicate name (case-insensitive) is rejected
      await expectLater(
        () => processRepo.createProcess(name: '  cutting  '),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'duplicate_process_name',
          ),
        ),
      );

      // Update
      final updated = await processRepo.updateProcess(
        processId: created.id,
        name: 'Master Cutting',
        description: 'Updated description',
        billingModeOverride: ProcessBillingModeOverride.givenQty,
        includeDamagedInLabour: true,
      );
      expect(updated.name, 'Master Cutting');
      expect(updated.billingModeOverride, ProcessBillingModeOverride.givenQty);
      expect(updated.includeDamagedInLabour, isTrue);

      // Deactivate & Reactivate
      final deactivated = await processRepo.setProcessActive(
        processId: created.id,
        isActive: false,
      );
      expect(deactivated.isActive, isFalse);

      final activeList = await processRepo.getProcesses(isActiveFilter: true);
      expect(activeList, isEmpty);
      final inactiveList = await processRepo.getProcesses(
        isActiveFilter: false,
      );
      expect(inactiveList.length, 1);

      final reactivated = await processRepo.setProcessActive(
        processId: created.id,
        isActive: true,
      );
      expect(reactivated.isActive, isTrue);

      // Detail includes full audit history
      final detail = await processRepo.getProcessDetail(created.id);
      expect(detail, isNotNull);
      final actionTypes = detail!.auditHistory.map((a) => a.actionType).toSet();
      expect(
        actionTypes,
        containsAll(['CREATE', 'UPDATE', 'DEACTIVATE', 'REACTIVATE']),
      );
    });
  });

  group('Module B & C — Workers & Many-to-Many Assignments', () {
    test(
      'creates, updates, searches, and filters active/inactive workers',
      () async {
        final hasmukh = await workerRepo.createWorker(
          name: 'Hasmukh Bhai',
          phone: '9876543210',
          address: 'Surat Textile Market',
          notes: 'Senior karigar',
        );
        final rakesh = await workerRepo.createWorker(
          name: 'Rakesh Bhai',
          phone: '9988776655',
        );

        expect(
          (await workerRepo.getWorkers(searchQuery: 'surat')).single.id,
          hasmukh.id,
        );

        final updated = await workerRepo.updateWorker(
          workerId: rakesh.id,
          name: 'Rakesh Kumar',
          phone: '9988776655',
          address: 'Ring Road',
        );
        expect(updated.name, 'Rakesh Kumar');
        expect(updated.address, 'Ring Road');

        await workerRepo.setWorkerActive(workerId: rakesh.id, isActive: false);
        expect((await workerRepo.getWorkers(isActiveFilter: true)).length, 1);
        expect((await workerRepo.getWorkers(isActiveFilter: false)).length, 1);
      },
    );

    test('supports many-to-many assignments and rejects duplicates or inactive entities', () async {
      final cutting = await processRepo.createProcess(name: 'Cutting');
      final press = await processRepo.createProcess(name: 'Press');
      final hasmukh = await workerRepo.createWorker(name: 'Hasmukh Bhai');
      final rakesh = await workerRepo.createWorker(name: 'Rakesh Bhai');

      // One worker -> multiple processes
      await workerRepo.assignProcessToWorker(
        workerId: hasmukh.id,
        processId: cutting.id,
      );
      await workerRepo.assignProcessToWorker(
        workerId: hasmukh.id,
        processId: press.id,
      );

      // One process -> multiple workers
      await workerRepo.assignProcessToWorker(
        workerId: rakesh.id,
        processId: cutting.id,
      );

      expect((await workerRepo.getAssignmentsForWorker(hasmukh.id)).length, 2);
      final cuttingDetail = await processRepo.getProcessDetail(cutting.id);
      expect(cuttingDetail!.assignedWorkers.length, 2);

      // Duplicate active assignment rejected
      await expectLater(
        () => workerRepo.assignProcessToWorker(
          workerId: hasmukh.id,
          processId: cutting.id,
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'duplicate_assignment',
          ),
        ),
      );

      // Deactivate and re-assign reactivates same link cleanly
      await workerRepo.deactivateAssignment(
        workerId: hasmukh.id,
        processId: press.id,
      );
      expect((await workerRepo.getAssignmentsForWorker(hasmukh.id)).length, 1);
      await workerRepo.assignProcessToWorker(
        workerId: hasmukh.id,
        processId: press.id,
      );
      expect((await workerRepo.getAssignmentsForWorker(hasmukh.id)).length, 2);

      // Inactive worker rejected
      await workerRepo.setWorkerActive(workerId: rakesh.id, isActive: false);
      await expectLater(
        () => workerRepo.assignProcessToWorker(
          workerId: rakesh.id,
          processId: press.id,
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'inactive_worker',
          ),
        ),
      );

      // Inactive process rejected
      final stitching = await processRepo.createProcess(name: 'Stitching');
      await processRepo.setProcessActive(
        processId: stitching.id,
        isActive: false,
      );
      await expectLater(
        () => workerRepo.assignProcessToWorker(
          workerId: hasmukh.id,
          processId: stitching.id,
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'inactive_process',
          ),
        ),
      );
    });
  });

  group('Module D — Historical Per-Piece Rates', () {
    test('enforces non-overlap, supports auto-close, resolves IST dates, and protects historical rates', () async {
      final cutting = await processRepo.createProcess(name: 'Cutting');
      final hasmukh = await workerRepo.createWorker(name: 'Hasmukh Bhai');
      await workerRepo.assignProcessToWorker(
        workerId: hasmukh.id,
        processId: cutting.id,
      );

      // Add initial open-ended rate ₹20 from 2026-01-01
      final r1 = await rateRepo.addRate(
        workerId: hasmukh.id,
        processId: cutting.id,
        ratePaise: 2000,
        effectiveFrom: '2026-01-01',
      );
      expect(r1.ratePaise, 2000);
      expect(r1.effectiveTo, isNull);

      // Adding another open-ended rate without autoClose is rejected
      await expectLater(
        () => rateRepo.addRate(
          workerId: hasmukh.id,
          processId: cutting.id,
          ratePaise: 3000,
          effectiveFrom: '2026-12-01',
          autoClosePreviousOpenRate: false,
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'rate_multiple_open_ended',
          ),
        ),
      );

      // With autoClosePreviousOpenRate=true, r1 is closed to 2026-11-30 and r2 opens 2026-12-01
      final r2 = await rateRepo.addRate(
        workerId: hasmukh.id,
        processId: cutting.id,
        ratePaise: 3000,
        effectiveFrom: '2026-12-01',
        autoClosePreviousOpenRate: true,
      );
      final history = await rateRepo.getRateHistory(
        workerId: hasmukh.id,
        processId: cutting.id,
      );
      expect(history.length, 2);
      final refreshedR1 = history.firstWhere((r) => r.id == r1.id);
      expect(refreshedR1.effectiveTo, '2026-11-30');
      expect(r2.effectiveTo, isNull);

      // Overlapping closed period is rejected
      await expectLater(
        () => rateRepo.addRate(
          workerId: hasmukh.id,
          processId: cutting.id,
          ratePaise: 2500,
          effectiveFrom: '2026-11-15',
          effectiveTo: '2026-11-25',
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'rate_overlap',
          ),
        ),
      );

      // IST midnight boundary resolution via RateRepository
      final nov30Ist = await rateRepo.resolveRate(
        workerId: hasmukh.id,
        processId: cutting.id,
        transactionAtUtcMillis: DateTime.utc(
          2026,
          11,
          30,
          18,
          0,
        ).millisecondsSinceEpoch,
      );
      expect((nov30Ist as RateResolutionFound).rate.ratePaise, 2000);

      final dec01Ist = await rateRepo.resolveRate(
        workerId: hasmukh.id,
        processId: cutting.id,
        transactionAtUtcMillis: DateTime.utc(
          2026,
          11,
          30,
          19,
          0,
        ).millisecondsSinceEpoch,
      );
      expect((dec01Ist as RateResolutionFound).rate.ratePaise, 3000);

      // Safe edit works when rate is NOT referenced by stock movements
      final editedR2 = await rateRepo.updateRate(
        rateId: r2.id,
        ratePaise: 3200,
        effectiveFrom: '2026-12-01',
        notes: 'Revised winter rate',
      );
      expect(editedR2.ratePaise, 3200);

      // Simulate a historical stock movement referencing r1 -> editing r1 must be blocked
      final now = IstDateTimeHelper.nowUtcMillis();
      await db.lotDao.insertLot(
        LotsCompanion(
          id: const Value('lot1'),
          lotNumber: const Value('LOT-001'),
          status: const Value('ACTIVE'),
          transactionAt: Value(now),
          recordedAt: Value(now),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await db.lotDao.insertDesign(
        LotDesignsCompanion(
          id: const Value('des1'),
          lotId: const Value('lot1'),
          designName: const Value('D1'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await db.lotDao.insertDesignColour(
        DesignColoursCompanion(
          id: const Value('col1'),
          lotDesignId: const Value('des1'),
          colourName: const Value('Red'),
          initialQuantity: const Value(100),
          unitPricePaise: const Value(50000),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await db.stockMovementDao.insertMovement(
        StockMovementsCompanion(
          id: const Value('sm1'),
          lotId: const Value('lot1'),
          lotDesignId: const Value('des1'),
          designColourId: const Value('col1'),
          processId: Value(cutting.id),
          memberId: Value(hasmukh.id),
          movementType: const Value('ISSUE'),
          quantity: const Value(50),
          sourceRateId: Value(r1.id),
          appliedRatePaise: const Value(2000),
          transactionAt: Value(now),
          recordedAt: Value(now),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      expect(await rateRepo.isRateLockedByHistory(r1.id), isTrue);
      await expectLater(
        () => rateRepo.updateRate(
          rateId: r1.id,
          ratePaise: 9999,
          effectiveFrom: '2026-01-01',
          effectiveTo: '2026-11-30',
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'rate_locked_by_history',
          ),
        ),
      );

      // Worker profile detail summarizes assigned processes & current rates
      final workerDetail = await workerRepo.getWorkerDetail(
        hasmukh.id,
        asOfUtcMillis: DateTime.utc(2026, 12, 10).millisecondsSinceEpoch,
      );
      expect(workerDetail, isNotNull);
      expect(workerDetail!.assignedProcesses.length, 1);
      expect(workerDetail.assignedProcesses.first.currentRate?.ratePaise, 3200);
      expect(workerDetail.assignedProcesses.first.totalRateHistoryCount, 2);
    });
  });
}
