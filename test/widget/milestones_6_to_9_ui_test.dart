import 'dart:io';

import 'package:business_manager/app.dart';
import 'package:business_manager/core/config/app_config.dart';
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
    tempDir = await Directory.systemTemp.createTemp('sf_m6_9_ui_');
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
    'navigates Live Dashboard -> Stock Movements -> Accounting -> Reports -> Backup in EN & GU + Light/Dark',
    (tester) async {
      final config = AppConfig.dev();
      await tester.pumpWidget(BusinessManagerApp(config: config));
      await tester.pumpAndSettle();

      // Live Dashboard renders real KPIs
      await tester.scrollUntilVisible(
        find.text('Inventory & Production Health'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Inventory & Production Health'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Worker Accounting Summary'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Worker Accounting Summary'), findsOneWidget);
      await tester.drag(find.byType(ListView).first, const Offset(0, 900));
      await tester.pumpAndSettle();

      // Open Stock Movements screen
      await tester.tap(find.text('Stock Movements').first);
      await tester.pumpAndSettle();
      expect(find.text('No Pending Issues'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Open Labour & Payments screen
      await tester.tap(find.text('Labour & Payments').first);
      await tester.pumpAndSettle();
      expect(find.text('Labour & Worker Accounts'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Open Business Reports screen & verify V1.2 report categories
      await tester.tap(find.text('Reports').first);
      await tester.pumpAndSettle();
      expect(find.text('Business Reports'), findsOneWidget);
      expect(find.text('Daily Workshop'), findsWidgets);
      await tester.pageBack();
      await tester.pumpAndSettle();

      // Open Settings -> Backup & Data Safety screen
      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Backup & Data Safety'),
        200,
        scrollable: find.descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        ),
      );
      await tester.ensureVisible(find.text('Backup & Data Safety').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Backup & Data Safety').first);
      await tester.pumpAndSettle();
      expect(find.text('Create Full Backup (.zip)'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Export Raw SQLite (.sqlite)').first,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Export Raw SQLite (.sqlite)'), findsWidgets);

      // Switch to Gujarati + Dark Mode & verify localization + theme
      await getIt<ThemeCubit>().setPreference(AppThemePreference.dark);
      await getIt<LocaleCubit>().setPreference(AppLocalePreference.gu);
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
      expect(find.text('બેકઅપ, રિસ્ટોર અને ડેટા સુરક્ષા'), findsWidgets);
    },
  );

  testWidgets(
    'renders Live Dashboard cleanly across Mobile (360dp), Tablet (800dp), and Desktop (1280dp)',
    (tester) async {
      final config = AppConfig.dev();
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1.0;

      // Mobile 360dp
      tester.view.physicalSize = const Size(360, 800);
      await tester.pumpWidget(BusinessManagerApp(config: config));
      await tester.pumpAndSettle();
      expect(find.byType(NavigationBar), findsOneWidget);

      // Tablet 800dp
      tester.view.physicalSize = const Size(800, 1024);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationRail), findsOneWidget);

      // Desktop 1280dp
      tester.view.physicalSize = const Size(1280, 900);
      await tester.pumpAndSettle();
      expect(find.byType(NavigationDrawer), findsOneWidget);
    },
  );
}
