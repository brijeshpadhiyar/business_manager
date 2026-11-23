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
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempDir;
  late AppDatabase testDb;

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('sf_m4_ui_');
    testDb = AppDatabase.forTesting(NativeDatabase.memory());

    final config = AppConfig.dev();
    await configureDependencies(config);

    // Override DB & media storage with isolated in-memory / temp test instances
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
    'navigates Dashboard -> Lots -> Inventory -> Business Profile in EN & GU + Dark theme',
    (tester) async {
      final config = AppConfig.dev();
      await tester.pumpWidget(BusinessManagerApp(config: config));
      await tester.pumpAndSettle();

      expect(find.text('StitchFlow Dev'), findsWidgets);

      // Navigate to Lots tab -> verify empty state
      await tester.tap(find.text('Lots').last);
      await tester.pumpAndSettle();
      expect(find.text('No Lots Yet'), findsOneWidget);

      // Navigate to Inventory tab -> verify empty initial inventory state
      await tester.tap(find.text('Inventory').last);
      await tester.pumpAndSettle();
      expect(find.text('Initial Inventory Overview'), findsOneWidget);
      expect(find.text('No Initial Inventory Yet'), findsOneWidget);

      // Navigate to Business Profile tab -> verify seeded profile & validation
      await tester.tap(find.text('Business Profile').last);
      await tester.pumpAndSettle();
      expect(find.text('Business Profile'), findsWidgets);
      expect(find.text('Business Manager'), findsOneWidget);

      // Switch to Gujarati & Dark Theme
      await getIt<ThemeCubit>().setPreference(AppThemePreference.dark);
      await getIt<LocaleCubit>().setPreference(AppLocalePreference.gu);
      await tester.pumpAndSettle();

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.themeMode, ThemeMode.dark);
      expect(find.text('બિઝનેસ પ્રોફાઇલ'), findsWidgets);
    },
  );
}
