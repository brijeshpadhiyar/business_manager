import 'dart:async';
import 'dart:convert';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_logger.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/services/app_message_service.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/auth/domain/entities/auth_entities.dart';
import 'package:business_manager/features/auth/domain/repositories/auth_repository.dart';
import 'package:business_manager/features/auth/domain/services/rbac_policy.dart';
import 'package:business_manager/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:business_manager/features/sync/data/services/sync_conflict_service.dart';
import 'package:business_manager/features/sync/domain/entities/sync_entities.dart';
import 'package:business_manager/features/sync/domain/repositories/cloud_sync_gateway.dart';
import 'package:business_manager/features/sync/domain/repositories/sync_repository.dart';
import 'package:business_manager/features/sync/presentation/bloc/sync_cubit.dart';
import 'package:business_manager/features/sync/presentation/pages/sync_conflict_inspector_page.dart';
import 'package:business_manager/features/team/domain/entities/team_entities.dart';
import 'package:business_manager/features/team/domain/repositories/team_repository.dart';
import 'package:business_manager/features/team/presentation/pages/team_management_page.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockGateway extends Mock implements CloudSyncGateway {}

class _MockTeamRepository extends Mock implements TeamRepository {}

final class _FakeSyncRepository implements SyncRepository {
  _FakeSyncRepository(this._conflictService);

  final SyncConflictService _conflictService;

  @override
  bool get isCloudConfigured => true;

  @override
  bool get isSyncRunning => false;

  @override
  Future<SyncSessionSummary> getSessionState() async =>
      const SyncSessionSummary(deviceId: 'dev-1', lastFullSyncAt: 1795324800000);

  @override
  Future<void> updateSessionBinding({
    required String? userId,
    required String? businessId,
  }) async {}

  @override
  Stream<int> watchPendingOutboxCount() => Stream.value(0);

  @override
  Stream<int> watchPendingMediaCount() => Stream.value(0);

  @override
  Future<int> getPendingOutboxCount() async => 0;

  @override
  Future<List<SyncFailedItem>> getFailedOutboxItems() async => const [];

  @override
  Future<int> getUnresolvedConflictCount() async =>
      (await _conflictService.loadConflicts())
          .where((c) => c.isUnresolved)
          .length;

  @override
  Future<void> resetFailedItems() async {}

  @override
  Future<FirstLoginMergeSummary> inspectFirstLoginMerge(AuthUser user) async =>
      const FirstLoginMergeSummary(localRowCount: 0, cloudRowCount: 0);

  @override
  Future<SyncRunSummary> executeFirstLoginMerge(
    AuthUser user,
    FirstLoginMergeChoice choice,
  ) async => const SyncRunSummary();

  @override
  Future<SyncRunSummary> runSyncCycle(AuthUser user) async =>
      const SyncRunSummary();
}

