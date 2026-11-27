import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
  });

  group('AppButton states', () {
    testWidgets('handles enabled tap, disabled state, and loading state', (
      tester,
    ) async {
      int taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Column(
              children: [
                AppButton(label: 'Active', onPressed: () => taps++),
                const AppButton(label: 'Disabled', onPressed: null),
                AppButton(
                  label: 'Loading',
                  isLoading: true,
                  onPressed: () => taps++,
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Active'));
      expect(taps, 1);

      await tester.tap(find.text('Disabled'));
      expect(taps, 1);

      await tester.tap(find.text('Loading'));
      expect(taps, 1);
      expect(find.byType(AppSpinner), findsOneWidget);
    });
  });

  group('AppTextField validation', () {
    testWidgets('displays validation error when submitted empty', (
      tester,
    ) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Form(
              key: formKey,
              child: Column(
                children: [
                  AppTextField(
                    label: 'Reference Name',
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required field' : null,
                  ),
                  AppButton(
                    label: 'Submit',
                    onPressed: () => formKey.currentState!.validate(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Submit'));
      await tester.pump();

      expect(find.text('Required field'), findsOneWidget);
    });

    testWidgets('validates live while typing, before any Save', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Form(
              child: Column(
                children: [
                  AppTextField(
                    label: 'Qty',
                    validator: (v) =>
                        (int.tryParse(v ?? '') ?? 0) > 0 ? null : 'Enter qty',
                  ),
                  const AppTextField(label: 'Untouched', validator: _alwaysBad),
                ],
              ),
            ),
          ),
        ),
      );

      // Nothing shows before the user interacts.
      expect(find.text('Enter qty'), findsNothing);

      await tester.enterText(find.byType(TextFormField).first, '0');
      await tester.pump();
      expect(find.text('Enter qty'), findsOneWidget);
      // Fields the user has not touched stay quiet.
      expect(find.text('bad'), findsNothing);

      await tester.enterText(find.byType(TextFormField).first, '12');
      await tester.pump();
      expect(find.text('Enter qty'), findsNothing);
    });
  });

  group('ResponsiveNavigation breakpoints', () {
    Widget buildNav(Size size) {
      return MediaQuery(
        data: MediaQueryData(size: size),
        child: MaterialApp(
          theme: AppTheme.light(),
          home: ResponsiveNavigation(
            title: 'Business Manager',
            selectedIndex: 0,
            onDestinationSelected: (_) {},
            destinations: const [
              ResponsiveNavDestination(label: 'Tab 1', icon: Icons.home),
              ResponsiveNavDestination(label: 'Tab 2', icon: Icons.list),
            ],
            body: const Center(child: Text('Body')),
          ),
        ),
      );
    }

    testWidgets('uses NavigationBar on mobile (< 600dp)', (tester) async {
      await tester.pumpWidget(buildNav(const Size(360, 800)));
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);
      expect(find.byType(NavigationDrawer), findsNothing);
    });

    testWidgets('uses NavigationRail on tablet (600..1023dp)', (tester) async {
      await tester.pumpWidget(buildNav(const Size(768, 1024)));
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(NavigationDrawer), findsNothing);
    });

    testWidgets('uses NavigationDrawer sidebar on desktop (>= 1024dp)', (
      tester,
    ) async {
      await tester.pumpWidget(buildNav(const Size(1280, 800)));
      expect(find.byType(NavigationDrawer), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);
    });
  });

  group('AppDataTable responsive rendering', () {
    testWidgets('renders mobile cards at 360dp and DataTable at 800dp', (
      tester,
    ) async {
      Widget buildTable(double width) {
        return MaterialApp(
          theme: AppTheme.dark(),
          home: Scaffold(
            body: SizedBox(
              width: width,
              child: AppDataTable<String>(
                columns: const [AppDataColumn(label: 'Item')],
                items: const ['Alpha'],
                cellsBuilder: (item) => [AppText(item)],
                mobileCardBuilder: (_, item) => AppText(item),
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildTable(360));
      expect(find.byType(DataTable), findsNothing);
      expect(find.text('Alpha'), findsOneWidget);

      await tester.pumpWidget(buildTable(800));
      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
    });
  });
}

String? _alwaysBad(String? _) => 'bad';
