import 'dart:io';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/cashbook/domain/entities/cashbook_entities.dart';
import 'package:business_manager/features/cashbook/domain/repositories/cashbook_repository.dart';
import 'package:business_manager/features/cashbook/presentation/pages/cashbook_page.dart';
import 'package:business_manager/features/cashbook/presentation/pages/cashbook_transfer_form_page.dart';
import 'package:business_manager/features/cashbook/presentation/pages/expense_form_page.dart';
import 'package:business_manager/features/reports/presentation/pages/reports_page.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempDir;
  late AppDatabase testDb;

  setUpAll(IstDateTimeHelper.initialize);

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('sf_cashbook_ui_');
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
    if (tempDir.existsSync()) await tempDir.delete(recursive: true);
  });

  Widget wrap(Widget child, {Locale locale = const Locale('en')}) {
    return MaterialApp(
      locale: locale,
      theme: AppTheme.light(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  testWidgets('renders CashbookPage with balances, pending bill & Gujarati locale', (
    tester,
  ) async {
    final now = IstDateTimeHelper.nowUtcMillis();
    final repo = getIt<CashbookRepository>();
    await repo.setOpeningBalances(
      openingCashPaise: 250000,
      openingBankPaise: 750000,
      transactionAtUtcMillis: now,
    );
    await repo.recordExpense(
      RecordExpenseInput(
        category: ExpenseCategory.electricity,
        title: 'Power Bill',
        amountPaise: 120000,
        paymentStatus: ExpensePaymentStatus.unpaid,
        transactionAtUtcMillis: now,
      ),
    );

    await tester.pumpWidget(wrap(const CashbookPage()));
    await tester.pumpAndSettle();

    expect(find.text('Cashbook & Expenses'), findsOneWidget);
    expect(find.text('Pending Bills (1)'), findsOneWidget);

    await tester.tap(find.text('Pending Bills (1)'));
    await tester.pumpAndSettle();
    expect(find.text('Power Bill'), findsOneWidget);
    expect(find.text('Mark Paid'), findsOneWidget);

    // Gujarati rendering smoke check
    await tester.pumpWidget(
      wrap(const CashbookPage(), locale: const Locale('gu')),
    );
    await tester.pumpAndSettle();
    expect(find.text('કેશબુક અને ખર્ચ'), findsOneWidget);
  });

  testWidgets('renders ExpenseFormPage, CashbookTransferFormPage, and Reports tab 8 cleanly', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(const ExpenseFormPage()));
    await tester.pumpAndSettle();
    expect(find.text('Record Workshop Expense'), findsOneWidget);

    await tester.pumpWidget(wrap(const CashbookTransferFormPage()));
    await tester.pumpAndSettle();
    expect(find.text('Cashbook Transfer / Capital'), findsOneWidget);

    await tester.pumpWidget(wrap(const ReportsPage(initialTab: 7)));
    await tester.pumpAndSettle();
    expect(find.text('True Workshop Net Profit'), findsOneWidget);
  });

  testWidgets(
    'supports date preset, search filtering, partial bill settlement, and expense detail sheet',
    (tester) async {
      final now = IstDateTimeHelper.nowUtcMillis();
      final repo = getIt<CashbookRepository>();
      await repo.recordExpense(
        RecordExpenseInput(
          category: ExpenseCategory.electricity,
          title: 'DGVCL Power Bill',
          payeeName: 'DGVCL',
          amountPaise: 120000,
          paymentStatus: ExpensePaymentStatus.unpaid,
          notes: 'November meter bill',
          transactionAtUtcMillis: now,
        ),
      );

      await tester.pumpWidget(wrap(const CashbookPage()));
      await tester.pumpAndSettle();

      // Switch to Today preset -> Period Cash & Bank strip appears
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(find.text('Period Cash'), findsOneWidget);
      expect(find.text('Period Bank / UPI'), findsOneWidget);

      // Open Pending Bills tab & partially settle ₹500 of ₹1,200
      await tester.tap(find.text('Pending Bills (1)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Mark Paid'));
      await tester.pumpAndSettle();

      final amountField = find.widgetWithText(
        TextFormField,
        'Settlement Amount (₹)',
      );
      await tester.enterText(amountField, '500');
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(Dialog),
          matching: find.text('Mark Paid'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Partially Paid'), findsOneWidget);
      expect(find.textContaining('Paid ₹500.00 of ₹1,200.00'), findsOneWidget);

      // Tap card to open Expense Detail sheet with settlement history
      await tester.tap(find.text('DGVCL Power Bill'));
      await tester.pumpAndSettle();
      expect(find.text('Expense Details'), findsOneWidget);
      expect(find.text('Settlement History'), findsOneWidget);
      expect(find.text('November meter bill'), findsOneWidget);

      // Close sheet and verify search filtering
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      final searchField = find.widgetWithText(
        TextFormField,
        'Search expenses, payee, ref, notes',
      );
      await tester.enterText(searchField, 'nonexistent');
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
      expect(find.text('No Pending Unpaid Bills'), findsOneWidget);
    },
  );
}
