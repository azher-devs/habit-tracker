import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers.dart';

typedef DailyEntryKey = ({String folderId, String date});

final dailyEntryProvider = StreamProvider.autoDispose
    .family<DailyEntryRow?, DailyEntryKey>(
      (ref, key) =>
          ref.watch(entryRepositoryProvider).watchEntry(key.folderId, key.date),
    );
