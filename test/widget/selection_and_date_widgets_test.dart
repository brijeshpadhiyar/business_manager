import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    ...GlobalMaterialLocalizations.delegates,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

const _fruits = [
  'Apple',
  'Banana',
  'Cherry',
  'Date',
  'Elderberry',
  'Fig',
  'Grape',
  'Honeydew',
];

void main() {
  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
  });

  group('AppSelect', () {
    testWidgets('in-memory list: search filters and tap selects', (
      tester,
    ) async {
      String? selected;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => AppSelect<String>(
              label: 'Fruit',
              items: _fruits,
              value: selected,
              itemLabelBuilder: (f) => f,
              presentation: AppSelectPresentation.bottomSheet,
              onChanged: (v) => setState(() => selected = v),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Fruit'));
      await tester.pumpAndSettle();
      // More than 7 items → search box shown automatically.
      expect(find.byType(TextField), findsWidgets);

      await tester.enterText(find.byType(TextField).last, 'ch');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Cherry'), findsOneWidget);
      expect(find.text('Apple'), findsNothing);

      await tester.tap(find.text('Cherry'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(selected, 'Cherry');
    });

    testWidgets('async loader receives query, offset and page size', (
      tester,
    ) async {
      final calls = <(String, int, int)>[];
      String? selected;
      await tester.pumpWidget(
        _app(
          AppSelect<String>(
            label: 'Worker',
            loader: (query, offset, limit) async {
              calls.add((query, offset, limit));
              return _fruits
                  .where((f) => f.toLowerCase().contains(query.toLowerCase()))
                  .skip(offset)
                  .take(limit)
                  .toList();
            },
            pageSize: 20,
            itemLabelBuilder: (f) => f,
            presentation: AppSelectPresentation.bottomSheet,
            onChanged: (v) => selected = v,
          ),
        ),
      );

      await tester.tap(find.text('Worker'));
      await tester.pumpAndSettle();
      expect(calls, isNotEmpty);
      expect(calls.first, ('', 0, 20));

      await tester.enterText(find.byType(TextField).last, '  gra ');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(calls.last.$1, 'gra');
      expect(find.text('Grape'), findsOneWidget);

      await tester.tap(find.text('Grape'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(selected, 'Grape');
    });

    testWidgets('shows the empty message when nothing matches', (tester) async {
      await tester.pumpWidget(
        _app(
          AppSelect<String>(
            label: 'Fruit',
            items: _fruits,
            itemLabelBuilder: (f) => f,
            presentation: AppSelectPresentation.bottomSheet,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.tap(find.text('Fruit'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'zzz');
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('No matching items'), findsOneWidget);
    });
  });

  group('AppMultiSelect', () {
    testWidgets('picks several items and confirms with Done', (tester) async {
      var values = <String>[];
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => AppMultiSelect<String>(
              label: 'Fruits',
              items: _fruits.take(4).toList(),
              values: values,
              itemLabelBuilder: (f) => f,
              presentation: AppSelectPresentation.bottomSheet,
              onChanged: (v) => setState(() => values = v),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Fruits'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Apple'), warnIfMissed: false);
      await tester.pump();
      await tester.tap(find.text('Cherry'), warnIfMissed: false);
      await tester.pump();
      expect(find.text('2 selected'), findsOneWidget);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(values, unorderedEquals(['Apple', 'Cherry']));
    });

    testWidgets('Select all picks every in-memory item', (tester) async {
      var values = <String>[];
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => AppMultiSelect<String>(
              label: 'Fruits',
              items: _fruits.take(3).toList(),
              values: values,
              itemLabelBuilder: (f) => f,
              presentation: AppSelectPresentation.bottomSheet,
              onChanged: (v) => setState(() => values = v),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Fruits'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select all'));
      await tester.pump();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      expect(values, unorderedEquals(['Apple', 'Banana', 'Cherry']));
    });
  });

  group('AppChipGroup', () {
    testWidgets('single choice reports the tapped item', (tester) async {
      String? value = 'Day';
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => AppChipGroup<String>(
              items: const ['Day', 'Week', 'Month'],
              itemLabelBuilder: (s) => s,
              value: value,
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(value, 'Week');
    });

    testWidgets('multi choice toggles items', (tester) async {
      var values = <String>['Day'];
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) => AppChipGroup<String>.multi(
              items: const ['Day', 'Week', 'Month'],
              itemLabelBuilder: (s) => s,
              values: values,
              onChangedMulti: (v) => setState(() => values = v),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      expect(values, unorderedEquals(['Day', 'Month']));
      await tester.tap(find.text('Day'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(values, ['Month']);
    });
  });

  testWidgets('AppProgressBar clamps and shows its value', (tester) async {
    await tester.pumpWidget(
      _app(
        const Column(
          children: [
            AppProgressBar(value: 0.4, semanticLabel: 'Progress'),
            AppProgressBar(),
          ],
        ),
      ),
    );
    final bars = tester
        .widgetList<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        )
        .toList();
    expect(bars, hasLength(2));
    expect(bars.first.value, closeTo(0.4, 1e-9));
    expect(bars.last.value, isNull); // indeterminate
  });

  group('AppDateTimeDialogs', () {
    testWidgets('pickDate returns null when cancelled', (tester) async {
      int? result = -1;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => AppButton(
              label: 'Open',
              onPressed: () async {
                result = await AppDateTimeDialogs.pickDate(context);
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final cancel = find.textContaining(
        RegExp('cancel', caseSensitive: false),
      );
      expect(cancel, findsWidgets);
      await tester.tap(cancel.last);
      await tester.pumpAndSettle();
      expect(result, isNull);
    });

    testWidgets('pickDate returns 12:00 IST of the chosen day', (tester) async {
      // 15 Mar 2026, 12:00 IST.
      final initial = IstDateTimeHelper.istNoonUtcMillis(
        year: 2026,
        month: 3,
        day: 15,
      );
      int? result;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => AppButton(
              label: 'Open',
              onPressed: () async {
                result = await AppDateTimeDialogs.pickDate(
                  context,
                  initialUtcMillis: initial,
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20').first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.textContaining(RegExp('^ok\$', caseSensitive: false)).last,
      );
      await tester.pumpAndSettle();

      expect(
        result,
        IstDateTimeHelper.istNoonUtcMillis(year: 2026, month: 3, day: 20),
      );
    });
  });
}
