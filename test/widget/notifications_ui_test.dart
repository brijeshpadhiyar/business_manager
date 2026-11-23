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
import 'package:business_manager/features/notifications/domain/entities/notification_entities.dart';
import 'package:business_manager/features/notifications/domain/services/local_notification_service.dart';
import 'package:business_manager/features/security/domain/entities/security_entities.dart';
import 'package:business_manager/features/security/domain/repositories/security_repository.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/security/app_lock_cubit_test.dart';

final class _FakeLocalNotificationService implements LocalNotificationService {
  NotificationPermissionStatus status =
      NotificationPermissionStatus.notRequested;
  int syncCount = 0;
  int testNotifCount = 0;

  @override
  Future<void> initialize({
    required void Function(String route) onDeepLinkTap,
  }) async {}

  @override
  Future<NotificationPermissionStatus> checkPermissionStatus() async => status;

  @override
  Future<NotificationPermissionStatus> requestPermission() async {
    status = NotificationPermissionStatus.granted;
    return status;
  }

  @override
  Future<void> syncPlan(NotificationSyncPlan plan) async {
    syncCount++;
  }

  @override
  Future<bool> showTestNotification({
    required String title,
    required String body,
  }) async {
    testNotifCount++;
    return true;
  }

  @override
  Future<void> cancelAll() async {}

  @override
  Future<String?> consumeLaunchRoute() async => null;
}

void main() {
  late Directory tempDir;
  late AppDatabase testDb;
  late _FakeLocalNotificationService fakeNotif;

  setUpAll(() {
    IstDateTimeHelper.initialize();
  });

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('sf_v1_2_notif_ui_');
    testDb = AppDatabase.forTesting(NativeDatabase.memory());
    fakeNotif = _FakeLocalNotificationService();

    final config = AppConfig.dev();
    await configureDependencies(config);

    await getIt.unregister<AppDatabase>();
    getIt.registerSingleton<AppDatabase>(testDb);
    await getIt.unregister<LocalNotificationService>();
    getIt.registerSingleton<LocalNotificationService>(fakeNotif);
    await getIt.unregister<MediaStorageService>();
    getIt.registerSingleton<MediaStorageService>(
      NativeMediaStorageService(
        config: config,
        idGenerator: getIt<IdGenerator>(),
        baseDirectoryOverride: tempDir,
      ),
    );
    final secRepo = InMemorySecurityRepository();
    final bioService = FakeBiometricService()
      ..nextOutcome = BiometricAuthOutcome.canceled;
    final winSecService = FakeWindowSecurityService();
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

  testWidgets(
    'Notification Settings renders at 360dp, requests permission contextually, and toggles reminders cleanly',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(BusinessManagerApp(config: AppConfig.dev()));
      await tester.pumpAndSettle();

      // Open Settings tab -> Notifications & Reminders
      await tester.tap(find.text('Settings').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Notifications & Reminders'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Notifications & Reminders'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Notifications & Reminders'));
      await tester.pumpAndSettle();

      expect(find.text('Permission Needed'), findsOneWidget);
      expect(find.text('Allow Notifications'), findsOneWidget);

      // Grant permission -> triggers sync & shows Test Notification button
      await tester.tap(find.text('Allow Notifications'));
      await tester.pumpAndSettle();
      expect(find.text('Allowed'), findsOneWidget);
      expect(find.text('Send Test Notification'), findsOneWidget);
      expect(fakeNotif.syncCount, greaterThanOrEqualTo(1));

      // Send Test Notification
      await tester.tap(find.text('Send Test Notification'));
      await tester.pumpAndSettle();
      expect(fakeNotif.testNotifCount, 1);

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Notification tap deep-link waits behind App Lock PIN and navigates only after unlock',
    (tester) async {
      final lockCubit = getIt<AppLockCubit>();
      await lockCubit.initialize();
      await lockCubit.enablePin(pin: '1234', recoveryKey: 'ABCD-2345');
      await lockCubit.lockNow();
      expect(lockCubit.state.status, AppLockStatus.locked);

      // Simulate notification tap while locked
      lockCubit.queueDeepLinkRoute(RoutePaths.dailySummary);
      expect(lockCubit.state.pendingDeepLinkRoute, RoutePaths.dailySummary);
      expect(lockCubit.state.status, AppLockStatus.locked);

      await tester.pumpWidget(BusinessManagerApp(config: AppConfig.dev()));
      await tester.pumpAndSettle();

      // Lock screen MUST be visible; Daily Production Summary MUST NOT be visible yet
      expect(find.text('StitchFlow Locked'), findsOneWidget);
      expect(find.text('Daily Production Summary'), findsNothing);

      // Unlock with PIN 1-2-3-4
      for (final d in ['1', '2', '3', '4']) {
        await tester.tap(find.text(d).first);
        await tester.pump(const Duration(milliseconds: 50));
      }
      await tester.pumpAndSettle();

      // After unlock, queued notification deep-link navigates directly to Daily Summary!
      expect(find.text('Daily Production Summary'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
