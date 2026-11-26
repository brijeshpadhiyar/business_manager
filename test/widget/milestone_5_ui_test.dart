import 'dart:io';

import 'package:business_manager/app.dart';
import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/design_system/app_icons.dart';
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
    tempDir = await Directory.systemTemp.createTemp('sf_m5_ui_');
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
    'creates process & worker, validates forms, assigns process, adds rate, and renders EN/GU + Light/Dark',
    (tester) async {
      final config = AppConfig.dev();
      await tester.pumpWidget(BusinessManagerApp(config: config));
      await tester.pumpAndSettle();

      // 1. Open Processes from Dashboard Quick Actions -> verify empty state
      await tester.drag(find.byType(ListView).first, const Offset(0, -260));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Processes').first);
      await tester.pumpAndSettle();
      expect(find.text('No Processes Yet'), findsOneWidget);

      // Open New Process form -> test validation -> create 'Cutting'
      await tester.tap(find.text('New Process').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('This field is required.'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'Cutting');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Cutting'), findsOneWidget);

      // Back to shell -> Navigate to Workers tab -> verify empty state -> create 'Hasmukh Bhai'
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Workers').last);
      await tester.pumpAndSettle();
      expect(find.text('No Workers Yet'), findsOneWidget);

      await tester.tap(find.text('New Worker').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('This field is required.'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).first, 'Hasmukh Bhai');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Hasmukh Bhai'), findsOneWidget);

      // 3. Open Worker Profile Summary -> Manage Assignments -> Assign 'Cutting'
      await tester.tap(find.text('Hasmukh Bhai'));
      await tester.pumpAndSettle();
      expect(find.text('Assigned Processes & Current Rates'), findsOneWidget);

      await tester.tap(find.text('Manage Assignments').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Assign Process'));
      await tester.pumpAndSettle();
      expect(find.text('Cutting'), findsOneWidget);

      // 4. Open Rate History -> Add Rate ₹20
      await tester.tap(find.byIcon(AppIcons.pieceRate));
      await tester.pumpAndSettle();
      expect(find.text('No Rates Configured'), findsOneWidget);

      await tester.tap(find.text('Add Rate').first);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, '20');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.textContaining('₹20.00'), findsWidgets);

      // 5. Switch to Gujarati + Dark Theme and verify localized UI
      await getIt<ThemeCubit>().setPreference(AppThemePreference.dark);
      await getIt<LocaleCubit>().setPreference(AppLocalePreference.gu);
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
      expect(find.textContaining('વર્તમાન ભાવ'), findsWidgets);
    },
  );

  testWidgets('renders cleanly across Mobile (360dp) and Desktop (1280dp)', (
    tester,
  ) async {
    final config = AppConfig.dev();

    // Mobile compact width
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(BusinessManagerApp(config: config));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);

    // Desktop expanded width
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationDrawer), findsOneWidget);
  });
}
