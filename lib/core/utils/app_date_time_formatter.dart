import 'package:business_manager/core/utils/ist_datetime_helper.dart';
import 'package:intl/intl.dart';

/// Centralized, common application-level helper for all date, time, range,
/// timestamp, and duration formatting across StitchFlow.
///
/// Enforces `Asia/Kolkata` (IST) display timezone and caches [DateFormat]
/// instances per `(pattern, locale)` to avoid per-frame allocations in
/// high-refresh-rate scrolling lists.
abstract final class AppDateTimeFormatter {
  static const String _datePattern = 'dd MMM yyyy';
  static const String _dateTimePattern = 'dd MMM yyyy, hh:mm a';
  static const String _timePattern = 'hh:mm a';
  static const String _shortDatePattern = 'dd MMM';

  static final Map<String, DateFormat> _formatCache = <String, DateFormat>{};

  static DateFormat _cachedFormat(String pattern, String locale) {
    final normalizedLocale = locale.trim().isEmpty ? 'en' : locale.trim();
    final key = '$pattern::$normalizedLocale';
    return _formatCache.putIfAbsent(
      key,
      () => DateFormat(pattern, normalizedLocale),
    );
  }

  /// Formats UTC epoch milliseconds as localized IST date (e.g. `24 Nov 2026`).
  static String formatDate(int utcMillis, {String locale = 'en'}) {
    final ist = IstDateTimeHelper.fromUtcMillisToIst(utcMillis);
    return _cachedFormat(_datePattern, locale).format(ist);
  }

  /// Formats UTC epoch milliseconds as localized IST date + 12h time
  /// (e.g. `24 Nov 2026, 04:15 PM`).
  static String formatDateTime(int utcMillis, {String locale = 'en'}) {
    final ist = IstDateTimeHelper.fromUtcMillisToIst(utcMillis);
    return _cachedFormat(_dateTimePattern, locale).format(ist);
  }

  /// Formats UTC epoch milliseconds as localized 12-hour IST time
  /// (e.g. `04:15 PM`).
  static String formatTime(
    int utcMillis, {
    String locale = 'en',
    bool includeIstSuffix = false,
  }) {
    final ist = IstDateTimeHelper.fromUtcMillisToIst(utcMillis);
    final formatted = _cachedFormat(_timePattern, locale).format(ist);
    return includeIstSuffix ? '$formatted IST' : formatted;
  }

  /// Formats a wall-clock `(hour, minute)` pair in 12-hour format
  /// (e.g. `08:00 PM` or `08:00 PM IST`).
  static String formatTimeFromHourMinute(
    int hour,
    int minute, {
    String locale = 'en',
    bool includeIstSuffix = false,
  }) {
    final clampedHour = hour.clamp(0, 23);
    final clampedMinute = minute.clamp(0, 59);
    final reference = DateTime(2026, 1, 1, clampedHour, clampedMinute);
    final formatted = _cachedFormat(_timePattern, locale).format(reference);
    return includeIstSuffix ? '$formatted IST' : formatted;
  }

  /// Formats UTC epoch milliseconds as compact day + month (e.g. `24 Nov`).
  static String formatShortDate(int utcMillis, {String locale = 'en'}) {
    final ist = IstDateTimeHelper.fromUtcMillisToIst(utcMillis);
    return _cachedFormat(_shortDatePattern, locale).format(ist);
  }

  /// Formats a calendar [DateTime] as compact day + month (e.g. `24 Nov`).
  static String formatShortDayMonth(DateTime date, {String locale = 'en'}) {
    return _cachedFormat(_shortDatePattern, locale).format(date);
  }

  /// Formats a calendar [DateTime] as strict ISO date (`YYYY-MM-DD`).
  static String toIsoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Extracts the `Asia/Kolkata` business date in strict ISO `YYYY-MM-DD` format.
  static String toIstBusinessDate(int utcMillis) {
    final ist = IstDateTimeHelper.fromUtcMillisToIst(utcMillis);
    return toIsoDate(ist);
  }

