import 'dart:async';

import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/auth/domain/entities/auth_entities.dart';
import 'package:business_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:business_manager/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:business_manager/features/sync/data/repositories/sync_repository_impl.dart';
import 'package:business_manager/features/sync/data/services/sync_engine.dart';
import 'package:business_manager/features/sync/domain/repositories/cloud_sync_gateway.dart';
import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_logger.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockGateway extends Mock implements CloudSyncGateway {}

class _MockMediaStorage extends Mock implements MediaStorageService {}

void main() {
  late AppDatabase db;
  late _MockAuthRepository authRepo;
  late SyncRepositoryImpl syncRepo;
  late StreamController<AuthUser?> authStream;
  late AuthCubit cubit;

  const googleUser = AuthUser(
    id: 'uid-google-1',
    businessId: 'biz_uidgoogle1',
    displayName: 'Brijesh',
    email: 'brijesh@example.com',
  );

  const phoneUser = AuthUser(
    id: 'uid-phone-1',
    businessId: 'biz_uidphone1',
    phone: '+919876543210',
  );

  setUp(() {
    IstDateTimeHelper.initialize();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    authRepo = _MockAuthRepository();
    authStream = StreamController<AuthUser?>.broadcast();

    when(() => authRepo.isCloudConfigured).thenReturn(true);
    when(() => authRepo.watchAuthUser()).thenAnswer((_) => authStream.stream);
    when(() => authRepo.restoreCachedUser()).thenAnswer((_) async => null);

    final gateway = _MockGateway();
    when(() => gateway.isConfigured).thenReturn(true);
    final engine = SyncEngine(
      db,
      gateway,
      _MockMediaStorage(),
      authRepo,
      IdGenerator(),
      AppLogger(AppConfig.dev()),
    );
    syncRepo = SyncRepositoryImpl(db, engine);
    cubit = AuthCubit(authRepo, syncRepo);
  });

  tearDown(() async {
    await cubit.close();
    await authStream.close();
    await db.close();
  });

  test('normalizeIndianPhone normalizes 10-digit & E.164 numbers accurately',
      () {
    expect(AuthCubit.normalizeIndianPhone('9876543210'), '+919876543210');
    expect(AuthCubit.normalizeIndianPhone('98765 43210'), '+919876543210');
    expect(AuthCubit.normalizeIndianPhone('+91 98765-43210'), '+919876543210');
    expect(AuthCubit.normalizeIndianPhone('12345'), isNull);
  });

  test('initialize falls back to offlineGuest when no cached user exists',
      () async {
    await cubit.initialize();
    expect(cubit.state.status, AuthStatus.offlineGuest);
    expect(cubit.state.isAuthenticated, isFalse);
  });

  test('signInWithGoogle authenticates and binds local sync session', () async {
    when(() => authRepo.signInWithGoogle()).thenAnswer((_) async => googleUser);
    await cubit.initialize();

    final ok = await cubit.signInWithGoogle();
    expect(ok, isTrue);
    expect(cubit.state.isAuthenticated, isTrue);
    expect(cubit.state.user?.email, 'brijesh@example.com');

    final session = await db.syncDao.getSessionState();
    expect(session.boundUserId, googleUser.id);
    expect(session.boundBusinessId, googleUser.businessId);
  });

  test('Phone OTP send + verify authenticates and signOut clears binding',
      () async {
    when(() => authRepo.sendPhoneOtp('+919876543210')).thenAnswer((_) async {});
    when(
      () => authRepo.verifyPhoneOtp(
        e164Phone: '+919876543210',
        token: '123456',
      ),
    ).thenAnswer((_) async => phoneUser);
    when(() => authRepo.signOut()).thenAnswer((_) async {});

    await cubit.initialize();
    expect(await cubit.sendPhoneOtp('9876543210'), isTrue);
    expect(cubit.state.pendingOtpPhone, '+919876543210');

    expect(await cubit.verifyPhoneOtp('123456'), isTrue);
    expect(cubit.state.isAuthenticated, isTrue);
    expect(cubit.state.user?.phone, '+919876543210');

    await cubit.signOut();
    expect(cubit.state.status, AuthStatus.offlineGuest);
    expect(cubit.state.user, isNull);
  });
}
