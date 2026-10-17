import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/database/app_database.dart';
import 'package:habit_tracker/features/settings/data/settings_repository.dart';

void main() {
  late AppDatabase db;
  late SettingsRepository settings;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
  });
  tearDown(() => db.close());

  test('persists theme selection and falls back on unknown values', () async {
    await settings.setThemeMode(ThemeMode.dark);
    expect(await settings.watchThemeMode().first, ThemeMode.dark);
    await settings.set(SettingsRepository.themeModeKey, 'unknown');
    expect(await settings.watchThemeMode().first, ThemeMode.light);
  });

  test('uses light on first launch without writing a preference', () async {
    expect(await settings.watchThemeMode().first, ThemeMode.light);
    expect(await settings.get(SettingsRepository.themeModeKey), isNull);
  });

  test(
    'does not replace an existing preference during initialization',
    () async {
      await settings.setThemeMode(ThemeMode.dark);
      expect(await settings.watchThemeMode().first, ThemeMode.dark);
      expect(await settings.get(SettingsRepository.themeModeKey), 'dark');
    },
  );

  test('defaults to Arabic without writing a language preference', () async {
    expect(await settings.watchLanguage().first, const Locale('ar'));
    expect(await settings.get(SettingsRepository.languageKey), isNull);
  });

  test('keeps a saved language and theme across database reopen', () async {
    final directory = await Directory.systemTemp.createTemp(
      'habit_language_test',
    );
    final file = File('${directory.path}/settings.sqlite');
    try {
      final firstDb = AppDatabase(NativeDatabase(file));
      final firstSettings = SettingsRepository(firstDb);
      await firstSettings.setThemeMode(ThemeMode.dark);
      await firstSettings.setLanguage(const Locale('en'));
      await firstDb.close();

      final reopenedDb = AppDatabase(NativeDatabase(file));
      final reopenedSettings = SettingsRepository(reopenedDb);
      expect(await reopenedSettings.watchLanguage().first, const Locale('en'));
      expect(await reopenedSettings.watchThemeMode().first, ThemeMode.dark);
      expect(await reopenedSettings.get(SettingsRepository.languageKey), 'en');
      await reopenedDb.close();
    } finally {
      await directory.delete(recursive: true);
    }
  });
}
