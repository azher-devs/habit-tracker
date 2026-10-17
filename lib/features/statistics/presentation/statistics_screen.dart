import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/database/app_database.dart';
import '../../../core/localization/gen/app_localizations.dart';
import '../../../core/utils/date_key.dart';
import '../../daily_entry/data/entry_repository.dart';
import '../../folders/providers/folder_providers.dart';
import '../../folders/presentation/folder_catalog.dart';
import '../domain/completion_rate.dart';
import '../domain/monthly_summary_builder.dart';
import '../providers/statistics_providers.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  late DateTime _month;
  bool _showArchived = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime.utc(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final folders = ref.watch(activeFoldersProvider);
    final archived = ref.watch(archivedFoldersProvider);
    final today = ref.watch(localTodayProvider).value ?? DateTime.now();
    final todayKey = DateKey.fromDate(today);
    final counts = ref.watch(
      monthStatusCountsProvider((
        year: _month.year,
        month: _month.month,
        todayKey: todayKey,
      )),
    );
    return Scaffold(
      appBar: AppBar(title: Text(l10n.tabStatistics)),
      body: folders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.errorGeneric)),
        data: (items) => archived.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.errorGeneric)),
          data: (archivedItems) => counts.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(child: Text(l10n.errorGeneric)),
            data: (values) => _buildContent(
              context,
              l10n,
              _showArchived ? [...items, ...archivedItems] : items,
              values,
              elapsedDays: MonthlySummaryBuilder.elapsedDayCount(
                _month.year,
                _month.month,
                todayKey: todayKey,
              ),
              archivedIds: {for (final folder in archivedItems) folder.id},
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    List<FolderRow> folders,
    Map<String, StatusCounts> counts, {
    required int elapsedDays,
    required Set<String> archivedIds,
  }) {
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                IconButton(
                  tooltip: l10n.previousMonth,
                  onPressed: () => setState(
                    () => _month = DateTime.utc(_month.year, _month.month - 1),
                  ),
                  icon: Icon(isRtl ? Icons.chevron_right : Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    intl.DateFormat.yMMMM(
                      Localizations.localeOf(context).toString(),
                    ).format(_month),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.nextMonth,
                  onPressed: () => setState(
                    () => _month = DateTime.utc(_month.year, _month.month + 1),
                  ),
                  icon: Icon(isRtl ? Icons.chevron_left : Icons.chevron_right),
                ),
              ],
            ),
          ),
        ),
        SwitchListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          title: Text(l10n.showArchivedStatistics),
          value: _showArchived,
          onChanged: (value) => setState(() => _showArchived = value),
        ),
        const SizedBox(height: 18),
        Text(l10n.monthOverview, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(l10n.completionRecordedOnly),
        const SizedBox(height: 12),
        if (folders.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(l10n.emptyFoldersBody, textAlign: TextAlign.center),
            ),
          )
        else
          for (final folder in folders)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FolderProgressCard(
                folder: folder,
                counts: counts[folder.id] ?? const StatusCounts(),
                elapsedDays: elapsedDays,
                archived: archivedIds.contains(folder.id),
                onTap: () => context.push('/folders/${folder.id}/statistics'),
              ),
            ),
      ],
    );
  }
}

class _FolderProgressCard extends StatelessWidget {
  const _FolderProgressCard({
    required this.folder,
    required this.counts,
    required this.elapsedDays,
    required this.archived,
    required this.onTap,
  });

  final FolderRow folder;
  final StatusCounts counts;
  final int elapsedDays;
  final bool archived;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rate = CompletionRate(
      completed: counts.completed,
      missed: counts.missed,
    );
    final recorded = rate.recorded;
    final progress = rate.fraction ?? 0.0;
    final color = safeFolderColor(folder.color);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      backgroundColor: color.withValues(alpha: 0.12),
                      color: color,
                    ),
                    Text(
                      rate.percent == null ? '—' : '${rate.percent}%',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      folder.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (archived)
                      Text(
                        l10n.archivedFolders,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    const SizedBox(height: 7),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: progress,
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.12),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      elapsedDays == 0
                          ? l10n.noMonthlyData
                          : l10n.monthStatusCountLine(
                              counts.completed,
                              counts.missed,
                              elapsedDays - recorded,
                            ),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
