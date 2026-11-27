import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/design_system/app_colors.dart';
import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/error/exceptions.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/router/app_router.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/lots/data/repositories/colour_master_repository_impl.dart';
import 'package:business_manager/features/lots/data/repositories/lot_repository_impl.dart';
import 'package:business_manager/features/lots/domain/repositories/colour_master_repository.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/lots/presentation/widgets/visual_colour_picker_sheet.dart';
import 'package:business_manager/features/process_routing/data/repositories/process_routing_repository_impl.dart';
import 'package:business_manager/features/process_routing/domain/entities/process_routing_entities.dart';
import 'package:business_manager/features/process_routing/domain/repositories/process_routing_repository.dart';
import 'package:business_manager/features/process_routing/presentation/pages/job_process_routing_page.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:business_manager/features/stock_movements/data/repositories/stock_movement_repository_impl.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const now = 1795324800000;

  group('Visual Colour Master & Lot Colour Workflow (Unit / DB)', () {
    late AppDatabase db;
    late DatabaseTransactionRunner txRunner;
    late IdGenerator idGenerator;
    late ColourMasterRepository colourMasterRepo;
    late LotRepository lotRepo;
    late ProcessRoutingRepository routingRepo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.verifyPragmas();
      txRunner = DatabaseTransactionRunner(db);
      idGenerator = IdGenerator();
      colourMasterRepo = ColourMasterRepositoryImpl(db, txRunner, idGenerator);
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
    });

    tearDown(() async {
      await db.close();
    });

    test(
      'seeds default colour_master palette and supports custom colours',
      () async {
        final initial = await colourMasterRepo.getAllColours();
        expect(initial.length, greaterThanOrEqualTo(20));
        expect(
          initial.any((c) => c.name == 'Red' && c.hexCode == '#DC2626'),
          isTrue,
        );

        final created = await colourMasterRepo.createCustomColour(
          name: 'Peacock Teal',
          hexCode: '#0d7377',
        );
        expect(created.name, 'Peacock Teal');
        expect(created.hexCode, '#0D7377');
        expect(created.isCustom, isTrue);

        // Update custom colour
        final updated = await colourMasterRepo.updateColour(
          id: created.id,
          name: 'Deep Peacock',
          hexCode: '#095256',
        );
        expect(updated.name, 'Deep Peacock');
        expect(updated.hexCode, '#095256');
      },
    );

    test('prevents duplicate colour creation (case-insensitive)', () async {
      await expectLater(
        colourMasterRepo.createCustomColour(name: 'red', hexCode: '#FF0000'),
        throwsA(isA<DomainValidationException>()),
      );
    });

    test('creates colour-only lot and design-based lot with same colour across designs', () async {
      // 1. Colour-only lot
      final lot1 = await lotRepo.createLot(
        lotNumber: 'LOT-C1',
        title: 'Colour Only Batch',
        transactionAtUtcMillis: now,
      );
      await lotRepo.addColourDirectlyToLot(
        lotId: lot1.id,
        colourName: 'Red',
        colourHex: '#DC2626',
        initialQuantity: 200,
        unitPricePaise: 5000,
      );
      await lotRepo.addColourDirectlyToLot(
        lotId: lot1.id,
        colourName: 'Blue',
        colourHex: '#2563EB',
        initialQuantity: 150,
        unitPricePaise: 5000,
      );
      final lot1Detail = await lotRepo.getLotDetail(lot1.id);
      expect(lot1Detail!.designs.length, 1);
      expect(
        lot1Detail.designs.first.design.designName,
        kColourOnlyDesignSentinel,
      );
      expect(lot1Detail.designs.first.colours.length, 2);
      final lot1Total = lot1Detail.designs.first.colours.fold<int>(
        0,
        (s, c) => s + c.initialQuantity,
      );
      expect(lot1Total, 350);

      // 2. Design-based lot with same colour (Red) under two different designs
      final lot2 = await lotRepo.createLot(
        lotNumber: 'LOT-D1',
        title: 'Multi Design Batch',
        transactionAtUtcMillis: now,
      );
      final d101 = await lotRepo.createDesign(
        lotId: lot2.id,
        designName: 'D-101',
      );
      final d102 = await lotRepo.createDesign(
        lotId: lot2.id,
        designName: 'D-102',
      );

      await lotRepo.createDesignColour(
        lotDesignId: d101.id,
        colourName: 'Red',
        colourHex: '#DC2626',
        initialQuantity: 100,
        unitPricePaise: 6000,
      );
      await lotRepo.createDesignColour(
        lotDesignId: d102.id,
        colourName: 'Red',
        colourHex: '#DC2626',
        initialQuantity: 80,
        unitPricePaise: 6000,
      );
      final lot2Detail = await lotRepo.getLotDetail(lot2.id);
      expect(lot2Detail!.designs.length, 2);
      final totalLot2 = lot2Detail.designs.fold<int>(
        0,
        (sum, d) =>
            sum + d.colours.fold<int>(0, (cs, c) => cs + c.initialQuantity),
      );
      expect(totalLot2, 180);
    });

    test('colour-wise assignments, direct transfers, factory returns & strict quantity reconciliation', () async {
      // Seed processes & workers
      await db.processMemberDao.insertProcess(
        const ProcessesCompanion(
          id: Value('p-cut'),
          name: Value('Cutting'),
          defaultRatePaise: Value(500),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await db.processMemberDao.insertProcess(
        const ProcessesCompanion(
          id: Value('p-pack'),
          name: Value('Packing'),
          defaultRatePaise: Value(300),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await db.processMemberDao.insertMember(
        const MembersCompanion(
          id: Value('w-dharmesh'),
          name: Value('Dharmesh Bhai'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );
      await db.processMemberDao.insertMember(
        const MembersCompanion(
          id: Value('w-packing'),
          name: Value('Packing Dept'),
          createdAt: Value(now),
          updatedAt: Value(now),
        ),
      );

      final lot = await lotRepo.createLot(
        lotNumber: 'LOT-REC-1',
        transactionAtUtcMillis: now,
      );
      final red = await lotRepo.addColourDirectlyToLot(
        lotId: lot.id,
        colourName: 'Red',
        colourHex: '#DC2626',
        initialQuantity: 100,
        unitPricePaise: 0,
      );
      final blue = await lotRepo.addColourDirectlyToLot(
        lotId: lot.id,
        colourName: 'Blue',
        colourHex: '#2563EB',
        initialQuantity: 80,
        unitPricePaise: 0,
      );

      // Assign 60 Red to Cutting -> Direct Transfer 40 Red to Packing -> Return 20 Red to Factory
      final redCut = await routingRepo.addJobProcess(
        lotId: lot.id,
        designColourId: red.id,
        processId: 'p-cut',
        workerId: 'w-dharmesh',
        quantity: 60,
        transactionAtUtcMillis: now,
        dispatchImmediately: true,
        agreedRatePaise: 500,
      );
      await routingRepo.directTransfer(
        sourceJobProcessId: redCut.id,
        destinationProcessId: 'p-pack',
        destinationWorkerId: 'w-packing',
        quantity: 40,
        transactionAtUtcMillis: now,
        autoConfirmReceipt: true,
      );
      await routingRepo.returnToFactory(
        sourceJobProcessId: redCut.id,
        goodQuantity: 20,
        damagedQuantity: 0,
        transactionAtUtcMillis: now,
      );

      // Assign 30 Blue to Cutting (must remain isolated from Red)
      await routingRepo.addJobProcess(
        lotId: lot.id,
        designColourId: blue.id,
        processId: 'p-cut',
        workerId: 'w-dharmesh',
        quantity: 30,
        transactionAtUtcMillis: now,
        dispatchImmediately: true,
        agreedRatePaise: 500,
      );

      final overview = (await routingRepo.getJobRoutingOverview(lot.id))!;
      final redBal = overview.skuBalances.firstWhere(
        (b) => b.designColourId == red.id,
      );
      final blueBal = overview.skuBalances.firstWhere(
        (b) => b.designColourId == blue.id,
      );

      // Red: 100 initial = 60 in factory (40 untouched + 20 returned) + 40 with Packing Dept
      expect(redBal.physicalAvailableInHouse, 60);
      expect(redBal.totalPendingWithWorkers, 40);
      expect(
        redBal.physicalAvailableInHouse +
            redBal.totalPendingWithWorkers +
            redBal.damagedBucket,
        redBal.initialQuantity,
      );

      // Blue: 80 initial = 50 in factory + 30 with Dharmesh
      expect(blueBal.physicalAvailableInHouse, 50);
      expect(blueBal.totalPendingWithWorkers, 30);
      expect(
        blueBal.physicalAvailableInHouse +
            blueBal.totalPendingWithWorkers +
            blueBal.damagedBucket,
        blueBal.initialQuantity,
      );

      // Handovers strictly preserve designColourId
      final redHandovers = overview.handovers
          .where((h) => h.designColourId == red.id)
          .toList();
      final blueHandovers = overview.handovers
          .where((h) => h.designColourId == blue.id)
          .toList();
      expect(
        redHandovers.any(
          (h) => h.handoverType == ProcessHandoverType.directTransfer,
        ),
        isTrue,
      );
      expect(
        redHandovers.any(
          (h) => h.handoverType == ProcessHandoverType.factoryReturn,
        ),
        isTrue,
      );
      expect(blueHandovers.length, 1);
    });

    test('legacy null-HEX colours resolve cleanly with high contrast', () {
      final resolvedRed = AppColourUtils.resolveColor(
        null,
        fallbackName: 'Red',
      );
      expect(AppColourUtils.toHex(resolvedRed), '#DC2626');

      final whiteColor = AppColourUtils.resolveColor(
        '#FFFFFF',
        fallbackName: 'White',
      );
      final blackColor = AppColourUtils.resolveColor(
        '#111827',
        fallbackName: 'Black',
      );
      expect(AppColourUtils.contrastForeground(whiteColor), AppColors.slate900);
      expect(AppColourUtils.contrastForeground(blackColor), Colors.white);
    });
  });

  group('Visual Colour Picker, Colour Cards & Colour Detail UI (Widget)', () {
    late AppDatabase testDb;

    setUp(() async {
      await getIt.reset();
      SharedPreferences.setMockInitialValues({});
      testDb = AppDatabase.forTesting(NativeDatabase.memory());

      final config = AppConfig.dev();
      await configureDependencies(config);
      await getIt.unregister<AppDatabase>();
      getIt.registerSingleton<AppDatabase>(testDb);
    });

    tearDown(() async {
      await testDb.close();
    });

    testWidgets(
      'VisualColourPickerSheet selects, deselects, enters quantities, and returns variants',
      (tester) async {
        List<dynamic>? picked;
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (ctx) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      picked = await VisualColourPickerSheet.show(
                        ctx,
                        title: 'Select Colours',
                      );
                    },
                    child: const Text('Open Picker'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Picker'));
        await tester.pumpAndSettle();

        // Select Red and Blue
        await tester.tap(find.text('Red').first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Blue').first);
        await tester.pumpAndSettle();

        expect(find.text('Selected Colours (2)'), findsOneWidget);

        // Deselect Blue
        await tester.tap(find.text('Blue').first);
        await tester.pumpAndSettle();
        expect(find.text('Selected Colours (1)'), findsOneWidget);

        // Enter quantity for Red and confirm
        final qtyField = find.widgetWithText(TextFormField, 'Qty (pcs)').first;
        await tester.enterText(qtyField, '125');
        await tester.pumpAndSettle();

        final confirmBtn = find.text('Add 1 Colour(s) • 125 pcs');
        await tester.ensureVisible(confirmBtn);
        await tester.tap(confirmBtn);
        await tester.pumpAndSettle();

        expect(picked, isNotNull);
        expect(picked!.length, 1);
      },
    );

    testWidgets(
      'LotDetailPage renders clickable Premium Colour Cards and navigates to LotColourDetailPage',
      (tester) async {
        final lotRepo = getIt<LotRepository>();
        final lot = await lotRepo.createLot(
          lotNumber: 'LOT-UI-1',
          title: 'Visual Cards Test',
          transactionAtUtcMillis: now,
        );
        await lotRepo.addColourDirectlyToLot(
          lotId: lot.id,
          colourName: 'Royal Blue',
          colourHex: '#1D4ED8',
          initialQuantity: 250,
          unitPricePaise: 4500,
        );

        final router = createAppRouter(AppConfig.dev());
        await tester.pumpWidget(
          BlocProvider<AppLockCubit>.value(
            value: getIt<AppLockCubit>(),
            child: MaterialApp.router(
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
            ),
          ),
        );
        router.go(RoutePaths.lotDetail(lot.id));
        await tester.pumpAndSettle();

        // Scroll to Premium Colour Card and verify content
        await tester.scrollUntilVisible(
          find.text('Royal Blue'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        expect(find.text('Royal Blue'), findsOneWidget);
        expect(find.text('#1D4ED8'), findsOneWidget);
        expect(find.text('250'), findsOneWidget);

        // Tap the colour card -> navigates to LotColourDetailPage
        await tester.tap(find.text('Royal Blue'));
        await tester.pumpAndSettle();

        expect(find.text('Royal Blue Details'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Stage-wise Breakdown'),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Stage-wise Breakdown'), findsOneWidget);
        // Only stages actually used on this colour are listed: no hardcoded
        // Cutting / Stitching / Packing placeholders.
        expect(find.text('No work stages assigned yet.'), findsOneWidget);
        expect(find.text('Stitching'), findsNothing);
      },
    );

    testWidgets(
      'JobProcessRoutingPage filters operations strictly by colour chip',
      (tester) async {
        tester.view.physicalSize = const Size(900, 1800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await testDb.processMemberDao.insertProcess(
          const ProcessesCompanion(
            id: Value('p-cut'),
            name: Value('Cutting'),
            defaultRatePaise: Value(500),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );
        await testDb.processMemberDao.insertMember(
          const MembersCompanion(
            id: Value('w-1'),
            name: Value('Ramesh Bhai'),
            createdAt: Value(now),
            updatedAt: Value(now),
          ),
        );

        final lotRepo = getIt<LotRepository>();
        final routingRepo = getIt<ProcessRoutingRepository>();
        final lot = await lotRepo.createLot(
          lotNumber: 'LOT-FLT-1',
          transactionAtUtcMillis: now,
        );
        final red = await lotRepo.addColourDirectlyToLot(
          lotId: lot.id,
          colourName: 'Red',
          colourHex: '#DC2626',
          initialQuantity: 100,
          unitPricePaise: 0,
        );
        final black = await lotRepo.addColourDirectlyToLot(
          lotId: lot.id,
          colourName: 'Black',
          colourHex: '#111827',
          initialQuantity: 90,
          unitPricePaise: 0,
        );

        await routingRepo.addJobProcess(
          lotId: lot.id,
          designColourId: red.id,
          processId: 'p-cut',
          workerId: 'w-1',
          quantity: 40,
          transactionAtUtcMillis: now,
          dispatchImmediately: true,
        );
        await routingRepo.addJobProcess(
          lotId: lot.id,
          designColourId: black.id,
          processId: 'p-cut',
          workerId: 'w-1',
          quantity: 30,
          transactionAtUtcMillis: now,
          dispatchImmediately: true,
        );

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: JobProcessRoutingPage(lotId: lot.id),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('All (2)'), findsOneWidget);
        expect(find.text('Work Stage (2)'), findsOneWidget);

        // Tap Red colour filter chip
        await tester.tap(find.text('Red (40)'));
        await tester.pumpAndSettle();

        expect(find.text('Work Stage (1)'), findsOneWidget);
      },
    );
  });
}
