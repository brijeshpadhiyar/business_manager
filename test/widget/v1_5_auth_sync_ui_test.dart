import 'dart:async';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_logger.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/auth/domain/entities/auth_entities.dart';
import 'package:business_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:business_manager/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:business_manager/features/auth/presentation/pages/account_settings_page.dart';
import 'package:business_manager/features/auth/presentation/pages/login_page.dart';
import 'package:business_manager/features/sync/data/services/sync_engine.dart';
import 'package:business_manager/features/sync/domain/entities/sync_entities.dart';
import 'package:business_manager/features/sync/domain/repositories/cloud_sync_gateway.dart';
import 'package:business_manager/features/sync/presentation/bloc/sync_cubit.dart';
import 'package:business_manager/features/sync/presentation/pages/sync_center_page.dart';
import 'package:business_manager/features/sync/presentation/widgets/first_login_merge_dialog.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockGateway extends Mock implements CloudSyncGateway {}

class _MockMediaStorage extends Mock implements MediaStorageService {}

void main() {
  late AppDatabase db;
  late _MockAuthRepository authRepo;
  late _MockGateway gateway;
  late _MockMediaStorage mediaStorage;
  late StreamController<AuthUser?> authStream;
  late AuthCubit authCubit;
  late SyncCubit syncCubit;

  setUp(() async {
    IstDateTimeHelper.initialize();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    authRepo = _MockAuthRepository();
    gateway = _MockGateway();
    mediaStorage = _MockMediaStorage();
    authStream = StreamController<AuthUser?>.broadcast();

    when(() => authRepo.isCloudConfigured).thenReturn(true);
    when(() => authRepo.watchAuthUser()).thenAnswer((_) => authStream.stream);
    when(() => authRepo.restoreCachedUser()).thenAnswer((_) async => null);
    when(
      () => authRepo.fetchLinkedDevices(
        currentDeviceId: any(named: 'currentDeviceId'),
      ),
    ).thenAnswer((_) async => const []);
    when(() => gateway.isConfigured).thenReturn(true);
    when(
      () => gateway.unsubscribeFromSyncNotifications(),
    ).thenAnswer((_) async {});

    authCubit = AuthCubit(authRepo, db);
    await authCubit.initialize();

    final engine = SyncEngine(
      db,
      gateway,
      mediaStorage,
      authRepo,
      IdGenerator(),
      AppLogger(AppConfig.dev()),
    );
    syncCubit = SyncCubit(
      db,
      engine,
      gateway,
      authCubit,
      AppLogger(AppConfig.dev()),
    );
    await syncCubit.initialize();
  });

  tearDown(() async {
    await syncCubit.close();
    await authCubit.close();
    await authStream.close();
    await db.close();
  });

  Widget wrap(Widget child, {Locale locale = const Locale('en')}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<SyncCubit>.value(value: syncCubit),
      ],
      child: MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        theme: AppTheme.light(),
        home: child,
      ),
    );
  }

  testWidgets('LoginPage renders Google, Phone OTP & Continue Offline in EN/GU',
      (tester) async {
    await tester.pumpWidget(wrap(const LoginPage()));
    await tester.pumpAndSettle();

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Phone Number'), findsOneWidget);
    expect(find.text('Continue Offline (Local Only)'), findsOneWidget);

    await tester.pumpWidget(
      wrap(const LoginPage(), locale: const Locale('gu')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Google સાથે ચાલુ રાખો'), findsOneWidget);
    expect(find.text('મોબાઇલ નંબરથી ચાલુ રાખો'), findsOneWidget);
  });

  testWidgets('AccountSettingsPage & SyncCenterPage render cleanly at 360dp',
      (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap(const AccountSettingsPage()));
    await tester.pumpAndSettle();
    expect(find.text('Offline Mode'), findsOneWidget);

    await tester.pumpWidget(wrap(const SyncCenterPage()));
    await tester.pumpAndSettle();
    expect(find.text('Cloud Sync Center'), findsWidgets);
  });

  testWidgets('FirstLoginMergeDialog displays all 3 merge choices cleanly',
      (tester) async {
    await tester.pumpWidget(
      wrap(
        const FirstLoginMergeDialog(
          summary: FirstLoginMergeSummary(localRowCount: 5, cloudRowCount: 12),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Merge Local + Cloud (Recommended)'), findsOneWidget);
    expect(find.text('Keep Cloud Only'), findsOneWidget);
    expect(find.text('Keep Local & Push to Cloud'), findsOneWidget);
  });
}
