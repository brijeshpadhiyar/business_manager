import 'dart:typed_data';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/database/migrations/database_migration_manager.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/features/lots/data/repositories/lot_repository_impl.dart';
import 'package:business_manager/features/process_routing/data/repositories/process_routing_repository_impl.dart';
import 'package:business_manager/features/process_routing/domain/calculators/process_pricing_calculator.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/stock_movements/data/repositories/stock_movement_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

final class _NoopMediaStorage implements MediaStorageService {
  @override
  String computeSha256(Uint8List bytes) => '0';

  @override
  Future<bool> deleteIfExists(String relativePath) async => false;

  @override
  Future<bool> exists(String relativePath) async => false;

  @override
  Future<Uint8List?> readBytes(String relativePath) async => null;

  @override
  Future<SavedMediaFile> saveBytes({
    required Uint8List bytes,
    required MediaCategory category,
    required String entityId,
    required String fileExtension,
    required String mimeType,
  }) async => SavedMediaFile(
    relativePath: 'noop.$fileExtension',
    fileSizeBytes: bytes.length,
    sha256Hex: '0',
    mimeType: mimeType,
  );
}

void main() {
  late AppDatabase db;
  late DatabaseTransactionRunner txRunner;
  late IdGenerator idGen;
  late LotRepositoryImpl lotRepo;
  late StockMovementRepositoryImpl stockRepo;
  late ProcessRoutingRepositoryImpl routingRepo;

  const baseTs = 1795411200000;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    txRunner = DatabaseTransactionRunner(db);
    idGen = IdGenerator();
    lotRepo = LotRepositoryImpl(db, txRunner, idGen, _NoopMediaStorage());
    stockRepo = StockMovementRepositoryImpl(db, txRunner, idGen);
    routingRepo = ProcessRoutingRepositoryImpl(db, txRunner, stockRepo, idGen);
    await db.verifyPragmas();

    for (final (id, name) in const [
      ('p-cut', 'Cutting'),
      ('p-pack', 'Packing'),
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

    for (final (id, name) in const [
      ('w-dharmesh', 'Dharmesh'),
      ('w-ramesh', 'Ramesh'),
      ('w-suresh', 'Suresh'),
      ('w-packing', 'Packing Dept'),
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

  test('1. Colour-only lot creation (design optional, total 500 pcs)', () async {
    final lot = await lotRepo.createLot(
      lotNumber: '1001',
      title: 'Colour-Only Batch',
      transactionAtUtcMillis: baseTs,
    );

    await lotRepo.addColourDirectlyToLot(
      lotId: lot.id,
      colourName: 'Red',
      initialQuantity: 200,
      unitPricePaise: 0,
    );
    await lotRepo.addColourDirectlyToLot(
      lotId: lot.id,
      colourName: 'Blue',
      initialQuantity: 150,
      unitPricePaise: 0,
    );
    await lotRepo.addColourDirectlyToLot(
      lotId: lot.id,
      colourName: 'Black',
      initialQuantity: 150,
      unitPricePaise: 0,
    );

    final detail = (await lotRepo.getLotDetail(lot.id))!;
    expect(detail.designs.length, 1);
    expect(detail.designs.first.design.designName, kColourOnlyDesignSentinel);
    expect(detail.designs.first.colours.length, 3);

    final overview = (await routingRepo.getJobRoutingOverview(lot.id))!;
    expect(overview.totalInitialQuantity, 500);
    expect(overview.totalFactoryAvailable, 500);
    expect(
      formatVariantLabel(
        overview.skuBalances.first.designName,
        overview.skuBalances.first.colourName,
      ),
      isNot(contains(kColourOnlyDesignSentinel)),
    );
  });

  test(
    '2, 3, 4, 5 & 6. Design-based lot, variant splitting across workers, direct transfer & factory return preserve variant details',
    () async {
      final lot = await lotRepo.createLot(
        lotNumber: '1002',
        transactionAtUtcMillis: baseTs,
      );
      final d101 = await lotRepo.createDesign(
        lotId: lot.id,
        designName: 'D-101',
      );
      final d102 = await lotRepo.createDesign(
        lotId: lot.id,
        designName: 'D-102',
      );

      final d101Red = await lotRepo.createDesignColour(
        lotDesignId: d101.id,
        colourName: 'Red',
        initialQuantity: 100,
        unitPricePaise: 0,
      );
      final d101Blue = await lotRepo.createDesignColour(
        lotDesignId: d101.id,
        colourName: 'Blue',
        initialQuantity: 100,
        unitPricePaise: 0,
      );
      await lotRepo.createDesignColour(
        lotDesignId: d101.id,
        colourName: 'Green',
        initialQuantity: 100,
        unitPricePaise: 0,
      );
      final d102Black = await lotRepo.createDesignColour(
        lotDesignId: d102.id,
        colourName: 'Black',
        initialQuantity: 100,
        unitPricePaise: 0,
      );
      await lotRepo.createDesignColour(
        lotDesignId: d102.id,
        colourName: 'Yellow',
        initialQuantity: 100,
        unitPricePaise: 0,
      );

      // Variant-level split: D-101 Red (100) -> Dharmesh 60, Ramesh 40
      final dharmeshRed = await routingRepo.addJobProcess(
        lotId: lot.id,
        designColourId: d101Red.id,
        processId: 'p-cut',
        workerId: 'w-dharmesh',
        quantity: 60,
        transactionAtUtcMillis: baseTs,
      );
      final rameshRed = await routingRepo.addJobProcess(
        lotId: lot.id,
        designColourId: d101Red.id,
        processId: 'p-cut',
        workerId: 'w-ramesh',
        quantity: 40,
        transactionAtUtcMillis: baseTs + 1000,
      );
      // One worker receives multiple variants: Dharmesh also gets D-101 Blue (100)
      await routingRepo.addJobProcess(
        lotId: lot.id,
        designColourId: d101Blue.id,
        processId: 'p-cut',
        workerId: 'w-dharmesh',
        quantity: 100,
        transactionAtUtcMillis: baseTs + 2000,
      );
      // Suresh gets D-102 Black (100)
      await routingRepo.addJobProcess(
        lotId: lot.id,
        designColourId: d102Black.id,
        processId: 'p-cut',
        workerId: 'w-suresh',
        quantity: 100,
        transactionAtUtcMillis: baseTs + 3000,
      );

      // Direct transfer preserves Design D-101 / Red
      final transfer = await routingRepo.directTransfer(
        sourceJobProcessId: dharmeshRed.id,
        destinationProcessId: 'p-pack',
        destinationWorkerId: 'w-packing',
        quantity: 60,
        transactionAtUtcMillis: baseTs + 4000,
        autoConfirmReceipt: true,
      );
      expect(transfer.designName, 'D-101');
      expect(transfer.colourName, 'Red');
      expect(transfer.variantLabel, 'D-101 • Red');

      // Factory return preserves Design D-101 / Red
      final ret = await routingRepo.returnToFactory(
        sourceJobProcessId: rameshRed.id,
        goodQuantity: 40,
        transactionAtUtcMillis: baseTs + 5000,
      );
      expect(ret.designName, 'D-101');
      expect(ret.colourName, 'Red');

      final overview = (await routingRepo.getJobRoutingOverview(lot.id))!;
      expect(overview.totalInitialQuantity, 500);
      expect(overview.totalFactoryAvailable, 240); // Green 100 + Yellow 100 + Returned Red 40
      expect(overview.totalPendingWithWorkers, 260); // Packing Red 60 + Dharmesh Blue 100 + Suresh Black 100
    },
  );

  test(
    '7, 8, 9, 10, 11 & 12. Dynamic pricing, override reason, default rate change preserves history, charges, payments & exact cost summaries',
    () async {
      final lot = await lotRepo.createLot(
        lotNumber: '1003',
        transactionAtUtcMillis: baseTs,
      );
      final d101 = await lotRepo.createDesign(
        lotId: lot.id,
        designName: 'D-101',
      );
      final d102 = await lotRepo.createDesign(
        lotId: lot.id,
        designName: 'D-102',
      );
      final red = await lotRepo.createDesignColour(
        lotDesignId: d101.id,
        colourName: 'Red',
        initialQuantity: 350,
        unitPricePaise: 0,
      );
      final black = await lotRepo.createDesignColour(
        lotDesignId: d102.id,
        colourName: 'Black',
        initialQuantity: 150,
        unitPricePaise: 0,
      );

      // Set Default Cutting Rate = ₹5.00 (500 paise) per piece
      await routingRepo.updateProcessDefaultRate(
        processId: 'p-cut',
        defaultRatePaise: 500,
        defaultPricingUnit: ProcessPricingCalculator.unitPerPiece,
        reason: 'Standard cutting rate',
      );

      // Overriding rate WITHOUT reason must fail
      await expectLater(
        () => routingRepo.addJobProcess(
          lotId: lot.id,
          designColourId: red.id,
          processId: 'p-cut',
          workerId: 'w-ramesh',
          quantity: 150,
          transactionAtUtcMillis: baseTs,
          agreedRatePaise: 700,
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'rate_override_reason_required',
          ),
        ),
      );

      // Dharmesh: 200 pcs × ₹5 (default) = ₹1,000 (100,000 paise)
      final jpDharmesh = await routingRepo.addJobProcess(
        lotId: lot.id,
        designColourId: red.id,
        processId: 'p-cut',
        workerId: 'w-dharmesh',
        quantity: 200,
        transactionAtUtcMillis: baseTs,
      );
      // Ramesh: 150 pcs × ₹7 (override) = ₹1,050 (105,000 paise)
      final jpRamesh = await routingRepo.addJobProcess(
        lotId: lot.id,
        designColourId: red.id,
        processId: 'p-cut',
        workerId: 'w-ramesh',
        quantity: 150,
        transactionAtUtcMillis: baseTs + 1000,
        agreedRatePaise: 700,
        rateOverrideReason: 'Urgent night shift rate',
      );
      // Suresh: 150 pcs × ₹6 (override) = ₹900 (90,000 paise)
      final jpSuresh = await routingRepo.addJobProcess(
        lotId: lot.id,
        designColourId: black.id,
        processId: 'p-cut',
        workerId: 'w-suresh',
        quantity: 150,
        transactionAtUtcMillis: baseTs + 2000,
        agreedRatePaise: 600,
        rateOverrideReason: 'Heavy fabric cutting',
      );

      expect(jpDharmesh.payableAmountPaise, 100000);
      expect(jpRamesh.payableAmountPaise, 105000);
      expect(jpSuresh.payableAmountPaise, 90000);

      // Change Default Cutting Rate to ₹8.00 -> existing assignments MUST remain untouched!
      await routingRepo.updateProcessDefaultRate(
        processId: 'p-cut',
        defaultRatePaise: 800,
        defaultPricingUnit: ProcessPricingCalculator.unitPerPiece,
        reason: 'Seasonal revision',
      );

      final history = await routingRepo.getProcessRateHistory('p-cut');
      expect(history.length, 4); // 2 default changes + 2 assignment overrides

      // Add extra charge ₹150 to Dharmesh & deduction ₹50 to Suresh
      await routingRepo.addAdditionalCharge(
        jobProcessId: jpDharmesh.id,
        chargeType: ProcessChargeType.extraCharge,
        description: 'Special pattern layout',
        amountPaise: 15000,
        transactionAtUtcMillis: baseTs + 3000,
      );
      await routingRepo.addAdditionalCharge(
        jobProcessId: jpSuresh.id,
        chargeType: ProcessChargeType.deduction,
        description: 'Thread wastage deduction',
        amountPaise: 5000,
        transactionAtUtcMillis: baseTs + 3500,
      );

      // Partial payment to Dharmesh (₹500 of ₹1,150) & full payment to Ramesh (₹1,050)
      final dharmeshPaid = await routingRepo.recordProcessPayment(
        jobProcessId: jpDharmesh.id,
        amountPaise: 50000,
        paymentMode: 'CASH',
        transactionAtUtcMillis: baseTs + 4000,
      );
      expect(dharmeshPaid.paymentStatus, ProcessPaymentStatus.partiallyPaid);

      final rameshPaid = await routingRepo.recordProcessPayment(
        jobProcessId: jpRamesh.id,
        amountPaise: 105000,
        paymentMode: 'UPI',
        transactionAtUtcMillis: baseTs + 4500,
      );
      expect(rameshPaid.paymentStatus, ProcessPaymentStatus.paid);

      final overview = (await routingRepo.getJobRoutingOverview(lot.id))!;
      // Verify historical rates preserved despite default changing to ₹8
      final reloadedDharmesh = overview.jobProcesses.firstWhere(
        (p) => p.id == jpDharmesh.id,
      );
      expect(reloadedDharmesh.defaultRatePaise, 500);
      expect(reloadedDharmesh.agreedRatePaise, 500);

      // Verify exact totals:
      // Base: 1000 + 1050 + 900 = ₹2,950 (295,000 paise)
      // Extra: +₹150, Deduction: -₹50 -> Net Total = ₹3,050 (305,000 paise)
      // Paid: ₹500 + ₹1,050 = ₹1,550 (155,000 paise) -> Outstanding: ₹1,500 (150,000 paise)
      final cost = overview.costSummary;
      expect(cost.totalBasePaise, 295000);
      expect(cost.totalAdditionalChargesPaise, 15000);
      expect(cost.totalDeductionsPaise, 5000);
      expect(cost.totalNetCostPaise, 305000);
      expect(cost.totalPaidPaise, 155000);
      expect(cost.totalOutstandingPaise, 150000);

      // Design-wise & Colour-wise costs:
      // D-101 / Red: Dharmesh (1000+150) + Ramesh (1050) = ₹2,200 (220,000 paise)
      // D-102 / Black: Suresh (900-50) = ₹850 (85,000 paise)
      expect(
        cost.designCosts.firstWhere((d) => d.id == d101.id).totalCostPaise,
        220000,
      );
      expect(
        cost.designCosts.firstWhere((d) => d.id == d102.id).totalCostPaise,
        85000,
      );
      expect(
        cost.colourCosts.firstWhere((c) => c.id == red.id).totalCostPaise,
        220000,
      );
      expect(
        cost.colourCosts.firstWhere((c) => c.id == black.id).totalCostPaise,
        85000,
      );

      // Configurable pricing units: PER_DOZEN & FIXED_AMOUNT
      const calc = ProcessPricingCalculator();
      expect(
        calc.calculateBaseAmountPaise(
          quantity: 24,
          ratePaise: 6000, // ₹60 / dozen
          pricingUnit: ProcessPricingCalculator.unitPerDozen,
        ),
        12000, // ₹120
      );
      expect(
        calc.calculateBaseAmountPaise(
          quantity: 500,
          ratePaise: 250000, // ₹2,500 fixed
          pricingUnit: ProcessPricingCalculator.unitFixedAmount,
        ),
        250000,
      );
    },
  );

  test('13. Database v4 -> v5 migration integrity is idempotent', () async {
    await DatabaseMigrationManager.handleOnUpgrade(
      db.createMigrator(),
      db,
      4,
      5,
    );
    final cols = await db.customSelect('PRAGMA table_info(processes);').get();
    final colNames = cols.map((r) => r.read<String>('name')).toSet();
    expect(
      colNames,
      containsAll(const ['default_rate_paise', 'default_pricing_unit']),
    );
  });
}
