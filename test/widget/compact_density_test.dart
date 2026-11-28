import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/localization/locale_cubit.dart';
import 'package:business_manager/core/localization/locale_state.dart';
import 'package:business_manager/core/theme/density_cubit.dart';
import 'package:business_manager/core/theme/theme_cubit.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/settings/presentation/pages/appearance_settings_page.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppTheme & AppDensityTokens', () {
    test('compact theme injects AppDensityTokens.compact and shrinks chrome/text', () {
      final comfortable = AppTheme.light(visualDensity: VisualDensity.standard);
      final compact = AppTheme.light(visualDensity: VisualDensity.compact);

      final cTokens = comfortable.extension<AppDensityTokens>()!;
      final kTokens = compact.extension<AppDensityTokens>()!;

      expect(cTokens.isCompact, isFalse);
      expect(kTokens.isCompact, isTrue);
      expect(kTokens.appBarHeight, lessThan(cTokens.appBarHeight));
      expect(kTokens.navBarHeight, lessThan(cTokens.navBarHeight));
      expect(kTokens.buttonHeight, lessThan(cTokens.buttonHeight));
      expect(kTokens.inputHeight, lessThan(cTokens.inputHeight));
      expect(kTokens.tableRowMinHeight, lessThan(cTokens.tableRowMinHeight));

      expect(
        compact.appBarTheme.toolbarHeight!,
        lessThan(comfortable.appBarTheme.toolbarHeight!),
      );
      expect(
        compact.navigationBarTheme.height!,
        lessThan(comfortable.navigationBarTheme.height!),
      );
      expect(
        compact.textTheme.bodyMedium!.fontSize!,
        lessThan(comfortable.textTheme.bodyMedium!.fontSize!),
      );
      expect(
        compact.textTheme.titleLarge!.fontSize!,
        lessThan(comfortable.textTheme.titleLarge!.fontSize!),
      );
    });
  });

  group('Core widgets shrink in Compact density mode', () {
    Widget wrap(ThemeData theme, Widget child, {Size size = const Size(360, 800)}) {
      return MaterialApp(
        theme: theme,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          ...GlobalMaterialLocalizations.delegates,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, inner) => MediaQuery(
          data: MediaQuery.of(context).copyWith(size: size),
          child: inner!,
        ),
        home: Scaffold(body: child),
      );
    }

    testWidgets('AppButton, AppCard, AppMetricTile, AppStatusBadge are smaller', (
      tester,
    ) async {
      Widget buildSample() => Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppButton(label: 'Save', onPressed: () {}),
            const AppGap.sm(),
            const AppCard(child: AppText('Card content')),
            const AppGap.sm(),
            const AppMetricTile(
              label: 'Available',
              value: 120,
              suffix: ' pcs',
              icon: Icons.inventory_2,
            ),
            const AppGap.sm(),
            const AppStatusBadge(label: 'Good: 120 pcs'),
          ],
        ),
      );

      await tester.pumpWidget(
        wrap(AppTheme.light(visualDensity: VisualDensity.standard), buildSample()),
      );
      await tester.pumpAndSettle();
      final comfyBtn = tester.getSize(find.byType(AppButton));
      final comfyCard = tester.getSize(find.byType(AppCard).first);
      final comfyMetric = tester.getSize(find.byType(AppMetricTile));
      final comfyBadge = tester.getSize(find.byType(AppStatusBadge));

      await tester.pumpWidget(
        wrap(AppTheme.light(visualDensity: VisualDensity.compact), buildSample()),
      );
      await tester.pumpAndSettle();
      final compactBtn = tester.getSize(find.byType(AppButton));
      final compactCard = tester.getSize(find.byType(AppCard).first);
      final compactMetric = tester.getSize(find.byType(AppMetricTile));
      final compactBadge = tester.getSize(find.byType(AppStatusBadge));

      expect(compactBtn.height, lessThan(comfyBtn.height));
      expect(compactCard.height, lessThan(comfyCard.height));
      expect(compactMetric.height, lessThan(comfyMetric.height));
      expect(compactBadge.height, lessThan(comfyBadge.height));
    });

    testWidgets('AppResponsiveGrid fits more columns per row in Compact mode', (
      tester,
    ) async {
      Widget buildGrid() => const Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 360,
          child: AppResponsiveGrid(
            compactColumns: 2,
            children: [
              AppMetricTile(label: 'A', value: 1),
              AppMetricTile(label: 'B', value: 2),
              AppMetricTile(label: 'C', value: 3),
            ],
          ),
        ),
      );

      await tester.pumpWidget(
        wrap(
          AppTheme.light(visualDensity: VisualDensity.standard),
          buildGrid(),
          size: const Size(360, 800),
        ),
      );
      await tester.pumpAndSettle();
      // In comfortable mode (2 cols on 360dp), tile C wraps to row 2.
      final comfyY0 = tester.getTopLeft(find.byType(AppMetricTile).at(0)).dy;
      final comfyY2 = tester.getTopLeft(find.byType(AppMetricTile).at(2)).dy;
      expect(comfyY2, greaterThan(comfyY0));

      await tester.pumpWidget(
        wrap(
          AppTheme.light(visualDensity: VisualDensity.compact),
          buildGrid(),
          size: const Size(360, 800),
        ),
      );
      await tester.pumpAndSettle();
      // In compact mode (3 cols on 360dp), all 3 tiles fit on the first row.
      final compactY0 = tester.getTopLeft(find.byType(AppMetricTile).at(0)).dy;
      final compactY2 = tester.getTopLeft(find.byType(AppMetricTile).at(2)).dy;
      expect(compactY2, equals(compactY0));
    });

    testWidgets('AppDataTable uses compact row heights on wide screens', (
      tester,
    ) async {
      Widget buildTable() => AppDataTable<int>(
        columns: const [
          AppDataColumn(label: 'Lot'),
          AppDataColumn(label: 'Qty', numeric: true),
        ],
        items: const [1, 2, 3],
        cellsBuilder: (i) => [AppText('LOT-$i'), AppText('$i')],
        mobileCardBuilder: (_, i) => AppText('LOT-$i'),
      );

      await tester.pumpWidget(
        wrap(
          AppTheme.light(visualDensity: VisualDensity.standard),
          buildTable(),
          size: const Size(900, 700),
        ),
      );
      await tester.pumpAndSettle();
      final comfyHeight = tester.getSize(find.byType(DataTable)).height;

      await tester.pumpWidget(
        wrap(
          AppTheme.light(visualDensity: VisualDensity.compact),
          buildTable(),
          size: const Size(900, 700),
        ),
      );
      await tester.pumpAndSettle();
      final compactHeight = tester.getSize(find.byType(DataTable)).height;

      expect(compactHeight, lessThan(comfyHeight));
    });

    testWidgets('ResponsiveNavigation shrinks AppBar and NavigationBar in Compact mode', (
      tester,
    ) async {
      Widget buildNav() => ResponsiveNavigation(
        title: 'Business Manager',
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        destinations: const [
          ResponsiveNavDestination(label: 'Home', icon: Icons.home),
          ResponsiveNavDestination(label: 'Lots', icon: Icons.inventory),
        ],
        body: const Center(child: Text('Body')),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(visualDensity: VisualDensity.standard),
          builder: (context, inner) => MediaQuery(
            data: MediaQuery.of(context).copyWith(size: const Size(360, 800)),
            child: inner!,
          ),
          home: buildNav(),
        ),
      );
      await tester.pumpAndSettle();
      final comfyNavH = tester.getSize(find.byType(StitchFlowBottomNav)).height;
      final comfyBarH = tester.getSize(find.byType(AppBar)).height;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(visualDensity: VisualDensity.compact),
          builder: (context, inner) => MediaQuery(
            data: MediaQuery.of(context).copyWith(size: const Size(360, 800)),
            child: inner!,
          ),
          home: buildNav(),
        ),
      );
      await tester.pumpAndSettle();
      final compactNavH = tester.getSize(find.byType(StitchFlowBottomNav)).height;
      final compactBarH = tester.getSize(find.byType(AppBar)).height;

      expect(compactNavH, lessThan(comfyNavH));
      expect(compactBarH, lessThan(comfyBarH));
    });
  });

  group('AppearanceSettingsPage Density toggle', () {
    testWidgets('switches between Comfortable and Compact cleanly in EN and GU', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      final themeCubit = ThemeCubit(prefs);
      final localeCubit = LocaleCubit(prefs);
      final densityCubit = DensityCubit(prefs);

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<ThemeCubit>.value(value: themeCubit),
            BlocProvider<LocaleCubit>.value(value: localeCubit),
            BlocProvider<DensityCubit>.value(value: densityCubit),
          ],
          child: BlocBuilder<DensityCubit, DensityState>(
            builder: (context, densityState) => BlocBuilder<LocaleCubit, LocaleState>(
              builder: (context, localeState) => MaterialApp(
                locale: localeState.preference.locale,
                supportedLocales: AppLocalizations.supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  ...GlobalMaterialLocalizations.delegates,
                ],
                theme: AppTheme.light(
                  visualDensity: densityState.mode.visualDensity,
                ),
                home: const AppearanceSettingsPage(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(densityCubit.state.mode, UiDensityMode.comfortable);

      // Scroll to and tap Compact
      final compactFinder = find.textContaining('Compact');
      await tester.scrollUntilVisible(
        compactFinder,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.ensureVisible(compactFinder);
      await tester.pumpAndSettle();
      await tester.tap(compactFinder);
      await tester.pumpAndSettle();
      expect(densityCubit.state.mode, UiDensityMode.compact);
      expect(tester.takeException(), isNull);

      // Switch to Gujarati while in Compact mode
      await localeCubit.setPreference(AppLocalePreference.gu);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await themeCubit.close();
      await localeCubit.close();
      await densityCubit.close();
    });
  });
}
