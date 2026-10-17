import 'dart:io';
import 'package:drift/drift.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../features/daily_entry/data/entry_repository.dart';
import '../../features/folders/data/folder_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import '../database/app_database.dart';
import 'backup_codec.dart';
import 'backup_models.dart';
import 'backup_validator.dart';

enum RestoreStrategy { replace, merge }

class BackupService {
  BackupService({
    required AppDatabase database,
    required FolderRepository folders,
    required EntryRepository entries,
    required SettingsRepository settings,
    Future<Directory> Function()? documentsDirectory,
    Future<String> Function()? appVersion,
    Uuid? uuid,
    DateTime Function()? now,
  }) : _database = database,
       _folders = folders,
       _entries = entries,
       _settings = settings,
       _documentsDirectory =
           documentsDirectory ?? getApplicationDocumentsDirectory,
       _appVersion = appVersion ?? _installedAppVersion,
       _uuid = uuid ?? const Uuid(),
       _now = now ?? DateTime.now;

  final AppDatabase _database;
  final FolderRepository _folders;
  final EntryRepository _entries;
  final SettingsRepository _settings;
  final Future<Directory> Function() _documentsDirectory;
  final Future<String> Function() _appVersion;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<Uint8List> exportBytes() async {
    final snapshot = await _database.transaction(
      () async => (
        folders: await _folders.getAll(),
        entries: await _entries.getAll(),
        settings: await _settings.getAll(),
      ),
    );
    final bytes = BackupCodec.encode(
      folders: snapshot.folders,
      entries: snapshot.entries,
      settings: snapshot.settings,
      appVersion: await _appVersion(),
      exportedAt: _now(),
    );
    BackupValidator.decode(bytes);
    return bytes;
  }

  /// Validates the complete archive before touching local data.
  Future<void> restoreBytes(
    List<int> bytes, {
    required RestoreStrategy strategy,
    String importedFolderSuffix = ' (مستورد)',
  }) async {
    final document = BackupValidator.decode(bytes);
    if (strategy == RestoreStrategy.merge) {
      await _merge(document, importedFolderSuffix);
    } else {
      await _replace(document);
    }
  }

  Future<File> writeSafetyBackup() async {
    final bytes = await exportBytes();
    final directory = Directory(
      '${(await _documentsDirectory()).path}${Platform.pathSeparator}backups',
    );
    await directory.create(recursive: true);
    final stamp = _now().toUtc().toIso8601String().replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    var suffix = 0;
    var file = File(
      '${directory.path}${Platform.pathSeparator}pre_restore_$stamp.zip',
    );
    while (await file.exists()) {
      suffix++;
      file = File(
        '${directory.path}${Platform.pathSeparator}pre_restore_${stamp}_$suffix.zip',
      );
    }
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  Future<void> _replace(BackupDocument document) async {
    // Keep a recoverable copy before beginning the destructive transaction.
    await writeSafetyBackup();
    await _database.transaction(() async {
      await _entries.deleteAllForRestore();
      await _folders.deleteAllForRestore();
      await _settings.deleteAllForRestore();
      await _folders.insertRestored([
        for (final folder in document.folders) _folderCompanion(folder),
      ]);
      await _entries.insertRestored([
        for (final entry in document.entries) _entryCompanion(entry),
      ]);
      await _settings.insertRestored(document.settings);
      final folders = await _folders.getAll();
      final entries = await _entries.getAll();
      final settings = await _settings.getAll();
      if (folders.length != document.folders.length ||
          entries.length != document.entries.length ||
          settings.length != document.settings.length) {
        throw StateError('Restore count verification failed.');
      }
    });
  }

  Future<void> _merge(
    BackupDocument document,
    String importedFolderSuffix,
  ) async {
    await _database.transaction(() async {
      final existing = await _folders.getAll();
      final existingEntries = await _entries.getAll();
      final nextOrder = existing.fold<int>(
        -1,
        (max, folder) => folder.sortOrder > max ? folder.sortOrder : max,
      );
      final idMap = <String, String>{
        for (final folder in document.folders) folder.id: _uuid.v4(),
      };
      final importedFolders = <FoldersCompanion>[];
      for (var index = 0; index < document.folders.length; index++) {
        final folder = document.folders[index];
        importedFolders.add(
          _folderCompanion(
            folder,
            id: idMap[folder.id]!,
            name: _importedName(folder.name, importedFolderSuffix),
            sortOrder: nextOrder + index + 1,
          ),
        );
      }
      await _folders.insertRestored(importedFolders);
      await _entries.insertRestored([
        for (final entry in document.entries)
          _entryCompanion(
            entry,
            id: _uuid.v4(),
            folderId: idMap[entry.folderId]!,
          ),
      ]);
      final folders = await _folders.getAll();
      final entries = await _entries.getAll();
      if (folders.length != existing.length + document.folders.length ||
          entries.length != existingEntries.length + document.entries.length) {
        throw StateError('Merge count verification failed.');
      }
    });
  }

  FoldersCompanion _folderCompanion(
    BackupFolder folder, {
    String? id,
    String? name,
    int? sortOrder,
  }) => FoldersCompanion.insert(
    id: id ?? folder.id,
    name: name ?? folder.name,
    color: folder.color,
    iconCode: Value(folder.iconCode),
    sortOrder: sortOrder ?? folder.sortOrder,
    isArchived: Value(folder.isArchived),
    createdAt: folder.createdAt,
    updatedAt: folder.updatedAt,
  );

  DailyEntriesCompanion _entryCompanion(
    BackupEntry entry, {
    String? id,
    String? folderId,
  }) => DailyEntriesCompanion.insert(
    id: id ?? entry.id,
    folderId: folderId ?? entry.folderId,
    entryDate: entry.date,
    status: Value(entry.status?.value),
    notesJson: Value(entry.notesJson),
    createdAt: entry.createdAt,
    updatedAt: entry.updatedAt,
  );

  String _importedName(String name, String suffix) {
    final base = name.runes.take(60 - suffix.runes.length).toList();
    return '${String.fromCharCodes(base)}$suffix';
  }

  static Future<String> _installedAppVersion() async =>
      (await PackageInfo.fromPlatform()).version;
}
