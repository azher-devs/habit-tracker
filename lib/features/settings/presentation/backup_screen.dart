import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/backup/backup_providers.dart';
import '../../../core/backup/backup_exception.dart';
import '../../../core/backup/backup_service.dart';
import '../../../core/backup/backup_validator.dart';
import '../../../core/localization/gen/app_localizations.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.backupTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(l10n.backupDescription),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _busy ? null : _export,
                    icon: const Icon(Icons.file_upload_outlined),
                    label: Text(l10n.exportBackup),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _import,
                    icon: const Icon(Icons.file_download_outlined),
                    label: Text(l10n.importBackup),
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final service = ref.read(backupServiceProvider);
      final bytes = await service.exportBytes();
      if (!mounted) return;
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(RegExp(r'[^0-9]'), '')
          .substring(0, 8);
      final saved = await FilePicker.saveFile(
        dialogTitle: l10n.exportBackup,
        fileName: 'DayTracker_Backup_$timestamp.zip',
        type: FileType.custom,
        allowedExtensions: const ['zip'],
        bytes: bytes,
      );
      if (!mounted || saved == null) return;
      _showMessage(l10n.backupExported);
    } catch (_) {
      if (mounted) _showMessage(l10n.backupOperationFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['zip'],
        allowMultiple: false,
        withData: true,
      );
      if (!mounted || result == null) return;
      if (result.files.single.size > BackupValidator.maxArchiveBytes) {
        _showMessage(l10n.backupInvalid);
        return;
      }
      final bytes = result.files.single.bytes;
      if (bytes == null) {
        _showMessage(l10n.backupInvalid);
        return;
      }
      final document = BackupValidator.decode(bytes);
      final strategy = await showDialog<RestoreStrategy>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.backupImportTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.backupCounts(
                  document.folders.length,
                  document.entries.length,
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.backupReplaceSafety),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.backupCancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, RestoreStrategy.merge),
              child: Text(l10n.backupMerge),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, RestoreStrategy.replace),
              child: Text(l10n.backupReplace),
            ),
          ],
        ),
      );
      if (!mounted || strategy == null) return;
      await ref
          .read(backupServiceProvider)
          .restoreBytes(
            bytes,
            strategy: strategy,
            importedFolderSuffix: l10n.importedFolderSuffix,
          );
      if (!mounted) return;
      _showMessage(
        strategy == RestoreStrategy.replace
            ? l10n.backupRestored
            : l10n.backupMerged,
      );
    } on BackupFormatException {
      if (mounted) _showMessage(l10n.backupInvalid);
    } catch (_) {
      if (mounted) _showMessage(l10n.backupOperationFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
