import 'package:drift/native.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/app/app.dart';
import 'package:habit_tracker/core/database/app_database.dart';
import 'package:habit_tracker/core/database/providers.dart';
import 'package:habit_tracker/features/daily_entry/data/entry_repository.dart';
import 'package:habit_tracker/features/daily_entry/domain/entry_status.dart';
import 'package:habit_tracker/features/folders/data/folder_repository.dart';
import 'package:habit_tracker/features/settings/data/settings_repository.dart';
import 'package:habit_tracker/features/statistics/providers/statistics_providers.dart';

void main() {
  testWidgets('switches the full app from Arabic RTL to English LTR', (
    tester,
  ) async {
    final db = AppDatabase(
      DatabaseConnection(
        NativeDatabase.memory(),
        closeStreamsSynchronously: true,
      ),
    );
    final folderId = await FolderRepository(
      db,
    ).create(name: 'الرياضة', color: 0xFF2E9E57);
    await EntryRepository(db).saveEntry(
      folderId,
      '2026-10-14',
      status: EntryStatus.completed,
      notesJson: null,
    );
    await SettingsRepository(db).setThemeMode(ThemeMode.dark);
    addTearDown(() async {
      await db.close();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          localTodayProvider.overrideWith(
            (ref) => Stream.value(DateTime(2026, 10, 16)),
          ),
        ],
        child: const HabitTrackerApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('مجلداتي'), findsWidgets);
    expect(
      Directionality.of(tester.element(find.text('مجلداتي').first)),
      TextDirection.rtl,
    );

    await tester.tap(find.text('المزيد').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButton<Locale>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.text('Settings'))),
      TextDirection.ltr,
    );
    expect(
      Theme.of(tester.element(find.text('Settings'))).brightness,
      Brightness.dark,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Statistics'));
    await tester.pumpAndSettle();
    expect(find.text('Statistics'), findsWidgets);
    expect(find.textContaining('October'), findsOneWidget);

    expect(await FolderRepository(db).getById(folderId), isNotNull);
    expect(
      (await EntryRepository(db).getEntry(folderId, '2026-10-14'))?.status,
      EntryStatus.completed.value,
    );
    expect(
      await SettingsRepository(db).get(SettingsRepository.languageKey),
      'en',
    );
    expect(
      await SettingsRepository(db).get(SettingsRepository.themeModeKey),
      'dark',
    );
  });
}
