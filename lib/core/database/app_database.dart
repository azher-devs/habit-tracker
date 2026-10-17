import 'package:drift/drift.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Folders, DailyEntries, AppSettings])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  /// Bump this and add a step in [migration] whenever the schema changes.
  static const int currentSchemaVersion = 1;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      // No upgrade steps exist yet (schema v1 is the first release).
      // Future versions must add explicit, data-preserving steps here.
    },
    beforeOpen: (details) async {
      // SQLite ignores foreign keys unless enabled per connection.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
