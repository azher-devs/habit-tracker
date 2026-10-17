import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/database/providers.dart';
import '../../../core/localization/gen/app_localizations.dart';
import '../../../core/theme/status_colors.dart';
import '../../../core/utils/date_key.dart';
import '../domain/entry_status.dart';
import '../domain/notes_codec.dart';
import '../providers/daily_entry_providers.dart';

/// Keeps platform text-input diffs inside Quill's editable range.
///
/// Quill documents always end with a newline. Some keyboards report a
/// replacement at `document.length`, which is after that newline and is not a
/// valid insertion point. Treat it as an edit immediately before the newline.
class _DailyEntryQuillController extends QuillController {
  _DailyEntryQuillController({
    required super.document,
    required super.selection,
  });

  @override
  void replaceText(
    int index,
    int len,
    Object? data,
    TextSelection? textSelection, {
    bool ignoreFocus = false,
    bool shouldNotifyListeners = true,
  }) {
    final editableEnd = document.length - 1;
    final safeIndex = index.clamp(0, editableEnd);
    final safeLength = len.clamp(0, editableEnd - safeIndex);
    super.replaceText(
      safeIndex,
      safeLength,
      data,
      textSelection,
      ignoreFocus: ignoreFocus,
      // ignore: experimental_member_use
      shouldNotifyListeners: shouldNotifyListeners,
    );
  }
}

class DailyEntryScreen extends ConsumerWidget {
  const DailyEntryScreen({
    super.key,
    required this.folderId,
    required this.date,
  });

  final String folderId;
  final String date;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (!DateKey.isValid(date)) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.dayDetails)),
        body: Center(child: Text(l10n.errorInvalidDate)),
      );
    }

    final entry = ref.watch(
      dailyEntryProvider((folderId: folderId, date: date)),
    );
    return entry.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.dayDetails)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.dayDetails)),
        body: Center(child: Text(l10n.errorGeneric)),
      ),
      data: (row) => _DailyEntryEditor(
        key: ValueKey('$folderId/$date'),
        folderId: folderId,
        date: date,
        notesJson: row?.notesJson,
        status: EntryStatus.fromValue(row?.status),
      ),
    );
  }
}

class _DailyEntryEditor extends ConsumerStatefulWidget {
  const _DailyEntryEditor({
    super.key,
    required this.folderId,
    required this.date,
    required this.notesJson,
    required this.status,
  });

  final String folderId;
  final String date;
  final String? notesJson;
  final EntryStatus? status;

  @override
  ConsumerState<_DailyEntryEditor> createState() => _DailyEntryEditorState();
}

class _DailyEntryEditorState extends ConsumerState<_DailyEntryEditor> {
  late final QuillController _quillController;
  late final FocusNode _editorFocusNode;
  late final ScrollController _editorScrollController;
  late final StreamSubscription<dynamic> _documentSubscription;

  late EntryStatus? _originalStatus;
  late EntryStatus? _selectedStatus;
  late String? _originalNotesJson;
  late String _baselineDocumentSignature;
  late String _lastDocumentSignature;

  bool _notesLoadFailed = false;
  bool _isSaving = false;
  bool _saveFailed = false;
  bool _allowPop = false;
  bool _leaveDialogOpen = false;

  @override
  void initState() {
    super.initState();
    _originalStatus = widget.status;
    _selectedStatus = widget.status;
    _originalNotesJson = widget.notesJson;

    final document = _loadDocument(widget.notesJson);
    _quillController = _DailyEntryQuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _editorFocusNode = FocusNode(debugLabel: 'daily-notes-editor');
    _editorScrollController = ScrollController();
    _baselineDocumentSignature = _documentSignature;
    _lastDocumentSignature = _baselineDocumentSignature;

    _documentSubscription = _quillController.document.changes.listen((_) {
      final signature = _documentSignature;
      if (signature == _lastDocumentSignature) return;
      _lastDocumentSignature = signature;
      if (mounted) {
        setState(() => _saveFailed = false);
      }
    });
  }

