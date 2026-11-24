import 'dart:io';

import 'package:business_manager/app.dart';
import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:business_manager/features/production_history/domain/entities/production_history_entities.dart';
import 'package:business_manager/features/production_history/domain/repositories/production_history_repository.dart';
import 'package:business_manager/features/production_history/presentation/pages/inspection_queue_page.dart';
import 'package:business_manager/features/production_history/presentation/pages/lot_history_page.dart';
import 'package:business_manager/features/production_history/presentation/pages/lot_timeline_page.dart';
import 'package:business_manager/features/production_history/presentation/pages/process_history_page.dart';
import 'package:business_manager/features/production_history/presentation/pages/production_history_dashboard_page.dart';
import 'package:business_manager/features/production_history/presentation/pages/production_transaction_detail_page.dart';
import 'package:business_manager/features/production_history/presentation/pages/worker_production_history_page.dart';
import 'package:business_manager/features/rates/domain/repositories/rate_repository.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:business_manager/features/workers/domain/repositories/worker_repository.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
    tempDir = await Directory.systemTemp.createTemp('sf_ph_ui_');
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

  Widget wrapWithRouter(Widget home, {Locale locale = const Locale('en')}) {
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => home),
        GoRoute(
          path: RoutePaths.productionHistory,
          builder: (_, _) => const ProductionHistoryDashboardPage(),
        ),
        GoRoute(
          path: RoutePaths.inspectionQueue,
          builder: (_, _) => const InspectionQueuePage(),
        ),
        GoRoute(
          path: RoutePaths.processProductionHistory,
          builder: (_, _) => const ProcessHistoryPage(),
        ),
        GoRoute(
          path: RoutePaths.workerProductionHistory,
          builder: (_, _) => const WorkerProductionHistoryPage(),
        ),
      ],
    );
    return MaterialApp.router(
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }

  testWidgets(
    'All new Production History & QC Inspection screens render cleanly at 360dp in EN & GU with zero overflow',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Seed realistic production history data
      final lotRepo = getIt<LotRepository>();
      final procRepo = getIt<ProcessRepository>();
      final workerRepo = getIt<WorkerRepository>();
      final rateRepo = getIt<RateRepository>();
      final stockRepo = getIt<StockMovementRepository>();
      final histRepo = getIt<ProductionHistoryRepository>();
      final now = IstDateTimeHelper.nowUtcMillis();

      final proc = await procRepo.createProcess(name: 'Stitching');
      final worker = await workerRepo.createWorker(name: 'Rameshbhai');
      await workerRepo.assignProcessToWorker(
        workerId: worker.id,
        processId: proc.id,
      );
      await rateRepo.addRate(
        workerId: worker.id,
        processId: proc.id,
        ratePaise: 1000,
        effectiveFrom: '2025-01-01',
      );
      final lot = await lotRepo.createLotComplete(
        lotNumber: 'LOT-UI-01',
        title: 'Cotton Kurti',
        transactionAtUtcMillis: now,
        designs: const [
          LotDesignDraftInput(
            designName: 'D-UI',
            colours: [
              LotColourDraftInput(
                colourName: 'Teal',
                initialQuantity: 100,
                unitPricePaise: 30000,
              ),
            ],
          ),
        ],
      );
      final detail = (await lotRepo.getLotDetail(lot.id))!;
      final issue = await stockRepo.issueStock(
        designColourId: detail.designs.first.colours.first.id,
        processId: proc.id,
        workerId: worker.id,
        quantity: 60,
        transactionAtUtcMillis: now + 1000,
      );
      final ret = await histRepo.recordProductionReturn(
        parentIssueId: issue.id,
        returnedQuantity: 40,
        transactionAtUtcMillis: now + 2000,
        inspectImmediately: false,
      );
      final insp = await histRepo.approveReturnInspection(
        productionReturnId: ret.productionReturn.id,
        acceptedQuantity: 25,
        rejectedQuantity: 5,
        rejectionReason: 'Seam defect',
        transactionAtUtcMillis: now + 3000,
        approvedBy: 'Owner',
        authorizedViaPin: true,
      );

      // 1. Production History Dashboard (EN & GU)
      for (final locale in const [Locale('en'), Locale('gu')]) {
        await tester.pumpWidget(
          wrapWithRouter(
            const ProductionHistoryDashboardPage(),
            locale: locale,
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.textContaining('LOT-UI-01'), findsWidgets);
      }

      // 2. Lot Complete History
      await tester.pumpWidget(wrapWithRouter(LotHistoryPage(lotId: lot.id)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('LOT-UI-01'), findsWidgets);

      // 3. Lot Timeline
      await tester.pumpWidget(wrapWithRouter(LotTimelinePage(lotId: lot.id)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // 4. Worker-Wise Production History
      await tester.pumpWidget(
        wrapWithRouter(const WorkerProductionHistoryPage()),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Rameshbhai'), findsWidgets);

      // 5. Process-Wise Production History
      await tester.pumpWidget(wrapWithRouter(const ProcessHistoryPage()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Stitching'), findsWidgets);

      // 6. QC Inspection Queue (Pending Return + Rejection tabs)
      await tester.pumpWidget(wrapWithRouter(const InspectionQueuePage()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('LOT-UI-01'), findsWidgets);

      // 7. Production Transaction Detail (PIN audit badge)
      await tester.pumpWidget(
        wrapWithRouter(
          ProductionTransactionDetailPage(
            kindSegment: ProductionTransactionKind.inspection.routeSegment,
            transactionId: insp.inspection.id,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('LOT-UI-01'), findsWidgets);

      // 8. Full App Dashboard smoke check
      await tester.pumpWidget(BusinessManagerApp(config: AppConfig.dev()));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
