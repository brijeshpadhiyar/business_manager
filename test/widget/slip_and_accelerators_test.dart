import 'package:business_manager/core/services/form_draft_service.dart';
import 'package:business_manager/core/theme/density_cubit.dart';
import 'package:business_manager/features/slips/domain/entities/slip_entities.dart';
import 'package:business_manager/features/slips/presentation/widgets/slip_preview_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('gu');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('FormDraftService saves, restores, clears drafts & remembered defaults', () async {
    final prefs = await SharedPreferences.getInstance();
    final service = FormDraftService(prefs);

    expect(service.readDraft('payment_form'), isNull);
    await service.saveDraft('payment_form', {'amount': '1500', 'notes': 'UPI'});
    final restored = service.readDraft('payment_form');
    expect(restored?['amount'], '1500');
    expect(restored?['notes'], 'UPI');

    await service.setLastPaymentMode('UPI');
    await service.setLastProcessId('proc-stitch');
    await service.setSetupChecklistDismissed(true);
    expect(service.lastPaymentMode, 'UPI');
    expect(service.lastProcessId, 'proc-stitch');
    expect(service.isSetupChecklistDismissed, isTrue);

    await service.clearDraft('payment_form');
    expect(service.readDraft('payment_form'), isNull);
  });

  test('DensityCubit persists comfortable/compact preference', () async {
    final prefs = await SharedPreferences.getInstance();
    final cubit = DensityCubit(prefs);
    expect(cubit.state.mode, UiDensityMode.comfortable);

    await cubit.setMode(UiDensityMode.compact);
    expect(cubit.state.mode, UiDensityMode.compact);
    expect(cubit.state.mode.visualDensity, VisualDensity.compact);

    final reloaded = DensityCubit(prefs);
    expect(reloaded.state.mode, UiDensityMode.compact);
    await cubit.close();
    await reloaded.close();
  });

  testWidgets('SlipPreviewCard renders in EN and GU without overflow', (
    tester,
  ) async {
    const slip = WorkerSlipData(
      type: SlipDocumentType.stockIssueChallan,
      referenceId: 'CH-AB12',
      businessNameEn: 'StitchFlow Textile Workshop',
      businessNameGu: 'સ્ટિચફ્લો ટેક્સટાઇલ વર્કશોપ',
      workerName: 'Kishorbhai',
      transactionAtUtcMillis: 1732620000000,
      items: [
        SlipLineItem(
          title: 'LOT-007 • Kurti • Indigo',
          subtitle: 'Stitching',
          quantityText: '120 pcs',
          rateText: '₹35.00/pc',
          amountPaise: 420000,
        ),
      ],
      primaryAmountPaise: 420000,
      outstandingPayablePaise: 500000,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SlipPreviewCard(slip: slip, localeCode: 'en'),
                SlipPreviewCard(slip: slip, localeCode: 'gu'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('StitchFlow Textile Workshop'), findsOneWidget);
    expect(find.text('સ્ટિચફ્લો ટેક્સટાઇલ વર્કશોપ'), findsOneWidget);
    expect(find.text('CH-AB12'), findsNothing);
    expect(find.textContaining('CH-AB12'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });
}
