import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/features/daily_entry/domain/entry_status.dart';
import 'package:habit_tracker/features/statistics/domain/monthly_summary_builder.dart';

void main() {
  test(
    'builds chronological notes, clipped Saturday weeks, and comparison',
    () {
      final summary = MonthlySummaryBuilder.build(
        year: 2026,
        month: 10,
        today: DateTime(2026, 10, 12),
        allStatuses: {
          '2026-09-01': EntryStatus.completed,
          '2026-09-02': EntryStatus.missed,
          '2026-09-12': EntryStatus.missed,
          '2026-10-01': EntryStatus.completed,
          '2026-10-02': EntryStatus.missed,
          '2026-10-03': EntryStatus.completed,
          '2026-10-12': EntryStatus.missed,
          '2026-10-13': EntryStatus.completed,
        },
        monthEntries: const [
          SummaryEntry(
            date: '2026-10-04',
            status: null,
            notesJson: '[{"insert":"second\\n"}]',
          ),
          SummaryEntry(
            date: '2026-10-02',
            status: EntryStatus.missed,
            notesJson: '[{"insert":"missed day note\\n"}]',
          ),
          SummaryEntry(
            date: '2026-10-01',
            status: EntryStatus.completed,
            notesJson: '[{"insert":"first\\n"}]',
          ),
          SummaryEntry(date: '2026-10-06', status: null, notesJson: null),
          SummaryEntry(
            date: '2026-10-05',
            status: EntryStatus.completed,
            notesJson: '[{"insert":"\\n"}]',
          ),
          SummaryEntry(
            date: '2026-10-13',
            status: null,
            notesJson: '[{"insert":"future note\\n"}]',
          ),
        ],
      );

      expect(summary.monthlyCompleted, 2);
      expect(summary.monthlyMissed, 1);
      expect(summary.completion.percent, 67);
      expect(summary.notes.map((note) => note.date), [
        '2026-10-01',
        '2026-10-02',
        '2026-10-04',
      ]);
      expect(summary.notes.map((note) => note.status), [
        EntryStatus.completed,
        EntryStatus.missed,
        null,
      ]);
      expect(summary.weeks.first.startDate, '2026-10-01');
      expect(summary.weeks.first.endDate, '2026-10-02');
      expect(summary.weeks.last.startDate, '2026-10-10');
      expect(summary.weeks.last.endDate, '2026-10-11');
      expect(summary.weeks, hasLength(3));
      expect(summary.comparisonPercentagePoints, closeTo(100 / 6, 0.001));
      expect(summary.previousPeriodDays, 11);
      expect(summary.previousPeriodCompleted, 1);
      expect(summary.previousPeriodMissed, 1);
      expect(summary.elapsedDays, 11);
      expect(summary.elapsedCompleted, 2);
      expect(summary.elapsedMissed, 1);
      expect(summary.unrecordedElapsedDays, 8);
      expect(
        summary.notes.map((note) => note.date),
        isNot(contains('2026-10-13')),
      );
      expect(
        summary.weeks.fold<int>(0, (sum, week) => sum + week.completed),
        2,
      );
      expect(summary.weeks.fold<int>(0, (sum, week) => sum + week.missed), 1);
      expect(
        summary.weeks.fold<int>(0, (sum, week) => sum + week.unrecorded),
        8,
      );
    },
  );

  test('does not compare when either month has no recorded status', () {
    final summary = MonthlySummaryBuilder.build(
      year: 2026,
      month: 10,
      today: DateTime(2026, 10, 1),
      allStatuses: {'2026-10-01': EntryStatus.completed},
      monthEntries: const [],
    );
    expect(summary.previousMonthRate, isNull);
    expect(summary.comparisonPercentagePoints, isNull);
    expect(summary.hasComparison, isFalse);
  });

  test('compares January with December of the previous year', () {
    final summary = MonthlySummaryBuilder.build(
      year: 2026,
      month: 1,
      today: DateTime(2026, 2, 1),
      allStatuses: {
        '2025-12-31': EntryStatus.missed,
        '2026-01-01': EntryStatus.completed,
      },
      monthEntries: const [],
    );
    expect(summary.previousMonthRate, 0);
    expect(summary.comparisonPercentagePoints, 100);
  });

  test('excludes unfinished today and future dates from month and weeks', () {
    final summary = MonthlySummaryBuilder.build(
      year: 2026,
      month: 2,
      today: DateTime(2026, 2, 3, 23, 59),
      allStatuses: {
        '2026-01-31': EntryStatus.completed,
        '2026-02-01': EntryStatus.completed,
        '2026-02-02': EntryStatus.missed,
        '2026-02-03': EntryStatus.completed,
        '2026-02-04': EntryStatus.missed,
      },
      monthEntries: const [
        SummaryEntry(
          date: '2026-02-03',
          status: EntryStatus.completed,
          notesJson: '[{"insert":"today\\n"}]',
        ),
        SummaryEntry(
          date: '2026-02-04',
          status: null,
          notesJson: '[{"insert":"future\\n"}]',
        ),
      ],
    );

    expect(summary.elapsedDays, 2);
    expect(summary.monthlyCompleted, 1);
    expect(summary.monthlyMissed, 1);
    expect(summary.unrecordedElapsedDays, 0);
    expect(summary.notes, isEmpty);
    expect(summary.weeks.fold<int>(0, (sum, week) => sum + week.dayCount), 2);
  });

  test(
    'past February includes every day, including leap day and unrecorded',
    () {
      final summary = MonthlySummaryBuilder.build(
        year: 2024,
        month: 2,
        today: DateTime(2024, 3, 1),
        allStatuses: {
          '2024-02-01': EntryStatus.completed,
          '2024-02-29': EntryStatus.missed,
        },
        monthEntries: const [],
      );

      expect(summary.elapsedDays, 29);
      expect(summary.monthlyCompleted, 1);
      expect(summary.monthlyMissed, 1);
      expect(summary.unrecordedElapsedDays, 27);
      expect(summary.previousPeriodDays, 31);
      expect(
        summary.weeks.fold<int>(0, (sum, week) => sum + week.dayCount),
        29,
      );
      expect(
        summary.weeks.fold<int>(0, (sum, week) => sum + week.completed),
        1,
      );
    },
  );

  test('future month has no elapsed statistics or comparison', () {
    final summary = MonthlySummaryBuilder.build(
      year: 2026,
      month: 11,
      today: DateTime(2026, 10, 31),
      allStatuses: {
        '2026-11-01': EntryStatus.completed,
        '2026-10-01': EntryStatus.completed,
      },
      monthEntries: const [],
    );
    expect(summary.elapsedDays, 0);
    expect(summary.monthlyRecorded, 0);
    expect(summary.weeks, isEmpty);
    expect(summary.comparisonPercentagePoints, isNull);
  });
}
