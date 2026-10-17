/// Calendar grid geometry for a month whose first weekday is Saturday.
class CalendarMonth {
  const CalendarMonth(this.year, this.month);

  final int year;
  final int month;

  int get daysInMonth => DateTime.utc(year, month + 1, 0).day;

  /// Number of empty cells before day 1 when Saturday is column zero.
  int get leadingDays => (DateTime.utc(year, month, 1).weekday + 1) % 7;

  /// Grid cell count rounded up to complete weeks.
  int get cellCount => ((leadingDays + daysInMonth + 6) ~/ 7) * 7;

  /// The calendar day at [cell], or null for an out-of-month grid cell.
  int? dayAt(int cell) {
    if (cell < 0 || cell >= cellCount) return null;
    final day = cell - leadingDays + 1;
    return day < 1 || day > daysInMonth ? null : day;
  }
}
