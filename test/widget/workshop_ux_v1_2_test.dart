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
    tempDir = await Directory.systemTemp.createTemp('sf_v1_2_ux_');
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

  testWidgets(
    'Today Dashboard, Daily Summary, Worker Live Overview, and Quick Return sorting render cleanly at 360dp',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final lotRepo = getIt<LotRepository>();
      final procRepo = getIt<ProcessRepository>();
      final workerRepo = getIt<WorkerRepository>();
      final rateRepo = getIt<RateRepository>();
      final stockRepo = getIt<StockMovementRepository>();
      final acctRepo = getIt<AccountingRepository>();

      final now = IstDateTimeHelper.nowUtcMillis();
      final lot = await lotRepo.createLot(
        lotNumber: 'LOT-501',
        title: 'Cotton Kurta',
        transactionAtUtcMillis: now,
      );
      final design = await lotRepo.createDesign(
        lotId: lot.id,
        designName: 'D-501',
      );
      final colour = await lotRepo.createDesignColour(
        lotDesignId: design.id,
        colourName: 'Navy',
        initialQuantity: 100,
        unitPricePaise: 30000,
      );
      final proc = await procRepo.createProcess(name: 'Cutting');
      final worker = await workerRepo.createWorker(name: 'Mahesh Bhai');
      await workerRepo.assignProcessToWorker(
        workerId: worker.id,
        processId: proc.id,
      );
      await rateRepo.addRate(
        workerId: worker.id,
        processId: proc.id,
        ratePaise: 2000,
        effectiveFrom: '2025-01-01',
      );
      final issue = await stockRepo.issueStock(
        designColourId: colour.id,
        processId: proc.id,
        workerId: worker.id,
        quantity: 60,
        transactionAtUtcMillis: now,
      );
      await stockRepo.recordSettlement(
        parentIssueId: issue.id,
        goodQuantity: 20,
        damagedQuantity: 0,
        lostQuantity: 0,
        shortageQuantity: 0,
        transactionAtUtcMillis: now,
      );
      await acctRepo.recordPayment(
        workerId: worker.id,
        paymentType: PaymentType.regular,
        amountPaise: 15000,
        paymentMode: PaymentMode.cash,
        transactionAtUtcMillis: now,
      );

      await tester.pumpWidget(BusinessManagerApp(config: AppConfig.dev()));
      await tester.pumpAndSettle();

      // 1. Dashboard shows Today's Workshop & Important Pending Work
      final dashScroll = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text("Today's Workshop"),
        200,
        scrollable: dashScroll,
      );
      expect(find.text("Today's Workshop"), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Important Pending Work'),
        200,
        scrollable: dashScroll,
      );
      expect(find.text('Important Pending Work'), findsOneWidget);

      // 2. Open Daily Summary from Dashboard Quick Action
      await tester.drag(dashScroll, const Offset(0, 700));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Daily Summary').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Daily Summary').first);
      await tester.pumpAndSettle();
      expect(find.text('Daily Production Summary'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Mahesh Bhai'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Mahesh Bhai'), findsWidgets);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 3. Open Workers tab -> Mahesh Bhai -> verify Live Work & Balance Overview
      await tester.tap(find.text('Workers').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mahesh Bhai').first);
      await tester.pumpAndSettle();
      expect(find.text('Live Work & Balance Overview'), findsOneWidget);
      expect(find.text('Open Pending Work'), findsOneWidget);

      expect(tester.takeException(), isNull);
    },
  );
}
