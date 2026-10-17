import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/database/app_database.dart';
import 'package:habit_tracker/features/folders/data/folder_repository.dart';
import 'package:habit_tracker/features/folders/presentation/folder_catalog.dart';

void main() {
  late AppDatabase db;
  late FolderRepository folders;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    folders = FolderRepository(db);
  });
  tearDown(() => db.close());

  test('persists expanded colors and stable icon identifiers', () async {
    const color = Color(0xFF006064);
    final id = await folders.create(
      name: 'صحة',
      color: color.toARGB32(),
      iconCode: 'health',
    );
    final row = await folders.getById(id);
    expect(row?.color, color.toARGB32());
    expect(row?.iconCode, 'health');
  });

  test(
    'editing a folder name preserves its color and icon selection',
    () async {
      const color = Color(0xFF880E4F);
      final id = await folders.create(
        name: 'تعلم',
        color: color.toARGB32(),
        iconCode: 'language',
      );
      await folders.update(id, name: 'تعلم يومي');
      final row = await folders.getById(id);
      expect(row?.name, 'تعلم يومي');
      expect(row?.color, color.toARGB32());
      expect(row?.iconCode, 'language');
    },
  );

  test('legacy identifiers remain available and unknown values fall back', () {
    expect(folderIconOptions.length, greaterThanOrEqualTo(36));
    expect(folderColors.length, greaterThanOrEqualTo(24));
    expect(
      FolderColorFamily.values
          .expand(folderColorsInFamily)
          .map((color) => color.toARGB32())
          .toSet()
          .length,
      folderColors.toSet().length,
    );
    for (final legacy in [
      'check',
      'book',
      'fitness',
      'water',
      'selfcare',
      'work',
    ]) {
      expect(folderIcons[legacy], isNotNull);
    }
    expect(folderIconFor('obsolete'), folderIconFor('check'));
  });

  test('invalid colors fall back, supported legacy colors stay unchanged', () {
    expect(safeFolderColor(null), folderColors.first);
    expect(safeFolderColor(-1), folderColors.first);
    expect(safeFolderColor(0), folderColors.first);
    expect(safeFolderColor(0xFF2E7D5B), folderColors.first);
    expect(safeFolderColor(0xFF006064), const Color(0xFF006064));
  });
}
