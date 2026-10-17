import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers.dart';
import '../../../core/localization/gen/app_localizations.dart';
import '../providers/folder_providers.dart';
import 'folder_catalog.dart';

class ArchivedFoldersScreen extends ConsumerWidget {
  const ArchivedFoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final folders = ref.watch(archivedFoldersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.archivedFolders)),
      body: folders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.errorGeneric)),
        data: (items) => items.isEmpty
            ? Center(child: Text(l10n.noArchivedFolders))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _ArchivedFolderTile(folder: items[index]),
              ),
      ),
    );
  }
}

class _ArchivedFolderTile extends ConsumerWidget {
  const _ArchivedFolderTile({required this.folder});

  final FolderRow folder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: safeFolderColor(
            folder.color,
          ).withValues(alpha: 0.15),
          foregroundColor: folderColorForeground(safeFolderColor(folder.color)),
          child: Icon(folderIconFor(folder.iconCode)),
        ),
        title: Text(folder.name),
        trailing: TextButton.icon(
          onPressed: () async {
            try {
              await ref
                  .read(folderRepositoryProvider)
                  .setArchived(folder.id, false);
            } catch (_) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.genericSaveError)));
            }
          },
          icon: const Icon(Icons.unarchive_outlined),
          label: Text(l10n.restoreFolder),
        ),
      ),
    );
  }
}
