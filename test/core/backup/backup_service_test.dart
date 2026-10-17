import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/backup/backup_exception.dart';
import 'package:habit_tracker/core/backup/backup_service.dart';
import 'package:habit_tracker/core/backup/backup_validator.dart';
import 'package:habit_tracker/core/database/app_database.dart';
import 'package:habit_tracker/features/daily_entry/data/entry_repository.dart';
import 'package:habit_tracker/features/daily_entry/domain/entry_status.dart';
import 'package:habit_tracker/features/folders/data/folder_repository.dart';
import 'package:habit_tracker/features/settings/data/settings_repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late FolderRepository folders;
  late EntryRepository entries;
  late SettingsRepository settings;
  late Directory temp;
  late BackupService service;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    folders = FolderRepository(db);
    entries = EntryRepository(db);
    settings = SettingsRepository(db);
    temp = await Directory.systemTemp.createTemp('habit_backup_test');
    service = BackupService(
      database: db,
      folders: folders,
      entries: entries,
      settings: settings,
      documentsDirectory: () async => temp,
      appVersion: () async => '0.1.0',
      now: () => DateTime.utc(2026, 10, 12, 9),
    );
  });

  tearDown(() async {
    await db.close();
    await temp.delete(recursive: true);
  });

  test(
    'exports and validates a round trip including Delta and settings',
    () async {
      final folderId = await folders.create(
        name: 'الرياضة',
        color: 0xFF2E9E57,
        iconCode: 'fitness',
      );
      await entries.setStatus(folderId, '2026-10-12', EntryStatus.completed);
      await entries.setNotes(
        folderId,
        '2026-10-12',
        '[{"insert":"تمرين\\n","attributes":{"bold":true}}]',
      );
      await settings.setThemeMode(ThemeMode.dark);

      final bytes = await service.exportBytes();
      final document = BackupValidator.decode(bytes);
      expect(document.folders.single.name, 'الرياضة');
      expect(document.folders.single.iconCode, 'fitness');
      expect(document.entries.single.status, EntryStatus.completed);
      expect(document.entries.single.notesJson, contains('تمرين'));
      expect(document.settings['themeMode'], 'dark');
    },
  );

  test('replace writes a safety snapshot and swaps all records', () async {
    final oldId = await folders.create(name: 'قديم', color: 1);
    await entries.setStatus(oldId, '2026-10-01', EntryStatus.missed);
    await settings.setThemeMode(ThemeMode.dark);
    final replacement = _validArchive(
      folders: [
        _folder(id: '11111111-1111-4111-8111-111111111111', name: 'جديد'),
      ],
      entries: [
        _entry(
          id: '22222222-2222-4222-8222-222222222222',
          folderId: '11111111-1111-4111-8111-111111111111',
        ),
      ],
      settings: {'themeMode': 'light'},
    );

    await service.restoreBytes(replacement, strategy: RestoreStrategy.replace);

    expect((await folders.getAll()).map((folder) => folder.name), ['جديد']);
    expect((await entries.getAll()).single.status, EntryStatus.completed.value);
    expect(await settings.get('themeMode'), 'light');
    final backups = Directory('${temp.path}${Platform.pathSeparator}backups');
    final files = await backups
        .list()
        .where((entity) => entity is File)
        .toList();
    expect(files, hasLength(1));
    final safety = BackupValidator.decode(
      await (files.single as File).readAsBytes(),
    );
    expect(safety.folders.single.name, 'قديم');
  });

  test(
    'merge remaps imported IDs and leaves existing data and settings alone',
    () async {
      final existingId = await folders.create(name: 'حالي', color: 1);
      await entries.setStatus(existingId, '2026-10-01', EntryStatus.missed);
      await settings.setThemeMode(ThemeMode.dark);
      final sourceFolderId = '11111111-1111-4111-8111-111111111111';
      final sourceEntryId = '22222222-2222-4222-8222-222222222222';
      final bytes = _validArchive(
        folders: [_folder(id: sourceFolderId, name: 'مصدر')],
        entries: [_entry(id: sourceEntryId, folderId: sourceFolderId)],
        settings: {'themeMode': 'light'},
      );

      await service.restoreBytes(bytes, strategy: RestoreStrategy.merge);

      final allFolders = await folders.getAll();
      expect(allFolders, hasLength(2));
      final imported = allFolders.singleWhere(
        (folder) => folder.id != existingId,
      );
      expect(imported.id, isNot(sourceFolderId));
      expect(imported.name, 'مصدر (مستورد)');
      final allEntries = await entries.getAll();
      expect(allEntries, hasLength(2));
      final importedEntry = allEntries.singleWhere(
        (entry) => entry.folderId == imported.id,
      );
      expect(importedEntry.id, isNot(sourceEntryId));
      expect(allEntries.any((entry) => entry.folderId == existingId), isTrue);
      expect(await settings.get('themeMode'), 'dark');
    },
  );

  test(
    'transaction rollback keeps existing data when replacement insertion fails',
    () async {
      final existingId = await folders.create(name: 'يبقى', color: 1);
      await entries.setStatus(existingId, '2026-10-01', EntryStatus.completed);
      await db.customStatement('''
      CREATE TRIGGER fail_restored_folder BEFORE INSERT ON folders
      BEGIN SELECT RAISE(ABORT, 'forced restore failure'); END
    ''');
      final bytes = _validArchive(
        folders: [
          _folder(id: '11111111-1111-4111-8111-111111111111', name: 'فشل'),
        ],
        entries: const [],
        settings: const {},
      );

      await expectLater(
        service.restoreBytes(bytes, strategy: RestoreStrategy.replace),
        throwsA(isA<Exception>()),
      );
      expect((await folders.getAll()).single.id, existingId);
      expect((await entries.getAll()).single.folderId, existingId);
    },
  );

  test('rejects traversal entries and unknown statuses', () {
    final traversal = _archive({
      'manifest.json': _manifest(0, 0),
      '../folders.json': const [],
      'daily_entries.json': const [],
      'settings.json': const {},
    });
    expect(
      () => BackupValidator.decode(traversal),
      throwsA(isA<BackupFormatException>()),
    );

    final invalidStatus = _validArchive(
      folders: [_folder(id: '11111111-1111-4111-8111-111111111111', name: 'س')],
      entries: [
        _entry(
          id: '22222222-2222-4222-8222-222222222222',
          folderId: '11111111-1111-4111-8111-111111111111',
          status: 'other',
        ),
      ],
      settings: const {},
    );
    expect(
      () => BackupValidator.decode(invalidStatus),
      throwsA(isA<BackupFormatException>()),
    );

    final invalidDelta = _validArchive(
      folders: [_folder(id: '11111111-1111-4111-8111-111111111111', name: 'س')],
      entries: [
        _entry(
          id: '22222222-2222-4222-8222-222222222222',
          folderId: '11111111-1111-4111-8111-111111111111',
          notes: [
            {
              'insert': 'text',
              'attributes': {'link': 'https://example.com'},
            },
          ],
        ),
      ],
      settings: const {},
    );
    expect(
      () => BackupValidator.decode(invalidDelta),
      throwsA(isA<BackupFormatException>()),
    );
  });

  test(
    'invalid archive is rejected before creating a safety backup or mutating data',
    () async {
      final existingId = await folders.create(name: 'يبقى', color: 1);
      final invalid = _archive({'unexpected.json': const {}});
      await expectLater(
        service.restoreBytes(invalid, strategy: RestoreStrategy.replace),
        throwsA(isA<BackupFormatException>()),
      );
      expect((await folders.getAll()).single.id, existingId);
      expect(
        await Directory(
          '${temp.path}${Platform.pathSeparator}backups',
        ).exists(),
        isFalse,
      );
    },
  );
}

