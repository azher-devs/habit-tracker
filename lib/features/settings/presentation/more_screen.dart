import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/gen/app_localizations.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.moreTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: Text(l10n.openSettings),
              subtitle: Text(l10n.settingsDescription),
              trailing: Icon(isRtl ? Icons.chevron_left : Icons.chevron_right),
              onTap: () => context.push('/settings'),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.backup_outlined),
              title: Text(l10n.openBackups),
              trailing: Icon(isRtl ? Icons.chevron_left : Icons.chevron_right),
              onTap: () => context.push('/backup'),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.archive_outlined),
              title: Text(l10n.openArchived),
              trailing: Icon(isRtl ? Icons.chevron_left : Icons.chevron_right),
              onTap: () => context.push('/archived'),
            ),
          ),
        ],
      ),
    );
  }
}
