import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../features/daily_entry/domain/entry_status.dart';
import '../../features/daily_entry/domain/notes_codec.dart';
import '../database/app_database.dart';
import 'backup_validator.dart';

abstract final class BackupCodec {
  static Uint8List encode({
    required List<FolderRow> folders,
    required List<DailyEntryRow> entries,
    required Map<String, String> settings,
    required String appVersion,
    DateTime? exportedAt,
  }) {
    final manifest = {
      'format': 'daytracker-backup',
      'formatVersion': 1,
      'schemaVersion': AppDatabase.currentSchemaVersion,
      'exportedAt': (exportedAt ?? DateTime.now()).toUtc().toIso8601String(),
      'appVersion': appVersion,
      'counts': {'folders': folders.length, 'entries': entries.length},
    };
    final files = <String, Object?>{
      'manifest.json': manifest,
      'folders.json': [for (final folder in folders) _folderJson(folder)],
      'daily_entries.json': [for (final entry in entries) _entryJson(entry)],
      'settings.json': settings,
    };
    final archive = Archive();
    for (final file in files.entries) {
      final encoded = utf8.encode(jsonEncode(file.value));
      if (encoded.length > BackupValidator.maxFileBytes) {
        throw const FormatException('A backup component exceeds its size cap.');
      }
      archive.addFile(ArchiveFile.bytes(file.key, encoded));
    }
    final bytes = ZipEncoder().encodeBytes(archive);
    if (bytes.length > BackupValidator.maxArchiveBytes) {
      throw const FormatException('The backup exceeds its size cap.');
    }
    return bytes;
  }

  static Map<String, Object?> _folderJson(FolderRow folder) => {
    'id': folder.id,
    'name': folder.name,
    'color': folder.color,
    'iconCode': folder.iconCode,
    'sortOrder': folder.sortOrder,
    'isArchived': folder.isArchived,
    'createdAt': folder.createdAt.toUtc().toIso8601String(),
    'updatedAt': folder.updatedAt.toUtc().toIso8601String(),
  };

  static Map<String, Object?> _entryJson(DailyEntryRow entry) => {
    'id': entry.id,
    'folderId': entry.folderId,
    'entryDate': entry.entryDate,
    'status': switch (EntryStatus.fromValue(entry.status)) {
      EntryStatus.completed => 'completed',
      EntryStatus.missed => 'missed',
      null => null,
    },
    'notes': entry.notesJson == null
        ? null
        : NotesCodec.decode(entry.notesJson),
    'createdAt': entry.createdAt.toUtc().toIso8601String(),
    'updatedAt': entry.updatedAt.toUtc().toIso8601String(),
  };
}
