import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/date_key.dart';
import '../../../core/utils/validation.dart';
import '../domain/entry_status.dart';

typedef StatusRecord = ({String date, EntryStatus status});

class StatusCounts {
  const StatusCounts({this.completed = 0, this.missed = 0});

  final int completed;
  final int missed;

  int get recorded => completed + missed;

  @override
  bool operator ==(Object other) =>
      other is StatusCounts &&
      other.completed == completed &&
      other.missed == missed;

  @override
  int get hashCode => Object.hash(completed, missed);
}

class EntryRepository {
  EntryRepository(this._db, {Uuid? uuid, DateTime Function()? now})
    : _uuid = uuid ?? const Uuid(),
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final Uuid _uuid;
  final DateTime Function() _now;

  /// Entries of a single month only (never the whole history).
  Stream<List<DailyEntryRow>> watchMonth(String folderId, int year, int month) {
    final query = _db.select(_db.dailyEntries)
      ..where(
        (t) =>
            t.folderId.equals(folderId) &
            t.entryDate.isBetweenValues(
              DateKey.monthStart(year, month),
              DateKey.monthEnd(year, month),
            ),
      )
      ..orderBy([(t) => OrderingTerm.asc(t.entryDate)]);
    return query.watch();
  }

  Stream<DailyEntryRow?> watchEntry(String folderId, String date) =>
      _entryQuery(folderId, date).watchSingleOrNull();

  Future<DailyEntryRow?> getEntry(String folderId, String date) =>
      _entryQuery(folderId, date).getSingleOrNull();

  SimpleSelectStatement<$DailyEntriesTable, DailyEntryRow> _entryQuery(
    String folderId,
    String date,
  ) =>
      _db.select(_db.dailyEntries)
        ..where((t) => t.folderId.equals(folderId) & t.entryDate.equals(date));

  /// Lightweight (date, status) projection of the full history, used for
  /// streak calculation without loading notes.
  Stream<List<StatusRecord>> watchStatuses(String folderId) {
    final query = _db.selectOnly(_db.dailyEntries)
      ..addColumns([_db.dailyEntries.entryDate, _db.dailyEntries.status])
      ..where(
        _db.dailyEntries.folderId.equals(folderId) &
            _db.dailyEntries.status.isNotNull(),
      )
      ..orderBy([OrderingTerm.asc(_db.dailyEntries.entryDate)]);
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          (
            date: row.read(_db.dailyEntries.entryDate)!,
            status: EntryStatus.fromValue(row.read(_db.dailyEntries.status))!,
          ),
      ],
    );
  }

  /// Sets or clears only the status, leaving notes untouched.
  Future<void> setStatus(String folderId, String date, EntryStatus? status) =>
      _mutate(folderId, date, status: Value(status?.value));

  /// Sets or clears only the notes, leaving the status untouched. Blank text
  /// is treated as "no notes".
  Future<void> setNotes(String folderId, String date, String? notesJson) {
    final cleaned = (notesJson == null || notesJson.trim().isEmpty)
        ? null
        : notesJson;
    return _mutate(folderId, date, notes: Value(cleaned));
  }

  /// Saves both editable fields together so status and notes cannot diverge.
  Future<void> saveEntry(
    String folderId,
    String date, {
    required EntryStatus? status,
    required String? notesJson,
  }) {
    final cleaned = (notesJson == null || notesJson.trim().isEmpty)
        ? null
        : notesJson;
    return _mutate(
      folderId,
      date,
      status: Value(status?.value),
      notes: Value(cleaned),
    );
  }

  Future<void> _mutate(
    String folderId,
    String date, {
    Value<int?> status = const Value.absent(),
    Value<String?> notes = const Value.absent(),
  }) {
    if (!DateKey.isValid(date)) {
      throw const ValidationException(ValidationError.invalidDate);
    }
    return _db.transaction(() async {
      final existing = await getEntry(folderId, date);
      final newStatus = status.present ? status.value : existing?.status;
      final newNotes = notes.present ? notes.value : existing?.notesJson;
      final now = _now();

      if (newStatus == null && newNotes == null) {
        if (existing != null) {
          await (_db.delete(
            _db.dailyEntries,
          )..where((t) => t.id.equals(existing.id))).go();
        }
        return;
      }
      if (existing == null) {
        await _db
            .into(_db.dailyEntries)
            .insert(
              DailyEntriesCompanion.insert(
                id: _uuid.v4(),
                folderId: folderId,
                entryDate: date,
                status: Value(newStatus),
                notesJson: Value(newNotes),
                createdAt: now,
                updatedAt: now,
              ),
            );
      } else {
        await (_db.update(
          _db.dailyEntries,
        )..where((t) => t.id.equals(existing.id))).write(
          DailyEntriesCompanion(
            status: Value(newStatus),
            notesJson: Value(newNotes),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  /// Completed/missed counts per folder for one month.
  Stream<Map<String, StatusCounts>> watchMonthCounts(
    int year,
    int month, {
    required String? throughDate,
  }) {
    if (throughDate == null) return Stream.value(const {});
    return _countsQuery(
      where: 'WHERE status IS NOT NULL AND entry_date BETWEEN ? AND ?',
      variables: [
        Variable<String>(DateKey.monthStart(year, month)),
        Variable<String>(throughDate),
      ],
    );
  }

  /// Completed/missed counts per folder over the whole history.
  Stream<Map<String, StatusCounts>> watchAllTimeCounts() =>
      _countsQuery(where: 'WHERE status IS NOT NULL', variables: const []);

  Stream<Map<String, StatusCounts>> _countsQuery({
    required String where,
    required List<Variable> variables,
  }) {
    return _db
        .customSelect(
          'SELECT folder_id, '
          'COALESCE(SUM(status = 1), 0) AS completed, '
          'COALESCE(SUM(status = 2), 0) AS missed '
          'FROM daily_entries $where GROUP BY folder_id',
          variables: variables,
          readsFrom: {_db.dailyEntries},
        )
        .watch()
        .map(
          (rows) => {
            for (final row in rows)
              row.read<String>('folder_id'): StatusCounts(
                completed: row.read<int>('completed'),
                missed: row.read<int>('missed'),
              ),
          },
        );
  }

  /// All rows, used by backup export.
  Future<List<DailyEntryRow>> getAll() =>
      (_db.select(_db.dailyEntries)..orderBy([
            (t) => OrderingTerm.asc(t.folderId),
            (t) => OrderingTerm.asc(t.entryDate),
          ]))
          .get();

  /// Restore helpers. Call from a surrounding database transaction.
  Future<void> deleteAllForRestore() => _db.delete(_db.dailyEntries).go();

  Future<void> insertRestored(Iterable<DailyEntriesCompanion> rows) async {
    for (final row in rows) {
      await _db.into(_db.dailyEntries).insert(row);
    }
  }
}
