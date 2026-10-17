import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/database/app_database.dart';
import 'package:habit_tracker/core/utils/validation.dart';
import 'package:habit_tracker/features/daily_entry/data/entry_repository.dart';
import 'package:habit_tracker/features/daily_entry/domain/entry_status.dart';
import 'package:habit_tracker/features/folders/data/folder_repository.dart';

AppDatabase _memoryDb() => AppDatabase(NativeDatabase.memory());

void main() {
  // Tests intentionally open several short-lived databases (e.g. reopen test).
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase db;
  late FolderRepository folders;
  late EntryRepository entries;

  setUp(() {
    db = _memoryDb();
    folders = FolderRepository(db);
    entries = EntryRepository(db);
  });

  tearDown(() => db.close());

  group('folders', () {
    test('create assigns unique ids and increasing sort order', () async {
      final a = await folders.create(name: 'الرياضة', color: 0xFF2E9E57);
      final b = await folders.create(
        name: 'القراءة',
        color: 0xFF1E88E5,
        iconCode: 'book',
      );
      expect(a, isNot(b));
      final all = await folders.getAll();
      expect(all.map((f) => f.name), ['الرياضة', 'القراءة']);
      expect(all.map((f) => f.sortOrder), [0, 1]);
      expect(all.last.iconCode, 'book');
    });

    test('rejects empty and over-long names', () async {
      expect(
        () => folders.create(name: '   ', color: 1),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.error,
            'error',
            ValidationError.emptyName,
          ),
        ),
      );
      expect(
        () => folders.create(name: 'x' * 61, color: 1),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.error,
            'error',
            ValidationError.nameTooLong,
          ),
        ),
      );
    });

    test('rename/color/icon changes keep id and daily records', () async {
      final id = await folders.create(name: 'قديم', color: 1);
      await entries.setStatus(id, '2025-03-01', EntryStatus.completed);
      await folders.update(
        id,
        name: '  جديد ',
        color: 2,
        iconCode: const Value('star'),
      );
      final f = (await folders.getById(id))!;
      expect(f.id, id);
      expect(f.name, 'جديد');
      expect(f.color, 2);
      expect(f.iconCode, 'star');
      final e = await entries.getEntry(id, '2025-03-01');
      expect(e!.status, EntryStatus.completed.value);
    });

    test('reorder persists the new order', () async {
      final a = await folders.create(name: 'أ', color: 1);
      final b = await folders.create(name: 'ب', color: 1);
      final c = await folders.create(name: 'ج', color: 1);
      await folders.reorder([c, a, b]);
      final active = await folders.watchActive().first;
      expect(active.map((f) => f.id), [c, a, b]);
    });

    test('archive preserves data and unarchive restores it', () async {
      final id = await folders.create(name: 'دراسة', color: 1);
      final other = await folders.create(name: 'عمل', color: 1);
      await entries.setStatus(id, '2025-03-01', EntryStatus.missed);
      await entries.setNotes(id, '2025-03-02', '[{"insert":"hi\\n"}]');

      await folders.setArchived(id, true);
      expect((await folders.watchActive().first).map((f) => f.id), [other]);
      expect((await folders.watchArchived().first).map((f) => f.id), [id]);
      expect((await entries.getAll()).length, 2);

      await folders.setArchived(id, false);
      final active = await folders.watchActive().first;
      expect(active.map((f) => f.id), [other, id]);
      expect(
        (await entries.getEntry(id, '2025-03-01'))!.status,
        EntryStatus.missed.value,
      );
    });

    test('permanent delete cascades to entries', () async {
      final id = await folders.create(name: 'حذف', color: 1);
      await entries.setStatus(id, '2025-03-01', EntryStatus.completed);
      await folders.deletePermanently(id);
      expect(await entries.getAll(), isEmpty);
    });
  });

  group('daily entries', () {
    test('insert and retrieve status and notes', () async {
      final id = await folders.create(name: 'ر', color: 1);
      await entries.setStatus(id, '2025-03-05', EntryStatus.completed);
      await entries.setNotes(id, '2025-03-05', '[{"insert":"x\\n"}]');
      final e = (await entries.getEntry(id, '2025-03-05'))!;
      expect(e.status, 1);
      expect(e.notesJson, '[{"insert":"x\\n"}]');
      expect(e.entryDate, '2025-03-05');
    });

    test('status and notes updates do not overwrite each other', () async {
      final id = await folders.create(name: 'ر', color: 1);
      await entries.setNotes(id, '2025-03-05', '[{"insert":"n\\n"}]');
      await entries.setStatus(id, '2025-03-05', EntryStatus.missed);
      await entries.setStatus(id, '2025-03-05', null);
      final e = (await entries.getEntry(id, '2025-03-05'))!;
      expect(e.status, isNull);
      expect(e.notesJson, '[{"insert":"n\\n"}]');
    });

    test(
      'saveEntry commits status and notes in one repository operation',
      () async {
        final id = await folders.create(name: 'ر', color: 1);
        await entries.saveEntry(
          id,
          '2025-03-05',
          status: EntryStatus.completed,
          notesJson: '[{"insert":"ملاحظة\\n"}]',
        );

        final saved = (await entries.getEntry(id, '2025-03-05'))!;
        expect(saved.status, EntryStatus.completed.value);
        expect(saved.notesJson, '[{"insert":"ملاحظة\\n"}]');

        await entries.saveEntry(
          id,
          '2025-03-05',
          status: null,
          notesJson: null,
        );
        expect(await entries.getEntry(id, '2025-03-05'), isNull);
      },
    );

    test('record is removed when neither status nor notes remain', () async {
      final id = await folders.create(name: 'ر', color: 1);
      await entries.setStatus(id, '2025-03-05', EntryStatus.completed);
      await entries.setStatus(id, '2025-03-05', null);
      expect(await entries.getEntry(id, '2025-03-05'), isNull);
      await entries.setNotes(id, '2025-03-06', '   ');
      expect(await entries.getEntry(id, '2025-03-06'), isNull);
    });

    test('at most one entry per folder and date', () async {
      final id = await folders.create(name: 'ر', color: 1);
      await entries.setStatus(id, '2025-03-05', EntryStatus.completed);
      await entries.setStatus(id, '2025-03-05', EntryStatus.missed);
      expect((await entries.getAll()).length, 1);

      final now = DateTime.now();
      expect(
        () => db
            .into(db.dailyEntries)
            .insert(
              DailyEntriesCompanion.insert(
                id: 'dup',
                folderId: id,
                entryDate: '2025-03-05',
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('same date is independent across folders', () async {
      final a = await folders.create(name: 'أ', color: 1);
      final b = await folders.create(name: 'ب', color: 1);
      await entries.setStatus(a, '2025-03-05', EntryStatus.completed);
      await entries.setStatus(b, '2025-03-05', EntryStatus.missed);
      expect((await entries.getEntry(a, '2025-03-05'))!.status, 1);
      expect((await entries.getEntry(b, '2025-03-05'))!.status, 2);
    });

    test('invalid dates are rejected', () {
      expect(() async {
        final id = await folders.create(name: 'ر', color: 1);
        await entries.setStatus(id, '2025-02-30', EntryStatus.completed);
      }(), throwsA(isA<ValidationException>()));
    });

    test('foreign keys are enforced', () {
      expect(
        entries.setStatus(
          'missing-folder',
          '2025-03-05',
          EntryStatus.completed,
        ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('database rejects unknown status values', () async {
      final id = await folders.create(name: 'ر', color: 1);
      final now = DateTime.now();
      expect(
        () => db
            .into(db.dailyEntries)
            .insert(
              DailyEntriesCompanion.insert(
                id: 'bad',
                folderId: id,
                entryDate: '2025-03-05',
                status: const Value(9),
                createdAt: now,
                updatedAt: now,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('watchMonth returns only the requested month', () async {
      final id = await folders.create(name: 'ر', color: 1);
      await entries.setStatus(id, '2025-02-28', EntryStatus.completed);
      await entries.setStatus(id, '2025-03-01', EntryStatus.completed);
      await entries.setStatus(id, '2025-03-31', EntryStatus.missed);
      await entries.setStatus(id, '2025-04-01', EntryStatus.completed);
      final march = await entries.watchMonth(id, 2025, 3).first;
      expect(march.map((e) => e.entryDate), ['2025-03-01', '2025-03-31']);
    });

    test(
      'count streams aggregate per folder and ignore notes-only rows',
      () async {
        final a = await folders.create(name: 'أ', color: 1);
        final b = await folders.create(name: 'ب', color: 1);
        await entries.setStatus(a, '2025-03-01', EntryStatus.completed);
        await entries.setStatus(a, '2025-03-02', EntryStatus.missed);
        await entries.setStatus(a, '2025-04-01', EntryStatus.completed);
        await entries.setNotes(a, '2025-03-03', '[{"insert":"n\\n"}]');
        await entries.setStatus(b, '2025-03-01', EntryStatus.completed);

        final march = await entries
            .watchMonthCounts(2025, 3, throughDate: '2025-03-31')
            .first;
        expect(march[a], const StatusCounts(completed: 1, missed: 1));
        expect(march[b], const StatusCounts(completed: 1));

        final throughFirst = await entries
            .watchMonthCounts(2025, 3, throughDate: '2025-03-01')
            .first;
        expect(throughFirst[a], const StatusCounts(completed: 1));
        expect(throughFirst[b], const StatusCounts(completed: 1));

        final all = await entries.watchAllTimeCounts().first;
        expect(all[a], const StatusCounts(completed: 2, missed: 1));
      },
    );

    test('watchStatuses emits updates and excludes notes-only days', () async {
      final id = await folders.create(name: 'ر', color: 1);
      final stream = entries.watchStatuses(id);
      // Drift re-emits on every table write, so collapse repeated lengths.
      final expectation = expectLater(
        stream.map((l) => l.length).distinct(),
        emitsInOrder([0, 1, 2]),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await entries.setStatus(id, '2025-03-01', EntryStatus.completed);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await entries.setNotes(id, '2025-03-02', '[{"insert":"n\\n"}]');
      await entries.setStatus(id, '2025-03-03', EntryStatus.missed);
      await expectation;
    });
  });

  group('persistence and schema', () {
    test('data survives closing and reopening a file database', () async {
      final dir = await Directory.systemTemp.createTemp('habit_db_test');
      final file = File('${dir.path}/test.sqlite');
      try {
        var first = AppDatabase(NativeDatabase(file));
        final f1 = FolderRepository(first);
        final id = await f1.create(name: 'مستمر', color: 7);
        await EntryRepository(
          first,
        ).setStatus(id, '2025-03-05', EntryStatus.completed);
        await first.close();

        final second = AppDatabase(NativeDatabase(file));
        final reopened = await FolderRepository(second).getById(id);
        expect(reopened!.name, 'مستمر');
        expect(
          (await EntryRepository(second).getEntry(id, '2025-03-05'))!.status,
          1,
        );
        await second.close();
      } finally {
        await dir.delete(recursive: true);
      }
    });

    test(
      'schema v1 creates expected tables, indexes, and foreign keys',
      () async {
        final tables = await db
            .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
            .get();
        expect(
          tables.map((r) => r.read<String>('name')),
          containsAll(['folders', 'daily_entries', 'app_settings']),
        );
        final indexes = await db
            .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
            .get();
        expect(
          indexes.map((r) => r.read<String>('name')),
          containsAll(['idx_entries_date', 'idx_folders_sort']),
        );
        final version = await db
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(
          version.read<int>('user_version'),
          AppDatabase.currentSchemaVersion,
        );
        final fk = await db.customSelect('PRAGMA foreign_keys').getSingle();
        expect(fk.read<int>('foreign_keys'), 1);
      },
    );
  });
}
