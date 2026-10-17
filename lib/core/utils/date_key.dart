/// Helpers for the normalized, locale-independent `YYYY-MM-DD` calendar date
/// representation stored in the database.
///
/// Parsed dates are returned as UTC midnight so that day arithmetic
/// (differences, additions) is never affected by daylight-saving changes.
/// Only the year/month/day components are meaningful.
abstract final class DateKey {
  static final RegExp _pattern = RegExp(r'^\d{4}-\d{2}-\d{2}$');

  /// Formats the year/month/day components of [date] without any timezone
  /// conversion.
  static String fromDate(DateTime date) =>
      fromParts(date.year, date.month, date.day);

  static String fromParts(int year, int month, int day) =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  /// Returns the date for [value], or `null` when it is malformed or does not
  /// exist on the calendar (for example `2025-02-30`).
  static DateTime? tryParse(String value) {
    if (!_pattern.hasMatch(value)) return null;
    final year = int.parse(value.substring(0, 4));
    final month = int.parse(value.substring(5, 7));
    final day = int.parse(value.substring(8, 10));
    final parsed = DateTime.utc(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  static DateTime parse(String value) {
    final parsed = tryParse(value);
    if (parsed == null) {
      throw FormatException('Invalid calendar date', value);
    }
    return parsed;
  }

  static bool isValid(String value) => tryParse(value) != null;

  /// Today's calendar date (from the device's local clock) as UTC midnight.
  static DateTime today([DateTime? now]) {
    final local = now ?? DateTime.now();
    return DateTime.utc(local.year, local.month, local.day);
  }

  static int daysInMonth(int year, int month) =>
      DateTime.utc(year, month + 1, 0).day;

  static String monthStart(int year, int month) => fromParts(year, month, 1);

  static String monthEnd(int year, int month) =>
      fromParts(year, month, daysInMonth(year, month));
}
