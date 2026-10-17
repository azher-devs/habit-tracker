import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/folders/domain/calendar_month.dart';

void main() {
  group('CalendarMonth (Saturday-first)', () {
    test('aligns months to Saturday as column zero', () {
      // 1 January 2026 is Thursday: five cells follow Saturday-first order.
      final month = CalendarMonth(2026, 1);
      expect(month.leadingDays, 5);
      expect(month.dayAt(0), isNull);
      expect(month.dayAt(4), isNull);
      expect(month.dayAt(5), 1);
      expect(month.dayAt(6), 2);
    });

    test('handles leap months and clips trailing cells', () {
      final month = CalendarMonth(2024, 2);
      expect(month.daysInMonth, 29);
      expect(month.dayAt(month.leadingDays), 1);
      expect(month.dayAt(month.leadingDays + 28), 29);
      expect(month.dayAt(month.cellCount - 1), isNull);
    });

    test('invalid cells return null', () {
      final month = CalendarMonth(2025, 3);
      expect(month.dayAt(-1), isNull);
      expect(month.dayAt(month.cellCount), isNull);
    });
  });
}
