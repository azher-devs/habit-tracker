import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/providers.dart';
import '../../../core/localization/gen/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(languageProvider).value ?? const Locale('ar');
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: mode.when(
              loading: () => ListTile(
                leading: Icon(Icons.palette_outlined),
                title: Text(l10n.appearance),
                trailing: SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, _) => ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: Text(l10n.appearance),
                subtitle: Text(l10n.errorGeneric),
              ),
              data: (value) => Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.palette_outlined),
                    title: Text(l10n.appearance),
                  ),
                  SwitchListTile(
                    title: Text(l10n.darkMode),
                    value: value == ThemeMode.dark,
                    onChanged: (enabled) async {
                      try {
                        await ref
                            .read(settingsRepositoryProvider)
                            .setThemeMode(
                              enabled ? ThemeMode.dark : ThemeMode.light,
                            );
                      } catch (_) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.genericSaveError)),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.language_outlined),
              title: Text(l10n.language),
              trailing: DropdownButton<Locale>(
                value: locale,
                items: const [
                  DropdownMenuItem(value: Locale('ar'), child: Text('العربية')),
                  DropdownMenuItem(value: Locale('en'), child: Text('English')),
                ],
                onChanged: (selected) async {
                  if (selected == null) return;
                  try {
                    await ref
                        .read(settingsRepositoryProvider)
                        .setLanguage(selected);
                  } catch (_) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.genericSaveError)),
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
