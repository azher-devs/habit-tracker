import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'متتبع العادات'**
  String get appName;

  /// No description provided for @tabFolders.
  ///
  /// In ar, this message translates to:
  /// **'مجلداتي'**
  String get tabFolders;

  /// No description provided for @tabStatistics.
  ///
  /// In ar, this message translates to:
  /// **'الإحصائيات'**
  String get tabStatistics;

  /// No description provided for @tabSettings.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get tabSettings;

  /// No description provided for @foldersTitle.
  ///
  /// In ar, this message translates to:
  /// **'مجلداتي'**
  String get foldersTitle;

  /// No description provided for @errorGeneric.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ غير متوقع. حاول مرة أخرى.'**
  String get errorGeneric;

  /// No description provided for @errorEmptyName.
  ///
  /// In ar, this message translates to:
  /// **'الرجاء إدخال اسم المجلد.'**
  String get errorEmptyName;

  /// No description provided for @errorNameTooLong.
  ///
  /// In ar, this message translates to:
  /// **'اسم المجلد طويل جدًا (الحد الأقصى 60 حرفًا).'**
  String get errorNameTooLong;

  /// No description provided for @errorInvalidDate.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ غير صالح.'**
  String get errorInvalidDate;

  /// No description provided for @emptyFoldersTitle.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بهدفك الأول'**
  String get emptyFoldersTitle;

  /// No description provided for @emptyFoldersBody.
  ///
  /// In ar, this message translates to:
  /// **'أنشئ مجلدًا لمتابعة عاداتك وتقدمك اليومي.'**
  String get emptyFoldersBody;

  /// No description provided for @addFolder.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مجلد'**
  String get addFolder;

  /// No description provided for @editFolder.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المجلد'**
  String get editFolder;

  /// No description provided for @folderName.
  ///
  /// In ar, this message translates to:
  /// **'اسم المجلد'**
  String get folderName;

  /// No description provided for @chooseColor.
  ///
  /// In ar, this message translates to:
  /// **'اختر لونًا'**
  String get chooseColor;

  /// No description provided for @colorFamilyGreen.
  ///
  /// In ar, this message translates to:
  /// **'أخضر'**
  String get colorFamilyGreen;

  /// No description provided for @colorFamilyTeal.
  ///
  /// In ar, this message translates to:
  /// **'فيروزي'**
  String get colorFamilyTeal;

  /// No description provided for @colorFamilyBlue.
  ///
  /// In ar, this message translates to:
  /// **'أزرق'**
  String get colorFamilyBlue;

  /// No description provided for @colorFamilyCyan.
  ///
  /// In ar, this message translates to:
  /// **'سماوي'**
  String get colorFamilyCyan;

  /// No description provided for @colorFamilyIndigo.
  ///
  /// In ar, this message translates to:
  /// **'نيلي'**
  String get colorFamilyIndigo;

  /// No description provided for @colorFamilyPurple.
  ///
  /// In ar, this message translates to:
  /// **'بنفسجي'**
  String get colorFamilyPurple;

  /// No description provided for @colorFamilyPink.
  ///
  /// In ar, this message translates to:
  /// **'وردي'**
  String get colorFamilyPink;

  /// No description provided for @colorFamilyRed.
  ///
  /// In ar, this message translates to:
  /// **'أحمر'**
  String get colorFamilyRed;

  /// No description provided for @colorFamilyOrange.
  ///
  /// In ar, this message translates to:
  /// **'برتقالي'**
  String get colorFamilyOrange;

  /// No description provided for @colorFamilyAmber.
  ///
  /// In ar, this message translates to:
  /// **'كهرماني'**
  String get colorFamilyAmber;

  /// No description provided for @colorFamilyYellow.
  ///
  /// In ar, this message translates to:
  /// **'أصفر'**
  String get colorFamilyYellow;

  /// No description provided for @colorFamilyCustom.
  ///
  /// In ar, this message translates to:
  /// **'لون محفوظ'**
  String get colorFamilyCustom;

  /// No description provided for @chooseIcon.
  ///
  /// In ar, this message translates to:
  /// **'اختر رمزًا'**
  String get chooseIcon;

  /// No description provided for @searchFolderIcons.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن رمز'**
  String get searchFolderIcons;

  /// No description provided for @allFolderIcons.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get allFolderIcons;

  /// No description provided for @noFolderIconsFound.
  ///
  /// In ar, this message translates to:
  /// **'لم يتم العثور على رموز مطابقة.'**
  String get noFolderIconsFound;

  /// No description provided for @folderIconFitness.
  ///
  /// In ar, this message translates to:
  /// **'الرياضة والصحة'**
  String get folderIconFitness;

  /// No description provided for @folderIconLearning.
  ///
  /// In ar, this message translates to:
  /// **'التعلم والدراسة'**
  String get folderIconLearning;

  /// No description provided for @folderIconDaily.
  ///
  /// In ar, this message translates to:
  /// **'الحياة اليومية'**
  String get folderIconDaily;

  /// No description provided for @folderIconWork.
  ///
  /// In ar, this message translates to:
  /// **'العمل والإنتاجية'**
  String get folderIconWork;

  /// No description provided for @folderIconGoals.
  ///
  /// In ar, this message translates to:
  /// **'المال والأهداف'**
  String get folderIconGoals;

  /// No description provided for @folderIconNature.
  ///
  /// In ar, this message translates to:
  /// **'الطبيعة والهوايات'**
  String get folderIconNature;

  /// No description provided for @save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @archiveFolder.
  ///
  /// In ar, this message translates to:
  /// **'أرشفة المجلد'**
  String get archiveFolder;

  /// No description provided for @restoreFolder.
  ///
  /// In ar, this message translates to:
  /// **'استعادة المجلد'**
  String get restoreFolder;

  /// No description provided for @archivedFolders.
  ///
  /// In ar, this message translates to:
  /// **'المجلدات المؤرشفة'**
  String get archivedFolders;

  /// No description provided for @noArchivedFolders.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مجلدات مؤرشفة.'**
  String get noArchivedFolders;

  /// No description provided for @statisticsComingSoon.
  ///
  /// In ar, this message translates to:
  /// **'ستظهر إحصائيات تقدمك هنا.'**
  String get statisticsComingSoon;

  /// No description provided for @appearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get appearance;

  /// No description provided for @systemTheme.
  ///
  /// In ar, this message translates to:
  /// **'حسب إعدادات الجهاز'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get darkTheme;

  /// No description provided for @settingsTitle.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get settingsTitle;

  /// No description provided for @genericSaveError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ التغييرات. حاول مرة أخرى.'**
  String get genericSaveError;

  /// No description provided for @folderIcon.
  ///
  /// In ar, this message translates to:
  /// **'رمز المجلد'**
  String get folderIcon;

  /// No description provided for @moveFolder.
  ///
  /// In ar, this message translates to:
  /// **'إعادة ترتيب المجلد'**
  String get moveFolder;

  /// No description provided for @openCalendar.
  ///
  /// In ar, this message translates to:
  /// **'عرض التقويم'**
  String get openCalendar;

  /// No description provided for @previousMonth.
  ///
  /// In ar, this message translates to:
  /// **'الشهر السابق'**
  String get previousMonth;

  /// No description provided for @nextMonth.
  ///
  /// In ar, this message translates to:
  /// **'الشهر التالي'**
  String get nextMonth;

  /// No description provided for @completed.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get completed;

  /// No description provided for @missed.
  ///
  /// In ar, this message translates to:
  /// **'لم يكتمل'**
  String get missed;

  /// No description provided for @unrecorded.
  ///
  /// In ar, this message translates to:
  /// **'بدون تسجيل'**
  String get unrecorded;

  /// No description provided for @selectDayStatus.
  ///
  /// In ar, this message translates to:
  /// **'اختر حالة اليوم'**
  String get selectDayStatus;

  /// No description provided for @clearStatus.
  ///
  /// In ar, this message translates to:
  /// **'مسح الحالة'**
  String get clearStatus;

  /// No description provided for @saveStatusError.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ حالة اليوم. حاول مرة أخرى.'**
  String get saveStatusError;

  /// No description provided for @weekdaySaturday.
  ///
  /// In ar, this message translates to:
  /// **'س'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In ar, this message translates to:
  /// **'ح'**
  String get weekdaySunday;

  /// No description provided for @weekdayMonday.
  ///
  /// In ar, this message translates to:
  /// **'ن'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In ar, this message translates to:
  /// **'ث'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In ar, this message translates to:
  /// **'ر'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In ar, this message translates to:
  /// **'خ'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In ar, this message translates to:
  /// **'ج'**
  String get weekdayFriday;

  /// No description provided for @dayDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل اليوم'**
  String get dayDetails;

  /// No description provided for @dailyStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة اليوم'**
  String get dailyStatus;

  /// No description provided for @notesTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظات اليوم'**
  String get notesTitle;

  /// No description provided for @notesPlaceholder.
  ///
  /// In ar, this message translates to:
  /// **'دوّن ما تريد تذكره عن هذا اليوم...'**
  String get notesPlaceholder;

  /// No description provided for @saveFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حفظ التغييرات. بقيت كما هي على هذه الشاشة. حاول مرة أخرى.'**
  String get saveFailed;

  /// No description provided for @notesLoadWarning.
  ///
  /// In ar, this message translates to:
  /// **'تعذر قراءة تنسيق الملاحظات المحفوظة. لن تتغير ما لم تعدّل الملاحظات.'**
  String get notesLoadWarning;

  /// No description provided for @monthOverview.
  ///
  /// In ar, this message translates to:
  /// **'نظرة عامة على الشهر'**
  String get monthOverview;

  /// No description provided for @completionRate.
  ///
  /// In ar, this message translates to:
  /// **'نسبة الإنجاز'**
  String get completionRate;

  /// No description provided for @completionRecordedOnly.
  ///
  /// In ar, this message translates to:
  /// **'تُحسب نسبة الإنجاز من الأيام المسجلة فقط.'**
  String get completionRecordedOnly;

  /// No description provided for @completedDaysCount.
  ///
  /// In ar, this message translates to:
  /// **'أيام مكتملة: {count}'**
  String completedDaysCount(int count);

  /// No description provided for @missedDaysCount.
  ///
  /// In ar, this message translates to:
  /// **'أيام لم تكتمل: {count}'**
  String missedDaysCount(int count);

  /// No description provided for @unrecordedElapsedCount.
  ///
  /// In ar, this message translates to:
  /// **'أيام منقضية دون تسجيل: {count}'**
  String unrecordedElapsedCount(int count);

  /// No description provided for @recordingCoverage.
  ///
  /// In ar, this message translates to:
  /// **'تغطية التسجيل: {percent}% ({recorded} من {elapsed})'**
  String recordingCoverage(int percent, int recorded, int elapsed);

  /// No description provided for @statisticsDetails.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الإحصائيات'**
  String get statisticsDetails;

  /// No description provided for @comparisonSamePeriod.
  ///
  /// In ar, this message translates to:
  /// **'مقارنة بالفترة المنقضية نفسها من الشهر السابق'**
  String get comparisonSamePeriod;

  /// No description provided for @comparisonFullMonths.
  ///
  /// In ar, this message translates to:
  /// **'مقارنة بالشهر السابق كاملًا'**
  String get comparisonFullMonths;

  /// No description provided for @comparisonCounts.
  ///
  /// In ar, this message translates to:
  /// **'السابق: {completed} مكتمل، {missed} لم يكتمل، {unrecorded} دون تسجيل'**
  String comparisonCounts(int completed, int missed, int unrecorded);

  /// No description provided for @comparisonPeriodDays.
  ///
  /// In ar, this message translates to:
  /// **'الفترة المقارنة: {count} يومًا'**
  String comparisonPeriodDays(int count);

  /// No description provided for @recordedDays.
  ///
  /// In ar, this message translates to:
  /// **'يوم مسجل'**
  String get recordedDays;

  /// No description provided for @moreTitle.
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get moreTitle;

  /// No description provided for @openSettings.
  ///
  /// In ar, this message translates to:
  /// **'الإعدادات'**
  String get openSettings;

  /// No description provided for @settingsDescription.
  ///
  /// In ar, this message translates to:
  /// **'المظهر والبيانات المحلية'**
  String get settingsDescription;

  /// No description provided for @openArchived.
  ///
  /// In ar, this message translates to:
  /// **'المجلدات المؤرشفة'**
  String get openArchived;

  /// No description provided for @addNewFolder.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مجلد جديد'**
  String get addNewFolder;

  /// No description provided for @saveNotesNow.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get saveNotesNow;

  /// No description provided for @saving.
  ///
  /// In ar, this message translates to:
  /// **'جارٍ الحفظ...'**
  String get saving;

  /// No description provided for @saveSucceeded.
  ///
  /// In ar, this message translates to:
  /// **'تم الحفظ بنجاح'**
  String get saveSucceeded;

  /// No description provided for @unsavedChangesLabel.
  ///
  /// In ar, this message translates to:
  /// **'تغييرات غير محفوظة'**
  String get unsavedChangesLabel;

  /// No description provided for @unsavedChangesTitle.
  ///
  /// In ar, this message translates to:
  /// **'تغييرات غير محفوظة'**
  String get unsavedChangesTitle;

  /// No description provided for @unsavedChangesMessage.
  ///
  /// In ar, this message translates to:
  /// **'لديك تغييرات غير محفوظة. هل تريد الخروج دون حفظ؟'**
  String get unsavedChangesMessage;

  /// No description provided for @discardChanges.
  ///
  /// In ar, this message translates to:
  /// **'الخروج دون حفظ'**
  String get discardChanges;

  /// No description provided for @continueEditing.
  ///
  /// In ar, this message translates to:
  /// **'العودة للتعديل'**
  String get continueEditing;

  /// No description provided for @noMonthlyData.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد أيام مسجلة في هذا الشهر.'**
  String get noMonthlyData;

  /// No description provided for @monthlyProgress.
  ///
  /// In ar, this message translates to:
  /// **'التقدم الشهري'**
  String get monthlyProgress;

  /// No description provided for @darkMode.
  ///
  /// In ar, this message translates to:
  /// **'الوضع الداكن'**
  String get darkMode;

  /// No description provided for @monthlySummaryTitle.
  ///
  /// In ar, this message translates to:
  /// **'ملخص الشهر'**
  String get monthlySummaryTitle;

  /// No description provided for @streaksTitle.
  ///
  /// In ar, this message translates to:
  /// **'سلاسل الإنجاز'**
  String get streaksTitle;

  /// No description provided for @currentStreak.
  ///
  /// In ar, this message translates to:
  /// **'السلسلة الحالية'**
  String get currentStreak;

  /// No description provided for @longestStreak.
  ///
  /// In ar, this message translates to:
  /// **'أطول سلسلة'**
  String get longestStreak;

  /// No description provided for @daysCount.
  ///
  /// In ar, this message translates to:
  /// **'{count} يوم'**
  String daysCount(int count);

  /// No description provided for @monthRecordedCounts.
  ///
  /// In ar, this message translates to:
  /// **'{completed} مكتمل · {missed} لم يكتمل · {recorded} يوم مسجل'**
  String monthRecordedCounts(int completed, int missed, int recorded);

  /// No description provided for @monthStatusCountLine.
  ///
  /// In ar, this message translates to:
  /// **'{completed} مكتمل · {missed} لم يكتمل · {unrecorded} دون تسجيل'**
  String monthStatusCountLine(int completed, int missed, int unrecorded);

  /// No description provided for @elapsedUnrecorded.
  ///
  /// In ar, this message translates to:
  /// **'أيام الفترة المنقضية دون تسجيل: {count}'**
  String elapsedUnrecorded(int count);

  /// No description provided for @monthComparison.
  ///
  /// In ar, this message translates to:
  /// **'مقارنة بالشهر السابق'**
  String get monthComparison;

  /// No description provided for @insufficientComparison.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد بيانات كافية للمقارنة'**
  String get insufficientComparison;

  /// No description provided for @percentagePointChange.
  ///
  /// In ar, this message translates to:
  /// **'التغير {change} نقطة مئوية'**
  String percentagePointChange(double change);

  /// No description provided for @weeklyProgress.
  ///
  /// In ar, this message translates to:
  /// **'التقدم الأسبوعي'**
  String get weeklyProgress;

  /// No description provided for @weekCounts.
  ///
  /// In ar, this message translates to:
  /// **'الأسبوع {week}: {completed} مكتمل، {missed} لم يكتمل، {unrecorded} دون تسجيل'**
  String weekCounts(int week, int completed, int missed, int unrecorded);

  /// No description provided for @monthNotes.
  ///
  /// In ar, this message translates to:
  /// **'أيام بملاحظات: {count}'**
  String monthNotes(int count);

  /// No description provided for @noMonthlyNotes.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد ملاحظات في هذا الشهر.'**
  String get noMonthlyNotes;

  /// No description provided for @showArchivedStatistics.
  ///
  /// In ar, this message translates to:
  /// **'إظهار المجلدات المؤرشفة'**
  String get showArchivedStatistics;

  /// No description provided for @backupTitle.
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي والاستعادة'**
  String get backupTitle;

  /// No description provided for @backupDescription.
  ///
  /// In ar, this message translates to:
  /// **'احتفظ بنسخة محلية من مجلداتك وسجلاتك وملاحظاتك.'**
  String get backupDescription;

  /// No description provided for @exportBackup.
  ///
  /// In ar, this message translates to:
  /// **'تصدير نسخة احتياطية'**
  String get exportBackup;

  /// No description provided for @importBackup.
  ///
  /// In ar, this message translates to:
  /// **'استعادة من ملف'**
  String get importBackup;

  /// No description provided for @backupExported.
  ///
  /// In ar, this message translates to:
  /// **'تم تجهيز النسخة الاحتياطية.'**
  String get backupExported;

  /// No description provided for @backupRestored.
  ///
  /// In ar, this message translates to:
  /// **'تمت استعادة البيانات واستبدال البيانات الحالية.'**
  String get backupRestored;

  /// No description provided for @backupMerged.
  ///
  /// In ar, this message translates to:
  /// **'تم استيراد المجلدات كنسخة منفصلة.'**
  String get backupMerged;

  /// No description provided for @backupInvalid.
  ///
  /// In ar, this message translates to:
  /// **'ملف النسخة غير صالح أو غير مدعوم.'**
  String get backupInvalid;

  /// No description provided for @backupOperationFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذرت العملية. تحقق من مساحة التخزين وحاول مجددًا.'**
  String get backupOperationFailed;

  /// No description provided for @backupImportTitle.
  ///
  /// In ar, this message translates to:
  /// **'محتويات النسخة الاحتياطية'**
  String get backupImportTitle;

  /// No description provided for @backupCounts.
  ///
  /// In ar, this message translates to:
  /// **'{folders} مجلد · {entries} سجل يومي'**
  String backupCounts(int folders, int entries);

  /// No description provided for @backupReplace.
  ///
  /// In ar, this message translates to:
  /// **'استبدال البيانات'**
  String get backupReplace;

  /// No description provided for @backupMerge.
  ///
  /// In ar, this message translates to:
  /// **'استيراد كمجلدات منفصلة'**
  String get backupMerge;

  /// No description provided for @backupCancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get backupCancel;

  /// No description provided for @backupReplaceSafety.
  ///
  /// In ar, this message translates to:
  /// **'عند اختيار الاستبدال، ستُحفظ نسخة أمان قبل تغيير البيانات.'**
  String get backupReplaceSafety;

  /// No description provided for @openBackups.
  ///
  /// In ar, this message translates to:
  /// **'النسخ الاحتياطي والاستعادة'**
  String get openBackups;

  /// No description provided for @elapsedStatusDistribution.
  ///
  /// In ar, this message translates to:
  /// **'توزيع الأيام المنقضية'**
  String get elapsedStatusDistribution;

  /// No description provided for @chartCompleted.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل: {count}'**
  String chartCompleted(int count);

  /// No description provided for @chartMissed.
  ///
  /// In ar, this message translates to:
  /// **'لم يكتمل: {count}'**
  String chartMissed(int count);

  /// No description provided for @chartUnrecorded.
  ///
  /// In ar, this message translates to:
  /// **'بدون تسجيل: {count}'**
  String chartUnrecorded(int count);

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @importedFolderSuffix.
  ///
  /// In ar, this message translates to:
  /// **' (مستورد)'**
  String get importedFolderSuffix;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
