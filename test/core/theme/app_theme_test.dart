import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:habit_tracker/core/theme/app_theme.dart';
import 'package:habit_tracker/core/theme/status_colors.dart';

void main() {
  test(
    'light and dark themes use the bundled Arabic family and fixed status colors',
    () {
      final light = AppTheme.light();
      final dark = AppTheme.dark();
      expect(light.textTheme.bodyMedium?.fontFamily, 'IBMPlexSansArabic');
      expect(dark.textTheme.bodyMedium?.fontFamily, 'IBMPlexSansArabic');
      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(
        light.extension<StatusColors>()?.completed,
        StatusColors.light.completed,
      );
      expect(dark.extension<StatusColors>()?.missed, StatusColors.dark.missed);
      expect(
        light.extension<StatusColors>()?.completed,
        isNot(ColorScheme.fromSeed(seedColor: const Color(0xFF1678F2)).primary),
      );
    },
  );
}
