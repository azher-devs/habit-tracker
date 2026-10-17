/// Completion for one folder and month. Notes-only and unrecorded dates are
/// excluded because callers pass counts from explicit statuses only.
class CompletionRate {
  const CompletionRate({required this.completed, required this.missed});

  final int completed;
  final int missed;

  int get recorded => completed + missed;

  double? get fraction => recorded == 0 ? null : completed / recorded;

  int? get percent => fraction == null ? null : (fraction! * 100).round();
}
