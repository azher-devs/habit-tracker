import '../../../core/utils/date_key.dart';
import '../../daily_entry/domain/entry_status.dart';
import 'completion_rate.dart';

class FolderStats {
  const FolderStats({
    required this.completed,
    required this.missed,
    required this.currentStreak,
    required this.longestStreak,
  });

  final int completed;
  final int missed;
  final int currentStreak;
  final int longestStreak;

  int get recorded => completed + missed;
  CompletionRate get completion =>
      CompletionRate(completed: completed, missed: missed);
}

/// Pure statistics over explicitly recorded statuses. Notes-only days are
/// absent from [statuses], and therefore do not count as completed days.
abstract final class StatsCalculator {
  static FolderStats compute(
    Map<String, EntryStatus> statuses, {
    required DateTime today,
  }) {
    var completed = 0;
    var missed = 0;
    final completedDates = <DateTime>[];
    final todayKey = DateKey.fromDate(today);
    for (final entry in statuses.entries) {
      // Corrupt/future records must not influence a streak or its totals.
      if (entry.key.compareTo(todayKey) > 0) continue;
      final date = DateKey.parse(entry.key);
      if (entry.value == EntryStatus.completed) {
        completed++;
        completedDates.add(date);
      } else {
        missed++;
      }
    }

    completedDates.sort();
    var longest = 0;
    var run = 0;
    DateTime? previous;
    for (final date in completedDates) {
      run = previous != null && date.difference(previous).inDays == 1
          ? run + 1
          : 1;
      if (run > longest) longest = run;
      previous = date;
    }

    final todayStatus = statuses[todayKey];
    var cursor = DateKey.today(today);
    if (todayStatus == EntryStatus.missed) {
      return FolderStats(
        completed: completed,
        missed: missed,
        currentStreak: 0,
        longestStreak: longest,
      );
    } else if (todayStatus == null) {
      cursor = DateTime.utc(cursor.year, cursor.month, cursor.day - 1);
    }

    var current = 0;
    while (statuses[DateKey.fromDate(cursor)] == EntryStatus.completed) {
      current++;
      cursor = DateTime.utc(cursor.year, cursor.month, cursor.day - 1);
    }

    return FolderStats(
      completed: completed,
      missed: missed,
      currentStreak: current,
      longestStreak: longest,
    );
  }
}
