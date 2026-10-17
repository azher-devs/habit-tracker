import 'package:flutter/material.dart';

/// Fixed daily-status colors, independent of any folder color.
@immutable
class StatusColors extends ThemeExtension<StatusColors> {
  const StatusColors({
    required this.completed,
    required this.missed,
    required this.unrecorded,
    required this.onStatus,
  });

  final Color completed;
  final Color missed;
  final Color unrecorded;
  final Color onStatus;

  static const light = StatusColors(
    completed: Color(0xFF2E9E57),
    missed: Color(0xFFD64545),
    unrecorded: Color(0xFFE6E8EC),
    onStatus: Colors.white,
  );

  static const dark = StatusColors(
    completed: Color(0xFF3DB86B),
    missed: Color(0xFFE05A5A),
    unrecorded: Color(0xFF2E3138),
    onStatus: Colors.white,
  );

  @override
  StatusColors copyWith({
    Color? completed,
    Color? missed,
    Color? unrecorded,
    Color? onStatus,
  }) => StatusColors(
    completed: completed ?? this.completed,
    missed: missed ?? this.missed,
    unrecorded: unrecorded ?? this.unrecorded,
    onStatus: onStatus ?? this.onStatus,
  );

  @override
  StatusColors lerp(StatusColors? other, double t) {
    if (other == null) return this;
    return StatusColors(
      completed: Color.lerp(completed, other.completed, t)!,
      missed: Color.lerp(missed, other.missed, t)!,
      unrecorded: Color.lerp(unrecorded, other.unrecorded, t)!,
      onStatus: Color.lerp(onStatus, other.onStatus, t)!,
    );
  }
}

extension StatusColorsContext on BuildContext {
  StatusColors get statusColors => Theme.of(this).extension<StatusColors>()!;
}