  Document _loadDocument(String? notesJson) {
    try {
      return Document.fromJson(NotesCodec.decode(notesJson));
    } catch (_) {
      _notesLoadFailed = true;
      return Document();
    }
  }

  String get _documentSignature =>
      jsonEncode(_quillController.document.toDelta().toJson());

  bool get _hasUnsavedChanges =>
      _selectedStatus != _originalStatus ||
      _documentSignature != _baselineDocumentSignature;

  @override
  void dispose() {
    unawaited(_documentSubscription.cancel());
    _quillController.dispose();
    _editorFocusNode.dispose();
    _editorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateLabel = DateFormat.yMMMMd(
      Localizations.localeOf(context).toString(),
    ).format(DateKey.parse(widget.date));
    final theme = Theme.of(context);

    return PopScope(
      canPop: (!_hasUnsavedChanges && !_isSaving) || _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_allowPop) unawaited(_confirmLeave());
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(l10n.dayDetails),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(34),
            child: Padding(
              padding: const EdgeInsetsDirectional.only(bottom: 10),
              child: Text(
                dateLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              IgnorePointer(
                ignoring: _isSaving,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 8),
                  child: _StatusSection(
                    selectedStatus: _selectedStatus,
                    changed: _hasUnsavedChanges,
                    onChanged: (status) {
                      setState(() {
                        _selectedStatus = status;
                        _saveFailed = false;
                      });
                    },
                  ),
                ),
              ),
              if (_notesLoadFailed)
                _MessageBanner(
                  message: l10n.notesLoadWarning,
                  color: theme.colorScheme.errorContainer,
                  foreground: theme.colorScheme.onErrorContainer,
                ),
              if (_saveFailed)
                _MessageBanner(
                  message: l10n.saveFailed,
                  color: theme.colorScheme.errorContainer,
                  foreground: theme.colorScheme.onErrorContainer,
                ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(18, 4, 18, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.description_outlined,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.notesTitle,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (_hasUnsavedChanges) ...[
                      Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: theme.colorScheme.tertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.unsavedChangesLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: IgnorePointer(
                  ignoring: _isSaving,
                  child: Card(
                    margin: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 8),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 50,
                          child: QuillSimpleToolbar(
                            controller: _quillController,
                            config: QuillSimpleToolbarConfig(
                              multiRowsDisplay: false,
                              showFontFamily: false,
                              showFontSize: false,
                              showBoldButton: true,
                              showItalicButton: true,
                              showUnderLineButton: true,
                              showStrikeThrough: false,
                              showInlineCode: false,
                              showColorButton: false,
                              showBackgroundColorButton: false,
                              showClearFormat: false,
                              showAlignmentButtons: false,
                              showHeaderStyle: true,
                              showListNumbers: true,
                              showListBullets: true,
                              showListCheck: false,
                              showCodeBlock: false,
                              showQuote: false,
                              showIndent: false,
                              showLink: false,
                              showUndo: true,
                              showRedo: true,
                              showSearchButton: false,
                              showSubscript: false,
                              showSuperscript: false,
                            ),
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: theme.colorScheme.outlineVariant,
                        ),
                        Expanded(
                          child: TextSelectionTheme(
                            data: TextSelectionThemeData(
                              cursorColor: theme.colorScheme.primary,
                              selectionColor: theme.colorScheme.primary
                                  .withValues(alpha: 0.26),
                              selectionHandleColor: theme.colorScheme.primary,
                            ),
                            child: QuillEditor.basic(
                              controller: _quillController,
                              focusNode: _editorFocusNode,
                              scrollController: _editorScrollController,
                              config: QuillEditorConfig(
                                // Leave room for Android's native selection
                                // toolbar above the first line. This keeps it
                                // inside the editor instead of over the fixed
                                // formatting controls.
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                  16,
                                  64,
                                  16,
                                  16,
                                ),
                                placeholder: l10n.notesPlaceholder,
                                enableInteractiveSelection: true,
                                enableSelectionToolbar: true,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(14, 0, 14, 10),
                  child: SizedBox(
                    height: 56,
                    child: FilledButton.icon(
                      key: const ValueKey('save-daily-entry'),
                      onPressed: _isSaving ? null : () => unawaited(_save()),
                      icon: _isSaving
                          ? const SizedBox.square(
                              dimension: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: Text(
                        _isSaving ? l10n.saving : l10n.saveNotesNow,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final selectedStatus = _selectedStatus;
    final successMessage = AppLocalizations.of(context).saveSucceeded;

    setState(() {
      _isSaving = true;
      _saveFailed = false;
    });
    _editorFocusNode.unfocus();

    try {
      final documentSignature = _documentSignature;
      final notesJson = documentSignature == _baselineDocumentSignature
          ? _originalNotesJson
          : NotesCodec.encode(_quillController.document.toDelta().toJson());
      await ref
          .read(entryRepositoryProvider)
          .saveEntry(
            widget.folderId,
            widget.date,
            status: selectedStatus,
            notesJson: notesJson,
          );
      if (!mounted) return;

      setState(() {
        _originalStatus = selectedStatus;
        _originalNotesJson = notesJson;
        _baselineDocumentSignature = documentSignature;
        _isSaving = false;
      });

      final messenger = ScaffoldMessenger.of(context);
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveFailed = true;
      });
    }
  }

  Future<void> _confirmLeave() async {
    if (!mounted || _isSaving || !_hasUnsavedChanges || _leaveDialogOpen) {
      return;
    }
    _leaveDialogOpen = true;
    final l10n = AppLocalizations.of(context);
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.unsavedChangesTitle),
        content: Text(l10n.unsavedChangesMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.continueEditing),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.discardChanges),
          ),
        ],
      ),
    );
    _leaveDialogOpen = false;
    if (discard != true || !mounted) return;

    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.of(context).pop();
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({
    required this.selectedStatus,
    required this.changed,
    required this.onChanged,
  });

  final EntryStatus? selectedStatus;
  final bool changed;
  final ValueChanged<EntryStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.statusColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.dailyStatus,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (changed)
              Tooltip(
                message: l10n.unsavedChangesLabel,
                child: Icon(
                  Icons.circle,
                  size: 9,
                  color: theme.colorScheme.tertiary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            Expanded(
              child: _DailyStatusButton(
                icon: Icons.check_circle_outline,
                selectedIcon: Icons.check_circle,
                label: l10n.completed,
                color: colors.completed,
                selected: selectedStatus == EntryStatus.completed,
                onTap: () => onChanged(
                  selectedStatus == EntryStatus.completed
                      ? null
                      : EntryStatus.completed,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _DailyStatusButton(
                icon: Icons.cancel_outlined,
                selectedIcon: Icons.cancel,
                label: l10n.missed,
                color: colors.missed,
                selected: selectedStatus == EntryStatus.missed,
                onTap: () => onChanged(
                  selectedStatus == EntryStatus.missed
                      ? null
                      : EntryStatus.missed,
                ),
              ),
            ),
          ],
        ),
        if (selectedStatus != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.remove_circle_outline, size: 18),
              label: Text(l10n.clearStatus),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsetsDirectional.only(start: 4, end: 8),
              ),
            ),
          ),
      ],
    );
  }
}

class _DailyStatusButton extends StatelessWidget {
  const _DailyStatusButton({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected
            ? color.withValues(
                alpha: theme.brightness == Brightness.dark ? 0.22 : 0.12,
              )
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: selected ? color : theme.colorScheme.outlineVariant,
                width: selected ? 1.7 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(selected ? selectedIcon : icon, color: color, size: 23),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.message,
    required this.color,
    required this.foreground,
  });

  final String message;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.fromSTEB(14, 4, 14, 8),
    child: Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: foreground, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: foreground)),
          ),
        ],
      ),
    ),
  );
}
