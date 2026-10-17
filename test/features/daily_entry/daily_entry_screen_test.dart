import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/database/app_database.dart';
import 'package:habit_tracker/core/database/providers.dart';
import 'package:habit_tracker/core/localization/gen/app_localizations.dart';
import 'package:habit_tracker/core/theme/app_theme.dart';
import 'package:habit_tracker/features/daily_entry/data/entry_repository.dart';
import 'package:habit_tracker/features/daily_entry/domain/entry_status.dart';
import 'package:habit_tracker/features/daily_entry/presentation/daily_entry_screen.dart';
import 'package:habit_tracker/features/daily_entry/providers/daily_entry_providers.dart';
import 'package:habit_tracker/features/folders/data/folder_repository.dart';

class _TrackingEntryRepository extends EntryRepository {
  _TrackingEntryRepository(super.db);

  int saveCalls = 0;
  bool failSaves = false;
  Completer<void>? saveGate;

  @override
  Future<void> saveEntry(
    String folderId,
    String date, {
    required EntryStatus? status,
    required String? notesJson,
  }) async {
    saveCalls++;
    await saveGate?.future;
    if (failSaves) throw StateError('test save failure');
    await super.saveEntry(folderId, date, status: status, notesJson: notesJson);
  }
}

class _TestData {
  const _TestData({
    required this.db,
    required this.folderId,
    required this.repo,
  });

  final AppDatabase db;
  final String folderId;
  final _TrackingEntryRepository repo;
}

Future<_TestData> _pumpDailyEntry(
  WidgetTester tester, {
  String? notesJson,
  EntryStatus? status,
}) async {
  final db = AppDatabase(NativeDatabase.memory());
  final folderId = await FolderRepository(
    db,
  ).create(name: 'الرياضة', color: 0xFF2E9E57);
  final repo = _TrackingEntryRepository(db);
  if (notesJson != null || status != null) {
    await repo.saveEntry(
      folderId,
      '2026-10-12',
      status: status,
      notesJson: notesJson,
    );
    repo.saveCalls = 0;
  }
  final initialEntry = await repo.getEntry(folderId, '2026-10-12');
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await db.close();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        dailyEntryProvider((
          folderId: folderId,
          date: '2026-10-12',
        )).overrideWith((ref) => Stream.value(initialEntry)),
        entryRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FlutterQuillLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Previous screen'),
                  TextButton(
                    key: const ValueKey('open-day'),
                    onPressed: () => Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (_) => DailyEntryScreen(
                          folderId: folderId,
                          date: '2026-10-12',
                        ),
                      ),
                    ),
                    child: const Text('Open day'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(const ValueKey('open-day')));
  for (var frame = 0; frame < 8; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  return _TestData(db: db, folderId: folderId, repo: repo);
}

