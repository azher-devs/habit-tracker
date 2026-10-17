import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/providers.dart';
import 'backup_service.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(
    database: ref.watch(appDatabaseProvider),
    folders: ref.watch(folderRepositoryProvider),
    entries: ref.watch(entryRepositoryProvider),
    settings: ref.watch(settingsRepositoryProvider),
  );
});
