// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Habit Tracker';

  @override
  String get tabFolders => 'My Folders';

  @override
  String get tabStatistics => 'Statistics';

  @override
  String get tabSettings => 'More';

  @override
  String get foldersTitle => 'My Folders';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorEmptyName => 'Enter a folder name.';

  @override
  String get errorNameTooLong =>
      'Folder name is too long (maximum 60 characters).';

  @override
  String get errorInvalidDate => 'The date is invalid.';

  @override
  String get emptyFoldersTitle => 'Start your first goal';

  @override
  String get emptyFoldersBody =>
      'Create a folder to track your habits and daily progress.';

  @override
  String get addFolder => 'Add folder';

  @override
  String get editFolder => 'Edit folder';

  @override
  String get folderName => 'Folder name';

  @override
  String get chooseColor => 'Choose a color';

  @override
  String get colorFamilyGreen => 'Green';

  @override
  String get colorFamilyTeal => 'Teal';

  @override
  String get colorFamilyBlue => 'Blue';

  @override
  String get colorFamilyCyan => 'Cyan';

  @override
  String get colorFamilyIndigo => 'Indigo';

  @override
  String get colorFamilyPurple => 'Purple';

  @override
  String get colorFamilyPink => 'Pink';

  @override
  String get colorFamilyRed => 'Red';

  @override
  String get colorFamilyOrange => 'Orange';

  @override
  String get colorFamilyAmber => 'Amber';

  @override
  String get colorFamilyYellow => 'Yellow';

  @override
  String get colorFamilyCustom => 'Saved color';

  @override
  String get chooseIcon => 'Choose an icon';

  @override
  String get searchFolderIcons => 'Search icons';

  @override
  String get allFolderIcons => 'All';

  @override
  String get noFolderIconsFound => 'No matching icons found.';

  @override
  String get folderIconFitness => 'Fitness and health';

  @override
  String get folderIconLearning => 'Learning and study';

  @override
  String get folderIconDaily => 'Daily life';

  @override
  String get folderIconWork => 'Work and productivity';

  @override
  String get folderIconGoals => 'Money and goals';

  @override
  String get folderIconNature => 'Nature and hobbies';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get archiveFolder => 'Archive folder';

  @override
  String get restoreFolder => 'Restore folder';

  @override
  String get archivedFolders => 'Archived folders';

  @override
  String get noArchivedFolders => 'No archived folders.';

  @override
  String get statisticsComingSoon =>
      'Your progress statistics will appear here.';

  @override
  String get appearance => 'Appearance';

  @override
  String get systemTheme => 'Use device settings';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get genericSaveError =>
      'Couldn\'t save your changes. Please try again.';

  @override
  String get folderIcon => 'Folder icon';

  @override
  String get moveFolder => 'Reorder folder';

  @override
  String get openCalendar => 'Open calendar';

  @override
  String get previousMonth => 'Previous month';

  @override
  String get nextMonth => 'Next month';

  @override
  String get completed => 'Completed';

  @override
  String get missed => 'Missed';

  @override
  String get unrecorded => 'Not recorded';

  @override
  String get selectDayStatus => 'Choose today\'s status';

  @override
  String get clearStatus => 'Clear status';

  @override
  String get saveStatusError =>
      'Couldn\'t save the day\'s status. Please try again.';

  @override
  String get weekdaySaturday => 'Sat';

  @override
  String get weekdaySunday => 'Sun';

  @override
  String get weekdayMonday => 'Mon';

  @override
  String get weekdayTuesday => 'Tue';

  @override
  String get weekdayWednesday => 'Wed';

  @override
  String get weekdayThursday => 'Thu';

  @override
  String get weekdayFriday => 'Fri';

  @override
  String get dayDetails => 'Day details';

  @override
  String get dailyStatus => 'Today\'s status';

  @override
  String get notesTitle => 'Today\'s notes';

  @override
  String get notesPlaceholder =>
      'Write anything you want to remember about this day...';

  @override
  String get saveFailed =>
      'Couldn\'t save your changes. They are still on this screen. Please try again.';

  @override
  String get notesLoadWarning =>
      'Couldn\'t read the saved note format. It won\'t change unless you edit the note.';

  @override
  String get monthOverview => 'Monthly overview';

  @override
  String get completionRate => 'Completion rate';

  @override
  String get completionRecordedOnly =>
      'Completion rate is based on recorded days only.';

  @override
  String completedDaysCount(int count) {
    return 'Completed: $count';
  }

  @override
  String missedDaysCount(int count) {
    return 'Missed: $count';
  }

  @override
  String unrecordedElapsedCount(int count) {
    return 'Elapsed days not recorded: $count';
  }

  @override
  String recordingCoverage(int percent, int recorded, int elapsed) {
    return 'Recording coverage: $percent% ($recorded of $elapsed)';
  }

  @override
  String get statisticsDetails => 'Statistics details';

  @override
  String get comparisonSamePeriod =>
      'Compared with the same elapsed period last month';

  @override
  String get comparisonFullMonths => 'Compared with the full previous month';

  @override
  String comparisonCounts(int completed, int missed, int unrecorded) {
    return 'Previous: $completed completed, $missed missed, $unrecorded not recorded';
  }

  @override
  String comparisonPeriodDays(int count) {
    return 'Comparison period: $count days';
  }

  @override
  String get recordedDays => 'Recorded days';

  @override
  String get moreTitle => 'More';

  @override
  String get openSettings => 'Settings';

  @override
  String get settingsDescription => 'Appearance and local data';

  @override
  String get openArchived => 'Archived folders';

  @override
  String get addNewFolder => 'Add a folder';

  @override
  String get saveNotesNow => 'Save';

  @override
  String get saving => 'Saving...';

  @override
  String get saveSucceeded => 'Saved successfully';

  @override
  String get unsavedChangesLabel => 'Unsaved changes';

  @override
  String get unsavedChangesTitle => 'Unsaved changes';

  @override
  String get unsavedChangesMessage =>
      'You have unsaved changes. Do you want to leave without saving?';

  @override
  String get discardChanges => 'Leave without saving';

  @override
  String get continueEditing => 'Keep editing';

  @override
  String get noMonthlyData => 'No recorded days this month.';

  @override
  String get monthlyProgress => 'Monthly progress';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get monthlySummaryTitle => 'Monthly summary';

  @override
  String get streaksTitle => 'Streaks';

  @override
  String get currentStreak => 'Current streak';

  @override
  String get longestStreak => 'Longest streak';

  @override
  String daysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '# days',
      one: '1 day',
      zero: '0 days',
    );
    return '$_temp0';
  }

  @override
  String monthRecordedCounts(int completed, int missed, int recorded) {
    return '$completed completed · $missed missed · $recorded recorded days';
  }

  @override
  String monthStatusCountLine(int completed, int missed, int unrecorded) {
    return '$completed completed · $missed missed · $unrecorded not recorded';
  }

  @override
  String elapsedUnrecorded(int count) {
    return 'Elapsed days not recorded: $count';
  }

  @override
  String get monthComparison => 'Compared with last month';

  @override
  String get insufficientComparison => 'Not enough data to compare';

  @override
  String percentagePointChange(double change) {
    return 'Change: $change percentage points';
  }

  @override
  String get weeklyProgress => 'Weekly progress';

  @override
  String weekCounts(int week, int completed, int missed, int unrecorded) {
    return 'Week $week: $completed completed, $missed missed, $unrecorded not recorded';
  }

  @override
  String monthNotes(int count) {
    return 'Days with notes: $count';
  }

  @override
  String get noMonthlyNotes => 'No notes this month.';

  @override
  String get showArchivedStatistics => 'Show archived folders';

  @override
  String get backupTitle => 'Backup and restore';

  @override
  String get backupDescription =>
      'Keep a local copy of your folders, entries, and notes.';

  @override
  String get exportBackup => 'Export backup';

  @override
  String get importBackup => 'Restore from file';

  @override
  String get backupExported => 'Backup is ready.';

  @override
  String get backupRestored => 'Data restored and current data replaced.';

  @override
  String get backupMerged => 'Folders imported separately.';

  @override
  String get backupInvalid => 'The backup file is invalid or unsupported.';

  @override
  String get backupOperationFailed =>
      'The operation failed. Check storage space and try again.';

  @override
  String get backupImportTitle => 'Backup contents';

  @override
  String backupCounts(int folders, int entries) {
    return '$folders folders · $entries daily entries';
  }

  @override
  String get backupReplace => 'Replace data';

  @override
  String get backupMerge => 'Import as separate folders';

  @override
  String get backupCancel => 'Cancel';

  @override
  String get backupReplaceSafety =>
      'A safety backup will be saved before replacing your data.';

  @override
  String get openBackups => 'Backup and restore';

  @override
  String get elapsedStatusDistribution => 'Elapsed-day status breakdown';

  @override
  String chartCompleted(int count) {
    return 'Completed: $count';
  }

  @override
  String chartMissed(int count) {
    return 'Missed: $count';
  }

  @override
  String chartUnrecorded(int count) {
    return 'Not recorded: $count';
  }

  @override
  String get language => 'Language';

  @override
  String get importedFolderSuffix => ' (Imported)';
}
