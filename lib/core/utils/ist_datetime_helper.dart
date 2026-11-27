import 'package:business_manager/core/utils/app_date_time_formatter.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Enforces UTC storage and `Asia/Kolkata` (IST, UTC+05:30) conversion across
/// the entire application.
///
/// All display and string formatting delegates to the centralized
/// [AppDateTimeFormatter] helper class.
abstract final class IstDateTimeHelper {
  static const String istLocationName = 'Asia/Kolkata';
  static bool _initialized = false;
  static late tz.Location _istLocation;

  /// Must be called once during app bootstrap (or test setUpAll).
  static void initialize() {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    _istLocation = tz.getLocation(istLocationName);
    _initialized = true;
  }

  static tz.Location get istLocation {
    if (!_initialized) {
      initialize();
    }
    return _istLocation;
  }

  /// Current UTC epoch milliseconds for database storage.
  static int nowUtcMillis() => DateTime.now().toUtc().millisecondsSinceEpoch;

  /// Converts UTC epoch milliseconds to an `Asia/Kolkata` [tz.TZDateTime].
  static tz.TZDateTime fromUtcMillisToIst(int utcMillis) {
    return tz.TZDateTime.fromMillisecondsSinceEpoch(istLocation, utcMillis);
  }

  /// Converts wall-clock date/time components in `Asia/Kolkata` (IST) to UTC epoch ms.
  static int istDateTimeToUtcMillis({
    required int year,
    required int month,
    required int day,
    int hour = 0,
    int minute = 0,
    int second = 0,
  }) {
    final ist = tz.TZDateTime(
      istLocation,
      year,
      month,
      day,
      hour,
      minute,
      second,
    );
    return ist.toUtc().millisecondsSinceEpoch;
  }

  /// UTC epoch ms of `00:00:00.000 IST` on the IST calendar day of [utcMillis].
  static int startOfIstDayUtcMillis(int utcMillis) {
    final ist = fromUtcMillisToIst(utcMillis);
    return istDateTimeToUtcMillis(
      year: ist.year,
      month: ist.month,
      day: ist.day,
    );
  }

  /// UTC epoch ms of `23:59:59.999 IST` on the IST calendar day of [utcMillis].
  static int endOfIstDayUtcMillis(int utcMillis) {
    final ist = fromUtcMillisToIst(utcMillis);
    final nextDayStart = istDateTimeToUtcMillis(
      year: ist.year,
      month: ist.month,
      day: ist.day + 1,
    );
    return nextDayStart - 1;
  }

  /// UTC epoch ms of 12:00 IST on the given IST calendar date — the canonical
  /// storage instant for date-only values (immune to DST/offset edge cases).
  static int istNoonUtcMillis({
    required int year,
    required int month,
    required int day,
  }) => istDateTimeToUtcMillis(year: year, month: month, day: day, hour: 12);

  /// Extracts the `Asia/Kolkata` business date in strict ISO `YYYY-MM-DD` format.
  /// Used for effective-dated historical rate lookups (`member_process_rates`).
  static String toIstBusinessDate(int utcMillis) =>
      AppDateTimeFormatter.toIstBusinessDate(utcMillis);

  /// Formats UTC epoch milliseconds for UI display in `Asia/Kolkata`.
  static String formatIstDateTime(int utcMillis, {String locale = 'en'}) =>
      AppDateTimeFormatter.formatDateTime(utcMillis, locale: locale);

  /// Formats UTC epoch milliseconds as a compact `Asia/Kolkata` date string.
  static String formatIstDate(int utcMillis, {String locale = 'en'}) =>
      AppDateTimeFormatter.formatDate(utcMillis, locale: locale);

  /// Formats UTC epoch milliseconds as deterministic ISO IST (`YYYY-MM-DD HH:MM:SS IST`).
  static String formatIstIsoDateTime(int utcMillis) =>
      AppDateTimeFormatter.formatIsoDateTimeIst(utcMillis);

  /// Formats UTC epoch milliseconds for deterministic IST filenames (`YYYYMMDD_HHMMSS`).
  static String formatIstFileTimestamp(int utcMillis) =>
      AppDateTimeFormatter.formatFileTimestampIst(utcMillis);
}
