import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/features/lots/data/repositories/lot_repository_impl.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/process_routing/data/repositories/process_routing_repository_impl.dart';
import 'package:business_manager/features/process_routing/domain/calculators/process_pricing_calculator.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/process_routing/domain/repositories/process_routing_repository.dart';
import 'package:business_manager/features/stock_movements/data/repositories/stock_movement_repository_impl.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const now = 1795324800000;

  late AppDatabase db;
  late DatabaseTransactionRunner txRunner;
  late IdGenerator idGenerator;
  late LotRepository lotRepo;
  late ProcessRoutingRepository routingRepo;

  Future<void> seedProcessesAndWorkers() async {
    for (final p in const [
      ('p-cut', 'Cutting', 500),
      ('p-stitch', 'Stitching', 1200),
      ('p-pack', 'Packing', 300),
    ]) {
      await db.processMemberDao.insertProcess(
        ProcessesCompanion(
          id: Value(p.$1),
          name: Value(p.$2),
          defaultRatePaise: Value(p.$3),
          defaultPricingUnit: const Value(
            ProcessPricingCalculator.unitPerPiece,
          ),
          createdAt: const Value(now),
          updatedAt: const Value(now),
        ),
      );
    }
    for (final w in const [
      ('w-dharmesh', 'Dharmesh Bhai'),
      ('w-ramesh', 'Ramesh Bhai'),
      ('w-packing', 'Packing Department'),
    ]) {
      await db.processMemberDao.insertMember(
        MembersCompanion(
          id: Value(w.$1),
          name: Value(w.$2),
          createdAt: const Value(now),
          updatedAt: const Value(now),
        ),
      );
    }
  }

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.verifyPragmas();
    txRunner = DatabaseTransactionRunner(db);
    idGenerator = IdGenerator();
    lotRepo = LotRepositoryImpl(
      db,
      txRunner,
      idGenerator,
      NativeMediaStorageService(
        config: AppConfig.dev(),
        idGenerator: idGenerator,
      ),
    );
    final stockRepo = StockMovementRepositoryImpl(db, txRunner, idGenerator);
    routingRepo = ProcessRoutingRepositoryImpl(
      db,
      txRunner,
      stockRepo,
      idGenerator,
    );
    await seedProcessesAndWorkers();
  });

  tearDown(() async {
    await db.close();
  });

  group('StitchFlow V1.3 – 12-Scenario Business Workflow QA', () {
    test(
      'Scenario 1: Lot Creation with multiple designs & colours + exact totals',
      () async {
        final lot = await lotRepo.createLot(
          lotNumber: 'QA-1001',
          title: 'Multi-Design Production Lot',
          transactionAtUtcMillis: now,
        );
        final d101 = await lotRepo.createDesign(
          lotId: lot.id,
          designName: 'D-101',
        );
        final d102 = await lotRepo.createDesign(
          lotId: lot.id,
          designName: 'D-102',
        );

        await lotRepo.createDesignColour(
          lotDesignId: d101.id,
          colourName: 'Red',
          colourHex: '#DC2626',
          initialQuantity: 100,
          unitPricePaise: 5000,
        );
        await lotRepo.createDesignColour(
          lotDesignId: d101.id,
          colourName: 'Blue',
          colourHex: '#2563EB',
          initialQuantity: 100,
          unitPricePaise: 5000,
        );
        await lotRepo.createDesignColour(
          lotDesignId: d101.id,
          colourName: 'Green',
          colourHex: '#16A34A',
          initialQuantity: 100,
          unitPricePaise: 5000,
        );
        await lotRepo.createDesignColour(
          lotDesignId: d102.id,
          colourName: 'Black',
          colourHex: '#111827',
          initialQuantity: 100,
          unitPricePaise: 5000,
        );
        await lotRepo.createDesignColour(
          lotDesignId: d102.id,
          colourName: 'Yellow',
          colourHex: '#FACC15',
          initialQuantity: 100,
          unitPricePaise: 5000,
        );

        final detail = (await lotRepo.getLotDetail(lot.id))!;
        expect(detail.designs.length, 2);
        final d101Total = detail.designs
            .firstWhere((d) => d.design.designName == 'D-101')
            .colours
            .fold<int>(0, (s, c) => s + c.initialQuantity);
        final d102Total = detail.designs
            .firstWhere((d) => d.design.designName == 'D-102')
            .colours
            .fold<int>(0, (s, c) => s + c.initialQuantity);
        expect(d101Total, 300);
        expect(d102Total, 200);
        expect(d101Total + d102Total, 500);
      },
    );

    test('Scenario 2: Colour-Only Lot hides internal sentinel in labels & calculates totals', () async {
      final lot = await lotRepo.createLot(
        lotNumber: 'QA-1002',
        transactionAtUtcMillis: now,
      );
      await lotRepo.addColourDirectlyToLot(
        lotId: lot.id,
        colourName: 'Red',
        colourHex: '#DC2626',
        initialQuantity: 200,
        unitPricePaise: 0,
      );
      await lotRepo.addColourDirectlyToLot(
        lotId: lot.id,
        colourName: 'Blue',
        colourHex: '#2563EB',
        initialQuantity: 150,
        unitPricePaise: 0,
      );
      await lotRepo.addColourDirectlyToLot(
        lotId: lot.id,
        colourName: 'Black',
        colourHex: '#111827',
        initialQuantity: 150,
        unitPricePaise: 0,
      );

      final detail = (await lotRepo.getLotDetail(lot.id))!;
      expect(detail.designs.length, 1);
      expect(detail.designs.first.design.designName, kColourOnlyDesignSentinel);
      expect(formatVariantLabel(kColourOnlyDesignSentinel, 'Red'), 'Red');
      expect(
        formatVariantLabel(kColourOnlyDesignSentinel, 'Red'),
        isNot(contains('__NO_DESIGN__')),
      );
      final total = detail.designs.first.colours.fold<int>(
        0,
        (s, c) => s + c.initialQuantity,
      );
      expect(total, 500);
    });

    test('Scenario 3 & 4: Worker Assignment (splitting same variant) + Multiple Variants per worker', () async {
      final lot = await lotRepo.createLot(
        lotNumber: 'QA-1003',
        transactionAtUtcMillis: now,
      );
      final d101 = await lotRepo.createDesign(
        lotId: lot.id,
        designName: 'D-101',
      );
      final red = await lotRepo.createDesignColour(
        lotDesignId: d101.id,
        colourName: 'Red',
        initialQuantity: 200,
        unitPricePaise: 0,
      );
      final blue = await lotRepo.createDesignColour(
        lotDesignId: d101.id,
        colourName: 'Blue',
        initialQuantity: 300,
        unitPricePaise: 0,
      );

      // Split D-101 Red: Dharmesh 60, Ramesh 40 -> 100 left in factory
      await routingRepo.addJobProcess(
        lotId: lot.id,
        designColourId: red.id,
        processId: 'p-cut',
        workerId: 'w-dharmesh',
        quantity: 60,
        transactionAtUtcMillis: now,
      );
      await routingRepo.addJobProcess(
        lotId: lot.id,
        designColourId: red.id,
        processId: 'p-cut',
        workerId: 'w-ramesh',
        quantity: 40,
        transactionAtUtcMillis: now,
      );
      // Dharmesh also receives 100 of D-101 Blue
      await routingRepo.addJobProcess(
        lotId: lot.id,
        designColourId: blue.id,
        processId: 'p-cut',
        workerId: 'w-dharmesh',
        quantity: 100,
        transactionAtUtcMillis: now,
      );

      final overview = (await routingRepo.getJobRoutingOverview(lot.id))!;
      final redBal = overview.skuBalances.firstWhere(
        (b) => b.designColourId == red.id,
      );
      final blueBal = overview.skuBalances.firstWhere(
        (b) => b.designColourId == blue.id,
      );
      expect(redBal.physicalAvailableInHouse, 100);
      expect(redBal.totalPendingWithWorkers, 100);
      expect(blueBal.physicalAvailableInHouse, 200);
      expect(blueBal.totalPendingWithWorkers, 100);
      expect(overview.totalInitialQuantity, 500);
    });

    test(
      'Scenario 5: Direct Worker Transfer (100 -> 60 Packing + 40 remain)',
      () async {
        final lot = await lotRepo.createLot(
          lotNumber: 'QA-1005',
          transactionAtUtcMillis: now,
        );
        final red = await lotRepo.addColourDirectlyToLot(
          lotId: lot.id,
          colourName: 'Red',
          initialQuantity: 100,
          unitPricePaise: 0,
        );
        final cutOp = await routingRepo.addJobProcess(
          lotId: lot.id,
          designColourId: red.id,
          processId: 'p-cut',
          workerId: 'w-dharmesh',
          quantity: 100,
          transactionAtUtcMillis: now,
        );
        final transfer = await routingRepo.directTransfer(
          sourceJobProcessId: cutOp.id,
          destinationProcessId: 'p-pack',
          destinationWorkerId: 'w-packing',
          quantity: 60,
          transactionAtUtcMillis: now,
          autoConfirmReceipt: false,
        );
        expect(transfer.transferReference, startsWith('TRF-'));
        expect(transfer.status, ProcessHandoverStatus.pendingReceipt);

        final confirmed = await routingRepo.confirmHandoverReceipt(
          handoverId: transfer.id,
          receivedQuantity: 60,
          transactionAtUtcMillis: now,
        );
        expect(confirmed.status, ProcessHandoverStatus.received);

        final overview = (await routingRepo.getJobRoutingOverview(lot.id))!;
        final bal = overview.skuBalances.single;
        expect(bal.physicalAvailableInHouse, 0);
        expect(bal.totalPendingWithWorkers, 100);
        final dharmeshOp = overview.jobProcesses.firstWhere(
          (p) => p.id == cutOp.id,
        );
        expect(dharmeshOp.pendingQuantity, 40);
        final packingOp = overview.jobProcesses.firstWhere(
          (p) => p.memberId == 'w-packing',
        );
        expect(packingOp.pendingQuantity, 60);
      },
    );

    test('Scenario 6 & 7: Factory Return (Good + Damaged, Partial & Full) & Partial Split (500 = 300 + 150 + 50)', () async {
      final lot = await lotRepo.createLot(
        lotNumber: 'QA-1007',
        transactionAtUtcMillis: now,
      );
      final black = await lotRepo.addColourDirectlyToLot(
        lotId: lot.id,
        colourName: 'Black',
        initialQuantity: 500,
        unitPricePaise: 0,
      );
      final cut = await routingRepo.addJobProcess(
        lotId: lot.id,
        designColourId: black.id,
        processId: 'p-cut',
        workerId: 'w-dharmesh',
        quantity: 500,
        transactionAtUtcMillis: now,
      );

      // 300 direct transfer to Packing
      await routingRepo.directTransfer(
        sourceJobProcessId: cut.id,
        destinationProcessId: 'p-pack',
        destinationWorkerId: 'w-packing',
        quantity: 300,
        transactionAtUtcMillis: now,
        autoConfirmReceipt: true,
      );
      // 150 return to Factory (145 good + 5 damaged)
      await routingRepo.returnToFactory(
        sourceJobProcessId: cut.id,
        goodQuantity: 145,
        damagedQuantity: 5,
        reason: 'Fabric tear',
        transactionAtUtcMillis: now,
      );

      final overview = (await routingRepo.getJobRoutingOverview(lot.id))!;
      final bal = overview.skuBalances.single;
      expect(bal.physicalAvailableInHouse, 145);
      expect(bal.damagedBucket, 5);
      expect(bal.totalPendingWithWorkers, 350); // 300 Packing + 50 Dharmesh
      expect(
        bal.physicalAvailableInHouse +
            bal.damagedBucket +
            bal.totalPendingWithWorkers,
        500,
      );
      final src = overview.jobProcesses.firstWhere((p) => p.id == cut.id);
      expect(src.pendingQuantity, 50);
    });

    test('Scenario 8, 9 & 10: Dynamic Pricing, Historical Preservation, Charges/Deductions (₹3,050) & Payments', () async {
      final lot = await lotRepo.createLot(
        lotNumber: 'QA-1008',
        transactionAtUtcMillis: now,
      );
      final red = await lotRepo.addColourDirectlyToLot(
        lotId: lot.id,
        colourName: 'Red',
        initialQuantity: 600,
        unitPricePaise: 0,
      );

      // Assign 500 pcs at agreed rate ₹5.90 (590 paise) != default ₹5.00 -> base = ₹2,950.00 (295000 paise)
      final op = await routingRepo.addJobProcess(
        lotId: lot.id,
        designColourId: red.id,
        processId: 'p-cut',
        workerId: 'w-dharmesh',
        quantity: 500,
        agreedRatePaise: 590,
        rateOverrideReason: 'Urgent heavy fabric',
        transactionAtUtcMillis: now,
      );
      // v1.4: earnings follow ACCEPTED pieces only; nothing accepted yet.
      expect(op.payableAmountPaise, 0);

      // Update default process rate to ₹8.00 -> historical assignment must stay ₹5.90
      await routingRepo.updateProcessDefaultRate(
        processId: 'p-cut',
        defaultRatePaise: 800,
        defaultPricingUnit: ProcessPricingCalculator.unitPerPiece,
        reason: 'Seasonal rate revision',
      );
      final history = await routingRepo.getProcessRateHistory('p-cut');
      expect(history.length, greaterThanOrEqualTo(2));

      // Extra charge ₹150 (15000) & Deduction ₹50 (5000) -> Net ₹3,050 (305000 paise)
      await routingRepo.addAdditionalCharge(
        jobProcessId: op.id,
        chargeType: ProcessChargeType.extraCharge,
        description: 'Urgent night shift',
        amountPaise: 15000,
        transactionAtUtcMillis: now,
      );
      await routingRepo.addAdditionalCharge(
        jobProcessId: op.id,
        chargeType: ProcessChargeType.deduction,
        description: 'Minor trimming defect',
        amountPaise: 5000,
        transactionAtUtcMillis: now,
      );

      var overview = (await routingRepo.getJobRoutingOverview(lot.id))!;
      expect(overview.costSummary.totalBasePaise, 0);
      expect(overview.costSummary.totalAdditionalChargesPaise, 15000);
      expect(overview.costSummary.totalDeductionsPaise, 5000);

      // Charges / deductions land in the worker ledger as CREDIT / DEBIT.
      final adjustments = await db.workerAdjustmentDao.getAdjustmentsForMember(
        'w-dharmesh',
      );
      expect(
        adjustments.map((a) => (a.adjustmentType, a.amountPaise)).toSet(),
        {('CREDIT', 15000), ('DEBIT', 5000)},
      );
      expect(adjustments.every((a) => a.jobProcessId == op.id), isTrue);

      // All 500 pcs accepted at the locked ₹5.90 -> base ₹2,950, net ₹3,050.
      await routingRepo.returnToFactory(
        sourceJobProcessId: op.id,
        goodQuantity: 500,
        transactionAtUtcMillis: now,
      );
      overview = (await routingRepo.getJobRoutingOverview(lot.id))!;
      expect(overview.jobProcesses.single.payableAmountPaise, 295000);
      expect(overview.costSummary.totalBasePaise, 295000);
      expect(overview.costSummary.totalNetCostPaise, 305000);
      // Payments are recorded in Accounting only; Routing never adds any.
      expect(overview.costSummary.totalPaidPaise, 0);
    });

    test('Scenario 11: Full End-to-End Production Lifecycle', () async {
      final lot = await lotRepo.createLot(
        lotNumber: 'QA-E2E-1',
        title: 'Full Lifecycle Order',
        transactionAtUtcMillis: now,
      );
      final design = await lotRepo.createDesign(
        lotId: lot.id,
        designName: 'D-201',
      );
      final colour = await lotRepo.createDesignColour(
        lotDesignId: design.id,
        colourName: 'Navy Blue',
        colourHex: '#1E3A8A',
        initialQuantity: 120,
        unitPricePaise: 8000,
      );

      // Cutting -> Direct Transfer to Packing -> Receipt -> Return to Factory -> Complete -> Pay
      final cut = await routingRepo.addJobProcess(
        lotId: lot.id,
        designColourId: colour.id,
        processId: 'p-cut',
        workerId: 'w-dharmesh',
        quantity: 120,
        transactionAtUtcMillis: now,
      );
      final trf = await routingRepo.directTransfer(
        sourceJobProcessId: cut.id,
        destinationProcessId: 'p-pack',
        destinationWorkerId: 'w-packing',
        quantity: 120,
        transactionAtUtcMillis: now,
        autoConfirmReceipt: false,
      );
      await routingRepo.confirmHandoverReceipt(
        handoverId: trf.id,
        receivedQuantity: 120,
        transactionAtUtcMillis: now,
      );
      final packOp = (await routingRepo.getJobRoutingOverview(lot.id))!
          .jobProcesses
          .firstWhere((p) => p.memberId == 'w-packing');
      await routingRepo.returnToFactory(
        sourceJobProcessId: packOp.id,
        goodQuantity: 120,
        damagedQuantity: 0,
        transactionAtUtcMillis: now,
      );
      await routingRepo.markProcessCompleted(
        jobProcessId: packOp.id,
        transactionAtUtcMillis: now,
      );
      final finalOverview = (await routingRepo.getJobRoutingOverview(lot.id))!;
      expect(finalOverview.totalFactoryAvailable, 120);
      expect(finalOverview.totalPendingWithWorkers, 0);
      expect(finalOverview.costSummary.totalPaidPaise, 0);
    });

    test('Scenario 12: Negative Workflow Testing rejects every invalid operation safely', () async {
      final lot = await lotRepo.createLot(
        lotNumber: 'QA-NEG-1',
        transactionAtUtcMillis: now,
      );
      final red = await lotRepo.addColourDirectlyToLot(
        lotId: lot.id,
        colourName: 'Red',
        initialQuantity: 50,
        unitPricePaise: 0,
      );

      // Zero & negative quantity
      await expectLater(
        routingRepo.addJobProcess(
          lotId: lot.id,
          designColourId: red.id,
          processId: 'p-cut',
          workerId: 'w-dharmesh',
          quantity: 0,
          transactionAtUtcMillis: now,
        ),
        throwsA(isA<DomainValidationException>()),
      );
      await expectLater(
        routingRepo.addJobProcess(
          lotId: lot.id,
          designColourId: red.id,
          processId: 'p-cut',
          workerId: 'w-dharmesh',
          quantity: -10,
          transactionAtUtcMillis: now,
        ),
        throwsA(isA<DomainValidationException>()),
      );
      // Excess dispatch > 50 available
      await expectLater(
        routingRepo.addJobProcess(
          lotId: lot.id,
          designColourId: red.id,
          processId: 'p-cut',
          workerId: 'w-dharmesh',
          quantity: 51,
          transactionAtUtcMillis: now,
        ),
        throwsA(isA<DomainValidationException>()),
      );
      // Rate override without mandatory reason
      await expectLater(
        routingRepo.addJobProcess(
          lotId: lot.id,
          designColourId: red.id,
          processId: 'p-cut',
          workerId: 'w-dharmesh',
          quantity: 20,
          agreedRatePaise: 700,
          transactionAtUtcMillis: now,
        ),
        throwsA(isA<DomainValidationException>()),
      );

      // Valid dispatch of 20
      final op = await routingRepo.addJobProcess(
        lotId: lot.id,
        designColourId: red.id,
        processId: 'p-cut',
        workerId: 'w-dharmesh',
        quantity: 20,
        transactionAtUtcMillis: now,
      );

      // Excess direct transfer > 20 held
      await expectLater(
        routingRepo.directTransfer(
          sourceJobProcessId: op.id,
          destinationProcessId: 'p-pack',
          destinationWorkerId: 'w-packing',
          quantity: 25,
          transactionAtUtcMillis: now,
        ),
        throwsA(isA<DomainValidationException>()),
      );
      // Excess factory return > 20 held
      await expectLater(
        routingRepo.returnToFactory(
          sourceJobProcessId: op.id,
          goodQuantity: 21,
          damagedQuantity: 0,
          transactionAtUtcMillis: now,
        ),
        throwsA(isA<DomainValidationException>()),
      );
      // Damaged return without reason
      await expectLater(
        routingRepo.returnToFactory(
          sourceJobProcessId: op.id,
          goodQuantity: 10,
          damagedQuantity: 2,
          transactionAtUtcMillis: now,
        ),
        throwsA(isA<DomainValidationException>()),
      );
      // Cannot mark completed while 20 pcs still pending
      await expectLater(
        routingRepo.markProcessCompleted(
          jobProcessId: op.id,
          transactionAtUtcMillis: now,
        ),
        throwsA(isA<DomainValidationException>()),
      );
      // Invalid charge amount <= 0
      await expectLater(
        routingRepo.addAdditionalCharge(
          jobProcessId: op.id,
          chargeType: ProcessChargeType.extraCharge,
          description: 'Zero',
          amountPaise: 0,
          transactionAtUtcMillis: now,
        ),
        throwsA(isA<DomainValidationException>()),
      );
    });
  });
}
