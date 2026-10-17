import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/daily_entry/data/entry_repository.dart';
import '../../features/folders/data/folder_repository.dart';
import '../../features/settings/data/settings_repository.dart';
import 'app_database.dart';

/// Overridden in tests with an in-memory database.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(driftDatabase(name: 'habit_tracker'));
  ref.onDispose(db.close);
  return db;
});

final folderRepositoryProvider = Provider<FolderRepository>(
  (ref) => FolderRepository(ref.watch(appDatabaseProvider)),
);

final entryRepositoryProvider = Provider<EntryRepository>(
  (ref) => EntryRepository(ref.watch(appDatabaseProvider)),
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

final themeModeProvider = StreamProvider<ThemeMode>(
  (ref) => ref.watch(settingsRepositoryProvider).watchThemeMode(),
);

final languageProvider = StreamProvider<Locale>(
  (ref) => ref.watch(settingsRepositoryProvider).watchLanguage(),
);
