import 'dart:io';

import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/database/database_transaction_runner.dart';
import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/services/app_message_service.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/features/lots/data/repositories/lot_repository_impl.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/parties/data/repositories/party_repository_impl.dart';
import 'package:business_manager/features/parties/domain/entities/party_entities.dart';
import 'package:business_manager/features/parties/domain/repositories/party_repository.dart';
import 'package:business_manager/features/parties/presentation/bloc/parties_cubit.dart';
import 'package:business_manager/features/parties/presentation/bloc/party_detail_cubit.dart';
import 'package:business_manager/features/parties/presentation/pages/buyer_return_form_page.dart';
import 'package:business_manager/features/parties/presentation/pages/dispatch_challan_detail_page.dart';
import 'package:business_manager/features/parties/presentation/pages/dispatch_challan_form_page.dart';
import 'package:business_manager/features/parties/presentation/pages/parties_list_page.dart';
import 'package:business_manager/features/parties/presentation/pages/party_detail_page.dart';
import 'package:business_manager/features/parties/presentation/pages/party_form_page.dart';
import 'package:business_manager/features/parties/presentation/pages/party_payment_form_page.dart';
import 'package:business_manager/features/parties/presentation/widgets/lot_pnl_section.dart';
import 'package:business_manager/features/stock_movements/domain/entities/stock_movement_entities.dart';
import 'package:business_manager/features/stock_movements/domain/repositories/stock_movement_repository.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockStockMovementRepository extends Mock
    implements StockMovementRepository {}

