import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/localization/gen/app_localizations.dart';
import '../features/daily_entry/presentation/daily_entry_screen.dart';
import '../features/folders/presentation/archived_folders_screen.dart';
import '../features/folders/presentation/folder_calendar_screen.dart';
import '../features/folders/presentation/folders_screen.dart';
import '../features/settings/presentation/more_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/settings/presentation/backup_screen.dart';
import '../features/statistics/presentation/statistics_screen.dart';
import '../features/statistics/presentation/folder_statistics_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const FoldersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/statistics',
                builder: (context, state) => const StatisticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/more',
                builder: (context, state) => const MoreScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/archived',
        builder: (context, state) => const ArchivedFoldersScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/backup',
        builder: (context, state) => const BackupScreen(),
      ),
      GoRoute(
        path: '/folders/:folderId',
        builder: (context, state) =>
            FolderCalendarScreen(folderId: state.pathParameters['folderId']!),
        routes: [
          GoRoute(
            path: 'statistics',
            builder: (context, state) => FolderStatisticsScreen(
              folderId: state.pathParameters['folderId']!,
            ),
          ),
          GoRoute(
            path: 'day/:date',
            builder: (context, state) => DailyEntryScreen(
              folderId: state.pathParameters['folderId']!,
              date: state.pathParameters['date']!,
            ),
          ),
        ],
      ),
    ],
  );
});

class _AppShell extends StatelessWidget {
  const _AppShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.folder_outlined),
            label: l10n.tabFolders,
          ),
          NavigationDestination(
            icon: const Icon(Icons.insights_outlined),
            label: l10n.tabStatistics,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            label: l10n.tabSettings,
          ),
        ],
      ),
    );
  }
}
