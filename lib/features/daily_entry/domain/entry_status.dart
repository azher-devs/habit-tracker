/// Explicit daily statuses. "Unrecorded" is represented by the absence of a
/// status (or of the whole entry), never by an enum value.
enum EntryStatus {
  completed(1),
  missed(2);

  const EntryStatus(this.value);

  /// Integer persisted in the database.
  final int value;

  static EntryStatus? fromValue(int? value) {
    switch (value) {
      case null:
        return null;
      case 1:
        return EntryStatus.completed;
      case 2:
        return EntryStatus.missed;
      default:
        throw ArgumentError.value(value, 'value', 'Unknown entry status');
    }
  }
}
