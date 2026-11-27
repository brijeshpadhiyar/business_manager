import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget home, {Size size = const Size(400, 800)}) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: home,
    ),
  );
}

void main() {
  group('AppLazySection', () {
    testWidgets('builds only the first rows and reveals more on demand', (
      tester,
    ) async {
      final items = List.generate(55, (i) => 'Row $i');
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: SingleChildScrollView(
              child: AppLazySection<String>(
                items: items,
                initialCount: 5,
                pageSize: 20,
                itemBuilder: (_, item, _) => Text(item),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Row 4'), findsOneWidget);
      expect(find.text('Row 5'), findsNothing);
      expect(find.text('Show 20 more'), findsOneWidget);

      await tester.tap(find.text('Show 20 more'));
      await tester.pumpAndSettle();
      expect(find.text('Row 24'), findsOneWidget);
      expect(find.text('Row 25'), findsNothing);
      expect(find.text('Show less'), findsOneWidget);

      await tester.tap(find.text('Show less'));
      await tester.pumpAndSettle();
      expect(find.text('Row 5'), findsNothing);
    });

    testWidgets('shows no footer when everything already fits', (tester) async {
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: AppLazySection<String>(
              items: const ['a', 'b'],
              itemBuilder: (_, item, _) => Text(item),
            ),
          ),
        ),
      );
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('sliver variant works inside CustomScrollView', (tester) async {
      final items = List.generate(30, (i) => 'S$i');
      await tester.pumpWidget(
        _app(
          Scaffold(
            body: CustomScrollView(
              slivers: [
                AppLazySection<String>.sliver(
                  items: items,
                  initialCount: 3,
                  itemBuilder: (_, item, _) => Text(item),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('S2'), findsOneWidget);
      expect(find.text('S3'), findsNothing);
      expect(find.text('Show 20 more'), findsOneWidget);
    });
  });

  group('AppUnsavedChangesGuard', () {
    Future<void> openForm(WidgetTester tester, {required bool dirty}) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => AppUnsavedChangesGuard(
                        hasChanges: dirty,
                        child: const Scaffold(body: Text('Form page')),
                      ),
                    ),
                  ),
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Form page'), findsOneWidget);
    }

    testWidgets('clean form closes without asking', (tester) async {
      await openForm(tester, dirty: false);
      await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
      await tester.pumpAndSettle();
      expect(find.text('Form page'), findsNothing);
      expect(find.text('Discard changes?'), findsNothing);
    });

    testWidgets('dirty form asks, keep editing stays, discard leaves', (
      tester,
    ) async {
      await openForm(tester, dirty: true);
      await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
      await tester.pumpAndSettle();
      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Form page'), findsOneWidget);

      await tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text('Form page'), findsNothing);
    });
  });

  group('AppAdaptiveField', () {
    Future<double> fieldWidth(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _app(
          const Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: AppAdaptiveField(child: Placeholder()),
            ),
          ),
          size: size,
        ),
      );
      return tester.getSize(find.byType(Placeholder)).width;
    }

    testWidgets('full width on phones, capped on desktop', (tester) async {
      expect(await fieldWidth(tester, const Size(390, 800)), 390);
      expect(await fieldWidth(tester, const Size(1280, 800)), 220);
    });
  });
}
