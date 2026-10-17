import 'package:flutter/material.dart';

import '../../../core/database/app_database.dart';

class SettingsRepository {
  SettingsRepository(this._db);

  static const themeModeKey = 'themeMode';
  static const languageKey = 'language';

  final AppDatabase _db;

  Stream<String?> watch(String key) =>
      (_db.select(_db.appSettings)..where((t) => t.key.equals(key)))
          .watchSingleOrNull()
          .map((row) => row?.value);

  Future<String?> get(String key) async {
    final row = await (_db.select(
      _db.appSettings,
    )..where((t) => t.key.equals(key))).getSingleOrNull();
    return row?.value;
  }

  Future<Map<String, String>> getAll() async {
    final rows = await _db.select(_db.appSettings).get();
    return {for (final row in rows) row.key: row.value};
  }

  /// Restore helpers. Call from a surrounding database transaction.
  Future<void> deleteAllForRestore() => _db.delete(_db.appSettings).go();

  Future<void> insertRestored(Map<String, String> values) async {
    for (final entry in values.entries) {
      await _db
          .into(_db.appSettings)
          .insert(
            AppSettingsCompanion.insert(key: entry.key, value: entry.value),
          );
    }
  }

  Future<void> set(String key, String value) => _db
      .into(_db.appSettings)
      .insertOnConflictUpdate(
        AppSettingsCompanion.insert(key: key, value: value),
      );

  Stream<ThemeMode> watchThemeMode() => watch(themeModeKey).map(parseThemeMode);

  Future<void> setThemeMode(ThemeMode mode) => set(themeModeKey, mode.name);

  Stream<Locale> watchLanguage() => watch(languageKey).map(parseLanguage);

  Future<void> setLanguage(Locale locale) async {
    final language = locale.languageCode;
    if (language != 'ar' && language != 'en') {
      throw ArgumentError.value(locale, 'locale', 'Unsupported language');
    }
    await set(languageKey, language);
  }

  static Locale parseLanguage(String? raw) => switch (raw) {
    'en' => const Locale('en'),
    _ => const Locale('ar'),
  };

  static ThemeMode parseThemeMode(String? raw) {
    for (final mode in ThemeMode.values) {
      if (mode.name == raw) return mode;
    }
    return ThemeMode.light;
  }
}