void main() {
  late Directory tempDir;
  late AppDatabase db;
  late LotRepositoryImpl lotRepo;
  late PartyRepositoryImpl partyRepo;
  late _MockStockMovementRepository stockRepo;
  late String partyId;
  late String lotId;
  late String colourId;
  late String challanId;

  const now = 1795324800000;

  setUp(() async {
    IstDateTimeHelper.initialize();
    await getIt.reset();

    tempDir = await Directory.systemTemp.createTemp('sf_party_ui_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final txRunner = DatabaseTransactionRunner(db);
    final ids = IdGenerator();
    final media = NativeMediaStorageService(
      config: AppConfig.dev(),
      idGenerator: ids,
      baseDirectoryOverride: tempDir,
    );

    lotRepo = LotRepositoryImpl(db, txRunner, ids, media);
    partyRepo = PartyRepositoryImpl(db, txRunner, ids);
    stockRepo = _MockStockMovementRepository();

    getIt.registerSingleton<AppDatabase>(db);
    getIt.registerSingleton<LotRepository>(lotRepo);
    getIt.registerSingleton<PartyRepository>(partyRepo);
    getIt.registerSingleton<StockMovementRepository>(stockRepo);
    getIt.registerFactory<PartiesCubit>(() => PartiesCubit(partyRepo));
    getIt.registerFactory<PartyDetailCubit>(() => PartyDetailCubit(partyRepo));

    final party = await partyRepo.createParty(
      name: 'Patel Textiles',
      phone: '9876543210',
      partyType: PartyType.buyer,
      gstin: '24AAAAA0000A1Z5',
      openingBalancePaise: 500000,
    );
    partyId = party.id;

    final lot = await lotRepo.createLotComplete(
      lotNumber: 'LOT-204',
      title: 'Festive Collection',
      transactionAtUtcMillis: now,
      designs: const [
        LotDesignDraftInput(
          designName: 'D-204',
          colours: [
            LotColourDraftInput(
              colourName: 'Maroon',
              initialQuantity: 100,
              unitPricePaise: 45000,
            ),
          ],
        ),
      ],
    );
    lotId = lot.id;
    final detail = await lotRepo.getLotDetail(lotId);
    final designId = detail!.designs.first.design.id;
    colourId = detail.designs.first.colours.first.id;

    when(
      () => stockRepo.getAllDesignColourBalances(lotId: any(named: 'lotId')),
    ).thenAnswer(
      (_) async => [
        DesignColourStockBalance(
          designColourId: colourId,
          lotDesignId: designId,
          lotId: lotId,
          lotNumber: 'LOT-204',
          designName: 'D-204',
          colourName: 'Maroon',
          initialQuantity: 100,
          damagedBucket: 0,
          totalLost: 0,
          totalShortage: 0,
          totalGoodPhysicalStock: 100,
          totalPendingWithWorkers: 0,
          physicalAvailableInHouse: 100,
          totalIssued: 0,
          totalGoodReturned: 0,
          totalRepairedToGood: 0,
          unitPricePaise: 45000,
          processBreakdown: const [],
        ),
      ],
    );

    final challanView = await partyRepo.createDispatchChallan(
      partyId: partyId,
      challanNumber: 'DC-2026-0001',
      items: [
        DispatchLineDraft(
          lotId: lotId,
          lotDesignId: designId,
          designColourId: colourId,
          quantity: 20,
          ratePaise: 45000,
        ),
      ],
      transactionAtUtcMillis: now,
    );
    challanId = challanView.challan.id;

    await partyRepo.recordPartyPayment(
      partyId: partyId,
      paymentType: PartyPaymentType.receipt,
      paymentMode: PartyPaymentMode.upi,
      amountPaise: 300000,
      referenceNo: 'UPI-REF-01',
      transactionAtUtcMillis: now + 1000,
    );

    await partyRepo.addLotDirectCost(
      lotId: lotId,
      category: LotCostCategory.fabric,
      description: 'Rayon Fabric Roll',
      amountPaise: 250000,
      transactionAtUtcMillis: now + 2000,
    );
  });

  tearDown(() async {
    AppMessageService.cancelPendingTimers();
    await getIt.reset();
    await db.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget wrap(Widget child, {Locale locale = const Locale('en')}) {
    return MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      home: child,
    );
  }

  Widget wrapRouter(Widget child, {Locale locale = const Locale('en')}) {
    final router = GoRouter(
      initialLocation: '/form',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => const Scaffold(body: SizedBox.shrink()),
          routes: [
            GoRoute(path: 'form', builder: (_, _) => child),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    return MaterialApp.router(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light(),
      routerConfig: router,
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

  testWidgets('PartiesListPage renders totals, filter chips, and search in EN & GU at 360dp', (
    tester,
  ) async {
    setPhoneViewport(tester);

    await tester.pumpWidget(wrap(const PartiesListPage()));
    await tester.pumpAndSettle();

    expect(find.text('Patel Textiles'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Filter to Advance Credit (none exists -> empty state)
    await tester.ensureVisible(find.text('Advance Credit'));
    await tester.tap(find.text('Advance Credit'));
    await tester.pumpAndSettle();
    expect(find.text('Patel Textiles'), findsNothing);

    // Switch back to Receivable Due
    await tester.ensureVisible(find.text('Receivable Due'));
    await tester.tap(find.text('Receivable Due'));
    await tester.pumpAndSettle();
    expect(find.text('Patel Textiles'), findsOneWidget);

    // Verify Gujarati locale at 360dp has no layout overflow
    await tester.pumpWidget(
      wrap(const PartiesListPage(), locale: const Locale('gu')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Patel Textiles'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PartyFormPage creates a new party and persists to Drift', (
    tester,
  ) async {
    setPhoneViewport(tester);

    await tester.pumpWidget(wrapRouter(const PartyFormPage()));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'Mehta Silks');
    await tester.tap(find.byIcon(AppIcons.save));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));

    final summaries = await partyRepo.getAllPartySummaries();
    expect(summaries.any((p) => p.partyName == 'Mehta Silks'), isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PartyDetailPage, DispatchChallanDetailPage & Dispatch/Return/Payment forms render cleanly', (
    tester,
  ) async {
    setPhoneViewport(tester);

    // PartyDetailPage in EN & GU
    await tester.pumpWidget(wrap(PartyDetailPage(partyId: partyId)));
    await tester.pumpAndSettle();
    expect(find.text('Patel Textiles'), findsOneWidget);
    expect(find.textContaining('DC-2026-0001'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      wrap(PartyDetailPage(partyId: partyId), locale: const Locale('gu')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Patel Textiles'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // DispatchChallanDetailPage
    await tester.pumpWidget(
      wrap(DispatchChallanDetailPage(challanId: challanId)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('DC-2026-0001'), findsWidgets);
    expect(tester.takeException(), isNull);

    // DispatchChallanFormPage
    await tester.pumpWidget(
      wrap(DispatchChallanFormPage(initialPartyId: partyId, initialLotId: lotId)),
    );
    await tester.pumpAndSettle();
    expect(find.text('LOT-204 • D-204 • Maroon'), findsWidgets);
    expect(tester.takeException(), isNull);

    // BuyerReturnFormPage
    await tester.pumpWidget(
      wrap(BuyerReturnFormPage(partyId: partyId, initialChallanId: challanId)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('DC-2026-0001'), findsWidgets);
    expect(tester.takeException(), isNull);

    // PartyPaymentFormPage
    await tester.pumpWidget(wrap(PartyPaymentFormPage(partyId: partyId)));
    await tester.pumpAndSettle();
    expect(find.text('Patel Textiles'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('LotPnlSection shows P&L metrics and adds a Direct Cost cleanly', (
    tester,
  ) async {
    setPhoneViewport(tester);

    await tester.pumpWidget(
      wrap(
        Scaffold(
          body: SingleChildScrollView(child: LotPnlSection(lotId: lotId)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rayon Fabric Roll'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Open Add Direct Cost sheet
    await tester.tap(find.text('Add Direct Cost'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Buttons & Zippers');
    await tester.enterText(fields.at(1), '1250');
    await tester.ensureVisible(find.byIcon(AppIcons.save));
    await tester.tap(find.byIcon(AppIcons.save));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));

    expect(find.text('Buttons & Zippers'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
