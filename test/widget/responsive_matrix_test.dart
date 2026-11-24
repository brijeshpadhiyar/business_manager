import 'dart:io';

import 'package:business_manager/app.dart';
import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/database/app_database.dart';
import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/platform/media_storage_service.dart';
import 'package:business_manager/core/platform/media_storage_service_native.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/lots/presentation/pages/designs_colours_page.dart';
import 'package:business_manager/features/production_history/presentation/pages/inspection_queue_page.dart';
import 'package:business_manager/features/production_history/presentation/pages/process_history_page.dart';
import 'package:business_manager/features/production_history/presentation/pages/production_history_dashboard_page.dart';
import 'package:business_manager/features/production_history/presentation/pages/worker_production_history_page.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempDir;
  late AppDatabase testDb;

  const matrixWidths = <double>[
    360,
    390,
    430,
    600,
    768,
    1024,
    1280,
    1440,
    1920,
  ];

  setUpAll(() {
    IstDateTimeHelper.initialize();
  });

  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('sf_resp_matrix_');
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

  Widget wrapLocalized(Widget child) {
    return MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );
  }

  group('Phase 6.1 Responsive Testing Matrix (All 9 Viewports + Live Resizing)', () {
    for (final width in matrixWidths) {
      testWidgets(
        'StitchFlow shell renders cleanly with zero overflow at ${width.toInt()}px',
        (tester) async {
          tester.view.devicePixelRatio = 1.0;
          tester.view.physicalSize = Size(width, 900);
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(BusinessManagerApp(config: AppConfig.dev()));
          await tester.pumpAndSettle();

          if (width < 600) {
            expect(find.byType(NavigationBar), findsOneWidget);
          } else if (width < 1024) {
            expect(find.byType(NavigationRail), findsOneWidget);
          } else {
            expect(find.byType(NavigationDrawer), findsOneWidget);
            expect(find.byType(AppBreadcrumbBar), findsOneWidget);
          }

          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets(
      'Live browser resize transitions cleanly: 390 -> 768 -> 1440 -> 360',
      (tester) async {
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        tester.view.physicalSize = const Size(390, 844);
        await tester.pumpWidget(BusinessManagerApp(config: AppConfig.dev()));
        await tester.pumpAndSettle();
        expect(find.byType(NavigationBar), findsOneWidget);

        tester.view.physicalSize = const Size(768, 1024);
        await tester.pumpAndSettle();
        expect(find.byType(NavigationRail), findsOneWidget);

        tester.view.physicalSize = const Size(1440, 900);
        await tester.pumpAndSettle();
        expect(find.byType(NavigationDrawer), findsOneWidget);

        tester.view.physicalSize = const Size(360, 800);
        await tester.pumpAndSettle();
        expect(find.byType(NavigationBar), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'Designs & Colours + Production History + QC Queue render cleanly on Mobile (360dp) & Desktop (1440dp)',
      (tester) async {
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final pages = <Widget>[
          const DesignsColoursPage(),
          const ProductionHistoryDashboardPage(),
          const WorkerProductionHistoryPage(),
          const ProcessHistoryPage(),
          const InspectionQueuePage(),
        ];

        for (final width in const [360.0, 1440.0]) {
          tester.view.physicalSize = Size(width, 900);
          for (final page in pages) {
            await tester.pumpWidget(wrapLocalized(page));
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: 'Overflow/exception on ${page.runtimeType} at ${width}px',
            );
          }
        }
      },
    );

    testWidgets(
      'AppDataTable v2 pagination & sorting paginate 35 items cleanly on Desktop',
      (tester) async {
        tester.view.devicePixelRatio = 1.0;
        tester.view.physicalSize = const Size(1280, 900);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final items = List<String>.generate(35, (i) => 'Lot-${i + 1}');
        await tester.pumpWidget(
          wrapLocalized(
            Scaffold(
              body: SingleChildScrollView(
                child: AppDataTable<String>(
                  enablePagination: true,
                  initialPageSize: 10,
                  columns: const [
                    AppDataColumn(label: 'Lot Number', sortable: true),
                  ],
                  items: items,
                  cellsBuilder: (s) => [Text(s)],
                  mobileCardBuilder: (_, s) => Text(s),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('1–10 / 35'), findsOneWidget);
        expect(find.text('Lot-1'), findsOneWidget);
        expect(find.text('Lot-11'), findsNothing);

        await tester.tap(find.byIcon(Icons.chevron_right_rounded));
        await tester.pumpAndSettle();

        expect(find.text('11–20 / 35'), findsOneWidget);
        expect(find.text('Lot-11'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  });
}
