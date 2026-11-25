import 'dart:io';

import 'package:business_manager/app.dart';
import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/locale_cubit.dart';
import 'package:business_manager/core/localization/locale_state.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/router/route_paths.dart';
import 'package:business_manager/core/theme/theme_cubit.dart';
import 'package:business_manager/core/theme/theme_state.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:business_manager/features/rates/domain/repositories/rate_repository.dart';
import 'package:business_manager/features/security/presentation/widgets/pin_keypad.dart';
import 'package:business_manager/features/workers/domain/repositories/worker_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Compact-screen matrix: every screen of the app must lay out without
/// overflow on phones (portrait and landscape), with large text, in Gujarati
/// and in dark mode. A failure names the route and the screen size.
void main() {
  late Directory tempDir;
  late AppDatabase testDb;

  setUpAll(IstDateTimeHelper.initialize);

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('sf_compact_');
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
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Future<List<String>> seedAndListRoutes() async {
    final lotRepo = getIt<LotRepository>();
    final processRepo = getIt<ProcessRepository>();
    final workerRepo = getIt<WorkerRepository>();
    final rateRepo = getIt<RateRepository>();
    final now = IstDateTimeHelper.nowUtcMillis();

    final lot = await lotRepo.createLot(
      lotNumber: 'LOT-2024-ULTRA-LONG-NUMBER-101',
      title: 'Festive embroidered kurti with very long descriptive title',
      transactionAtUtcMillis: now,
    );
    final design = await lotRepo.createDesign(
      lotId: lot.id,
      designName: 'D-201 Paisley Heritage Collection',
    );
    final colour = await lotRepo.createDesignColour(
      lotDesignId: design.id,
      colourName: 'Teal Peacock Green',
      initialQuantity: 1250,
      unitPricePaise: 12345678,
    );
    final proc = await processRepo.createProcess(
      name: 'Stitching and finishing',
    );
    final worker = await workerRepo.createWorker(
      name: 'Rameshbhai Jayantilal Patel',
      phone: '9876543210',
    );
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

    return [
      RoutePaths.home,
      RoutePaths.lots,
      RoutePaths.workers,
      RoutePaths.stockMovements,
      RoutePaths.settings,
      RoutePaths.designsColours,
      RoutePaths.processes,
      RoutePaths.inventory,
      RoutePaths.lotCreate,
      RoutePaths.lotDetail(lot.id),
      RoutePaths.lotColourDetail(lot.id, colour.id),
      RoutePaths.lotRouting(lot.id),
      RoutePaths.lotHistory(lot.id),
      RoutePaths.lotTimeline(lot.id),
      RoutePaths.processCreate,
      RoutePaths.processDetail(proc.id),
      RoutePaths.processEdit(proc.id),
      RoutePaths.workerCreate,
      RoutePaths.workerDetail(worker.id),
      RoutePaths.workerEdit(worker.id),
      RoutePaths.workerAssignments(worker.id),
      RoutePaths.workerRates(worker.id),
      RoutePaths.workerRateCreate(worker.id),
      RoutePaths.workerLedger(worker.id),
      RoutePaths.workerAdjustmentCreate(worker.id),
      RoutePaths.stockIssue(),
      RoutePaths.stockReturnPicker,
      RoutePaths.stockRepair,
      RoutePaths.accounting,
      RoutePaths.paymentCreate(),
      RoutePaths.reports,
      RoutePaths.dailySummary,
      RoutePaths.productionHistory,
      RoutePaths.workerProductionHistory,
      RoutePaths.processProductionHistory,
      RoutePaths.inspectionQueue,
      RoutePaths.backupRestore,
      RoutePaths.settingsAppearance,
      RoutePaths.settingsBusinessProfile,
      RoutePaths.settingsStockLabour,
      RoutePaths.settingsSecurity,
      RoutePaths.settingsNotifications,
      RoutePaths.settingsHelp,
      RoutePaths.settingsAbout,
    ];
  }

  Future<void> settle(WidgetTester tester) async {
    try {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 50),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 5),
      );
    } on FlutterError {
      // A screen with a continuous animation: layout is what we check.
    }
  }

  Future<void> configure(
    WidgetTester tester,
    Size size, {
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  final configs = <({String name, Size size, double text, bool gu, bool dark})>[
    (
      name: '320x640',
      size: const Size(320, 640),
      text: 1.0,
      gu: false,
      dark: false,
    ),
    (
      name: '360x800 large text dark',
      size: const Size(360, 800),
      text: 1.3,
      gu: false,
      dark: true,
    ),
    (
      name: '360x800 Gujarati',
      size: const Size(360, 800),
      text: 1.0,
      gu: true,
      dark: false,
    ),
    (
      name: '412x915',
      size: const Size(412, 915),
      text: 1.0,
      gu: false,
      dark: false,
    ),
    (
      name: 'landscape 640x360',
      size: const Size(640, 360),
      text: 1.0,
      gu: false,
      dark: false,
    ),
    (
      name: 'landscape 568x320',
      size: const Size(568, 320),
      text: 1.0,
      gu: false,
      dark: false,
    ),
  ];

  for (final c in configs) {
    testWidgets('every screen lays out cleanly at ${c.name}', (tester) async {
      await configure(tester, c.size, textScale: c.text);
      final routes = await seedAndListRoutes();
      if (c.gu) {
        await getIt<LocaleCubit>().setPreference(AppLocalePreference.gu);
      }
      if (c.dark) {
        await getIt<ThemeCubit>().setPreference(AppThemePreference.dark);
      }
      await tester.pumpWidget(BusinessManagerApp(config: AppConfig.dev()));
      await settle(tester);
      expect(tester.takeException(), isNull, reason: 'start at ${c.name}');

      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      for (final route in routes) {
        router.go(route);
        await settle(tester);
        expect(
          tester.takeException(),
          isNull,
          reason: 'layout error on $route at ${c.name}',
        );
      }
    });
  }

  testWidgets('phone toolbar: Search + More menu instead of many icons', (
    tester,
  ) async {
    await configure(tester, const Size(320, 640));
    await seedAndListRoutes();
    await tester.pumpWidget(BusinessManagerApp(config: AppConfig.dev()));
    await settle(tester);

    expect(find.byIcon(Icons.search_rounded), findsWidgets);
    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
    // The desktop/tablet icon row (e.g. the Reports icon) is not shown.
    expect(find.byIcon(Icons.analytics_outlined), findsNothing);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await settle(tester);
    expect(find.text('Reports'), findsWidgets);
    expect(find.textContaining('Inspection'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('deep-linked secondary page on a phone gets a Home button', (
    tester,
  ) async {
    await configure(tester, const Size(360, 800));
    await seedAndListRoutes();
    await tester.pumpWidget(BusinessManagerApp(config: AppConfig.dev()));
    await settle(tester);

    final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
    router.go(RoutePaths.reports);
    await settle(tester);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.home_outlined));
    await settle(tester);
    expect(find.byIcon(Icons.more_vert_rounded), findsOneWidget);
  });

  group('System back button never closes the app unexpectedly', () {
    // Top-most location, including pushed pages.
    String location(GoRouter router) => router.state.uri.path;

    testWidgets('screen opened from the phone More menu goes back to its tab', (
      tester,
    ) async {
      await configure(tester, const Size(360, 800));
      await seedAndListRoutes();
      await tester.pumpWidget(BusinessManagerApp(config: AppConfig.dev()));
      await settle(tester);
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));

      router.go(RoutePaths.lots);
      await settle(tester);
      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await settle(tester);
      await tester.ensureVisible(find.text('Reports').last);
      await settle(tester);
      await tester.tap(find.text('Reports').last);
      await settle(tester);
      expect(location(router), RoutePaths.reports);

      await tester.binding.handlePopRoute();
      await settle(tester);
      expect(location(router), RoutePaths.lots);
    });

    testWidgets('back on another tab or a go() screen returns Home', (
      tester,
    ) async {
      await configure(tester, const Size(360, 800));
      await seedAndListRoutes();
      await tester.pumpWidget(BusinessManagerApp(config: AppConfig.dev()));
      await settle(tester);
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));

      for (final path in [RoutePaths.workers, RoutePaths.reports]) {
        router.go(path);
        await settle(tester);
        await tester.binding.handlePopRoute();
        await settle(tester);
        expect(location(router), RoutePaths.home, reason: path);
      }
    });

    testWidgets('back on Home asks to press again before exiting', (
      tester,
    ) async {
      final exitCalls = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'SystemNavigator.pop') exitCalls.add(call.method);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await configure(tester, const Size(360, 800));
      await seedAndListRoutes();
      await tester.pumpWidget(BusinessManagerApp(config: AppConfig.dev()));
      await settle(tester);

      await tester.binding.handlePopRoute();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.text('Press back again to exit'), findsOneWidget);
      expect(exitCalls, isEmpty);

      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 300));
      expect(exitCalls, ['SystemNavigator.pop']);
      await settle(tester);
    });
  });

  testWidgets('PIN keypad accepts a physical keyboard (desktop / web)', (
    tester,
  ) async {
    final typed = <String>[];
    var backspaces = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => PinKeypad(
              pinLength: 4,
              enteredLength: typed.length,
              onDigitPressed: (d) => setState(() => typed.add(d)),
              onBackspacePressed: () => setState(() {
                backspaces++;
                typed.removeLast();
              }),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.numpad2);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit7);
    await tester.pump();
    await tester.pump();
    expect(typed, ['4', '7']);
    expect(backspaces, 1);
    expect(find.bySemanticsLabel('Delete'), findsOneWidget);
  });
}
