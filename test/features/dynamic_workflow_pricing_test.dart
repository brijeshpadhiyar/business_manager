import 'dart:io';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/lots/data/repositories/lot_repository_impl.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/process_routing/data/repositories/process_routing_repository_impl.dart';
import 'package:business_manager/features/processes/data/repositories/process_repository_impl.dart';
import 'package:business_manager/features/processes/domain/entities/process_entities.dart';
import 'package:business_manager/features/rates/domain/entities/rate_entities.dart';
import 'package:business_manager/features/stock_movements/data/repositories/stock_movement_repository_impl.dart';
import 'package:business_manager/features/workers/data/repositories/worker_repository_impl.dart';
import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late ProcessRepositoryImpl processRepo;
  late LotRepositoryImpl lotRepo;
  late WorkerRepositoryImpl workerRepo;
  late StockMovementRepositoryImpl stockRepo;
  late ProcessRoutingRepositoryImpl routingRepo;

  setUpAll(() {
    IstDateTimeHelper.initialize();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sf_dyn_wf_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final txRunner = DatabaseTransactionRunner(db);
    final idGen = IdGenerator();
    final media = NativeMediaStorageService(
      config: AppConfig.dev(),
      idGenerator: idGen,
      baseDirectoryOverride: tempDir,
    );
    processRepo = ProcessRepositoryImpl(db, txRunner, idGen);
    lotRepo = LotRepositoryImpl(db, txRunner, idGen, media);
    workerRepo = WorkerRepositoryImpl(db, txRunner, idGen);
    stockRepo = StockMovementRepositoryImpl(db, txRunner, idGen);
    routingRepo = ProcessRoutingRepositoryImpl(db, txRunner, stockRepo, idGen);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Phase 1 — Dynamic Multi-Process Management & Default Rates', () {
    test('creates unlimited processes preserving existing Silay and default rates', () async {
      final silay = await processRepo.createProcess(
        name: 'Silay',
        defaultRatePaise: 2500,
        defaultPricingUnit: 'PER_PIECE',
        billingModeOverride: ProcessBillingModeOverride.receivedQty,
        includeDamagedInLabour: false,
      );
      final cutting = await processRepo.createProcess(
        name: 'Cutting',
        defaultRatePaise: 1200,
        defaultPricingUnit: 'PER_PIECE',
        billingModeOverride: ProcessBillingModeOverride.givenQty,
        includeDamagedInLabour: true,
      );
      final embroidery = await processRepo.createProcess(
        name: 'Embroidery',
        defaultRatePaise: 36000,
        defaultPricingUnit: 'PER_DOZEN',
      );
      final finishing = await processRepo.createProcess(
        name: 'Finishing',
        isActive: false,
      );

      final all = await processRepo.getProcesses();
      expect(all.length, 4);
      expect(all.any((p) => p.id == silay.id && p.defaultRatePaise == 2500), isTrue);
      expect(
        all.any(
          (p) =>
              p.id == cutting.id &&
              p.billingModeOverride == ProcessBillingModeOverride.givenQty &&
              p.includeDamagedInLabour,
        ),
        isTrue,
      );
      expect(
        all.any(
          (p) =>
              p.id == embroidery.id &&
              p.defaultRatePaise == 36000 &&
              p.defaultPricingUnit == 'PER_DOZEN',
        ),
        isTrue,
      );
      expect(all.any((p) => p.id == finishing.id && !p.isActive), isTrue);

      // Update rate & reactivate
      final updated = await processRepo.updateProcess(
        processId: finishing.id,
        name: 'Finishing & Ironing',
        isActive: true,
        includeDamagedInLabour: false,
        defaultRatePaise: 800,
        defaultPricingUnit: 'PER_PIECE',
      );
      expect(updated.isActive, isTrue);
      expect(updated.defaultRatePaise, 800);
    });
  });

  group('Phases 2 & 3 — Complete Atomic Lot Creation & Direct Colour Pricing', () {
    test('creates Lot + multiple Designs + multiple Colours with distinct prices atomically', () async {
      final now = IstDateTimeHelper.nowUtcMillis();
      final lot = await lotRepo.createLotComplete(
        lotNumber: 'LOT-501',
        title: 'Diwali Collection',
        transactionAtUtcMillis: now,
        designs: const [
          LotDesignDraftInput(
            designName: 'D-Alpha',
            colours: [
              LotColourDraftInput(
                colourName: 'Maroon',
                colourHex: '#881337',
                initialQuantity: 60,
                unitPricePaise: 45000,
              ),
              LotColourDraftInput(
                colourName: 'Navy',
                colourHex: '#1E3A8A',
                initialQuantity: 40,
                unitPricePaise: 47500,
              ),
            ],
          ),
          LotDesignDraftInput(
            designName: 'D-Beta',
            colours: [
              LotColourDraftInput(
                colourName: 'Ivory',
                colourHex: '#FEF3C7',
                initialQuantity: 50,
                unitPricePaise: 52000,
              ),
            ],
          ),
        ],
      );

      final detail = await lotRepo.getLotDetail(lot.id);
      expect(detail, isNotNull);
      expect(detail!.designs.length, 2);
      final totalInitQty = detail.designs
          .expand((d) => d.colours)
          .fold<int>(0, (acc, c) => acc + c.initialQuantity);
      expect(totalInitQty, 150);

      final alpha = detail.designs.firstWhere((d) => d.design.designName == 'D-Alpha');
      expect(alpha.colours.length, 2);
      expect(
        alpha.colours.firstWhere((c) => c.colourName == 'Maroon').unitPricePaise,
        45000,
      );
      expect(
        alpha.colours.firstWhere((c) => c.colourName == 'Navy').unitPricePaise,
        47500,
      );

      // Distinct design name reuse suggestions
      final names = await lotRepo.getDistinctDesignNames();
      expect(names, ['D-Alpha', 'D-Beta']);

      // Phase 3: Adding batch colours with direct prices does not mutate existing colour prices
      await lotRepo.createDesignColoursBatch(
        lotId: lot.id,
        lotDesignId: alpha.design.id,
        colours: const [
          LotColourDraftInput(
            colourName: 'Teal',
            colourHex: '#0D9488',
            initialQuantity: 25,
            unitPricePaise: 49000,
          ),
        ],
      );
      final afterBatch = await lotRepo.getLotDetail(lot.id);
      final alphaAfter = afterBatch!.designs.firstWhere((d) => d.design.id == alpha.design.id);
      expect(alphaAfter.colours.length, 3);
      expect(
        alphaAfter.colours.firstWhere((c) => c.colourName == 'Maroon').unitPricePaise,
        45000,
      );
      expect(
        alphaAfter.colours.firstWhere((c) => c.colourName == 'Teal').unitPricePaise,
        49000,
      );
    });

    test('rolls back completely when nested colour validation fails (zero partial saves)', () async {
      final now = IstDateTimeHelper.nowUtcMillis();
      await expectLater(
        () => lotRepo.createLotComplete(
          lotNumber: 'LOT-ROLLBACK',
          transactionAtUtcMillis: now,
          designs: const [
            LotDesignDraftInput(
              designName: 'D-Bad',
              colours: [
                LotColourDraftInput(
                  colourName: 'Red',
                  initialQuantity: 50,
                  unitPricePaise: 10000,
                ),
                LotColourDraftInput(
                  colourName: 'red', // Duplicate colour in same design
                  initialQuantity: 20,
                  unitPricePaise: 12000,
                ),
              ],
            ),
          ],
        ),
        throwsA(
          isA<DomainValidationException>().having(
            (e) => e.code,
            'code',
            'duplicate_colour_name',
          ),
        ),
      );

      final lots = await lotRepo.getLots();
      expect(lots, isEmpty);
    });
  });

  group('Phases 4, 5 & 6 — Worker Multi-Process Assignment & Unified Labour Precedence', () {
    test('creates worker with multiple processes, custom vs inherited rates, and applies strict precedence', () async {
      final silay = await processRepo.createProcess(
        name: 'Silay',
        defaultRatePaise: 2000, // ₹20.00 / pc
        defaultPricingUnit: 'PER_PIECE',
      );
      final cutting = await processRepo.createProcess(
        name: 'Cutting',
        defaultRatePaise: 1000, // ₹10.00 / pc
        defaultPricingUnit: 'PER_PIECE',
      );
      final embroidery = await processRepo.createProcess(
        name: 'Embroidery',
        defaultRatePaise: 24000, // ₹240.00 / doz -> ₹20.00 / pc
        defaultPricingUnit: 'PER_DOZEN',
      );

      // Worker assigned to 3 processes:
      // - Silay: custom worker rate ₹28.00/pc (overrides ₹20.00 default)
      // - Cutting: no custom rate -> inherits ₹10.00/pc default
      // - Embroidery: no custom rate -> inherits ₹240/doz (₹20.00/pc)
      final worker = await workerRepo.createWorkerWithProcesses(
        name: 'Ramesh Karigar',
        phone: '9876543210',
        isActive: true,
        processConfigs: [
          WorkerProcessConfigInput(
            processId: silay.id,
            customRatePaise: 2800,
          ),
          WorkerProcessConfigInput(processId: cutting.id),
          WorkerProcessConfigInput(processId: embroidery.id),
        ],
      );

      final detail = await workerRepo.getWorkerDetail(worker.id);
      expect(detail, isNotNull);
      expect(detail!.assignedProcesses.length, 3);

      final silaySummary = detail.assignedProcesses.firstWhere(
        (s) => s.assignment.processId == silay.id,
      );
      expect(silaySummary.currentRate?.ratePaise, 2800);
      expect(silaySummary.processDefaultRatePaise, 2000);

      final cuttingSummary = detail.assignedProcesses.firstWhere(
        (s) => s.assignment.processId == cutting.id,
      );
      expect(cuttingSummary.currentRate, isNull);
      expect(cuttingSummary.processDefaultRatePaise, 1000);

      final now = IstDateTimeHelper.nowUtcMillis();

      // Unified rate preview precedence:
      // 1. Silay -> Worker Custom Rate (₹28.00)
      final silayPreview = await stockRepo.previewRate(
        workerId: worker.id,
        processId: silay.id,
        transactionAtUtcMillis: now,
      );
      expect(silayPreview, isA<RateResolutionFound>());
      expect((silayPreview as RateResolutionFound).rate.ratePaise, 2800);

      // 2. Cutting -> Inherited Process Default Rate (₹10.00)
      final cuttingPreview = await stockRepo.previewRate(
        workerId: worker.id,
        processId: cutting.id,
        transactionAtUtcMillis: now,
      );
      expect(cuttingPreview, isA<RateResolutionProcessDefault>());
      expect((cuttingPreview as RateResolutionProcessDefault).ratePaise, 1000);

      // 3. Embroidery -> Inherited Per-Dozen Process Default normalized to ₹20.00/pc
      final embPreview = await stockRepo.previewRate(
        workerId: worker.id,
        processId: embroidery.id,
        transactionAtUtcMillis: now,
      );
      expect(embPreview, isA<RateResolutionProcessDefault>());
      expect((embPreview as RateResolutionProcessDefault).ratePaise, 2000);

      // Create lot & issue stock to Cutting using inherited process default (no manual override needed!)
      final lot = await lotRepo.createLotComplete(
        lotNumber: 'LOT-PREC-1',
        transactionAtUtcMillis: now,
        designs: const [
          LotDesignDraftInput(
            designName: 'D-1',
            colours: [
              LotColourDraftInput(
                colourName: 'Black',
                initialQuantity: 100,
                unitPricePaise: 30000,
              ),
            ],
          ),
        ],
      );
      final lotDetail = await lotRepo.getLotDetail(lot.id);
      final colourId = lotDetail!.designs.first.colours.first.id;

      final cuttingIssue = await stockRepo.issueStock(
        designColourId: colourId,
        processId: cutting.id,
        workerId: worker.id,
        quantity: 20,
        transactionAtUtcMillis: now,
      );
      expect(cuttingIssue.appliedRatePaise, 1000);
      expect(cuttingIssue.isRateOverridden, isFalse);
      expect(cuttingIssue.sourceRateId, isNull);

      // Process Routing also uses strict Worker -> Process Default precedence
      final routedSilay = await routingRepo.addJobProcess(
        lotId: lot.id,
        designColourId: colourId,
        processId: silay.id,
        workerId: worker.id,
        quantity: 10,
        dispatchImmediately: false,
        transactionAtUtcMillis: now,
      );
      expect(routedSilay.defaultRatePaise, 2800);
      expect(routedSilay.agreedRatePaise, 2800);

      // Phase 5: Soft-deactivating Cutting via updateWorkerWithProcesses preserves historical issue!
      await workerRepo.updateWorkerWithProcesses(
        workerId: worker.id,
        name: 'Ramesh Karigar',
        phone: '9876543210',
        isActive: true,
        processConfigs: [
          WorkerProcessConfigInput(
            processId: silay.id,
            customRatePaise: 3000,
          ),
        ],
      );
      final afterEdit = await workerRepo.getWorkerDetail(worker.id);
      expect(afterEdit!.assignedProcesses.length, 1);
      expect(afterEdit.assignedProcesses.first.currentRate?.ratePaise, 3000);

      // Historical Cutting stock movement remains untouched
      final openIssues = await stockRepo.getOpenIssues(workerId: worker.id);
      expect(openIssues.length, 1);
      expect(openIssues.first.issueView.movement.appliedRatePaise, 1000);
    });
  });
}
