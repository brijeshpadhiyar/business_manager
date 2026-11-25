import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/utils/app_memo.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/processes/domain/repositories/process_repository.dart';
import 'package:business_manager/features/search/presentation/global_search_dialog.dart';
import 'package:business_manager/features/search/presentation/quick_actions.dart';
import 'package:business_manager/features/workers/domain/entities/worker_entities.dart';
import 'package:business_manager/features/workers/domain/repositories/worker_repository.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockLotRepository extends Mock implements LotRepository {}

class _MockWorkerRepository extends Mock implements WorkerRepository {}

class _MockProcessRepository extends Mock implements ProcessRepository {}

Widget _app(Widget home) {
  return MaterialApp(
    theme: AppTheme.light(),
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      ...GlobalMaterialLocalizations.delegates,
    ],
    home: home,
  );
}

void main() {
  group('AppMemo', () {
    test('recomputes only when a dependency changes', () {
      final memo = AppMemo<int>();
      var runs = 0;
      final list = [3, 1, 2];
      int compute() => ++runs;

      memo([list, 'a', 1], compute);
      memo([list, 'a', 1], compute);
      expect(runs, 1, reason: 'same list instance and values');

      memo([list, 'b', 1], compute);
      expect(runs, 2, reason: 'string changed');

      memo([List.of(list), 'b', 1], compute);
      expect(runs, 3, reason: 'new list instance');

      memo.clear();
      memo([list, 'b', 1], compute);
      expect(runs, 4, reason: 'cleared');
    });
  });

  group('AppFormDirtyTracker', () {
    test('text edits, revert, manual marks and reset', () {
      final a = TextEditingController(text: 'x');
      final b = TextEditingController();
      final tracker = AppFormDirtyTracker()..watch([a, b]);
      var notifications = 0;
      tracker.addListener(() => notifications++);

      expect(tracker.isDirty, isFalse);
      b.text = 'typed';
      expect(tracker.isDirty, isTrue);
      b.text = '';
      expect(tracker.isDirty, isFalse, reason: 'back to the saved text');
      expect(notifications, 2, reason: 'only flips are reported');

      a.text = 'loaded from db';
      tracker.reset();
      expect(tracker.isDirty, isFalse, reason: 'loaded values become saved');

      tracker.markDirty();
      expect(tracker.isDirty, isTrue);

      tracker.dispose();
      a.dispose();
      b.dispose();
    });
  });

  group('Quick actions panel', () {
    for (final width in [360.0, 800.0, 1440.0]) {
      testWidgets('lays out without overflow at ${width.toInt()}dp', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _app(
            const Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: QuickActionsPanel(),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('Issue stock to worker'), findsOneWidget);
        expect(find.text('Record payment'), findsOneWidget);
      });
    }

    testWidgets('large text (1.3x) still fits on a small phone', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(
            size: Size(360, 800),
            textScaler: TextScaler.linear(1.3),
          ),
          child: _app(
            const Scaffold(
              body: SingleChildScrollView(child: QuickActionsPanel()),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Global search', () {
    late _MockLotRepository lots;
    late _MockWorkerRepository workers;
    late _MockProcessRepository processes;

    setUp(() async {
      await getIt.reset();
      lots = _MockLotRepository();
      workers = _MockWorkerRepository();
      processes = _MockProcessRepository();
      getIt
        ..registerSingleton<LotRepository>(lots)
        ..registerSingleton<WorkerRepository>(workers)
        ..registerSingleton<ProcessRepository>(processes);
      when(
        () => lots.getLots(searchQuery: any(named: 'searchQuery')),
      ).thenAnswer((_) async => const []);
      when(
        () => workers.getWorkers(searchQuery: any(named: 'searchQuery')),
      ).thenAnswer((_) async => const []);
      when(
        () => processes.getProcesses(searchQuery: any(named: 'searchQuery')),
      ).thenAnswer((_) async => const []);
    });

    tearDown(() async => getIt.reset());

    Future<void> open(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => AppDialog.showCustom<String>(
                  context,
                  builder: (_) => const GlobalSearchDialog(),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('empty box shows quick actions', (tester) async {
      await open(tester);
      expect(find.text('Quick actions'), findsOneWidget);
      expect(find.text('New lot'), findsOneWidget);
    });

    testWidgets('typing finds lots and workers', (tester) async {
      const ts = 1700000000000;
      when(() => lots.getLots(searchQuery: 'ra')).thenAnswer(
        (_) async => const [
          LotEntity(
            id: 'l1',
            lotNumber: 'LOT-77',
            title: 'Rani kurti',
            status: LotStatus.active,
            transactionAt: ts,
            recordedAt: ts,
            createdAt: ts,
            updatedAt: ts,
          ),
        ],
      );
      when(() => workers.getWorkers(searchQuery: 'ra')).thenAnswer(
        (_) async => const [
          WorkerEntity(
            id: 'w1',
            name: 'Ramesh',
            isActive: true,
            createdAt: ts,
            updatedAt: ts,
          ),
        ],
      );
      await open(tester);
      await tester.enterText(find.byType(TextField), 'ra');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('LOT-77'), findsOneWidget);
      expect(find.text('Ramesh'), findsOneWidget);
      expect(find.text('Lots'), findsOneWidget);
      expect(find.text('Workers'), findsOneWidget);
    });

    testWidgets('shows a friendly message when nothing matches', (
      tester,
    ) async {
      await open(tester);
      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('No matches for "zzz"'), findsOneWidget);
    });
  });
}
