enum ValidationError { emptyName, nameTooLong, invalidDate }

/// Thrown by repositories when user-supplied data is invalid. The UI maps the
/// [error] to a localized Arabic message.
class ValidationException implements Exception {
  const ValidationException(this.error);

  final ValidationError error;

  @override
  String toString() => 'ValidationException($error)';
}

const int maxFolderNameLength = 60;

/// Returns the trimmed folder name or throws a [ValidationException].
String validateFolderName(String raw) {
  final name = raw.trim();
  if (name.isEmpty) throw const ValidationException(ValidationError.emptyName);
  if (name.length > maxFolderNameLength) {
    throw const ValidationException(ValidationError.nameTooLong);
  }
  return name;
}
