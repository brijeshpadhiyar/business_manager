import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('AppScaffold Modes & Backward Compatibility', () {
    testWidgets('Standard mode preserves existing title, actions & body API', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: AppScaffold(
            title: 'Create Lot',
            actions: [
              AppIconButton(
                icon: Icons.check,
                tooltip: 'Save',
                onPressed: () {},
              ),
            ],
            body: const Center(child: Text('Standard Body')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Create Lot'), findsOneWidget);
      expect(find.text('Standard Body'), findsOneWidget);
    });

    testWidgets('Compact mode renders minimal 48dp toolbar & body', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AppScaffold(
            scrollMode: AppScrollMode.compact,
            title: 'Compact Workspace',
            body: Center(child: Text('Max Working Area')),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Compact Workspace'), findsOneWidget);
      expect(find.text('Max Working Area'), findsOneWidget);
      final appBar = tester.widget<AppBar>(find.byType(AppBar));
      expect(appBar.toolbarHeight, 48);
    });
  });

  group('AppScaffold Collapsible Mode, Summary Strip & Pinned Search', () {
    Widget buildCollapsibleApp({
      required Size surfaceSize,
      required ThemeData theme,
      Locale locale = const Locale('en'),
      ValueChanged<String>? onSearch,
    }) {
      return MaterialApp(
        theme: theme,
        locale: locale,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: MediaQuery(
          data: MediaQueryData(size: surfaceSize),
          child: AppScaffold(
            scrollMode: AppScrollMode.collapsible,
            header: AppCollapsibleHeader(
              title: 'Lots Management',
              subtitle: 'Track active production lots',
              expandedHeight: 184,
              summary: const AppSummaryStrip(
                metrics: [
                  AppSummaryMetric(
                    label: 'Total',
                    value: '42',
                    tone: AppStatusTone.info,
                  ),
                  AppSummaryMetric(
                    label: 'Active',
                    value: '30',
                    tone: AppStatusTone.good,
                  ),
                  AppSummaryMetric(
                    label: 'Completed',
                    value: '12',
                    tone: AppStatusTone.neutral,
                  ),
                ],
              ),
              actions: [
                AppIconButton(
                  icon: Icons.add,
                  tooltip: 'Add',
                  onPressed: () {},
                ),
              ],
            ),
            pinnedHeaderHeight: 68,
            pinnedHeader: AppSearchField(
              label: 'Search lots',
              onChanged: onSearch,
            ),
            slivers: [
              SliverList.builder(
                itemCount: 40,
                itemBuilder: (ctx, i) => ListTile(
                  key: ValueKey<int>(i),
                  title: Text('Lot #$i'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    testWidgets(
      'Mobile (360dp Light Glass): expands initially, collapses smoothly on scroll, keeps search pinned',
      (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        String query = '';
        await tester.pumpWidget(
          buildCollapsibleApp(
            surfaceSize: const Size(360, 780),
            theme: AppTheme.light(),
            onSearch: (v) => query = v,
          ),
        );
        await tester.pumpAndSettle();

        // Expanded initial state
        expect(find.text('Lots Management'), findsWidgets);
        expect(find.text('Track active production lots'), findsOneWidget);
        expect(find.text('42'), findsOneWidget);
        expect(find.text('Lot #0'), findsOneWidget);

        // Scroll down to collapse header
        await tester.drag(find.byType(CustomScrollView), const Offset(0, -350));
        await tester.pumpAndSettle();

        // Pinned search remains accessible after collapse
        await tester.enterText(find.byType(TextFormField), '1001');
        await tester.pumpAndSettle();
        expect(query, '1001');

        // Clear search button works
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();
        expect(query, '');
      },
    );

    testWidgets(
      'Tablet (768dp Dark Glass) & Desktop (1280dp) adapt cleanly without overflow',
      (tester) async {
        for (final size in const [Size(768, 900), Size(1280, 900)]) {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(
            buildCollapsibleApp(
              surfaceSize: size,
              theme: AppTheme.dark(),
              locale: const Locale('gu'),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.text('Lots Management'), findsWidgets);
          expect(find.text('42'), findsOneWidget);
          expect(find.byType(AppSearchField), findsOneWidget);
        }

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );
  });
}
