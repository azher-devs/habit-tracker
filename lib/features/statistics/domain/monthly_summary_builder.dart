import '../../../core/utils/date_key.dart';
import '../../daily_entry/domain/notes_codec.dart';
import '../../daily_entry/domain/entry_status.dart';
import 'completion_rate.dart';
import 'stats_calculator.dart';

class SummaryEntry {
  const SummaryEntry({
    required this.date,
    required this.status,
    required this.notesJson,
  });

  final String date;
  final EntryStatus? status;
  final String? notesJson;
}

class SummaryNote {
  const SummaryNote({
    required this.date,
    required this.status,
    required this.notesJson,
  });

  final String date;
  final EntryStatus? status;
  final String notesJson;
}

class WeeklySummary {
  const WeeklySummary({
    required this.startDate,
    required this.endDate,
    required this.completed,
    required this.missed,
    required this.unrecorded,
  });

  final String startDate;
  final String endDate;
  final int completed;
  final int missed;
  final int unrecorded;

  int get dayCount => completed + missed + unrecorded;
  CompletionRate get completion =>
      CompletionRate(completed: completed, missed: missed);
}

class MonthlySummary {
  const MonthlySummary({
    required this.year,
    required this.month,
    required this.stats,
    required this.monthlyCompleted,
    required this.monthlyMissed,
    required this.notes,
    required this.weeks,
    required this.previousMonthRate,
    required this.comparisonPercentagePoints,
    required this.elapsedDays,
    required this.elapsedCompleted,
    required this.elapsedMissed,
    required this.unrecordedElapsedDays,
    required this.previousPeriodDays,
    required this.previousPeriodCompleted,
    required this.previousPeriodMissed,
    required this.previousPeriodUnrecorded,
    required this.comparisonUsesMatchingPeriod,
  });

  final int year;
  final int month;
  final FolderStats stats;
  final int monthlyCompleted;
  final int monthlyMissed;
  final List<SummaryNote> notes;
  final List<WeeklySummary> weeks;
  final double? previousMonthRate;
  final double? comparisonPercentagePoints;
  final int elapsedDays;
  final int elapsedCompleted;
  final int elapsedMissed;
  final int unrecordedElapsedDays;
  final int previousPeriodDays;
  final int previousPeriodCompleted;
  final int previousPeriodMissed;
  final int previousPeriodUnrecorded;
  final bool comparisonUsesMatchingPeriod;

  int get daysWithNotes => notes.length;
  int get monthlyRecorded => monthlyCompleted + monthlyMissed;
  CompletionRate get completion =>
      CompletionRate(completed: monthlyCompleted, missed: monthlyMissed);
  bool get hasComparison => comparisonPercentagePoints != null;
}

