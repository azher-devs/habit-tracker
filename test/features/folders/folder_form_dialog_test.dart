import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/database/app_database.dart';
import 'package:habit_tracker/core/database/providers.dart';
import 'package:habit_tracker/core/localization/gen/app_localizations.dart';
import 'package:habit_tracker/features/folders/data/folder_repository.dart';
import 'package:habit_tracker/features/folders/presentation/folder_form_dialog.dart';

void main() {
  testWidgets('editing a folder keeps its stored color and icon', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = FolderRepository(db);
    const storedColor = Color(0xFF006064);
    final id = await repository.create(
      name: 'صحة',
      color: storedColor.toARGB32(),
      iconCode: 'health',
    );
    final folder = (await repository.getById(id))!;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => FolderFormDialog(folder: folder),
                  ),
                  child: const Text('edit'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('edit'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.medical_services_outlined), findsOneWidget);
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    final saved = await repository.getById(id);
    expect(saved?.color, storedColor.toARGB32());
    expect(saved?.iconCode, 'health');
  });
}