void main() {
  late AppDatabase db;
  late _MockAuthRepository authRepo;
  late _MockGateway gateway;
  late _MockTeamRepository teamRepo;
  late SyncConflictService conflictService;
  late StreamController<AuthUser?> authStream;
  late AuthCubit authCubit;
  late SyncCubit syncCubit;

  setUpAll(() {
    registerFallbackValue(BusinessRole.qcInspector);
  });

  setUp(() async {
    IstDateTimeHelper.initialize();
    await getIt.reset();

    db = AppDatabase.forTesting(NativeDatabase.memory());
    authRepo = _MockAuthRepository();
    gateway = _MockGateway();
    teamRepo = _MockTeamRepository();
    conflictService = SyncConflictService(db, IdGenerator());
    authStream = StreamController<AuthUser?>.broadcast();

    const ownerUser = AuthUser(
      id: 'user-owner',
      businessId: 'biz-1',
      role: BusinessRole.owner,
      displayName: 'Owner Bhai',
      email: 'owner@stitchflow.test',
    );

    when(() => authRepo.isCloudConfigured).thenReturn(true);
    when(() => authRepo.watchAuthUser()).thenAnswer((_) => authStream.stream);
    when(() => authRepo.restoreCachedUser()).thenAnswer((_) async => ownerUser);
    when(
      () => authRepo.fetchLinkedDevices(
        currentDeviceId: any(named: 'currentDeviceId'),
      ),
    ).thenAnswer((_) async => const []);
    when(() => gateway.isConfigured).thenReturn(true);
    when(
      () => gateway.subscribeToSyncNotifications(
        businessId: any(named: 'businessId'),
        currentDeviceId: any(named: 'currentDeviceId'),
        onRemoteChange: any(named: 'onRemoteChange'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => gateway.unsubscribeFromSyncNotifications(),
    ).thenAnswer((_) async {});
    when(() => teamRepo.isCloudConfigured).thenReturn(true);

    getIt.registerSingleton<TeamRepository>(teamRepo);
    getIt.registerSingleton<SyncConflictService>(conflictService);

    final syncRepo = _FakeSyncRepository(conflictService);
    authCubit = AuthCubit(authRepo, syncRepo);
    await authCubit.initialize();

    syncCubit = SyncCubit(
      syncRepo,
      gateway,
      authCubit,
      AppLogger(AppConfig.dev()),
    );
    await syncCubit.initialize();
  });

  tearDown(() async {
    AppMessageService.cancelPendingTimers();
    await getIt.reset();
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
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: child,
      ),
    );
  }

  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('TeamManagementPage allows Owner to change active member role and hides edit for QC Inspector', (
    tester,
  ) async {
    setPhoneViewport(tester);

    var memberRole = BusinessRole.qcInspector;
    when(() => teamRepo.loadMembers(any())).thenAnswer(
      (_) async => [
        const TeamMemberInfo(
          userId: 'user-owner',
          businessId: 'biz-1',
          role: BusinessRole.owner,
          status: 'ACTIVE',
          displayName: 'Owner Bhai',
          updatedAtUtcMillis: 1795324800000,
        ),
        TeamMemberInfo(
          userId: 'user-staff',
          businessId: 'biz-1',
          role: memberRole,
          status: 'ACTIVE',
          displayName: 'Ramesh Staff',
          updatedAtUtcMillis: 1795324800000,
        ),
      ],
    );
    when(() => teamRepo.loadInvites(any())).thenAnswer((_) async => const []);
    when(
      () => teamRepo.updateMemberRole(
        businessId: 'biz-1',
        userId: 'user-staff',
        role: BusinessRole.manager,
      ),
    ).thenAnswer((_) async {
      memberRole = BusinessRole.manager;
    });

    await tester.pumpWidget(wrap(const TeamManagementPage()));
    await tester.pumpAndSettle();

    expect(find.text('Ramesh Staff'), findsOneWidget);
    expect(find.byIcon(AppIcons.edit), findsOneWidget);

    await tester.tap(find.byIcon(AppIcons.edit));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<BusinessRole>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Manager / Supervisor').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(AppIcons.confirm));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));

    verify(
      () => teamRepo.updateMemberRole(
        businessId: 'biz-1',
        userId: 'user-staff',
        role: BusinessRole.manager,
      ),
    ).called(1);

    // Demote current signed-in user in stream to QC Inspector -> edit & invite disappear
    authStream.add(
      const AuthUser(
        id: 'user-staff',
        businessId: 'biz-1',
        role: BusinessRole.qcInspector,
        displayName: 'Ramesh Staff',
      ),
    );
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(authCubit.state.user?.role, BusinessRole.qcInspector);
    expect(find.byIcon(AppIcons.edit), findsNothing);
    expect(find.byIcon(AppIcons.invite), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SyncConflictInspectorPage displays field diffs and supports Acknowledge & Restore in EN & GU', (
    tester,
  ) async {
    setPhoneViewport(tester);
    const now = 1795324800000;

    // Seed an active lot row and unresolved LWW conflicts in SQLite
    await db.lotDao.insertLot(
      LotsCompanion.insert(
        id: 'l-101',
        lotNumber: 'LOT-101',
        title: const Value('Cloud Lot Title'),
        transactionAt: now,
        recordedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await db.attachmentAuditDao.insertAuditLog(
      AuditLogsCompanion.insert(
        id: 'audit-conf-1',
        entityType: 'lots',
        entityId: 'l-101',
        actionType: 'UPDATE',
        previousValueJson: Value(
          jsonEncode({
            'id': 'l-101',
            'lot_number': 'LOT-101',
            'title': 'Local Lot Title',
          }),
        ),
        newValueJson: Value(
          jsonEncode({
            'id': 'l-101',
            'lot_number': 'LOT-101',
            'title': 'Cloud Lot Title',
          }),
        ),
        reason: const Value('sync_conflict_lww'),
        transactionAt: now,
        recordedAt: now,
      ),
    );

    await tester.pumpWidget(wrap(const SyncConflictInspectorPage()));
    await tester.pumpAndSettle();

    expect(find.textContaining('lots • l-101'), findsOneWidget);
    expect(find.textContaining('Local Lot Title'), findsOneWidget);
    expect(find.textContaining('Cloud Lot Title'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Keep Cloud'));
    await tester.pumpAndSettle();

    final afterAck = await conflictService.loadConflicts();
    expect(afterAck.single.status, SyncConflictStatus.acknowledged);

    // Seed a second unresolved conflict and test Gujarati rendering + Restore Local
    await db.attachmentAuditDao.insertAuditLog(
      AuditLogsCompanion.insert(
        id: 'audit-conf-2',
        entityType: 'lots',
        entityId: 'l-101',
        actionType: 'UPDATE',
        previousValueJson: Value(
          jsonEncode({
            'id': 'l-101',
            'lot_number': 'LOT-101',
            'title': 'Restored Local Title',
          }),
        ),
        newValueJson: Value(
          jsonEncode({
            'id': 'l-101',
            'lot_number': 'LOT-101',
            'title': 'Cloud Lot Title',
          }),
        ),
        reason: const Value('sync_conflict_lww'),
        transactionAt: now + 1000,
        recordedAt: now + 1000,
      ),
    );

    await tester.pumpWidget(
      wrap(
        const SyncConflictInspectorPage(key: ValueKey('gu')),
        locale: const Locale('gu'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Restored Local Title'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byIcon(AppIcons.restore).first);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));

    final restoredLot = await db.lotDao.findLotById('l-101');
    expect(restoredLot?.title, 'Restored Local Title');
    expect(tester.takeException(), isNull);
  });
}
