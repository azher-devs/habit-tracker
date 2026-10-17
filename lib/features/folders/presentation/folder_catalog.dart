import 'package:flutter/material.dart';

const folderColors = <Color>[
  // Existing values stay first so folders created by earlier app builds
  // retain their familiar palette positions.
  Color(0xFF2E7D5B),
  Color(0xFF1976D2),
  Color(0xFF7B1FA2),
  Color(0xFFE67E22),
  Color(0xFFC0392B),
  Color(0xFF00897B),
  Color(0xFF43A047),
  Color(0xFF1B5E20),
  Color(0xFF009688),
  Color(0xFF00695C),
  Color(0xFF42A5F5),
  Color(0xFF0D47A1),
  Color(0xFF00ACC1),
  Color(0xFF006064),
  Color(0xFF5C6BC0),
  Color(0xFF283593),
  Color(0xFFAB47BC),
  Color(0xFF4A148C),
  Color(0xFFEC407A),
  Color(0xFF880E4F),
  Color(0xFFEF5350),
  Color(0xFFB71C1C),
  Color(0xFFFFA726),
  Color(0xFFFFB300),
  Color(0xFFFDD835),
  Color(0xFFFFEE58),
];

enum FolderColorFamily {
  green,
  teal,
  blue,
  cyan,
  indigo,
  purple,
  pink,
  red,
  orange,
  amber,
  yellow,
}

List<Color> folderColorsInFamily(FolderColorFamily family) => switch (family) {
  FolderColorFamily.green => [
    const Color(0xFF2E7D5B),
    const Color(0xFF43A047),
    const Color(0xFF1B5E20),
  ],
  FolderColorFamily.teal => [
    const Color(0xFF00897B),
    const Color(0xFF009688),
    const Color(0xFF00695C),
  ],
  FolderColorFamily.blue => [
    const Color(0xFF1976D2),
    const Color(0xFF42A5F5),
    const Color(0xFF0D47A1),
  ],
  FolderColorFamily.cyan => [const Color(0xFF00ACC1), const Color(0xFF006064)],
  FolderColorFamily.indigo => [
    const Color(0xFF5C6BC0),
    const Color(0xFF283593),
  ],
  FolderColorFamily.purple => [
    const Color(0xFF7B1FA2),
    const Color(0xFFAB47BC),
    const Color(0xFF4A148C),
  ],
  FolderColorFamily.pink => [const Color(0xFFEC407A), const Color(0xFF880E4F)],
  FolderColorFamily.red => [
    const Color(0xFFC0392B),
    const Color(0xFFEF5350),
    const Color(0xFFB71C1C),
  ],
  FolderColorFamily.orange => [
    const Color(0xFFE67E22),
    const Color(0xFFFFA726),
  ],
  FolderColorFamily.amber => [const Color(0xFFFFB300)],
  FolderColorFamily.yellow => [
    const Color(0xFFFDD835),
    const Color(0xFFFFEE58),
  ],
};

Color safeFolderColor(int? value) {
  if (value == null || value < 0 || value > 0xFFFFFFFF || value >> 24 == 0) {
    return folderColors.first;
  }
  return Color(value);
}

Color folderColorForeground(Color color) =>
    color.computeLuminance() > 0.45 ? Colors.black : Colors.white;

enum FolderIconCategory { fitness, learning, daily, work, goals, nature }

class FolderIconOption {
  const FolderIconOption({
    required this.id,
    required this.icon,
    required this.category,
    required this.searchTerms,
  });

  final String id;
  final IconData icon;
  final FolderIconCategory category;
  final String searchTerms;
}

