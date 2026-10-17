import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers.dart';
import '../../../core/utils/date_key.dart';
import '../../daily_entry/data/entry_repository.dart';
import '../../daily_entry/domain/entry_status.dart';
import '../domain/monthly_summary_builder.dart';

final localTodayProvider = StreamProvider<DateTime>(
  (ref) => _watchLocalCalendarDate(),
);

Stream<DateTime> _watchLocalCalendarDate() async* {
  String? previous;
  while (true) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final key = '${today.year}-${today.month}-${today.day}';
    if (key != previous) {
      previous = key;
      yield today;
    }
    await Future<void>.delayed(const Duration(minutes: 1));
  }
}

typedef MonthCountsKey = ({int year, int month, String todayKey});

final monthStatusCountsProvider = StreamProvider.autoDispose
    .family<Map<String, StatusCounts>, MonthCountsKey>(
      (ref, key) => ref
          .watch(entryRepositoryProvider)
          .watchMonthCounts(
            key.year,
            key.month,
            throughDate: _elapsedThroughDate(key.year, key.month, key.todayKey),
          ),
    );

typedef MonthlySummaryKey = ({
  String folderId,
  int year,
  int month,
  String todayKey,
});

final monthlySummaryProvider = StreamProvider.autoDispose
    .family<MonthlySummary, MonthlySummaryKey>((ref, key) {
      final repository = ref.watch(entryRepositoryProvider);
      final output = StreamController<MonthlySummary>();
      List<DailyEntryRow>? monthRows;
      List<StatusRecord>? history;

      void publishIfReady() {
        final rows = monthRows;
        final statuses = history;
        if (rows == null || statuses == null) return;
        try {
          output.add(
            MonthlySummaryBuilder.build(
              year: key.year,
              month: key.month,
              today: DateKey.parse(key.todayKey),
              monthEntries: [
                for (final row in rows)
                  SummaryEntry(
                    date: row.entryDate,
                    status: EntryStatus.fromValue(row.status),
                    notesJson: row.notesJson,
                  ),
              ],
              allStatuses: {
                for (final item in statuses) item.date: item.status,
              },
            ),
          );
        } catch (error, stack) {
          output.addError(error, stack);
        }
      }

      final monthSubscription = repository
          .watchMonth(key.folderId, key.year, key.month)
          .listen((value) {
            monthRows = value;
            publishIfReady();
          }, onError: output.addError);
      final statusSubscription = repository.watchStatuses(key.folderId).listen((
        value,
      ) {
        history = value;
        publishIfReady();
      }, onError: output.addError);

      output.onCancel = () async {
        await monthSubscription.cancel();
        await statusSubscription.cancel();
        await output.close();
      };
      ref.onDispose(() {
        unawaited(monthSubscription.cancel());
        unawaited(statusSubscription.cancel());
        if (!output.isClosed) unawaited(output.close());
      });
      return output.stream;
    });

String? _elapsedThroughDate(int year, int month, String todayKey) {
  final elapsed = MonthlySummaryBuilder.elapsedDayCount(
    year,
    month,
    todayKey: todayKey,
  );
  if (elapsed == 0) return null;
  return DateKey.fromDate(DateTime.utc(year, month, elapsed));
}
