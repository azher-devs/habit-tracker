import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/utils/date_key.dart';

void main() {
  test('formats and parses without timezone shifts', () {
    expect(DateKey.fromParts(2025, 3, 5), '2025-03-05');
    final d = DateKey.parse('2025-03-05');
    expect((d.year, d.month, d.day), (2025, 3, 5));
    expect(DateKey.fromDate(DateTime(2025, 12, 31, 23, 59)), '2025-12-31');
  });

  test('rejects malformed and non-existent dates', () {
    for (final bad in [
      '2025-02-30',
      '2025-13-01',
      '25-01-01',
      '2025/01/01',
      '',
      '2025-1-1',
    ]) {
      expect(DateKey.isValid(bad), isFalse, reason: bad);
    }
    expect(DateKey.isValid('2024-02-29'), isTrue);
    expect(DateKey.isValid('2100-02-29'), isFalse);
  });

  test('month helpers handle leap years', () {
    expect(DateKey.daysInMonth(2024, 2), 29);
    expect(DateKey.daysInMonth(2000, 2), 29);
    expect(DateKey.daysInMonth(2100, 2), 28);
    expect(DateKey.daysInMonth(2025, 12), 31);
    expect(DateKey.monthEnd(2024, 2), '2024-02-29');
    expect(DateKey.monthStart(2025, 1), '2025-01-01');
  });
}