const folderIconOptions = <FolderIconOption>[
  FolderIconOption(
    id: 'fitness',
    icon: Icons.fitness_center,
    category: FolderIconCategory.fitness,
    searchTerms: 'رياضة تمرين لياقة أثقال',
  ),
  FolderIconOption(
    id: 'walking',
    icon: Icons.directions_walk,
    category: FolderIconCategory.fitness,
    searchTerms: 'مشي خطوات',
  ),
  FolderIconOption(
    id: 'cycling',
    icon: Icons.directions_bike,
    category: FolderIconCategory.fitness,
    searchTerms: 'دراجة ركوب',
  ),
  FolderIconOption(
    id: 'heart',
    icon: Icons.favorite_border,
    category: FolderIconCategory.fitness,
    searchTerms: 'قلب صحة',
  ),
  FolderIconOption(
    id: 'health',
    icon: Icons.medical_services_outlined,
    category: FolderIconCategory.fitness,
    searchTerms: 'طبي علاج عافية',
  ),
  FolderIconOption(
    id: 'yoga',
    icon: Icons.self_improvement,
    category: FolderIconCategory.fitness,
    searchTerms: 'يوغا تأمل تنفس',
  ),
  FolderIconOption(
    id: 'book',
    icon: Icons.menu_book_outlined,
    category: FolderIconCategory.learning,
    searchTerms: 'كتاب قراءة تعلم دراسة',
  ),
  FolderIconOption(
    id: 'graduation',
    icon: Icons.school_outlined,
    category: FolderIconCategory.learning,
    searchTerms: 'تخرج جامعة تعليم',
  ),
  FolderIconOption(
    id: 'brain',
    icon: Icons.psychology_outlined,
    category: FolderIconCategory.learning,
    searchTerms: 'دماغ عقل تركيز',
  ),
  FolderIconOption(
    id: 'language',
    icon: Icons.translate_outlined,
    category: FolderIconCategory.learning,
    searchTerms: 'لغة ترجمة كلمات',
  ),
  FolderIconOption(
    id: 'science',
    icon: Icons.science_outlined,
    category: FolderIconCategory.learning,
    searchTerms: 'علوم مختبر تجربة',
  ),
  FolderIconOption(
    id: 'check',
    icon: Icons.check_circle_outline,
    category: FolderIconCategory.learning,
    searchTerms: 'إنجاز نجاح تحقق',
  ),
  FolderIconOption(
    id: 'water',
    icon: Icons.water_drop_outlined,
    category: FolderIconCategory.daily,
    searchTerms: 'ماء شرب ترطيب',
  ),
  FolderIconOption(
    id: 'sleep',
    icon: Icons.bedtime_outlined,
    category: FolderIconCategory.daily,
    searchTerms: 'نوم راحة ليل',
  ),
  FolderIconOption(
    id: 'food',
    icon: Icons.restaurant_outlined,
    category: FolderIconCategory.daily,
    searchTerms: 'طعام أكل تغذية',
  ),
  FolderIconOption(
    id: 'selfcare',
    icon: Icons.spa_outlined,
    category: FolderIconCategory.daily,
    searchTerms: 'عناية استرخاء',
  ),
  FolderIconOption(
    id: 'home',
    icon: Icons.home_outlined,
    category: FolderIconCategory.daily,
    searchTerms: 'منزل بيت',
  ),
  FolderIconOption(
    id: 'cleaning',
    icon: Icons.cleaning_services_outlined,
    category: FolderIconCategory.daily,
    searchTerms: 'تنظيف ترتيب',
  ),
  FolderIconOption(
    id: 'checklist',
    icon: Icons.checklist_outlined,
    category: FolderIconCategory.daily,
    searchTerms: 'قائمة مهام عادة',
  ),
  FolderIconOption(
    id: 'work',
    icon: Icons.work_outline,
    category: FolderIconCategory.work,
    searchTerms: 'عمل وظيفة مكتب',
  ),
  FolderIconOption(
    id: 'laptop',
    icon: Icons.laptop_mac_outlined,
    category: FolderIconCategory.work,
    searchTerms: 'حاسوب كمبيوتر لابتوب',
  ),
  FolderIconOption(
    id: 'code',
    icon: Icons.code_outlined,
    category: FolderIconCategory.work,
    searchTerms: 'برمجة تطوير كود',
  ),
  FolderIconOption(
    id: 'calendar',
    icon: Icons.calendar_month_outlined,
    category: FolderIconCategory.work,
    searchTerms: 'تقويم موعد جدول',
  ),
  FolderIconOption(
    id: 'timer',
    icon: Icons.timer_outlined,
    category: FolderIconCategory.work,
    searchTerms: 'وقت مؤقت تركيز',
  ),
  FolderIconOption(
    id: 'tasks',
    icon: Icons.task_alt_outlined,
    category: FolderIconCategory.work,
    searchTerms: 'مهمة إنجاز قائمة',
  ),
  FolderIconOption(
    id: 'money',
    icon: Icons.payments_outlined,
    category: FolderIconCategory.goals,
    searchTerms: 'مال نقود مصروف',
  ),
  FolderIconOption(
    id: 'savings',
    icon: Icons.savings_outlined,
    category: FolderIconCategory.goals,
    searchTerms: 'ادخار توفير ميزانية',
  ),
  FolderIconOption(
    id: 'target',
    icon: Icons.track_changes_outlined,
    category: FolderIconCategory.goals,
    searchTerms: 'هدف أهداف تطوير',
  ),
  FolderIconOption(
    id: 'travel',
    icon: Icons.flight_takeoff_outlined,
    category: FolderIconCategory.goals,
    searchTerms: 'سفر طائرة رحلة',
  ),
  FolderIconOption(
    id: 'shopping',
    icon: Icons.shopping_bag_outlined,
    category: FolderIconCategory.goals,
    searchTerms: 'تسوق مشتريات',
  ),
  FolderIconOption(
    id: 'checklist_goal',
    icon: Icons.flag_outlined,
    category: FolderIconCategory.goals,
    searchTerms: 'هدف إنجاز تحدي',
  ),
  FolderIconOption(
    id: 'plant',
    icon: Icons.yard_outlined,
    category: FolderIconCategory.nature,
    searchTerms: 'نبات حديقة زراعة',
  ),
  FolderIconOption(
    id: 'pet',
    icon: Icons.pets_outlined,
    category: FolderIconCategory.nature,
    searchTerms: 'حيوان أليف قط كلب',
  ),
  FolderIconOption(
    id: 'camera',
    icon: Icons.camera_alt_outlined,
    category: FolderIconCategory.nature,
    searchTerms: 'تصوير كاميرا هواية',
  ),
  FolderIconOption(
    id: 'palette',
    icon: Icons.palette_outlined,
    category: FolderIconCategory.nature,
    searchTerms: 'فن رسم ألوان',
  ),
  FolderIconOption(
    id: 'music',
    icon: Icons.music_note_outlined,
    category: FolderIconCategory.nature,
    searchTerms: 'موسيقى عزف',
  ),
  FolderIconOption(
    id: 'hiking',
    icon: Icons.hiking_outlined,
    category: FolderIconCategory.nature,
    searchTerms: 'مشي جبال طبيعة',
  ),
  FolderIconOption(
    id: 'games',
    icon: Icons.sports_esports_outlined,
    category: FolderIconCategory.nature,
    searchTerms: 'ألعاب ترفيه هواية',
  ),
];

final folderIcons = <String, IconData>{
  for (final option in folderIconOptions) option.id: option.icon,
};

IconData folderIconFor(String? id) =>
    folderIcons[id] ?? Icons.check_circle_outline;
