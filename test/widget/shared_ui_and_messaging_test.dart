import 'package:business_manager/core/design_system/app_theme.dart';
import 'package:business_manager/core/services/app_message_service.dart';
import 'package:business_manager/core/validation/validation.dart';
import 'package:business_manager/core/widgets/widgets.dart';
import 'package:business_manager/l10n/generated/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:toastification/toastification.dart';

void main() {
  group('Extended Centralized Validators & Localizer', () {
    test('minLengthValidator and exactLengthValidator enforce exact bounds', () {
      expect(
        AppValidators.minLengthValidator('ab', minLength: 3).code,
        ValidationErrorCode.minLength,
      );
      expect(AppValidators.minLengthValidator('abc', minLength: 3).isValid, isTrue);
      expect(
        AppValidators.exactLengthValidator('123', length: 4).code,
        ValidationErrorCode.minLength,
      );
      expect(
        AppValidators.exactLengthValidator('12345', length: 4).code,
        ValidationErrorCode.maxLength,
      );
      expect(AppValidators.exactLengthValidator('1234', length: 4).isValid, isTrue);
    });

    test('ValidationLocalizer translates V1.3 Process Routing codes in EN & GU', () async {
      final en = await AppLocalizations.delegate.load(const Locale('en'));
      final gu = await AppLocalizations.delegate.load(const Locale('gu'));

      expect(
        ValidationLocalizer.localizeDomainCode(en, 'exceeds_held_quantity'),
        contains('held by the worker'),
      );
      expect(
        ValidationLocalizer.localizeDomainCode(gu, 'exceeds_held_quantity'),
        isNotEmpty,
      );
      expect(
        ValidationLocalizer.localizeDomainCode(en, 'rate_override_reason_required'),
        en.validationOverrideReasonRequired,
      );
      expect(
        ValidationLocalizer.localizeDomainCode(en, 'overpayment_not_allowed'),
        en.validationOverpaymentNotAllowed,
      );
    });
  });

  group('Shared UI Components & AppMessageService (Light & Dark Glass)', () {
    testWidgets('AppMessageService displays glass notifications & dismisses cleanly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              ToastificationWrapper(child: child ?? const SizedBox.shrink()),
          home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (ctx) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppButton(
                        label: 'Show Success',
                        onPressed: () => AppMessageService.success(
                          ctx,
                          'Saved lot successfully',
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppButton(
                        label: 'Show Warning',
                        onPressed: () =>
                            AppMessageService.warning(ctx, 'Low factory stock'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show Success'));
      await tester.pumpAndSettle();
      expect(find.text('Saved lot successfully'), findsOneWidget);
      expect(find.text('Success'), findsOneWidget);

      AppMessageService.dismissAll();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Saved lot successfully'), findsNothing);
    });

    testWidgets(
      'AppConfirmationDialog, AppSuccessState, AppSearchField & AppSectionHeader render cleanly in Dark Glass',
      (tester) async {
        bool? confirmed;
        String searchValue = '';

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Builder(
              builder: (ctx) => AppScaffold(
                title: 'Shared UI Test',
                body: ListView(
                  children: [
                    const AppSectionHeader(
                      title: 'Inventory Section',
                      subtitle: 'Live factory balances',
                    ),
                    AppSearchField(
                      label: 'Search lots',
                      onChanged: (v) => searchValue = v,
                    ),
                    const AppSuccessState(
                      title: 'All Caught Up',
                      subtitle: 'Zero pending handovers',
                    ),
                    AppButton(
                      label: 'Open Confirm',
                      onPressed: () async {
                        confirmed = await AppConfirmationDialog.show(
                          ctx,
                          title: 'Delete Lot?',
                          message: 'This will archive the lot record.',
                          consequenceNote: 'Existing stock history is preserved.',
                          confirmLabel: 'Confirm Delete',
                          cancelLabel: 'Cancel',
                          tone: AppConfirmationTone.destructive,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Inventory Section'), findsOneWidget);
        expect(find.text('All Caught Up'), findsOneWidget);

        await tester.enterText(find.byType(TextFormField), 'LOT-1001');
        await tester.pumpAndSettle();
        expect(searchValue, 'LOT-1001');

        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();
        expect(searchValue, '');

        await tester.tap(find.text('Open Confirm'));
        await tester.pumpAndSettle();
        expect(find.text('Delete Lot?'), findsOneWidget);
        expect(find.text('Existing stock history is preserved.'), findsOneWidget);

        await tester.tap(find.text('Confirm Delete'));
        await tester.pumpAndSettle();
        expect(confirmed, isTrue);
      },
    );
  });
}
