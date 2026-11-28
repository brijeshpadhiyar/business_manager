import 'dart:io';

import 'package:business_manager/app.dart';
import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_identity.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/locale_cubit.dart';
import 'package:business_manager/core/localization/locale_state.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/theme/theme_cubit.dart';
import 'package:business_manager/core/theme/theme_state.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/accounting/domain/repositories/accounting_repository.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:business_manager/features/rates/domain/repositories/rate_repository.dart';
import 'package:business_manager/features/settings/domain/help_topics.dart';
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
    tempDir = await Directory.systemTemp.createTemp('sf_v1_1_ui_');
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

  Future<({String colourId, String processId, String workerId})>
  seedWorkshopData() async {
    final lotRepo = getIt<LotRepository>();
    final processRepo = getIt<ProcessRepository>();
    final workerRepo = getIt<WorkerRepository>();
    final rateRepo = getIt<RateRepository>();

    final now = IstDateTimeHelper.nowUtcMillis();
    final lot = await lotRepo.createLot(
      lotNumber: 'LOT-101',
      title: 'Festive Kurti',
      transactionAtUtcMillis: now,
    );
    final design = await lotRepo.createDesign(
      lotId: lot.id,
      designName: 'D-201',
    );
    final colour = await lotRepo.createDesignColour(
      lotDesignId: design.id,
      colourName: 'Teal',
      initialQuantity: 100,
      unitPricePaise: 45000,
    );
    final proc = await processRepo.createProcess(name: 'Stitching');
    final worker = await workerRepo.createWorker(
      name: 'Ramesh Patel',
      phone: '9876543210',
    );
    await workerRepo.assignProcessToWorker(
      workerId: worker.id,
      processId: proc.id,
    );
    await rateRepo.addRate(
      workerId: worker.id,
      processId: proc.id,
      ratePaise: 2500, // ₹25.00
      effectiveFrom: '2025-01-01',
    );

    return (colourId: colour.id, processId: proc.id, workerId: worker.id);
  }

  test('Android splash, launcher icon, and flavor resource configuration check', () {
    final v31Light = File('android/app/src/main/res/values-v31/styles.xml');
    final v31Dark = File(
      'android/app/src/main/res/values-night-v31/styles.xml',
    );
    final v21Light = File(
      'android/app/src/main/res/drawable-v21/launch_background.xml',
    );
    final v21Dark = File(
      'android/app/src/main/res/drawable-night-v21/launch_background.xml',
    );
    final launcherAdaptive = File(
      'android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml',
    );
    final gradle = File('android/app/build.gradle.kts');

    expect(v31Light.existsSync(), isTrue);
    expect(v31Dark.existsSync(), isTrue);
    expect(v21Light.existsSync(), isTrue);
    expect(v21Dark.existsSync(), isTrue);
    expect(launcherAdaptive.existsSync(), isTrue);

    final v31LightXml = v31Light.readAsStringSync();
    expect(v31LightXml, contains('windowSplashScreenBackground'));
    expect(v31LightXml, contains('splash_icon_android12'));
    expect(v31LightXml, contains('splash_branding_light'));

    final v31DarkXml = v31Dark.readAsStringSync();
    expect(v31DarkXml, contains('splash_background_dark'));
    expect(v31DarkXml, contains('splash_icon_android12'));
    expect(v31DarkXml, contains('splash_branding_dark'));

    final v21LightXml = v21Light.readAsStringSync();
    expect(v21LightXml, contains('splash_brand_light'));

    for (final density in const [
      'mdpi',
      'hdpi',
      'xhdpi',
      'xxhdpi',
      'xxxhdpi',
    ]) {
      expect(
        File(
          'android/app/src/main/res/drawable-$density/splash_icon_android12.png',
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          'android/app/src/main/res/drawable-$density/splash_brand_light.png',
        ).existsSync(),
        isTrue,
      );
      expect(
        File('android/app/src/main/res/drawable-$density/splash_brand_dark.png')
            .existsSync(),
        isTrue,
      );
    }

    final gradleText = gradle.readAsStringSync();
    expect(gradleText, contains('StitchFlow Dev'));
    expect(gradleText, contains('"StitchFlow"'));
    expect(gradleText, contains('com.brijesh.stitchflow'));
  });

  test('Help & Guidance catalog contains all 23 bilingual workshop topics', () {
    expect(StitchFlowHelpCatalog.topics.length, 23);
    for (final topic in StitchFlowHelpCatalog.topics) {
      expect(topic.titleEn.trim(), isNotEmpty);
      expect(topic.titleGu.trim(), isNotEmpty);
      expect(topic.stepsEn, isNotEmpty);
      expect(topic.stepsGu, isNotEmpty);
      expect(topic.exampleEn.trim(), isNotEmpty);
      expect(topic.exampleGu.trim(), isNotEmpty);
    }
  });

  testWidgets(
    'Centralized Settings, Appearance persistence, Stock & Labour, Help & About work cleanly in EN & GU at 360dp',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await seedWorkshopData();
      final config = AppConfig.dev();
      await tester.pumpWidget(BusinessManagerApp(config: config));
      await tester.pumpAndSettle();

      // Open Settings via More sheet from compact StitchFlowBottomNav
      expect(find.byType(StitchFlowBottomNav), findsOneWidget);
      await tester.tap(find.text('More').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Business Profile'), findsOneWidget);
      expect(find.text('Stock & Labour Preferences'), findsOneWidget);

      final settingsScrollable = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Backup & Data Safety'),
        200,
        scrollable: settingsScrollable,
      );
      expect(find.text('Backup & Data Safety'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Help & Guidance'),
        200,
        scrollable: settingsScrollable,
      );
      expect(find.text('Help & Guidance'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('About StitchFlow'),
        200,
        scrollable: settingsScrollable,
      );
      expect(find.text('About StitchFlow'), findsOneWidget);

      // Scroll back to top of Settings list so Appearance is centered in viewport
      await tester.scrollUntilVisible(
        find.text('Appearance'),
        -200,
        scrollable: settingsScrollable,
      );
      await tester.ensureVisible(find.text('Appearance'));
      await tester.pumpAndSettle();

      // 1. Appearance: switch Theme to Dark & Language to Gujarati, verify persistence
      await tester.tap(find.text('Appearance'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();
      expect(getIt<ThemeCubit>().state.preference, AppThemePreference.dark);

      await tester.scrollUntilVisible(
        find.text('ગુજરાતી (Gujarati)'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(find.text('ગુજરાતી (Gujarati)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('ગુજરાતી (Gujarati)'));
      await tester.pumpAndSettle();
      expect(getIt<LocaleCubit>().state.preference, AppLocalePreference.gu);

      // Switch back to English Light for readable assertions
      await tester.scrollUntilVisible(
        find.text('English (અંગ્રેજી)'),
        -200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(find.text('English (અંગ્રેજી)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English (અંગ્રેજી)'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Light'),
        -200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(find.text('Light'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 2. Stock & Labour Preferences shows the payment rule, the Work Stages
      // link and the seeded 'Stitching' stage
      await tester.tap(find.text('Stock & Labour Preferences'));
      await tester.pumpAndSettle();
      expect(find.text('Manage Work Stages'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Stitching'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Stitching'), findsOneWidget);
      expect(find.text('Inherits Global Default'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 3. Help & Guidance: search and open topic detail
      await tester.scrollUntilVisible(
        find.text('Help & Guidance'),
        200,
        scrollable: settingsScrollable,
      );
      await tester.ensureVisible(find.text('Help & Guidance'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Help & Guidance'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'return');
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Receiving Returned Stock').first);
      await tester.pumpAndSettle();
      expect(find.text('Step-by-Step Guide'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Practical Workshop Example'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Practical Workshop Example'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();

      // 4. About StitchFlow
      await tester.scrollUntilVisible(
        find.text('About StitchFlow'),
        200,
        scrollable: settingsScrollable,
      );
      await tester.ensureVisible(find.text('About StitchFlow'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('About StitchFlow'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('100% Offline & Private Local Data'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('100% Offline & Private Local Data'), findsOneWidget);
      expect(find.textContaining(AppIdentity.appVersion), findsWidgets);

      // Ensure zero overflow or layout exceptions occurred
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Redesigned Stock Issue & Receive Return workflows: validation, partial/full return, reason guard, labour & stock accuracy',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final seeded = await seedWorkshopData();
      final config = AppConfig.dev();
      await tester.pumpWidget(BusinessManagerApp(config: config));
      await tester.pumpAndSettle();

      // Open Stock Issue from Dashboard Quick Action tile
      await tester.tap(find.text('Issue stock to worker').first);
      await tester.pumpAndSettle();

      // Single seeded colour with stock auto-selects; verify locked rate ₹25.00 preview
      expect(find.textContaining('₹25.00'), findsWidgets);

      // Test over-stock validation (150 > 100 available)
      final issueListScroll = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Issue Quantity (pcs)'),
        200,
        scrollable: issueListScroll,
      );
      await tester.enterText(find.byType(TextFormField).first, '150');
      await tester.pumpAndSettle();
      expect(
        find.text('Cannot issue more than available good stock.'),
        findsOneWidget,
      );

      // Enter valid quantity 40 and submit
      await tester.enterText(find.byType(TextFormField).first, '40');
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Confirm & Issue Stock'),
        250,
        scrollable: issueListScroll,
      );
      await tester.ensureVisible(find.text('Confirm & Issue Stock'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm & Issue Stock'));
      await tester.pumpAndSettle();

      // Step 5 Success Screen shows updated available stock = 60 pcs
      expect(find.text('Stock Issued Successfully'), findsOneWidget);
      expect(find.text('60 pcs'), findsWidgets);

      // Proceed directly to Receive Return from success screen
      await tester.ensureVisible(find.text('View Issue / Receive Return'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('View Issue / Receive Return'));
      await tester.pumpAndSettle();

      // 1. Over-return validation: try entering 50 > 40 pending
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '50');
      await tester.pumpAndSettle();
      expect(
        find.text('Total entered exceeds remaining pending quantity.'),
        findsOneWidget,
      );

      // 2. Partial return: 25 Good (leaves 15 pending)
      await tester.enterText(fields.at(0), '25');
      await tester.pumpAndSettle();
      expect(find.text('15 pcs'), findsWidgets); // live remaining pending
      final returnListScroll = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first;
      // Save is pinned in the bottom bar; scroll to the labour impact card.
      await tester.scrollUntilVisible(
        find.textContaining('₹625.00'),
        250,
        scrollable: returnListScroll,
      );
      expect(find.textContaining('₹625.00'), findsWidgets); // 25 * ₹25 labour
      await tester.ensureVisible(find.text('Confirm & Save Return'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm & Save Return'));
      await tester.pumpAndSettle();

      expect(find.text('Return Recorded Successfully'), findsOneWidget);
      expect(find.text('15 pcs'), findsWidgets);

      // Verify DB stock & labour balances after partial return
      final stockRepo = getIt<StockMovementRepository>();
      final acctRepo = getIt<AccountingRepository>();
      final balAfterPartial = await stockRepo.getDesignColourBalance(
        seeded.colourId,
      );
      expect(balAfterPartial!.physicalAvailableInHouse, 85); // 60 + 25
      expect(balAfterPartial.totalPendingWithWorkers, 15);
      final workerSummary1 = await acctRepo.getWorkerLedgerDetail(
        seeded.workerId,
      );
      expect(workerSummary1!.summary.earnedLabourPaise, 62500); // ₹625

      // 3. Receive remaining 15 with Damaged + Lost + Shortage -> test mandatory reason guard
      await tester.ensureVisible(find.text('Receive Another Return'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Receive Another Return'));
      await tester.pumpAndSettle();

      final fields2 = find.byType(TextFormField);
      await tester.enterText(fields2.at(0), '10'); // good
      await tester.enterText(fields2.at(1), '2'); // damaged
      await tester.enterText(fields2.at(2), '2'); // lost
      await tester.enterText(fields2.at(3), '1'); // shortage
      await tester.pumpAndSettle();

      final returnListScroll2 = find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.scrollUntilVisible(
        find.text('Confirm & Save Return'),
        250,
        scrollable: returnListScroll2,
      );
      await tester.ensureVisible(find.text('Confirm & Save Return'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm & Save Return'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Reason is required for damaged, lost, or shortage settlements.',
        ),
        findsWidgets,
      );

      // Provide reason and save full settlement
      await tester.scrollUntilVisible(
        fields2.at(4),
        -200,
        scrollable: returnListScroll2,
      );
      await tester.enterText(fields2.at(4), 'Oil mark and count short');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Confirm & Save Return'),
        250,
        scrollable: returnListScroll2,
      );
      await tester.ensureVisible(find.text('Confirm & Save Return'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm & Save Return'));
      await tester.pumpAndSettle();

      expect(find.text('Return Recorded Successfully'), findsOneWidget);
      expect(find.text('Fully Settled'), findsOneWidget);

      // Verify final stock & labour balances in DB
      final finalBal = await stockRepo.getDesignColourBalance(seeded.colourId);
      expect(finalBal!.physicalAvailableInHouse, 95); // 85 + 10
      expect(finalBal.damagedBucket, 2);
      expect(finalBal.totalLost, 2);
      expect(finalBal.totalShortage, 1);
      expect(finalBal.totalPendingWithWorkers, 0);

      final workerSummary2 = await acctRepo.getWorkerLedgerDetail(
        seeded.workerId,
      );
      // 35 total good returned * ₹25 = ₹875.00 (damaged excluded by default)
      expect(workerSummary2!.summary.earnedLabourPaise, 87500);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Duplicate submission protection (clientRequestId idempotency) prevents double stock issue',
    (tester) async {
      final seeded = await seedWorkshopData();
      final stockRepo = getIt<StockMovementRepository>();
      final reqId = getIt<IdGenerator>().nextRequestId();
      final now = IstDateTimeHelper.nowUtcMillis();

      final first = await stockRepo.issueStock(
        designColourId: seeded.colourId,
        processId: seeded.processId,
        workerId: seeded.workerId,
        quantity: 20,
        transactionAtUtcMillis: now,
        clientRequestId: reqId,
      );
      final duplicate = await stockRepo.issueStock(
        designColourId: seeded.colourId,
        processId: seeded.processId,
        workerId: seeded.workerId,
        quantity: 20,
        transactionAtUtcMillis: now,
        clientRequestId: reqId,
      );

      expect(duplicate.id, first.id);
      final bal = await stockRepo.getDesignColourBalance(seeded.colourId);
      expect(bal!.physicalAvailableInHouse, 80);
      expect(bal.totalPendingWithWorkers, 20);
    },
  );

  testWidgets(
    'Gujarati long translations & Dark theme render without overflow across 360dp phone on main tabs',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await seedWorkshopData();
      await getIt<LocaleCubit>().setPreference(AppLocalePreference.gu);
      await getIt<ThemeCubit>().setPreference(AppThemePreference.dark);

      final config = AppConfig.dev();
      await tester.pumpWidget(BusinessManagerApp(config: config));
      await tester.pumpAndSettle();

      // Walk through all 5 bottom navigation slots in Gujarati + Dark at 360dp
      for (final tabLabel in const [
        'ડેશબોર્ડ',
        'લોટ્સ',
        'સ્ટોક',
        'કારીગરો',
        'વધુ',
      ]) {
        await tester.tap(find.text(tabLabel).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      // Open Settings from the More sheet in Gujarati + Dark
      await tester.tap(find.text('સેટિંગ્સ').last);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