  /// Parses strict ISO `YYYY-MM-DD` into a local calendar [DateTime], or `null`
  /// if invalid.
  static DateTime? tryParseIsoDate(String isoDate) {
    final trimmed = isoDate.trim();
    final parts = trimmed.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    final dt = DateTime(y, m, d);
    if (dt.year != y || dt.month != m || dt.day != d) return null;
    return dt;
  }

  /// Formats a strict ISO business date (`YYYY-MM-DD`) into human-readable
  /// display format (e.g. `2026-11-24` -> `24 Nov 2026`).
  /// Falls back to [isoDate] unchanged if it cannot be parsed.
  static String formatIsoBusinessDateForDisplay(
    String isoDate, {
    String locale = 'en',
  }) {
    final parsed = tryParseIsoDate(isoDate);
    if (parsed == null) return isoDate;
    return _cachedFormat(_datePattern, locale).format(parsed);
  }

  /// Formats an ISO business date range (e.g. `01 Jan 2026 – 31 Mar 2026` or
  /// `01 Apr 2026 – Ongoing`).
  static String formatIsoDateRange({
    required String fromIso,
    String? toIso,
    required String ongoingLabel,
    String locale = 'en',
  }) {
    final fromText = formatIsoBusinessDateForDisplay(fromIso, locale: locale);
    final toText = (toIso != null && toIso.trim().isNotEmpty)
        ? formatIsoBusinessDateForDisplay(toIso, locale: locale)
        : ongoingLabel;
    return '$fromText – $toText';
  }

  /// Formats UTC epoch milliseconds as deterministic ISO IST
  /// (`YYYY-MM-DD HH:MM:SS IST`) without requiring `intl` locale tables
  /// (safe for background jobs, exports, and backup manifests).
  static String formatIsoDateTimeIst(int utcMillis) {
    final ist = IstDateTimeHelper.fromUtcMillisToIst(utcMillis);
    final y = ist.year.toString().padLeft(4, '0');
    final mo = ist.month.toString().padLeft(2, '0');
    final d = ist.day.toString().padLeft(2, '0');
    final h = ist.hour.toString().padLeft(2, '0');
    final mi = ist.minute.toString().padLeft(2, '0');
    final s = ist.second.toString().padLeft(2, '0');
    return '$y-$mo-$d $h:$mi:$s IST';
  }

  /// Formats UTC epoch milliseconds for deterministic IST filenames
  /// (`YYYYMMDD_HHMMSS`).
  static String formatFileTimestampIst(int utcMillis) {
    final ist = IstDateTimeHelper.fromUtcMillisToIst(utcMillis);
    final y = ist.year.toString().padLeft(4, '0');
    final mo = ist.month.toString().padLeft(2, '0');
    final d = ist.day.toString().padLeft(2, '0');
    final h = ist.hour.toString().padLeft(2, '0');
    final mi = ist.minute.toString().padLeft(2, '0');
    final s = ist.second.toString().padLeft(2, '0');
    return '$y$mo${d}_$h$mi$s';
  }

  /// Formats UTC epoch milliseconds as standard UTC ISO-8601 string.
  static String formatUtcIso8601(int utcMillis) {
    return DateTime.fromMillisecondsSinceEpoch(
      utcMillis,
      isUtc: true,
    ).toIso8601String();
  }

  /// Formats a duration in hours concisely (`2.5d` for >=24h, `4.5h` otherwise).
  static String formatDurationHours(double hours) {
    if (hours >= 24) {
      return '${(hours / 24).toStringAsFixed(1)}d';
    }
    return '${hours.toStringAsFixed(1)}h';
  }

  /// Formats a countdown duration in seconds (e.g. `2m 05s` or `45s`).
  static String formatCountdownSeconds(int totalSeconds) {
    final safe = totalSeconds < 0 ? 0 : totalSeconds;
    final mins = safe ~/ 60;
    final secs = safe % 60;
    if (mins > 0) {
      return '${mins}m ${secs.toString().padLeft(2, '0')}s';
    }
    return '${secs}s';
  }
}
