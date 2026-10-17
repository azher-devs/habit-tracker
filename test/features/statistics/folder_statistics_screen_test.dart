import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:habit_tracker/core/database/app_database.dart';
import 'package:habit_tracker/core/database/providers.dart';
import 'package:habit_tracker/core/localization/gen/app_localizations.dart';
import 'package:habit_tracker/core/theme/app_theme.dart';
import 'package:habit_tracker/core/utils/date_key.dart';
import 'package:habit_tracker/features/daily_entry/domain/entry_status.dart';
import 'package:habit_tracker/features/folders/data/folder_repository.dart';
import 'package:habit_tracker/features/statistics/domain/monthly_summary_builder.dart';
import 'package:habit_tracker/features/statistics/presentation/folder_statistics_screen.dart';
import 'package:habit_tracker/features/statistics/providers/statistics_providers.dart';

class _FixedFolderRepository extends FolderRepository {
  _FixedFolderRepository(super.db, this.folder);

  final FolderRow folder;

  @override
  Stream<FolderRow?> watchById(String id) =>
      Stream.value(id == folder.id ? folder : null);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('note cards show saved statuses and open the matching day', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await db.close();
    });
    final folders = FolderRepository(db);
    final folderId = await folders.create(name: 'الرياضة', color: 0xFF2E9E57);
    final folder = (await folders.getById(folderId))!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, 20);
    final dates = [
      for (var day = 1; day <= 4; day++)
        DateKey.fromDate(DateTime.utc(now.year, now.month, day)),
    ];
    final summary = MonthlySummaryBuilder.build(
      year: now.year,
      month: now.month,
      today: today,
      allStatuses: {
        dates[0]: EntryStatus.completed,
        dates[1]: EntryStatus.missed,
      },
      monthEntries: [
        SummaryEntry(
          date: dates[0],
          status: EntryStatus.completed,
          notesJson: '[{"insert":"ملاحظة مكتملة\\n"}]',
        ),
        SummaryEntry(
          date: dates[1],
          status: EntryStatus.missed,
          notesJson: '[{"insert":"ملاحظة لم تكتمل\\n"}]',
        ),
        SummaryEntry(
          date: dates[2],
          status: null,
          notesJson: '[{"insert":"ملاحظة دون تسجيل\\n"}]',
        ),
        SummaryEntry(
          date: dates[3],
          status: EntryStatus.completed,
          notesJson: '[{"insert":"\\n"}]',
        ),
      ],
    );
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: '/folders/$folderId/statistics',
      routes: [
        GoRoute(
          path: '/folders/:folderId',
          builder: (context, state) => const Scaffold(),
          routes: [
            GoRoute(
              path: 'statistics',
              builder: (context, state) => FolderStatisticsScreen(
                folderId: state.pathParameters['folderId']!,
              ),
            ),
            GoRoute(
              path: 'day/:date',
              builder: (context, state) => Scaffold(
                body: Text('opened:${state.pathParameters['date']}'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          folderRepositoryProvider.overrideWithValue(
            _FixedFolderRepository(db, folder),
          ),
          localTodayProvider.overrideWith((ref) => Stream.value(today)),
          monthlySummaryProvider((
            folderId: folderId,
            year: now.year,
            month: now.month,
            todayKey: DateKey.fromDate(today),
          )).overrideWith((ref) => Stream.value(summary)),
        ],
        child: MaterialApp.router(
          locale: const Locale('ar'),
          supportedLocales: const [Locale('ar')],
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          routerConfig: router,
        ),
      ),
    );
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text('تفاصيل الإحصائيات'));
    await tester.pumpAndSettle();

    for (final (index, label, icon) in [
      (0, 'مكتمل', Icons.check_circle),
      (1, 'لم يكتمل', Icons.cancel),
      (2, 'بدون تسجيل', Icons.radio_button_unchecked),
    ]) {
      final card = find.byKey(ValueKey('monthly-note-${dates[index]}'));
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text(label)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.byIcon(icon)),
        findsOneWidget,
      );
    }
    expect(find.byKey(ValueKey('monthly-note-${dates[3]}')), findsNothing);

    final completedCard = find.byKey(ValueKey('monthly-note-${dates[0]}'));
    await tester.tap(completedCard);
    await tester.pumpAndSettle();
    expect(find.text('opened:${dates[0]}'), findsOneWidget);
  });
}
