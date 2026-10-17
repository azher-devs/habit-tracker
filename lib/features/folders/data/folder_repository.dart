import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/validation.dart';

class FolderRepository {
  FolderRepository(this._db, {Uuid? uuid, DateTime Function()? now})
    : _uuid = uuid ?? const Uuid(),
      _now = now ?? DateTime.now;

  final AppDatabase _db;
  final Uuid _uuid;
  final DateTime Function() _now;

  Stream<List<FolderRow>> watchActive() => _watchByArchived(false);

  Stream<List<FolderRow>> watchArchived() => _watchByArchived(true);

  Stream<List<FolderRow>> _watchByArchived(bool archived) {
    final query = _db.select(_db.folders)
      ..where((t) => t.isArchived.equals(archived))
      ..orderBy([
        (t) => OrderingTerm.asc(t.sortOrder),
        (t) => OrderingTerm.asc(t.createdAt),
      ]);
    return query.watch();
  }

  Stream<FolderRow?> watchById(String id) => (_db.select(
    _db.folders,
  )..where((t) => t.id.equals(id))).watchSingleOrNull();

  Future<FolderRow?> getById(String id) => (_db.select(
    _db.folders,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<FolderRow>> getAll() => (_db.select(
    _db.folders,
  )..orderBy([(t) => OrderingTerm.asc(t.sortOrder)])).get();

  /// Restore helpers. Call from a surrounding database transaction.
  Future<void> deleteAllForRestore() => _db.delete(_db.folders).go();

  Future<void> insertRestored(Iterable<FoldersCompanion> rows) async {
    for (final row in rows) {
      await _db.into(_db.folders).insert(row);
    }
  }

  /// Creates a folder at the end of the list and returns its identifier.
  Future<String> create({
    required String name,
    required int color,
    String? iconCode,
  }) async {
    final cleanName = validateFolderName(name);
    final id = _uuid.v4();
    final now = _now();
    await _db.transaction(() async {
      final order = await _nextSortOrder();
      await _db
          .into(_db.folders)
          .insert(
            FoldersCompanion.insert(
              id: id,
              name: cleanName,
              color: color,
              iconCode: Value(iconCode),
              sortOrder: order,
              createdAt: now,
              updatedAt: now,
            ),
          );
    });
    return id;
  }

  /// Updates presentation fields only; daily entries are never touched.
  Future<void> update(
    String id, {
    String? name,
    int? color,
    Value<String?> iconCode = const Value.absent(),
  }) async {
    final cleanName = name == null ? null : validateFolderName(name);
    await (_db.update(_db.folders)..where((t) => t.id.equals(id))).write(
      FoldersCompanion(
        name: cleanName == null ? const Value.absent() : Value(cleanName),
        color: color == null ? const Value.absent() : Value(color),
        iconCode: iconCode,
        updatedAt: Value(_now()),
      ),
    );
  }

  /// Persists the given order (index becomes the new sort order).
  Future<void> reorder(List<String> orderedIds) => _db.transaction(() async {
    for (var i = 0; i < orderedIds.length; i++) {
      await (_db.update(_db.folders)..where((t) => t.id.equals(orderedIds[i])))
          .write(FoldersCompanion(sortOrder: Value(i)));
    }
  });

  /// Archives or restores a folder. All entries are preserved either way.
  Future<void> setArchived(String id, bool archived) =>
      _db.transaction(() async {
        final order = archived ? null : await _nextSortOrder();
        await (_db.update(_db.folders)..where((t) => t.id.equals(id))).write(
          FoldersCompanion(
            isArchived: Value(archived),
            sortOrder: order == null ? const Value.absent() : Value(order),
            updatedAt: Value(_now()),
          ),
        );
      });

  /// Irreversibly deletes the folder and (via cascade) all of its entries.
  Future<void> deletePermanently(String id) =>
      (_db.delete(_db.folders)..where((t) => t.id.equals(id))).go();

  Future<int> _nextSortOrder() async {
    final row = await _db
        .customSelect('SELECT COALESCE(MAX(sort_order), -1) AS m FROM folders')
        .getSingle();
    return row.read<int>('m') + 1;
  }
}
