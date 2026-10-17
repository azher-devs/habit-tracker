import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/database/app_database.dart';
import '../../../core/database/providers.dart';
import '../../../core/localization/gen/app_localizations.dart';
import '../../../core/theme/status_colors.dart';
import '../../../core/utils/date_key.dart';
import '../../daily_entry/domain/entry_status.dart';
import '../../daily_entry/domain/notes_codec.dart';
import '../domain/monthly_summary_builder.dart';
import '../providers/statistics_providers.dart';

class FolderStatisticsScreen extends ConsumerStatefulWidget {
  const FolderStatisticsScreen({super.key, required this.folderId});

  final String folderId;

  @override
  ConsumerState<FolderStatisticsScreen> createState() =>
      _FolderStatisticsScreenState();
}

class _FolderStatisticsScreenState
    extends ConsumerState<FolderStatisticsScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime.utc(now.year, now.month);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final today = ref.watch(localTodayProvider).value ?? DateTime.now();
    final folderStream = ref
        .watch(folderRepositoryProvider)
        .watchById(widget.folderId);
    final summary = ref.watch(
      monthlySummaryProvider((
        folderId: widget.folderId,
        year: _month.year,
        month: _month.month,
        todayKey: DateKey.fromDate(today),
      )),
    );
    return StreamBuilder<FolderRow?>(
      stream: folderStream,
      builder: (context, folderSnapshot) => Scaffold(
        appBar: AppBar(
          title: Text(folderSnapshot.data?.name ?? l10n.monthlySummaryTitle),
        ),
        body: summary.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(child: Text(l10n.errorGeneric)),
          data: (value) => _content(context, l10n, value),
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    MonthlySummary summary,
  ) {
    final theme = Theme.of(context);
    final monthTitle = intl.DateFormat.yMMMM(
      Localizations.localeOf(context).toString(),
    ).format(_month);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final rate = summary.completion;
    final progress = rate.fraction ?? 0.0;
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 24),
      children: [
        Card(
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.previousMonth,
                onPressed: () => setState(
                  () => _month = DateTime.utc(_month.year, _month.month - 1),
                ),
                icon: Icon(isRtl ? Icons.chevron_right : Icons.chevron_left),
              ),
              Expanded(child: Text(monthTitle, textAlign: TextAlign.center)),
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
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.monthOverview, style: theme.textTheme.titleMedium),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.completionRate),
                          const SizedBox(height: 3),
                          Text(
                            rate.percent == null ? '—' : '${rate.percent}%',
                            style: theme.textTheme.headlineLarge?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 64,
                      height: 64,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 7,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        semanticsLabel: l10n.completionRate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  l10n.completionRecordedOnly,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 14,
                  runSpacing: 12,
                  children: [
                    _CountMetric(
                      color: context.statusColors.completed,
                      label: l10n.completedDaysCount(summary.elapsedCompleted),
                    ),
                    _CountMetric(
                      color: context.statusColors.missed,
                      label: l10n.missedDaysCount(summary.elapsedMissed),
                    ),
                    _CountMetric(
                      color: context.statusColors.unrecorded,
                      label: l10n.unrecordedElapsedCount(
                        summary.unrecordedElapsedDays,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: summary.elapsedDays == 0
                        ? 0
                        : summary.monthlyRecorded / summary.elapsedDays,
                    minHeight: 7,
                    color: theme.colorScheme.tertiary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.recordingCoverage(
                    summary.elapsedDays == 0
                        ? 0
                        : (summary.monthlyRecorded * 100 / summary.elapsedDays)
                              .round(),
                    summary.monthlyRecorded,
                    summary.elapsedDays,
                  ),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            title: Text(l10n.statisticsDetails),
            childrenPadding: const EdgeInsetsDirectional.fromSTEB(
              16,
              0,
              16,
              16,
            ),
            children: [
              Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.streaksTitle,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _Metric(
                                  label: l10n.currentStreak,
                                  valueLabel: l10n.daysCount(
                                    summary.stats.currentStreak,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: _Metric(
                                  label: l10n.longestStreak,
                                  valueLabel: l10n.daysCount(
                                    summary.stats.longestStreak,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _StatusDistribution(summary: summary),
                  const SizedBox(height: 10),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        summary.comparisonPercentagePoints == null
                            ? Icons.compare_arrows
                            : summary.comparisonPercentagePoints! >= 0
                            ? Icons.trending_up
                            : Icons.trending_down,
                      ),
                      title: Text(l10n.monthComparison),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            summary.comparisonPercentagePoints == null
                                ? l10n.insufficientComparison
                                : summary.comparisonUsesMatchingPeriod
                                ? l10n.comparisonSamePeriod
                                : l10n.comparisonFullMonths,
                          ),
                          if (summary.comparisonPercentagePoints != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              l10n.percentagePointChange(
                                double.parse(
                                  summary.comparisonPercentagePoints!
                                      .toStringAsFixed(1),
                                ),
                              ),
                            ),
                            Text(
                              l10n.comparisonCounts(
                                summary.previousPeriodCompleted,
                                summary.previousPeriodMissed,
                                summary.previousPeriodUnrecorded,
                              ),
                            ),
                            Text(
                              l10n.comparisonPeriodDays(
                                summary.previousPeriodDays,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.weeklyProgress,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (summary.weeks.isEmpty)
                            Text(l10n.noMonthlyData)
                          else
                            for (var i = 0; i < summary.weeks.length; i++)
                              _WeekRow(week: summary.weeks[i], index: i + 1),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.monthNotes(summary.daysWithNotes),
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          if (summary.notes.isEmpty)
                            Text(l10n.noMonthlyNotes)
                          else
                            for (final note in summary.notes)
                              _NoteRow(
                                key: ValueKey('monthly-note-${note.date}'),
                                note: note,
                                l10n: l10n,
                                onTap: () => context.push(
                                  '/folders/${widget.folderId}/day/${note.date}',
                                ),
                              ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CountMetric extends StatelessWidget {
  const _CountMetric({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.circle, color: color, size: 11),
      const SizedBox(width: 6),
      Text(label, style: Theme.of(context).textTheme.bodyMedium),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.valueLabel});

  final String label;
  final String valueLabel;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodyMedium),
      const SizedBox(height: 4),
      Text(valueLabel, style: Theme.of(context).textTheme.titleLarge),
    ],
  );
}

class _StatusDistribution extends StatelessWidget {
  const _StatusDistribution({required this.summary});

  final MonthlySummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.statusColors;
    final total = summary.elapsedDays;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.elapsedStatusDistribution,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                SizedBox(
                  width: 112,
                  height: 112,
                  child: total == 0
                      ? const Center(child: Text('—'))
                      : PieChart(
                          PieChartData(
                            centerSpaceRadius: 30,
                            sectionsSpace: 2,
                            sections: [
                              PieChartSectionData(
                                value: summary.elapsedCompleted.toDouble(),
                                color: colors.completed,
                                radius: 24,
                                showTitle: false,
                              ),
                              PieChartSectionData(
                                value: summary.elapsedMissed.toDouble(),
                                color: colors.missed,
                                radius: 24,
                                showTitle: false,
                              ),
                              PieChartSectionData(
                                value: summary.unrecordedElapsedDays.toDouble(),
                                color: colors.unrecorded,
                                radius: 24,
                                showTitle: false,
                              ),
                            ],
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _LegendLine(
                        color: colors.completed,
                        label: l10n.chartCompleted(summary.elapsedCompleted),
                      ),
                      _LegendLine(
                        color: colors.missed,
                        label: l10n.chartMissed(summary.elapsedMissed),
                      ),
                      _LegendLine(
                        color: colors.unrecorded,
                        label: l10n.chartUnrecorded(
                          summary.unrecordedElapsedDays,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendLine extends StatelessWidget {
  const _LegendLine({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Icon(Icons.circle, size: 11, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(label)),
      ],
    ),
  );
}

class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.week, required this.index});

  final WeeklySummary week;
  final int index;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final start = DateKey.parse(week.startDate).day;
    final end = DateKey.parse(week.endDate).day;
    final completedFraction = week.completion.fraction ?? 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          SizedBox(width: 48, child: Text('$start–$end')),
          Expanded(child: LinearProgressIndicator(value: completedFraction)),
          const SizedBox(width: 10),
          Text(
            l10n.weekCounts(
              index,
              week.completed,
              week.missed,
              week.unrecorded,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoteRow extends StatelessWidget {
  const _NoteRow({
    super.key,
    required this.note,
    required this.l10n,
    required this.onTap,
  });

  final SummaryNote note;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final statusColors = context.statusColors;
    String text;
    try {
      text = NotesCodec.decode(
        note.notesJson,
      ).map((operation) => operation['insert'] as String).join().trim();
    } on FormatException {
      text = l10n.notesLoadWarning;
    }
    final status = note.status;
    final statusLabel = switch (status) {
      EntryStatus.completed => l10n.completed,
      EntryStatus.missed => l10n.missed,
      null => l10n.unrecorded,
    };
    final statusIcon = switch (status) {
      EntryStatus.completed => Icons.check_circle,
      EntryStatus.missed => Icons.cancel,
      null => Icons.radio_button_unchecked,
    };
    final statusColor = switch (status) {
      EntryStatus.completed =>
        theme.brightness == Brightness.light
            ? const Color(0xFF1B6E3A)
            : statusColors.completed,
      EntryStatus.missed =>
        theme.brightness == Brightness.light
            ? const Color(0xFFB3261E)
            : statusColors.missed,
      null => theme.colorScheme.onSurfaceVariant,
    };
    final badgeBackground = switch (status) {
      EntryStatus.completed => statusColors.completed.withValues(alpha: 0.12),
      EntryStatus.missed => statusColors.missed.withValues(alpha: 0.12),
      null => theme.colorScheme.surfaceContainerHighest,
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      intl.DateFormat.yMMMMd(
                        Localizations.localeOf(context).toString(),
                      ).format(DateKey.parse(note.date)),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    isRtl ? Icons.chevron_left : Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsetsDirectional.fromSTEB(10, 5, 10, 5),
                decoration: BoxDecoration(
                  color: badgeBackground,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 16),
                    const SizedBox(width: 5),
                    Text(
                      statusLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: Text(
                  text,
                  softWrap: true,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
