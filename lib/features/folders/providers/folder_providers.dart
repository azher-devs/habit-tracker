import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers.dart';
import '../../daily_entry/data/entry_repository.dart';

final activeFoldersProvider = StreamProvider<List<FolderRow>>(
  (ref) => ref.watch(folderRepositoryProvider).watchActive(),
);

final archivedFoldersProvider = StreamProvider<List<FolderRow>>(
  (ref) => ref.watch(folderRepositoryProvider).watchArchived(),
);

final allTimeStatusCountsProvider = StreamProvider<Map<String, StatusCounts>>(
  (ref) => ref.watch(entryRepositoryProvider).watchAllTimeCounts(),
);
