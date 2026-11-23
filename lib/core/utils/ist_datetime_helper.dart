import 'package:intl/intl.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Enforces UTC storage and `Asia/Kolkata` (IST, UTC+05:30) display and
/// business-date extraction across the entire application.
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

  /// Extracts the `Asia/Kolkata` business date in strict ISO `YYYY-MM-DD` format.
  /// Used for effective-dated historical rate lookups (`member_process_rates`).
  static String toIstBusinessDate(int utcMillis) {
    final ist = fromUtcMillisToIst(utcMillis);
    final y = ist.year.toString().padLeft(4, '0');
    final m = ist.month.toString().padLeft(2, '0');
    final d = ist.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Formats UTC epoch milliseconds for UI display in `Asia/Kolkata`.
  static String formatIstDateTime(int utcMillis, {String locale = 'en'}) {
    final ist = fromUtcMillisToIst(utcMillis);
    return DateFormat('dd MMM yyyy, hh:mm a', locale).format(ist);
  }
}