/// Builds a calendar-month summary from a month's entries and the lightweight
/// status-only history used for streaks.
abstract final class MonthlySummaryBuilder {
  static MonthlySummary build({
    required int year,
    required int month,
    required Iterable<SummaryEntry> monthEntries,
    required Map<String, EntryStatus> allStatuses,
    required DateTime today,
  }) {
    final start = DateKey.monthStart(year, month);
    final previousMonth = DateTime.utc(year, month - 1);
    final previousStart = DateKey.monthStart(
      previousMonth.year,
      previousMonth.month,
    );
    final todayKey = DateKey.fromDate(DateKey.today(today));
    final normalizedToday = DateKey.parse(todayKey);
    final elapsedDays = elapsedDayCount(year, month, todayKey: todayKey);
    final isCurrentMonth =
        year == normalizedToday.year && month == normalizedToday.month;
    final currentPeriodEnd = elapsedDays == 0
        ? null
        : DateKey.fromDate(DateTime.utc(year, month, elapsedDays));
    final previousMonthLength = DateKey.daysInMonth(
      previousMonth.year,
      previousMonth.month,
    );
    final previousPeriodDays = elapsedDays == 0
        ? 0
        : isCurrentMonth && elapsedDays < previousMonthLength
        ? elapsedDays
        : previousMonthLength;
    final previousPeriodEnd = previousPeriodDays == 0
        ? null
        : DateKey.fromDate(
            DateTime.utc(
              previousMonth.year,
              previousMonth.month,
              previousPeriodDays,
            ),
          );
    final currentStatuses = <String, EntryStatus>{};
    final previousStatuses = <String, EntryStatus>{};
    for (final entry in allStatuses.entries) {
      if (currentPeriodEnd != null &&
          entry.key.compareTo(start) >= 0 &&
          entry.key.compareTo(currentPeriodEnd) <= 0) {
        currentStatuses[entry.key] = entry.value;
      } else if (previousPeriodEnd != null &&
          entry.key.compareTo(previousStart) >= 0 &&
          entry.key.compareTo(previousPeriodEnd) <= 0) {
        previousStatuses[entry.key] = entry.value;
      }
    }

    final weekly = <WeeklySummary>[];
    var cursor = DateKey.parse(start);
    final visibleEnd = currentPeriodEnd == null
        ? null
        : DateKey.parse(currentPeriodEnd);
    while (visibleEnd != null && !cursor.isAfter(visibleEnd)) {
      // UTC weekday: Monday=1, so Saturday begins the summary week.
      final daysFromSaturday = (cursor.weekday + 1) % 7;
      final weekStart = DateTime.utc(
        cursor.year,
        cursor.month,
        cursor.day - daysFromSaturday,
      );
      var weekEnd = DateTime.utc(
        weekStart.year,
        weekStart.month,
        weekStart.day + 6,
      );
      final clippedStart = weekStart.isBefore(DateKey.parse(start))
          ? DateKey.parse(start)
          : weekStart;
      if (weekEnd.isAfter(visibleEnd)) weekEnd = visibleEnd;
      var complete = 0;
      var missed = 0;
      var day = clippedStart;
      while (!day.isAfter(weekEnd)) {
        switch (currentStatuses[DateKey.fromDate(day)]) {
          case EntryStatus.completed:
            complete++;
          case EntryStatus.missed:
            missed++;
          case null:
            break;
        }
        day = DateTime.utc(day.year, day.month, day.day + 1);
      }
      final bucketDays = weekEnd.difference(clippedStart).inDays + 1;
      weekly.add(
        WeeklySummary(
          startDate: DateKey.fromDate(clippedStart),
          endDate: DateKey.fromDate(weekEnd),
          completed: complete,
          missed: missed,
          unrecorded: bucketDays - complete - missed,
        ),
      );
      cursor = DateTime.utc(weekEnd.year, weekEnd.month, weekEnd.day + 1);
    }

    final notes = [
      for (final entry in monthEntries)
        if (currentPeriodEnd != null &&
            entry.date.compareTo(start) >= 0 &&
            entry.date.compareTo(currentPeriodEnd) <= 0 &&
            entry.notesJson != null &&
            _hasNoteContent(entry.notesJson!))
          SummaryNote(
            date: entry.date,
            status: entry.status,
            notesJson: entry.notesJson!,
          ),
    ]..sort((a, b) => a.date.compareTo(b.date));

    final stats = StatsCalculator.compute(allStatuses, today: today);
    final monthlyCompleted = currentStatuses.values
        .where((status) => status == EntryStatus.completed)
        .length;
    final monthlyMissed = currentStatuses.values
        .where((status) => status == EntryStatus.missed)
        .length;
    final currentRate = CompletionRate(
      completed: monthlyCompleted,
      missed: monthlyMissed,
    ).fraction;
    final previousPeriodCompleted = previousStatuses.values
        .where((status) => status == EntryStatus.completed)
        .length;
    final previousPeriodMissed = previousStatuses.values
        .where((status) => status == EntryStatus.missed)
        .length;
    final previousRate = CompletionRate(
      completed: previousPeriodCompleted,
      missed: previousPeriodMissed,
    ).fraction;
    final comparison = currentRate == null || previousRate == null
        ? null
        : (currentRate - previousRate) * 100;

    final elapsedCompleted = monthlyCompleted;
    final elapsedMissed = monthlyMissed;
    final previousPeriodUnrecorded =
        previousPeriodDays - previousPeriodCompleted - previousPeriodMissed;

    return MonthlySummary(
      year: year,
      month: month,
      stats: stats,
      monthlyCompleted: monthlyCompleted,
      monthlyMissed: monthlyMissed,
      notes: notes,
      weeks: weekly,
      previousMonthRate: previousRate,
      comparisonPercentagePoints: comparison,
      elapsedDays: elapsedDays,
      elapsedCompleted: elapsedCompleted,
      elapsedMissed: elapsedMissed,
      unrecordedElapsedDays: elapsedDays - elapsedCompleted - elapsedMissed,
      previousPeriodDays: previousPeriodDays,
      previousPeriodCompleted: previousPeriodCompleted,
      previousPeriodMissed: previousPeriodMissed,
      previousPeriodUnrecorded: previousPeriodUnrecorded,
      comparisonUsesMatchingPeriod: isCurrentMonth,
    );
  }

  /// Returns elapsed dates in the selected month. Today is excluded until its
  /// local calendar day has ended; past months are complete and future months
  /// have no elapsed dates.
  static int elapsedDayCount(int year, int month, {required String todayKey}) {
    final today = DateKey.parse(todayKey);
    final monthStart = DateTime.utc(year, month);
    final selectedMonth = DateTime.utc(today.year, today.month);
    if (monthStart.isAfter(selectedMonth)) return 0;
    if (monthStart.isBefore(selectedMonth)) {
      return DateKey.daysInMonth(year, month);
    }
    return today.day - 1;
  }

  static bool _hasNoteContent(String notesJson) {
    try {
      final text = NotesCodec.decode(notesJson)
          .map((operation) => operation['insert'])
          .whereType<String>()
          .join()
          .replaceAll('\n', '')
          .trim();
      return text.isNotEmpty;
    } on FormatException {
      // Keep malformed non-empty data visible so the note card can show the
      // existing Arabic load warning instead of silently hiding user data.
      return notesJson.trim().isNotEmpty;
    }
  }
}
