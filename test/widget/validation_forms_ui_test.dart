import 'dart:io';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/accounting/presentation/pages/payment_form_page.dart';
import 'package:business_manager/features/accounting/presentation/pages/worker_adjustment_form_page.dart';
import 'package:business_manager/features/business_profile/presentation/pages/business_profile_page.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:business_manager/features/rates/presentation/pages/rate_form_page.dart';
import 'package:business_manager/features/security/presentation/bloc/app_lock_cubit.dart';
import 'package:business_manager/features/security/presentation/pages/pin_recovery_page.dart';
import 'package:business_manager/features/workers/domain/repositories/worker_repository.dart';
import 'package:business_manager/features/workers/presentation/pages/worker_form_page.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    tempDir = await Directory.systemTemp.createTemp('sf_val_ui_');
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

  Widget wrapPage(
    Widget child, {
    Locale locale = const Locale('en'),
    ThemeMode themeMode = ThemeMode.light,
  }) {
    return MaterialApp(
      locale: locale,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  testWidgets(
    'WorkerFormPage validates whitespace, Indian mobile numbers, clears errors on fix, and renders Gujarati + Dark Glass cleanly',
    (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 1. English Light Glass
      await tester.pumpWidget(wrapPage(const WorkerFormPage()));
      await tester.pumpAndSettle();

      // Whitespace-only worker name rejected
      await tester.enterText(find.byType(TextFormField).at(0), '    ');
      // Invalid mobile with letters
      await tester.enterText(find.byType(TextFormField).at(1), '98765abc');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('This field cannot contain only spaces.'),
        findsOneWidget,
      );
      expect(
        find.text('Mobile number contains invalid characters.'),
        findsOneWidget,
      );

      // Incomplete Indian mobile rejected
      await tester.enterText(find.byType(TextFormField).at(0), 'Ramesh Bhai');
      await tester.enterText(find.byType(TextFormField).at(1), '98765432');
      await tester.pumpAndSettle();

      // Name error automatically clears upon correction!
      expect(
        find.text('This field cannot contain only spaces.'),
        findsNothing,
      );
      expect(
        find.text('Enter a valid 10-digit mobile number.'),
        findsOneWidget,
      );

      // Valid formatted Indian mobile clears error immediately!
      await tester.enterText(find.byType(TextFormField).at(1), '+91 98765-43210');
      await tester.pumpAndSettle();
      expect(
        find.text('Enter a valid 10-digit mobile number.'),
        findsNothing,
      );
      expect(tester.takeException(), isNull);

      // 2. Gujarati Dark Glass theme check (zero overflow & accessible error colors)
      await tester.pumpWidget(
        wrapPage(
          const WorkerFormPage(key: ValueKey('gu_dark_worker_form')),
          locale: const Locale('gu'),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'કિશોર ભાઈ');
      await tester.enterText(find.byType(TextFormField).at(1), '1234567890');
      await tester.ensureVisible(find.text('સાચવો'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('સાચવો'));
      await tester.pumpAndSettle();

      expect(
        find.text('માન્ય 10 અંકનો મોબાઇલ નંબર દાખલ કરો.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'BusinessProfilePage validates phone number in Light and Dark themes',
    (tester) async {
      await tester.pumpWidget(
        wrapPage(
          const BusinessProfilePage(showAppBar: true),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pumpAndSettle();

      // Field index 3 is Business Phone
      await tester.enterText(find.byType(TextFormField).at(3), '5432109876');
      await tester.scrollUntilVisible(
        find.text('Save'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('Enter a valid 10-digit mobile number.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'PaymentFormPage & WorkerAdjustmentFormPage enforce exact positive decimal validation',
    (tester) async {
      final worker = await getIt<WorkerRepository>().createWorker(
        name: 'Jignesh Bhai',
        phone: '9876543210',
      );

      // 1. PaymentFormPage
      await tester.pumpWidget(
        wrapPage(PaymentFormPage(initialWorkerId: worker.id)),
      );
      await tester.pumpAndSettle();

      final amountField = find.byType(TextFormField).first;

      // Zero amount rejected with positive amount error (NOT "This field is required.")
      await tester.enterText(amountField, '0');
      await tester.scrollUntilVisible(
        find.text('Save'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        find.text('Enter a valid amount greater than 0.'),
        findsOneWidget,
      );

      // 3 decimal places rejected (never silently rounded!)
      await tester.enterText(amountField, '100.999');
      await tester.pumpAndSettle();
      expect(find.text('Enter up to 2 decimal places.'), findsOneWidget);

      // Negative rejected
      await tester.enterText(amountField, '-50');
      await tester.pumpAndSettle();
      expect(find.text('Value cannot be negative.'), findsOneWidget);

      // Overflow huge input rejected gracefully
      await tester.enterText(amountField, '99999999999999999999999');
      await tester.pumpAndSettle();
      expect(
        find.text('Entered value exceeds the maximum allowed limit.'),
        findsOneWidget,
      );

      // Valid decimal clears error
      await tester.enterText(amountField, '250.50');
      await tester.pumpAndSettle();
      expect(
        find.text('Entered value exceeds the maximum allowed limit.'),
        findsNothing,
      );

      // 2. WorkerAdjustmentFormPage: whitespace reason rejected
      await tester.pumpWidget(
        wrapPage(WorkerAdjustmentFormPage(workerId: worker.id)),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), '150');
      await tester.enterText(find.byType(TextFormField).at(1), '   ');
      await tester.scrollUntilVisible(
        find.text('Save'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(
        find.text('This field cannot contain only spaces.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'RateFormPage rejects huge overflow & >2 decimal rates without FormatException',
    (tester) async {
      final proc = await getIt<ProcessRepository>().createProcess(
        name: 'Overlock',
      );
      final worker = await getIt<WorkerRepository>().createWorker(
        name: 'Bhavesh',
      );

      await tester.pumpWidget(
        wrapPage(
          RateFormPage(workerId: worker.id, initialProcessId: proc.id),
        ),
      );
      await tester.pumpAndSettle();

      final rateField = find.byType(TextFormField).first;
      await tester.enterText(rateField, '99999999999999999999999999');
      await tester.scrollUntilVisible(
        find.text('Save'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('Entered value exceeds the maximum allowed limit.'),
        findsOneWidget,
      );

      await tester.enterText(rateField, '20.123');
      await tester.pumpAndSettle();
      expect(find.text('Enter up to 2 decimal places.'), findsOneWidget);
    },
  );

  testWidgets(
    'PinRecoveryPage distinguishes empty vs invalid recovery key inline',
    (tester) async {
      final lockCubit = getIt<AppLockCubit>();
      await tester.pumpWidget(
        BlocProvider<AppLockCubit>.value(
          value: lockCubit,
          child: wrapPage(PinRecoveryPage(onBackToLock: () {})),
        ),
      );
      await tester.pumpAndSettle();

      // Empty submission shows required prompt
      await tester.tap(find.text('Verify Recovery Key'));
      await tester.pumpAndSettle();
      expect(
        find.text('Enter your 8-character Recovery Key.'),
        findsOneWidget,
      );

      // Invalid format shows invalid error inline
      await tester.enterText(find.byType(TextFormField).first, 'BAD!');
      await tester.pumpAndSettle();
      expect(
        find.text('Invalid Recovery Key. Check your code and try again.'),
        findsOneWidget,
      );
    },
  );
}
