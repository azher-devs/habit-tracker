import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/providers.dart';
import '../../../core/localization/gen/app_localizations.dart';
import '../providers/folder_providers.dart';
import 'folder_catalog.dart';
import 'folder_form_dialog.dart';

class FoldersScreen extends ConsumerWidget {
  const FoldersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final folders = ref.watch(activeFoldersProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.foldersTitle),
        actions: [
          IconButton(
            tooltip: l10n.addFolder,
            onPressed: () => _showForm(context),
            icon: const Icon(Icons.add),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
          ),
          PopupMenuButton<String>(
            tooltip: l10n.archivedFolders,
            onSelected: (value) {
              if (value == 'archived') context.push('/archived');
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'archived',
                child: Text(l10n.archivedFolders),
              ),
            ],
            icon: const Icon(Icons.more_vert),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: folders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) =>
            Center(child: Text(l10n.errorGeneric, textAlign: TextAlign.center)),
        data: (items) => items.isEmpty
            ? _EmptyFolders(onAdd: () => _showForm(context))
            : ReorderableListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                buildDefaultDragHandles: false,
                itemCount: items.length,
                onReorder: (oldIndex, newIndex) =>
                    _reorder(ref, items, oldIndex, newIndex),
                itemBuilder: (context, index) => Padding(
                  key: ValueKey(items[index].id),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _FolderCard(
                    folder: items[index],
                    index: index,
                    onEdit: () => _showForm(context, items[index]),
                    onArchive: () => _archive(context, ref, items[index]),
                  ),
                ),
              ),
      ),
    );
  }

  Future<void> _showForm(BuildContext context, [FolderRow? folder]) async {
    await showDialog<bool>(
      context: context,
      builder: (_) => FolderFormDialog(folder: folder),
    );
  }

  Future<void> _archive(
    BuildContext context,
    WidgetRef ref,
    FolderRow folder,
  ) async {
    final l10n = AppLocalizations.of(context);
    try {
      await ref.read(folderRepositoryProvider).setArchived(folder.id, true);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.genericSaveError)));
    }
  }

  Future<void> _reorder(
    WidgetRef ref,
    List<FolderRow> items,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex--;
    final reordered = [...items];
    final item = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, item);
    await ref
        .read(folderRepositoryProvider)
        .reorder(reordered.map((folder) => folder.id).toList());
  }
}

class _EmptyFolders extends StatelessWidget {
  const _EmptyFolders({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.track_changes_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 18),
            Text(
              l10n.emptyFoldersTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(l10n.emptyFoldersBody, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.addFolder),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderCard extends ConsumerWidget {
  const _FolderCard({
    required this.folder,
    required this.index,
    required this.onEdit,
    required this.onArchive,
  });

  final FolderRow folder;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final color = safeFolderColor(folder.color);
    final icon = folderIconFor(folder.iconCode);
    final counts = ref.watch(allTimeStatusCountsProvider);
    final countLabel = counts.when(
      data: (values) =>
          '${values[folder.id]?.recorded ?? 0} ${l10n.recordedDays}',
      loading: () => l10n.openCalendar,
      error: (_, _) => l10n.errorGeneric,
    );
    return Material(
      color: color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => context.push('/folders/${folder.id}'),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 12, 12),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  icon,
                  color: folderColorForeground(color),
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      countLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') onEdit();
                  if (value == 'archive') onArchive();
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'edit', child: Text(l10n.editFolder)),
                  PopupMenuItem(
                    value: 'archive',
                    child: Text(l10n.archiveFolder),
                  ),
                ],
              ),
              ReorderableDelayedDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(start: 4),
                  child: Icon(
                    Icons.drag_indicator,
                    color: color.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
