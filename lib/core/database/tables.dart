import 'package:drift/drift.dart';

@DataClassName('FolderRow')
@TableIndex(name: 'idx_folders_sort', columns: {#isArchived, #sortOrder})
class Folders extends Table {
  /// UUID v4, stable across renames and backups.
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 60)();

  /// ARGB color value chosen by the user.
  IntColumn get color => integer()();

  /// Stable icon key (see folder icon catalog), not a raw code point.
  TextColumn get iconCode => text().nullable()();
  IntColumn get sortOrder => integer()();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DailyEntryRow')
@TableIndex(name: 'idx_entries_date', columns: {#entryDate})
class DailyEntries extends Table {
  TextColumn get id => text()();

  /// Deleting a folder permanently removes its entries; archiving never
  /// deletes anything.
  TextColumn get folderId =>
      text().references(Folders, #id, onDelete: KeyAction.cascade)();

  /// Normalized `YYYY-MM-DD` calendar date, independent of timezone.
  TextColumn get entryDate => text().withLength(min: 10, max: 10)();

  /// 1 = completed, 2 = missed, NULL = no status (notes only).
  IntColumn get status =>
      // ignore: recursive_getters
      integer().nullable().check(status.isNull() | status.isIn(const [1, 2]))();

  /// Quill document delta as JSON text.
  TextColumn get notesJson => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {folderId, entryDate},
  ];
}

@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
