import 'dart:io';

import 'package:business_manager/app.dart';
import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/security/domain/entities/security_entities.dart';
import 'package:business_manager/features/security/domain/repositories/security_repository.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/security/app_lock_cubit_test.dart';

void main() {
  late Directory tempDir;
  late AppDatabase testDb;
  late InMemorySecurityRepository secRepo;
  late FakeBiometricService bioService;
  late FakeWindowSecurityService winSecService;

  setUpAll(() {
    IstDateTimeHelper.initialize();
  });

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('sf_sec_ui_');
    testDb = AppDatabase.forTesting(NativeDatabase.memory());
    secRepo = InMemorySecurityRepository();
    bioService = FakeBiometricService();
    winSecService = FakeWindowSecurityService();

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
    await getIt.unregister<SecurityRepository>();
    getIt.registerSingleton<SecurityRepository>(secRepo);
    await getIt.unregister<BiometricAuthService>();
    getIt.registerSingleton<BiometricAuthService>(bioService);
    await getIt.unregister<WindowSecurityService>();
    getIt.registerSingleton<WindowSecurityService>(winSecService);
    await getIt.unregister<AppLockCubit>();
    final lockCubit = AppLockCubit(secRepo, bioService, winSecService);
    getIt.registerSingleton<AppLockCubit>(lockCubit);
    await lockCubit.initialize();
  });

  tearDown(() async {
    await getIt<AppLockCubit>().close();
    await testDb.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<void> tapDigits(WidgetTester tester, String digits) async {
    for (var i = 0; i < digits.length; i++) {
      await tester.tap(find.text(digits[i]).last);
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Full PIN setup, Recovery Key confirmation, Lock Now, wrong PIN, and unlock work cleanly at 360dp',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(BusinessManagerApp(config: AppConfig.dev()));
      await tester.pumpAndSettle();

      // Navigate via More sheet -> Settings -> App Lock & Security
      await tester.tap(find.text('More').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('App Lock & Security'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('App Lock & Security'));
      await tester.pumpAndSettle();

      expect(find.text('App Lock Is Off'), findsOneWidget);
      await tester.tap(find.text('Enable App PIN'));
      await tester.pumpAndSettle();

      // Enter PIN 1234 -> Confirm mismatch 9999 -> Confirm 1234
      await tapDigits(tester, '1234');
      await tapDigits(tester, '9999');
      expect(find.text('PINs do not match. Please try again.'), findsOneWidget);
      await tapDigits(tester, '1234');

      // Recovery Key step displayed -> confirm checkbox -> activate
      expect(find.text('Save Your Offline Recovery Key'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Activate App Lock'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.text('I have written down this Recovery Key in a safe place.'),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Activate App Lock'));
      await tester.pumpAndSettle();

      expect(find.text('StitchFlow Is PIN Protected'), findsOneWidget);

      // Simulate user dismissing biometric prompt so we verify PIN-pad fallback
      bioService.nextOutcome = BiometricAuthOutcome.canceled;

      // Lock Now immediately displays Lock Screen and hides Settings
      await tester.tap(find.text('Lock Now'));
      await tester.pumpAndSettle();
      expect(find.text('StitchFlow Locked'), findsOneWidget);
      expect(find.text('StitchFlow Is PIN Protected'), findsNothing);

      // Wrong PIN keeps lock screen active
      await tapDigits(tester, '0000');
      expect(find.text('Incorrect PIN. Please try again.'), findsOneWidget);
      expect(find.text('StitchFlow Locked'), findsOneWidget);

      // Correct PIN unlocks cleanly back into app
      await tapDigits(tester, '1234');
      expect(find.text('StitchFlow Locked'), findsNothing);
      expect(find.text('StitchFlow Is PIN Protected'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Cold start with PIN enabled never renders Dashboard before unlock',
    (tester) async {
      await secRepo.setupPin(pin: '5678', recoveryKey: 'AB23-CD45');
      await getIt<AppLockCubit>().initialize();
      expect(getIt<AppLockCubit>().state.status, AppLockStatus.locked);

      await tester.pumpWidget(BusinessManagerApp(config: AppConfig.dev()));
      await tester.pumpAndSettle();

      expect(find.text('StitchFlow Locked'), findsOneWidget);
      expect(find.text('Issue stock to worker'), findsNothing);

      await tapDigits(tester, '5678');
      expect(find.text('StitchFlow Locked'), findsNothing);
      expect(find.text('Issue stock to worker'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
