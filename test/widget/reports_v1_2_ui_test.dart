import 'dart:io';

import 'package:business_manager/app.dart';
import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/domain/entities/accounting_entities.dart';
import 'package:business_manager/features/accounting/domain/repositories/accounting_repository.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:business_manager/features/rates/domain/repositories/rate_repository.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:business_manager/features/workers/domain/repositories/worker_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempDir;
  late AppDatabase testDb;

  setUpAll(() {
    IstDateTimeHelper.initialize();
  });

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('sf_v1_2_rep_ui_');
    testDb = AppDatabase.forTesting(NativeDatabase.memory());

    final config = AppConfig.dev();
    await configureDependencies(config);

    await getIt.unregister<AppDatabase>();
    getIt.registerSingleton<AppDatabase>(testDb);
    await getIt.unregister<MediaStorageService>();
    getIt.registerSingleton<MediaStorageService>(
      NativeMediaStorageService(
        config: config,
        idGenerator: getIt<IdGenerator>(),
        baseDirectoryOverride: tempDir,
      ),
    );
  });

  tearDown(() async {
    await testDb.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> seedWorkshopData() async {
    final lotRepo = getIt<LotRepository>();
    final procRepo = getIt<ProcessRepository>();
    final workerRepo = getIt<WorkerRepository>();
    final rateRepo = getIt<RateRepository>();
    final stockRepo = getIt<StockMovementRepository>();
    final acctRepo = getIt<AccountingRepository>();

    final now = IstDateTimeHelper.nowUtcMillis();
    final lot = await lotRepo.createLot(
      lotNumber: 'LOT-888',
      title: 'Silk Dupatta',
      transactionAtUtcMillis: now,
    );
    final design = await lotRepo.createDesign(
      lotId: lot.id,
      designName: 'D-888',
    );
    final colour = await lotRepo.createDesignColour(
      lotDesignId: design.id,
      colourName: 'Maroon',
      initialQuantity: 120,
      unitPricePaise: 35000,
    );
    final proc = await procRepo.createProcess(name: 'Embroidery');
    final worker = await workerRepo.createWorker(name: 'Kiran Bhai');
    await workerRepo.assignProcessToWorker(
      workerId: worker.id,
      processId: proc.id,
    );
    await rateRepo.addRate(
      workerId: worker.id,
      processId: proc.id,
      ratePaise: 2500,
      effectiveFrom: '2025-01-01',
    );
    final issue = await stockRepo.issueStock(
      designColourId: colour.id,
      processId: proc.id,
      workerId: worker.id,
      quantity: 50,
      transactionAtUtcMillis: now,
    );
    await stockRepo.recordSettlement(
      parentIssueId: issue.id,
      goodQuantity: 30,
      damagedQuantity: 2,
      lostQuantity: 0,
      shortageQuantity: 0,
      reason: 'Thread pull',
      transactionAtUtcMillis: now,
    );
    await acctRepo.recordPayment(
      workerId: worker.id,
      paymentType: PaymentType.regular,
      amountPaise: 20000,
      paymentMode: PaymentMode.upi,
      transactionAtUtcMillis: now,
    );
  }

  testWidgets(
    '6-category Reports hub, export sheet, and truthful labels render cleanly at 360dp',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await seedWorkshopData();

      await tester.pumpWidget(BusinessManagerApp(config: AppConfig.dev()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Dashboard overflow');

      // Open Reports from the dashboard links; on phones they sit behind the
      // "More screens" toggle below the quick action tiles.
      await tester.ensureVisible(find.text('More screens'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('More screens'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Reports').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reports').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Daily tab overflow');

      Future<void> selectCategoryChip(String label) async {
        final chip = find.text(label).first;
        await tester.ensureVisible(chip);
        await tester.pumpAndSettle();
        await tester.tap(chip);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$label tab overflow');
      }

      // Category 1: Daily Workshop
      expect(find.text('Daily Workshop'), findsWidgets);
      expect(find.text('True Workshop Net Profit'), findsNothing);
      expect(find.textContaining('Revenue'), findsNothing);

      // Category 2: Worker Performance
      await selectCategoryChip('Worker Performance');
      expect(find.text('Kiran Bhai'), findsWidgets);

      // Category 3: Work Stage Performance
      await selectCategoryChip('Work Stage Performance');
      expect(find.text('Embroidery'), findsWidgets);

      // Category 4: Inventory -> Reference Stock Value (never Profit/Revenue)
      await selectCategoryChip('Inventory');
      expect(find.text('Reference Stock Value'), findsWidgets);
      expect(find.text('True Workshop Net Profit'), findsNothing);

      // Category 5: Labour & Financial
      await selectCategoryChip('Labour & Financial');
      expect(find.text('Earned Labour'), findsWidgets);

      // Category 6: Business Insights
      await selectCategoryChip('Business Insights');
      expect(find.text('Production Trends'), findsOneWidget);
      expect(find.text('True Workshop Net Profit'), findsNothing);
      expect(find.textContaining('Revenue'), findsNothing);

      // Open Export Sheet
      await tester.tap(find.byTooltip('Export / Print'));
      await tester.pumpAndSettle();
      expect(find.text('Print / Save as PDF'), findsOneWidget);
      expect(find.text('Export Excel (.xlsx)'), findsOneWidget);
      expect(find.text('Export CSV (UTF-8)'), findsOneWidget);
    },
  );
}
