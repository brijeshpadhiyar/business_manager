import 'package:business_manager/core/design_system/app_icons.dart';
import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/features/slips/domain/entities/slip_entities.dart';
import 'package:business_manager/features/slips/presentation/widgets/slip_share_sheet.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('gu');
  });

  Widget wrapApp(Widget home, {EdgeInsets viewInsets = EdgeInsets.zero}) {
    return MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(360, 740),
          viewInsets: viewInsets,
        ),
        child: home,
      ),
    );
  }

  testWidgets('Core buttons, icon buttons & cards pass Android tap-target and labeled-target guidelines', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      wrapApp(
        Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppButton(
                  label: 'Issue Stock',
                  icon: AppIcons.stockIssue,
                  onPressed: () {},
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    AppIconButton(
                      icon: AppIcons.share,
                      tooltip: 'Share Slip',
                      onPressed: () {},
                    ),
                    AppIconButton(
                      icon: AppIcons.refresh,
                      tooltip: 'Refresh Data',
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    handle.dispose();
  });

  testWidgets('SlipShareSheet renders cleanly with active 300px virtual keyboard inset on compact phone', (
    tester,
  ) async {
    const slip = WorkerSlipData(
      type: SlipDocumentType.paymentReceipt,
      referenceId: 'PAY-991',
      businessNameEn: 'StitchFlow Workshop',
      businessNameGu: 'સ્ટિચફ્લો વર્કશોપ',
      workerName: 'Maheshbhai',
      transactionAtUtcMillis: 1732620000000,
      items: [
        SlipLineItem(
          title: 'Regular Payment',
          subtitle: 'Cash',
          amountPaise: 150000,
        ),
      ],
      primaryAmountPaise: 150000,
      outstandingPayablePaise: 0,
    );

    await tester.pumpWidget(
      wrapApp(
        const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: SlipShareSheet(slip: slip, initialLocaleCode: 'en'),
          ),
        ),
        viewInsets: const EdgeInsets.only(bottom: 300),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('StitchFlow Workshop'), findsOneWidget);
    expect(find.text('Share Image (PNG)'), findsOneWidget);
    expect(find.text('Share Text (WhatsApp)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