Uint8List _validArchive({
  required List<Map<String, Object?>> folders,
  required List<Map<String, Object?>> entries,
  required Map<String, String> settings,
}) => _archive({
  'manifest.json': _manifest(folders.length, entries.length),
  'folders.json': folders,
  'daily_entries.json': entries,
  'settings.json': settings,
});

Uint8List _archive(Map<String, Object?> values) {
  final archive = Archive();
  for (final entry in values.entries) {
    archive.addFile(ArchiveFile.string(entry.key, jsonEncode(entry.value)));
  }
  return ZipEncoder().encodeBytes(archive);
}

Map<String, Object?> _manifest(int folderCount, int entryCount) => {
  'format': 'daytracker-backup',
  'formatVersion': 1,
  'schemaVersion': 1,
  'exportedAt': '2026-10-12T09:00:00.000Z',
  'appVersion': '0.1.0',
  'counts': {'folders': folderCount, 'entries': entryCount},
};

Map<String, Object?> _folder({required String id, required String name}) => {
  'id': id,
  'name': name,
  'color': 0xFF2E9E57,
  'iconCode': 'fitness',
  'sortOrder': 0,
  'isArchived': false,
  'createdAt': '2026-10-12T09:00:00.000Z',
  'updatedAt': '2026-10-12T09:00:00.000Z',
};

Map<String, Object?> _entry({
  required String id,
  required String folderId,
  Object? status = 'completed',
  Object? notes,
}) => {
  'id': id,
  'folderId': folderId,
  'entryDate': '2026-10-12',
  'status': status,
  'notes': notes,
  'createdAt': '2026-10-12T09:00:00.000Z',
  'updatedAt': '2026-10-12T09:00:00.000Z',
};
