import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:material_ui/material_ui.dart';

Widget _harness(
  Widget child, {
  ThemeData? theme,
  bool disableAnimations = false,
  Size size = const Size(360, 720),
}) {
  return MediaQuery(
    data: MediaQueryData(size: size, disableAnimations: disableAnimations),
    child: MaterialApp(
      theme: theme ?? AppTheme.light(),
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('AppEmptyAnimation.fromIcon', () {
    test('maps icons to expected empty-state categories', () {
      expect(
        AppEmptyAnimation.fromIcon(AppIcons.clearFilter),
        AppEmptyAnimation.search,
      );
      expect(
        AppEmptyAnimation.fromIcon(AppIcons.help),
        AppEmptyAnimation.search,
      );
      expect(
        AppEmptyAnimation.fromIcon(AppIcons.worker),
        AppEmptyAnimation.workers,
      );
      expect(
        AppEmptyAnimation.fromIcon(AppIcons.workers),
        AppEmptyAnimation.workers,
      );
      expect(
        AppEmptyAnimation.fromIcon(AppIcons.unlink),
        AppEmptyAnimation.workers,
      );
      expect(
        AppEmptyAnimation.fromIcon(AppIcons.payment),
        AppEmptyAnimation.finance,
      );
      expect(
        AppEmptyAnimation.fromIcon(AppIcons.ledger),
        AppEmptyAnimation.finance,
      );
      expect(
        AppEmptyAnimation.fromIcon(AppIcons.qcPassed),
        AppEmptyAnimation.allClear,
      );
      expect(
        AppEmptyAnimation.fromIcon(AppIcons.cloudDone),
        AppEmptyAnimation.allClear,
      );
      expect(
        AppEmptyAnimation.fromIcon(AppIcons.lot),
        AppEmptyAnimation.box,
      );
    });
  });

  group('Bundled Lottie assets', () {
    for (final preset in AppEmptyAnimation.values) {
      if (preset.assetPath == null) continue;
      test('parses ${preset.assetPath} without error', () async {
        final data = await rootBundle.load(preset.assetPath!);
        final composition = await LottieComposition.fromByteData(data);
        expect(composition.duration, greaterThan(Duration.zero));
        expect(composition.bounds.width, greaterThan(0));
      });
    }
  });

  group('AppEmptyState widget', () {
    testWidgets('renders Lottie visual, title, subtitle and CTA in light theme', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        _harness(
          AppEmptyState(
            icon: AppIcons.lot,
            title: 'No Lots Yet',
            subtitle: 'Create your first production lot to begin tracking.',
            actionLabel: 'Create Lot',
            onAction: () => tapped = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(AppEmptyVisual), findsOneWidget);
      expect(find.byType(Lottie), findsOneWidget);
      expect(find.text('No Lots Yet'), findsOneWidget);
      expect(
        find.text('Create your first production lot to begin tracking.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Create Lot'));
      expect(tapped, isTrue);
    });

    testWidgets('renders cleanly in dark theme and under reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          const AppEmptyState(
            icon: AppIcons.qcPassed,
            title: 'All Clear',
            subtitle: 'No pending inspections.',
          ),
          theme: AppTheme.dark(),
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Lottie), findsOneWidget);
      expect(find.text('All Clear'), findsOneWidget);
    });

    testWidgets('supports AppEmptyAnimation.none icon fallback', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          const AppEmptyState(
            icon: AppIcons.inventory,
            title: 'Empty Inventory',
            animation: AppEmptyAnimation.none,
          ),
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Lottie), findsNothing);
      expect(find.byIcon(AppIcons.inventory), findsOneWidget);
    });

    testWidgets('falls back to icon when gifAsset fails to load', (
      tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          const AppEmptyState(
            icon: AppIcons.worker,
            title: 'No Workers',
            gifAsset: 'assets/animations/missing_demo.gif',
          ),
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(AppIcons.worker), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
