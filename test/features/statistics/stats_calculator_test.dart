import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/daily_entry/domain/entry_status.dart';
import 'package:habit_tracker/features/statistics/domain/stats_calculator.dart';

void main() {
  group('StatsCalculator', () {
    test('counts only explicit statuses and calculates longest streak', () {
      final stats = StatsCalculator.compute({
        '2026-10-01': EntryStatus.completed,
        '2026-10-02': EntryStatus.completed,
        '2026-10-03': EntryStatus.completed,
        '2026-10-04': EntryStatus.missed,
        '2026-10-06': EntryStatus.completed,
      }, today: DateTime(2026, 10, 7));

      expect(stats.completed, 4);
      expect(stats.missed, 1);
      expect(stats.recorded, 5);
      expect(stats.completion.percent, 80);
      expect(stats.longestStreak, 3);
    });

    test('current streak starts yesterday when today is unrecorded', () {
      final stats = StatsCalculator.compute({
        '2026-10-11': EntryStatus.completed,
        '2026-10-12': EntryStatus.completed,
      }, today: DateTime(2026, 10, 13, 23));
      expect(stats.currentStreak, 2);
    });

    test('a missed today breaks the current streak immediately', () {
      final stats = StatsCalculator.compute({
        '2026-10-12': EntryStatus.completed,
        '2026-10-13': EntryStatus.missed,
      }, today: DateTime(2026, 10, 13));
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 1);
    });

    test('yesterday missed and an older streak both end at zero today', () {
      final yesterdayMissed = StatsCalculator.compute({
        '2026-10-11': EntryStatus.missed,
        '2026-10-10': EntryStatus.completed,
      }, today: DateTime(2026, 10, 12));
      expect(yesterdayMissed.currentStreak, 0);

      final stale = StatsCalculator.compute({
        '2026-10-09': EntryStatus.completed,
      }, today: DateTime(2026, 10, 12));
      expect(stale.currentStreak, 0);
    });

    test('future records do not affect totals or longest streak', () {
      final stats = StatsCalculator.compute({
        '2026-10-10': EntryStatus.completed,
        '2026-10-11': EntryStatus.completed,
        '2026-10-12': EntryStatus.completed,
        '2026-10-13': EntryStatus.missed,
        '2026-10-14': EntryStatus.completed,
        '2026-10-15': EntryStatus.completed,
      }, today: DateTime(2026, 10, 12, 18));

      expect(stats.completed, 3);
      expect(stats.missed, 0);
      expect(stats.longestStreak, 3);
      expect(stats.currentStreak, 3);
    });

    test('completed today counts in the live current streak', () {
      final stats = StatsCalculator.compute({
        '2026-10-11': EntryStatus.completed,
        '2026-10-12': EntryStatus.completed,
      }, today: DateTime(2026, 10, 12, 10));
      expect(stats.currentStreak, 2);
    });

    test('empty history has no completion percentage or streak', () {
      final stats = StatsCalculator.compute({}, today: DateTime(2026, 10, 13));
      expect(stats.completion.percent, isNull);
      expect(stats.currentStreak, 0);
      expect(stats.longestStreak, 0);
    });
  });
}
