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

  testWidgets('Renders EN and switches live to Gujarati (બિઝનેસ મેનેજર)', (
    tester,
  ) async {
    final config = AppConfig.dev();
    await configureDependencies(config);

    await tester.pumpWidget(BusinessManagerApp(config: config));
    await tester.pumpAndSettle();

    expect(find.text('StitchFlow Dev'), findsOneWidget);
    expect(find.text('Project Foundation Ready'), findsOneWidget);
    expect(find.text('business_manager_dev.sqlite'), findsOneWidget);

    // Switch to Gujarati via LocaleCubit and verify immediate localized render.
    await getIt<LocaleCubit>().setPreference(AppLocalePreference.gu);
    await tester.pumpAndSettle();

    expect(find.text('સ્ટિચફ્લો (Dev)'), findsOneWidget);
    expect(find.text('પ્રોજેક્ટ ફાઉન્ડેશન તૈયાર છે'), findsOneWidget);
  });
}