Finder get _saveButton => find.byKey(const ValueKey('save-daily-entry'));

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Arabic text remains editable through rebuilds with a stable caret',
    (tester) async {
      final data = await _pumpDailyEntry(
        tester,
        notesJson: '[{"insert":"مرحبا بالعالم\\n"}]',
      );

      final editorFinder = find.byType(QuillEditor);
      final initialEditor = tester.widget<QuillEditor>(editorFinder);
      await tester.tap(editorFinder);
      await tester.pump();
      expect(initialEditor.focusNode.hasFocus, isTrue);

      final controller = initialEditor.controller;
      controller.updateSelection(
        const TextSelection.collapsed(offset: 6),
        ChangeSource.local,
      );
      await tester.pump();
      expect(controller.selection.baseOffset, 6);

      controller.replaceText(
        6,
        0,
        'جديد',
        const TextSelection.collapsed(offset: 10),
      );
      await tester.pump();

      final rebuiltEditor = tester.widget<QuillEditor>(editorFinder);
      expect(identical(rebuiltEditor.controller, controller), isTrue);
      expect(
        identical(rebuiltEditor.focusNode, initialEditor.focusNode),
        isTrue,
      );
      expect(
        identical(
          rebuiltEditor.scrollController,
          initialEditor.scrollController,
        ),
        isTrue,
      );
      expect(rebuiltEditor.focusNode.hasFocus, isTrue);
      expect(rebuiltEditor.controller.selection.baseOffset, 10);
      expect(controller.document.toPlainText(), contains('مرحبا جديدبالعالم'));

      controller.replaceText(
        6,
        4,
        '',
        const TextSelection.collapsed(offset: 6),
      );
      await tester.pump();
      expect(controller.document.toPlainText(), 'مرحبا بالعالم\n');
      expect(data.repo.saveCalls, 0);
    },
  );

  testWidgets(
    'keyboard input and backspace edit mixed Arabic and English text',
    (tester) async {
      final data = await _pumpDailyEntry(tester);
      final editor = tester.widget<QuillEditor>(find.byType(QuillEditor));

      await tester.tap(find.byType(QuillEditor));
      await tester.pump();
      expect(editor.focusNode.hasFocus, isTrue);

      tester.testTextInput.enterText('مرحبا English');
      await tester.pump();
      expect(editor.controller.document.toPlainText(), 'مرحبا English\n');

      editor.controller.updateSelection(
        const TextSelection(baseOffset: 6, extentOffset: 7),
        ChangeSource.local,
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pump();
      expect(editor.controller.document.toPlainText(), 'مرحبا nglish\n');
      expect(data.repo.saveCalls, 0);
    },
  );

  testWidgets(
    'formatting toolbar stays available for selections with keyboard open or closed',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const note = 'بداية النص في المنتصف والنهاية';
      await _pumpDailyEntry(tester, notesJson: '[{"insert":"$note\\n"}]');

      final editorFinder = find.byType(QuillEditor);
      final boldFinder = find.byIcon(Icons.format_bold);
      const selections = [
        TextSelection(baseOffset: 0, extentOffset: 4),
        TextSelection(baseOffset: 9, extentOffset: 14),
        TextSelection(
          baseOffset: note.length - 8,
          extentOffset: note.length - 1,
        ),
      ];

      for (final keyboardOpen in [false, true]) {
        tester.view.viewInsets = FakeViewPadding(
          bottom: keyboardOpen ? 300 : 0,
        );
        await tester.pumpAndSettle();

        final editor = tester.widget<QuillEditor>(editorFinder);
        final editorConfig = editor.config;
        expect(editorConfig.enableInteractiveSelection, isTrue);
        expect(editorConfig.enableSelectionToolbar, isTrue);
        expect(editorConfig.padding.resolve(TextDirection.rtl).top, 64);

        await tester.tap(editorFinder);
        await tester.pump();
        for (final selection in selections) {
          editor.controller.updateSelection(selection, ChangeSource.local);
          await tester.pump();

          expect(boldFinder, findsOneWidget);
          final toolbarRect = tester.getRect(find.byType(QuillSimpleToolbar));
          expect(toolbarRect.top, greaterThanOrEqualTo(0));
          expect(toolbarRect.bottom, lessThan(844 - (keyboardOpen ? 300 : 0)));

          await tester.ensureVisible(boldFinder);
          await tester.pumpAndSettle();
          final boldRect = tester.getRect(boldFinder);
          expect(boldRect.left, greaterThanOrEqualTo(0));
          expect(boldRect.right, lessThanOrEqualTo(390));
          expect(editor.controller.selection, selection);
          final boldButton = tester.widget<IconButton>(
            find
                .ancestor(of: boldFinder, matching: find.byType(IconButton))
                .first,
          );
          expect(boldButton.onPressed, isNotNull);
          expect(boldRect.overlaps(toolbarRect), isTrue);
          editor.controller.formatSelection(Attribute.bold);
          expect(
            editor.controller.document.toDelta().toJson().toString(),
            contains('bold'),
          );
        }
      }
    },
  );

  testWidgets('status and typing stay local until Save commits both fields', (
    tester,
  ) async {
    final data = await _pumpDailyEntry(tester);

    await tester.tap(find.text('مكتمل'));
    await tester.pump();
    final controller = tester
        .widget<QuillEditor>(find.byType(QuillEditor))
        .controller;
    controller.replaceText(
      0,
      0,
      'تمرين اليوم: رائع',
      const TextSelection.collapsed(offset: 17),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(data.repo.saveCalls, 0);
    expect(await data.repo.getEntry(data.folderId, '2026-10-12'), isNull);

    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    final saved = await data.repo.getEntry(data.folderId, '2026-10-12');
    expect(saved?.status, EntryStatus.completed.value);
    expect(saved?.notesJson, contains('تمرين اليوم: رائع'));
    expect(data.repo.saveCalls, 1);
    expect(find.text('Previous screen'), findsOneWidget);
    expect(find.text('تم الحفظ بنجاح'), findsOneWidget);
  });

  testWidgets('unsaved status asks before exit and discard writes nothing', (
    tester,
  ) async {
    final data = await _pumpDailyEntry(tester);

    await tester.tap(find.text('مكتمل'));
    await tester.pump();
    expect(await data.repo.getEntry(data.folderId, '2026-10-12'), isNull);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('تغييرات غير محفوظة'),
      ),
      findsOneWidget,
    );
    expect(
      find.text('لديك تغييرات غير محفوظة. هل تريد الخروج دون حفظ؟'),
      findsOneWidget,
    );

    await tester.tap(find.text('العودة للتعديل'));
    await tester.pumpAndSettle();
    expect(find.byType(QuillEditor), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('الخروج دون حفظ'));
    await tester.pumpAndSettle();

    expect(find.text('Previous screen'), findsOneWidget);
    expect(await data.repo.getEntry(data.folderId, '2026-10-12'), isNull);
    expect(data.repo.saveCalls, 0);
  });

  testWidgets('leaving an unchanged entry does not show a warning', (
    tester,
  ) async {
    final data = await _pumpDailyEntry(tester);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Previous screen'), findsOneWidget);
    expect(find.text('تغييرات غير محفوظة'), findsNothing);
    expect(data.repo.saveCalls, 0);
  });

  testWidgets('failed Save keeps the editor and edits available for retry', (
    tester,
  ) async {
    final data = await _pumpDailyEntry(tester);
    data.repo.failSaves = true;

    final controller = tester
        .widget<QuillEditor>(find.byType(QuillEditor))
        .controller;
    controller.replaceText(
      0,
      0,
      'ملاحظة تبقى هنا',
      const TextSelection.collapsed(offset: 15),
    );
    await tester.pump();
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();

    expect(find.byType(QuillEditor), findsOneWidget);
    expect(find.textContaining('تعذر حفظ التغييرات'), findsOneWidget);
    expect(controller.document.toPlainText(), contains('ملاحظة تبقى هنا'));
    expect(await data.repo.getEntry(data.folderId, '2026-10-12'), isNull);

    data.repo.failSaves = false;
    await tester.tap(_saveButton);
    await tester.pumpAndSettle();
    expect(find.text('Previous screen'), findsOneWidget);
    expect(data.repo.saveCalls, 2);
  });

  testWidgets('repeated Save taps cannot overlap an active write', (
    tester,
  ) async {
    final data = await _pumpDailyEntry(tester);
    final gate = Completer<void>();
    data.repo.saveGate = gate;

    final controller = tester
        .widget<QuillEditor>(find.byType(QuillEditor))
        .controller;
    controller.replaceText(
      0,
      0,
      'مرة واحدة',
      const TextSelection.collapsed(offset: 9),
    );
    await tester.pump();
    await tester.tap(_saveButton);
    await tester.pump();
    await tester.tap(_saveButton, warnIfMissed: false);
    await tester.pump();
    expect(data.repo.saveCalls, 1);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('Previous screen'), findsOneWidget);
    expect(data.repo.saveCalls, 1);
  });
}
