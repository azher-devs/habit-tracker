import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;

import '../../../core/database/app_database.dart';
import '../../../core/database/providers.dart';
import '../../../core/localization/gen/app_localizations.dart';
import '../../../core/utils/validation.dart';
import 'folder_catalog.dart';

export 'folder_catalog.dart' show folderIcons;

class FolderFormDialog extends ConsumerStatefulWidget {
  const FolderFormDialog({super.key, this.folder});

  final FolderRow? folder;

  @override
  ConsumerState<FolderFormDialog> createState() => _FolderFormDialogState();
}

class _FolderFormDialogState extends ConsumerState<FolderFormDialog> {
  late final TextEditingController _nameController;
  late Color _color;
  late String _icon;
  late final TextEditingController _iconSearchController;
  String _iconSearch = '';
  FolderIconCategory? _iconCategory;
  bool _saving = false;

  bool get _editing => widget.folder != null;

  @override
  void initState() {
    super.initState();
    final folder = widget.folder;
    _nameController = TextEditingController(text: folder?.name ?? '');
    _color = safeFolderColor(folder?.color);
    _icon = folderIcons.containsKey(folder?.iconCode)
        ? folder!.iconCode!
        : 'check';
    _iconSearchController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _iconSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(_editing ? l10n.editFolder : l10n.addFolder),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              maxLength: 60,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(labelText: l10n.folderName),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.chooseColor,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            for (final family in FolderColorFamily.values)
              _buildColorFamily(context, l10n, family),
            if (!folderColors.any(
              (color) => color.toARGB32() == _color.toARGB32(),
            ))
              _buildColorGrid(context, l10n, [_color], l10n.colorFamilyCustom),
            const SizedBox(height: 20),
            Text(
              l10n.chooseIcon,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _iconSearchController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                hintText: l10n.searchFolderIcons,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _iconSearch = value.trim()),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: Text(l10n.allFolderIcons),
                  selected: _iconCategory == null,
                  onSelected: (_) => setState(() => _iconCategory = null),
                ),
                for (final category in FolderIconCategory.values)
                  ChoiceChip(
                    label: Text(_categoryLabel(l10n, category)),
                    selected: _iconCategory == category,
                    onSelected: (_) => setState(() => _iconCategory = category),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (!_hasMatchingIcon)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(l10n.noFolderIconsFound),
              )
            else
              for (final category in FolderIconCategory.values)
                if (_iconCategory == null || _iconCategory == category)
                  _buildIconCategory(context, l10n, category),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.save),
        ),
      ],
    );
  }

  Widget _buildColorFamily(
    BuildContext context,
    AppLocalizations l10n,
    FolderColorFamily family,
  ) => _buildColorGrid(
    context,
    l10n,
    folderColorsInFamily(family),
    _colorFamilyLabel(l10n, family),
  );

  Widget _buildColorGrid(
    BuildContext context,
    AppLocalizations l10n,
    List<Color> colors,
    String label,
  ) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsetsDirectional.only(start: 4, top: 3),
        child: Text(label, style: Theme.of(context).textTheme.labelSmall),
      ),
      Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final color in colors)
            SizedBox.square(
              dimension: 38,
              child: Semantics(
                label: label,
                selected: _color.toARGB32() == color.toARGB32(),
                child: InkWell(
                  onTap: () => setState(() => _color = color),
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: color,
                      child: _color.toARGB32() == color.toARGB32()
                          ? Icon(
                              Icons.check,
                              color: folderColorForeground(color),
                              size: 18,
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ],
  );

  String _colorFamilyLabel(AppLocalizations l10n, FolderColorFamily family) =>
      switch (family) {
        FolderColorFamily.green => l10n.colorFamilyGreen,
        FolderColorFamily.teal => l10n.colorFamilyTeal,
        FolderColorFamily.blue => l10n.colorFamilyBlue,
        FolderColorFamily.cyan => l10n.colorFamilyCyan,
        FolderColorFamily.indigo => l10n.colorFamilyIndigo,
        FolderColorFamily.purple => l10n.colorFamilyPurple,
        FolderColorFamily.pink => l10n.colorFamilyPink,
        FolderColorFamily.red => l10n.colorFamilyRed,
        FolderColorFamily.orange => l10n.colorFamilyOrange,
        FolderColorFamily.amber => l10n.colorFamilyAmber,
        FolderColorFamily.yellow => l10n.colorFamilyYellow,
      };

  bool get _hasMatchingIcon => folderIconOptions.any((option) {
    final matchesCategory =
        _iconCategory == null || option.category == _iconCategory;
    final query = _iconSearch.toLowerCase();
    final matchesSearch =
        query.isEmpty ||
        option.id.toLowerCase().contains(query) ||
        option.searchTerms.toLowerCase().contains(query);
    return matchesCategory && matchesSearch;
  });

  Widget _buildIconCategory(
    BuildContext context,
    AppLocalizations l10n,
    FolderIconCategory category,
  ) {
    final query = _iconSearch.toLowerCase();
    final options = folderIconOptions.where((option) {
      final inCategory = option.category == category;
      final matchesSearch =
          query.isEmpty ||
          option.id.toLowerCase().contains(query) ||
          option.searchTerms.toLowerCase().contains(query);
      return inCategory && matchesSearch;
    }).toList();
    if (options.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _categoryLabel(l10n, category),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final option in options)
                SizedBox.square(
                  dimension: 50,
                  child: Semantics(
                    label: l10n.folderIcon,
                    selected: option.id == _icon,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _icon = option.id),
                      child: Container(
                        decoration: BoxDecoration(
                          color: option.id == _icon
                              ? _color.withValues(alpha: 0.16)
                              : Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: option.id == _icon
                                ? _color
                                : Theme.of(context).colorScheme.outlineVariant,
                            width: option.id == _icon ? 2 : 1,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              option.icon,
                              color: folderColorForeground(_color),
                              size: 24,
                            ),
                            if (option.id == _icon)
                              const PositionedDirectional(
                                top: 2,
                                end: 2,
                                child: Icon(Icons.check_circle, size: 14),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _categoryLabel(AppLocalizations l10n, FolderIconCategory category) =>
      switch (category) {
        FolderIconCategory.fitness => l10n.folderIconFitness,
        FolderIconCategory.learning => l10n.folderIconLearning,
        FolderIconCategory.daily => l10n.folderIconDaily,
        FolderIconCategory.work => l10n.folderIconWork,
        FolderIconCategory.goals => l10n.folderIconGoals,
        FolderIconCategory.nature => l10n.folderIconNature,
      };

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    try {
      validateFolderName(_nameController.text);
      setState(() => _saving = true);
      final repository = ref.read(folderRepositoryProvider);
      if (_editing) {
        await repository.update(
          widget.folder!.id,
          name: _nameController.text,
          color: _color.toARGB32(),
          iconCode: Value(_icon),
        );
      } else {
        await repository.create(
          name: _nameController.text,
          color: _color.toARGB32(),
          iconCode: _icon,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } on ValidationException catch (error) {
      if (!mounted) return;
      final message = switch (error.error) {
        ValidationError.emptyName => l10n.errorEmptyName,
        ValidationError.nameTooLong => l10n.errorNameTooLong,
        ValidationError.invalidDate => l10n.errorInvalidDate,
      };
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      setState(() => _saving = false);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.genericSaveError)));
      setState(() => _saving = false);
    }
  }
}
