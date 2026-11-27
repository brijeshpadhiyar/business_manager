import 'dart:io';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/lots/presentation/pages/lot_create_page.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:business_manager/features/settings/presentation/pages/stock_labour_settings_page.dart';
import 'package:business_manager/features/workers/domain/repositories/worker_repository.dart';
import 'package:business_manager/features/workers/presentation/pages/worker_form_page.dart';
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
    tempDir = await Directory.systemTemp.createTemp('sf_dyn_ui_');
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

  Widget wrapWithRouter(Widget child) {
    final router = GoRouter(
      initialLocation: '/target',
      routes: [
        GoRoute(path: '/', builder: (_, _) => const SizedBox.shrink()),
        GoRoute(path: '/target', builder: (_, _) => child),
      ],
    );
    return MaterialApp.router(
      theme: AppTheme.light(),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: router,
    );
  }

  testWidgets(
    'StockLabourSettingsPage links to Work Stages and renders INR rates without overflow at 360dp',
    (tester) async {
      tester.view.physicalSize = const Size(360, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final procRepo = getIt<ProcessRepository>();
      await procRepo.createProcess(
        name: 'Silay',
        defaultRatePaise: 2500,
        defaultPricingUnit: 'PER_PIECE',
      );
      await procRepo.createProcess(
        name: 'Cutting',
        defaultRatePaise: 1200,
        defaultPricingUnit: 'PER_PIECE',
      );

      await tester.pumpWidget(wrapWithRouter(const StockLabourSettingsPage()));
      await tester.pumpAndSettle();

      final listScrollable = find.byType(Scrollable).first;
      // Work stages are created from their own tab; settings links there.
      await tester.scrollUntilVisible(
        find.text('Manage Work Stages'),
        200,
        scrollable: listScrollable,
      );
      expect(find.text('Manage Work Stages'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Silay'),
        200,
        scrollable: listScrollable,
      );
      expect(find.text('Silay'), findsOneWidget);
      expect(find.textContaining('₹25.00 / pc'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Cutting'),
        200,
        scrollable: listScrollable,
      );
      expect(find.text('Cutting'), findsOneWidget);
      expect(find.textContaining('₹12.00 / pc'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'LotCreatePage supports inline design addition and atomic lot save',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWithRouter(const LotCreatePage()));
      await tester.pumpAndSettle();

      // Enter Lot Number
      final lotNumField = find.byType(TextFormField).first;
      await tester.enterText(lotNumField, 'LOT-UI-900');

      final mainScrollable = find.byType(Scrollable).first;
      // Open inline "+ Add New Design" without leaving the screen
      await tester.scrollUntilVisible(
        find.text('Add New Design'),
        200,
        scrollable: mainScrollable,
      );
      await tester.ensureVisible(find.text('Add New Design'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add New Design'));
      await tester.pumpAndSettle();

      expect(find.text('New Design (Inline)'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Add Design to Lot'),
        150,
        scrollable: mainScrollable,
      );
      await tester.ensureVisible(find.text('Add Design to Lot'));
      await tester.pumpAndSettle();
      final inlineDesignNameField = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            (w.decoration?.labelText?.contains('Design') ?? false),
      );
      await tester.enterText(inlineDesignNameField, 'D-Inline-1');
      await tester.tap(find.text('Add Design to Lot'));
      await tester.pumpAndSettle();

      expect(find.text('D-Inline-1'), findsOneWidget);

      // Pinned Save button is immediately visible without extra scrolling
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      // Drain the 3s success toast auto-dismiss timer cleanly.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      final lots = await getIt<LotRepository>().getLots();
      expect(lots.length, 1);
      expect(lots.first.lotNumber, 'LOT-UI-900');
      final detail = await getIt<LotRepository>().getLotDetail(lots.first.id);
      expect(detail!.designs.length, 1);
      expect(detail.designs.first.design.designName, 'D-Inline-1');
    },
  );

  testWidgets(
    'WorkerFormPage creates worker with multi-process assignments and inherited/custom rates',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final procRepo = getIt<ProcessRepository>();
      await procRepo.createProcess(
        name: 'Silay',
        defaultRatePaise: 2000,
        defaultPricingUnit: 'PER_PIECE',
      );
      await procRepo.createProcess(
        name: 'Cutting',
        defaultRatePaise: 1000,
        defaultPricingUnit: 'PER_PIECE',
      );

      await tester.pumpWidget(wrapWithRouter(const WorkerFormPage()));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Worker Name'),
        'Suresh Master',
      );

      final mainScrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        find.text('Silay'),
        200,
        scrollable: mainScrollable,
      );
      await tester.ensureVisible(find.text('Silay'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Silay'));
      await tester.pumpAndSettle();
      expect(find.text('Inherits Default'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Cutting'),
        200,
        scrollable: mainScrollable,
      );
      await tester.ensureVisible(find.text('Cutting'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cutting'));
      await tester.pumpAndSettle();

      // Pinned Save button is always visible
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final workers = await getIt<WorkerRepository>().getWorkers();
      expect(workers.length, 1);
      expect(workers.first.name, 'Suresh Master');
      final detail = await getIt<WorkerRepository>().getWorkerDetail(
        workers.first.id,
      );
      expect(detail!.assignedProcesses.length, 2);
    },
  );
}
