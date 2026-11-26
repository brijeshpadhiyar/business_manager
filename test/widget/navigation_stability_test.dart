import 'package:business_manager/core/design_system/app_breakpoints.dart';
import 'package:business_manager/core/design_system/app_motion.dart';
import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/widgets/app_glass_backdrop.dart';
import 'package:business_manager/core/widgets/app_scaffold.dart';
import 'package:business_manager/core/widgets/responsive_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

final class _StatefulTabCounter extends StatefulWidget {
  const _StatefulTabCounter({required this.label});

  final String label;

  @override
  State<_StatefulTabCounter> createState() => _StatefulTabCounterState();
}

final class _StatefulTabCounterState extends State<_StatefulTabCounter> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${widget.label}: $_count'),
          FilledButton(
            onPressed: () => setState(() => _count++),
            child: Text('Inc ${widget.label}'),
          ),
        ],
      ),
    );
  }
}

void main() {
  group('AppCrossFadeIndexedStack', () {
    testWidgets(
      'preserves child State across forward and backward tab switches',
      (tester) async {
        int currentIndex = 0;
        late StateSetter setHostState;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: StatefulBuilder(
              builder: (context, setState) {
                setHostState = setState;
                return Scaffold(
                  body: AppCrossFadeIndexedStack(
                    index: currentIndex,
                    children: const [
                      _StatefulTabCounter(label: 'Home'),
                      _StatefulTabCounter(label: 'Lots'),
                      _StatefulTabCounter(label: 'Stock'),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        // Mutate Home state before switching away.
        await tester.tap(find.text('Inc Home'));
        await tester.pump();
        expect(find.text('Home: 1'), findsOneWidget);

        // Switch forward 0 -> 2 (Stock painted above Home).
        setHostState(() => currentIndex = 2);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 75));
        // Mid-transition: both outgoing and incoming are onstage inside Stack.
        expect(find.text('Home: 1'), findsOneWidget);
        expect(find.text('Stock: 0'), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.text('Stock: 0'), findsOneWidget);

        // Mutate Stock state, then switch backward 2 -> 0 (Stock painted above Home).
        await tester.tap(find.text('Inc Stock'));
        await tester.pump();
        expect(find.text('Stock: 1'), findsOneWidget);

        setHostState(() => currentIndex = 0);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 75));
        expect(find.text('Home: 1'), findsOneWidget);
        expect(find.text('Stock: 1'), findsOneWidget);

        await tester.pumpAndSettle();
        // Home state remained intact (never unmounted or reparented).
        expect(find.text('Home: 1'), findsOneWidget);
      },
    );

    testWidgets('switches instantaneously when reduced motion is enabled', (
      tester,
    ) async {
      int currentIndex = 0;
      late StateSetter setHostState;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: AppTheme.light(),
            home: StatefulBuilder(
              builder: (context, setState) {
                setHostState = setState;
                return Scaffold(
                  body: AppCrossFadeIndexedStack(
                    index: currentIndex,
                    children: const [
                      Center(child: Text('Tab A')),
                      Center(child: Text('Tab B')),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Tab A'), findsOneWidget);
      setHostState(() => currentIndex = 1);
      await tester.pump();
      expect(find.text('Tab B'), findsOneWidget);
    });
  });

  group('AppMotionEntrance', () {
    testWidgets('renders child immediately without opacity-0 mount blink', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: const Scaffold(
            body: AppMotionEntrance(index: 2, child: Text('Instant Content')),
          ),
        ),
      );
      expect(find.text('Instant Content'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppMotionEntrance),
          matching: find.byType(FadeTransition),
        ),
        findsNothing,
      );
    });
  });

  group('Opaque AppScaffold inside persistent shell', () {
    testWidgets(
      'non-embedded AppScaffold paints AppGlassBackdrop even when hasPersistentChrome is true',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            home: const ResponsiveShellScope(
              sizeClass: AppWindowSizeClass.expanded,
              hasPersistentChrome: true,
              child: AppScaffold(
                title: 'Detail Page',
                body: Center(child: Text('Detail Body')),
              ),
            ),
          ),
        );

        expect(find.byType(AppGlassBackdrop), findsOneWidget);
        expect(find.text('Detail Body'), findsOneWidget);
      },
    );

    test(
      'AppTheme disables transition snapshotting on Android and Desktop to prevent loading-frame blinks',
      () {
        for (final theme in [AppTheme.light(), AppTheme.dark()]) {
          final builders = theme.pageTransitionsTheme.builders;
          final android =
              builders[TargetPlatform.android]
                  as PredictiveBackPageTransitionsBuilder;
          final windows =
              builders[TargetPlatform.windows]
                  as FadeForwardsPageTransitionsBuilder;
          expect(android.allowSnapshotting, isFalse);
          expect(android.fallbackColor, theme.colorScheme.surface);
          expect(windows.allowSnapshotting, isFalse);
          expect(windows.backgroundColor, theme.colorScheme.surface);
        }
      },
    );
  });

  group('StatefulShellRoute + ShellRoute mobile/desktop stability', () {
    GoRouter buildTestRouter() {
      final rootKey = GlobalKey<NavigatorState>();
      final shellKey = GlobalKey<NavigatorState>();
      return GoRouter(
        navigatorKey: rootKey,
        initialLocation: '/',
        routes: [
          ShellRoute(
            navigatorKey: shellKey,
            builder: (context, state, child) {
              final width = MediaQuery.sizeOf(context).width;
              final sizeClass = AppBreakpoints.fromWidth(width);
              if (sizeClass.isCompact) {
                return ResponsiveShellScope(
                  sizeClass: sizeClass,
                  hasPersistentChrome: false,
                  child: child,
                );
              }
              return ResponsiveNavigation(
                title: 'Test App',
                selectedIndex: state.uri.path == '/lots' ? 1 : 0,
                onDestinationSelected: (idx) =>
                    context.go(idx == 0 ? '/' : '/lots'),
                destinations: const [
                  ResponsiveNavDestination(label: 'Home', icon: Icons.home),
                  ResponsiveNavDestination(label: 'Lots', icon: Icons.list),
                ],
                body: child,
              );
            },
            routes: [
              StatefulShellRoute(
                pageBuilder: (context, state, navigationShell) =>
                    MaterialPage<void>(
                      key: state.pageKey,
                      child: navigationShell,
                    ),
                navigatorContainerBuilder:
                    (context, navigationShell, children) {
                      final tabStack = AppCrossFadeIndexedStack(
                        index: navigationShell.currentIndex,
                        children: children,
                      );
                      final isCompact = AppBreakpoints.fromWidth(
                        MediaQuery.sizeOf(context).width,
                      ).isCompact;
                      if (!isCompact) return tabStack;
                      return ResponsiveNavigation(
                        title: 'Test App',
                        selectedIndex: navigationShell.currentIndex,
                        showMobileChrome: true,
                        onDestinationSelected: (idx) =>
                            navigationShell.goBranch(idx),
                        destinations: const [
                          ResponsiveNavDestination(
                            label: 'Home',
                            icon: Icons.home,
                          ),
                          ResponsiveNavDestination(
                            label: 'Lots',
                            icon: Icons.list,
                          ),
                        ],
                        body: tabStack,
                      );
                    },
                branches: [
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: '/',
                        pageBuilder: (context, state) => NoTransitionPage<void>(
                          key: state.pageKey,
                          child: const _StatefulTabCounter(label: 'Home'),
                        ),
                      ),
                    ],
                  ),
                  StatefulShellBranch(
                    routes: [
                      GoRoute(
                        path: '/lots',
                        pageBuilder: (context, state) => NoTransitionPage<void>(
                          key: state.pageKey,
                          child: Center(
                            child: FilledButton(
                              onPressed: () => context.push('/lots/42'),
                              child: const Text('Open Lot 42'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              GoRoute(
                path: '/lots/:id',
                pageBuilder: (context, state) => AppMotion.buildPage(
                  state: state,
                  child: AppScaffold(
                    title: 'Lot ${state.pathParameters['id']}',
                    body: const Center(child: Text('Lot Detail Content')),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    testWidgets(
      'mobile keeps tab chrome alive underneath pushed detail route and restores tab state on pop',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final router = buildTestRouter();
        addTearDown(router.dispose);

        await tester.pumpWidget(
          MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
        );
        await tester.pumpAndSettle();

        expect(find.byType(NavigationBar), findsOneWidget);
        await tester.tap(find.text('Inc Home'));
        await tester.pump();
        expect(find.text('Home: 1'), findsOneWidget);

        // Switch to Lots tab.
        await tester.tap(find.text('Lots'));
        await tester.pumpAndSettle();
        expect(find.text('Open Lot 42'), findsOneWidget);

        // Push detail route: detail page covers mobile tab scaffold cleanly.
        await tester.tap(find.text('Open Lot 42'));
        await tester.pumpAndSettle();
        expect(find.text('Lot Detail Content'), findsOneWidget);

        // Pop back to Lots tab, then switch back to Home — Home state survived!
        router.pop();
        await tester.pumpAndSettle();
        expect(find.text('Open Lot 42'), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);

        await tester.tap(find.text('Home'));
        await tester.pumpAndSettle();
        expect(find.text('Home: 1'), findsOneWidget);
      },
    );

    testWidgets(
      'desktop keeps persistent sidebar mounted across tab switches and detail pushes',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final router = buildTestRouter();
        addTearDown(router.dispose);

        await tester.pumpWidget(
          MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
        );
        await tester.pumpAndSettle();

        expect(find.byType(NavigationDrawer), findsOneWidget);
        expect(find.byType(NavigationBar), findsNothing);

        await tester.tap(find.text('Lots'));
        await tester.pumpAndSettle();
        expect(find.text('Open Lot 42'), findsOneWidget);

        await tester.tap(find.text('Open Lot 42'));
        await tester.pumpAndSettle();
        // Sidebar stays mounted while opaque detail page renders in right pane.
        expect(find.byType(NavigationDrawer), findsOneWidget);
        expect(find.text('Lot Detail Content'), findsOneWidget);
      },
    );
  });
}
