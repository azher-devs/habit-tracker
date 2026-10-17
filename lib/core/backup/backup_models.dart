import '../../features/daily_entry/domain/entry_status.dart';

class BackupFolder {
  const BackupFolder({
    required this.id,
    required this.name,
    required this.color,
    required this.iconCode,
    required this.sortOrder,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final int color;
  final String? iconCode;
  final int sortOrder;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class BackupEntry {
  const BackupEntry({
    required this.id,
    required this.folderId,
    required this.date,
    required this.status,
    required this.notesJson,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String folderId;
  final String date;
  final EntryStatus? status;
  final String? notesJson;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class BackupDocument {
  const BackupDocument({
    required this.formatVersion,
    required this.schemaVersion,
    required this.exportedAt,
    required this.appVersion,
    required this.folders,
    required this.entries,
    required this.settings,
  });

  final int formatVersion;
  final int schemaVersion;
  final DateTime exportedAt;
  final String appVersion;
  final List<BackupFolder> folders;
  final List<BackupEntry> entries;
  final Map<String, String> settings;
}
