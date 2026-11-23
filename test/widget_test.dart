import 'package:business_manager/app.dart';
import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/di/injection.dart';
import 'package:business_manager/core/localization/locale_cubit.dart';
import 'package:business_manager/core/localization/locale_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    await getIt.reset();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Renders StitchFlow EN Dashboard and switches live to Gujarati', (
    tester,
  ) async {
    final config = AppConfig.dev();
    await configureDependencies(config);

    await tester.pumpWidget(BusinessManagerApp(config: config));
    await tester.pumpAndSettle();

    expect(find.text('StitchFlow Dev'), findsWidgets);
    expect(find.text('From Fabric to Finished.'), findsOneWidget);

    // Switch to Gujarati via LocaleCubit and verify immediate localized render.
    await getIt<LocaleCubit>().setPreference(AppLocalePreference.gu);
    await tester.pumpAndSettle();

    expect(find.text('સ્ટિચફ્લો (Dev)'), findsWidgets);
    expect(find.text('કાપડથી તૈયાર વસ્ત્ર સુધી.'), findsOneWidget);
  });
}
