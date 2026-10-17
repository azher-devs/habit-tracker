import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' as intl;

import '../../../core/database/app_database.dart';
import '../../../core/database/providers.dart';
import '../../../core/localization/gen/app_localizations.dart';
import '../../../core/theme/status_colors.dart';
import '../../../core/utils/date_key.dart';
import 'folder_catalog.dart';
import '../../daily_entry/domain/entry_status.dart';
import '../domain/calendar_month.dart';

typedef _MonthKey = ({String folderId, int year, int month});

final _folderMonthProvider = StreamProvider.autoDispose
    .family<List<DailyEntryRow>, _MonthKey>(
      (ref, key) => ref
          .watch(entryRepositoryProvider)
          .watchMonth(key.folderId, key.year, key.month),
    );

class FolderCalendarScreen extends ConsumerStatefulWidget {
  const FolderCalendarScreen({super.key, required this.folderId});

  final String folderId;

  @override
  ConsumerState<FolderCalendarScreen> createState() =>
      _FolderCalendarScreenState();
}

class _FolderCalendarScreenState extends ConsumerState<FolderCalendarScreen> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();
    final today = DateKey.today();
    _month = DateTime.utc(today.year, today.month);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final folder = ref
        .watch(folderRepositoryProvider)
        .watchById(widget.folderId);
    final key = (
      folderId: widget.folderId,
      year: _month.year,
      month: _month.month,
    );
    final entries = ref.watch(_folderMonthProvider(key));
    return StreamBuilder<FolderRow?>(
      stream: folder,
      builder: (context, folderSnapshot) {
        final folderRow = folderSnapshot.data;
        return Scaffold(
          appBar: AppBar(
            title: Text(folderRow?.name ?? l10n.foldersTitle),
            backgroundColor: folderRow == null
                ? Theme.of(context).colorScheme.primary
                : safeFolderColor(folderRow.color),
            foregroundColor: folderRow == null
                ? Colors.white
                : folderColorForeground(safeFolderColor(folderRow.color)),
            leading: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
            ),
          ),
          body: entries.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(child: Text(l10n.errorGeneric)),
            data: (rows) => _buildCalendar(context, l10n, rows, folderRow),
          ),
        );
      },
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    AppLocalizations l10n,
    List<DailyEntryRow> rows,
    FolderRow? folder,
  ) {
    final byDate = {for (final row in rows) row.entryDate: row};
    final calendar = CalendarMonth(_month.year, _month.month);
    final completedCount = rows
        .where((row) => row.status == EntryStatus.completed.value)
        .length;
    final missedCount = rows
        .where((row) => row.status == EntryStatus.missed.value)
        .length;
    final recordedCount = completedCount + missedCount;
    final monthName = intl.DateFormat.yMMMM(
      Localizations.localeOf(context).toString(),
    ).format(_month);
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final statusColors = context.statusColors;
    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
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
                    monthName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
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
        const SizedBox(height: 12),
        Row(
          children: [
            for (final day in [
              l10n.weekdaySaturday,
              l10n.weekdaySunday,
              l10n.weekdayMonday,
              l10n.weekdayTuesday,
              l10n.weekdayWednesday,
              l10n.weekdayThursday,
              l10n.weekdayFriday,
            ])
              Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: calendar.cellCount,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 0.86,
          ),
          itemBuilder: (context, index) {
            final day = calendar.dayAt(index);
            if (day == null) return const SizedBox.shrink();
            final date = DateKey.fromParts(_month.year, _month.month, day);
            final row = byDate[date];
            final status = EntryStatus.fromValue(row?.status);
            final color = switch (status) {
              EntryStatus.completed => statusColors.completed,
              EntryStatus.missed => statusColors.missed,
              null => statusColors.unrecorded,
            };
            final label = switch (status) {
              EntryStatus.completed => l10n.completed,
              EntryStatus.missed => l10n.missed,
              null => l10n.unrecorded,
            };
            return Semantics(
              button: true,
              label: '$day, $label',
              child: Material(
                color: color,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () =>
                      context.push('/folders/${widget.folderId}/day/$date'),
                  onLongPress: () => _chooseStatus(date, status),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          color: status == null
                              ? Theme.of(context).colorScheme.onSurface
                              : statusColors.onStatus,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Icon(
                        switch (status) {
                          EntryStatus.completed => Icons.check_circle,
                          EntryStatus.missed => Icons.cancel,
                          null => Icons.remove_circle_outline,
                        },
                        size: 14,
                        color: status == null
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : statusColors.onStatus,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            _Legend(
              color: statusColors.completed,
              icon: Icons.check_circle,
              label: l10n.completed,
            ),
            _Legend(
              color: statusColors.missed,
              icon: Icons.cancel,
              label: l10n.missed,
            ),
            _Legend(
              color: statusColors.unrecorded,
              icon: Icons.remove_circle_outline,
              label: l10n.unrecorded,
            ),
          ],
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Expanded(
                  child: _MonthCount(
                    label: l10n.completed,
                    value: completedCount,
                    color: statusColors.completed,
                  ),
                ),
                Expanded(
                  child: _MonthCount(
                    label: l10n.missed,
                    value: missedCount,
                    color: statusColors.missed,
                  ),
                ),
                Expanded(
                  child: _MonthCount(
                    label: l10n.recordedDays,
                    value: recordedCount,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _chooseStatus(String date, EntryStatus? current) async {
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<_StatusChoice>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.selectDayStatus,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(
                  Icons.check_circle,
                  color: context.statusColors.completed,
                ),
                title: Text(l10n.completed),
                selected: current == EntryStatus.completed,
                onTap: () => Navigator.pop(context, _StatusChoice.completed),
              ),
              ListTile(
                leading: Icon(Icons.cancel, color: context.statusColors.missed),
                title: Text(l10n.missed),
                selected: current == EntryStatus.missed,
                onTap: () => Navigator.pop(context, _StatusChoice.missed),
              ),
              ListTile(
                leading: const Icon(Icons.remove_circle_outline),
                title: Text(l10n.clearStatus),
                onTap: () => Navigator.pop(context, _StatusChoice.clear),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || choice == null) return;
    final selected = switch (choice) {
      _StatusChoice.completed => EntryStatus.completed,
      _StatusChoice.missed => EntryStatus.missed,
      _StatusChoice.clear => null,
    };
    if (selected == current) return;
    try {
      await ref
          .read(entryRepositoryProvider)
          .setStatus(widget.folderId, date, selected);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.saveStatusError)));
    }
  }
}

enum _StatusChoice { completed, missed, clear }

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.icon, required this.label});

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 5),
      Text(label),
    ],
  );
}

class _MonthCount extends StatelessWidget {
  const _MonthCount({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        '$value',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: Theme.of(context).textTheme.bodySmall,
        textAlign: TextAlign.center,
      ),
    ],
  );
}
