import 'package:bloc_test/bloc_test.dart';
import 'package:business_manager/core/config/app_config.dart';
import 'package:business_manager/core/config/app_flavor.dart';
import 'package:business_manager/core/config/app_logger.dart';
import 'package:business_manager/core/localization/locale_cubit.dart';
import 'package:business_manager/core/localization/locale_state.dart';
import 'package:business_manager/core/utils/id_generator.dart';
import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:business_manager/core/utils/money_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() {
    IstDateTimeHelper.initialize();
  });

  group('AppConfig & AppLogger flavor isolation', () {
    test('dev and prod configs use distinct DB, media dir, and logging', () {
      final dev = AppConfig.dev();
      final prod = AppConfig.prod();

      expect(dev.flavor, AppFlavor.dev);
      expect(prod.flavor, AppFlavor.prod);
      expect(dev.databaseName, 'business_manager_dev.sqlite');
      expect(prod.databaseName, 'business_manager_prod.sqlite');
      expect(dev.mediaDirName, 'media_dev');
      expect(prod.mediaDirName, 'media_prod');
      expect(dev.enableDebugLogs, isTrue);
      expect(prod.enableDebugLogs, isFalse);

      expect(AppLogger(dev).isEnabled, isTrue);
      expect(AppLogger(prod).isEnabled, isFalse);
    });
  });

  group('IstDateTimeHelper UTC -> Asia/Kolkata boundary', () {
    test('converts UTC 19:00 on Nov 30 to Dec 1 IST business date', () {
      final utcMillis = DateTime.utc(
        2026,
        11,
        30,
        19,
        0,
      ).millisecondsSinceEpoch;
      expect(IstDateTimeHelper.toIstBusinessDate(utcMillis), '2026-12-01');
    });

    test('converts UTC 18:29:59 on Nov 30 to Nov 30 IST business date', () {
      final utcMillis = DateTime.utc(
        2026,
        11,
        30,
        18,
        29,
        59,
      ).millisecondsSinceEpoch;
      expect(IstDateTimeHelper.toIstBusinessDate(utcMillis), '2026-11-30');
    });
  });

  group('MoneyFormatter', () {
    test('formats positive and negative paise using Indian grouping', () {
      expect(MoneyFormatter.formatPaise(2000), '₹20.00');
      expect(MoneyFormatter.formatPaise(12500050), '₹1,25,000.50');
      expect(MoneyFormatter.formatPaise(-100000), '-₹1,000.00');
    });
  });

  group('IdGenerator', () {
    test('generates distinct UUIDv7 entity IDs and UUIDv4 request IDs', () {
      final generator = IdGenerator();
      final id1 = generator.nextEntityId();
      final id2 = generator.nextEntityId();
      expect(id1, isNot(equals(id2)));
      expect(id1.length, 36);
      expect(generator.nextRequestId().length, 36);
    });
  });

  group('LocaleCubit persistence', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    blocTest<LocaleCubit, LocaleState>(
      'persists Gujarati then English then System Default preferences',
      build: () => LocaleCubit(prefs),
      act: (cubit) async {
        await cubit.setPreference(AppLocalePreference.gu);
        await cubit.setPreference(AppLocalePreference.en);
        await cubit.setPreference(AppLocalePreference.system);
      },
      expect: () => const [
        LocaleState(preference: AppLocalePreference.gu),
        LocaleState(preference: AppLocalePreference.en),
        LocaleState(preference: AppLocalePreference.system),
      ],
      verify: (_) {
        expect(prefs.getString('app_locale_preference'), 'system');
      },
    );
  });
}
