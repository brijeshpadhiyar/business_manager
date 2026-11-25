import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/lots/domain/entities/lot_entities.dart';
import 'package:business_manager/features/lots/domain/repositories/lot_repository.dart';
import 'package:business_manager/features/lots/presentation/bloc/lot_list_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';

class _MockLotRepository extends Mock implements LotRepository {}

void main() {
  group('Global 120Hz glassmorphism & rebuild performance modes', () {
    testWidgets(
      'Default AppCard, AppCard.listItem, and AppMetricTile use lightweight frosted glass (zero BackdropFilter) in Light & Dark themes',
      (tester) async {
        for (final theme in [AppTheme.light(), AppTheme.dark()]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: theme,
              home: AppGlassBackdrop(
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Column(
                    children: [
                      const AppCard(child: Text('Standard Card')),
                      AppCard.listItem(
                        onTap: () {},
                        child: const Text('Dense List Row'),
                      ),
                      const AppMetricTile(label: 'Pending', value: 42),
                    ],
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Standard Card'), findsOneWidget);
          expect(find.text('Dense List Row'), findsOneWidget);
          expect(find.byType(BackdropFilter), findsNothing);
          expect(find.byType(AppGlassSurface), findsNWidgets(3));
        }
      },
    );

    testWidgets(
      'v1.4 soft elevation: full-style Hero AppCard and AppScaffold AppBar render no active backdrop blur',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            home: const AppScaffold(
              title: 'Dashboard',
              body: AppCard(
                glassStyle: AppGlassStyle.full,
                blurSigma: 12,
                child: Text('Hero Banner'),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Hero Banner'), findsOneWidget);
        // Surfaces are opaque in v1.4: the card has no BackdropFilter and the
        // AppBar keeps its filter disabled.
        final activeBlurs = tester
            .widgetList<BackdropFilter>(find.byType(BackdropFilter))
            .where((f) => f.enabled);
        expect(activeBlurs, isEmpty);
      },
    );

    testWidgets(
      'AppPinnedSliverHeader avoids stacked BackdropFilter beneath AppCollapsibleHeader',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: AppScaffold(
              scrollMode: AppScrollMode.collapsible,
              header: const AppCollapsibleHeader(title: 'Lots'),
              pinnedHeaderHeight: 64,
              pinnedHeader: const Text('Pinned Search'),
              slivers: [
                SliverList.builder(
                  itemCount: 10,
                  itemBuilder: (_, i) => AppCard.listItem(child: Text('Lot $i')),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Only the AppCollapsibleHeader toolbar holds a BackdropFilter (not pinned bar or rows)
        expect(find.byType(BackdropFilter), findsOneWidget);
      },
    );

    testWidgets(
      'AppDataTable.buildSliver uses lazy SliverList with zero row BackdropFilters on mobile',
      (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => CustomScrollView(
                  slivers: [
                    AppDataTable.buildSliver<int>(
                      context,
                      itemKeyBuilder: (i) => ValueKey<int>(i),
                      columns: const [AppDataColumn(label: 'Lot')],
                      items: List<int>.generate(50, (i) => i),
                      cellsBuilder: (i) => [Text('Lot #$i')],
                      mobileCardBuilder: (_, i) => Text('Lot #$i'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SliverList), findsOneWidget);
        expect(find.byType(BackdropFilter), findsNothing);
        expect(find.text('Lot #0'), findsOneWidget);
        expect(find.text('Lot #49'), findsNothing);
      },
    );

    test(
      'LotListCubit search/filter updates silently in place without flashing loading state after initial load',
      () async {
        final repo = _MockLotRepository();
        const ts = 1700000000000;
        const lotA = LotEntity(
          id: 'l-1',
          lotNumber: 'LOT-101',
          status: LotStatus.active,
          transactionAt: ts,
          recordedAt: ts,
          createdAt: ts,
          updatedAt: ts,
        );
        when(
          () => repo.getLots(searchQuery: any(named: 'searchQuery'), status: any(named: 'status')),
        ).thenAnswer((_) async => const [lotA]);

        final cubit = LotListCubit(repo);
        final statuses = <LotListStatus>[];
        final sub = cubit.stream.listen((s) => statuses.add(s.status));

        // First load transitions initial -> loading -> loaded
        await cubit.loadLots();
        await Future<void>.delayed(Duration.zero);
        expect(statuses, [LotListStatus.loading, LotListStatus.loaded]);

        // Subsequent search updates silently without flashing LotListStatus.loading
        statuses.clear();
        await cubit.loadLots(searchQuery: '101');
        await Future<void>.delayed(Duration.zero);
        expect(statuses.contains(LotListStatus.loading), isFalse);
        expect(cubit.state.status, LotListStatus.loaded);

        await sub.cancel();
        await cubit.close();
      },
    );
  });
}
